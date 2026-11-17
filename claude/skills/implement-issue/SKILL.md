---
name: implement-issue
description: Implement a GitHub issue end to end — check it is ready (open, spec'd, every "blocked by" closed), branch from the right base (the epic branch for a sub-issue, main otherwise; sub-issues one at a time), read the ADRs, areas and coding rules it touches, write the tests for its acceptance criteria, implement, run the project's verify commands and check visible changes on device, commit, push and open the PR with `Closes #n`. Stops at the PR and hands over to pr-loop. Use whenever the user asks to implement, build, do, work on, pick up or "fix issue 42", or to take the next ready sub-issue of an epic. Do NOT use it to slice an epic (split-feature), to refine a need (grill-me) or write a spec (prepare-feature), to review or fix review comments (pr-review / pr-fix), or for a Sentry error (fix-sentry-issue).
---

# Implement Issue

Input: an issue number or URL, or an epic number with "next" (pick a ready sub-issue). Output: a pushed branch and
an open PR that closes the issue, ready for `pr-loop`.

Pipeline this skill sits in: `grill-me` → `prepare-feature` → `split-feature` → **implement-issue** (per
sub-issue, one at a time) → `pr-loop` → merge into the epic branch → next sub-issue → … → `close-feature`. A
standalone issue (no epic) goes straight to `main`.

Sub-issues of an epic are implemented **sequentially**, in the user's own checkout: the next one starts only once the
previous one's PR is merged into the epic branch, and branches from it, so each builds on the last.

The issue body is the spec. You implement it; you don't redesign it. When the spec is wrong or incomplete, stop and
say so rather than fill the gap yourself. On a sub-issue, the route back is: `grill-me` on the gap → `prepare-feature`
on the epic (amend its body, and its ADRs if needed) → `split-feature` in re-plan mode (amend or add sub-issues) →
`implement-issue` again.

Project-specific commands come from the `docs/review.md` front matter (`verify`, `generate`, `run_app`); a key that
is missing means the project has no such step.

## 1. Check the issue

```bash
gh issue view <n> --json number,title,body,state,labels,parent,subIssues
gh api "repos/{owner}/{repo}/issues/<n>/dependencies/blocked_by" --jq '.[] | {number, state, title}'
```

Given an epic and "next": run `node <split_feature_dir>/scripts/epic_status.mjs <epic>` and take the lowest number
in `ready` (sub-issues are numbered in build order), unless the user names another. `<split_feature_dir>` is the
`split-feature` skill directory, a sibling of this one. `ready` empty with `stuck` non-empty: a blocker was closed as
not planned; stop and point to `split-feature` re-plan.

Stop and say why if:

- The issue is closed, or a PR already closes it (`gh pr list --search "<n> in:body" --state all`).
- It is a sub-issue and another PR into the epic branch is still open
  (`gh pr list --base <epic branch> --state open`): sub-issues go one at a time. Name that PR; it must be merged
  first. A PR for this same issue (resumed work) is the exception.
- It has sub-issues: it is an epic. Point to its ready sub-issues, or to `split-feature` if it has none.
- A "blocked by" issue is still open. Name it, and the ready ones if this is a sub-issue.
- There are no testable acceptance criteria, or an open question changes what to build. Suggest the route above.

## 2. Branch

Work in the user's checkout. It must be clean (`git status --porcelain` empty); if not, stop and ask.

- **Base**: the issue's `parent` is an epic → its branch, named in the sub-issue body ("epic branch `…`"; else
  `git ls-remote --heads origin "feature/<epic>-*"`). If it doesn't exist, stop: `prepare-feature` creates it.
  No parent → `main`.
- **Name**: `bugfix/<n>-<slug>` for a `bug` label, else `feature/<n>-<slug>` (project git workflow). Slug: 2–5
  kebab-case words from the title.

  ```bash
  git fetch origin
  git switch -c <branch> origin/<base>
  ```

  If the branch exists already (resumed work): `git switch <branch>`, merge `origin/<base>` into it if it moved
  (no rebase once pushed), and read its commits before going on.
- **Dependencies**: if the switch changed a lockfile (`Gemfile.lock`, `package-lock.json`) or a migration, install
  and migrate with the commands in `CLAUDE.md` before running anything.

### Epic branch behind `main`

For a sub-issue, check how far the epic branch has drifted:

```bash
git rev-list --count origin/<base>..origin/main
git diff --name-only origin/<base>...origin/main
```

If `main` has commits the epic branch lacks **and** any of them touch files this issue will edit, or the count is
over 20, tell the user and propose a sync PR before going on: branch `chore/<epic>-sync-main` from the epic branch,
`git merge origin/main` (never rebase: the epic branch is shared), resolve conflicts, run the `verify` commands, open
a PR into the epic branch, run `pr-loop` on it; a human merges it (merge commit), then start this issue from the
updated epic branch. Do it only on the user's yes; otherwise go on and mention the drift in the PR.

## 3. Read before coding

Read these yourself, up front: they are the rules the reviewer will hold the PR to.

- **Issue + parent.** The issue body and everything it links ("Read first", contract, sibling issues for scope).
  If it has a `parent`, the parent body too (`gh issue view <parent> --json title,body`): context only, this
  issue's scope wins.
