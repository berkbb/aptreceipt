# AptReceipt — Roadmap

- **Last updated:** 2026-10-20

Pending work only. Remove an item as soon as it ships; shipped history lives in `CHANGELOG.md` (the former "completed phases" list was removed from this file for that reason).

## Safety & data integrity

- [ ] **Screenshot generator must not touch real data.** `--generate-screenshots` replaces the receipt archive and wipes the defaults domain, restoring only some keys (`reflexion_memory_log.md`, R-001). Run it against an injected in-memory `ReceiptSettingsStore` and a temporary archive instead of the real ones.
- [ ] **Injectable archive location.** `ReceiptArchiveStore` writes to a fixed Application Support path, so any test that adds or imports receipts would touch the real archive. Inject the file URL (or an in-memory store) like `ReceiptSettingsStore(defaults:)`.
- [ ] **Decimal money arithmetic.** `LateFeeCalculator.roundedToCents` rounds a `Double`; values exactly on half a cent can round the wrong way because of binary representation. Move money math to `Decimal` with explicit round-half-up.

## Product

- [ ] **Use due day and grace period in the late fee.** They are stored, edited and backed up, but `LateFeeCalculator` computes `base × rate × months` without them; decide with the user how they should affect the number of late months.
- [ ] **Multi-building portfolio management**: switch between several apartments, complexes or sites in one app instance.
- [ ] **Bank statement import & reconciliation**: parse CSV/OFX/CAMT.053 statements and match resident payments against due dates.
- [ ] **Resident self-service export**: static HTML ledger generation for offline distribution to resident groups.

## Distribution

- [ ] **Notarized releases**: sign with a Developer ID and notarize so Gatekeeper no longer blocks the first launch.
