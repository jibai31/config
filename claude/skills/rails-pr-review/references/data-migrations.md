# Review checklist: Data integrity & migrations

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (`docs/review/` in the repo) override this file.

## Data integrity

- **Uniqueness validations** must be backed by a unique index. `validates :x, uniqueness: true` alone is a race condition.
- **Multi-record writes** that must succeed or fail together need a `transaction`. Look for two or more `save`/`update`/`create` calls in one method.
- **Ignored return values.** A `save`/`update` whose result is unchecked means failure is silent. Use the bang version, or handle `false`.
- **Validation-skipping calls.** `update_column(s)`, `update_all`, `insert_all`, `delete_all`, and `touch` skip validations and callbacks. Is that intended here?
- **find_or_create_by** without a unique index creates duplicates under concurrency. `create_or_find_by` requires the index.
- **Foreign keys and dependents.** New `has_many` or `belongs_to` associations: what happens on delete (`dependent:`, `on_delete:`)? Can orphans appear?
- **Nullability.** A new column the code assumes is always present should be `null: false`, with a default or a backfill.
- **Money** stored or computed as `Float` should be integer cents or `decimal`.
- **Time.** Use `Time.current`/`Date.current`, not `Time.now`/`Date.today`. Watch for comparisons across time zones and for date-boundary bugs.
- **State machines (AASM etc.).** New transitions: are guards and side effects correct? Does any code bypass the machine by assigning the state column directly?

## Migrations (PostgreSQL)

A migration that locks a busy table is a production incident, so treat real risks as blocking.

- **Indexes on existing tables** need `algorithm: :concurrently` plus `disable_ddl_transaction!`. This matters for large or hot tables. On a tiny table, downgrade to a nit or skip it.
- **Foreign keys on large tables:** add with `validate: false`, then validate in a separate migration.
- **Changing a column type, or renaming a column or table,** rewrites or breaks the running app during deploy. Expand-and-contract is safer: add the new column, backfill, switch reads, then drop the old one.
- **Removing a column** requires `self.ignored_columns += [...]` in the model to ship *before* the drop, or running processes will error.
- **Data backfills** don't belong inside schema migrations on large tables: they run in one long transaction. Prefer a separate task or job, batched with `in_batches`.
- **Missing indexes:** every new foreign key column, and columns used in new `where`/`order`/`joins`. Confirm against `db/schema.rb` first.
- **Reversibility:** `change` must be reversible, or define `up`/`down`.
- **Adding `null: false` to an existing column** fails, or locks the table, if data isn't backfilled first.
