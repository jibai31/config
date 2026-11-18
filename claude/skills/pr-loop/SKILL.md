---
name: pr-loop
description: Orchestrate the review/fix loop on a GitHub pull request until it is ready to merge or needs a human — runs the pr-review skill (Opus, high effort) and the pr-fix skill (Sonnet medium or Opus high, routed by comment severity, scope and convergence) as separate subagents, round after round, up to the project's round cap, then waits for CI and sends failing checks back to the fixer. Use whenever the user asks to run the review loop, "get this PR ready", "review and fix until clean", run the software factory on a PR, or ship a branch through review. Do NOT use it for a single review round (pr-review) or a single fix round (pr-fix).
model: haiku
effort: low
---

# PR Loop

You are the **orchestrator**. You don't review and you don't edit code: you launch the reviewer and the fixer as
subagents, read their exit signals, and decide the next step. Keep your own context small: never read diffs, source
files or CI logs, only the JSON the scripts print, the exit codes and the agents' short reports.

Independence is the point: the reviewer and the fixer each start with a fresh context, so the reviewer never sees the
implementer's reasoning and judges only the code.

## Models

| Role | Model | Effort |
|---|---|---|
| Orchestrator (you) | Haiku | low |
| Reviewer (`pr-review`) | Opus | high |
| Fixer (`pr-fix`), review threads | from `recommended_fixer` in `open_threads.mjs`: Opus high for any blocking or cross-cutting comment, or when the last round left as many blocking + should-fix open as the round before; Sonnet medium otherwise | |
| Fixer (`pr-fix`), failing CI | Sonnet medium on the first CI round, Opus high on the second | |

Launch each with the Agent tool, setting `model` and `effort` explicitly as above (this skill asks for them).

## Prerequisites

- A PR exists for the branch (`gh pr view --json number`). If not, stop and tell the user to open one first.
- The checkout is clean (`git status --porcelain` empty). If not, stop and say so: the fixer commits.
- The checkout is on the PR's head branch (`gh pr view <n> --json headRefName --jq .headRefName` equals
  `git branch --show-current`). If not, `gh pr checkout <n>`. `<repo path>` = the repository root.
- `<review_dir>` = the `pr-review` skill directory, `<fix_dir>` = the `pr-fix` skill directory (siblings of this one).

## Loop

Repeat until a stop condition:

**1. Review.** Launch the reviewer subagent (Opus, high):

> Use the pr-review skill to review PR #<n> in <repo path>. Post the review. Reply with only: the round number, the
> real exit code of post_review.mjs (run unpiped, not inferred from the dry run), counts per severity and scope,
> and the review summary (≤ 5 lines).

Read the exit code from its report:

| Exit | Next |
|---|---|
| `0` | No open blocking, no unanswered should-fix: go to step 5 (CI). |
| `2` | Blocking or unanswered should-fix open: go to step 2. |
| `3` | Stop: **round cap reached, human takes over**. |
| `1` or no code | Retry the reviewer once; if it fails again, stop and report the error. |
| "nothing new to review" | Stop: the fixer pushed nothing and answered nothing; report the open threads. |

**2. Route the fixer.**

```bash
node <fix_dir>/scripts/open_threads.mjs <n>
```

Read only `to_answer_count`, `review_rounds` and `recommended_fixer` (`model`, `effort`, `reasons`). If
`to_answer_count` is 0 although the reviewer exited `2`, the open blocking / should-fix threads were already answered
and await the reviewer: go back to step 1.

**3. Fix.** Launch the fixer subagent with `recommended_fixer.model` and `recommended_fixer.effort`:

> Use the pr-fix skill to address the open review threads on PR #<n> in <repo path>. Reply with only: the commit SHA
> (or "no commit"), and per thread one line: path:line, severity · scope, outcome (fixed / won't fix / question).

**4. Check for human input.** If the fixer answered any thread with `Question:`, stop: **a human must answer**
(list the questions with their thread links). Otherwise go to step 1.

**5. CI.** Wait for the checks on the head commit:

```bash
gh pr checks <n> --watch --interval 30
```

Run it unpiped and read its exit code:

- Exit `0`: stop, **ready for human review / merge**.
- Output says "no checks reported": the runs may not have started yet. List them with
  `gh run list --commit <head sha> --json status,name` (head sha: `gh pr view <n> --json headRefOid`). Some queued
  or in progress → run the watch again. None → stop, **ready**, and say CI did not run.
- Otherwise, checks failed: get their names and go to step 6.

  ```bash
  gh pr checks <n> --json name,bucket --jq '.[] | select(.bucket == "fail") | .name'
  ```

**6. Fix CI.** At most 2 CI rounds per invocation; on a third failure, stop: **CI still failing, human takes over**.
Launch the fixer (Sonnet medium on the first CI round, Opus high on the second):

> Use the pr-fix skill in CI mode on PR #<n> in <repo path>: these checks fail: <names>. Read their logs, fix the
> cause, verify, commit and push. Reply with only: the commit SHA (or "no commit"), and per check one line: name,
> cause, outcome (fixed / not fixed: why).

Then:

- A commit → go to step 1: the reviewer checks the CI fix like any other change.
- No commit, every check reported flaky and rerun → go to step 5.
- No commit otherwise → stop: **CI failing, human takes over** (list the fixer's per-check lines).

Safety stop: never run more than `max_rounds + 1` reviewer launches in one invocation, whatever the exit codes say.

## Report

Before reporting, run `node <fix_dir>/scripts/open_threads.mjs <n>` once more and read only its `human_threads`:
the unresolved threads opened by a human, with `needs_answer`.

End with a short report:

- Final state: ready / human takes over (why) / questions for a human / CI failing / error
- Per round: reviewer counts (blocking / should-fix / nit, local / cross-cutting), fixer model used and why, commit;
  CI rounds: failing checks, fixer model, commit
- CI: final status of the checks
- Human threads still open (path:line, author, answered or not, link), or "none"
- PR link

If the final state is ready, a human merges the PR with **squash and merge** (the loop's commits stay on the PR,
under `refs/pull/<n>/head`, for retros and evals) — except a sync PR (`<default>` merged into an epic branch), which
takes a **merge commit**, never a squash; never merge yourself. (When `implement-feature` runs this loop, it applies
its own merge gate after your report and may merge into the epic branch; this loop still never merges.) If the PR targets an epic branch (`feature/<epic>-…`, not
the default branch) and closes a sub-issue, check the PR body has `Closes #<sub-issue>` (the "Close linked issues" workflow
closes it on merge, which makes the next sub-issue ready; without that workflow, tell the human to close it by hand
after the merge), then point to `implement-issue <epic> next` (or `implement-feature <epic>` to chain the rest), or
to `close-feature` once the epic has no open sub-issue.
