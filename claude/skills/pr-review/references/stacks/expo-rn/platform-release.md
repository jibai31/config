# Review checklist: Platform, config & release

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Native changes vs OTA.** A change needing a new native build (new native module, permission, config plugin,
  `app.json` native field, SDK bump) shipped as if OTA-compatible; runtime version / fingerprint policy respected.
- **Permissions.** New permission without usage description strings (iOS) or with broader scope than needed; requested
  at launch instead of in context; denial path handled.
- **Config.** Secrets in `app.json`/`app.config` or `EXPO_PUBLIC_*` env vars (they ship in the bundle). Bundle id,
  scheme or version changed by accident.
- **Prebuild drift.** Hand edits in `ios/`/`android/` that `expo prebuild` would wipe, when the project uses CNG;
  config belongs in config plugins.
- **Dependencies.** Not installed via `npx expo install` (SDK-incompatible version); native module without Expo
  support in a managed/CNG project.
- **Store rules.** Content or features that conflict with store policies or with the project's legal rules.
