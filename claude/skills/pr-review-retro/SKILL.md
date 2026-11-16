---
name: pr-review-retro
description: Learn from past review loops — collect what the AI reviewer (pr-review) flagged on one or more PRs and what became of it (fixed, pushed back, overridden by a human), plus what humans caught that the AI missed, then propose concrete changes to the project's coding rules (.claude/rules), docs/review.md, the pr-review checklists, and new eval cases. Use whenever the user asks for a review retro, to tune or calibrate the reviewer, to learn from merged PRs, "why did the reviewer miss this", or "the reviewer keeps flagging X".
---

# PR Review Retro

The reviewer only gets better if its mistakes feed back into its rules, and the implementer only stops repeating a
mistake if the rule reaches it *before* it writes code. This skill turns review outcomes into rule changes and eval
cases. You propose; the user approves; then you apply.

Where rules live (each fact in one place):

- **`.claude/rules/*.md`** in the project — coding rules, scoped with `paths:` front matter; Claude Code loads them
  for the implementer when it touches matching files, and the reviewer checks them. Conventions are stated there
  directly; architecture decisions are only linked (the ADR owns them).
- **`docs/review.md`** — review-only: area map, severity overrides, "don't flag". Never coding rules.
- **`pr-review` checklists** — generic, cross-project review heuristics.

## 1. Collect

```bash
node <skill_dir>/scripts/retro_data.mjs <pr> [<pr>...] > <tmp>/retro.json   # specific PRs
node <skill_dir>/scripts/retro_data.mjs --merged 10 > <tmp>/retro.json       # last 10 merged PRs
```

`<tmp>` = `${TMPDIR:-/tmp}/pr-retro/`. Per PR: `ai_findings` (severity, scope, category, title, `outcome`, fixer
replies, human comments in the thread) and `human_findings` (threads a human opened). `summary` aggregates.

Outcomes: `fixed` (fixer fixed, reviewer verified), `pushback_accepted` (fixer said won't fix, reviewer agreed),
`resolved_other` (resolved without a fixer verdict — usually a human), `open_at_close` (still open when the PR was
merged or closed — a human overrode it or the loop handed off), `open`.

## 2. Classify the signals

Read the full thread for every signal before judging it; open the code at the PR's merge commit when needed.

| Signal | Likely meaning | Look at |
|---|---|---|
| `pushback_accepted` | False positive, or a rule the project doesn't hold | The fixer's evidence: was the reviewer missing context? |
| `open_at_close` / `resolved_other` with a human comment | A human disagreed with the reviewer | The human's words |
| `fixed` but the fix was trivial and the severity was `blocking` | Severity inflation | The failure scenario claimed |
| `human_findings` on a PR the AI had passed (exit 0) | **Miss** — the most valuable signal | Which area should have caught it; was it loaded? |
| Human finding repeated across PRs | A missing project rule | Is the rule written anywhere? |
| A category with many `pushback_accepted` | Checklist item too broad | The checklist line that drove it |
| Many handoffs | Loop not converging | Round-2+ findings: new nits/should-fix creeping in? |

Ignore one-off noise; act on patterns and on any miss that was blocking-grade.

## 3. Propose changes

For each pattern, propose exactly one change, at the narrowest layer that fixes it:

| Fix | Where |
|---|---|
| Project-specific false positive | `docs/review.md` → "Don't flag"; if a `.claude/rules/` line caused it, fix or narrow that line |
| Project-specific severity wrong | `docs/review.md` → "Severity overrides" |
| Convention the implementer broke (fixed after a finding) or didn't know (human finding), that isn't an architecture decision | `.claude/rules/<area>.md`: add the rule to the file whose `paths:` cover the files involved, or create a new file with `paths:` front matter (same naming: `mobile-*`, `backend-*`, or a cross-stack topic). Recurring `fixed` findings of the same kind are the main signal: the reviewer catches it, but the coder should never have written it |
| Architecture decision the reviewer or implementer didn't know | The ADR that owns it (amendment or new ADR — follow `docs/adrs/README.md`); the guide's area map and the matching `.claude/rules/` file link it |
| Rule exists but didn't reach the implementer | Widen the rules file's `paths:` (check the actual files of the PR against the globs) |
| Rule a linter or type checker could enforce | Propose the lint/CI rule as well; once it is enforced, remove the prose rule and add it to the guide's "Don't flag" |
| Area not loaded when it should have been | `docs/review.md` front matter `areas`, or the stack README path table |
| Generic checklist gap or overly broad item | `pr-review/references/core/*.md` or `references/stacks/<stack>/*.md` |
| Process problem (verification too weak, budget) | `pr-review/SKILL.md` or `pr-fix/SKILL.md` |
| Every miss, and every recurring false positive | A new eval case (`pr-review-eval` skill): the miss as `expected`, the false positive as `must_not_flag` |

A new or changed coding rule must be: imperative and checkable on a line of code ("Style with NativeWind
`className` only", not "keep styles clean"); in the narrowest file whose `paths:` cover it; and not a restatement of
an ADR (link instead). Keep each rules file short — split by path when it grows past ~40 lines, since every line
loads into the implementer's context.

Present them as a table: signal (PR + thread link) → proposed change → file → diff preview. Then ask the user which
to apply. Don't edit before they approve.

## 4. Apply

- Project docs and `.claude/rules/`: on a branch per the repo's git workflow, one commit, PR (the PR itself goes through `pr-loop`).
- Skill files (`~/.claude/skills/…`): edit in place; tell the user to run their config sync to version them.
- Eval cases: create them with the `pr-review-eval` skill's case format, then run that skill to confirm the
  reviewer now catches the miss (and that nothing else regressed).

## 5. Report

Summary numbers (findings, outcome mix, pushback-accepted rate, misses, handoffs), the changes applied, the eval
cases added, and the eval result if run.
