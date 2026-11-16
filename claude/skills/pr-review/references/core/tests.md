# Review checklist: Tests

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **New behavior has a test** — new branch, public function, endpoint, screen behavior, migration with data logic. A
  bug fix without a regression test is should-fix.
- **Coverage of the unhappy paths:** failure, authorization ("another user gets 404"), empty and boundary inputs, not
  just the happy path.
- **Tests at the right level.** Logic tested through the UI/E2E when a unit test would do (slow, flaky), or a unit
  test so mocked it tests the mocks.
- **Implementation coupling.** Assertions on private methods, internal state or exact call counts that break on any
  refactor without catching a real bug.
- **Determinism.** Fixed sleeps/waits, reliance on ordering without explicit sort, real time without freezing it, real
  network, shared state between tests, random data without a seed.
- **Test data.** Factories/fixtures creating far more than needed; magic values whose meaning isn't clear.
- **Deleted, skipped or weakened tests** (assertion removed, `.skip`, `xit`, `pending`) need a stated reason.
- **Test names** state the behavior, so a failure says what broke.
