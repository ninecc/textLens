# TextLens Next-Stage Retention PRD

Date: 2026-07-07

## 1. Goal

Move TextLens from a useful translation utility to a daily macOS reading
assistant that users keep in the menu bar and reuse throughout the day.

The current MVP already covers selected text translation, clipboard translation,
screenshot OCR translation, settings, secure credentials, retry, copy controls,
history, glossary, provider comparison, and expanded result viewing. This PRD
therefore focuses only on the next retention layer: first-use completion,
reusing past results, reading long translations, and returning from the menu bar.

## 2. Non-Goals

- Account system.
- Cloud sync.
- Browser extensions.
- Team terminology libraries.
- Offline translation models.
- Complex tags or folders for history.
- Provider marketplace or plugin system.

These can wait until local daily usage is proven.

## 3. Target Users

- macOS knowledge workers who read foreign-language material daily.
- Developers and researchers reading docs, issues, papers, logs, or screenshots.
- Students and operations users who translate chats, emails, images, or PDFs.

## 4. Product Principle

TextLens should stay lightweight: one menu bar app, fast keyboard entry, local
history, and clear recovery when macOS permissions or translation providers fail.
Every new feature must reuse the current app shape unless it clearly improves a
daily workflow.

## 5. Success Metrics

Measure these through dogfood sessions, beta feedback, or explicit opt-in local
diagnostics. This stage does not add default telemetry.

- First-use setup completion rate is above 70%.
- Median first-use setup time is under 2 minutes.
- Day-7 retention is above 25%.
- Average translations per active user per day is above 5.
- At least 20% of active users use history search or favorites weekly.
- At least 40% of expanded long-text sessions end with copy, favorite, or retry.

## 6. P0 Requirements

### 6.1 First-Use Setup Guide

First launch should guide the user through the minimum setup needed to get a
successful translation.

Requirements:

- Show a three-step setup flow: permissions, target language, translation source
  test.
- Detect Accessibility and Screen Recording status using the existing permission
  checks.
- Provide one primary action per missing permission: open the relevant macOS
  settings pane.
- Let users keep the default free provider without creating an API setup burden.
- Let users test the selected free provider.
- Let users enable API fallback only as an optional advanced step.
- Mark setup complete after required permissions are granted or explicitly
  skipped, target language is selected, and at least one translation path has
  been tested or skipped.
- Keep the existing Settings view available after setup.

Acceptance criteria:

- A new user can understand what is blocking TextLens without reading docs.
- A user who only wants free translation can finish setup without seeing API
  credential fields as mandatory.
- Failed provider tests show a short explanation and a retry action.

### 6.2 History Search And Favorites

The existing local history should become useful for repeated reading without
becoming a knowledge-base product.

Requirements:

- Search local history by original text and translated text.
- Favorite or unfavorite a history item.
- Filter history to favorites.
- Copy original text or translated text from a history item.
- Re-run translation for a history item using current settings.
- Keep history local and governed by the existing history enabled setting.
- Preserve the existing lightweight retention limit unless the user favorites an
  item.

Acceptance criteria:

- A user can find a translation from earlier in the day in under 10 seconds.
- Favorites are not removed by the normal recent-history limit.
- Disabling history stops new non-favorite history storage.

### 6.3 Long-Text Result Window

Expanded results should support reading and acting on longer translations.

Requirements:

- Preserve paragraph breaks and readable spacing for original and translated
  text.
- Provide copy all, retry translation, and favorite actions.
- Keep the popover lightweight; long-text controls live in the expanded window.
- Show provider or fallback status when available.
- Keep the window keyboard-friendly: Escape closes, Command-C copies selected
  text through native behavior.

Acceptance criteria:

- A multi-paragraph translation is readable without horizontal scrolling.
- A user can copy the full translation with one action.
- Retry uses the same original text and current translation settings.

### 6.4 Menu Bar Recent Results

The menu bar should give users a quick return path to recent work.

Requirements:

- Show the three most recent history items in the menu bar menu.
- Each recent item opens the expanded result window.
- Add an Open History menu item when history is enabled.
- Hide recent items when history is disabled or empty.
- Keep core actions visible: Translate Selection, Translate Clipboard,
  Screenshot Translate, Settings, Quit.

Acceptance criteria:

- Recent results do not push primary actions out of sight.
- History-disabled users do not see empty or misleading history controls.
- Selecting a recent item does not trigger a new translation unless the user
  chooses retry.

## 7. P1 Requirements

### 7.1 Shortcut Conflict Guidance

When a shortcut fails to register, tell the user which TextLens shortcut failed
and suggest choosing another key in Settings.

### 7.2 OCR Confirmation Actions

OCR confirmation should include Copy OCR Text and Reselect Region actions so a
bad recognition result is recoverable without restarting from the menu.

### 7.3 Favorites Export

History export should support exporting all history or favorites only.

### 7.4 Settings Simplification

Settings should show daily-use controls first and keep provider credentials,
API fallback, and provider comparison behind clearly labeled advanced sections.

## 8. User Flows

### 8.1 First Use

1. User launches TextLens.
2. TextLens opens the setup guide.
3. User grants required permissions or skips with visible consequences.
4. User chooses a target language.
5. User tests the default free provider.
6. TextLens shows ready status and closes the guide.

### 8.2 Repeat Translation

1. User translates selected text, clipboard text, or a screenshot region.
2. Result appears in the popover.
3. User opens expanded view for longer text.
4. User copies, favorites, retries, or closes.
5. TextLens stores the result locally when history is enabled.

### 8.3 Return To Recent Translation

1. User opens the TextLens menu bar menu.
2. User selects one of the recent history items.
3. TextLens opens the expanded result window.
4. User copies, favorites, or retries.

## 9. Error Handling

- Missing permissions show the relevant setup step and a single Open Settings
  action.
- Provider test failures show the provider name, short failure text, and Retry.
- Empty history search shows a neutral empty state and a Clear Search action.
- Favorite storage failures should not block translation; show a short local
  error message.
- Retrying a result should reuse current settings and surface provider fallback
  errors through the existing result error pattern.

## 10. Privacy And Storage

- History remains local.
- Favorites remain local.
- No account, sync, telemetry, or remote storage is introduced by this stage.
- Existing Keychain credential storage remains the credential boundary.
- Users can disable history and clear stored history from Settings.

## 11. Testing Requirements

- Unit tests for history search, favorites, favorite retention, and export mode.
- Unit tests for setup completion state transitions.
- Existing checks must continue to pass: `swift run TextLensChecks`.
- Manual smoke test for first launch, menu bar recent items, expanded result
  actions, and history-disabled behavior.

## 12. Open Risks

- macOS permission flows vary by OS version and may still require manual user
  action outside TextLens.
- Menu bar space is limited; recent results must stay short.
- Favorites can grow without a cap; keep the first version local and simple, then
  add limits only if real usage shows a problem.
- Provider reliability still depends on external services; this PRD improves
  recovery and reuse, not provider quality itself.
