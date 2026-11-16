# Stack pack: Rails

Load the area files below when the diff touches the matching paths (paths relative to the Rails root, which may be a
subdirectory such as `backend/`).

| Area file | Load when the diff touches |
|---|---|
| `correctness.md` | any Ruby file |
| `maintainability.md` | `app/` |
| `tests.md` | `spec/`, `test/`, or `app/` without a spec change |
| `security.md` | `app/controllers/`, `config/routes*`, policies/abilities, API, auth, webhooks, uploads, `html_safe`/`raw` |
| `data-migrations.md` | `db/`, `app/models/`, state machines, code writing several records |
| `performance.md` | `app/controllers/`, `app/views/`, `app/components/`, serializers, queries, jobs iterating over records |
| `jobs-integrations.md` | `app/jobs/`, `app/workers/`, `perform_async`/`perform_later`, HTTP clients, services calling APIs |
| `views-components.md` | `app/controllers/`, `app/views/`, `app/components/`, helpers, decorators, `app/javascript/` |

Context to read: `db/schema.rb` (or `structure.sql`) before claiming a missing index/constraint; `config/routes.rb`
for new endpoints; `.rubocop.yml`.

## Covered by tooling — don't flag

When CI runs them (check `ci_checks` / the workflow files): RuboCop (style, layout, Rails/RSpec/performance cops),
Brakeman (common vulnerability patterns), bundler-audit (vulnerable gems).
