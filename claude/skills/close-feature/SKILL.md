---
name: close-feature
description: Close an epic whose sub-issues are all merged into the epic branch — check the epic's acceptance criteria end to end, check its ADRs still match the code, promote lasting lessons from the sub-PRs into the project's rules and CLAUDE.md, turn recurring review findings into lint rules, then open the epic PR into the default branch. With --merged, after a human merged the epic PR, mark its ADRs as shipped, tick the roadmap and clean up branches. This is where knowledge from many sub-PRs gets consolidated. Use whenever the user asks to close, finish, wrap up or ship an epic / feature, "all sub-issues of #42 are merged, what now", or "the epic PR is merged, clean up". Do NOT use it on a single sub-issue PR (pr-loop) or before the epic is fully implemented.
---

# Close Feature

Input: the epic issue number, optionally `--merged`. Last step of `grill-me` → `prepare-feature` → `split-feature` →
`implement-issue` + `pr-loop` per sub-issue → **close-feature**. You check, consolidate and propose; the user
approves every change to rules, ADRs and CLAUDE.md, and the epic PR is merged by a human.

Two modes:

- **Close** (default): steps 1–6, ending with the epic PR into `<default>`.
- **After merge** (`--merged`, once a human merged the epic PR): step 7 only.

`<default>` = the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).

`<split_dir>` = the `split-feature` skill directory, `<retro_dir>` = the `pr-review-retro` skill directory
(siblings of this one). Project-specific commands come from the `docs/review.md` front matter (`full_verify`,
`contracts_check`, `run_app`, `lint_rules`); a missing or empty key means the project has no such step.

This is the only place the review retro runs inside the epic workflow (`pr-loop` doesn't): step 4 runs it once over
every PR merged into the epic branch.

## 1. Everything merged?

```bash
node <split_dir>/scripts/epic_status.mjs <epic>
gh pr list --base feature/<epic>-<slug> --state all --json number,title,state,headRefName,body
```

The epic branch name is in each sub-issue body ("epic branch `…`").

- A sub-issue still open whose PR is merged into the epic branch: the "Close linked issues" workflow missed it (PR
  body without `Closes #n`, the workflow failed — check its run — or the project doesn't have it). List them and
  close them on the user's yes (`gh issue close <n> --reason completed`).
- A sub-issue open with no merged PR, or a PR into the epic branch still open: **stop**. Report what is left
  (`ready` / `blocked` from the script). The epic is not done.
- A PR into the epic branch merged by squash or rebase instead of a merge commit (its `mergeCommit` has one parent:
  `git rev-list --parents -n1 <sha>`): note it — the loop's commits are lost for the retro; its review threads are
  not.

Work from here on the epic branch, in the user's checkout. It must be clean (`git status --porcelain`); if not, stop
and ask. `git fetch origin && git switch feature/<epic>-<slug> && git pull --ff-only`, then install dependencies and
migrate if lockfiles or migrations changed (commands in `CLAUDE.md`).

- The epic branch behind `<default>`: propose merging it into the epic branch (`git merge origin/<default>`; no
  rebase, no force-push: the branch is shared), resolve conflicts, run the full suites below.

## 2. Acceptance criteria, end to end

The epic body's acceptance criteria are the spec. Each sub-PR proved its own slice; this step proves the slices add
up.

1. Run the full suites, not the related-tests subset: every `full_verify` command, then every `contracts_check`
   command.
2. For each criterion, find the evidence: the test(s) that cover it end to end (name the file and example), or, for
   behaviour only visible in the running app (UI flows, visual states, copy), run the app with the `run_app`
   skill and walk the flow; keep the screenshots. The sub-PRs' "Checked in the app" sections say what each slice
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
  diff): propose the amendment, in the form `docs/adrs/README.md` gives, or a sub-issue that fixes the
  code. Ask the user which.
- If the ADR rules have a shipped status (e.g. "Phase N Shipped"), don't set it here: it requires the code on
  `<default>`. Note which ADR and phase each one reaches: step 7 applies it after the merge.

## 4. Consolidate lessons

Sources: the review threads and commits of every PR merged into the epic branch (sub-issue PRs, the ADR PR, sync
PRs), their descriptions, Decision Log entries (if the project keeps one) added on the epic branch, and anything the
ACs check surprised you with. Merge commits keep each PR's loop commits on the branch:
`git log --first-parent feature/<epic>-<slug>` lists the merges, `git log <merge>^1..<merge>^2` one PR's commits
(what the fixer changed, round by round).

```bash
node <retro_dir>/scripts/retro_data.mjs <pr> <pr> ... > ${TMPDIR:-/tmp}/close-feature/<epic>/retro.json
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
  `.claude/rules/`; architecture decisions in an ADR; small decisions in the Decision Log, if any. Each fact in one place:
  link, never restate an ADR.
- Every miss a human caught on a sub-PR becomes an eval case (`pr-review-eval`), as the retro skill says.

Present the proposals as one table: signal (PR + thread links, occurrence count) → change → file → diff preview.
Apply only what the user approves.

## 5. Epic PR

On the user's yes:

1. Commit the consolidation on the epic branch (`#<epic>: Close feature — rules, lint`, per the project's
   commit format), push.
