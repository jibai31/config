#!/usr/bin/env node
// Prints the review state of a PR as JSON: round number, last reviewed commit, open threads left by the
// reviewer (with the fixer's replies), changed files and CI status.
//
// Usage: node review_state.mjs [PR_NUMBER]

import {
  COMMENT_MARKER,
  FIX_MARKER,
  fetchPullRequest,
  gh,
  lastReviewMarker,
  maxRounds,
  prNumberFromArgs,
  repo,
  runMain,
  scopeOf,
  severityOf,
} from './github.mjs';

function ciChecks(number) {
  // `gh pr checks` exits non-zero when checks fail or are pending, so read stdout regardless.
  const out = gh(['pr', 'checks', String(number), '--json', 'name,state,bucket'], { allowFailure: true });
  try {
    const checks = JSON.parse(out);
    return {
      failing: checks.filter((c) => c.bucket === 'fail').map((c) => c.name),
      pending: checks.filter((c) => c.bucket === 'pending').map((c) => c.name),
      passing_count: checks.filter((c) => c.bucket === 'pass').length,
    };
  } catch {
    return { failing: [], pending: [], passing_count: 0, note: 'no CI checks reported' };
  }
}

function changedFiles(number) {
  return gh(['api', `repos/${repo()}/pulls/${number}/files`, '--paginate', '--jq', '.[] | .filename'])
    .split('\n')
    .filter(Boolean);
}

function openReviewerThreads(threads) {
  return threads
    .filter((t) => !t.isResolved)
    .map((t) => ({ thread: t, comments: t.comments.nodes }))
    .filter(({ comments }) => comments[0]?.body.includes(COMMENT_MARKER))
    .map(({ thread, comments }) => ({
      thread_id: thread.id,
      comment_id: comments[0].databaseId,
      path: thread.path,
      line: thread.line ?? thread.originalLine,
      outdated: thread.isOutdated,
      severity: severityOf(comments[0].body),
      scope: scopeOf(comments[0].body),
      comment: comments[0].body.replace(COMMENT_MARKER, '').trim(),
      awaiting_reviewer: comments.length > 1 && comments.at(-1).body.includes(FIX_MARKER),
      replies: comments.slice(1).map((c) => ({ author: c.author?.login, body: c.body, at: c.createdAt })),
    }));
}

runMain(() => {
  const number = prNumberFromArgs(process.argv.slice(2));
  const { pull, threads } = fetchPullRequest(number);
  const last = lastReviewMarker(pull);
  const previousRounds = last ? Number(last.round) : 0;
  const openThreads = openReviewerThreads(threads);

  const state = {
    repo: repo(),
    pr: number,
    title: pull.title,
    body: pull.body,
    head_ref: pull.headRefName,
    base_ref: pull.baseRefName,
    head_sha: pull.headRefOid,
    previous_rounds: previousRounds,
    next_round: previousRounds + 1,
    max_rounds: maxRounds(),
    last_reviewed_sha: last?.sha ?? null,
    new_commits_since_last_review: !last || last.sha !== pull.headRefOid,
    changed_files: changedFiles(number),
    open_threads: openThreads,
    open_blocking_count: openThreads.filter((t) => t.severity === 'blocking').length,
    threads_awaiting_reviewer: openThreads.filter((t) => t.awaiting_reviewer).length,
    ci_checks: ciChecks(number),
  };
  console.log(JSON.stringify(state, null, 2));
});
