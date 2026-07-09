# Fix screenshot reselect and multi-screen capture

## Goal

Fix two screenshot-translation interaction regressions:

- `Reselect` should hide the existing translation popover before entering selection mode.
- Multi-screen screenshot selection should work on the screen the user interacts with without requiring a manual activation click on that display first. When the mouse enters a screen, that screen should become the active selection screen.

## Confirmed Facts

- `Sources/TextLens/ScreenCaptureTranslator.swift` wires screenshot result `Reselect` to `start()` without first closing the current `ResultPopover`.
- `Sources/TextLens/ResultPopover.swift` has a private `close()` selector but no public close/dismiss API for callers.
- `ScreenCaptureTranslator.start()` creates one `RegionSelectionWindow` per `NSScreen`.
- `ScreenCaptureTranslator.start()` then calls `makeKeyAndOrderFront` on each selection window in sequence, which leaves only the last window as key.
- `Sources/TextLens/RegionSelectionWindow.swift` uses `level = .screenSaver`, transparent borderless windows, and a per-window `RegionSelectionView` that handles drag selection.

## Requirements

- Hide/dismiss the existing translation result popover before `Reselect` enters screenshot selection mode.
- `Reselect` only needs to close the main translation popover; expanded result windows are out of scope for this fix.
- Preserve the current screenshot selection behavior on single-display setups.
- Improve multi-display screenshot selection so the user can start dragging on the intended display without first manually activating that display.
- When the pointer moves into a covered display, that display should become the active selection surface automatically.
- When screenshot selection starts, the display containing the current mouse pointer should be active by default.
- Apply a lightweight selection overlay improvement: active display keeps the normal drag hint/selection affordance, inactive displays are visually softer and become active when the pointer enters them.
- Keep the fix scoped to screenshot translation and shared popover dismissal mechanics only.

## Acceptance Criteria

- [ ] Clicking screenshot result `Reselect` removes the existing translation popover before selection overlays appear.
- [ ] `Reselect` does not need to close expanded result windows.
- [ ] On a multi-display setup, starting screenshot translate lets the user select a region on any covered display without a separate manual activation click.
- [ ] Moving the pointer into a display makes that display active for screenshot selection.
- [ ] The display containing the mouse pointer is active immediately when screenshot selection starts.
- [ ] The selection overlay lightly distinguishes the active display from inactive displays without a full redesign.
- [ ] Selection cancellation with Esc still closes selection overlays.
- [ ] Existing selection/clipboard translation result behavior is unchanged except for any new no-op-safe popover dismissal API.

## Open Questions

- None.
