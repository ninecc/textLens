# Improve screenshot translation interaction design

## Boundaries

- Scope is screenshot translation only.
- `SelectionTranslator` and clipboard translation keep their current result popover behavior.
- No new dependencies or new UI framework.

## Flow

1. `ScreenCaptureTranslator.translate(region:on:)` captures the region and runs OCR.
2. If OCR returns text, it immediately shows the translating state and calls translation with the OCR text.
3. The final screenshot result popover includes screenshot-specific actions:
   - `Copy Original`
   - `Copy Translation`
   - `Edit Original`
   - `Reselect`
   - `Close`
4. `Edit Original` opens a small editor dialog seeded with the original/OCR text. `Retranslate` translates the edited text and updates the result.
5. `Reselect` starts a new screenshot selection.

## UI Contract

- Screenshot result actions use two rows:
  - Row 1: copy actions.
  - Row 2: edit/reselect/close workflow actions.
- Screenshot results hide `Expand`.
- Non-screenshot callers continue using the existing single-row result popover.

## Implementation Shape

- Extend `ResultPopover.show` with optional screenshot-only parameters for edit/reselect actions and layout mode.
- Keep existing defaults so current selection/clipboard callers do not change.
- Remove the blocking default use of `confirmOCRText(_:)`; keep or reshape the editor helper for optional OCR correction.

## Rollback

- Revert the `ResultPopover` parameter extension and restore the `confirmOCRText(_:)` call before translation.
