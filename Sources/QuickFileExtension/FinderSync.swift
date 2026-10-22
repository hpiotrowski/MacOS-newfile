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
    }

    private let kinds: [FileKind] = [
        FileKind(title: "Tekst (.txt)", ext: "txt"),
        FileKind(title: "Markdown (.md)", ext: "md"),
        FileKind(title: "Rich Text (.rtf)", ext: "rtf")
    ]

    override init() {
        super.init()
        // Monitor the whole filesystem so the menu is available in every folder.
        // The home directory is added as a fallback in case a volume root is rejected.
        let home = FileManager.default.homeDirectoryForCurrentUser
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/"),
            home
        ]
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        NSLog("QuickFile extension: menu requested")
        let menu = NSMenu(title: "")

        let parent = NSMenuItem(title: "Nowy plik", action: nil, keyEquivalent: "")
        parent.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        let submenu = NSMenu(title: "Nowy plik")

        let symbols = ["doc.text", "doc.plaintext", "doc.richtext"]
        for (index, kind) in kinds.enumerated() {
            let item = NSMenuItem(title: kind.title, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = kind.ext
            if index < symbols.count {
                item.image = NSImage(systemSymbolName: symbols[index], accessibilityDescription: nil)
            }
            submenu.addItem(item)
        }

        parent.submenu = submenu
        menu.addItem(parent)
        return menu
    }

    // MARK: - Actions

    @objc private func createFile(_ sender: NSMenuItem) {
        guard let ext = sender.representedObject as? String else { return }
        guard let folder = targetFolder() else { return }

        var components = URLComponents()
        components.scheme = "quickfile"
        components.host = "create"
        components.queryItems = [
            URLQueryItem(name: "folder", value: folder.path),
            URLQueryItem(name: "ext", value: ext)
        ]

        guard let url = components.url else { return }
        NSWorkspace.shared.open(url)
    }

    /// Folder the user right-clicked in, or the selected folder itself.
    private func targetFolder() -> URL? {
        if let selected = FIFinderSyncController.default().selectedItemURLs(),
           let directory = selected.first(where: { isDirectory($0) }) {
            return directory
        }
        if let targeted = FIFinderSyncController.default().targetedURL(), isDirectory(targeted) {
            return targeted
        }
        return nil
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
