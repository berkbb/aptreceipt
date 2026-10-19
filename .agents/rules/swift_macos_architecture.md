# Swift & macOS Architecture Standards

## UI / UX Architecture
1. **AppKit + SwiftUI Hybrid**: Use `NSHostingController` or SwiftUI views embedded inside AppKit windows where appropriate.
2. **Persistence**: Use `Codable` models with JSON serialization to `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` or `UserDefaults` for lightweight state.
3. **Typography & Colors**:
   - Always use semantic colors (`Color.primary`, `Color.secondary`, `Color(NSColor.windowBackgroundColor)`, `Color.accentColor`) to ensure perfect appearance in both Dark and Light appearance modes.
4. **Localization**:
   - All string keys must exist in `en`, `tr`, and `ro`.
   - Provide strong fallbacks when string keys are formatted.
