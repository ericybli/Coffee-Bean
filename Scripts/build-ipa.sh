#!/bin/bash
# Build an UNSIGNED device IPA for AltStore sideloading.
# Works with the local Xcode 16.3 (iOS 18.4 SDK) — the app runs fine on iOS 26 devices.
# Output: dist/CoffeeBean.ipa  (AltStore re-signs it with your free Apple ID on install)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/App"
DIST="$ROOT/dist"
BUILD="$DIST/build"

echo "▸ regenerate Xcode project"
(cd "$APP_DIR" && xcodegen generate --spec project.yml >/dev/null)

echo "▸ build Release for device (unsigned)"
xcodebuild -project "$APP_DIR/CoffeeBean.xcodeproj" -scheme CoffeeBean \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  CONFIGURATION_BUILD_DIR="$BUILD" build | grep -E "BUILD (SUCCEEDED|FAILED)" || true

test -d "$BUILD/CoffeeBean.app" || { echo "✗ build failed — CoffeeBean.app not found"; exit 1; }

echo "▸ package IPA"
rm -rf "$DIST/Payload" "$DIST/CoffeeBean.ipa"
mkdir -p "$DIST/Payload"
cp -R "$BUILD/CoffeeBean.app" "$DIST/Payload/"
(cd "$DIST" && zip -qr CoffeeBean.ipa Payload && rm -rf Payload)

echo "✓ $(du -h "$DIST/CoffeeBean.ipa" | cut -f1 | tr -d ' ')  →  $DIST/CoffeeBean.ipa"
echo "  AirDrop it to the iPhone, then AltStore → My Apps → ＋ → pick it."
