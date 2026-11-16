#!/usr/bin/env node
// Prints the unresolved review threads of a PR as JSON, flags the ones that still need a fixer answer (the last
// comment is not a fixer reply), and recommends the fixer's model and effort for this round.
//
// Usage: node open_threads.mjs [PR_NUMBER]

import {
  COMMENT_MARKER,
  FIX_MARKER,
  fetchPullRequest,
  lastReviewMarker,
  prNumberFromArgs,
  repo,
  runMain,
  scopeOf,
  severityOf,
} from '../../pr-review/scripts/github.mjs';

const NON_CONVERGING_AFTER_ROUNDS = 2;

function serialize(thread) {
  const comments = thread.comments.nodes;
  const first = comments[0];
  const aiReview = first.body.includes(COMMENT_MARKER);
  return {
    thread_id: thread.id,
    comment_id: first.databaseId,
    path: thread.path,
    line: thread.line ?? thread.originalLine,
    outdated: thread.isOutdated,
    source: aiReview ? 'ai-review' : 'human',
    severity: aiReview ? severityOf(first.body) : null,
    scope: aiReview ? scopeOf(first.body) : null,
    needs_answer: !comments.at(-1).body.includes(FIX_MARKER),
    comments: comments.map((c) => ({
      author: c.author?.login,
      body: c.body.replace(COMMENT_MARKER, '').trim(),
      at: c.createdAt,
    })),
  };
}

// Severity alone doesn't size a change: a blocking comment can be a one-liner. Route on both.
function recommendFixer(toAnswer, reviewRounds) {
  if (!toAnswer.length) return null;
  const reasons = [];
  if (toAnswer.some((t) => t.severity === 'blocking')) reasons.push('blocking comment');
  if (toAnswer.some((t) => t.scope === 'cross-cutting')) reasons.push('cross-cutting comment');
  if (reviewRounds >= NON_CONVERGING_AFTER_ROUNDS) reasons.push(`not converging after ${reviewRounds} rounds`);
  return reasons.length
    ? { model: 'opus', effort: 'high', reasons }
    : { model: 'sonnet', effort: 'medium', reasons: ['only local should-fix / nit / human comments'] };
}

runMain(() => {
  const number = prNumberFromArgs(process.argv.slice(2));
  const { pull, threads } = fetchPullRequest(number);
  const openThreads = threads.filter((t) => !t.isResolved && t.comments.nodes.length).map(serialize);
  const toAnswer = openThreads.filter((t) => t.needs_answer);
  const reviewRounds = Number(lastReviewMarker(pull)?.round ?? 0);

  console.log(
    JSON.stringify(
      {
        repo: repo(),
        pr: number,
        title: pull.title,
        head_ref: pull.headRefName,
        head_sha: pull.headRefOid,
        review_rounds: reviewRounds,
        to_answer_count: toAnswer.length,
        has_cross_cutting: toAnswer.some((t) => t.scope === 'cross-cutting'),
        recommended_fixer: recommendFixer(toAnswer, reviewRounds),
        open_threads: openThreads,
      },
      null,
      2,
    ),
  );
});
