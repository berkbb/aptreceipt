# Product Requirements Document (PRD) - AptReceipt 2.0

## 1. Product Summary
AptReceipt is a native macOS application that enables apartment and site administrators to produce professional dues collection receipts (*Gelir/Tahsilat*), resident refunds (*Sakin İadesi*), and building operating expenses (*Yönetim Harcaması*). It delivers instant vector PDF export, AirPrint/system printing, and digital signature rendering.

## 2. Core Entities
- **Receipt**: Unique sequence number, kind (`income`, `outcome`, `managementExpense`), date, payer, payee, flat number (optional for management spending), amount, currency, description, digital signature, QR code verification token.
- **Resident**: Flat number, name, phone number, default payment notes.
- **Vendor**: Company/craftsman name, category (Elevator, Cleaning, Electricity/Water, Maintenance, General), phone, tax ID/notes.
- **Archive / History**: Persistent store of emitted receipts with searching and filtering.
- **Financial Balance**: Calculated sum of income vs expense with category breakdowns.

## 3. Localization
- Full support for English (`en`), Turkish (`tr`), and Romanian (`ro`).
- Number and currency formatting adhering to current locale standards.
- Number-to-words spelling engine supporting Turkish Lira, Euro, USD, and Romanian Leu.
