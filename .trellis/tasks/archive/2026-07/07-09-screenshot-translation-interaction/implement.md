# Improve screenshot translation interaction implementation plan

## Checklist

- [x] Load frontend/Trellis context before editing.
- [x] Extend `ResultPopover` with optional screenshot actions and a two-row screenshot layout.
- [x] Update `ScreenCaptureTranslator` to translate immediately after OCR.
- [x] Add `Edit Original` flow that opens a small editor dialog and retranslates edited text.
- [x] Change screenshot result retry behavior to `Reselect`.
- [x] Hide `Expand` for screenshot results while preserving it for selection/clipboard results.
- [x] Run the smallest available Swift build/test check.

## Validation

- `swift test` if this package has tests.
- Otherwise run the available build command from the package metadata.
- Manual smoke target: screenshot translate should show `Recognizing text...`, then `Translating...`, then a result without an OCR confirmation modal.

## Risk Points

- `ResultPopover` is shared by screenshot, selection, and clipboard translation; defaults must preserve existing callers.
- Button frames are manual AppKit layout, so two-row coordinates must be checked for overlap.
