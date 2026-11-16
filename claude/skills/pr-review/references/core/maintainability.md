# Review checklist: Maintainability

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

Default severity is should-fix or nit; the project guide decides what is blocking. The question for every finding:
*which future change does this make harder, more error-prone or slower?* Name it.

## Structure and boundaries

- **Layering.** Code placed in the wrong layer per the project's architecture (business rules in UI components or
  controllers, persistence details leaking into views, network calls from where the architecture forbids them).
- **Coupling.** A module reaching into another's internals, a new dependency direction that creates a cycle, a
  shared "utils" grab-bag growing.
- **Single source of truth.** The same fact (a constant, a rule, a mapping, a type) defined in two places that will
  drift. Generated artifacts edited by hand.
- **Duplication.** Logic that already exists elsewhere — name the existing function/component. Copy-pasted blocks
  that differ in one value.

## Abstractions

- **Premature abstraction.** A new layer, base class, config option, generic helper or plugin point with a single
  caller and no stated second use. Indirection that makes the code harder to follow than the duplication it avoids.
- **Missing abstraction.** The third copy of the same pattern; a function that does several unrelated things; a
  conditional on type/kind repeated in many places.
- **Leaky interfaces.** Booleans/flags that switch behavior (`doThing(x, true, false)`), long positional parameter
  lists, return values that need the caller to know internals.

## Readability

- **Naming.** Names that mislead (`find` that creates, `isX` that mutates), vague names (`data`, `handle`, `process`),
  inconsistent with the domain vocabulary the project uses.
- **Complexity.** Deep nesting, long functions mixing levels of abstraction, clever code where plain code would do.
- **Comments.** Comments that restate the code, or are now wrong. Missing *why* on non-obvious code (a workaround, a
  performance trick, a business rule).
- **Dead code.** Unused functions, params, exports, feature flags, commented-out code, leftover debugging.

## Docs drift

- A change in behavior, data model, API or architecture without the matching doc update the project requires
  (README, architecture docs, ADRs, data-model docs).
- A doc that restates rules owned by another doc instead of linking to it.