- **ADRs.** Collect every ADR referenced in the issue body **and** the parent body (links or `ADR-NNNN` mentions,
  e.g. `grep -oE 'ADR-[0-9]{4}'`), plus any other ADR that `docs/architecture.md` maps to a topic the change touches.
  Read `docs/adrs/README.md`, then each ADR **as it is on the base branch**
  (`git show origin/<base>:docs/adrs/<file>`), not `main`'s copy. Note its status:
  - **Proposed**, and the change relies on it → stop: the reviewer flags it; it needs `prepare-feature` first.
  - **Superseded** → follow the superseding ADR instead, and say so in the PR.
  - Referenced file missing → stop and ask: the spec points to something that doesn't exist.
- **Coding rules.** List the files you will create or edit (from the issue and the code), then read every
  `.claude/rules/*.md` whose `paths:` front matter matches one of them, and every rule file with no `paths:` (it
  applies everywhere). Don't rely on them auto-loading on edit: new files and files you never open won't trigger
  them. If the plan later grows to new paths, read the rules for those too.
- **Areas.** `docs/review.md`: find the areas the change touches (its `areas` paths are a floor; add areas for what
  the change does) and read their docs.

Keep the list of governing ADRs (number, title, status) and rule files: the plan, the self-review and the PR use
it.

- The code around the change: callers, existing patterns, existing tests. Reuse before adding. Don't ask what the
  codebase answers.
- A consumer slice ("Uses the contract from #n"): the merged request spec / generated types are the source of truth,
  not the issue text.

## 4. Plan

Write a short plan for yourself: files to touch, tests to write per acceptance criterion, docs to update, rough size,
and for each governing ADR and rule file the constraint it puts on this change (one line each). If the plan touches
paths you hadn't listed, go back and read their rule files.

Ask the user (`AskUserQuestion`) and wait only if the plan needs a decision the spec doesn't make: a product or UX
choice, diverging from an Accepted ADR, a new dependency, a data migration on existing data, or a change well over
~500 lines (propose a split instead). Otherwise go on without asking.

## 5. Implement

1. **Tests first** for each acceptance criterion; run them and see them fail for the right reason.
2. Implement the smallest change that meets the criteria. Stay in scope: anything the issue lists as "Out", or that a
   sibling issue covers, stays out — note it for the PR instead.
3. **Derived files**: after editing a file matched by a `generate` entry in `docs/review.md` (API request specs,
   database schemas…), run its commands and commit the output with the change. API changes: request spec and
   endpoint together.
4. **Docs travel with the code**: update the docs the change affects (linking to ADRs, never restating them). A
   significant choice the ADRs don't cover → a Proposed ADR or a Decision Log entry, per the ADR rules. Amending an
   Accepted ADR needs the user's yes.
5. Make each criterion pass before moving to the next.

## 6. Verify

Run the `verify` commands from `docs/review.md` front matter for every path you touched (they include the
formatters), plus the full test suite of each stack you touched if it is fast enough. All green before going on; if
something fails that you can't fix, stop and report — never ship a red branch.

Then re-read your own diff (`git diff origin/<base>...`) as a reviewer would, against the issue's acceptance
criteria, the `Read for every review` list in `docs/review.md`, and the governing list: walk each ADR and each rule
file whose `paths:` match a file in the final diff (`git diff --name-only origin/<base>...`), and check the diff
against it. Fix what you find.

### On device

If the diff touches a path matched by a `run_app` entry in `docs/review.md` and changes what the user sees or does
(a screen, a flow, copy, a gesture, offline behaviour), run the entry's skill (e.g. `run-mobile`) and
walk each acceptance criterion that is visible on screen, on every platform the skill supports. Save the screenshots in
the scratchpad. Pure logic with no visible effect: skip, and say so in the PR.

A failure here is a bug like a failing test: fix it before shipping. If the app can't be run (no simulator, build
failure you can't fix), say so in the PR and the report rather than claiming it was checked.

## 7. Ship

1. **Commit** with the project format: subject `#<n>: <what it does>`, a short body if useful, `Closes #<n>`, then
   the attribution trailer. Several commits are fine if each is a coherent step.
2. **Push**: `git push -u origin HEAD`.
3. **PR**: `gh pr create --base <base> --title "#<n>: <title>" --body-file <tmp>` with a body that fills
   `.github/pull_request_template.md`: `Closes #<n>` on the first line (on an epic branch the "Close linked issues"
   workflow relies on it), a summary (what and why, criteria → tests), a **Follows** line listing the governing
   ADRs (linked) and rule files, each checklist box ticked only if true with
   a reason for any n/a, an **Out of scope** line for what you deliberately left out, and a **Checked on device**
   section (platforms, flows walked, result, or why it was skipped). `gh` can't upload images: list the screenshot
   paths in your report so the user can drag them into the PR. End with the PR attribution line.

Never push to `main` or the epic branch directly, never force-push, never merge: a human merges every PR.

## 8. Hand over

Don't review your own PR in this context: the reviewer must start fresh. Report:

- Issue, branch, base, PR link
- Criteria → tests, verify results (actual counts)
- On-device check: platforms, result, screenshot paths (or why skipped)
- Decisions made, anything left out of scope, risks, epic branch drift
- Next step: run `pr-loop` on the PR (stay on this branch). When it reports ready, a human reviews and merges it
  with a **merge commit** (no squash, no rebase: the loop's commits are kept for retros and evals). On an epic
  branch, the merge closes the issue and the next sub-issue becomes ready: `implement-issue <epic> next`. Once the
  epic has no open sub-issue, run `close-feature`.
