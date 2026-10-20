# Localization Parity Rule (Mandatory)

- **Status:** Mandatory for every change. Set by the user on 2026-10-20.
- **Scope:** Every supported language, now `en`, `tr` and `ro`. Any language added later falls under the same rule.

## The rule

Every user-facing text must exist in **every** supported language with the same meaning, one to one. No screen, message, document or file name may show text in a language other than the one the user picked. A partial translation is a bug, not a follow-up.

## What counts as user-facing text

- Windows, sheets, menus, buttons, alerts, tooltips (`.help`), placeholders and empty states.
- Generated documents: receipts, the bulletin board PDF, amounts in words, footers.
- Messages the app writes for the user: WhatsApp, email, payment reminders.
- Data the app generates on the user's behalf: batch receipt descriptions and recipients, sample data, late-fee footnotes and legal notices.
- Suggested file names (PDF, JPEG, CSV, backups).
- Numbers shown on screen: amounts, percentages, rates and dates.

## How to comply

1. **Every language has its own file, and text comes from those files.** Add the key with its translation to each of `aptreceipt/en.lproj/Localizable.strings`, `tr.lproj/Localizable.strings` and `ro.lproj/Localizable.strings` (a new language gets its own `<code>.lproj/Localizable.strings`), expose it through `L10n`, and never write a literal word into a view (`Text("…")`, `Label("…")`, `Button("…")` and the like). The only literals allowed are brand names and language self-names (`Babadogan Tech and Edu`, `GNU GPL v3.0`, `babadogan.net`, `Türkçe`, `English`, `Română`).
2. **Really translate.** A `tr` or `ro` value must not be a copy of the English one. The only exceptions are listed in `sameAsEnglishAllowed` in the tests (`aboutCopyrightFormat`, `currencyEUR`, `menuZoom`, `okButton`, `subtotal`). Adding to that list needs a reason in the commit message.
3. **Same placeholders.** Every language uses the same format specifiers (`%@`, `%d`, positional `%1$@`). Word order may differ; use positional specifiers when it does.
4. **No text written per language in code.** Interface and generated texts (late-fee profile names, footnotes and legal notices, WhatsApp and email messages, file names) come from the language files, including whole sentences with positional placeholders (`L10n.message("waReminderWithFee", …)`). Only language data that is not interface text may branch per language in code, in its own place: number-word grammar (`NumberToWords.swift`), sample data (`SampleData.swift`), language self-names (`AppSettingsEnums.swift`) and receipt number prefixes (`ReceiptSerial`). `testNoInlinePerLanguageTextsInCode` enforces this.
8. **No raw `%` in WhatsApp text.** wa.me decodes the message more than once, so a `%` (Turkish "%5,0") turned into broken characters. Rates in messages are written in words (`waRatePercent`: "yüzde 5", "5 percent", "5 la sută").
5. **Numbers follow the language.** Use `AppFormat.currency` and `AppFormat.percent` (or a locale-aware `NumberFormatter` / `DateFormatter` with `l10n.locale`). Fixed patterns such as `String(format: "%.2f %@", …)` or a hardcoded `%` position are not allowed on screen. Machine formats (CSV columns, JSON) are exempt.
6. **Stored text may be in another language.** Receipts keep the text of the language they were created in. Code that reads such text back (for example the period through `ReceiptPeriod`) must understand every supported language and show the result in the current one.
7. **Adding a language** means creating its own `<code>.lproj/Localizable.strings` with every key translated, plus every per-language branch, sample data, amounts in words, file names and legal texts *before* it ships, and adding it to `parityLanguages` in the tests. Shipping with an English fallback is not allowed.

## Enforcement

These tests must pass before any commit (`./run_all_tests_mac.command`):

| Test | Guards |
| --- | --- |
| `testStringCatalogHasEveryKeyInEveryLanguage` | Same keys and format specifiers in every language |
| `testEveryLanguageHasItsOwnStringFile` | One `Localizable.strings` per language in the sources, no single shared catalog |
| `testEveryCatalogStringIsReallyTranslated` | No untranslated copies of English |
| `testEveryKeyUsedInCodeExistsInAllThreeLanguages` | Every key `L10n` uses exists everywhere |
| `testNoHardcodedTextInViews` | No literal words in views |
| `testNoFixedNumberFormatsOnScreen` | No fixed number patterns on screen |
| `testGeneratedTextsExistInAllThreeLanguages` | Messages, legal notes, amount in words, file names, sample data differ per language |
| `testEnumTitlesExistInAllThreeLanguages` | Every option title is translated |
| `testNoInlinePerLanguageTextsInCode` | No `isTurkish ?` choices and no text literals in `case .turkish` / `case .romanian` branches outside the exempt language-data files |
| `testEveryMessageKeyExistsInAllThreeLanguages` | Every WhatsApp/email message key used in `SharingHelpers.swift` exists in every language |
| `testWhatsAppMessagesCarryNoPercentSignAndSurviveTheLink` | No `%` in reminders; the wa.me link decodes back to the exact message |

When you add a new kind of user-facing text that these tests cannot see (for example a new generated document), extend the tests in the same change.
