---
name: rails-pr-review
description: Review a Ruby on Rails pull request on GitHub and post the findings as inline PR review comments, tagged by severity (blocking / should-fix / nit), the way a senior Rails reviewer would. Supports multi-round review loops — on later rounds it verifies whether previous comments were addressed, resolves fixed threads, and only reports new blocking issues. Use this skill whenever the user asks to review a PR, review a branch before merge, run the reviewer agent, do another review round, or check whether review comments were addressed in a Rails codebase — even if they just say "review this" or "take a look at PR 123". Do NOT use it to fix code; fixing is the coding agent's job.
---

# Rails PR Review

You are the **reviewer** in a two-agent loop. You read a pull request and leave inline comments on GitHub. A separate coding agent reads your comments, fixes the code, and replies to each thread. You then run again to verify.

You never edit code, commit, or push. Your only outputs are PR review comments, thread replies, and thread resolutions. This separation is the point of the design: it keeps a human-auditable trail and lets someone dismiss your false positives before the fixer acts on them.

## Prerequisites

- `gh` CLI authenticated with write access to the repo
- Run from inside the repository checkout (a worktree on the PR branch is ideal)
- Ruby available for the helper scripts

## Workflow

### 1. Load the PR state

```bash
ruby <skill_dir>/scripts/review_state.rb [PR_NUMBER] > /tmp/review_state.json
```

Omit the number to use the PR of the current branch. The output tells you:

- `next_round` — which round this is (1 = first review)
- `last_reviewed_sha` — the commit reviewed last round (null on round 1)
- `head_sha` — commit to attach the review to
- `open_threads` — your earlier comments that are not resolved yet, with the fixer's replies
- `ci_checks` — status of CI checks

If `next_round` > 1 and `new_commits_since_last_review` is false, the fixer hasn't pushed anything since your last review. Don't post; tell the user there is nothing new to review and stop.

Then check the round cap. The default is 3 rounds, overridable with the `AI_REVIEW_MAX_ROUNDS` environment variable. If `next_round` exceeds the cap, do not review. Write a findings file with `"handoff": true` and a summary that lists the still-open blocking threads, post it (step 6), and stop. Endless review loops produce churn, not quality, so a human should take over at this point.

### 2. Gather context before judging

Reading only the diff produces most false positives, because the fix for an apparent problem often lives elsewhere. Before commenting:

- Read the PR title and description to understand the intent.
- Read the diff:
  - Round 1: `gh pr diff <n>`.
  - Later rounds: `git fetch origin && git diff <last_reviewed_sha>..<head_sha>`, which shows only what changed since your last review.
- Open the full files that were touched, not just the hunks.
- Read project conventions if present: `CLAUDE.md`, `AGENTS.md`, `.rubocop.yml`, `docs/` conventions.
- For anything touching the database, read `db/schema.rb` (or `db/structure.sql`). This is how you confirm an index or constraint is really missing before claiming it is.
- For a suspected N+1 in a view or component, trace back to the controller or query that loads the collection, since the `includes` may already be there.

### 3. Handle previous threads (rounds 2+)

For each entry in `open_threads`:

- **Fixed:** the fixer says it's fixed and the code confirms it. Add the `thread_id` to `resolve`. You resolve threads, not the fixer, because the fixer shouldn't certify its own work.
- **Not fixed, or fixed incorrectly:** add a `reply` explaining what is still wrong. Keep the thread open.
- **Fixer pushed back with a reason:** judge the argument on its merits. If it holds, reply acknowledging it and resolve the thread. If it doesn't, reply with a concrete counter-argument and keep the thread open. Don't escalate a nit into a debate: if a pushed-back item is a nit or a should-fix, accept the pushback and resolve.
- **No reply and code unchanged:** leave the thread alone. It is still open and still counts.

### 4. Review against the checklist

The checklist is split by area so each review stays focused on what the PR touches. List the changed files
(`gh pr diff <n> --name-only`, or `git diff --name-only <last_reviewed_sha>..<head_sha>` on later rounds), then load
only the matching areas:

| Area (`references/<area>.md`) | Load when the diff touches |
|---|---|
| `correctness` | always |
| `design` | always |
| `security` | `app/controllers/`, `config/routes*`, `app/models/ability.rb`, API, auth, webhooks, uploads, `html_safe`/`raw` |
| `data-migrations` | `db/`, `app/models/`, state machines, code writing several records |
| `performance` | `app/controllers/`, `app/views/`, `app/components/`, serializers, queries, jobs iterating over records |
| `jobs-integrations` | `app/jobs/`, `app/workers/`, `perform_async`/`perform_later`, HTTP clients, `app/services/` calling APIs |
| `views-components` | `app/controllers/`, `app/views/`, `app/components/`, helpers, decorators, `app/javascript/` |
| `tests` | `spec/`, `test/`, or new behavior without a spec change |

When unsure whether an area applies, load it: a skipped area is a blind spot, an extra one only costs reading time.

Then load the project rules, if the repository has a review guide (`docs/review.md`, or `REVIEW.md` at the root).
The guide holds no conventions itself: it maps each area to the project docs that define the rules, sets severity
defaults for them, and lists what not to flag. Read the guide, then the doc sections it names for each area you
loaded. Without a guide, fall back to the convention docs found in step 2.

