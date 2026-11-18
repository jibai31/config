---
name: implement-feature
description: Implement a whole epic unattended, one sub-issue after the other — pick the next ready sub-issue, run implement-issue on it in a fresh subagent, run the pr-loop review/fix loop on its PR, and when the loop reports ready and the project's merge gate passes (CI green, no human threads, no risk flag such as an ADR change or a "Won't fix" on a blocking / should-fix thread), squash-merge it into the epic branch and go on to the next. Syncs the default branch into the epic when needed and conflict-free. Stops only when a human is needed, when the epic has no open sub-issue left, or after --max N sub-issues. Use whenever the user asks to implement a feature / epic end to end, "do all the sub-issues of #21", "run the factory on the epic", or chain implement-issue and pr-loop with auto-merge. Do NOT use it for a single issue without merging (implement-issue + pr-loop), to slice an epic (split-feature), or to close it (close-feature).
model: sonnet
effort: medium
---

# Implement Feature

Input: an epic issue number, optionally `--max N` (stop after N merged sub-issues; default: no cap). Output: sub-issue
PRs merged into the epic branch until the epic is done or a human is needed, and a short report.

Pipeline: `grill-me` → `prepare-feature` → `split-feature` → **implement-feature** (loops `implement-issue` →
`pr-loop` → merge into the epic branch) → `close-feature`. It replaces the human merge between sub-issues when it is
safe; the epic PR into the default branch is always merged by a human.

You are the **orchestrator**. You don't write code, review it or read diffs: you launch `implement-issue` as a
subagent, run the `pr-loop` orchestration yourself, apply the merge gate, merge, and go on. Keep your context small:
read only script JSON, exit codes and the agents' short reports. **GitHub is the only state**: every step re-reads
it, so a re-run after any stop resumes where the last one left off.

Paths: `<skills>` = the parent directory of this skill; `<this_dir>` = this skill's directory;
`<repo path>` = the repository root; `<review_dir>`, `<fix_dir>`, `<split_dir>`, `<loop_dir>`, `<issue_dir>` = the
`pr-review`, `pr-fix`, `split-feature`, `pr-loop`, `implement-issue` skill directories under `<skills>`.

## Models

| Role | Model | Effort |
|---|---|---|
| Orchestrator (you) | Sonnet | medium |
| Implementer (`implement-issue`), one fresh subagent per sub-issue | Opus | high |
| Reviewer and fixer | as `pr-loop` says | |

Launch subagents with the Agent tool, setting `model` and `effort` explicitly.

## 0. Prerequisites

- The checkout is clean (`git status --porcelain` empty). If not, stop and say so.
- The epic: `gh issue view <epic> --json number,title,state,body,subIssues`. Open, with sub-issues; else stop (no
  sub-issues → `split-feature`).
- `<default>` = `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.
- `<epic branch>`: named in the epic body, else `git ls-remote --heads origin "feature/<epic>-*"` (exactly one). None
  → stop: `prepare-feature` creates it.
- The merge policy: `git fetch origin && git show origin/<default>:docs/review.md`, front matter key `auto_merge`.
  If it is missing, say so up front: the run will stop at the first ready PR (auto-merge off), which still saves the
  implement + loop steps.
- `merged = 0`, `log = []` (one line per sub-issue for the report).

## 1. Pick the next step

```bash
gh pr list --base <epic branch> --state open --json number,title,headRefName,body
```

- **One open PR** → resume it: `gh pr checkout <pr>`. Head `chore/<epic>-sync-*` → it is a sync PR, go to
  step 5 (from "pr-loop"). Otherwise it is a sub-issue PR (`Closes #<n>` in the body) → go to step 3.
- **More than one** → stop: sub-issues go one at a time; a human must sort them out.
- **None**:
  1. `merged == max` → stop: **cap reached**.
  2. `node <split_dir>/scripts/epic_status.mjs <epic>`:
     - `all_closed` → stop: **epic done**, next step `close-feature <epic>`.
     - `cycle` non-null, or `ready` empty → stop: name the `stuck` / `blocked` / `external_blockers` issues, point
       to `split-feature` re-plan for stuck ones.
     - Otherwise `<n>` = the lowest number in `ready`. Go to step 2.

## 2. Implement (subagent)

Launch the implementer (Opus, high), fresh context:

> Use the implement-issue skill on issue #<n> (sub-issue of epic #<epic>, epic branch `<epic branch>`) in
> <repo path>, in **unattended mode** (see its "Unattended mode" section): never ask the user; stop and report
> instead. Reply with only, first line exactly one of `STATUS: pr-opened #<pr>`, `STATUS: sync-needed`,
> `STATUS: needs-human`, `STATUS: error`; then at most 10 lines: the reason (for needs-human: the question and the
> options you see), criteria → tests, verify counts, in-app check result and screenshot paths, out of scope, risks.

Read the first line:

| Status | Next |
|---|---|
| `pr-opened #<pr>` | `git status --porcelain` must be empty and the branch the PR's head; then step 3. |
| `sync-needed` | Step 5, then back to step 1. At most one sync per sub-issue: a second `sync-needed` for the same issue → stop. |
| `needs-human` | Stop: **decision needed** — relay the question and options verbatim. The user answers (in the issue, or by amending the spec) and re-runs. |
| `error`, or no status line | Stop: report the subagent's lines. |

## 3. Review loop

Run the `pr-loop` orchestration on `<pr>` **yourself**, in this context: read `<loop_dir>/SKILL.md` and follow its
Prerequisites, Loop and Report sections exactly (reviewer and fixer subagents, models, exit codes, CI rounds, safety
stop). Don't invoke it with the Skill tool: its front matter would switch your model.

