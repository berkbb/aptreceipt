# AptReceipt Product Roadmap

## Milestone Status & Roadmap

### Phase 1: Core Operations, Transparency & Safety (Completed in v3.2.0)
1. **Receipt History & Archive**:
   - Persistent `ReceiptRecord` store in Application Support JSON.
   - Searchable History window/sheet with multi-criteria filtering (kind, flat, date, search query).
   - Instant re-open, print, or export past receipts.
2. **Verifiable QR Code**:
   - Dynamic CoreImage QR code embedded in live preview and PDF document.
   - Encodes verified receipt summary (receipt #, flat, payer, amount, date) for anti-tamper authenticity.
3. **WhatsApp & Email Quick Share**:
   - Direct integration to dispatch receipt summaries and PDF links via WhatsApp Web/Desktop (`wa.me`) or macOS Mail.
   - Optional phone number stored with resident records.
4. **Data Backup & Restore**:
   - Full export of apartment configuration, residents, vendors, and receipt archive into a single `.json` backup file.
   - Seamless one-click restoration with validation and conflict safety.

---

### Phase 2: Financial Intelligence & Automation (Completed in v3.3.0)
5. **Cash Flow & Monthly Financial Summary (Kasa Özeti)**:
   - Aggregated monthly view: Total Income, Total Expenses, Net Cash Balance KPIs.
   - Category distribution charts for building management expenses with visual progress bars.
   - One-click PDF / CSV export ready for building bulletin board posting.
6. **Expense Attachment / Bill Photo OCR**:
   - Attach photos of invoices, receipts, or maintenance slips to management expenses with Apple Vision OCR.
   - Automatically merges attachments as Page 2 in exported PDF documents for audit compliance.
7. **Batch Dues Assessment (Toplu Aidat Tahakkuku)**:
   - One-click batch preparation of monthly dues receipts for all registered flats with sequential numbering.
8. **Printable A4 Bulletin Board Notice (Pano İlanı)**:
   - Generates and exports official A4 notice sheets ready for notice boards.

---

### Phase 3: Multi-Jurisdiction Compliance & Software Lifecycle (Completed in v3.4.1)
9. **Multi-Country Late Payment Compensation Engine**:
   - Master toggle switch to enable/disable late compensation calculation across receipts and UI.
   - Pre-configured jurisdiction profiles:
     - 🇹🇷 **Turkey**: KMK Art. 20/c statutory 5% monthly rate, 15th due day.
     - 🇷🇴 **Romania**: Law 196/2018 Art. 77 (up to 0.2%/day after 30-day grace period, default 6% monthly).
     - 🌐 **International**: Condominium / HOA property association bylaws (5% rate, 10-day grace period).
     - ⚙️ **Custom**: Fully editable rate, due day, grace period, and receipt legal footnote.
   - Dynamic per-country and custom legal footnotes embedded in A4 receipt documents.
10. **GitHub Release Update Checker**:
    - Automatic and manual update check querying GitHub Releases API (`berkbb/aptreceipt`).
    - Semver evaluation engine (`SemverCompare`) handling `v` prefixes, prereleases, and patch versions.
    - Menubar (`Check for Updates...`), Settings -> About tab, and About window integration with 1-click downloads.
    - In-app DMG download to `~/Downloads` with progress/cancel, SHA-256 verification against `SHA256SUMS.txt`, Ed25519 signature verification against the bundled `AptReceiptUpdatePublicEDKey`, and auto-open for drag-to-Applications install (no third-party updater framework).
11. **Comprehensive Test Suite & CLI Runner**:
    - 18 passing unit tests in `aptreceiptTests` verifying mathematical calculations, semver comparisons, JSON backwards compatibility, and localized citations.
    - Executable `./run_all_tests_mac.command` for continuous verification.

---

### Phase 4: Future Roadmap (Upcoming Milestones)
12. **Multi-Building Portfolio Management**:
    - Switch between multiple apartments, complexes, or sites within a single app instance.
13. **Bank Statement Import & Reconciliation**:
    - CSV/OFX/CAMT.053 bank statement parsing to automatically match resident payments against due dates.
14. **Resident Self-Service / Web Portal Export**:
    - Static HTML ledger generation for offline distribution to resident groups or personal portals.
