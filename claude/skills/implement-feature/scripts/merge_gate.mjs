#!/usr/bin/env node
// Decides whether implement-feature may merge a PR into the epic branch on its own, or must stop for a human.
// Prints JSON { verdict: "merge" | "stop", reasons, notes, ... } and exits 0 (merge), 2 (stop) or 1 (error).
//
// Usage: node merge_gate.mjs PR_NUMBER --base EPIC_BRANCH [--issue SUB_ISSUE] [--sync] [--guide PATH]
// --guide reads the policy from a local file instead (for testing).
//
// The policy comes from the `auto_merge` key of the docs/review.md front matter, read from the default branch so one
// policy applies to every epic branch whatever its age:
//
//   auto_merge:
//     stop_on_paths: ["docs/adrs/**"]   # a diff touching these stops (ADRs, Decision Log)
//     stop_on_wont_fix: true            # a `Won't fix:` answer on a blocking / should-fix thread stops
//
// No `auto_merge` key: auto-merge is off, the verdict is always "stop".
// --sync (a sync PR merging the default branch into the epic): the path check is skipped, the code is already on
// the default branch.

import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  COMMENT_MARKER,
  FIX_MARKER,
  fetchPullRequest,
  gh,
  ghJson,
  repo,
  reviewMarkers,
  runMain,
  severityOf,
} from '../../pr-review/scripts/github.mjs';

function parseArgs(argv) {
  const args = { pr: null, base: null, issue: null, sync: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--base') args.base = argv[++i];
    else if (a === '--issue') args.issue = Number(argv[++i]);
    else if (a === '--sync') args.sync = true;
    else if (a === "--guide") args.guide = argv[++i];
    else if (/^\d+$/.test(a)) args.pr = Number(a);
  }
  if (!args.pr || !args.base) throw new Error('Usage: node merge_gate.mjs PR_NUMBER --base EPIC_BRANCH [--issue N] [--sync]');
  return args;
}

function reviewGuide(defaultBranch, override) {
  if (override) return { text: readFileSync(override, "utf8"), source: override };
  const res = spawnSync('git', ['show', `origin/${defaultBranch}:docs/review.md`], { encoding: 'utf8' });
  if (res.status === 0) return { text: res.stdout, source: `origin/${defaultBranch}:docs/review.md` };
  const local = join(process.cwd(), 'docs', 'review.md');
  return existsSync(local) ? { text: readFileSync(local, 'utf8'), source: 'docs/review.md (working tree)' } : null;
}

// Reads the `auto_merge:` block (one level of `key: value`, values are JSON-style lists or booleans).
function autoMergeConfig(guide) {
  const frontMatter = guide?.text.match(/^---\n([\s\S]*?)\n---/)?.[1];
  if (!frontMatter) return null;
  const lines = frontMatter.split('\n');
  const start = lines.findIndex((l) => /^auto_merge:\s*$/.test(l));
  if (start === -1) return null;
  const config = { stop_on_paths: [], stop_on_wont_fix: false };
  for (const line of lines.slice(start + 1)) {
    if (!/^\s+/.test(line)) break;
    const m = line.match(/^\s+([a-z_]+):\s*(.+?)\s*(#.*)?$/);
    if (!m) continue;
    const [, key, raw] = m;
    config[key] = raw === 'true' ? true : raw === 'false' ? false : JSON.parse(raw);
  }
  return config;
}

function globToRegExp(glob) {
  let re = '';
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === '*' && glob[i + 1] === '*') {
      i++;
      if (glob[i + 1] === '/') {
        i++;
        re += '(?:.*/)?';
      } else re += '.*';
    } else if (c === '*') re += '[^/]*';
    else if (c === '?') re += '[^/]';
    else if (c === '{') {
      const end = glob.indexOf('}', i);
      re += `(?:${glob
        .slice(i + 1, end)
        .split(',')
        .map((s) => s.replace(/[.+^$()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]*'))
        .join('|')})`;
      i = end;
    } else re += c.replace(/[.+^$()|[\]\\]/g, '\\$&');
  }
  return new RegExp(`^${re}$`);
}

const fixReplies = (thread) =>
  thread.comments.nodes.filter((c) => c.body.includes(FIX_MARKER)).map((c) => c.body.replace(FIX_MARKER, '').trim());

