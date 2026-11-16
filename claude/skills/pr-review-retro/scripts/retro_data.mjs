#!/usr/bin/env node
// Collects review outcomes from one or more PRs, for the review retro: what the AI reviewer flagged and what became
// of it, and what humans flagged that the AI didn't.
//
// Usage: node retro_data.mjs PR_NUMBER [PR_NUMBER...]
//        node retro_data.mjs --merged N        (last N merged PRs)

import {
  AGENT_MARKERS,
  COMMENT_MARKER,
  FIX_MARKER,
  fetchPullRequest,
  ghJson,
  lastReviewMarker,
  repo,
  runMain,
  scopeOf,
  severityOf,
} from '../../pr-review/scripts/github.mjs';

const isAgent = (body) => AGENT_MARKERS.some((m) => body.includes(m));
const strip = (body) => AGENT_MARKERS.reduce((b, m) => b.replace(m, ''), body).trim();
const category = (body) => body.match(/\*\*\[[^\]]+\] · ([a-z/-]+)\*\*/)?.[1] ?? null;
const title = (body) => strip(body).split('\n')[0].replace(/^\*\*\[[^\]]+\] · [a-z/-]+\*\* — /, '');

function aiOutcome(thread, prClosed) {
  const fixes = thread.comments.nodes.filter((c) => c.body.includes(FIX_MARKER)).map((c) => strip(c.body));
  const last = fixes.at(-1) ?? '';
  if (thread.isResolved && last.startsWith('Fixed in ')) return 'fixed';
  if (thread.isResolved && last.startsWith("Won't fix: ")) return 'pushback_accepted';
  if (thread.isResolved) return 'resolved_other';
  return prClosed ? 'open_at_close' : 'open';
}

function analyzePr(number) {
  const { pull, threads } = fetchPullRequest(number);
  const prClosed = pull.state !== 'OPEN';
  const ai = [];
  const human = [];

  for (const thread of threads) {
    const comments = thread.comments.nodes;
    if (!comments.length) continue;
    const first = comments[0];
    const base = { path: thread.path, line: thread.line ?? thread.originalLine, resolved: thread.isResolved };

    if (first.body.includes(COMMENT_MARKER)) {
      ai.push({
        ...base,
        severity: severityOf(first.body),
        scope: scopeOf(first.body),
        category: category(first.body),
        title: title(first.body),
        outcome: aiOutcome(thread, prClosed),
        fixer_replies: comments.filter((c) => c.body.includes(FIX_MARKER)).map((c) => strip(c.body)),
        human_comments: comments.filter((c) => !isAgent(c.body)).map((c) => ({ author: c.author?.login, body: c.body })),
      });
    } else if (!isAgent(first.body)) {
      human.push({
        ...base,
        author: first.author?.login,
        at: first.createdAt,
        body: first.body,
        ai_replies: comments.slice(1).filter((c) => isAgent(c.body)).map((c) => strip(c.body)),
      });
    }
  }

  const last = lastReviewMarker(pull);
  return {
    pr: number,
    url: pull.url,
    title: pull.title,
    state: pull.state,
    merged_at: pull.mergedAt,
    ai_rounds: last ? Number(last.round) : 0,
    handoff: last?.handoff === 'true',
    ai_findings: ai,
    human_findings: human,
  };
}

function summarize(prs) {
  const all = prs.flatMap((p) => p.ai_findings);
  const count = (key) => all.reduce((acc, f) => ({ ...acc, [f[key]]: (acc[f[key]] ?? 0) + 1 }), {});
  return {
    prs: prs.length,
    ai_findings: all.length,
    by_outcome: count('outcome'),
    by_severity: count('severity'),
    by_category: count('category'),
    pushback_accepted_rate: all.length
      ? Number((all.filter((f) => f.outcome === 'pushback_accepted').length / all.length).toFixed(2))
      : null,
    human_findings: prs.reduce((n, p) => n + p.human_findings.length, 0),
    ai_threads_with_human_comments: all.filter((f) => f.human_comments.length).length,
    handoffs: prs.filter((p) => p.handoff).length,
  };
}

runMain(() => {
  const args = process.argv.slice(2);
  let numbers;
  if (args[0] === '--merged') {
    const limit = String(Number(args[1] ?? 10));
    numbers = ghJson(['pr', 'list', '--state', 'merged', '--limit', limit, '--json', 'number']).map((p) => p.number);
  } else {
    numbers = args.filter((a) => /^\d+$/.test(a)).map(Number);
  }
  if (!numbers.length) throw new Error('Usage: node retro_data.mjs PR_NUMBER... | --merged N');

  const prs = numbers.map(analyzePr);
  console.log(JSON.stringify({ repo: repo(), summary: summarize(prs), prs }, null, 2));
});
