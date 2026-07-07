# Task 6 Report: First-Use Setup Guide UI

## Implementation

- Added first-use setup state to `SettingsView` and initialized `showingSetupGuide` from `!settings.hasSeenOnboarding`.
- Split the view body so first launch shows an inline setup guide before the normal settings panes.
- Added `setupGuideState` using `TextLensCore.SetupGuideState` to drive the `Finish Setup` enabled state.
- Added the inline setup guide UI with:
  - permission rows for Accessibility and Screen Recording
  - `Skip permissions for now`
  - target language picker
  - `Test Free Provider` that marks the translation path as tested before reusing `testFreeProvider()`
  - `Finish Setup` and `Continue To Settings`, both saving settings and marking onboarding complete
- Updated `AppShell.openSettingsOnFirstLaunch()` so it opens Settings without setting `hasSeenOnboarding` early.

## Checks

- `rtk swift build --product TextLens`
  - Passed
- `rtk swift run TextLensChecks`
  - Passed, printed `ok`

## Files Changed

- `Sources/TextLens/SettingsView.swift`
- `Sources/TextLens/AppShell.swift`
- `.superpowers/sdd/task-6-report.md`

## Self-Review

- The onboarding flag now flips only from the setup guide/settings path, matching the task brief.
- Existing settings panes, save actions, and provider test flow were preserved and reused instead of duplicating logic.
- Kept the setup guide inline in `SettingsView` as requested.
- Build caught one SwiftUI body-wrapper issue during verification; fixed by wrapping the conditional body in `Group` before final checks.

## Concerns

- `TextLensChecks` and the existing unit tests cover the shared model/state, but there is still no UI-level automated check for the first-launch guide transition itself.
