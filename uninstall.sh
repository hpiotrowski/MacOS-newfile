#!/bin/bash
#
# Removes QuickFile, its Finder extension registration and its preferences.
#
set -euo pipefail

APP_NAME="QuickFile.app"
DEST="/Applications/$APP_NAME"
EXT_ID="pl.hpiotrowski.quickfile.extension"

echo "==> Quitting"
osascript -e 'tell application "QuickFile" to quit' >/dev/null 2>&1 || true
pkill -f "$APP_NAME/Contents/MacOS/QuickFile" >/dev/null 2>&1 || true

echo "==> Unregistering extension"
pluginkit -r "$DEST/Contents/PlugIns/QuickFileExtension.appex" >/dev/null 2>&1 || true
pluginkit -e ignore -i "$EXT_ID" >/dev/null 2>&1 || true

echo "==> Removing app"
rm -rf "$DEST"

echo "==> Removing preferences"
defaults delete pl.hpiotrowski.quickfile >/dev/null 2>&1 || true

killall Finder >/dev/null 2>&1 || true
echo "Done."
