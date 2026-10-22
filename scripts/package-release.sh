#!/bin/bash
#
# Builds the app and packs it into a release archive:
#
#   dist/QuickFile-<version>-arm64.zip
#   dist/QuickFile-<version>-arm64.zip.sha256
#
# Usage:
#   ./scripts/package-release.sh            # version 1.0.0
#   VERSION=1.0.1 ./scripts/package-release.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-1.0.0}"
DIST="$ROOT/dist"
NAME="QuickFile-$VERSION-arm64.zip"
ZIP="$DIST/$NAME"

"$ROOT/build.sh"

echo "==> Verifying signature and architecture"
codesign --verify --deep --strict "$ROOT/build/QuickFile.app"
ARCHS="$(lipo -archs "$ROOT/build/QuickFile.app/Contents/MacOS/QuickFile")"
if [[ "$ARCHS" != "arm64" ]]; then
    echo "ERROR: expected an arm64 build, got: $ARCHS"
    exit 1
fi

echo "==> Packing $NAME"
mkdir -p "$DIST"
rm -f "$ZIP" "$ZIP.sha256"
# ditto keeps the code signature, symlinks and bundle metadata intact.
ditto -c -k --keepParent "$ROOT/build/QuickFile.app" "$ZIP"

echo "==> Checksums"
( cd "$DIST" && shasum -a 256 "$NAME" > "$NAME.sha256" && cat "$NAME.sha256" )

echo "==> Round-trip check"
TMP="$(mktemp -d)"
ditto -x -k "$ZIP" "$TMP"
codesign --verify --deep --strict "$TMP/QuickFile.app"
echo "    unpacked bundle still passes signature validation"
rm -rf "$TMP"

echo
echo "Release archive ready:"
echo "  $ZIP"
echo "  $ZIP.sha256"
