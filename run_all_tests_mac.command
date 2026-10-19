#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=========================================="
echo " Running AptReceipt Test Suite (macOS)   "
echo "=========================================="

xcodebuild test \
  -project aptreceipt.xcodeproj \
  -scheme aptreceipt \
  -destination "platform=macOS" \
  -derivedDataPath .deriveddata \
  -only-testing:aptreceiptTests \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo ""
echo " All tests executed successfully!"
