---
name: pr-review-eval
description: Measure the pr-review skill against a set of eval cases — small changes with planted problems (expected findings) and traps (things that must not be flagged) — and report recall, false blocking, severity and scope accuracy, compared with the previous run. Use whenever the user asks to evaluate, benchmark or test the reviewer, check a change to the pr-review skill or the project review guide for regressions, or add an eval case (e.g. from a review retro miss).
---

# PR Review Eval

The reviewer is code, and code needs tests. Each eval case is a change with known problems; the reviewer reviews it
in local mode (no GitHub) and a script scores its findings. Run the suite after every change to `pr-review`, its
checklists, or a project's `docs/review.md`, and compare with the last run.

## Case sets

| Set | Where | Base |
|---|---|---|
| Generic | `<skill_dir>/cases/<id>/` | Self-contained fixture repo in `base/` |
| Project | `<repo>/.claude/review-evals/cases/<id>/` | `base_ref` (a commit sha of the repo), prepared as a git worktree |

Run the generic set plus the project set when one exists. History of aggregate scores: `<skill_dir>/history.jsonl`
for generic runs, `<repo>/.claude/review-evals/history.jsonl` for project runs.

## Case format

```text
<id>/
  case.json   { id, intent, commit_message?, base_ref?, expected: [...], must_not_flag: [...] }
  base/       fixture files of the base commit (generic cases)
  change/     files written over the base; change/.delete lists paths to remove
```

- `intent`: what the PR says it does — given to the reviewer, as a PR description would be.
- `expected[]`: `{ id, path, anchor, anchor_end?, span?, severity, severity_min?, blocking_ok?, scope?, required?,
  note }`. `anchor` is a regex for the line at the reviewed commit; a finding on the same path within ±`span`
  (default 3) lines matches. `required` defaults to true for blocking.
- `must_not_flag[]`: `{ id, path, anchor, keywords?, note }` — correct code that looks suspicious (e.g. already
  scoped, index exists elsewhere, a project convention).
- `acceptable[]`: `{ id, path, anchor, keywords?, note }` — real issues the case didn't plant but a good reviewer
  may raise (missing test, i18n…). Neither rewarded nor penalized, so they don't count as noise.
- `keywords` (any of the three lists): case-insensitive regex the finding's title + body must match. Use it whenever
  several issues can land on the same lines, or a trap line also carries a real issue: matching is by line range,
  and without keywords a valid finding can satisfy the wrong expectation or hit a trap.
- Trap lines must be free of any other real issue (the baseline run hit three traps with valid findings: an
  incomplete accessibility label, a schema not updated, hardcoded copy). Planted problems that share one fix are one
  expectation, not two.
- Keep cases small (≤ 150 changed lines), with 1–4 planted problems and at least one trap. Include a clean case
  (no expected findings) in every set: it measures noise.
- **Never** put hints in the code (`// BUG`), file names or commit message.

## Run

`<tmp>` = `${TMPDIR:-/tmp}/pr-review-eval/<timestamp>/`, with `work/` and `results/` inside.

1. **Prepare** every case:

   ```bash
   node <skill_dir>/scripts/prepare_case.mjs <case_dir> <tmp>/work [--repo <repo_root>]   # prints workdir, base_sha
   ```

2. **Review** each case with a fresh reviewer subagent (Agent tool, model **Opus**, effort **high** — the same as
   `pr-loop` uses), up to 4 in parallel. Give it only:

   > Use the pr-review skill in local mode. Repository: <workdir>. Run `--local <base_sha> --out
   > <tmp>/results/<id>/run-<k>.json`. PR description: "<intent>". Don't post anything. Reply with the counts only.

   The subagent must never see `case.json` or this skill's directory. With `--runs N` (default 1; use 3 when
   comparing two versions of the reviewer), repeat with `k` = 1..N: reviewer output varies between runs.

3. **Score:**

   ```bash
   node <skill_dir>/scripts/score.mjs --cases <skill_dir>/cases [--cases <repo>/.claude/review-evals/cases] \
     --results <tmp>/results --work <tmp>/work --out <tmp>/report.json \
     --history <history.jsonl> --label "<what changed>"
   ```

4. **Clean up** project worktrees: `git worktree remove --force <tmp>/work/<id>` for each project case.

## Report

Show the score table and the aggregate line, then compare with the previous history entry. Call out:

- **Required recall** below 100%: a planted blocking problem was missed — the most serious result.
- **False blocking** or **must-not hits** above 0: the reviewer would make the fixer churn on correct code.
- Severity or scope accuracy dropping: fixer routing (Sonnet vs Opus, plan-first) goes wrong.
- `unexpected/run` rising: noise. Read the unexpected findings: some are real problems the case didn't plant — then
  add them to the case's `expected`, not to the reviewer's faults.

For each failure, name the likely cause (area not loaded, checklist gap, verification pass too lax) and the file to
change. Don't change the reviewer in the same step: propose, then re-run after the change.

## Adding a case

From a retro miss or a recurring false positive (`pr-review-retro`): reproduce the smallest change that shows it,
as a generic fixture when it is stack-level, or a project case (`base_ref` = the commit before the PR) when it
depends on project rules. Prepare it once and check every anchor resolves (`score.mjs` fails loudly when one
doesn't) before running the reviewer.
