---
name: pr-loop
description: Orchestrate the review/fix loop on a GitHub pull request until it is ready to merge or needs a human — runs the pr-review skill (Opus, high effort) and the pr-fix skill (Sonnet medium or Opus high, routed by comment severity and scope) as separate subagents, round after round, up to the project's round cap. Use whenever the user asks to run the review loop, "get this PR ready", "review and fix until clean", run the software factory on a PR, or ship a branch through review. Do NOT use it for a single review round (pr-review) or a single fix round (pr-fix).
model: haiku
effort: low
---

# PR Loop

You are the **orchestrator**. You don't review and you don't edit code: you launch the reviewer and the fixer as
subagents, read their exit signals, and decide the next step. Keep your own context small: never read diffs or
source files, only the JSON the scripts print and the agents' short reports.

Independence is the point: the reviewer and the fixer each start with a fresh context, so the reviewer never sees the
implementer's reasoning and judges only the code.

## Models

| Role | Model | Effort |
|---|---|---|
| Orchestrator (you) | Haiku | low |
| Reviewer (`pr-review`) | Opus | high |
| Fixer (`pr-fix`) | from `recommended_fixer` in `open_threads.mjs`: Opus high for any blocking or cross-cutting comment, or after 2 non-converging rounds; Sonnet medium otherwise | |

Launch each with the Agent tool, setting `model` and `effort` explicitly as above (this skill asks for them).

## Prerequisites

- A PR exists for the branch (`gh pr view --json number`). If not, stop and tell the user to open one first.
- The working tree is clean (`git status --porcelain` empty). If not, stop and say so: the fixer commits.
- `<review_dir>` = the `pr-review` skill directory, `<fix_dir>` = the `pr-fix` skill directory (siblings of this one).

## Loop

Repeat until a stop condition:

**1. Review.** Launch the reviewer subagent (Opus, high):

> Use the pr-review skill to review PR #<n> in <repo path>. Post the review. Reply with only: the round number, the
> exit code of post_review.mjs, counts per severity and scope, and the review summary (≤ 5 lines).

Read the exit code from its report:

| Exit | Next |
|---|---|
| `0` | Stop: **ready for human review / merge**. |
| `2` | Go to step 2. |
| `3` | Stop: **round cap reached, human takes over**. |
| `1` or no code | Retry the reviewer once; if it fails again, stop and report the error. |
| "nothing new to review" | Stop: the fixer pushed nothing and answered nothing; report the open threads. |

**2. Route the fixer.**

```bash
node <fix_dir>/scripts/open_threads.mjs <n>
```

Read only `to_answer_count`, `review_rounds` and `recommended_fixer` (`model`, `effort`, `reasons`). If
`to_answer_count` is 0 although the reviewer exited `2`, the open blocking threads were already answered and await
the reviewer: go back to step 1.

**3. Fix.** Launch the fixer subagent with `recommended_fixer.model` and `recommended_fixer.effort`:

> Use the pr-fix skill to address the open review threads on PR #<n> in <repo path>. Reply with only: the commit SHA
> (or "no commit"), and per thread one line: path:line, severity · scope, outcome (fixed / won't fix / question).

**4. Check for human input.** If the fixer answered any thread with `Question:`, stop: **a human must answer**
(list the questions with their thread links). Otherwise go to step 1.

Safety stop: never run more than `max_rounds + 1` reviewer launches in one invocation, whatever the exit codes say.

## Report

End with a short report:

- Final state: ready / human takes over (why) / questions for a human / error
- Per round: reviewer counts (blocking / should-fix / nit, local / cross-cutting), fixer model used and why, commit
- PR link

If the final state is ready, suggest the user runs `pr-review-retro` on the PR after merging, so the reviewer learns
from what the human finds.
