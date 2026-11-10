---
name: rails-bundle-update
description: Weekly dependency update of the guliveo Rails app, end to end - create the "Bundle update - YYYY-MM-DD" GitHub issue, branch, run `bundle update`, run rubocop and fix the offenses, commit, push and open the PR. Use whenever the user asks to update the gems, run bundle update, do the weekly/Monday bundle update, or invokes /rails-bundle-update.
---

# rails-bundle-update

Repo: `guliveo/guliveo`, base branch `master`. Meant to run unattended (e.g. every Monday morning): never ask questions,
stop and report instead.

## 1. Preflight

1. `cd` to the repo root. `git status --porcelain`: if there are tracked changes (modified/staged), stop and report.
   Untracked files are fine, never `git add` them.
2. `git checkout master && git pull --ff-only`.
3. `DATE=$(date +%F)`. If an open issue titled `Bundle update - $DATE` already exists
   (`gh issue list --repo guliveo/guliveo --state open --search "Bundle update - $DATE in:title"`), reuse its number
   and branch instead of creating new ones; if its PR already exists, stop and report its URL.

## 2. Issue + branch

```bash
gh issue create --repo guliveo/guliveo --title "Bundle update - $DATE" \
  --body "Weekly \`bundle update\` + rubocop fixes."
```

Keep the issue number `N` from the URL. Branch: `git checkout -b feature/N-bundle-update`.

## 3. Update

1. `bundle update`. If it fails (resolution conflict, native extension build error), stop and report the error; don't
   pin or downgrade gems on your own.
2. `git diff --stat Gemfile.lock`. If nothing changed: close the issue (`gh issue close N --comment "Nothing to
   update."`), delete the branch, go back to `master`, report and stop.
3. Collect the list of updated gems with old → new versions (parse `git diff Gemfile.lock`, top-level specs only).
   Flag any major version bump, and any bump of `rails`, `rubocop*`, `sidekiq`, `devise`, `pg`.

## 4. Rubocop

1. `bundle exec rubocop`. If it reports "unrecognized cop" or weird config errors, run
   `bundle exec rubocop --restart-server` first (stale server, not a config bug).
2. Offenses: first `bundle exec rubocop -a` (safe autocorrect only, never `-A`). Then fix the remaining offenses by
   hand, following `docs/README.md` and `docs/architecture/CONVENTIONS.md`.
3. New cops introduced by a rubocop upgrade: fix the code if the change is mechanical and safe. If a cop would need a
   large or risky rewrite, disable it in `.rubocop.yml` with a comment instead and list it in the PR's "Out of scope".
   Don't add `rubocop:disable` inline comments.
4. Re-run `bundle exec rubocop` until `no offenses detected`. If still red and not fixable, stop and report, don't
   ship a red branch.
5. Run the specs of any file changed by hand in step 2-3 (`bundle exec rspec <spec files>`). The full suite runs in CI.

## 5. Commit + PR

1. `git add Gemfile.lock` plus the files fixed for rubocop (and `.rubocop.yml` if touched). Nothing else.
2. One commit (two if the rubocop fixes are large: lock first, then fixes):

   ```
   #N: bundle update

   <one line per notable gem bump, e.g. rails 8.1.4 → 8.1.4.1>
   <one line on rubocop fixes, if any>

   Closes #N

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   ```
3. `git push -u origin HEAD`.
4. `gh pr create --repo guliveo/guliveo --base master --title "#N: bundle update - $DATE"`, body filling
   `.github/PULL_REQUEST_TEMPLATE.md`:
   - first line: `> 🤖 This PR (code and description) was written by Claude Code, at the request of the author.`
   - **Summary**: table of updated gems (old → new), major bumps flagged; rubocop fixes made.
   - **Test plan**: `[x] rubocop` with `no offenses detected`; `[x]`/`[ ]` rspec on touched files with result, plus
     `[ ] full rspec suite (CI)`.
   - **ADR**: `n/a`.
   - **AI-assisted contribution checklist**: tick each item only if true; explain n/a.
   - **Out of scope**: disabled cops, gems held back, anything not done.
   - `Closes #N`, then `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
5. `git checkout master`.

## 6. Report

Extremely concise: issue URL, PR URL, number of gems updated, major bumps, rubocop fixes / disabled cops.

## Rules

- Never push to `master`, never force-push, never merge.
- Never commit untracked files, credentials or unrelated changes.
- On any blocking failure: leave the branch as is (no push if red), comment the error on the issue, report.
