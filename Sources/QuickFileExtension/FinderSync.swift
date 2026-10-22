import Cocoa
import FinderSync

/// Finder Sync extension.
///
/// The extension is sandboxed by macOS, so it never writes files itself.
/// It only resolves the folder the user right-clicked in and hands the work
/// to the containing app through the `quickfile://` URL scheme.
@objc(FinderSync)
final class FinderSync: FIFinderSync {

    private struct FileKind {
        let title: String
        let ext: String
        let symbol: String
    }

    private let kinds: [FileKind] = [
        FileKind(title: "Tekst (.txt)", ext: "txt", symbol: "doc.text"),
        FileKind(title: "Markdown (.md)", ext: "md", symbol: "doc.plaintext"),
        FileKind(title: "Rich Text (.rtf)", ext: "rtf", symbol: "doc.richtext")
    ]

    /// Menu kind received right before the user picks an item.
    private var currentMenuKind: FIMenuKind = .contextualMenuForContainer

    override init() {
        super.init()
        // Monitor the whole filesystem so the menu is available in every folder.
        // (Inside the sandbox `homeDirectoryForCurrentUser` points at the app
        // container, so only the volume root makes sense here.)
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        currentMenuKind = menuKind

        let menu = NSMenu(title: "")

        let parent = NSMenuItem(title: "Nowy plik", action: nil, keyEquivalent: "")
        parent.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)

        let submenu = NSMenu(title: "Nowy plik")
        for (index, kind) in kinds.enumerated() {
            // `tag` survives the XPC hop to Finder; `representedObject` does not.
            let item = NSMenuItem(title: kind.title, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: nil)
            submenu.addItem(item)
        }

        parent.submenu = submenu
        menu.addItem(parent)
        return menu
    }

    // MARK: - Actions

    @objc private func createFile(_ sender: NSMenuItem) {
        guard kinds.indices.contains(sender.tag) else {
            debugLog("createFile: invalid tag \(sender.tag)")
            return
        }
        let kind = kinds[sender.tag]

        guard let folder = targetFolder(for: currentMenuKind) else {
            debugLog("createFile: could not resolve folder for menu kind \(currentMenuKind.rawValue)")
            return
        }

        var components = URLComponents()
        components.scheme = "quickfile"
        components.host = "create"
        components.queryItems = [
            URLQueryItem(name: "folder", value: folder.path),
            URLQueryItem(name: "ext", value: kind.ext)
        ]

        guard let url = components.url else {
            debugLog("createFile: could not build url")
            return
        }

        if !NSWorkspace.shared.open(url) {
            debugLog("createFile: opening \(url.absoluteString) failed")
        }
    }

    /// Resolves the folder the new file belongs in.
    ///
    /// - Right-click on a folder: inside that folder.
    /// - Right-click on a file: next to that file.
    /// - Right-click on background / sidebar: that folder.
    private func targetFolder(for menuKind: FIMenuKind) -> URL? {
        let controller = FIFinderSyncController.default()

        switch menuKind {
        case .contextualMenuForItems:
            if let selected = controller.selectedItemURLs(), !selected.isEmpty {
                if selected.count == 1, let only = selected.first, isDirectory(only) {
                    return only
                }
                return selected[0].deletingLastPathComponent()
            }
            return controller.targetedURL()

        case .contextualMenuForSidebar:
            return controller.targetedURL()
                ?? controller.selectedItemURLs()?.first(where: isDirectory)

        default:
            return controller.targetedURL()
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    // MARK: - Diagnostics

    /// Unified logging is not readable from the terminal on every setup, so the
    /// extension also appends to a file inside its sandbox container:
    /// ~/Library/Containers/pl.hpiotrowski.quickfile.extension/Data/tmp/quickfile-extension.log
    private func debugLog(_ message: String) {
        NSLog("QuickFile extension: %@", message)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("quickfile-extension.log")
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}
