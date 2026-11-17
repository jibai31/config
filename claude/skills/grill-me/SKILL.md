---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree with a few concrete options per question, and end with a numbered decision summary (posted as a comment when the input is a GitHub issue). Use when the user wants to stress-test a plan, get grilled on their design, refine a need or an idea, or mentions "grill me". Generic: works on any plan, in any project. Do NOT use it to write an epic issue body or draft/accept ADRs (prepare-feature does that from the decision summary).
---

# Instructions

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each
branch of the decision tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead.

When the input is a GitHub issue, read it first (`gh issue view <n> --json title,body,comments`) and grill on what it
leaves open. Don't edit the issue body: writing the spec is a separate step.

## Asking

Ask with `AskUserQuestion`, never as open prose questions:

- One decision per question; batch up to 4 only when they are independent of each other.
- 2–4 concrete, mutually exclusive options per question, each with its trade-off in the description. Put your
  recommendation first, labelled "(Recommended)", based on the codebase, the project's ADRs and what was already
  decided.
- Ask the next question only once the answers it depends on are in. The user can always pick "Other": when they do,
  follow up on their answer before moving on.

## Decision summary

When no open question is left that would change the plan, end with a summary, so a later step (e.g.
`prepare-feature` for an epic) can write it up without re-asking:

```markdown
## Decision summary — <topic>

### Decisions
1. <decision> — <why, in one line>

### Rejected options
- <option> — <why not>

### Open questions
- <question> — <why it can wait>
```

Number the decisions; keep each to one or two lines. Only list open questions that don't change the plan; otherwise
keep grilling.

When the input was a GitHub issue, also post the summary as a comment on it, so a later session can pick it up:
`gh issue comment <n> --body-file <file>`. Keep the `## Decision summary — <topic>` heading first: `prepare-feature`
finds the latest comment by it. A later grilling on the same issue posts a new summary that restates every decision
still in force, not only the new ones.
