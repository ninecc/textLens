# TextLens Minimal Effective Refactor PRD

Date: 2026-07-08

## 1. Goal

Make the current TextLens macOS app feel clearer and harder to misclick without
changing its architecture. This pass focuses on three small user-facing
frictions: first setup completion, Settings button states, and screenshot/result
copy clarity.

## 2. Product Principle

Keep TextLens lightweight. Reuse the existing SwiftUI Settings view and AppKit
selection/result windows. Do not introduce a design system, visual reskin, or
SwiftUI rewrite for the result popover.

## 3. Scope

### 3.1 First Setup Page

Current issue: setup treats testing the free provider as mandatory before
`Finish Setup` can be used, and `Finish Setup` / `Continue To Settings` overlap
semantically.

Requirements:

- Let setup complete once required permissions are granted, or the user chooses
  to skip permissions for now.
- Keep target language selection required.
- Keep provider testing available as an optional action.
- Remove the ambiguous two-primary-action setup ending.
- Use one clear completion action: `Finish Setup`.
- Keep provider test status visible when the optional test is run.

Acceptance criteria:

- A user with required permissions can finish setup without testing a provider.
- A user who skips permissions can still enter Settings deliberately.
- The setup page does not show both `Finish Setup` and `Continue To Settings` as
  competing ways to leave the flow.

### 3.2 Settings Interaction States

Current issue: history actions and save state look actionable even when they do
nothing useful.

Requirements:

- Disable `Clear History` when there are no history items.
- Disable `Export All` when there are no history items.
- Keep `Export Favorites` disabled when there are no favorites.
- Make `Save` look actionable only when there are unsaved changes.
- Preserve existing Settings layout and panes.

Acceptance criteria:

- Empty history cannot be cleared or exported.
- After saving, `Save` no longer presents as an active change action.
- Changing any saved setting makes `Save` actionable again.

### 3.3 Screenshot Selection Hint And Result Window

Current issue: the screenshot overlay only says `Esc to cancel`, and result
actions use fixed AppKit button frames that can crowd each other.

Requirements:

- Change the selection overlay hint to `Drag to select, Esc to cancel`.
- Keep the overlay AppKit-based.
- Keep the result popover and expanded result window AppKit-based.
- Adjust result copy/action wording, button enabled states, and layout so buttons
  do not crowd each other.
- Preserve existing actions: copy original, copy translation, retry, expand,
  copy all, favorite, close.

Acceptance criteria:

- Screenshot selection clearly tells the user how to start and how to cancel.
- Loading/empty result states do not expose misleading copy or retry actions.
- Expanded result buttons remain readable at the default window size.

## 4. Non-Goals

- No broad visual redesign.
- No full design system.
- No Settings architecture rewrite.
- No SwiftUI rewrite of the result popover.
- No new translation providers.
- No telemetry.
- No history model changes beyond button state behavior.

## 5. Implementation Notes

- `SetupGuideState.isComplete` should stop depending on provider test success.
- `SettingsView` should track whether the current draft differs from the last
  saved values instead of using `saved` as the only visual source of truth.
- History buttons can derive disabled state from `historyStore.items.isEmpty`.
- `RegionSelectionWindow` only needs copy and bubble sizing changes.
- `ResultPopover` should stay in one file unless a smaller helper already exists.

## 6. Test Requirements

- Update `SetupGuideStateTests` for permission-only setup completion.
- Add or update the smallest settings-state test available for dirty/save
  behavior if this logic is in `TextLensCore`.
- Run:
  - `swift build`
  - `swift test`

## 7. Release Check

- Fresh launch setup can be completed after permissions are ready.
- Optional free provider test still runs and reports status.
- Empty history shows disabled `Clear History` and `Export All`.
- Unsaved Settings changes visibly enable `Save`; saving disables it again.
- Screenshot selection hint reads `Drag to select, Esc to cancel`.
- Result and expanded result buttons do not overlap at default sizes.
