#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-aptreceipt}"
BUILD_ROOT="${BUILD_ROOT:-build}"
DIST_ROOT="${DIST_ROOT:-dist}"
REPO="${REPO:-berkbb/aptreceipt}"
BRANCH="${BRANCH:-main}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install it with: brew install gh" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]]; then
  echo "Releases must be made from $BRANCH." >&2
  exit 1
fi

git fetch --quiet origin "$BRANCH"
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$BRANCH")" ]]; then
  echo "Local $BRANCH is not in sync with origin/$BRANCH. Push or pull first." >&2
  exit 1
fi

./build_app.sh

VERSION="$(defaults read "$PWD/$BUILD_ROOT/$APP_NAME.app/Contents/Info" CFBundleShortVersionString)"
TAG="v$VERSION"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists on $REPO. Bump the version first." >&2
  exit 1
fi

echo "Verifying checksums..."
(cd "$DIST_ROOT" && shasum -a 256 -c SHA256SUMS.txt)

# Ed25519-sign the DMG with the key in the login keychain. The app only accepts
# updates signed by the key matching its bundled AptReceiptUpdatePublicEDKey.
DMG_PATH="$DIST_ROOT/$APP_NAME-$VERSION.dmg"
SIGNING_TOOL=(xcrun swift scripts/update_signing.swift)
APP_PUBLIC_KEY="$(defaults read "$PWD/$BUILD_ROOT/$APP_NAME.app/Contents/Info" AptReceiptUpdatePublicEDKey)"
KEYCHAIN_PUBLIC_KEY="$("${SIGNING_TOOL[@]}" public-key)"
if [[ "$APP_PUBLIC_KEY" != "$KEYCHAIN_PUBLIC_KEY" ]]; then
  echo "Signing key in keychain does not match AptReceiptUpdatePublicEDKey in the app." >&2
  exit 1
fi

echo "Signing $DMG_PATH..."
"${SIGNING_TOOL[@]}" sign "$DMG_PATH" > "$DMG_PATH.sig"
"${SIGNING_TOOL[@]}" verify "$DMG_PATH" "$(cat "$DMG_PATH.sig")" "$APP_PUBLIC_KEY"

# Release notes are the CHANGELOG.md section for this version.
NOTES_FILE="$(mktemp)"
trap 'rm -f "$NOTES_FILE"' EXIT
awk -v version="$VERSION" '
  $0 ~ "^## \\[" version "\\]" { in_section = 1; next }
  in_section && /^## \[/ { exit }
  in_section { print }
' CHANGELOG.md > "$NOTES_FILE"

if [[ ! -s "$NOTES_FILE" ]]; then
  echo "No CHANGELOG.md entry found for $VERSION." >&2
  exit 1
fi

cat >> "$NOTES_FILE" <<'EOF'

### Installation
Download the `.dmg`, open it and drag **aptreceipt** into **Applications**.

The app is ad-hoc signed and not notarized, so Gatekeeper blocks the first launch. Either allow it via **System Settings → Privacy & Security → Open Anyway** (macOS 15+) / right-click → **Open** (macOS 13–14), or remove the quarantine attribute:

```bash
xattr -dr com.apple.quarantine /Applications/aptreceipt.app
```

See [Gatekeeper & Quarantine](https://github.com/berkbb/aptreceipt#gatekeeper--quarantine) for details.

Verify downloads with `shasum -a 256 -c SHA256SUMS.txt`.
EOF

echo "Publishing $TAG to $REPO..."
gh release create "$TAG" \
  --repo "$REPO" \
  --target "$(git rev-parse HEAD)" \
  --title "$APP_NAME $VERSION" \
  --notes-file "$NOTES_FILE" \
  "$DMG_PATH" \
  "$DMG_PATH.sig" \
  "$DIST_ROOT/SHA256SUMS.txt"

echo "Done: $(gh release view "$TAG" --repo "$REPO" --json url --jq .url)"
