# UI Rules — Dynamic Presentation & Hardcoded Text Ban

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt main window, preview, settings, About window, sheets and generated documents.

## 1. No hardcoded text or values

- Every user-facing text comes from the per-language files through `L10n` (`localization_parity.md`). No words in `Text("…")`, `Label("…")`, `Button("…")`, alerts, file names or generated documents. Only brand names and language self-names may stay literal.
- Version, build and year are read at runtime (`AppInfo.version`, `AppInfo.build`, `AppInfo.currentYear`); never hardcode them.
- Amounts and percentages go through `AppFormat`; dates and month names through locale-aware formatters with `l10n.locale`.
- Upper-case display text with `l10n.uppercased(_:)`, never `.uppercased()`: Turkish needs "İ" for "i".

## 2. Windows

- Settings: toolbar tabs (`SettingsTabViewController`), one 760 pt width for every tab, the window keeps its size and position when switching tabs. Each tab is a grouped `Form` with section headers. Edits on all tabs form one draft committed by *Save & Close* or discarded by *Cancel*.
- About window: standard traffic lights, content-sized, material background; the shared `AboutContentView` is also the top of the Settings → About tab.
- Presentation state (sheets, dialogs) belongs to the presenting view (`@State`), never to a shared store, so a sheet opens only in its own window.
- Footer and toolbar buttons must fit in every language; split rows instead of truncating.

## 3. Appearance

- Light, Dark and System themes with semantic colors; glass button styles on macOS 26 with bordered fallbacks.
- Follow HIG for keyboard shortcuts (`Cmd+,`, `Esc` cancels, `Return` confirms the primary action).

## 4. Verification

Check UI changes in the real running window; offscreen renders do not draw glass buttons or window chrome faithfully. Screenshots for the README come from `--generate-screenshots` in an unsigned scratch build; it renders sample data from in-memory stores only.
