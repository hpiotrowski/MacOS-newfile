# MacOS-newfile

A native macOS app that brings the Windows-style **New File** action to Finder's right-click menu.

Right-click in any Finder folder → **New File** → pick a type. The file is created instantly,
with a unique name, and selected in Finder.

## Status

Work in progress — see the plan below.

## Planned behaviour

- Finder context menu item: `New File` ▸ `Text (.txt)`, `Markdown (.md)`, `Rich Text (.rtf)`
- Unique naming: `Untitled.txt`, `Untitled 2.txt`, ...
- New file is revealed and selected in Finder right after creation
- Optional global shortcut (⌃⌥⌘N) for the current Finder folder and the Desktop

## Architecture

```
QuickFile.app                    headless agent (LSUIElement)
└─ Contents/PlugIns/
   QuickFileExtension.appex      sandboxed Finder Sync extension
```

The Finder Sync extension is sandboxed, so it only reads the targeted folder and opens a
`quickfile://` URL. The background agent creates the file — this mirrors how native-quality
Finder extensions work and avoids unreliable writes from inside the extension process.

## Known limitations

- Finder controls context-menu placement: the item appears in the extension group near the
  bottom of the menu, not above Finder's own *New Folder*. This cannot be changed through
  the Finder Sync API.
- Finder Sync extensions must be enabled once in System Settings → General → Login Items &
  Extensions. There is no API to enable them automatically.
