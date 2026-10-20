# Settings Window: Arhivar Standard Alignment Plan

- **Status:** Approved 2026-10-20 with D1a, D2a, D3a. Phases 0–5 done; phase 6 (Vendors) next.
- **Date:** 2026-10-20
- **Scope:** `aptreceipt/PreferencesViewController.swift` (`SettingsView`, `SettingsViewModel`, `SettingsTab`), `SettingsWindowManager` in `AppDelegate.swift`, `GitHubUpdateChecker.swift`, `L10n.swift`, `Localizable.xcstrings`.
- **Reference:** `arhivar-mac-universal/Sources/Arhivar/Views/SettingsView.swift` and the already-aligned `ilef_radio_swift` settings (commit `2833101`).

## Hard constraint (from the user)

No app-specific feature may be removed or have its behavior changed. Each phase changes presentation and structure only, plus the two additions listed under "New". Everything in the feature inventory below must still exist and behave the same after every phase. It doubles as the acceptance checklist.

## What "Arhivar standard" means here

1. Native tab switcher with an SF Symbol per tab.
2. `Form` with `.formStyle(.grouped)`; every `Section` has a header, and a footer where it explains something.
3. Native controls (`Toggle`, `Picker`, `LabeledContent`, `TextField`) instead of hand-drawn capsules and cards wherever a native control can show the same information.
4. A fixed, compact width instead of a large free-resizing window.
5. An **App Updates** section: installed version and build, check status, last-checked time, Check Now, inline Download when a newer release exists, and an opt-in "check at launch" toggle.
6. A **Reset** button with a confirmation dialog.

## Feature inventory (must survive unchanged)

| Tab | Features |
| --- | --- |
| Building (`general`) | Building hero card with logo upload/remove (immediate, not draft) and stats chips; building name, default manager, total flats + quick flat-count chips (`setQuickFlatCount` also pre-fills empty residents); default dues, next receipt number; currency selection; quick scenario cards TR/EN/RO with "apply scenario" (`loadSampleDefaults`) and feedback banner. |
| Building: late fee card | Enable toggle; country profile picker (`selectCountryProfile` resets rate, due day, grace, footnote); monthly rate with statutory-rate chip; due day; grace period; custom footnote with reset button. Profiles stay jurisdiction-neutral (see `user_rejected_spec.md`). |
| Residents | Badges: total / registered / vacant; fill sample residents; clear all; search by flat or name; per-flat name + phone fields, assigned/unassigned state, per-flat clear. |
| Vendors | Badges: vendors / preset services; load sample vendors and services + feedback; add vendor (name, category, contact); vendor search; delete vendor; add service (name, suggested vendor, description); delete service; empty states. |
| Appearance | Theme deck; language deck (TR/EN/RO/System with descriptions); restart notice for the menu bar; currency deck. |
| Signature | Signature preview; upload/remove (immediate, not draft). |
| Backup | Export full backup (NSSavePanel); import full backup (NSOpenPanel, reloads the draft); stats (total flats, archived receipts); success/error messages; notice text. |
| About | Shared `AboutContentView`; software update card with last-checked time and Check for Updates. |
| Window shell | Header (icon, title, subtitle) — *replaced in phase 1 by the toolbar tab bar and window title, as in Arhivar; the strings stay in the catalog;* Cancel (discards draft) and Save & Close (validates, then writes); validation alerts (flat count, sequence, amount, building/issuer required); restart alert; `initialTab` deep links used by `SettingsWindowManager.show(tab:)` and the screenshot generator (`--generate-screenshots` renders general, vendors and appearance). |

### Existing behavior that looks odd but stays as is

These are recorded so nobody "fixes" them by accident during the migration. Changing any of them needs a separate user decision.

- Picking a language card calls `viewModel.save(to:)`, so it commits **every** pending draft field at once, not only the language.
- Currency selection appears both in Building and in Appearance.
- `MainScreen` still has a `.sheet(isPresented: $viewModel.isPresentingSettings)` path, but nothing sets `isPresentingSettings` to `true`.
- "Clear all residents" has no confirmation; it only clears the draft, so Cancel still undoes it.
- Logo, signature and backup import act immediately, outside the Save/Cancel draft.
- The per-flat clear button's tooltip uses the "clear all residents" text.
- The statutory rate chip prints its rate twice, e.g. "%5.0 (%5.0 (Statutory))": the code wraps `statutoryRateChip`, whose catalog value already contains the rate, in another "%rate (…)".

