---
stacks: [expo-rn]
max_rounds: 3
---

# Review guide

Rules: [architecture.md](architecture.md).

## Severity overrides

- Blocking: a screen or component reading server data directly instead of from SQLite (architecture rule 1), or any
  network call outside `src/sync/` (rule 2).
