# Product Requirements Document (PRD) - AptReceipt 3.4

## 1. Product Summary
AptReceipt is a native macOS application engineered for apartment administrators, building managers, and property supervisors. It generates, tracks, and archives professional dues collection receipts (*Gelir/Tahsilat*), resident refund vouchers (*Sakin İadesi*), and building operating expenses (*Yönetim Harcaması*). It delivers instant vector PDF export, AirPrint/system printing, QR-code anti-tamper verification, multi-country late compensation calculation, and built-in GitHub release updating.

## 2. Core Entities & Architecture
- **Receipt**: Unique sequence number, kind (`income`, `outcome`, `managementExpense`), date, payer, payee, flat number, amount, currency, description, digital signature, QR code verification token, late fee breakdown (rate, months, amount, base amount), and jurisdiction-specific legal footnote.
- **Resident Directory**: Flat number, name, phone number, default payment notes.
- **Vendor Directory**: Company/contractor name, category (Elevator, Cleaning, Electrical, Maintenance, General), phone, tax ID/notes.
- **Archive / History**: Persistent store of emitted receipts with real-time search, category filtering, and CSV export.
- **Financial Balance & KPIs**: Cash register balance (*Kasa Özeti*), monthly income/expense distribution, and printable A4 bulletin board notices (*Pano İlanı*).
- **Multi-Country Late Fee Engine**:
  - Global toggle switch (`isLateFeeEnabled`).
  - Jurisdiction presets: Turkey (🇹🇷 KMK Md. 20/c), Romania (🇷🇴 Law 196/2018), International (🌐 HOA Bylaws), and Custom (⚙️).
  - Customizable due day, grace period in days, and receipt legal citation.
- **GitHub Update Checker**:
  - Semantic version evaluation (`SemverCompare`).
  - Release inspection via GitHub API (`berkbb/aptreceipt`).
  - Native alert presentations with direct release download links.

## 3. Localization & Governance
- Trilingual support: English (`en` - primary default), Turkish (`tr`), and Romanian (`ro`).
- Number and currency formatting adhering strictly to locale standards (`TRY`, `EUR`, `USD`, `RON`).
- Offline-first local storage (macOS Application Support & UserDefaults). Zero remote telemetry.
- Package identity: `com.babadogantech.aptreceipt` by **Babadogan Tech and Edu**.
