# Math Rules — Financial & Numerical Invariants

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt

The global probabilistic and simulation invariants (3-6-9 paradigm, mixture models, confidence intervals, survival analysis, queueing theory, PRNG seeding) apply to forecasting and simulation systems. AptReceipt has none, so they do **not** apply here. The app's financial invariants are:

1. **Money has two decimals.** Fees and totals are rounded to cents through `LateFeeCalculator.roundedToCents` (schoolbook rounding, half away from zero). Known limitation: it rounds a `Double`, so a value exactly on half a cent can round the wrong way; moving to `Decimal` is on `context/roadmap.md`.
2. **Late fee** = `base × (monthlyRate / 100) × months`, rounded to cents; **grand total** = `base + lateFee`, rounded to cents. All screens and documents use these functions; never re-implement the formula (tests exercise the real code).
3. **Rates** are monthly percentages ≥ 0; due day is clamped to `1…31`, grace period to `0…60` days (`SettingsViewModel.save`).
4. **Country profiles** supply defaults (rate, due day, grace days, footnote); re-selecting a profile re-applies them. Profiles stay jurisdiction-neutral (`user_rejected_spec.md`).
5. **Display formats** follow the language: `AppFormat.currency` (e.g. `₺1.750,00`, `$1,750.00`, `1.750,00 Lei`) and `AppFormat.percent` (`%16,7` in Turkish, `16.7%` in English, `16,7%` in Romanian). Machine formats (CSV, JSON backups) keep `.`-decimal numbers.
6. **Amount in words** (`NumberToWords`) covers every supported language and currency and must agree with the rounded total.
7. **Sequence numbers** are positive integers; a receipt's serial prefix depends on its kind and language (`TAH/GID/HAR`, `INC/DIS/ADM`, `REC/EXP/MGT`).
8. **Version comparison** (`SemverCompare`): numeric components, missing parts are 0, a pre-release is never newer than the release; an update is offered only when strictly newer, and accepted only with a matching SHA-256 and a valid Ed25519 signature.
