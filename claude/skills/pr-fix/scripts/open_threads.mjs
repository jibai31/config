#!/usr/bin/env node
// Prints the unresolved review threads of a PR as JSON, flags the ones that still need a fixer answer (the last
// comment is not a fixer reply), and recommends the fixer's model and effort for this round.
//
// Usage: node open_threads.mjs [PR_NUMBER]

import {
  COMMENT_MARKER,
  FIX_MARKER,
  fetchPullRequest,
  prNumberFromArgs,
  repo,
  reviewMarkers,
  runMain,
  scopeOf,
  severityOf,
} from '../../pr-review/scripts/github.mjs';

const openCount = (marker) => Number(marker.blocking ?? 0) + Number(marker.should_fix ?? 0);

// Not converging: the last review round left at least as many blocking + should-fix threads open as the one before.
function convergence(markers) {
  const [previous, last] = markers.slice(-2);
  if (!previous || !last) return null;
  const [before, after] = [openCount(previous), openCount(last)];
  return { previous_open: before, last_open: after, converging: after < before };
}

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
    url: first.url,
    comments: comments.map((c) => ({
      author: c.author?.login,
      body: c.body.replace(COMMENT_MARKER, '').trim(),
      at: c.createdAt,
    })),
  };
}

// Severity alone doesn't size a change: a blocking comment can be a one-liner. Route on severity, scope and
// convergence.
function recommendFixer(toAnswer, conv) {
  if (!toAnswer.length) return null;
  const reasons = [];
  if (toAnswer.some((t) => t.severity === 'blocking')) reasons.push('blocking comment');
  if (toAnswer.some((t) => t.scope === 'cross-cutting')) reasons.push('cross-cutting comment');
  if (conv && !conv.converging) {
    reasons.push(`not converging (${conv.previous_open} → ${conv.last_open} blocking + should-fix open)`);
  }
  return reasons.length
    ? { model: 'opus', effort: 'high', reasons }
    : { model: 'sonnet', effort: 'medium', reasons: ['only local should-fix / nit / human comments'] };
}

runMain(() => {
  const number = prNumberFromArgs(process.argv.slice(2));
  const { pull, threads } = fetchPullRequest(number);
  const openThreads = threads.filter((t) => !t.isResolved && t.comments.nodes.length).map(serialize);
  const toAnswer = openThreads.filter((t) => t.needs_answer);
  const markers = reviewMarkers(pull);
  const conv = convergence(markers);

  console.log(
    JSON.stringify(
      {
        repo: repo(),
        pr: number,
        title: pull.title,
        head_ref: pull.headRefName,
        head_sha: pull.headRefOid,
        review_rounds: Number(markers.at(-1)?.round ?? 0),
        convergence: conv,
        to_answer_count: toAnswer.length,
        has_cross_cutting: toAnswer.some((t) => t.scope === 'cross-cutting'),
        recommended_fixer: recommendFixer(toAnswer, conv),
        // Unresolved threads a human opened: pr-loop reports them, since they don't hold the AI loop.
        human_threads: openThreads
          .filter((t) => t.source === 'human')
          .map((t) => ({
            path: t.path,
            line: t.line,
            author: t.comments[0]?.author,
            needs_answer: t.needs_answer,
            url: t.url,
          })),
        open_threads: openThreads,
      },
      null,
      2,
    ),
  );
});
