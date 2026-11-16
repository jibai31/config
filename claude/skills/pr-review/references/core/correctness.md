# Review checklist: Correctness

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **Intent vs code.** The change does what the PR/issue says, fully: every case named in the issue is handled, nothing
  extra slipped in.
- **Edge cases.** Empty collections, nil/undefined/null, zero, negative, very large inputs, duplicates, unicode,
  first/last element, off-by-one on ranges and pagination.
- **Error paths.** Errors swallowed (`rescue => e`, `catch {}`, ignored promise, ignored return value), caught too
  broadly, or caught without logging/reporting. Failure leaves state half-written.
- **Conditionals.** New branches that make others unreachable, inverted conditions, missing `else` where the
  unhandled case is realistic, boolean logic mixing precedence.
- **State and ordering.** Side effects that run before a commit/rollback, async code that assumes ordering, stale
  closures or cached values read after they changed, shared mutable state (module-level caches, mutated defaults or
  constants).
- **Time and locale.** Time zones, date boundaries, DST, `now` captured once vs per call; hardcoded user-facing
  strings where the project localizes; number/date formatting.
- **Enum/string drift.** Comparing against string literals where an enum or constant exists; a new enum value not
  handled by every `switch`/`case` over it (look for exhaustiveness).
- **Behavior change for callers.** A changed signature, return shape, default or side effect that existing callers
  rely on. Grep the callers.
