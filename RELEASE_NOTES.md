## QuickFile 1.0.0

Adds the Windows-style **New File** action to Finder.

Right-click inside a folder → **New File** ▸ `Text (.txt)` / `Markdown (.md)` / `Rich Text (.rtf)`.
The file is created instantly as `Untitled.txt` (or `Untitled 2.txt`, …) and selected in Finder.

### Requirements

- macOS 14 or newer
- **Apple silicon** (arm64) — this build does not run on Intel Macs

### Install

1. Download `QuickFile-1.0.0-arm64.zip` below and unpack it.
2. Move `QuickFile.app` to `/Applications`.
3. Open it once. The app tries to register its Finder extension and shows a status window.
4. If the status window says the extension is inactive, enable **QuickFile** in
   **System Settings → General → Login Items & Extensions → Finder extensions**, then click
   **Restart Finder** in the app window.

### ⚠️ About the signature

This build is **ad-hoc signed**, not notarized by Apple (that requires a paid Developer ID).
macOS may therefore block it on first launch:

- **Recommended:** right-click `QuickFile.app` → **Open** → **Open** again.
- If it still refuses: `xattr -dr com.apple.quarantine /Applications/QuickFile.app`

Some systems are stricter with ad-hoc signed Finder extensions and may not offer the
extension in Settings at all. In that case build from source instead — see the README:

```sh
git clone https://github.com/hpiotrowski/MacOS-newfile.git
cd MacOS-newfile
./install.sh
```

### What works

- Context-menu creation in every folder, with native SF Symbols on macOS 26+
- Unique file names, new file revealed and selected in Finder
- Global shortcut ⌃⌥⌘N (needs one-time Automation permission for Finder)
- Status window with extension state, Settings deep link, Finder restart, launch-at-login

### Known limitations

- Finder places third-party items in the extension group near the bottom of the context
  menu; this cannot be changed through the Finder Sync API.
- Context-menu icons are drawn on macOS 26+ only.
- No auto-update.

### Uninstall

```sh
rm -rf /Applications/QuickFile.app
```
