#!/usr/bin/env bash

set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-aptreceipt.xcodeproj}"
SCHEME="${SCHEME:-aptreceipt}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.deriveddata}"
OUTPUT_ROOT="${OUTPUT_ROOT:-artifacts}"
BUILD_DIR="$OUTPUT_ROOT/build/$CONFIGURATION"
APP_NAME="${APP_NAME:-aptreceipt}"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
FINAL_APP_PATH="$OUTPUT_ROOT/$APP_NAME.app"

echo "Preparing output directories..."
rm -rf "$OUTPUT_ROOT/build"
mkdir -p "$BUILD_DIR"

echo "Building $SCHEME ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "platform=macOS" \
  -quiet \
  CONFIGURATION_BUILD_DIR="$PWD/$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build failed: app not found at $APP_PATH" >&2
  exit 1
fi

echo "Copying app bundle..."
rm -rf "$FINAL_APP_PATH"
cp -R "$APP_PATH" "$FINAL_APP_PATH"

echo "Done: $FINAL_APP_PATH"
