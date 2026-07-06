# TextLens Product Experience Report

Date: 2026-07-06

## 1. Product Positioning

TextLens is a native macOS menu bar translation tool. It solves the common
problem of quickly understanding foreign-language text without switching to a
browser translation page.

The core input paths are:

- Selected text in the current macOS app
- Clipboard text
- Text inside a selected screenshot region

Target users are macOS knowledge workers who frequently read foreign-language
content: developers, researchers, students, product and operations teams,
cross-border workers, and users who need to translate webpages, PDFs, images,
chat screenshots, or video subtitles.

## 2. Core Function Experience

### Main Flows

1. The user opens the menu bar item.
2. The user chooses `Translate Selection`, `Translate Clipboard`, or `Screenshot Translate`.
3. TextLens extracts text through Accessibility APIs, clipboard reading, or local OCR.
4. TextLens translates the text through the selected free provider.
5. If free translation fails and API fallback is enabled, TextLens uses an OpenAI-compatible API.
6. The result appears in a floating popover near the cursor or selected region.

### Usability

The menu actions are simple and fit a lightweight utility. Screenshot translation
has a clear drag-selection interaction and an `Esc to cancel` hint.

First-time setup now opens Settings on first launch and exposes permission
status, target language, active strategy, fallback order, and test actions. A
dedicated wizard would still be smoother, but the required setup steps are now
visible in one place.

### Efficiency

Global shortcuts make the product suitable for high-frequency use:

- `Control + Option + Command + S` for selected text translation
- `Control + Option + Command + T` for screenshot translation

The product keeps the user in the current work context, which is the main value
over copy-pasting into a web translator.

### Completion

The MVP flow is complete: selection translation, clipboard translation,
screenshot OCR translation, settings, free translation, API fallback, and
floating results all exist.

Automated checks passed after the P0 iteration:

- `swift build --product TextLens`: passed
- `swift test`: 26 tests passed
- `swift run TextLensChecks`: `ok`

The result popover now supports loading state, retry, copy original, copy
translation, and close. Long-text expansion and history remain next-stage
workflow improvements.

## 3. Typical Use Cases

- Reading English webpages, GitHub issues, API docs, or papers
- Translating text embedded in screenshots, PDFs, images, or video subtitles
- Understanding foreign-language chat messages, emails, or support tickets
- Translating developer errors, logs, or documentation snippets
- Quickly checking a phrase without leaving the current macOS app

## 4. Strengths

- Menu bar shape is right for a lightweight translation utility.
- Screenshot OCR expands coverage beyond selectable text.
- Local OCR improves privacy and avoids uploading screenshots.
- Free-provider-first strategy lowers first-use cost.
- API fallback keeps a path for higher quality or more stable translation.
- Global shortcuts support repeated daily use.
- Popover placement and screenshot-region calculations have automated tests.

## 5. Problems And Gaps

### Interaction

- First launch opens Settings so users can complete permissions, language, and
  translation source setup.
- Menu bar icon is abstract and may be hard to discover.
- Result popover controls cover retry, copy, and close; an expanded long-text
  view is still missing.

### Function

- No translation history.
- No custom shortcuts.
- No editable OCR text before translation.
- Multi-display screenshot behavior is intentionally limited.

### Performance And Reliability

- Free Google endpoint is unofficial and may be unstable.
- MyMemory fallback currently assumes English source text in its language pair,
  which may reduce accuracy for non-English source content.
- Selected-text access depends on macOS Accessibility support in each app.

### Information Architecture

- The Translation pane now shows active strategy and fallback order. API
  credential details still live in the API Fallback pane to keep secret fields
  separated.

### Copywriting

- Permission and common failure messages now point users toward Settings,
  permission fixes, or retry. Provider-specific network errors still depend on
  upstream error quality.

### Security

- API keys and provider secrets are stored in Keychain, with migration from
  existing `UserDefaults` values.

## 6. User Value Judgment

TextLens already provides clear value for quick, temporary translation. The
screenshot OCR flow is especially valuable because it covers content that normal
copy-based translation tools cannot handle.

The product has moved beyond the riskiest MVP gaps: onboarding visibility,
settings clarity, secure credential storage, and basic error recovery are now
covered. Daily retention now depends more on result management, history,
customization, and long-text workflows.

## 7. Improvement Suggestions

### P0

1. Done: first launch opens Settings for permissions, target language, and translation source setup.
2. Done: API keys and provider secrets are stored in Keychain.
3. Done: Translation settings show active strategy, fallback order, and provider tests.
4. Done: result popover supports loading, retry, copy original, and copy translation.
5. Done: Settings shows permission status and direct System Settings links.
6. Done: core permission, OCR, capture, and translation failures use actionable guidance.

