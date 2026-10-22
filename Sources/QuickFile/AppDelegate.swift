import Cocoa
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let hotKey = HotKeyManager()
    private var statusWindowController: StatusWindowController?
    private var didHandleURL = false

    // MARK: - Lifecycle

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        hotKey.register { [weak self] in
            self?.createFromHotKey()
        }

        configureLoginItemOnce()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ExtensionRegistrar.registerOnceIfNeeded()

        // Opened by hand (no quickfile:// event): show the status window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, !self.didHandleURL else { return }
            self.showStatusWindow()
        }
    }

    // MARK: - URL handling

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string) else { return }
        didHandleURL = true
        handle(url)
    }

    private func handle(_ url: URL) {
        guard url.scheme == "quickfile" else { return }

        switch url.host {
        case "create":
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let folderPath = components.queryItems?.first(where: { $0.name == "folder" })?.value,
                  let ext = components.queryItems?.first(where: { $0.name == "ext" })?.value
            else { return }
            create(in: URL(fileURLWithPath: folderPath, isDirectory: true), extension: ext)

        case "settings":
            showStatusWindow()

        default:
            break
        }
    }

    // MARK: - Creating files

    private func create(in folder: URL, extension ext: String) {
        do {
            let result = try FileCreator.create(in: folder, extension: ext)
            NSWorkspace.shared.activateFileViewerSelecting([result.url])
        } catch {
            presentError(error)
        }
    }

    private func createFromHotKey() {
        do {
            let folder = try FinderBridge.frontFolder()
            create(in: folder, extension: "txt")
        } catch {
            presentError(error)
        }
    }

    // MARK: - Interface

    private func showStatusWindow() {
        if statusWindowController == nil {
            statusWindowController = StatusWindowController()
        }
        statusWindowController?.present()
    }

    private func presentError(_ error: Error) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Could not create the file"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()

        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Login item

    private func configureLoginItemOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "loginItemConfigured") else { return }
        defaults.set(true, forKey: "loginItemConfigured")
        LoginItem.setEnabled(true)
    }
}
