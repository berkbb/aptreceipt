# AptReceipt — Roadmap

- **Last updated:** 2026-10-20

Pending work only. Remove an item as soon as it ships; shipped history lives in `CHANGELOG.md` (the former "completed phases" list was removed from this file for that reason).

## Safety & data integrity

- [ ] **Decimal money arithmetic** (`quality_plan.md`, phase 1). `LateFeeCalculator.roundedToCents` rounds a `Double`; values exactly on half a cent can round the wrong way because of binary representation. Move money math to `Decimal` with explicit round-half-up.

## Product

- [ ] **Use due day and grace period in the late fee** (`quality_plan.md`, phase 2): every started month after the due day plus grace counts.
- [ ] **Multi-building portfolio management** (`quality_plan.md`, phase 6): switch between several apartments, complexes or sites in one app instance.
- [ ] **Bank statement import & reconciliation**: parse CSV/OFX/CAMT.053 statements and match resident payments against due dates.
- [ ] **Resident self-service export**: static HTML ledger generation for offline distribution to resident groups.