### P1

1. Add local translation history for the latest 20 items.
2. Support custom global shortcuts.
3. Let users edit OCR text before translation.
4. Add an expanded result window for long text.
5. Add service health checks for translation providers.

### P2

1. Add glossary and preferred translations.
2. Improve full multi-display screenshot selection.
3. Add provider quality and failure-rate indicators.
4. Support history export.
5. Explore offline translation options.

# Next-Stage Product Requirements

## 1. Goal

Move TextLens from a reliable basic utility to a daily macOS translation
workflow. P0 trust and setup work is complete; the next stage should focus on
history, shortcut customization, OCR correction, long-text handling, and
provider reliability visibility.

## 2. Target Users And Core Scenarios

### Target Users

- macOS knowledge workers
- Developers and researchers
- Users who frequently read foreign-language webpages, PDFs, images, or chats

### Core Scenarios

- Select text in any app and translate it immediately.
- Select a screenshot region and translate text inside it.
- Understand and recover from permission, OCR, network, or API failures.
- Complete first-use setup within two minutes, then reuse the tool daily with
  minimal repeated configuration.

## 3. Functional Requirements

### P0

Status: completed in the 2026-07-06 P0 iteration.

- First-run onboarding
  - Done: first launch opens Settings.
  - Done: Settings shows Accessibility permission status.
  - Done: Settings shows Screen Recording permission status.
  - Done: Settings shows target language.
  - Done: Settings shows active translation strategy.
  - Done: Settings provides free-provider and API test actions.
- Permission center
  - Done: detect Accessibility and Screen Recording status.
  - Done: open the relevant macOS System Settings pane.
- Secure credential storage
  - Done: store API key, Baidu secret, and Youdao secret in Keychain.
  - Done: migrate existing values from `UserDefaults` when present.
- Translation strategy settings
  - Done: show selected free provider.
  - Done: show fallback order.
  - Done: show whether API fallback is enabled.
  - Done: test selected provider and API fallback.
- Result popover upgrade
  - Done: loading state.
  - Done: retry action.
  - Done: copy original.
  - Done: copy translation.
  - Done: actionable error states.
- Menu bar status
  - Done: ready.
  - Done: permission missing.
  - Done: translation source not configured.

### P1

Status: next implementation backlog.

- Local translation history
  - Keep the latest 20 results by default.
  - Allow clearing history.
  - Allow disabling history.
- Custom shortcuts
  - Configure selected-text and screenshot translation shortcuts.
  - Warn on unavailable shortcut capture when detectable.
- OCR confirmation
  - Allow editing recognized text before translation.
- Long-text result view
  - Open an expanded window from the popover.
- Provider health check
  - Show last successful provider.
  - Show recent provider failure messages.

### P2

Status: later research and power-user backlog.

- Glossary support.
- Full multi-display region selection.
- Translation quality comparison between providers.
- History export.
- Offline translation research.

## 4. Requirement Priority

P0 fixes trust and basic reliability. P1 improves retention and daily workflow.
P2 serves advanced or power-user needs after the core experience is stable.

## 5. Key User Flows

### First Use

1. User launches TextLens.
2. TextLens opens Settings for setup status and required configuration.
3. User grants required permissions.
4. User chooses target language.
5. User keeps the default free provider or configures API fallback.
6. User runs a test translation.
7. TextLens shows ready status.

### Screenshot Translation

1. User presses the screenshot shortcut.
2. TextLens shows the screen overlay.
3. User drags a region.
4. TextLens shows OCR and translation progress.
5. TextLens displays original and translated text.
6. User copies, retries, or closes. Expanded viewing and history are P1 work.

### Failure Recovery

1. Translation fails.
2. TextLens identifies the failure type.
3. TextLens shows a short explanation and one primary action.
4. User opens settings, retries, copies OCR text, or switches provider.

## 6. Success Metrics

- Median first-use setup time under 2 minutes.
- Screenshot translation success rate above 90%.
- Selected-text translation success rate above 85%.
- Failure recovery success rate above 50%.
- Day-7 retention above 25%.
- Average translations per active user per day above 5.
- Test translation success rate above 90% after setup.

## 7. Risks And Validation Questions

- Is the unofficial Google translation endpoint stable enough for default use?
- How often does selected-text translation fail across common macOS apps?
- Does requiring Screen Recording permission reduce activation?
- Does history create enough user value to justify storing translated text?
- Will users understand API fallback without advanced provider knowledge?
- How often do migrated `UserDefaults` credentials appear in real installs, and
  do any edge cases remain after Keychain migration?
- Does the floating popover obstruct the user's working area too often?