## Design

### Kept on purpose (deviation from Arhivar)

Arhivar applies every change instantly. AptReceipt edits a validated **draft** and commits it with Save & Close. That transactional model, its validation, and the Cancel button are app-specific behavior, so they stay. Only their look changes: a standard bottom bar with Cancel on the left and the prominent Save & Close on the right, as today.

### Window and tabs

- Keep `SettingsWindowManager` (NSWindow). It is what `initialTab` deep links, the menu command and the screenshot generator rely on, so the SwiftUI `Settings` scene is not used.
- Tab switcher: see decision **D1**.
- Width: see decision **D2**.
- Same seven tabs, same order, same icons, same localized titles.

### Tab by tab

- **Building:** sections *Building* (name, manager, flats + quick chips as a row of small bordered buttons), *Logo* (the hero card content: logo preview, upload/remove, stats chips), *Finance* (dues, next receipt number, currency), *Late Fee* (toggle; the remaining rows are disabled while it is off instead of being hidden, unless the current card hides them, in which case hiding stays), *Quick Scenarios* (the three scenario cards kept as custom rows; their descriptions are information that a plain picker would lose).
- **Residents:** section *Summary* (badges as `LabeledContent` rows with the same counts) and *Actions*; then a *Residents* section with the search field and one row per flat (name, phone, assigned state, clear). The list stays lazy so large buildings remain fast.
- **Vendors:** sections *Vendors* (add form, search, list with delete, empty state) and *Services* (add form, list with delete, empty state), with *Samples* holding the load-samples button and feedback.
- **Appearance:** *Theme* as a segmented picker, as in Arhivar. *Language* as a picker whose rows keep the flag and native name, with the selected language's description and the restart notice in the footer. *Currency* stays where it is today. The language commit-on-select behavior above is unchanged.
- **Signature:** one section with the preview as `LabeledContent` and upload/remove buttons.
- **Backup:** sections *Export* and *Import* with the same panels and messages, and a *Data* section with the counts.
- **About:** `AboutContentView` at the top. Below it, the new *App Updates* section replaces the current update card and keeps everything it shows, then the new *Reset* section.

## New (the only functional additions)

1. **App Updates section.** Built on the `UpdateCheckFailure` classification that already shipped. `GitHubUpdateChecker` gains a published `state` (idle, checking, upToDate, available(release), failed(failure)); `lastCheckedDate` already exists. Check Now runs without alerts and shows the result inline; Download appears only for a newer release and uses the existing verified download flow.
2. **Check at launch:** new `UserDefaults` key, **off by default**. Per `user_rejected_spec.md`, nothing may contact GitHub without the user's consent. When on, a newer release shows the existing update alert; otherwise launch stays silent.
3. **Reset Settings…** with a confirmation dialog. Its scope is decision **D3**. It never touches residents, phones, vendors, services, the receipt archive, the logo, the signature or the receipt sequence counter.

## Phases

Each phase is one commit. It must pass `./run_all_tests_mac.command`, and before the commit its screenshots are regenerated into a scratch folder and compared against the inventory.

