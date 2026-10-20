# Swift & macOS Architecture Standards

## UI / UX Architecture
1. **AppKit + SwiftUI Hybrid**: Use `NSHostingController` or SwiftUI views embedded inside AppKit windows where appropriate.
2. **Persistence**: Use `Codable` models with JSON serialization to `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` or `UserDefaults` for lightweight state.
3. **Typography & Colors**:
   - Always use semantic colors (`Color.primary`, `Color.secondary`, `Color(NSColor.windowBackgroundColor)`, `Color.accentColor`) to ensure perfect appearance in both Dark and Light appearance modes.
4. **Localization**:
   - UI strings live in one file per language: `aptreceipt/en.lproj/Localizable.strings`, `tr.lproj/…` and `ro.lproj/…`, with identical keys. Each `L10n` property maps to a key of the same name via `tr("key")`; values are looked up in the `.lproj` bundle of the in-app language (`AppLanguage`), not the system language. The English fallback is only a safety net; the parity tests keep every key present in every file.
   - All string keys must exist in `en`, `tr`, and `ro` with matching format specifiers (`%@`, `%d`, positional `%1$@`); `testStringCatalogHasEveryKeyInEveryLanguage` enforces this.
   - Formatted strings use `String(format:)` on the looked-up value.
   - When adding a key, add it to every language file in the same change, in the same alphabetical position.
   - One-to-one translation in every language is mandatory; see `localization_parity.md`.

## Source Layout
- One feature or type family per file (e.g. `L10n.swift`, `ReceiptSettingsStore.swift`, `MainScreen.swift`, `MainScreenViewModel.swift`, `ReceiptModels.swift`, `LateFee.swift`, one file per sheet). Do not grow catch-all files.
- Keep business calculations (e.g. `LateFeeCalculator`) as pure functions outside views so unit tests exercise the real code.
