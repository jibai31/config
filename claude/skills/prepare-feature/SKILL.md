---
name: prepare-feature
description: Turn an agreed plan (usually grill-me's decision summary, in the same session) into a ready epic — write the spec into the epic GitHub issue body (goal, scope, behaviour, API and data model changes, acceptance criteria, related ADRs), draft new or amended ADRs, get every Proposed ADR the epic relies on accepted, and commit them on the epic branch. Ready means split-feature can slice it. Use whenever the user asks to prepare, write up, spec or detail an epic / feature issue, update the epic issue after a grilling, or "prepare issue 42 for implementation". Do NOT use it to interview the user about the need (grill-me), to slice the epic (split-feature) or to implement.
---

# Prepare Feature

Input: an epic issue number (or URL), normally right after `grill-me` in the same session. Output: the epic issue
body filled with the spec, and every ADR it relies on Accepted on the epic branch.

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

Find the decisions: `grill-me`'s decision summary in this conversation, else the conversation itself, else only the
issue (new session). In the last case, expect step 3 to send the user back to `grill-me`.

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

## 5. Accept the ADRs before implementation

Slices may only implement **Accepted** ADRs (the reviewer flags code that implements a Proposed one), so the
decisions are ratified here, not after the code is written.

1. If a decision needs a new or amended ADR (see "When to Write an ADR" in `docs/adrs/README.md`), draft it with the
   project's template, from the agreed spec.
2. List every ADR the epic relies on that is **Proposed** (existing or just drafted) and ask the user to accept each
   one. Accepting is the user's decision: never set the status without their yes.
3. On yes, on the epic branch `feature/<n>-<slug>` (create it from `origin/main` if it doesn't exist; `split-feature`
   reuses it): set the status line to `Accepted` and the date, update the ADR index and the docs that link it
   (architecture overview), commit (`#<n>: Accept ADR-NNNN`, per the project's commit format) and push. Then switch
   back to where the user was.
4. An ADR the user doesn't accept: leave it Proposed, list it under "Open questions", and say the spec needs another
   `grill-me` pass to stop relying on it. `split-feature` refuses to slice until it is resolved.

Then update the issue body's "Related ADRs" so each one shows as Accepted.

## 6. Report

- Issue link; body updated or not (and what was dropped)
- ADRs drafted, accepted, left Proposed; epic branch and commits
- Gaps sent back to `grill-me`, if any
- Next step: `split-feature <n>` when ready
