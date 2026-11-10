# Review checklist: Correctness

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (the repo review guide) override this file.

## Correctness

- **Callbacks with side effects.** Sending email, enqueueing a job, or calling an API from `after_save`/`after_create` runs *before* commit and fires on rollback too. Use `after_commit` (or `after_create_commit`). Watch for callbacks that make seemingly simple `save` calls surprising.
- **Nil handling.** `&.` that hides a case that should never be nil. Missing handling where nil is realistic, such as an optional association or a failed external lookup.
- **Rescue scope.** `rescue => e` or `rescue StandardError` that swallows errors silently, or wraps too much code. `rescue` without logging or error reporting.
- **Conditionals.** New branches that make other branches unreachable. `unless ... else`. Mixing `and`/`or` with `&&`/`||`.
- **Mutating shared state.** Mutating constants, class-level caches in a threaded server (Puma), or `default:` hashes and arrays.
- **Enum/string drift.** Comparing against string literals where an enum or constant exists.
- **I18n / locale.** If the project uses I18n, check for hardcoded user-facing strings and missing keys in each locale file. Dates and numbers should be formatted with `l`/helpers.
