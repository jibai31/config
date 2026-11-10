# Review checklist: Tests

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (`docs/review/` in the repo) override this file.

## Tests

- **New behavior** (new branch, new public method, new endpoint, bug fix) has a test. A bug fix without a regression test is should-fix.
- **Coverage** includes the failure path and the authorization path ("user from another account gets 404"), not just the happy path.
- **Implementation coupling.** Tests that assert on implementation details (private methods, exact query counts without reason) and would break on refactoring.
- **System test flakiness.** `sleep`, fixed waits, or reliance on ordering without `order`.
- **Time-dependent tests** without `travel_to`/`freeze_time`.
- **Factories** creating far more records than needed, which slows the suite.
- **Deleted or skipped tests** in the PR need a stated reason.
