# Review checklist: Query performance

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (the repo review guide) override this file.

## Query performance

- **N+1.** An association accessed inside a loop in a view, component, serializer, mailer, or job, without `includes`/`preload`/`eager_load` where the collection is loaded. Trace to the loader before flagging. It's blocking on a list page that grows with data, and should-fix otherwise.
- **Queries in loops.** `each { |x| Model.where(...) }`, and `.count` or `.exists?` per row. Consider a grouped query, `index_by`, or a counter cache.
- **Unbounded loads.** `.all.each` or `.where(...).each` over a table that grows should use `find_each`/`in_batches`. Lists without pagination.
- **Loading records to read one column.** `map(&:id)` → `pluck(:id)` / `ids`; `present?` on a relation → `exists?`; `size` vs `count` vs `length` used in the wrong context.
- **Ruby-side filtering** (`select { }`, `sort_by`) of large collections that the database could do.
- **Missing `limit`** on "first/latest" style lookups done with `.last` on unordered relations. That is a correctness issue too.
- **Heavy work in a request** that belongs in a background job, such as external API calls or large exports.
