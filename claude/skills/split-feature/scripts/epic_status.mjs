#!/usr/bin/env node
// Prints an epic's sub-issues as JSON with their "blocked by" links, which ones are ready to implement (open, every
// blocker closed as completed), which are stuck behind a blocker closed as not planned, and whether the dependency
// graph has a cycle. Shared by split-feature (verify the graph it
// created), close-feature (is everything closed?) and whoever picks the next issue to implement.
//
// Usage: node epic_status.mjs EPIC_NUMBER

import { ghJson, repo, runMain } from '../../pr-review/scripts/github.mjs';

const api = (path) => ghJson(['api', '--paginate', '--slurp', path]).flat();

function findCycle(nodes) {
  const state = new Map(); // number -> 'visiting' | 'done'
  const byNumber = new Map(nodes.map((n) => [n.number, n]));
  const visit = (n, path) => {
    if (state.get(n.number) === 'done') return null;
    if (state.get(n.number) === 'visiting') return [...path.slice(path.indexOf(n.number)), n.number];
    state.set(n.number, 'visiting');
    for (const b of n.blocked_by) {
      const next = byNumber.get(b.number);
      const cycle = next && visit(next, [...path, n.number]);
      if (cycle) return cycle;
    }
    state.set(n.number, 'done');
    return null;
  };
  for (const n of nodes) {
    const cycle = visit(n, []);
    if (cycle) return cycle;
  }
  return null;
}

runMain(() => {
  const epic = Number(process.argv[2]);
  if (!epic) throw new Error('Usage: node epic_status.mjs EPIC_NUMBER');
  const r = repo();

  const subs = api(`repos/${r}/issues/${epic}/sub_issues?per_page=100`).map((s) => {
    const blockedBy = api(`repos/${r}/issues/${s.number}/dependencies/blocked_by?per_page=100`).map((b) => ({
      number: b.number,
      state: b.state,
      state_reason: b.state_reason ?? null,
      in_epic: false,
    }));
    return { number: s.number, title: s.title, state: s.state, url: s.html_url, blocked_by: blockedBy };
  });

  // A blocker closed as "not planned" never delivered what the slice depends on: it doesn't unblock it.
  const notPlanned = (b) => b.state === 'closed' && b.state_reason === 'not_planned';
  const inEpic = new Set(subs.map((s) => s.number));
  for (const s of subs) {
    for (const b of s.blocked_by) b.in_epic = inEpic.has(b.number);
    s.stuck = s.state === 'open' && s.blocked_by.some(notPlanned);
    s.ready = s.state === 'open' && s.blocked_by.every((b) => b.state === 'closed' && !notPlanned(b));
  }

  const open = subs.filter((s) => s.state === 'open');
  console.log(
    JSON.stringify(
      {
        epic,
        total: subs.length,
        open: open.length,
        all_closed: subs.length > 0 && open.length === 0,
        ready: subs.filter((s) => s.ready).map((s) => s.number),
        blocked: open.filter((s) => !s.ready && !s.stuck).map((s) => s.number),
        stuck: open.filter((s) => s.stuck).map((s) => s.number),
        cycle: findCycle(subs),
        external_blockers: [
          ...new Set(subs.flatMap((s) => s.blocked_by.filter((b) => !b.in_epic).map((b) => b.number))),
        ],
        sub_issues: subs,
      },
      null,
      2,
    ),
  );
});