2. Open the PR `feature/<epic>-<slug>` → `<default>` with the project's PR template. Body: `Closes #<epic>`, the list
   of sub-issues with their PRs, the acceptance table from step 2 (list the screenshot paths in the report so the
   user can drag them in: `gh` can't upload images), and the consolidation changes.
3. Its size is far above the per-PR guideline by design: every slice was already reviewed. Suggest `pr-loop` scoped
   to the consolidation commit only if it changed code (lint fixes), and a human review of the acceptance table.
   A human merges it with **rebase and merge** (each sub-issue's commits land on `<default>` as they are; the epic
   branch's merge commits are dropped). Never merge yourself. GitHub refuses the rebase if replaying the commits
   conflicts, typically after a `<default>` sync merge that resolved conflicts: then say so and let the human choose
   (resolve on the branch, or a merge commit for this epic).

## 6. Report

- Epic state: closed-ready (PR link) / blocked (what is left) / criteria failing (proposed sub-issues)
- Acceptance table
- ADR amendments proposed or applied, and the ADR phases step 7 will mark shipped
- Lint rules added (with occurrence counts), rules / CLAUDE.md lines added or removed, eval cases added
- Next step: once a human merged the epic PR (rebase and merge), run `close-feature <epic> --merged`

## 7. After merge (`--merged`)

1. **Check the merge.**
   `gh pr list --head feature/<epic>-<slug> --base <default> --state merged --json number,mergeCommit` must return the
   epic PR, and the epic issue must be closed (close it on the user's yes if `Closes #<epic>` missed). If not merged,
   stop.
2. **Ship the docs**, on a new branch from `<default>` in the user's checkout (clean tree;
   `git fetch origin && git switch -c chore/<epic>-shipped origin/<default>`). Nothing below applies → skip to 3:
   - **ADRs**, if `docs/adrs/README.md` has a shipped status (e.g. `Phase N Shipped`): set it on each ADR the epic
     implemented a phase of (noted in step 3). Verify before relabeling: name the module, table or test on
     `<default>` that implements the phase. Ask the user to confirm N for each ADR.
   - **Roadmap**, if the project has one (found from `CLAUDE.md`): tick the items the epic delivered, linking the
     epic; leave partly delivered items unticked and say what is left.
   - Update the ADR index and the architecture overview if they show statuses.
   - Run the `verify` commands for the files touched, commit (`#<epic>: Mark shipped — ADRs, roadmap`), push, and
     open a PR into `<default>` with `Refs #<epic>` (the epic is already closed). A human merges.
3. **Clean up**, on the user's yes after showing the list:
   - Remote branches whose PRs are merged: the epic branch and every branch merged into it (sub-issues, ADR PR,
     sync PRs) (`git push origin --delete <branch>`; skip the ones already deleted).
   - Local branches, from an up-to-date `<default>` (`git switch <default> && git pull --ff-only`). The rebase gave the
     commits new SHAs on `<default>`, so `git branch -d` refuses them: for each branch, confirm with
     `gh pr list --head <branch> --state merged` that its PR is merged, and that it has no commit newer than its
     PR's head (`git rev-parse <branch>` equals the PR's `headRefOid`); only then `git branch -D`. Anything else:
     report it, don't delete.
4. **Report**: ADRs relabeled (with the evidence on `<default>`), roadmap items ticked, docs PR link, branches
   removed or kept.
