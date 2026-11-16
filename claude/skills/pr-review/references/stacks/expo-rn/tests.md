# Review checklist: Mobile tests

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Testing Library queries** by role/label/text (what the user sees), not test ids or component internals, unless
  no accessible query exists.
- **Async UI.** `findBy`/`waitFor` instead of fixed timers; fake timers restored.
- **Mocks.** Native modules mocked at the boundary; over-mocking that tests the mock; DB logic tested against a real
  in-memory SQLite rather than a mocked query layer when feasible.
- **Domain logic** extracted from components gets plain unit tests.
- **Snapshot tests** used as the only assertion for behavior.