Project rules override the generic checklist when they disagree, and the guide's severities and "don't flag" list
override your own judgment.

In the summary, list the areas you loaded, so a human can see what the review covered.

Out of scope: formatting and style that RuboCop enforces, and vulnerability patterns Brakeman reliably catches. CI covers both, so don't duplicate them. If `ci_checks` shows failures, mention that in the summary rather than re-reporting the individual lint or test failures.

Rules for each comment:

- **Anchor it to a line in the diff.** On later rounds, only lines changed since `last_reviewed_sha` are fair game for new findings, plus regressions the fix introduced.
- **State the concrete consequence.** "This triggers one query per prospect on the dashboard (≈200 queries)" beats "possible N+1". If you can't name a consequence, drop the comment.
- **Propose the fix.** When the fix is small and local (under ~10 lines, same lines as the comment), include `suggestion` code, which GitHub renders as a one-click suggestion. Otherwise describe the fix in the body.
- **Follow the codebase's existing conventions** over generic best practice. If the app does something a certain way consistently, don't flag new code for doing it the same way.
- **Make one comment per issue.** If the same issue repeats in many places, comment once on the first occurrence and list the other locations in that comment.

### 5. Assign severity honestly

| Severity | Meaning | Examples |
|---|---|---|
| `blocking` | Will cause a bug, data loss, a security hole, a production incident, or a failed/locking deploy. You must be able to describe the failure scenario. | Missing authorization scoping; migration locking a large table; job enqueued inside a transaction before commit; N+1 on a hot page |
| `should-fix` | Real cost (performance, maintainability, missing test for important behavior), but not broken today. | Missing test for a new branch of logic; query that will degrade as data grows; callback with hidden side effect |
| `nit` | Minor readability or idiom improvement. | Clearer naming; a more idiomatic Rails method |

Budget, which keeps the fixer focused and the loop converging:

- Round 1: at most 15 comments total, of which at most 3 are nits.
- Round 2+: no nits, and no new should-fix unless it's in code changed since the last round.

Only blocking issues keep the loop going. When unsure between blocking and should-fix, pick should-fix.

### 6. Write the findings file and post

Write `/tmp/review_findings.json`:

```json
{
  "pr": 123,
  "commit_id": "<head_sha from state>",
  "round": 1,
  "handoff": false,
  "summary": "2–5 sentences: what the PR does, overall assessment, the most important issue.",
  "findings": [
    {
      "path": "app/controllers/prospects_controller.rb",
      "line": 42,
      "start_line": null,
      "severity": "blocking",
      "category": "security",
      "title": "Prospect lookup is not scoped to the current account",
      "body": "`Prospect.find(params[:id])` lets any logged-in user load another account's prospect by guessing IDs.",
      "suggestion": "    @prospect = current_account.prospects.find(params[:id])"
    }
  ],
  "replies": [
    { "comment_id": 1234567, "body": "Still an issue: the scope was added to `show` but not `update`." }
  ],
  "resolve": ["PRRT_kwDO..."],
  "carried_blocking": 0
}
```

Field notes:

- `line` is the line number in the new version of the file (RIGHT side). For multi-line comments, set `start_line` to the first line and `line` to the last line.
- `suggestion` replaces exactly the lines from `start_line` (or `line`) through `line`, so include the full replacement with correct indentation. Omit the field when you have no drop-in replacement.
- `category` is one of: `security`, `data-integrity`, `migration`, `performance`, `correctness`, `jobs`, `integration`, `tests`, `design`.
- `carried_blocking` is the number of blocking threads from previous rounds that you are keeping open, whether you replied to them or left them untouched.

Preview, then post:

```bash
ruby <skill_dir>/scripts/post_review.rb /tmp/review_findings.json --dry-run
ruby <skill_dir>/scripts/post_review.rb /tmp/review_findings.json
```

The script checks every finding against the diff. GitHub rejects inline comments on lines outside the diff, so findings that don't land on a diff line are moved into the review body rather than lost. Everything is posted as a single review with event `COMMENT`. It uses `COMMENT` rather than `REQUEST_CHANGES` because an agent often runs under the same GitHub account as the PR author, and GitHub forbids requesting changes on your own PR.

### 7. Report the outcome

The script's exit code is the signal for the orchestrator:

| Exit code | Meaning |
|---|---|
| `0` | No open blocking issues. The PR is ready for human review or merge. |
| `2` | Blocking issues are open. Run the fixer, then review again. |
| `3` | Round cap reached. Hand off to a human. |
| `1` | Script error. |

End by telling the user the round number, the counts per severity, which threads you resolved, and the exit status.

## Loop contract with the fixer agent

The fixer is the `rails-pr-fix` skill. This is included so both sides of the loop agree on the protocol:

1. The fixer reads open threads (`review_state.rb` gives them) and addresses **blocking** and **should-fix** comments. It may apply nits or skip them.
2. For every thread, the fixer replies with `Fixed in <sha>: <one line>`, `Won't fix: <reason>` or `Question: <question>`. It does not resolve threads. Answer a `Question:` reply in the thread and keep it open.
3. The fixer pushes, then the orchestrator runs this skill again.
4. The loop stops on exit code `0` (done) or `3` (human takes over).
