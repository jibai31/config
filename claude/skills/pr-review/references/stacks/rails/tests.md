# Review checklist: Rails tests (RSpec)

Rails stack pack for pr-review: complements `core/tests.md`. The project guide overrides this file.

- **Request specs** over controller specs for endpoints; cover the unauthorized and other-user cases.
- **Time-dependent specs** without `travel_to` / `freeze_time`.
- **Factories** creating more than needed (`create` where `build`/`build_stubbed` would do; cascades of associations).
- **System specs** with `sleep` or without Capybara's waiting matchers.
- **API specs** (rswag or similar) updated when an endpoint's contract changes, when the project generates contracts
  from them.
