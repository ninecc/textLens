# TextLens

TextLens is a native macOS menu bar app for fast translation from selected text,
clipboard text, and selected screenshot regions. Screenshot translation uses
Apple Vision for local OCR, then sends recognized text through the configured
translation provider.

## Current Product Shape

- Menu bar actions: `Translate Selection`, `Translate Clipboard`, `Screenshot Translate`, `Settings`, `Quit`
- Global shortcuts:
  - `Control + Option + Command + S`: translate selected text
  - `Control + Option + Command + T`: screenshot translation
- Translation settings:
  - Target language defaults to Chinese
  - Free provider defaults to Google
  - MyMemory is used as a backup free provider
  - OpenAI-compatible API can be enabled as fallback
- Screenshot translation:
  - Drag to select a region
  - `Esc` cancels selection
  - OCR runs locally with Apple Vision

## Build And Run

```bash
swift build --product TextLens
scripts/run_app.sh
```

## Test

```bash
swift test
swift run TextLensChecks
```

## Product Docs

- [macOS design spec](docs/superpowers/specs/2026-07-03-textlens-macos-design.md)
- [macOS implementation plan](docs/superpowers/plans/2026-07-03-textlens-macos-implementation.md)
- [product experience report and next-stage requirements](docs/superpowers/specs/2026-07-06-textlens-product-experience-report.md)

## Next Priorities

1. Add first-run onboarding for permissions and translation setup.
2. Store API keys and provider secrets in Keychain instead of `UserDefaults`.
3. Improve settings information architecture around free providers and API fallback.
4. Upgrade the result popover with loading, retry, and clearer error recovery.
5. Add a lightweight local translation history.
