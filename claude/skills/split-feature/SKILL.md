---
name: split-feature
description: Split an epic GitHub issue into sub-issues that can each be implemented, reviewed (pr-loop) and merged on their own into the epic branch, one after the other — API contract slices first, ordering expressed as GitHub "blocked by" links and issue numbers so only unblocked ones get picked. Creates the sub-issues (and the epic branch if missing) after the user approves the plan. Use whenever the user asks to split, slice, break down or plan an epic / feature issue into tasks or sub-issues. Do NOT use it to refine the need (grill-me), to write the epic spec or accept its ADRs (prepare-feature), or to implement a slice.
---

# Split Feature

Input: an epic issue number (or URL). Output: an epic branch and a set of sub-issues, linked to the epic as GitHub
sub-issues and to each other with "blocked by" links. Sub-issues are implemented **sequentially**: one at a time,
each branched from the epic branch after the previous one merged, so each builds on the last and they never conflict.
The links and the issue numbers are the plan: `implement-issue` picks the lowest-numbered open sub-issue whose
blockers are all closed. Never write the order in prose.

Pipeline this skill sits in: `grill-me` → `prepare-feature` (epic body, ADRs) → **split-feature** →
`implement-issue` on each ready sub-issue → `pr-loop` on its PR → merge into the epic branch → … → `close-feature`.

## 1. Check the epic

```bash
gh issue view <epic> --json number,title,body,state,labels,subIssues,parent
```

Stop and say why if:

- The issue is closed, or is itself a sub-issue (`parent` set).
- It already has sub-issues. Offer a **re-plan** instead: show the existing graph (`epic_status.mjs`, below), and only
  add missing slices or links on approval; never duplicate or delete existing ones.
- The body lacks testable acceptance criteria, or leaves open questions that change the slicing (scope, API shape,
  data model). Suggest running `prepare-feature` on the issue first. Don't fill the gaps yourself.

The body is the spec (not the comments). Note its acceptance criteria and its related ADRs.

`<default>` = the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`). Check the "Close
linked issues" workflow is on it (`git ls-tree origin/<default> .github/workflows/close-linked-issues.yml`). If not,
warn: sub-issues won't close when their PR merges into the epic branch, so the next one never becomes ready. Point to
`<skill_dir>/assets/close-linked-issues.yml` (`prepare-feature` offers to add it); if the user goes on without it,
say each sub-issue must be closed by hand after its merge.

## 2. Read before slicing

- Every ADR the epic links, and its status **on the epic branch** if it exists (`prepare-feature` accepts ADRs there
  through a PR, before the default branch has them). If the epic relies on an ADR that is still **Proposed** there,
  stop: the reviewer flags code that implements a Proposed ADR. If `prepare-feature`'s ADR PR (`docs/<epic>-adrs`) is
  still open, say it must be merged first; otherwise send the user back to `prepare-feature`.
- The project's ADR rules (`docs/adrs/README.md`), architecture overview, and `docs/review.md`: its `areas` map tells
  you which areas, docs and `.claude/rules/` files each slice will touch.
- The code the epic touches (explore it; don't ask what the codebase answers). Check whether the contract tooling
  exists yet (`docs/review.md` front matter: a `generate` entry for the contract tests and a non-empty
  `contracts_check`); if not, the contract slice is the contract tests plus the endpoint.
- The roadmap, if the project has one: anything it schedules later is out of scope for every slice.

## 3. Design the slices

Each slice is one PR into the epic branch that CI passes on its own and leaves the epic branch working:

- **Small.** Within the project's PR size guideline (`CLAUDE.md`; ~500 changed lines if none), one concern, one
  reviewer pass. Split bigger.
- **Independently mergeable.** No half-built code that only compiles with a later slice. A feature flag or an
  unreachable screen is fine; a broken build or a failing test is not.
- **Testable.** Each slice has its own acceptance criteria and the tests that prove them.

Ordering — slices run one at a time in issue-number order, so create them in the order you want them built. Add a
"blocked by" link for each real dependency too: it keeps a re-plan or a manual pick from starting a slice too early.

1. **Contract before consumer.** A slice that changes the API (endpoint, request/response shape, auth) lands the
   contract first — contract tests and the endpoint, plus the regenerated contract files when the tooling exists
   (`generate`). The client slice that calls it is blocked by that contract slice. One contract slice per endpoint
   group.
2. **Schema before use.** Migrations/models before the code that reads them, on every side that stores data
   (server, client). When data spans several stores, follow the project's ADRs for the order.
3. **Docs travel with the code.** Each slice updates the docs its change affects. ADRs are already accepted
   (`prepare-feature`); a slice that finds it must diverge from one amends it in its own PR, with the user's approval.
4. No slice for "tests" or "docs" alone, and no final "integration" slice: `close-feature` checks the epic end to
   end.

Check coverage: every epic acceptance criterion maps to at least one slice; every slice traces to a criterion or to
a prerequisite of one. Anything left over is out of scope — say so rather than invent a slice.

## 4. Present the plan, then wait

Show, before creating anything:

- Epic branch: `feature/<epic>-<slug>` (normally created by `prepare-feature`; from `<default>` otherwise).
- A table, in build order: local id (S1, S2…), title, stack (a `stacks` entry from `docs/review.md`, contracts, or
  docs), blocked by (local ids), epic criteria covered, rough size.
- The dependency graph as a Mermaid `graph LR`.
- Criteria → slices coverage, and anything out of scope.
- Risks: missing tooling, slices close to the size limit.

Ask the user to approve or adjust. Creating issues and pushing a branch are visible to others: don't do either before
the user says yes.

## 5. Create

1. **Epic branch**, unless it exists (`prepare-feature` creates it; reuse it as is). Create it without checking it
   out: `git fetch origin && git push origin origin/<default>:refs/heads/feature/<epic>-<slug>`.
2. **Sub-issues, in build order** (blockers first), so issue numbers follow the build order and every blocker has a
   number when it is referenced:

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
consumer slice: "Uses the contract from #n" — the contract tests / generated contract files are the source of truth.

## Read first
- ADRs: the subset that governs this slice, linked (not the epic's whole list)
- Areas (docs/review.md): … — their docs and `.claude/rules/` files apply

## Acceptance criteria
- [ ] Testable statements, each covered by a test in this PR

## Verify
Commands from docs/review.md `verify` for the paths this slice touches.

## Done when
PR from `feature/<this>-<slug>` (branched from the epic branch) is merged into `feature/<epic>-<slug>` with a merge
commit after `pr-loop`. The PR body says `Closes #<this>`: the "Close linked issues" workflow closes this issue on
merge into the epic branch (GitHub alone only does it for the default branch), which makes the next slice ready.
```

Don't write "blocked by" in the body: the GitHub links are the only source of the order.

## 6. Verify and report

```bash
node <skill_dir>/scripts/epic_status.mjs <epic>
```

Check: `total` equals the number of planned slices, `cycle` is `null`, every planned link is present in
`sub_issues[].blocked_by`, and the lowest number in `ready` is S1. Fix any gap with
`gh issue edit <n> --add-blocked-by <m>` or `--parent <epic>`.

Report: epic branch, sub-issue list with links in build order, and the next step — `implement-issue <epic> next`
(it takes the first ready sub-issue, branches from the epic branch, PR against it), then `pr-loop` on its PR. A human
merges it with squash and merge; then the next one. After the last one merges, run `close-feature`.
