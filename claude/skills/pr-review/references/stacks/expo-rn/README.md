# Stack pack: Expo / React Native (TypeScript)

Load the area files below when the diff touches the matching paths (relative to the app root, which may be a
subdirectory such as `mobile/`).

| Area file | Load when the diff touches |
|---|---|
| `components-hooks.md` | `*.tsx`, hooks (`use*.ts`), screens, `app/` (Expo Router), navigation |
| `state-data.md` | local DB (SQLite/Drizzle schema, queries, migrations), stores, data fetching, sync, storage, cache |
| `performance.md` | lists, screens, images, animations, app start (`App.tsx`, root layout), effects |
| `platform-release.md` | `app.json`/`app.config.*`, `eas.json`, `ios/`, `android/`, native modules, permissions, assets, OTA updates, `package.json` |
| `tests.md` | `__tests__/`, `*.test.ts(x)`, or `src/` without a test change |
| `accessibility-i18n.md` | `*.tsx` with user-visible UI |

Context to read: `app.json` / `app.config.*`, the navigation tree, the DB schema (`src/db/schema.ts` or equivalent)
and generated migrations, generated API types before claiming a shape mismatch.

## Covered by tooling — don't flag

When CI runs them: TypeScript (`tsc --noEmit`) type errors, ESLint (`eslint-config-expo`: hooks rules of hooks /
exhaustive deps as warnings, unused vars, import order), Prettier formatting, `expo-doctor` (SDK/package version
mismatches), `npm audit`. Still flag an `eslint-disable` or `@ts-ignore`/`@ts-expect-error`/`as any` that hides a real
problem or lacks a reason.
