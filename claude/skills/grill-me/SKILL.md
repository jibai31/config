---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree, and end with a numbered decision summary. Use when the user wants to stress-test a plan, get grilled on their design, refine a need or an idea, or mentions "grill me". Generic: works on any plan, in any project. Do NOT use it to write an epic issue body or draft/accept ADRs (prepare-feature does that from the decision summary).
---

# Instructions

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each
branch of the decision tree, resolving dependencies between decisions one-by-one.

If a question can be answered by exploring the codebase, explore the codebase instead.

When the input is a GitHub issue, read it first (`gh issue view <n> --json title,body,comments`) and grill on what it
leaves open. Don't edit the issue: writing it up is a separate step.

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
