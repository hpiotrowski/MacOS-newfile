# QuickFile — New File for macOS Finder

Brings the Windows-style **New File** action to macOS.

Right-click inside any folder → **New File** ▸ pick a type. The file is created instantly
with a collision-free name and selected in Finder.

```
New File
├── Text (.txt)
├── Markdown (.md)
└── Rich Text (.rtf)
```

> **Requirements:** macOS 14 or newer, Apple silicon (arm64).

---

## Install

### Option 1 — download (fast, unsigned)

1. Grab `QuickFile-1.0.0-arm64.zip` from [Releases](../../releases).
2. Unpack it and move `QuickFile.app` to `/Applications`.
3. Open it once — it registers its Finder extension and shows a status window.
4. If the window says the extension is inactive, enable **QuickFile** in
   **System Settings → General → Login Items & Extensions → Finder extensions**,
   then press **Restart Finder**.

The build is **ad-hoc signed**, not notarized, so macOS may block the first launch:
right-click the app → **Open**, or run

```sh
xattr -dr com.apple.quarantine /Applications/QuickFile.app
```

If your Mac refuses to load the extension from a downloaded ad-hoc build, use Option 2.

### Option 2 — build from source (recommended)

Needs the Command Line Tools (`xcode-select --install`); Xcode is not required.

```sh
git clone https://github.com/hpiotrowski/MacOS-newfile.git
cd MacOS-newfile
./install.sh
```

`install.sh` builds the app, copies it to `/Applications`, registers the extension with
`pluginkit`, enables it, restarts Finder and opens the app once.

## Usage

- **Context menu:** right-click inside a folder (or on a folder, or on a file) → `New File` → pick a type.
  - background → the file lands in the folder you are looking at
  - folder → the file lands inside that folder
  - file → the file lands next to that file
- **Shortcut:** ⌃⌥⌘N creates a text file in the folder shown by the front Finder window
  (also works on the Desktop). The first use asks for permission to control Finder —
  approve it once in **System Settings → Privacy & Security → Automation**.
- **Status window:** open `QuickFile` from `/Applications` to see whether the extension is
  active, restarted Finder, or toggle launch-at-login.

## How it works

```
QuickFile.app                     headless agent (LSUIElement, no Dock icon)
└── Contents/PlugIns/
    └── QuickFileExtension.appex  sandboxed Finder Sync extension
```

The Finder Sync extension is sandboxed by macOS, so it never writes files itself. It only
resolves the targeted folder and opens `quickfile://create?folder=…&ext=…`. The background
agent handles that URL, writes the file and reveals it in Finder. This avoids unreliable
writes from inside the extension process, and matches how polished Finder extensions work.

Finder's extension menus cross an XPC boundary, so menu items carry their payload in `tag`
— `representedObject` does not survive the trip.

The agent registers itself as a login item so the global shortcut survives a reboot.

## Build

```sh
./build.sh          # -> build/QuickFile.app (ad-hoc signed)
```

No Xcode project: `build.sh` compiles both targets with `swiftc`, assembles the bundle and
signs it. The icon is generated from the `doc.badge.plus` SF Symbol:

```sh
swift scripts/make-icon.swift
```

## Release

```sh
VERSION=1.0.0 ./scripts/package-release.sh
```

Produces `dist/QuickFile-1.0.0-arm64.zip` and its SHA256, and verifies the signature both
before and after a pack/unpack round-trip.

## Troubleshooting

```sh
# Is the extension registered and enabled?
pluginkit -m -p com.apple.FinderSync -v | grep quickfile

# Is the extension process running?
pgrep -fl QuickFileExtension

# Did Finder ask the extension for its menu?
log show --last 5m --predicate 'eventMessage CONTAINS "QuickFile extension"' --style compact

# Re-register and restart
./install.sh
```

## Limitations

- Finder decides context-menu placement: the item appears in the extension group near the
  bottom, not next to Finder's own *New Folder*. The Finder Sync API offers no control.
- Context-menu icons render on macOS 26+; older systems show plain items.
- The release build is ad-hoc signed. For a warning-free install, sign with a Developer ID
  and notarize.
- arm64 only.

## Uninstall

```sh
./uninstall.sh
```

## License

MIT — see [LICENSE](LICENSE).
