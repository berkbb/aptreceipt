# AptReceipt Product Roadmap

## SOTA Feature Roadmap (7 Key Enhancements)

### Phase 1: Core Operations, Transparency & Safety (Current Milestone)
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

### Phase 2: Financial Intelligence & Automation
5. **Cash Flow & Monthly Financial Summary (Pano Raporu)**:
   - Aggregated monthly view: Total Income, Total Expenses, Net Cash Balance.
   - Category distribution charts for building management expenses.
   - One-click PDF / CSV export ready for building bulletin board posting.
6. **Expense Attachment / Bill Photo**:
   - Attach photos of invoices, receipts, or maintenance slips to management expenses.
   - Renders as Page 2 in exported PDF documents for audit compliance.
7. **Batch Dues Assessment (Toplu Aidat Tahakkuku)**:
   - One-click batch preparation of monthly dues receipts for all registered flats.
