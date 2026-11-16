---
name: split-feature
description: Split an epic GitHub issue into sub-issues that can each be implemented, reviewed (pr-loop) and merged on their own into the epic branch — API contract slices first, ordering expressed as GitHub "blocked by" links so independent slices run in parallel and only unblocked ones get picked. Creates the epic branch and the sub-issues after the user approves the plan. Use whenever the user asks to split, slice, break down or plan an epic / feature issue into tasks or sub-issues, or "prepare issue 42 for implementation". Do NOT use it to detail the epic itself (grill-me) or to implement a slice.
---

# Split Feature

Input: an epic issue number (or URL). Output: an epic branch and a set of sub-issues, linked to the epic as GitHub
sub-issues and to each other with "blocked by" links. The links are the plan: whoever implements picks only open
sub-issues whose blockers are all closed, and runs independent ones in parallel. Never write the order in prose.

Pipeline this skill sits in: `grill-me` (epic body) → **split-feature** → implement each ready sub-issue → `pr-loop`
on its PR → merge into the epic branch → … → `close-feature`.

## 1. Check the epic

```bash
gh issue view <epic> --json number,title,body,state,labels,subIssues,parent
```

Stop and say why if:

- The issue is closed, or is itself a sub-issue (`parent` set).
- It already has sub-issues. Offer a **re-plan** instead: show the existing graph (`epic_status.mjs`, below), and only
  add missing slices or links on approval; never duplicate or delete existing ones.
- The body lacks testable acceptance criteria, or leaves open questions that change the slicing (scope, API shape,
  data model). Suggest running `grill-me` on the issue first. Don't fill the gaps yourself.

The body is the spec (not the comments). Note its acceptance criteria and its related ADRs.

## 2. Read before slicing

- Every ADR the epic links, and its status **on the epic branch** if it exists (`grill-me` accepts ADRs there,
  before `main` has them). If the epic relies on an ADR that is still **Proposed**, stop: the reviewer flags code
  that implements a Proposed ADR, so send the user back to `grill-me` to get it accepted first.
- The project's ADR rules (`docs/adrs/README.md`), architecture overview, and `docs/review.md`: its `areas` map tells
  you which areas, docs and `.claude/rules/` files each slice will touch.
- The code the epic touches (explore it; don't ask what the codebase answers). Check whether the contract tooling
  exists yet (rswag, `contracts:generate`); if not, the contract slice is the request spec plus the endpoint.
- The roadmap: anything it schedules later is out of scope for every slice.

## 3. Design the slices

Each slice is one PR into the epic branch that CI passes on its own and leaves the epic branch working:

- **Small.** Under ~500 changed lines (the project's PR guideline), one concern, one reviewer pass. Split bigger.
- **Independently mergeable.** No half-built code that only compiles with a later slice. A feature flag or an
  unreachable screen is fine; a broken build or a failing test is not.
- **Testable.** Each slice has its own acceptance criteria and the tests that prove them.

Ordering — add a "blocked by" link only for a real dependency, so the most slices can run in parallel:

1. **Contract before consumer.** A slice that changes the API (endpoint, request/response shape, auth) lands the
   contract first — rswag request specs and the endpoint, plus the regenerated OpenAPI and TS types when the tooling
   exists. The mobile slice that calls it is blocked by that contract slice. One contract slice per endpoint group,
   so mobile work on another endpoint is not held up.
2. **Schema before use.** Backend migrations/models before the endpoints that use them; Drizzle schema and migration
   before the mobile features that read them. A synced table needs both sides; follow the sync ADR's order.
3. **Shared files serialise.** Two slices that edit the same files (routes, schema, a shared component) would
   conflict when run in parallel: chain them, or move the shared edit into the earlier slice.
4. **Docs travel with the code.** Each slice updates the docs its change affects. ADRs are already accepted
   (`grill-me`); a slice that finds it must diverge from one amends it in its own PR, with the user's approval.
5. No slice for "tests" or "docs" alone, and no final "integration" slice: `close-feature` checks the epic end to
   end.

Check coverage: every epic acceptance criterion maps to at least one slice; every slice traces to a criterion or to
a prerequisite of one. Anything left over is out of scope — say so rather than invent a slice.

## 4. Present the plan, then wait

Show, before creating anything:

- Epic branch name: `feature/<epic>-<slug>` from `main` (per the project's git workflow).
- A table: local id (S1, S2…), title, stack (backend / mobile / contracts / docs), blocked by (local ids),
  epic criteria covered, rough size.
- The dependency graph as a Mermaid `graph LR`, and the first wave (slices with no blockers) that can start in
  parallel.
- Criteria → slices coverage, and anything out of scope.
- Risks: missing tooling, slices close to the size limit.

Ask the user to approve or adjust. Creating issues and pushing a branch are visible to others: don't do either before
the user says yes.

## 5. Create

1. **Epic branch**, unless it exists (`grill-me` creates it when it accepts an ADR; reuse it as is):
   `git fetch origin && git switch -c feature/<epic>-<slug> origin/main && git push -u origin HEAD`, then switch
   back to where the user was.
2. **Sub-issues, in topological order** (blockers first), so every blocker has a number when it is referenced:

   ```bash
   gh issue create --title "<title>" --body-file <tmp>/S<k>.md --parent <epic> [--blocked-by <n>,<n>]
   ```

   `<tmp>` = `${TMPDIR:-/tmp}/split-feature/<epic>/`. Record S-id → issue number as you go.

Sub-issue body (the implementer reads only this and what it links; keep it self-contained, link instead of
restating):

```markdown
Part of #<epic> · epic branch `feature/<epic>-<slug>`

## Goal
One or two sentences: what this slice delivers and why.

## Scope
- In: …
- Out: … (and which sibling sub-issue covers it, as #n)

## Contract
<Only for slices that change or consume the API.> Endpoint, method, request/response shape in outline. For a
consumer slice: "Uses the contract from #n" — the request spec / generated types are the source of truth.

## Read first
- ADRs: the subset that governs this slice, linked (not the epic's whole list)
- Areas (docs/review.md): … — their docs and `.claude/rules/` files apply

## Acceptance criteria
- [ ] Testable statements, each covered by a test in this PR

## Verify
Commands from docs/review.md `verify` for the paths this slice touches.

## Done when
PR from `feature/<this>-<slug>` (branched from the epic branch) is merged into `feature/<epic>-<slug>` after
`pr-loop`. The PR body says `Closes #<this>`: the "Close linked issues" workflow closes this issue on merge into
the epic branch (GitHub alone only does it for `main`), which makes the slices it blocks ready.
```

Don't write "blocked by" in the body: the GitHub links are the only source of the order.

## 6. Verify and report

```bash
node <skill_dir>/scripts/epic_status.mjs <epic>
```

Check: `total` equals the number of planned slices, `cycle` is `null`, every planned link is present in
`sub_issues[].blocked_by`, `ready` equals the planned first wave. Fix any gap with
`gh issue edit <n> --add-blocked-by <m>` or `--parent <epic>`.

Report: epic branch, sub-issue list with links, the ready set (what can start now, in parallel), and the next step —
implement a ready sub-issue on its own branch from the epic branch, open its PR against the epic branch, run
`pr-loop`. After the last one merges, run `close-feature`.
