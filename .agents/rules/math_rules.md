# Math Rules — Financial & Numerical Invariants

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt

The global probabilistic and simulation invariants (3-6-9 paradigm, mixture models, confidence intervals, survival analysis, queueing theory, PRNG seeding) apply to forecasting and simulation systems. AptReceipt has none, so they do **not** apply here. The app's financial invariants are:

1. **Money has two decimals and is calculated in `Decimal`.** Every fee, total, sum and difference goes through `Money` (`LateFee.swift`): each stored amount is read at its decimal value (`Money.decimal`, e.g. 1.005 rather than 1.00499…), calculated in `Decimal`, and rounded half-up (half away from zero) to cents with `NSDecimalRound(..., .plain)`. Amounts stay stored as JSON numbers (`Double`) for compatibility. Never add or multiply money as `Double`; tests in section 21 pin the half-cent cases.
1. **Late months follow the due day and grace period.** `LatePaymentSchedule`: due on the due day of the period's month (clamped to its last day), no fee through the grace end, then every started month counts (due 15 Oct, paid 16 Nov → 2). Used by auto-detect on the main screen, the cash summary late-fee badge and the WhatsApp reminder; tests in section 22.
2. **Late fee** = `base × (monthlyRate / 100) × months`, rounded to cents; **grand total** = `base + lateFee`, rounded to cents. All screens and documents use these functions; never re-implement the formula (tests exercise the real code).
3. **Rates** are monthly percentages ≥ 0; due day is clamped to `1…31`, grace period to `0…60` days (`SettingsViewModel.save`).
4. **Country profiles** supply defaults (rate, due day, grace days, footnote); re-selecting a profile re-applies them. Profiles stay jurisdiction-neutral (`user_rejected_spec.md`).
5. **Display formats** follow the language: `AppFormat.currency` (e.g. `₺1.750,00`, `$1,750.00`, `1.750,00 Lei`) and `AppFormat.percent` (`%16,7` in Turkish, `16.7%` in English, `16,7%` in Romanian). Machine formats (CSV, JSON backups) keep `.`-decimal numbers.
6. **Amount in words** (`NumberToWords`) covers every supported language and currency and must agree with the rounded total.
7. **Sequence numbers** are positive integers; a receipt's serial prefix depends on its kind and language (`TAH/GID/HAR`, `INC/DIS/ADM`, `REC/EXP/MGT`).
8. **Version comparison** (`SemverCompare`): numeric components, missing parts are 0, a pre-release is never newer than the release; an update is offered only when strictly newer, and accepted only with a matching SHA-256 and a valid Ed25519 signature.
