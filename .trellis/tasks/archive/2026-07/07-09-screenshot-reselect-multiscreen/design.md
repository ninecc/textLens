# Fix screenshot reselect and multi-screen capture design

## Boundaries

- Scope is screenshot translation selection flow.
- Do not change selection translation or clipboard translation.
- Do not redesign the result popover or add new dependencies.

## Flow

1. Screenshot result `Reselect` closes only the main result popover.
2. Screenshot selection starts with one overlay window per screen.
3. The screen containing `NSEvent.mouseLocation` starts active.
4. When the pointer enters another overlay window, that screen becomes active.
5. All screens remain draggable; active state is a visual/event focus aid, not a restriction.

## UI Contract

- Active screen: normal overlay hint and selection affordance.
- Inactive screens: softer/dimmer hint or overlay treatment.
- Moving the pointer across displays updates the active visual state.
- Esc still cancels selection from whichever overlay receives it.

## Implementation Shape

- Add a public main-window dismissal method to `ResultPopover`.
- Route screenshot `Reselect` through a small helper on `ScreenCaptureTranslator` that dismisses the popover, then calls `start()`.
- Extend `RegionSelectionWindow` / `RegionSelectionView` with active state and mouse-tracking enter handling.
- Keep the implementation minimal: a shared active-screen closure and per-window `isActive` updates are enough.

## Rollback

- Revert `Reselect` to calling `start()` directly.
- Remove active-state handling from region selection windows.
