# Review checklist: Components & hooks

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Effects.** `useEffect` used for derived state (compute during render instead) or to respond to events (do it in
  the handler). Missing cleanup for subscriptions, timers, listeners. Async effects that set state after unmount or
  after deps changed (no cancellation / ignore flag). Dependency arrays silenced or wrong.
- **State shape.** Duplicated or derivable state that can drift; state lifted too high (re-renders the whole tree) or
  kept too low (prop drilling across many levels where context/store is the project convention).
- **Keys.** Index or non-stable keys in lists whose items move, insert or delete.
- **Business logic in components.** Domain rules, data mapping or persistence inside screen components instead of
  hooks / domain modules the project designates. Screens should compose, not compute.
- **Component size.** A screen mixing data loading, business rules and large JSX; extract by responsibility.
- **Navigation.** Params typed and validated (deep links can pass anything); screens that assume params exist;
  listeners not removed; navigation state that doesn't survive app kill when it should.
- **Platform differences.** iOS-only/Android-only behavior (keyboard avoidance, safe areas, back button, permissions
  prompts) handled or deliberately ignored.
- **Styling.** Hardcoded colors/sizes where the project has design tokens or a theme; dark mode ignored when supported.