0. **Safety net (no UI change):** characterization tests for `SettingsViewModel` covering load/save round trip, every validation error, `selectCountryProfile`, `setQuickFlatCount`, fill/clear residents, add/delete vendor and service, `loadSampleDefaults`, and Cancel leaving the store untouched. A checklist test asserts every `SettingsTab` case still exists and `initialTab` still opens it.
1. **Shell:** new tab switcher, width, header, bottom bar. Tab bodies are moved unchanged.
2. **Appearance + Signature + Backup** to `Form` sections. These are the smallest tabs, so the pattern gets proven on them first.
3. **About:** App Updates section, launch toggle, Reset (after D3).
4. **Building + Late Fee.**
5. **Residents.**
6. **Vendors.**
7. **Docs:** CHANGELOG, README screenshots (`docs/screenshots` regenerated by the app's own generator), and removing this plan's "Draft" status.

## Decisions (approved 2026-10-20: D1a, D2a, D3a)

- **D1, tab switcher.** (a) Toolbar tabs through `NSTabViewController(.toolbar)` hosting each SwiftUI tab. This looks exactly like Arhivar and keeps the NSWindow manager. *Recommended.* (b) SwiftUI `TabView` inside the existing window. Simpler, but it draws a segmented control in the content rather than toolbar tabs.
- **D2, width.** (a) 560 pt for preference tabs and 760 pt for Residents and Vendors, resizing on tab change as Arhivar's settings window does. *Recommended*, because the resident and vendor lists don't fit in 560. (b) One fixed width for all tabs, around 680 pt.
- **D3, reset scope.** (a) Only preferences: theme, language, currency, late-fee configuration, launch check. *Recommended.* (b) Also building defaults (name, manager, default dues, flat count). Data is excluded in both options.

## Progress log

- **Phase 0 (489f5a4):** 9 characterization tests on an isolated `UserDefaults` suite.
- **Phase 1:** `SettingsTabViewController` (`NSTabViewController`, `.toolbar`, `.preference` toolbar style) inside `SettingsWindowManager`. One `SettingsViewModel` draft is shared by all seven pages, loaded once (`isLoaded`), so switching tabs keeps edits and Save & Close commits all of them. Only the visible page presents alerts. Widths 560/760, height 620, window keeps its top edge when resizing. The screenshot generator renders each page at its tab width. Tab bodies are unchanged; at 560 pt the currency cards on the Building tab truncate their subtitles until phase 4 converts that card.
- **Phase 2:** Appearance, Signature and Backup are grouped `Form`s with section headers (`SettingsTab.usesGroupedForm`). Theme is a segmented picker, language and currency are menu pickers; their setters keep the old card behavior: theme and currency apply at once; picking a language still applies its default currency, switches a sample building to that language's samples, saves the whole draft and shows the restart alert (moved unchanged into `SettingsViewModel.selectLanguage` and covered by tests). The selected language's description and the restart notice are in the section footer. Differences: re-picking the already selected language no longer re-runs those steps, because a picker only reports changes; the descriptions of the other languages show once they are picked. Signature keeps its preview, upload and remove; Backup keeps both counts, export, import and the success/error messages.
- **Phase 3:** About is a grouped `Form`: `AboutContentView`, then *Software Updates* (installed version and build, status with the failure kind from `GitHubUpdateChecker.lastFailure`, last checked, Check Now, inline Download for a newer release, opt-in *Check for updates at launch*), then *Reset*. Check Now in Settings shows its result inline instead of an alert; the menu command and the About window keep their alerts. The launch check (`check_updates_at_launch`, off by default) alerts only when a newer release exists. *Reset Settings…* asks for confirmation and restores language (fresh-install default: English), theme, currency, late-fee configuration including per-profile saved rates, and the launch check; it never touches building data, residents, phones, vendors, services, receipts, logo, signature or the receipt number. The reset is mirrored into the open draft without discarding other unsaved edits. Fresh-install values live in `ReceiptSettingsStore.Defaults`, used by both `init` and the reset.
- **Phase 4:** Building is a grouped `Form` with five sections: *Building Profile* (logo preview, name, manager, logo state, the four live stat chips, upload/remove logo), *Building Information* (name, manager, flats as labelled fields plus the eight quick flat-count chips), *Financial* (dues with the currency symbol, next receipt number, currency picker shared with Appearance, still applied at once), *Late Fee* (enable toggle with its own label `lateFeeEnableToggle`; when on, country profiles as buttons in a 2×2 grid so re-selecting a profile still re-applies its defaults, rate field with the profile's quick-rate chips, due day with prefix/suffix, grace period, footnote with reset; the legal notice moved to the footer) and *Starter Scenarios* (one row per scenario with description and Apply, plus the feedback line). Rows stay hidden while late fees are off, as before. Catalog labels ending in ":" are shown without the colon (display only).
- **Phase 5:** Residents is a grouped `Form`. *Residents Directory* shows total, registered and (when any) vacant counts as rows, plus Fill Sample Residents and Clear All; the description moved to the footer. The second section holds the search field, the empty state and one row per flat (flat badge, name, phone, assigned state, per-flat clear) without the old card chrome. Fields inside a `Form` use a prompt instead of a title, otherwise macOS lays them out as "label … value".

