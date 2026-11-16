# Review checklist: Mobile performance

Expo / React Native stack pack for pr-review: complements the core checklist. Only comment when you can point at a
line and name the consequence. The project guide overrides this file.

- **Lists.** Long lists with `ScrollView` + `map` instead of a virtualized list (`FlatList`/`FlashList`); missing
  `keyExtractor`; heavy `renderItem` without memoization; inline closures re-creating every item.
- **Re-renders.** Context values or props recreated every render (new objects/arrays/functions) causing wide
  re-renders; selectors returning new references. Only flag on screens where it is measurable (lists, animations).
- **Main/JS thread.** Heavy synchronous work (parsing, sorting large arrays, crypto) on the JS thread during
  interaction; animations not on the native/UI thread (Reanimated worklets / `useNativeDriver`).
- **Images.** Full-resolution images for thumbnails; no caching; remote images where offline requires local files.
- **App start.** New synchronous work, large imports or blocking requests before first render.
- **Leaks.** Timers, listeners, subscriptions not cleaned up; growing in-memory caches.
