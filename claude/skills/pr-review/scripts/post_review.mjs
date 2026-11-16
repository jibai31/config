#!/usr/bin/env node
// Posts a review from a findings JSON file: resolves verified threads, replies to still-open ones, then posts a
// single review with inline comments.
//
// Usage: node post_review.mjs FINDINGS_JSON [--dry-run]
//
// Exit codes: 0 no open blocking issues · 2 blocking issues open · 3 handoff to a human · 1 error

import { existsSync, readFileSync } from 'node:fs';

import {
  COMMENT_MARKER,
  REPLY_MARKER,
  SCOPES,
  SEVERITIES,
  buildReviewMarker,
  gh,
  ghJson,
  graphql,
  repo,
  runMain,
} from './github.mjs';

const RESOLVE_MUTATION = `
  mutation($id: ID!) { resolveReviewThread(input: { threadId: $id }) { thread { id isResolved } } }`;

// Returns { path: Set of commentable new-side line numbers } from the PR's patches.
function commentableLines(number) {
  const byFile = {};
  const raw = gh(['api', `repos/${repo()}/pulls/${number}/files`, '--paginate', '--jq', '.[] | {filename, patch}']);
  for (const line of raw.split('\n')) {
    if (!line.trim()) continue;
    const file = JSON.parse(line);
    byFile[file.filename] = parsePatch(file.patch ?? '');
  }
  return byFile;
}

export function parsePatch(patch) {
  const valid = new Set();
  let newLine = null;
  for (const row of patch.split('\n')) {
    const hunk = row.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
    if (hunk) {
      newLine = Number(hunk[1]);
    } else if (newLine === null || row.startsWith('\\') || row.startsWith('-')) {
      continue;
    } else {
      // context (" ") or addition ("+")
      valid.add(newLine);
      newLine += 1;
    }
  }
  return valid;
}

function formatComment(f) {
  const parts = [`${COMMENT_MARKER}\n**[${f.severity} · ${f.scope}] · ${f.category}** — ${f.title}`];
  parts.push(String(f.body).trim());
  if (f.suggestion) parts.push('```suggestion\n' + String(f.suggestion).replace(/\n$/, '') + '\n```');
  return parts.join('\n\n');
}

function validate(findings) {
  findings.forEach((f, i) => {
    const missing = ['path', 'line', 'severity', 'scope', 'category', 'title', 'body'].filter((k) => !f[k]);
    if (missing.length) throw new Error(`finding #${i} missing ${missing.join(', ')}`);
    if (!SEVERITIES.includes(f.severity)) throw new Error(`finding #${i} has unknown severity ${f.severity}`);
    if (!SCOPES.includes(f.scope)) throw new Error(`finding #${i} has unknown scope ${f.scope}`);
  });
}

function splitFindings(findings, validLines) {
  const inline = [];
  const orphans = [];
  for (const f of findings) {
    const lines = validLines[f.path];
    const start = f.start_line ?? f.line;
    let ok = Boolean(lines);
    for (let l = start; ok && l <= f.line; l += 1) ok = lines.has(l);
    (ok ? inline : orphans).push(f);
  }
  return { inline, orphans };
}

function buildBody(data, counts, orphans, openBlocking) {
  const lines = [
    data.handoff
      ? `## 🤖 AI review — round ${data.round}: handing off to a human`
      : `## 🤖 AI review — round ${data.round}`,
    String(data.summary ?? '').trim(),
    `**Findings:** ${counts.blocking} blocking · ${counts['should-fix']} should-fix · ${counts.nit} nit — ` +
      `**open blocking (incl. previous rounds): ${openBlocking}**`,
  ];
  if (data.areas?.length) lines.push(`**Areas covered:** ${data.areas.join(', ')}`);
  if (orphans.length) {
    lines.push('### Findings outside the diff');
    for (const f of orphans) {
      lines.push(`- **[${f.severity} · ${f.scope}]** \`${f.path}:${f.line}\` — ${f.title}: ${f.body}`);
    }
  }
  lines.push(
    buildReviewMarker({ round: data.round, sha: data.commit_id, blocking: openBlocking, handoff: !!data.handoff }),
  );
  return lines.join('\n\n');
}

runMain(() => {
  const [path, ...flags] = process.argv.slice(2);
  if (!path || !existsSync(path)) throw new Error('Usage: node post_review.mjs FINDINGS_JSON [--dry-run]');
  const dryRun = flags.includes('--dry-run');

  const data = JSON.parse(readFileSync(path, 'utf8'));
  const number = Number(data.pr);
  if (!number || !data.commit_id || !data.round) throw new Error('findings file needs pr, commit_id and round');
  const findings = data.handoff ? [] : (data.findings ?? []);
  validate(findings);

  const { inline, orphans } = splitFindings(findings, commentableLines(number));
  const counts = Object.fromEntries(SEVERITIES.map((s) => [s, findings.filter((f) => f.severity === s).length]));
  const openBlocking = counts.blocking + Number(data.carried_blocking ?? 0);
  const resolve = data.resolve ?? [];
  const replies = data.replies ?? [];

  const review = {
    commit_id: data.commit_id,
    event: 'COMMENT',
    body: buildBody(data, counts, orphans, openBlocking),
    comments: inline.map((f) => ({
      path: f.path,
      line: f.line,
      side: 'RIGHT',
      body: formatComment(f),
      ...(f.start_line && f.start_line < f.line ? { start_line: f.start_line, start_side: 'RIGHT' } : {}),
    })),
  };

  if (dryRun) {
    console.log(JSON.stringify({ resolve, replies, review, moved_to_body: orphans.length }, null, 2));
  } else {
    for (const id of resolve) graphql(RESOLVE_MUTATION, { id });
    for (const reply of replies) {
      gh([
        'api',
        `repos/${repo()}/pulls/${number}/comments/${reply.comment_id}/replies`,
        '--method',
        'POST',
        '-f',
        `body=${REPLY_MARKER}\n${reply.body}`,
      ]);
    }
    const result = ghJson(['api', `repos/${repo()}/pulls/${number}/reviews`, '--method', 'POST', '--input', '-'], {
      input: JSON.stringify(review),
    });
    console.log(`Posted review ${result.html_url}`);
    console.log(
      `Inline: ${inline.length} · in body: ${orphans.length} · resolved: ${resolve.length} · ` +
        `replies: ${replies.length} · open blocking: ${openBlocking}`,
    );
  }

  if (data.handoff) return 3;
  return openBlocking > 0 ? 2 : 0;
});
