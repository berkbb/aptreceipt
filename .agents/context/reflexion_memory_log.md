# Reflexion Memory Log

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt (aptreceipt)

Each entry: what happened, why, and the lesson to apply next time.

## R-001 — The screenshot generator overwrote the real receipt archive (2026-10-20)

- **What:** `--generate-screenshots` was run from a signed (sandboxed) build at 09:47. The generator calls `records.removeAll()` and adds two sample receipts, then saves; it does not restore the previous archive. It also removes the app's whole defaults domain and writes back only some keys (building fields, language, theme, currency, logo, owners 1–50): vendors, services, phones, the signature, late-fee settings, per-profile rates and the launch-check flag are lost. A local Time Machine snapshot from 09:02 holds the previous archive and preferences; restoring them is up to the user (the container is protected by macOS).
- **Why:** The generator backs up only part of `UserDefaults`, not the archive file, and it was run against the real data location.
- **Lesson:** Isolate sample data instead of backing up and restoring real data: a partial backup silently loses everything it forgot. Fixed the same day: a screenshot run keeps the shared settings (`InMemoryDefaults`) and the archive (`ReceiptArchiveStore(fileURL: nil)`) in memory through `ScreenshotMode`, and the generator refuses to run if the archive is on disk. Guarded by the "Screenshot Run Isolation" tests; still render README screenshots from an unsigned scratch build in a scratch working directory.

## R-002 — Two sizing mechanisms made the settings window drift (2026-10-20)

- **What:** Switching settings tabs moved the window 100 pt left each time and clipped the wide tabs.
- **Why:** Custom centering code and `NSTabViewController`'s own sizing fought each other.
- **Lesson:** One source of truth for size (`preferredContentSize`, `sizingOptions = []`), keep the top-left corner fixed; later one width (760 pt) for every tab. Guarded by `testSwitchingSettingsTabsKeepsWindowSizeAndPosition`.

## R-003 — A shared flag opened the license twice (2026-10-20)

- **What:** `showLicenseViewer` on the settings store drove sheets in the About window, the settings window and the main window, so one click opened several sheets.
- **Lesson:** Presentation state belongs to the view that presents it (`@State` in `AboutContentView`), not to a shared store.

## R-004 — Hardcoded formats and single-language texts slipped through (2026-10-20)

- **What:** Amounts as `1750.00 $`, Turkish-style percentages in every language, Turkish-only batch receipt texts, bulletin footer and file names, a hardcoded `v3.3.0`.
- **Lesson:** Format numbers through `AppFormat`, read versions from the bundle, keep every text in each language's own file; the parity tests now fail on these patterns. Mutation-check new guard tests (add a deliberate violation, see the test fail, remove it).

## R-005 — Hosted tests could write to the real defaults (2026-10-20)

- **What:** Tests run inside the app host; `ReceiptSettingsStore` used `UserDefaults.standard` directly.
- **Lesson:** Inject `UserDefaults` and use the in-memory `InMemoryDefaults` double; named suites leave plists in `~/Library/Preferences`.

## R-006 — WhatsApp messages broke in practice (2026-10-20)

- **What:** Local phone numbers (`0532 …`) opened wrong chats; `&` and `+` in texts cut or changed the message; amounts did not match the receipt.
- **Lesson:** Normalize numbers to international form per building country, escape query values with a strict character set, and test the decoded URL.

## R-007 — Stored text is in the language it was created in (2026-10-20)

- **What:** The cash summary listed periods exactly as stored ("October 2026" next to "Ekim 2026"), sorted alphabetically.
- **Lesson:** Code that reads stored text back (`ReceiptPeriod`) must understand every supported language and present the result in the current one.

## R-008 — The receipt QR code looked fine but could not be scanned (2026-10-20)

- **What:** The verification QR on receipts did not scan on screen, in the PDF or on paper. It was a `CIImage` scaled by a non-integer factor into 52 pt (uneven, blurred modules after rasterizing) with no quiet zone, next to a border stroke.
- **Lesson:** Verify machine-readable output by machine: decode generated codes in a test (Vision `VNDetectBarcodesRequest`) through the real export paths, not by eye. Draw codes as bitmaps with whole pixels per module and a quiet zone.

## R-009 — A readable QR code sent receipt details to web search (2026-10-20)

- **What:** 3.6.0 put the receipt as plain text in the QR code so phones could show it offline. Phone cameras offer "search the web" for plain text, so one tap sent the payer's name, amounts and building to a search engine.
- **Lesson:** Check what the phone's camera does with a QR payload type before choosing it, and keep personal data out of anything a phone may hand to an online service. Receipts now carry only a code sealed with the installation key; the camera offers to copy it.
