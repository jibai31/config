# Review checklist: Accessibility & i18n

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Accessible names.** Touchables/icons without `accessibilityLabel` / `accessibilityRole`; images conveying
  information without a label.
- **Touch targets** smaller than ~44pt; content that breaks at large font scales (fixed heights, `numberOfLines`
  clipping meaning).
- **Contrast** below WCAG AA on text, when the project defines colors.
- **Strings.** Hardcoded user-facing strings where the project localizes; concatenated sentences (word order differs
  per language); plurals without plural rules; dates/numbers not formatted per locale.
