# Review checklist: Rails maintainability

Rails stack pack for pr-review: complements `core/maintainability.md`. The project guide overrides this file.

- **Conventional Rails first.** A new service object, concern, form object or gem where plain Rails (model method,
  scope, validation, `has_many through`) would do.
- **Fat controllers.** Business logic in a controller action instead of the model / domain object that owns it.
- **Concerns as junk drawers.** A concern included in one model, or mixing unrelated behavior.
- **Scopes vs class methods** inconsistently; query logic duplicated across controllers instead of a named scope.
- **Leftover debugging:** `binding.irb`, `debugger`, `pp`, `puts`.
