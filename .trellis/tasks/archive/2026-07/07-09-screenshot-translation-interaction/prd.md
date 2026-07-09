# Improve screenshot translation interaction

## Goal

Make screenshot translation feel faster and less interruptive, especially after OCR succeeds.

The current screenshot shows a large modal "Confirm OCR Text" dialog before translation, while the result popover behind it is still in "Recognizing text..." state. The user experience feels unfriendly because the workflow pauses on OCR text confirmation before showing any translation value.

## Confirmed Facts

- Screenshot translation is implemented in `Sources/TextLens/ScreenCaptureTranslator.swift`.
- The current flow captures the selected region, shows `Recognizing text...`, runs OCR, then calls `confirmOCRText(_:)` before translation.
- `confirmOCRText(_:)` uses `NSAlert` with `Translate`, `Copy OCR Text`, `Reselect`, and `Cancel` actions plus an editable `NSTextView`.
- If the user confirms, translation runs and the result popover displays both original and translation.
- `Sources/TextLens/ResultPopover.swift` already supports copying original text, copying translation, retrying, expanding, and closing.

## Requirements

- Preserve the ability to inspect and edit OCR text when recognition is wrong.
- After OCR succeeds, translate immediately without showing the blocking OCR confirmation dialog by default.
- Provide OCR correction through an explicit button in the result popover.
- The OCR correction button opens a small editor dialog with the recognized/original text and `Retranslate` / `Cancel` actions.
- In screenshot translation results, replace the current same-region `Retry` action with `Reselect` so the user can select a new screen region when the first capture/OCR result is poor.
- Hide/remove `Expand` from screenshot translation results to keep the action bar focused on the core screenshot workflow.
- Preserve clear button labels rather than shortening them just to fit a single row.
- Use a two-row action area for screenshot translation results so long button labels do not crowd or overlap.
- Keep existing useful screenshot actions available where relevant: copy original/OCR text, copy translation, close.
- Leave selection translation and clipboard translation behavior unchanged.

## Acceptance Criteria

- [ ] After selecting a screenshot region with recognizable text, the app proceeds from OCR to translation without an OCR confirmation modal.
- [ ] The result popover provides a clear button to correct OCR/original text and retranslate.
- [ ] Choosing the correction button opens a focused editor dialog; confirming it runs translation again using the edited text.
- [ ] Screenshot translation results expose `Reselect` instead of `Retry`, and `Reselect` starts a new screenshot selection.
- [ ] Screenshot translation results do not show `Expand`; the action bar remains compact with copy/edit/reselect/close actions.
- [ ] Screenshot translation result buttons keep clear labels and fit without overlap or cramped spacing.
- [ ] Screenshot translation result buttons are arranged across two rows: copy actions together, workflow actions together.
- [ ] Selection translation and clipboard translation keep their current behavior.
- [ ] Loading, empty-OCR, capture-failure, and translation-error states remain understandable.
- [ ] Existing result actions remain available or have an intentional replacement.

## Open Questions

- None.
