# Review checklist: Rails correctness

Rails stack pack for pr-review: complements `core/correctness.md`. Only comment when you can point at a line and
name the consequence. The project guide overrides this file.

- **Callbacks with side effects.** Email, job enqueue or API call from `after_save`/`after_create` runs before commit
  and fires on rollback too. Use `after_commit` / `after_create_commit`. Callbacks that make a simple `save`
  surprising are a maintainability finding too.
- **`&.` hiding a case** that should never be nil; missing handling where nil is realistic (optional association,
  failed `find_by`).
- **`rescue => e` / `rescue StandardError`** swallowing silently or wrapping too much; no error reporting.
- **`unless … else`**, mixing `and`/`or` with `&&`/`||`.
- **Mutating shared state** in a threaded server (Puma): class-level caches, mutated constants, `default:` hashes or
  arrays.
- **Time:** `Time.now`/`Date.today` instead of `Time.current`/`Date.current`.
- **I18n:** hardcoded user-facing strings; keys missing in a locale file; dates/numbers not formatted with `l`/helpers.
