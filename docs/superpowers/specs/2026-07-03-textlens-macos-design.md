# TextLens macOS Design

## Summary

TextLens is a native macOS menu bar app for quick translation from selected text and selected screen regions. The first version uses macOS-native capture and OCR where possible, then sends extracted text to an OpenAI-compatible translation API. Results appear in a small floating window near the cursor.

## Goals

- Translate selected text from other macOS apps.
- Translate text inside a user-selected screenshot region.
- Support multiple source languages through automatic source-language handling.
- Use one fixed target language, defaulting to Chinese and editable in settings.
- Keep the first version small enough to ship and test quickly.

## Non-Goals

- Automatic popups after every text selection.
- Translation history.
- Provider plugin system.
- Account system.
- Offline translation models.
- Full multi-display continuous region selection.

## Product Shape

The first version is a native Swift macOS menu bar app named `TextLens`.

Chosen approach:

- UI: SwiftUI where simple, AppKit where required for menu bar, global overlays, and floating windows.
- OCR: Apple Vision, running locally.
- Translation: OpenAI-compatible HTTP API.
- Storage: `UserDefaults` for non-sensitive settings and Keychain for the API key.

Skipped approaches:

- A cross-platform desktop shell, because macOS permissions and global interactions are easier and cleaner natively.
- A provider/plugin platform, because one OpenAI-compatible adapter covers the first version.
- A screenshot-only prototype, because selected-text translation is part of the core product.

## Architecture

### AppShell

Owns the app lifecycle, menu bar item, menu commands, settings window, and permission status entry points.

Menu items:

- Translate Selection
- Translate Clipboard
- Screenshot Translate
- Settings
- Quit

### SelectionTranslator

Gets text from the current user selection and sends it through the translation flow.

Primary path:

1. User selects text in another app.
2. User clicks `Translate Selection`.
3. TextLens tries to read selected text through macOS Accessibility APIs.
4. If successful, the text goes to `TranslationService`.

Fallback:

- If selected text cannot be read, TextLens prompts the user to copy text and offers `Translate Clipboard`.

### ScreenCaptureTranslator

Handles screenshot translation.

Flow:

1. User clicks `Screenshot Translate` or presses the global shortcut.
2. TextLens shows a transparent full-screen selection overlay.
3. User drags to select a region.
4. TextLens captures that region from the current mouse screen.
5. The image goes to `OCRService`.
6. Recognized text goes to `TranslationService`.

First-version display support:

- Region selection supports the screen where the mouse starts.
- Full cross-display drag selection is out of scope.

### OCRService

Uses Apple Vision to recognize text in screenshots.

Behavior:

- Runs locally.
- Returns normalized plain text.
- If no text is found, the result popover shows `No text recognized` and no translation API call is made.

### TranslationService

Calls an OpenAI-compatible chat completions API.

Config:

- Base URL
- API key
- Model
- Target language

Request behavior:

- Source language is left for the model to infer.
- Target language comes from settings.
- The prompt asks for translation only, without commentary.

Response behavior:

- Extracts translated text from the first response choice.
- Returns clear errors for missing config, network failures, API failures, and malformed responses.

### ResultPopover

Shows the translation result near the cursor.

Contents:

- Original text
- Translated text
- Copy translated text button
- Close button
- Retry button when the translation failed

### SettingsStore

Stores app settings.

Storage:

- `UserDefaults`: base URL, model, target language, shortcut preference.
- Keychain: API key.

Settings UI:

- API Base URL
- API Key
- Model
- Target language
- Accessibility permission status
- Screen Recording permission status
- Buttons to open the relevant macOS System Settings panes

## User Flows

### Selected Text Translation

1. User selects text in any app.
2. User opens the menu bar item and clicks `Translate Selection`.
3. TextLens reads the selected text.
4. TextLens calls the configured translation API.
5. TextLens shows a floating result window near the cursor.

Failure fallback:

- If selected text cannot be read, TextLens shows a short message and offers clipboard translation.

### Screenshot Translation

1. User clicks `Screenshot Translate` or presses the global shortcut.
2. TextLens shows the region-selection overlay.
3. User drags a rectangle and releases.
4. TextLens captures the selected region.
5. Apple Vision extracts text.
6. TextLens translates extracted text.
7. TextLens shows the floating result window near the cursor.

### Settings

1. User opens `Settings`.
2. User enters API config and target language.
3. TextLens saves non-sensitive settings in `UserDefaults`.
4. TextLens saves the API key in Keychain.
5. TextLens shows permission status for Accessibility and Screen Recording.

## Permissions

Accessibility:

- Needed for selected-text access.
- If missing, `Translate Selection` shows an authorization prompt and a button to open System Settings.

Screen Recording:

- Needed for screenshot translation.
- If missing, `Screenshot Translate` shows an authorization prompt and a button to open System Settings.

## Error Handling

- Missing Accessibility permission: prompt before selected-text translation.
- Missing Screen Recording permission: prompt before screenshot translation.
- Selected text unavailable: offer clipboard fallback.
- Empty OCR result: show `No text recognized`; skip API call.
- Missing API config: open settings and highlight missing fields.
- Network or API error: show the error in the popover with a retry button.
- Malformed API response: show a generic translation failure with retry.

## Testing

Automated tests:

- `TranslationService` request body creation.
- `TranslationService` success response parsing.
- `TranslationService` API and malformed response errors.
- `SettingsStore` defaults and read/write behavior.

Manual test checklist:

- First launch without permissions.
- Accessibility permission prompt.
- Screen Recording permission prompt.
- Selected-text translation.
- Clipboard fallback translation.
- Screenshot region selection.
- OCR success and empty OCR.
- Missing API key.
- API failure and retry.
- Copy translated text.

## Deferred Work

- Global shortcut customization UI beyond one default shortcut.
- Automatic selection popup.
- Translation history.
- Multiple translation providers with separate adapters.
- Offline translation.
- Full multi-display continuous selection.
- Advanced target-language picker inside the result popover.
