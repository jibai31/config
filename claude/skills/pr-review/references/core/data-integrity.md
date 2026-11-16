# Review checklist: Data integrity & concurrency

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **Constraints in the database,** not only in app code: uniqueness, not-null, foreign keys, check constraints. A
  uniqueness check in code alone is a race.
- **Atomicity.** Several writes that must succeed or fail together without a transaction. Partial failure leaves
  inconsistent state.
- **Idempotency.** Anything retried (jobs, sync pushes, webhooks, client retries on timeout) must not double-apply.
  Look for a client-generated id, unique key or state check.
- **Concurrency.** Read-modify-write without locking or an atomic update; lost updates; check-then-act races.
- **Migrations.** Locking a large table, non-reversible without `down`, renaming/dropping what running code still
  reads, data backfills in schema migrations, `not null` added before backfill. Expand-and-contract for breaking
  changes.
- **Deletion semantics.** What happens to dependents on delete; soft vs hard delete consistency; orphans.
- **Money and precision.** Floats for money; rounding in the wrong place.
- **IDs and ordering.** Relying on auto-increment order, timestamps for ordering across clocks/devices, client clocks
  trusted for server decisions.
- **Offline / sync** (when the app has it): conflict resolution matches the documented protocol; cursors and outbox
  entries advance only after success; local and server schema stay in step.
