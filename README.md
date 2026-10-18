<img src="aptreceipt/Assets.xcassets/Logo.imageset/aparment_macos-2@256.png" width="160" alt="Apartment Receipt Logo" />

# Apartment Receipt Generator for macOS

A modern, native macOS application to effortlessly generate, manage, and export official apartment income and expense receipts.

## Features

- **Official A4 Invoice Format:** Styled to official ISO A4 itemized invoice standards with dual issuer/payer cards, service breakdown table, statutory tax exemption clause, and amounts in words.
- **Vector PDF & JPEG Export:** Export crystal-clear vector PDF documents with selectable text or high-resolution JPEG images.
- **Locale-Aware Smart Filenames:** Automatically generates descriptive filenames containing apartment name, document type, flat number, resident, and billing period formatted in the user's selected language.
- **Trilingual Support (English, Turkish, Romanian):** 1-to-1 localization for English (default), Turkish, and Romanian, automatically resolving to system locale or user choice.
- **Interactive License Viewer:** Direct read-only inspection of the GNU General Public License v3.0 from Preferences and About windows, highlighting publisher **berkbb**.
- **Real-Time Live Receipt Preview:** Live interactive preview card dynamically updates as you type.
- **Automatic Theme Support:** Light, Dark, and Automatic System appearance modes.
- **Dedicated Settings Window:** Accessible from the macOS Menu Bar (`Cmd+,` / `Preferences`) or the compact gear icon on the main screen, with tabbed sections for Building Details, Residents Directory, Appearance & Language, Signature, and About.
- **Residents Directory:** Save flat numbers and resident names for one-click auto-fill.
- **Digital Signature:** Import authorized signature images (PNG/JPEG) to print directly onto exported receipts.
- **Auto-Incrementing Sequence Numbers:** Receipt numbers increment automatically after generation.

---

## UI Screenshots

<table>
<tr>
  <td align="center"><b>Main Dashboard (Turkish)</b></td>
  <td align="center"><b>Main Dashboard (English)</b></td>
</tr>
<tr>
  <td><img src="docs/screenshots/01_main_dashboard.png" width="480" alt="Main Dashboard Turkish" /></td>
  <td><img src="docs/screenshots/05_main_dashboard_en.png" width="480" alt="Main Dashboard English" /></td>
</tr>
<tr>
  <td align="center"><b>Main Dashboard (Romanian)</b></td>
  <td align="center"><b>Preferences & About Window (License Viewer)</b></td>
</tr>
<tr>
  <td><img src="docs/screenshots/06_main_dashboard_ro.png" width="480" alt="Main Dashboard Romanian" /></td>
  <td><img src="docs/screenshots/03_settings_view.png" width="480" alt="Preferences & About" /></td>
</tr>
<tr>
  <td align="center"><b>A4 Income Receipt Certificate (PDF / JPEG)</b></td>
  <td align="center"><b>A4 Expense Receipt Certificate (PDF / JPEG)</b></td>
</tr>
<tr>
  <td><img src="docs/screenshots/02_receipt_document.png" width="480" alt="Income Receipt Certificate" /></td>
  <td><img src="docs/screenshots/04_receipt_outcome.png" width="480" alt="Expense Receipt Certificate" /></td>
</tr>
</table>

---

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)** - see the [LICENSE](LICENSE) file for details.

Publisher: **berkbb**
