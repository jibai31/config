---
name: close-feature
description: Close an epic whose sub-issues are all merged into the epic branch — check the epic's acceptance criteria end to end, check its ADRs still match the code, promote lasting lessons from the sub-PRs into the project's rules and CLAUDE.md, turn recurring review findings into lint rules, then open the epic PR into main. With --merged, after a human merged the epic PR, mark its ADRs as shipped, tick the roadmap and clean up branches and worktrees. This is where knowledge from many sub-PRs gets consolidated. Use whenever the user asks to close, finish, wrap up or ship an epic / feature, "all sub-issues of #42 are merged, what now", or "the epic PR is merged, clean up". Do NOT use it on a single sub-issue PR (pr-loop) or before the epic is fully implemented.
---

# Close Feature

Input: the epic issue number, optionally `--merged`. Last step of `grill-me` → `prepare-feature` → `split-feature` →
`implement-issue` + `pr-loop` per sub-issue → **close-feature**. You check, consolidate and propose; the user
approves every change to rules, ADRs and CLAUDE.md, and the epic PR is merged by a human.

Two modes:

- **Close** (default): steps 1–6, ending with the epic PR into `main`.
- **After merge** (`--merged`, once a human merged the epic PR): step 7 only.

`<split_dir>` = the `split-feature` skill directory, `<retro_dir>` = the `pr-review-retro` skill directory
(siblings of this one). Project-specific commands come from the `docs/review.md` front matter (`full_verify`,
`contracts_check`, `run_app`, `lint_rules`, `worktree_setup`); a missing or empty key means the project has no such
step.

## 1. Everything merged?

```bash
node <split_dir>/scripts/epic_status.mjs <epic>
gh pr list --base feature/<epic>-<slug> --state all --json number,title,state,headRefName,body
```

The epic branch name is in each sub-issue body ("epic branch `…`").

- A sub-issue still open whose PR is merged into the epic branch: the "Close linked issues" workflow missed it
  (PR body without `Closes #n`, or the workflow failed — check its run). List them and close them on the user's yes
  (`gh issue close <n> --reason completed`).
- A sub-issue open with no merged PR, or a PR into the epic branch still open: **stop**. Report what is left
  (`ready` / `blocked` from the script). The epic is not done.
- Sub-issue worktrees (`git worktree list`, under `.claude/worktrees/`) whose branch's PR is merged: list them and,
  on the user's yes, remove them (`git worktree remove <path>`, then `git branch -d <branch>`). Never remove one with
  uncommitted changes or unpushed commits: report it instead.

Work from here in a worktree of the epic branch: `<wt>` = `.claude/worktrees/<epic>-<slug>` (reuse it if
`git worktree list` shows one, else `git worktree add <wt> feature/<epic>-<slug>` after `git fetch origin`; run the
`worktree_setup` commands for both stacks). Its tree must be clean. Every command below runs in `<wt>`.

- The epic branch behind `main`: propose merging `main` into it (`git merge origin/main`; no rebase, no
  force-push: the branch is shared), resolve conflicts, run the full suites below.

## 2. Acceptance criteria, end to end

The epic body's acceptance criteria are the spec. Each sub-PR proved its own slice; this step proves the slices add
up.

1. Run the full suites, not the related-tests subset: every `full_verify` command, then every `contracts_check`
   command.
2. For each criterion, find the evidence: the test(s) that cover it end to end (name the file and example), or, for
   behaviour only visible on device (offline, sync, gestures, store-visible copy), run the app with the `run_app`
   skill and walk the flow; keep the screenshots. The sub-PRs' "Checked on device" sections say what each slice
   already checked; walk the flows that cross slices.
3. Build the table: criterion → evidence → pass / fail / not covered.

Any fail or "not covered": **stop here**. Don't patch it in this step: propose a new sub-issue (with `split-feature`
in re-plan mode) that goes through the normal `implement-issue` → `pr-loop` path, then rerun this skill.

## 3. ADRs match the code

The ADRs the epic relies on were accepted by `prepare-feature` before slicing. Here, check they still describe what
was built (the epic body, the sub-PRs' ADR checklist and amendment commits say which ADRs are involved):

- An ADR still **Proposed**: it should not be. Stop and ask the user — the slices that implement it were reviewed
  against an unratified decision.
- Code that diverges from an Accepted ADR without an amendment (check the sub-PRs' won't-fix threads and the
  diff): propose the amendment (`Amended (YYYY-MM-DD)` per `docs/adrs/README.md`), or a sub-issue that fixes the
  code. Ask the user which.
- Don't set "Phase N Shipped" here: it requires the code on `main`. Note which ADR and phase each one reaches: step 7
  applies it after the merge.

## 4. Consolidate lessons

Sources: the review threads on every sub-PR, the sub-PR descriptions, Decision Log entries added on the epic branch,
and anything the ACs check surprised you with.

```bash
node <retro_dir>/scripts/retro_data.mjs <sub-pr> <sub-pr> ... > ${TMPDIR:-/tmp}/close-feature/<epic>/retro.json
```

Then apply the `pr-review-retro` skill's classification and proposal rules to that data (its "Propose changes"
table decides where each lesson goes). On top of that, for an epic:

