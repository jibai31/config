# Review checklist: Design

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (`docs/review/` in the repo) override this file.

## Design (should-fix or nit, rarely blocking)

- Duplicated logic that already exists elsewhere in the codebase. Name the existing method.
- Dead code, commented-out code, and leftover debugging (`binding.irb`, `puts`, `pp`, `console.log`).
- Names that mislead: a method that says `find` but creates, or a boolean without `?`.
- A new abstraction (service, concern, gem) introduced where plain Rails would do. Prefer conventional Rails solutions.
- New gems: is it maintained? Does it duplicate something already in the Gemfile? Is it a heavy dependency for a small need?
