---
name: pr-fix
description: Read the open review comments on a GitHub pull request (any stack), decide which ones are valid, implement the needed changes — writing a short plan first for cross-cutting comments — run the project's verify commands from docs/review.md, commit and push, then reply to every thread with "Fixed in <sha>", "Won't fix: <reason>" or "Question: <question>". It is the fixer half of the loop with the pr-review skill, and also handles human reviewer comments. Use this skill whenever the user asks to address, handle, apply or fix PR review comments, run the fixer agent, "do what the reviewer said", or continue the review/fix loop — even if they just say "fix the comments on PR 123". Do NOT use it to review a PR; reviewing is the pr-review skill's job.
---

# PR Fix

You are the **fixer** in a two-agent loop. The reviewer (`pr-review` skill) leaves inline comments tagged
`**[<severity> · <scope>] · <category>**`. You read them, judge each one, change the code where needed, push, and
reply to every thread. The reviewer then runs again, checks your work and resolves the threads.

You never resolve threads and never post reviews. The reviewer certifies fixes, not you.

## Prerequisites

- `gh` authenticated with write access; Node ≥ 20
- Run from inside the repository checkout, on the PR head branch
- The `pr-review` skill installed next to this one (scripts share its `scripts/github.mjs`)

`<skill_dir>` is this skill's directory; `<tmp>` is `${TMPDIR:-/tmp}/pr-<n>/`.

## Workflow

### 1. Prepare the branch

```bash
git status --porcelain            # must be empty; stop and tell the user otherwise
gh pr checkout <n>                # or confirm the current branch is the PR head branch
git pull --ff-only
```

Never force-push and never rebase the PR branch: the reviewer diffs from its last reviewed commit.

### 2. Load the open threads

```bash
mkdir -p <tmp> && node <skill_dir>/scripts/open_threads.mjs [PR_NUMBER] > <tmp>/threads.json
```

Each entry in `open_threads` has `source` (`ai-review` or `human`), `severity` and `scope` (ai-review only),
`needs_answer` (true when the last comment is not one of your replies — only these need work), and `comments` (oldest
first; act on the latest reviewer message).

Top-level `recommended_fixer` says which model/effort this round deserves (Opus high for any blocking or
cross-cutting comment, or when the last review round left at least as many blocking + should-fix open as the one
before; Sonnet medium otherwise). An orchestrator uses it to launch you. If you were launched directly and you are a
weaker model than recommended, say so in the report.

If `to_answer_count` is 0, tell the user there is nothing to address and stop — unless you are in CI mode.

### CI mode

When asked to fix failing CI checks (`pr-loop` does it once the review is clean), the failing checks are the work
list, on top of any thread that needs an answer:

```bash
gh pr checks <n> --json name,bucket,link --jq '.[] | select(.bucket == "fail")'
gh run view <run id from the link> --log-failed
```

Find the cause in the log, reproduce it locally with the matching `verify` / `full_verify` command from
`docs/review.md`, then fix it like a `local` comment (step 5 if it spans several files). A flaky failure unrelated to
the PR: rerun it once (`gh run rerun <run id> --failed`), and if it passes, report it as flaky with no commit; never
retry more than once. A failure that is not caused by the PR and isn't flaky (e.g. broken on the base branch): no
change, report it. The commit message names the check (`#18: Fix CI (rspec: …)`). There are no threads to reply to
for checks: report per check instead (name, cause, outcome).

### 3. Load the project guide

Read `docs/review.md` (fallback `REVIEW.md`): its front matter has the `verify` commands and `commit` format; its
body links the project rules. Read `CLAUDE.md` / `AGENTS.md`, the coding rules in `.claude/rules/*.md` whose `paths:`
front matter matches the files you'll touch, and the rule docs they link (e.g. the Accepted ADRs for that area)
before editing.

### 4. Triage each thread that needs an answer

Open the full file and the surrounding code before deciding. A comment can be wrong because the reviewer only saw
part of the code.

