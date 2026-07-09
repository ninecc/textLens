# Fix screenshot reselect and multi-screen capture implementation plan

## Checklist

- [x] Load current task artifacts and frontend guidelines before editing.
- [x] Add a public `ResultPopover` method that closes only the main popover.
- [x] Change screenshot `Reselect` callbacks to dismiss the main popover before selection starts.
- [x] Track the active selection screen from the current mouse location at selection start.
- [x] Switch active screen when the pointer enters another screen overlay.
- [x] Lightly distinguish active and inactive screen overlays.
- [x] Run `swift test`.

## Validation

- `swift test`
- Manual smoke target:
  - `Reselect` hides the result popover before overlays appear.
  - On multi-display setups, the display under the mouse is active first.
  - Moving the pointer to another display changes the active overlay.
  - Dragging works without a preliminary activation click.

## Risk Points

- AppKit window focus and mouse tracking behavior varies across Spaces and displays.
- Selection overlays are full-screen borderless windows; visual changes should stay subtle.
