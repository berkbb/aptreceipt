# Offline QR Verification — Plan

- **Status:** Approved 2026-10-20. Phase 1 done (verification code, key store, backup, tests); phases 2–4 pending.
- **Scope:** Receipt QR code (`ReceiptDocumentView`), a verification secret, a "Verify Receipt" window in AptReceipt, Settings and the system backup.
- **Constraint:** Fully offline. No web page, no server, no domain (`user_rejected_spec.md`). A hosted verification page was proposed first and rejected.

## Goal

1. Anyone who scans the receipt QR code with a phone camera sees the receipt details as clear, labeled lines in the receipt's language — no internet needed.
2. The building manager can check any receipt in AptReceipt, offline: genuine (issued by this app installation and unchanged) or not, shown as a POS-style slip.

A phone camera cannot run code or open a local page from a QR code, so a resident's phone can show the text but cannot prove it is genuine; the proof happens in AptReceipt. The receipt text says this honestly.

## What the QR code contains

Plain UTF-8 text, one field per line, labels from the language files (tr/en/ro, 1:1):

```
AptReceipt
YILDIZ SİTESİ YÖNETİMİ
Tahsilat Makbuzu · TAH-1042
Tarih: 20.10.2026 · Dönem: Ekim 2026
Daire 12 · Ayşe Yılmaz
Aidat: ₺12.000,00
Gecikme bedeli: ₺750,50
Toplam: ₺12.750,50
Yönetici: Mehmet Şahin
Doğrulama: K7QM-2XPA-9TRB-4HWD
```

- Amounts are formatted with `AppFormat`, upper-casing with `l10n.uppercased`, exactly as printed on the receipt.
- Lines that are hidden on the receipt (flat number, late fee) are left out; notes are left out (length).
- Long names are capped at 40 characters so the code stays scannable.

## Verification code

- HMAC-SHA256 over the QR text itself (all lines above the code line), normalized so line endings, surrounding spaces, empty lines and Unicode composition do not matter, with the domain prefix `AptReceipt receipt code v1`. Truncated to 80 bits and written as 16 Crockford Base32 characters in four groups (no I, L, O, U; typed O/I/L are read as 0/1). Covering the text instead of separate fields means verification never has to parse amounts back, and any changed character breaks the code. A pinned test value guards the algorithm, because printed codes must stay valid forever.
- Each key is 32 random bytes; the first is created on first use for this installation. Only AptReceipt checks codes, so a shared secret is enough and keeps the code short (an Ed25519 signature would add 86 characters and its public key would be useless without a page).
- 80 bits cannot be guessed; changing any field (amount, name, date) breaks the code.
- Storage: app container `Application Support/aptreceipt/receipt-verification-keys` (32 bytes per key, current first), permissions 0600; an unreadable file is moved aside, never overwritten. Not the Keychain while builds are ad-hoc signed (the Keychain would ask for the password after every update).
- Injectable store (file or in-memory), like `InMemoryDefaults`: tests and screenshot runs never touch the real secret.
- The system backup (format 2.2) carries the keys. Restoring puts the backup's keys first and keeps this Mac's keys after them, so receipts from both still verify. Reset preferences keeps them.

## Verify Receipt window (AptReceipt)

- Opened from the Archive sheet and the app menu.
- Input: drop or choose a PNG, JPEG or PDF of a receipt (QR read with Vision, already used for invoice scanning), or paste the QR text.
- Output, offline: a POS-style slip (monospace, 80 mm strip, dashed rules, the same fields) with a stamp:
  - **Genuine** — the code matches this installation's secret; also says whether the receipt is in the archive, and flags differences from the archived record.
  - **Altered or not from this app** — the code does not match.
  - **Older receipt without a code** — plain QR from earlier versions; shown, not verified.
- All texts in tr/en/ro language files.

## Receipt changes

- The QR code contains the text above; 0.5 mm per module, so about 100–110 pt wide, with the footer adapting.
- The footer notice changes from "Scan with phone camera to verify receipt authenticity" to an accurate text, for example "Scan to read the receipt details. The building management verifies the code with AptReceipt." in all three languages.
- Already printed receipts keep their old QR; reprints from the archive get the new one.

## Tests

- Text QR: lines and labels per language, amounts as on the receipt, hidden fields left out, caps applied; the worst case decodes from the JPEG and PDF export paths (Vision).
- Code: the same fields give the same code; any changed field fails; a different secret fails; Base32 grouping.
- Parser: the QR text of every language parses back to the same fields; old plain QR texts are recognized as "without a code".
- Secret store isolation, backup round trip, reset keeps the secret, screenshot runs use an in-memory secret.
- Verify window: decoding from an exported PDF and JPEG of a receipt; archive match and mismatch.
- Language parity for all new keys (existing parity tests).

## Phases

1. Canonical fields, verification code, secret store, backup and tests (no visible change).
2. QR text and receipt footer in three languages, QR sizing, decode tests.
3. Verify Receipt window, menu and archive entry points, tests.
4. Screenshots, README, CHANGELOG; release as 3.6.0 when approved.

## Not doing

- Any web page, server or domain, hosted or cached.
- HTML or `data:` links inside the QR code.
- Public-key signatures for residents (no way to check them offline on a phone without an app).