| Case | Action |
|---|---|
| `blocking` or `should-fix`, valid | Implement it, within the PR's diff (see step 6). Both hold the loop until fixed or answered. |
| `nit`, valid and cheap | Implement it. Otherwise `Won't fix:` with a short reason. |
| Reviewer is wrong (fix exists elsewhere, false premise, conflicts with project rules) | No code change. `Won't fix:` with concrete evidence (file:line, schema, ADR, spec). |
| Human comment | At least `should-fix`. Ambiguous, or a design question you can't settle from the code and docs → `Question:`, no code change. |
| Reviewer replied "still an issue" | Re-read its explanation; fix properly this time or give a stronger counter-argument. Never repeat the same answer. |
| Fix would contradict an Accepted ADR / project rule | Don't implement. `Question:` explaining the conflict. |

Push back only with evidence. Don't argue about nits: apply or skip them.

### 5. Plan cross-cutting fixes first

If any thread you will implement is `cross-cutting` (or a human comment whose fix spans several files or changes an
interface, schema or design), write `<tmp>/plan-round-<r>.md` **before editing**:

- Comments addressed, grouped when they share a fix
- Files to touch, and why each
- Order of changes: schema/migration first, then model/domain, then callers, then UI; for data changes, the
  expand-and-contract steps if deployed clients or running code depend on the old shape
- Interfaces/contracts that change and every caller to update (grep for them now, list them)
- Specs/tests to add or update
- Docs/ADRs to update, per the project rules
- Risks and how verification will catch them

Then implement against the plan. If the plan reveals the fix is larger than the PR should carry, or needs a design
decision, reply `Question:` with the trade-off instead of improvising.

### 6. Implement

- Smallest change that fully addresses the comment. No drive-by refactors: they widen the next review diff.
- **Fix convention breaches only within the PR's diff.** When a comment flags a project-rule or convention breach
  (custom CSS instead of Bootstrap classes, raw Bootstrap markup instead of a `UI::*` component, `current_user`, …),
  fix the occurrences the PR adds or changes, nothing else. The same breach elsewhere in the app stays as is: don't
  refactor or migrate other files or callers. Touch a file outside the diff only when the in-diff fix needs it (e.g.
  add an option to a component so the PR's view can use it), keeping existing callers unchanged.
- Apply a `suggestion` block as-is unless it is wrong or doesn't fit the surrounding code.
- When the comment lists several locations, fix all of them.
- Add or update tests when the comment is about missing tests, and whenever the fix changes behavior.
- Never edit a migration that may have run in a shared environment; add a new one. Never hand-edit generated files;
  regenerate them with the project's command.

### 7. Verify

Run the `verify` commands from the guide for every path group you touched (fall back to the commands in `CLAUDE.md`).
Fix failures you introduced before committing. If a failure is pre-existing and unrelated, mention it in the report
instead of fixing it.

### 8. Commit and push

- One commit per round, covering all fixes.
- Message per the guide's `commit` format (else `CLAUDE.md`). When it needs an issue number, take it from the branch
  name (`feature/18-desc` → `#18: ...`). Describe what was addressed, e.g.
  `#18: Address review round 2 (scope tasting lookup, index on tastings.card_id)`.
- `git push` (no force). Note the short SHA.

No code change this round (all `Won't fix:` / `Question:`) → skip commit and push.

### 9. Reply to every thread

Write `<tmp>/replies.json`:

```json
{
  "pr": 123,
  "replies": [
    { "comment_id": 1234567, "body": "Fixed in abc1234: lookup now goes through `current_user.tastings`." },
    { "comment_id": 1234568, "body": "Won't fix: the index already exists (`db/schema.rb:81`, `index_tastings_on_card_id`)." },
    { "comment_id": 1234569, "body": "Question: should archived cards also be excluded here?" }
  ]
}
```

One reply per thread with `needs_answer: true`. Each body starts with exactly `Fixed in <sha>: `, `Won't fix: ` or
`Question: ` followed by one line.

```bash
node <skill_dir>/scripts/post_replies.mjs <tmp>/replies.json --dry-run
node <skill_dir>/scripts/post_replies.mjs <tmp>/replies.json
```

The script adds a hidden `<!-- ai-fix -->` marker so the next run knows which threads were answered.

### 10. Report

Commit SHA (if any); per thread one line with path:line, severity · scope, outcome (fixed / won't fix / question);
the plan file if one was written; verify commands run and their result; the `recommended_fixer` of this round. Next
step: another `pr-review` round.

## Loop contract

See the `pr-review` skill's "Loop contract with the fixer": reviewer comments → fixer fixes, pushes and replies on
every thread → reviewer resolves or replies → stop on reviewer exit `0` (done) or `3` (human takes over).