- **Recurring findings become lint rules.** A finding of the same kind on **3 or more** occasions across the
  sub-PRs (same category and same underlying rule, even if fixed each time) means prose is not stopping it. Propose,
  in this order of preference:
  1. A linter rule, where `lint_rules` says for the stack involved (config, or a local/custom rule with its spec).
     Run it on the epic branch: it must pass on the current code (fix the remaining offenses) and fail on the
     pattern. Then remove any prose rule it replaces and add the check to `docs/review.md` "Don't flag" (the linter
     owns it now).
  2. Only if no linter can express it: one imperative line in the narrowest `.claude/rules/<area>.md` whose
     `paths:` cover the files involved.
- **Lasting lessons, not history.** Promote only what a future implementer needs before writing code: a convention,
  a pitfall, a command. Project-wide facts (workflow, commands) go in `CLAUDE.md`; path-specific conventions in
  `.claude/rules/`; architecture decisions in an ADR; small decisions in the Decision Log. Each fact in one place:
  link, never restate an ADR.
- Every miss a human caught on a sub-PR becomes an eval case (`pr-review-eval`), as the retro skill says.

Present the proposals as one table: signal (PR + thread links, occurrence count) → change → file → diff preview.
Apply only what the user approves.

## 5. Epic PR

On the user's yes:

1. Commit the consolidation on the epic branch (`#<epic>: Close feature — rules, lint`, per the project's
   commit format), push.
2. Open the PR `feature/<epic>-<slug>` → `main` with the project's PR template. Body: `Closes #<epic>`, the list of
   sub-issues with their PRs, the acceptance table from step 2 (list the screenshot paths in the report so the user
   can drag them in: `gh` can't upload images), and the consolidation changes.
3. Its size is far above the per-PR guideline by design: every slice was already reviewed. Suggest `pr-loop` scoped
   to the consolidation commit only if it changed code (lint fixes), and a human review of the acceptance table.
   A human merges; never merge yourself.

## 6. Report

- Epic state: closed-ready (PR link) / blocked (what is left) / criteria failing (proposed sub-issues)
- Acceptance table
- ADR amendments proposed or applied, and the ADR phases step 7 will mark shipped
- Lint rules added (with occurrence counts), rules / CLAUDE.md lines added or removed, eval cases added
- Worktrees removed or kept (why)
- Next step: once a human merged the epic PR, run `close-feature <epic> --merged`

## 7. After merge (`--merged`)

1. **Check the merge.**
   `gh pr list --head feature/<epic>-<slug> --base main --state merged --json number,mergeCommit` must return the
   epic PR, and the epic issue must be closed (close it on the user's yes if `Closes #<epic>` missed). If not merged,
   stop.
2. **Ship the docs**, in a worktree on a new branch from `main`
   (`git worktree add .claude/worktrees/<epic>-shipped -b chore/<epic>-shipped origin/main`):
   - **ADRs**: for each ADR the epic implemented a phase of (noted in step 3), set the status to
     `Phase N Shipped` per `docs/adrs/README.md`. Verify before relabeling: name the module, table or test on `main`
     that implements the phase. Ask the user to confirm N for each ADR.
   - **Roadmap**: tick the items the epic delivered in `docs/roadmap.md`, linking the epic; leave partly delivered
     items unticked and say what is left.
   - Update the ADR index and the architecture overview if they show statuses.
   - Run the `verify` commands for the files touched, commit (`#<epic>: Mark shipped — ADRs, roadmap`), push, and
     open a PR into `main` with `Refs #<epic>` (the epic is already closed). A human merges.
3. **Clean up**, on the user's yes after showing the list:
   - Remote branches whose PRs are merged: the epic branch and every sub-issue branch
     (`git push origin --delete <branch>`; skip the ones GitHub already deleted).
   - Local branches (`git branch -d`, never `-D`) and the remaining worktrees of this epic (`git worktree remove`,
     then `git worktree prune`). Never remove a worktree with uncommitted changes or unpushed commits: report it.
4. **Report**: ADRs relabeled (with the evidence on `main`), roadmap items ticked, docs PR link, branches and
   worktrees removed or kept.
