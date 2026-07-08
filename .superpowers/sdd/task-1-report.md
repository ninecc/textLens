# Task 1 Report: Make Setup Completion Permission-Based

## What I changed
- `Tests/TextLensTests/SetupGuideStateTests.swift`
  - Replaced with the brief’s exact cases:
    - `testIncompleteWhenPermissionsMissingAndNotSkipped`
    - `testCompleteWhenPermissionsGrantedAndLanguageSelectedWithoutProviderTest`
    - `testCompleteWhenPermissionsSkippedAndLanguageSelectedWithoutProviderTest`
    - `testIncompleteWithoutTargetLanguage`
- `Sources/TextLensCore/SetupGuideState.swift`
  - Updated `isComplete` to require:
    - permissions ready (`skippedPermissions` is true, or both permissions granted), and
    - non-empty trimmed `targetLanguage`.
  - Removed `testedTranslationPath` as a required condition.
- `Sources/TextLens/SettingsView.swift`
  - Replaced setup footer `HStack` so it only has:
    - `Spacer()`
    - `Button("Finish Setup")` with `.disabled(!setupGuideState.isComplete)`
  - Removed competing “Continue To Settings” button.
  - Left the `Test Free Provider` button and status text unchanged.

## TDD evidence
- **RED step (as requested):**
  - `swift test --filter SetupGuideStateTests`
  - Expected fail observed: `testCompleteWhenPermissionsGrantedAndLanguageSelectedWithoutProviderTest` failed because `isComplete` still required `testedTranslationPath`.
- **GREEN step:**
  - `swift test --filter SetupGuideStateTests`
  - Result: PASS (4 tests, 0 failures).
- **Task checks:**
  - `swift build`
  - Result: PASS.

## Tests and results
- `swift test --filter SetupGuideStateTests` (first run, in-progress check): failed for environment cache permission error when building manifest (`/Users/didi/.cache/clang/ModuleCache` not writable) before retry.
- `swift test --filter SetupGuideStateTests` (escalated rerun): FAIL (expected, `testCompleteWhenPermissionsGrantedAndLanguageSelectedWithoutProviderTest`).
- `swift test --filter SetupGuideStateTests` (post-change): PASS, 4/4.
- `swift build`: PASS.

## Files changed
- `Sources/TextLensCore/SetupGuideState.swift`
- `Tests/TextLensTests/SetupGuideStateTests.swift`
- `Sources/TextLens/SettingsView.swift`
- `.superpowers/sdd/task-1-report.md`

## Self-review
- Implementation is minimal and scoped to the required contract shift: setup completion no longer blocks on provider test.
- `testedTranslationPath` remains present for provider test UI state and is not removed.
- Setup footer now has only one completion action, matching the brief.

## Concerns
- Two commands required escalated execution due sandbox restrictions (`swift` toolchain cache path and `git` index lock).

## Commit
- `9a8450a` — `fix: simplify setup completion`

- Task 1 review finding fix (skipped-permissions path):
  - Command: `swift test --filter SetupGuideStateTests`
  - Output: `PASS` (4 tests, 0 failures) after environment-adjusted rerun.
  - Files changed: `Tests/TextLensTests/SetupGuideStateTests.swift`
  - Commit: `9bb8409`
