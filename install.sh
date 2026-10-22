#!/bin/bash
#
# Builds and installs QuickFile, then registers the Finder extension.
# A stable path in /Applications is required for the login item and for
# macOS to keep the extension enabled across reboots.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="QuickFile.app"
DEST="/Applications/$APP_NAME"
EXT_ID="pl.hpiotrowski.quickfile.extension"

"$ROOT/build.sh"

echo "==> Quitting running instance"
osascript -e 'tell application "QuickFile" to quit' >/dev/null 2>&1 || true
pkill -f "$APP_NAME/Contents/MacOS/QuickFile" >/dev/null 2>&1 || true

echo "==> Installing to /Applications"
rm -rf "$DEST"
cp -R "$ROOT/build/$APP_NAME" "$DEST"
xattr -cr "$DEST"

echo "==> Registering with LaunchServices and pluginkit"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/QuickFileExtension.appex"
pluginkit -e use -i "$EXT_ID" || true

echo "==> Restarting Finder"
killall Finder >/dev/null 2>&1 || true

sleep 1
echo
if pluginkit -m -p com.apple.FinderSync -v | grep -q "$EXT_ID"; then
    echo "Rozszerzenie zarejestrowane."
else
    echo "UWAGA: rozszerzenie nie zostało zarejestrowane. Uruchom ponownie install.sh."
fi
echo
echo "Gotowe. Kliknij prawym przyciskiem w dowolnym folderze → „Nowy plik”."
echo "Jeśli pozycji nie ma: Ustawienia → Ogólne → Elementy logowania i rozszerzenia."
echo "Skrót: ⌃⌥⌘N (plik tekstowy w folderze otwartego okna Findera)."

open -a "$DEST"
