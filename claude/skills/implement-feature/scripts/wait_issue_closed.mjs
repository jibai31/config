#!/usr/bin/env node
// After a sub-issue PR is merged into the epic branch: waits for the "Close linked issues" workflow to close the
// sub-issue (which unblocks the next ones), and closes it by hand if it is still open after the timeout.
// Prints JSON { issue, state, closed_by: "workflow" | "already" | "implement-feature" } and exits 0, or 1 on error.
//
// Usage: node wait_issue_closed.mjs ISSUE_NUMBER --pr PR_NUMBER [--timeout SECONDS]   (default 180)

import { gh, ghJson, runMain } from '../../pr-review/scripts/github.mjs';

const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);

runMain(() => {
  const argv = process.argv.slice(2);
  const issue = Number(argv.find((a) => /^\d+$/.test(a)));
  const opt = (name) => {
    const i = argv.indexOf(name);
    return i === -1 ? null : argv[i + 1];
  };
  const pr = Number(opt('--pr'));
  const timeout = Number(opt('--timeout') ?? 180);
  if (!issue || !pr) throw new Error('Usage: node wait_issue_closed.mjs ISSUE_NUMBER --pr PR_NUMBER [--timeout S]');

  const state = () => ghJson(['issue', 'view', String(issue), '--json', 'state']).state;
  if (state() === 'CLOSED') {
    console.log(JSON.stringify({ issue, state: 'CLOSED', closed_by: 'already' }));
    return 0;
  }
  const deadline = Date.now() + timeout * 1000;
  while (Date.now() < deadline) {
    sleep(10_000);
    if (state() === 'CLOSED') {
      console.log(JSON.stringify({ issue, state: 'CLOSED', closed_by: 'workflow' }));
      return 0;
    }
  }
  gh(['issue', 'close', String(issue), '--reason', 'completed', '--comment', `Closed by implement-feature: #${pr} merged into the epic branch.`]);
  console.log(JSON.stringify({ issue, state: state(), closed_by: 'implement-feature' }));
  return 0;
});