runMain(() => {
  const args = parseArgs(process.argv.slice(2));
  const r = repo();
  const reasons = [];
  const notes = [];

  const view = ghJson([
    'pr', 'view', String(args.pr),
    '--json', 'state,baseRefName,headRefName,headRefOid,mergeable,reviewDecision,body,title,url',
  ]);
  const defaultBranch = ghJson(['repo', 'view', '--json', 'defaultBranchRef']).defaultBranchRef.name;

  // Policy
  const guide = reviewGuide(defaultBranch, args.guide);
  const config = autoMergeConfig(guide);
  if (!config) reasons.push('auto-merge is off: no `auto_merge` key in the docs/review.md front matter');

  // PR state
  if (view.state !== 'OPEN') reasons.push(`PR is ${view.state}`);
  if (view.baseRefName !== args.base) reasons.push(`PR targets ${view.baseRefName}, not ${args.base}`);
  if (view.baseRefName === defaultBranch) reasons.push('PR targets the default branch: never auto-merged');
  if (view.mergeable === 'CONFLICTING') reasons.push('PR has merge conflicts');
  else if (view.mergeable !== 'MERGEABLE') reasons.push(`mergeability is ${view.mergeable}: retry in a minute`);
  if (view.reviewDecision === 'CHANGES_REQUESTED') reasons.push('a reviewer requested changes');
  if (args.issue && !new RegExp(`\\b(close[sd]?|fix(e[sd])?|resolve[sd]?)\\s+#${args.issue}\\b`, 'i').test(view.body)) {
    reasons.push(`PR body lacks \`Closes #${args.issue}\``);
  }

  // Review loop outcome
  const { pull, threads } = fetchPullRequest(args.pr);
  const last = reviewMarkers(pull).at(-1);
  if (!last) reasons.push('no AI review round on this PR');
  else {
    if (last.sha !== view.headRefOid) reasons.push(`last review round (${last.round}) did not see the head commit`);
    if (Number(last.blocking ?? 0) > 0) reasons.push(`last review round left ${last.blocking} blocking open`);
  }

  const wontFix = [];
  for (const t of threads) {
    const first = t.comments.nodes[0];
    if (!first) continue;
    const ai = first.body.includes(COMMENT_MARKER);
    const severity = ai ? severityOf(first.body) : null;
    const replies = fixReplies(t);
    const lastIsFix = t.comments.nodes.at(-1).body.includes(FIX_MARKER);
    if (!ai && !t.isResolved) reasons.push(`open human thread by ${first.author?.login}: ${first.url}`);
    if (ai && !t.isResolved && severity === 'blocking') reasons.push(`open blocking thread: ${first.url}`);
    if (ai && !t.isResolved && severity === 'should-fix' && !lastIsFix) {
      reasons.push(`unanswered should-fix thread: ${first.url}`);
    }
    if (!t.isResolved && replies.at(-1)?.startsWith('Question:')) reasons.push(`open question for a human: ${first.url}`);
    if (ai && ['blocking', 'should-fix'].includes(severity) && replies.some((b) => b.startsWith("Won't fix:"))) {
      wontFix.push({ severity, url: first.url, resolved: t.isResolved });
    }
  }
  if (wontFix.length) {
    if (config?.stop_on_wont_fix) {
      for (const w of wontFix) reasons.push(`risk flag: "Won't fix" on a ${w.severity} thread: ${w.url}`);
    } else notes.push(`${wontFix.length} "Won't fix" answer(s) on blocking / should-fix threads`);
  }

  // Risk flag: paths
  const files = ghJson(['api', '--paginate', '--slurp', `repos/${r}/pulls/${args.pr}/files?per_page=100`])
    .flat()
    .map((f) => f.filename);
  if (!args.sync && config?.stop_on_paths?.length) {
    const patterns = config.stop_on_paths.map((g) => [g, globToRegExp(g)]);
    for (const f of files) {
      const hit = patterns.find(([, re]) => re.test(f));
      if (hit) reasons.push(`risk flag: touches ${f} (${hit[0]})`);
    }
  }

  // CI on the head commit
  // `gh pr checks` exits non-zero when checks fail or are pending, and prints nothing when there are none.
  const checksOut = gh(['pr', 'checks', String(args.pr), '--json', 'name,bucket'], { allowFailure: true }).trim();
  const checks = checksOut ? JSON.parse(checksOut) : [];
  if (!checks.length) notes.push('no CI checks reported for this PR');
  for (const c of checks) {
    if (c.bucket === 'pending') reasons.push(`check pending: ${c.name}`);
    else if (!['pass', 'skipping'].includes(c.bucket)) reasons.push(`check ${c.bucket}: ${c.name}`);
  }

  const verdict = reasons.length ? 'stop' : 'merge';
  console.log(
    JSON.stringify(
      {
        pr: args.pr,
        url: view.url,
        title: view.title,
        head_sha: view.headRefOid,
        sync: args.sync,
        policy_source: guide?.source ?? null,
        policy: config,
        review_rounds: Number(last?.round ?? 0),
        files_changed: files.length,
        checks: checks.length,
        verdict,
        reasons,
        notes,
      },
      null,
      2,
    ),
  );
  return verdict === 'merge' ? 0 : 2;
});
