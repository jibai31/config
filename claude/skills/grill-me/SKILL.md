---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving
each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me". Given a GitHub issue (an epic), it writes the agreed spec into the issue body with acceptance criteria and related ADRs, and gets the ADRs it relies on accepted, ready for split-feature.
---

# Instructions

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each
branch of the decision tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead.

## When the input is a GitHub issue (epic)

The issue body is the spec that `split-feature` slices and `close-feature` checks against, so the result goes in the
**body**, never in comments.

Before the first question, read the issue (`gh issue view <n> --json title,body,comments`), the project's ADR index
and rules (`docs/adrs/README.md`), and the ADRs and code the feature touches. Grill until every section below is
filled and no open question would change how the work is sliced (scope, API shape, data model, offline/sync
behaviour, user-visible copy).

Body structure:

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
Only ones that don't affect the slicing; otherwise keep grilling.
```

Link ADRs, never restate their rules. Show the final body, and update the issue (`gh issue edit <n> --body-file …`)
only after I approve it. If the original body had content the new one drops, say what.

### Accept the ADRs before implementation

Slices may only implement **Accepted** ADRs (the reviewer flags code that implements a Proposed one), so the
decisions are ratified here, at the end of the grilling, not after the code is written.

1. If the grilling produced a decision that needs a new or amended ADR (see "When to Write an ADR" in
   `docs/adrs/README.md`), draft it with the project's template, from the agreed spec.
2. List every ADR the epic relies on that is **Proposed** (existing or just drafted) and ask me to accept each one.
   Accepting is my decision: never set the status without my yes.
3. On my yes, on the epic branch `feature/<n>-<slug>` (create it from `origin/main` if it doesn't exist; `split-feature`
   reuses it): set the status line to `Accepted` and the date, update the ADR index and the docs that link it
   (architecture overview), commit (`#<n>: Accept ADR-NNNN`, per the project's commit format) and push. Then switch
   back to where I was.
4. An ADR I don't accept: keep grilling until the spec no longer needs it, or leave it Proposed and list it under
   "Open questions" — `split-feature` will refuse to slice until it is resolved.

The issue body's "Related ADRs" then shows each one as Accepted.
