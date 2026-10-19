#!/usr/bin/env bash

set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-aptreceipt.xcodeproj}"
SCHEME="${SCHEME:-aptreceipt}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.deriveddata}"
ENTITLEMENTS="${ENTITLEMENTS:-aptreceipt/aptreceipt.entitlements}"
APP_NAME="${APP_NAME:-aptreceipt}"
BUILD_ROOT="${BUILD_ROOT:-build}"
DIST_ROOT="${DIST_ROOT:-dist}"
PRODUCTS_DIR="$DERIVED_DATA_PATH/products/$CONFIGURATION"
APP_PATH="$PRODUCTS_DIR/$APP_NAME.app"
FINAL_APP_PATH="$BUILD_ROOT/$APP_NAME.app"

echo "Preparing output directories..."
rm -rf "$PRODUCTS_DIR" "$BUILD_ROOT" "$DIST_ROOT"
mkdir -p "$PRODUCTS_DIR" "$BUILD_ROOT" "$DIST_ROOT"

echo "Building $SCHEME ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "platform=macOS" \
  -quiet \
  CONFIGURATION_BUILD_DIR="$PWD/$PRODUCTS_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build failed: app not found at $APP_PATH" >&2
  exit 1
fi

echo "Copying app bundle..."
ditto "$APP_PATH" "$FINAL_APP_PATH"

echo "Ad-hoc signing app bundle..."
codesign --force --deep --sign - --timestamp=none \
  --entitlements "$ENTITLEMENTS" \
  "$FINAL_APP_PATH"
codesign --verify --deep --strict "$FINAL_APP_PATH"

VERSION="$(defaults read "$PWD/$FINAL_APP_PATH/Contents/Info" CFBundleShortVersionString)"
DMG_NAME="$APP_NAME-$VERSION.dmg"

echo "Creating $DMG_NAME..."
DMG_STAGING="$(mktemp -d)"
trap 'rm -rf "$DMG_STAGING"' EXIT
ditto "$FINAL_APP_PATH" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_STAGING" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  -quiet \
  "$DIST_ROOT/$DMG_NAME"
codesign --force --sign - "$DIST_ROOT/$DMG_NAME"

echo "Writing SHA-256 checksums..."
(cd "$DIST_ROOT" && shasum -a 256 "$DMG_NAME" > SHA256SUMS.txt)

echo "Done:"
echo "  $FINAL_APP_PATH"
echo "  $DIST_ROOT/$DMG_NAME"
echo "  $DIST_ROOT/SHA256SUMS.txt"
