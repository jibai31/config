---
name: prepare-feature
description: Turn an agreed plan (grill-me's decision summary, from the same session or its issue comment) into a ready epic — write the spec into the epic GitHub issue body (goal, scope, behaviour, API and data model changes, acceptance criteria, related ADRs), create the epic branch, draft new or amended ADRs, get every Proposed ADR the epic relies on accepted, and ship them in a PR into the epic branch that goes through pr-loop. Ready means split-feature can slice it. Use whenever the user asks to prepare, write up, spec or detail an epic / feature issue, update the epic issue after a grilling, or "prepare issue 42 for implementation". Do NOT use it to interview the user about the need (grill-me), to slice the epic (split-feature) or to implement.
---

# Prepare Feature

Input: an epic issue number (or URL), right after `grill-me` in the same session or in a new one. Output: the epic
issue body filled with the spec, the epic branch, and a reviewed PR into it that makes every ADR the epic relies on
Accepted.

Pipeline this skill sits in: `grill-me` (refine the need) → **prepare-feature** → `split-feature` →
`implement-issue` + `pr-loop` per sub-issue → `close-feature`.

You write up decisions; you don't make them. Your sources are the decision summary and the conversation, the issue,
the ADRs and the code. Don't interview: ask only to confirm a wording or a fact (a yes/no, a choice between two
written options). Anything bigger goes back to `grill-me`.

## 1. Read

```bash
gh issue view <n> --json number,title,body,state,labels,parent,subIssues,comments
```

Stop and say why if the issue is closed, or is itself a sub-issue (`parent` set). If it already has sub-issues, warn
that changing the spec may need a `split-feature` re-plan, and go on only on the user's yes.

Then read the project's ADR rules and index (`docs/adrs/README.md`), the architecture overview, the ADRs and code
the feature touches, and the roadmap (what it schedules later is out of scope).

Find the decisions, in this order:

1. `grill-me`'s decision summary in this conversation (and the discussion around it).
2. Else the latest issue comment whose body starts with `## Decision summary` (`grill-me` posts it there, so a new
   session can pick it up). Later comments may refine it: read the ones after it too.
3. Else only the issue body. Expect step 3 to send the user back to `grill-me`.

## 2. Draft the body

The issue body is the spec that `split-feature` slices and `close-feature` checks against, so the result goes in the
**body**, never in comments.

```markdown
## Goal
Who it is for and what changes for them.

## Scope
- In: …
- Out: … (later milestones stay in the roadmap)

## Behaviour
User flows and edge cases (offline, errors, empty states), as concrete as needed to test them.

## API changes
Endpoints added/changed, request/response shape in outline, compatibility with app versions in the stores. "None"
if none.

## Data model changes
Tables/columns on the server and device, synced or not, closed-enum values touched. "None" if none.

## Acceptance criteria
- [ ] Testable, end-to-end statements: what `close-feature` will check

## Related ADRs
- [ADR-NNNN](docs/adrs/ADR-NNNN-….md) (status) — why it applies
- Decisions here that need a new or amended ADR, and whether a Proposed draft exists

## Open questions
Only ones that don't affect the slicing.
```

Link ADRs, never restate their rules.

## 3. Readiness check

The epic is ready when every section above is filled from a decision (not from your guess) and no open question
would change how the work is sliced: scope, API shape, data model, offline/sync behaviour, user-visible copy.

If not, **stop**: list each gap (section + the question to settle) and tell the user to run `grill-me` on them, then
rerun this skill. Don't fill gaps yourself and don't grill here: keeping the interview in `grill-me` is the point of
the split.

## 4. Update the issue

Show the final body. If the original body had content the new one drops, say what. Update the issue
(`gh issue edit <n> --body-file …`) only after the user approves.

## 5. Epic branch

Create `feature/<n>-<slug>` (slug: 2–5 kebab-case words from the title) from `origin/main` if it doesn't exist,
without checking it out:

```bash
git fetch origin
git push origin origin/main:refs/heads/feature/<n>-<slug>
```

Every PR of the epic (this one, then each sub-issue's) targets it. `split-feature` reuses it.

## 6. Accept the ADRs, in a reviewed PR

Slices may only implement **Accepted** ADRs (the reviewer flags code that implements a Proposed one), so the
decisions are ratified here, before any code is written. They reach the epic branch through a PR and `pr-loop`,
like any other change: nothing is pushed to the epic branch directly.

1. List the changes the spec needs in the repository: new or amended ADRs (see "When to Write an ADR" in
   `docs/adrs/README.md`), every ADR the epic relies on that is still **Proposed**, and the docs that link them (ADR
   index, architecture overview). None → skip to step 7.
2. Ask the user to accept each Proposed ADR (existing or about to be drafted). Accepting is the user's decision:
   never set the status without their yes. An ADR the user doesn't accept stays Proposed: list it under "Open
   questions" and say the spec needs another `grill-me` pass to stop relying on it (`split-feature` refuses to slice
   until it is resolved). Leave it out of the PR.
3. Branch in the user's checkout. It must be clean (`git status --porcelain` empty); if not, stop and ask.

   ```bash
   git switch -c docs/<n>-adrs origin/feature/<n>-<slug>
   ```

4. Draft the ADRs from the agreed spec with the project's template, set each accepted one to `Accepted` with the
   date, update the ADR index and the docs that link them. Run the `verify` commands from `docs/review.md` for the
   files touched.
5. Commit (`#<n>: Accept ADR-NNNN …`, per the project's commit format, with the attribution trailer), push
   (`git push -u origin HEAD`), and open the PR into the epic branch:
   `gh pr create --base feature/<n>-<slug> --title "#<n>: Accept ADRs for <epic title>"`. The body fills the project's
   PR template, but its first line is `Refs #<n>`, **never** `Closes #<n>`: the "Close linked issues" workflow would
   close the epic when the PR merges into the epic branch. End with the PR attribution line.
6. Run the `pr-loop` skill on the PR. Its reviewer checks the ADRs against the project's ADR rules; a fix that
   changes a decision (not just its wording) goes back to the user before it is pushed.
7. When `pr-loop` reports ready, a human merges the PR into the epic branch with a **merge commit** (no squash, no
   rebase: the loop's commits are kept for retros and evals). Never merge yourself.

Then update the issue body's "Related ADRs": each accepted one shows as Accepted, with a link to the ADR PR.

## 7. Report

- Issue link; body updated or not (and what was dropped)
- Epic branch; ADRs drafted, accepted, left Proposed; ADR PR link and `pr-loop` final state
- Gaps sent back to `grill-me`, if any
- Next step: once the ADR PR is merged into the epic branch (or there was none), `split-feature <n>`