- Final state **ready** → step 4.
- Anything else (round cap, questions for a human, CI failing, error, "nothing new to review") → stop with
  pr-loop's state and report.

## 4. Merge gate and merge

```bash
node <this_dir>/scripts/merge_gate.mjs <pr> --base <epic branch> --issue <n>
```

(Sync PR: `--sync` instead of `--issue <n>`.) Run it unpiped; read the exit code and the JSON (`verdict`, `reasons`,
`notes`, `review_rounds`, `head_sha`). The gate stops on any human input it finds: an unresolved human thread or
reply, a PR conversation comment or a review body without an agent marker. Comments and review bodies can't be
resolved: a human clears them by posting a PR comment starting with `/auto-merge ok` (it clears everything before
it), then re-runs. Never post that comment yourself.

- Exit `2` → if the only reason is "mergeability is UNKNOWN", run it once more; otherwise stop: **merge gate** —
  list every reason. The PR stays open and ready; a human merges (or closes) it and re-runs.
- Exit `1` → retry once; then stop with the error.
- Exit `0` → merge:

  1. Merge, pinned to the commit the gate checked:
     - Sub-issue PR: `gh pr merge <pr> --squash --match-head-commit <head_sha> --subject "#<n>: <title>"
       --body "Closes #<n>"` (title from the PR, already `#<n>: …`: don't double the prefix).
     - Sync PR: `gh pr merge <pr> --merge --match-head-commit <head_sha>` — a merge commit, **never** a squash.
     Never pass `--delete-branch` (`close-feature --merged` cleans up branches) and never `--admin`.
     **Merge fails** (head moved, branch protection, required check missing, anything else) → don't retry and
     don't comment: stop with **merge failed** and gh's error. The PR stays open; a human merges it and re-runs.
  2. Only once `gh pr view <pr> --json state -q .state` is `MERGED`, the audit comment (write the body to a temp
     file in the scratchpad; keep the marker line, the gate uses it to skip this comment):

     ```text
     <!-- implement-feature -->
     Auto-merged by implement-feature: pr-loop ready after <review_rounds> review round(s), CI green
     (<checks or "no checks ran">), no open human comment, no risk flag (policy from <policy_source>).
     ```

     `gh pr comment <pr> --body-file <file>`
  3. Sub-issue PR only: `node <this_dir>/scripts/wait_issue_closed.mjs <n> --pr <pr>` (waits for the "Close linked
     issues" workflow, closes by hand after 3 min).
  4. `git switch <epic branch> && git pull --ff-only`.
  5. Sub-issue PR: `merged += 1`, add a line to `log`. Back to step 1.

## 5. Sync the default branch into the epic

Only when the implementer reported `sync-needed`, or to resume an open sync PR (then skip to "pr-loop" below).

`<sync branch>` = `chore/<epic>-sync-<default>-<short sha of origin/<default>>`: one name per sync, since merged
branches are kept until `close-feature --merged` (e.g. `chore/21-sync-main-3f9c2ab`).

```bash
git fetch origin
git switch -c <sync branch> origin/<epic branch>
git merge --no-edit origin/<default>
```

- **Branch exists** (locally or on origin: `git switch -c` fails, or the push is rejected) → a sync of this same
  `<default>` commit was already tried: its PR was closed without merging, or a stale local branch remains. Stop and
  say so (name the branch and its PR, if any); a human decides whether to delete it and retry.
- **Conflict** → `git merge --abort`, `git switch <epic branch>`, `git branch -D <sync branch>`, stop:
  **sync has conflicts, a human resolves them** (list the conflicting files).
- **Clean** → if the merge changed a dependency lockfile or a migration, install and migrate (commands in
  `CLAUDE.md`). Run the `full_verify` commands from the `docs/review.md` front matter (else the `verify` ones for the
  merged paths). **Red** → don't push: `git switch <epic branch>`, `git branch -D <sync branch>` (a re-run starts the
  sync afresh), stop: **sync breaks the build**, list the failing commands. Green → push and open the PR:

  ```bash
  git push -u origin HEAD
  gh pr create --base <epic branch> --title "#<epic>: Sync <default> into epic" --body-file <file>
  ```

  Body: `Refs #<epic>` (never `Closes`), one line on why (drift that the next sub-issue touches), the commit count,
  the PR attribution line.
- **pr-loop**: step 3 on the sync PR, then step 4 with `--sync` (merge commit). Back to step 1.

## Stop and report

On every stop (including epic done and cap reached):

1. Leave the checkout clean and on a branch a human expects: the open PR's head if one is waiting, else
   `<epic branch>`. Never leave uncommitted changes.
2. Send one push notification (PushNotification tool, if available; load it with ToolSearch): `Epic #<epic>: <state>
   — <one-line reason>`.
3. Report:
   - **Final state**: epic done / cap reached / decision needed / merge gate / merge failed / pr-loop stopped (its
     state) / sync conflict / sync branch exists / error — with the reason and what the human should do next.
   - **Per sub-issue this run**: issue, PR link, review rounds, fixer models, merged (commit) or where it stopped,
     screenshot paths from the implementer (the PR body lists them; a human can drag them in at epic review).
   - Sync PRs merged, if any.
   - **Next step**: re-run `implement-feature <epic>` after the human action, or `close-feature <epic>` when done.

## Rules

- Merge only through step 4: the gate passed, pinned with `--match-head-commit`, into the epic branch. Never merge
  into `<default>`, never push to the epic or default branch directly, never force-push, never bypass branch
  protection.
- One sub-issue at a time; never start one while a PR into the epic branch is open.
- Never answer a question meant for a human (spec gaps, `Question:` threads, ADR amendments) yourself.
- The safety stops of `pr-loop` stay in force for each PR.
