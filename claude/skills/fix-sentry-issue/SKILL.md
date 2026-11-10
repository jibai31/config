---
name: fix-sentry-issue
description: Analyze a Sentry issue (short ID like NEOCAMINOCOM-7M8, numeric ID or URL), propose a fix, and when the fix is clear-cut ship it end to end (GitHub issue linked to Sentry, bugfix branch, commit, push, PR). Use whenever the user pastes a Sentry link or ID and asks to fix, look at or investigate it.
---

# fix-sentry-issue

Input: a Sentry issue ID (`NEOCAMINOCOM-7M8`, `7812914827`) or URL (`https://neocamino.sentry.io/issues/...`).
Org: `neocamino`. Repo: `guliveo/guliveo`. Reference run: issue #18376 / PR #18377.

## 1. Analyze

1. Fetch the issue with the Sentry MCP (`mcp__sentry__get_sentry_resource` with the URL or ID). Get: title, culprit,
   stack trace of the latest event, request URL/params, tags, first/last seen, event and user counts. If the trace is
   not enough, use `mcp__sentry__analyze_issue_with_seer` as a second opinion, never as the answer.
2. Locate every in-app frame in the code (`app/`, `lib/`, `engines/`). Read the failing method and its callers.
3. Find the root cause, not just the line that raised. Ask: what input/state reaches here, can it be legitimate, is
   it a bug, bad user input, a race, stale data, or a third-party failure?
4. Check git history of the involved lines (`git log -L` / `git blame`) for a recent regression.

## 2. Propose

Report to the user, extremely concise:

- Cause (1-2 lines, with `file:line`)
- Impact (events, users, since when)
- Fix (what changes, where)
- Confidence: **sure** or **needs discussion**

**Sure** = one obvious, local fix, no product/behavior decision, no data migration, no change to a public API or
typed relation (see `docs/adrs/`). Otherwise it **needs discussion**: list the options with trade-offs and a
recommendation, ask with `AskUserQuestion`, and stop until the user picks one. Then continue with step 3 using the
chosen option.

If the issue is noise (bot traffic, already fixed on `master`, external outage), say so and propose resolving or
ignoring it in Sentry instead of changing code. Do not touch the Sentry issue status without asking.

## 3. Implement

1. Start from an up-to-date `master` with a clean tree (`git status`, `git checkout master && git pull`). If the tree
   is dirty, stop and ask.
2. Write a regression spec that reproduces the Sentry error first, run it and see it fail.
3. Fix, following `docs/README.md` and `docs/architecture/CONVENTIONS.md`. Smallest change that fixes the root cause.
4. Run the new/related specs and `bundle exec rubocop` on changed files. Everything green before going further.

## 4. Ship

1. **GitHub issue**, linked to Sentry (same body shape as the Sentry GitHub integration):

   ~~~bash
   gh issue create --repo guliveo/guliveo --label bug --title "<short description of the bug>" --body "$(cat <<'EOF'
   Sentry Issue: [<SHORT-ID>](<sentry issue url>)

   ```
   <exception class: message>

   <top in-app frames, with the source line under each>
   ...
   ```
   EOF
   )"
   ~~~

   Keep the issue number `N` from the output.
2. **Branch**: `git checkout -b bugfix/N-<short-kebab-desc>`.
3. **Commit** (format from `CLAUDE.md`): subject `#N: <what the fix does>`, a 1-2 line body explaining the bug, then
   `Closes #N`, then the attribution trailer.
4. **Push**: `git push -u origin HEAD`.
5. **PR**: `gh pr create --base master --title "#N: <same as commit subject>"` with a body that fills
   `.github/PULL_REQUEST_TEMPLATE.md` exactly (see PR #18377):
   - first line: `> 🤖 This PR (code, spec and description) was written by Claude Code, at the request of the author.`
   - **Summary**: the error as seen in Sentry (exception, URL, `<SHORT-ID>`, date), the fix, the regression spec.
   - **Test plan**: ticked boxes with the actual commands and results (`N examples, 0 failures`, `no offenses`).
   - **ADR**: link or `n/a`.
   - **AI-assisted contribution checklist**: tick each item only if true; explain any n/a.
   - **Out of scope**: what was deliberately not done.
   - `Closes #N`, then the PR attribution line.
6. Report to the user: cause in one line, GitHub issue URL, PR URL.

## Rules

- Never push to `master`, never force-push, never merge.
- Don't modify the Sentry issue (resolve, assign, ignore) unless asked.
- If any spec or rubocop fails and you can't fix it, stop and report; don't ship a red branch.
