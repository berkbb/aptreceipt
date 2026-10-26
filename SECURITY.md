# Security Policy

## Supported versions

Security fixes go into the latest release only. Update from the [Releases page](https://github.com/berkbb/aptreceipt/releases) or with **Check for Updates…** in the app menu.

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**, or go straight to [the private report form](https://github.com/berkbb/aptreceipt/security/advisories/new). Do not open a public issue.

Include the AptReceipt version, what you did, what happened and what someone could gain from it. You will get a reply in the report itself. Confirmed issues are fixed in a new release and published as a GitHub security advisory, with credit if you want it.

## What is in scope

- Receipt verification: sealed QR codes (`AR1.…`), verification codes, verification keys and recovery codes.
- Downloading updates: the SHA-256 and Ed25519 signature checks before a downloaded DMG is opened.
- System backups and the resident data the app stores on the Mac.

## Known design limits

These are deliberate and are not treated as vulnerabilities:

- Releases are ad-hoc signed, not notarized, so Gatekeeper asks before the first launch.
- The verification key is kept in a file in the app's own folder, not in the Keychain, and it is included in system backups. Anyone with access to your macOS account or to a backup file can make receipt codes that verify as genuine; keep backups private.
- Receipts printed before 3.6 carry no verification code and cannot be verified; Verify Receipt only compares them with the archive.
