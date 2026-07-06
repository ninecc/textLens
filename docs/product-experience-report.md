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

The main weakness is first-time setup. Users are not guided through Accessibility
permission, Screen Recording permission, translation provider selection, or API
fallback. Settings are functional, but the relationship between free providers
and API fallback is not obvious.

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

Automated checks passed during review:

- `swift test`: 21 tests passed
- `swift run TextLensChecks`: `ok`

The result popover is still basic. It supports copy and close, but not retry,
loading state, long-text expansion, history, or rich error recovery.

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

- No first-run onboarding.
- Menu bar icon is abstract and may be hard to discover.
- Missing visible permission status in settings.
- Result popover has limited controls: copy and close only.

### Function

- No retry action in the result popover.
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

- `Free Provider`, provider credentials, `Use API fallback`, API key, base URL,
  and model are split across settings panes. Users must infer the actual
  translation strategy.

### Copywriting

- Error messages are technically accurate but not action-oriented enough.
- Users need messages like "Enable Screen Recording", "Open Settings", or
  "Add API key to use fallback".

### Security

- The existing design document says API keys should be stored in Keychain.
  Current implementation stores API keys and provider secrets through
  `UserDefaults`, which should be fixed before broader distribution.

## 6. User Value Judgment

TextLens already provides clear value for quick, temporary translation. The
screenshot OCR flow is especially valuable because it covers content that normal
copy-based translation tools cannot handle.

The product is currently best described as a usable MVP. It can satisfy core
needs, but daily reliability depends on better onboarding, clearer settings,
secure credential storage, stronger error recovery, and result management.

## 7. Improvement Suggestions

### P0

1. Add first-run onboarding for permissions, target language, and translation source.
2. Store API keys and provider secrets in Keychain.
3. Merge translation source settings into one clear strategy section.
4. Add loading, retry, copy original, and copy translation states to the result popover.
5. Add permission status and direct System Settings links for Accessibility and Screen Recording.
6. Rewrite error messages into actionable user guidance.

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

Move TextLens from a usable MVP to a reliable daily macOS translation utility.
The next stage should focus on onboarding, configuration clarity, credential
security, error recovery, and result usability.

## 2. Target Users And Core Scenarios

### Target Users

- macOS knowledge workers
- Developers and researchers
- Users who frequently read foreign-language webpages, PDFs, images, or chats

### Core Scenarios

- Select text in any app and translate it immediately.
- Select a screenshot region and translate text inside it.
- Understand and recover from permission, OCR, network, or API failures.
- Complete first-use setup within two minutes.

## 3. Functional Requirements

### P0

- First-run onboarding
  - Show Accessibility permission status.
  - Show Screen Recording permission status.
  - Show target language.
  - Show active translation strategy.
  - Provide a test translation action.
- Permission center
  - Detect Accessibility and Screen Recording status.
  - Open the relevant macOS System Settings pane.
- Secure credential storage
  - Store API key, Baidu secret, and Youdao secret in Keychain.
  - Migrate existing values from `UserDefaults` when present.
- Translation strategy settings
  - Show selected free provider.
  - Show fallback order.
  - Show whether API fallback is enabled.
  - Test selected provider and API fallback.
- Result popover upgrade
  - Loading state.
  - Retry action.
  - Copy original.
  - Copy translation.
  - Actionable error states.
- Menu bar status
  - Ready.
  - Permission missing.
  - Translation source not configured.

### P1

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
2. TextLens opens onboarding or marks setup status from the menu.
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
6. User copies, retries, expands, saves to history, or closes.

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
- How should existing credentials be migrated from `UserDefaults` to Keychain?
- Does the floating popover obstruct the user's working area too often?
