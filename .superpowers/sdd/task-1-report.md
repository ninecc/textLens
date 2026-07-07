# Task 1 Report: History Search, Favorites, And Export Modes

## What I implemented
- Updated `Sources/TextLensCore/TranslationHistoryStore.swift` to include:
  - `TranslationHistoryItem.isFavorite`.
  - `TranslationHistoryStore.add(original:translated:) -> TranslationHistoryItem` with return value and dedupe/favorite retention behavior.
  - `TranslationHistoryStore.item(id:)`.
  - `TranslationHistoryStore.toggleFavorite(id:)`.
  - `TranslationHistoryStore.search(_ query:favoritesOnly:)`.
  - `TranslationHistoryStore.exportText(favoritesOnly:)`.
  - Favorite-aware retention logic so favorites are preserved beyond the recent-history limit.
  - Backward-compatible decoding for older persisted items missing `isFavorite` (defaults to `false`).
- Added tests to `Tests/TextLensTests/TranslationHistoryStoreTests.swift`:
  - `testSearchMatchesOriginalAndTranslationCaseInsensitively`
  - `testFavoritesSurviveRecentHistoryLimit`
  - `testFavoriteFilterAndExportFavoritesOnly`
  - `testDisabledHistoryDoesNotAddNewNonFavoriteItems`
  - Kept existing tests intact.

## Tests run and results
- `rtk swift test --filter TranslationHistoryStoreTests` (first attempts without escalation): failed before compile due sandbox/cache restrictions (`/Users/pp/.cache/clang/ModuleCache` not writable and `sandbox-exec` errors).
- `rtk swift test --filter TranslationHistoryStoreTests` (run with escalation): executed and failed as expected against old API surface (missing `search`, `toggleFavorite`, `add` return type, `exportText(favoritesOnly:)`) — RED phase.
- `rtk swift test --filter TranslationHistoryStoreTests` (run with escalation after implementation): **PASS**, 6 tests.
- `rtk swift run TextLensChecks` (run with escalation): **PASS** (`Build of product 'TextLensChecks' complete... ok`).

## TDD evidence
- RED command/output:
  - `rtk swift test --filter TranslationHistoryStoreTests` (with implementation still old) produced compile errors for missing members (`search`, `toggleFavorite`, `exportText(favoritesOnly:)`) and `add(...)` return type mismatch (`()`, warnings and key-path inference errors in new tests).
- GREEN command/output:
  - `rtk swift test --filter TranslationHistoryStoreTests` after code changes passed all selected tests:
    - `Executed 6 tests, with 0 failures (0 unexpected) in 0.016 (0.017) seconds`

## Files changed
- `Sources/TextLensCore/TranslationHistoryStore.swift`
- `Tests/TextLensTests/TranslationHistoryStoreTests.swift`
- `.superpowers/sdd/task-1-report.md`

## Self-review findings
- The implementation follows the brief exactly and preserves existing history ordering (most recent first).
- Favorite items are kept even when recent-history limit is exceeded.
- Search uses `localizedCaseInsensitiveContains` on both original and translated text.
- `add(...)` now returns the created/found item, aligning with required API and supporting tests.
- `exportText(favoritesOnly:)` now reuses the search path for consistent filtering.

## Concerns
- Test execution in this environment initially required escalating because of sandboxed SwiftPM/clang cache restrictions; I retried in escalated mode to collect actionable results.
