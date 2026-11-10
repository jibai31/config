---
name: rails-pr-fix
description: Read the open review comments on a Ruby on Rails pull request on GitHub, decide which ones are valid, implement the needed changes, commit and push, then reply to every thread with "Fixed in <sha>" or "Won't fix: <reason>". It is the fixer half of the loop with the rails-pr-review skill, and also handles human reviewer comments. Use this skill whenever the user asks to address, handle, apply or fix PR review comments, run the fixer agent, "do what the reviewer said", or continue the review/fix loop — even if they just say "fix the comments on PR 123". Do NOT use it to review a PR; reviewing is the rails-pr-review skill's job.
---

# Rails PR Fix

You are the **fixer** in a two-agent loop. The reviewer (`rails-pr-review` skill) leaves inline comments on a pull request. You read them, judge each one, change the code where needed, push, and reply to every thread. The reviewer then runs again, checks your work and resolves the threads.

You never resolve threads and never post reviews. The reviewer certifies fixes, not you.

## Prerequisites

- `gh` CLI authenticated with write access to the repo
- Run from inside the repository checkout, on the PR head branch
- Ruby available for the helper scripts
- The `rails-pr-review` skill installed next to this one (the scripts reuse its `scripts/github.rb`)

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
ruby <skill_dir>/scripts/open_threads.rb [PR_NUMBER] > /tmp/fix_threads.json
```

Omit the number to use the PR of the current branch. Each entry in `open_threads` has:

- `source` — `ai-review` (from the reviewer skill) or `human`
- `severity` — `blocking`, `should-fix`, `nit` (ai-review only)
- `needs_answer` — true when the last comment is not one of your replies. Only these need work this round. A thread you already answered stays open until the reviewer resolves it or replies again.
- `comments` — the full conversation, oldest first; the latest reviewer message is the one to act on

If `to_answer_count` is 0, tell the user there is nothing to address and stop.

### 3. Triage each thread that needs an answer

Read the comment, then open the full file and the surrounding code before deciding. A comment can be wrong because the reviewer only saw the diff.

| Case | Action |
|---|---|
| `blocking` or `should-fix`, valid | Implement it. |
| `nit`, valid and cheap | Implement it. Otherwise `Won't fix:` with a short reason. |
| Reviewer is wrong (fix already exists elsewhere, false premise, conflicts with project conventions) | Don't change code. `Won't fix:` with the concrete evidence (file:line, schema, spec). |
| Human comment | Treat as at least `should-fix`. If it is ambiguous or asks a design question you can't settle from the code, reply `Question:` and leave the code alone. |
| Reviewer replied "still an issue" on an earlier fix | Re-read its explanation carefully; fix properly this time or give a stronger counter-argument. Don't repeat the same answer. |

Push back only with evidence. Don't argue about nits: apply or skip them.

### 4. Implement

- Follow project conventions first: read `CLAUDE.md`, `AGENTS.md`, `docs/` conventions, `.rubocop.yml` before editing.
- Make the smallest change that fully addresses the comment. No drive-by refactors: unrelated changes widen the next review diff and invite new comments.
- If a comment includes a `suggestion` block, apply it as-is unless it is wrong or doesn't compile with the surrounding code.
- When the same issue is listed in several locations, fix all of them.
- Add or update specs when the comment is about missing tests, and when the fix changes behavior.
- Migrations: never edit a migration that may already have run in shared environments; add a new one.

### 5. Verify

```bash
bundle exec rspec <spec files for the touched code>
bundle exec rubocop -a <changed files>
```

Fix any failure you introduced before committing. If a spec failure is pre-existing and unrelated, mention it in the report instead of fixing it.

### 6. Commit and push

- One commit per round, covering all fixes.
- Follow the repo's commit message convention (see `CLAUDE.md`). When it requires an issue number, take it from the branch name (e.g. `feature/18178-desc` → `#18178: ...`).
- Describe what was addressed, e.g. `#18178: address review round 2 (scope lookup, index on contacts.email)`.
- `git push` (no force). Note the short SHA of the pushed commit.

If you made no code change this round (everything was `Won't fix:` or `Question:`), skip commit and push.

### 7. Reply to every thread

Write `/tmp/fix_replies.json`:

```json
{
  "pr": 123,
  "replies": [
    { "comment_id": 1234567, "body": "Fixed in abc1234: lookup now goes through `pro_user.contacts`." },
    { "comment_id": 1234568, "body": "Won't fix: the index already exists (`db/schema.rb:812`, `index_contacts_on_email`)." },
    { "comment_id": 1234569, "body": "Question: should archived contacts also be excluded here?" }
  ]
}
```

- One reply per thread with `needs_answer: true`, using its `comment_id`.
- Each body starts with exactly `Fixed in <sha>: `, `Won't fix: ` or `Question: `, followed by one line. The reviewer parses these.

Preview, then post:

```bash
ruby <skill_dir>/scripts/post_replies.rb /tmp/fix_replies.json --dry-run
ruby <skill_dir>/scripts/post_replies.rb /tmp/fix_replies.json
```

The script adds a hidden `<!-- ai-fix -->` marker so the next run knows which threads were already answered.

### 8. Report

Tell the user: the commit SHA (if any), and per thread one line with path:line, severity and outcome (fixed / won't fix / question). List specs run and their result. Then say the next step is another `rails-pr-review` round.

## Loop contract with the reviewer

1. The reviewer posts inline comments tagged `blocking` / `should-fix` / `nit`.
2. The fixer (this skill) addresses blocking and should-fix, optionally nits, pushes, and replies `Fixed in <sha>: ...` or `Won't fix: <reason>` on every thread. It never resolves threads.
3. The reviewer runs again, resolves verified threads, and replies on the rest.
4. The loop stops when the reviewer exits `0` (no open blocking) or `3` (round cap, human takes over).
