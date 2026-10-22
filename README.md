# MacOS-newfile (QuickFile)

Brings the Windows-style **New File** action to macOS Finder.

Right-click inside any folder → **Nowy plik** ▸ `Tekst (.txt)` / `Markdown (.md)` / `Rich Text (.rtf)`.
The file is created instantly with a collision-free name and selected in Finder.

```
Nowy plik
├── Tekst (.txt)
├── Markdown (.md)
└── Rich Text (.rtf)
```

## Features

- Native Finder context-menu entry (Finder Sync extension, SF Symbols, dark-mode aware)
- Instant creation — no dialog; the new file is revealed and selected in Finder
- Unique names: `Nowy plik.txt`, `Nowy plik 2.txt`, `Nowy plik 3.txt`, …
- Right-clicking a folder creates the file **inside** that folder; right-clicking a file
  creates it next to the file
- Global shortcut **⌃⌥⌘N** creates a text file in the folder shown by the front Finder window
  (also works on the Desktop, where the context menu cannot reach)
- Small status window (double-click `QuickFile` in `/Applications`) shows whether the
  extension is enabled and offers a one-click Finder restart

## How it works

```
QuickFile.app                     headless agent (LSUIElement, no Dock icon)
└── Contents/PlugIns/
    └── QuickFileExtension.appex  sandboxed Finder Sync extension
```

The Finder Sync extension is sandboxed by macOS, so it never writes files itself. It only
resolves the targeted folder and opens `quickfile://create?folder=…&ext=…`. The background
agent handles that URL, writes the file and reveals it in Finder. This avoids unreliable
writes from inside the extension process.

The agent also registers itself as a login item so the global shortcut keeps working after
a reboot.

## Requirements

- macOS 14 or newer (developed and tested on macOS 26.6, Apple silicon)
- Command Line Tools (`xcode-select --install`) — no Xcode project needed

## Build

```sh
./build.sh
```

The result is `build/QuickFile.app`, ad-hoc signed so it runs locally without a Developer
account.

The icon is generated from the `doc.badge.plus` SF Symbol:

```sh
swift scripts/make-icon.swift
```

## Install

```sh
./install.sh
```

The script builds, copies the app to `/Applications`, registers the extension with
`pluginkit`, enables it, restarts Finder and launches the app once.

A stable path in `/Applications` matters — macOS treats the bundle identity with the
extension registration, and login items require it.

### Enabling the extension

macOS requires a one-time user toggle; there is no API to flip it automatically:

**System Settings → General → Login Items & Extensions → Finder extensions** → enable
`QuickFile`, then restart Finder.

The status window deep-links to the right pane and can restart Finder for you.

## Usage

- **Context menu:** right-click a folder (or empty space in a Finder window) → `Nowy plik` → pick a type.
- **Shortcut:** ⌃⌥⌘N. The first use asks for permission to control Finder
  (System Settings → Privacy & Security → Automation). Approve once.

## Limitations

- Finder controls context-menu placement: the item appears in the extension group near the
  bottom of the menu, not next to Finder's own *New Folder*. This cannot be changed through
  the Finder Sync API.
- Icons inside context menus are rendered on macOS 26+; older systems show plain items.
- The app is ad-hoc signed. If macOS refuses to load the extension after an update, re-run
  `./install.sh`. For distribution outside this machine, sign with a Developer ID and
  notarize.
- Builds for `arm64` only (edit `TARGET` in `build.sh` if needed).

## Troubleshooting

```sh
# Is the extension registered and enabled?
pluginkit -m -p com.apple.FinderSync -v | grep quickfile

# Is the extension process running?
pgrep -fl QuickFileExtension

# Did Finder ask the extension for its menu?
log show --last 5m --predicate 'eventMessage CONTAINS "QuickFile extension"' --style compact

# Fallback when unified logging is unreadable: the extension's own log
cat ~/Library/Containers/pl.hpiotrowski.quickfile.extension/Data/tmp/quickfile-extension.log

# Re-register and restart
./install.sh
```

## Uninstall

```sh
./uninstall.sh
```

## Project structure

```
Sources/QuickFile/              agent (URL handling, file creation, hot key, status window)
Sources/QuickFileExtension/     Finder Sync extension (menu only)
Resources/                      Info.plists, entitlements, generated icon
scripts/make-icon.swift         icon renderer
build.sh                        compile + assemble bundle + ad-hoc sign
install.sh / uninstall.sh       install / remove
```

## License

MIT
