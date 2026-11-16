# Review checklist: State, local data & sync

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Source of truth.** Data read from the place the architecture designates (e.g. the local DB for offline-first
  apps), not from a parallel in-memory copy or directly from the network.
- **Offline behavior.** Every new user action works offline when the app is offline-first: write locally, queue for
  sync. No spinner waiting on the network for core flows. Network errors handled, not thrown into the UI.
- **Local schema changes** come with a generated migration (e.g. `drizzle-kit generate`), never a hand-edited
  generated file, and run safely on an existing install with data (upgrade path, defaults for new non-null columns).
- **Writes.** Multi-row writes in a transaction; ids generated client-side where sync requires it; timestamps from
  the agreed source.
- **Sync.** Outbox/queue entries created in the same transaction as the local write; idempotent push; cursor advanced
  only after the batch is applied; conflict handling as documented.
- **Storage choice.** Secrets/tokens in secure storage (`expo-secure-store`), not AsyncStorage/SQLite; large files in
  the file system, not the DB; nothing important in caches the OS may purge.
- **Queries.** Reactive queries re-running on unrelated changes; loading full tables to show a count or a page.
