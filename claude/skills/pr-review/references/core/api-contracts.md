# Review checklist: API contracts & module interfaces

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **Breaking changes.** Removing/renaming a field, changing a type, making optional → required, changing error
  shapes or status codes, for an API that deployed clients (mobile apps in stores!) still call. Needs versioning or
  expand-and-contract.
- **Contract source of truth.** Request/response shapes defined where the project says they are (spec, schema,
  generated types) and generated artifacts regenerated, not hand-edited.
- **Consistency.** Naming, casing, pagination, error format, timestamp format consistent with existing endpoints.
- **Validation at the boundary.** Input validated where it enters; client code doesn't trust server data shapes
  without the generated types.
- **Error handling contract.** Clients handle the documented error cases; servers return them consistently.
- **Module interfaces.** Public functions/components/hooks: minimal surface, clear names, no exposed internals; a
  change to one updates all its callers in the same PR.
