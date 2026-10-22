#!/bin/bash
#
# Builds QuickFile.app with a Finder Sync extension using only the
# Command Line Tools (no Xcode project required).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/QuickFile.app"
APPEX="$APP/Contents/PlugIns/QuickFileExtension.appex"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
TARGET="arm64-apple-macos14.0"

echo "==> Cleaning"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS"

echo "==> Compiling agent"
swiftc -O -target "$TARGET" -sdk "$SDK" \
    -framework Cocoa -framework FinderSync -framework ServiceManagement \
    "$ROOT"/Sources/QuickFile/*.swift \
    -o "$APP/Contents/MacOS/QuickFile"

echo "==> Compiling Finder extension"
swiftc -O -target "$TARGET" -sdk "$SDK" \
    -parse-as-library -application-extension \
    -framework Cocoa -framework FinderSync \
    -Xlinker -e -Xlinker _NSExtensionMain \
    "$ROOT"/Sources/QuickFileExtension/*.swift \
    -o "$APPEX/Contents/MacOS/QuickFileExtension"

echo "==> Assembling bundle"
cp "$ROOT/Resources/QuickFile-Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/QuickFileExtension-Info.plist" "$APPEX/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
printf 'XPC!????' > "$APPEX/Contents/PkgInfo"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi
xattr -cr "$APP"

echo "==> Signing (ad-hoc)"
codesign --force --sign - --timestamp=none \
    --entitlements "$ROOT/Resources/QuickFileExtension.entitlements" \
    "$APPEX"
codesign --force --sign - --timestamp=none "$APP"

echo "==> Built: $APP"
