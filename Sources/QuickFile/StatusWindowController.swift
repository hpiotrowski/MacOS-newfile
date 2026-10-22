import Cocoa
import FinderSync
import ServiceManagement

/// Small native window shown when the app is opened from Finder.
/// Doubles as onboarding: tells the user when the Finder extension
/// still needs to be enabled in System Settings.
final class StatusWindowController: NSWindowController, NSWindowDelegate {

    private var contentStack: NSStackView?

    private lazy var statusIcon: NSImageView = {
        let view = NSImageView()
        view.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
        view.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 10, weight: .regular)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var statusLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        return label
    }()

    private lazy var hintLabel: NSTextField = {
        let label = NSTextField(wrappingLabelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.isSelectable = true
        return label
    }()

    private lazy var enableButton: NSButton = {
        let button = NSButton(title: "Open Settings", target: self, action: #selector(openExtensionSettings))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        return button
    }()

    private lazy var restartButton: NSButton = {
        let button = NSButton(title: "Restart Finder", target: self, action: #selector(restartFinder))
        button.bezelStyle = .rounded
        return button
    }()

    private lazy var refreshButton: NSButton = {
        let button = NSButton(title: "Refresh", target: self, action: #selector(refresh))
        button.bezelStyle = .rounded
        return button
    }()

    private lazy var loginItemCheckbox: NSButton = {
        let button = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLoginItem))
        button.state = LoginItem.isEnabled ? .on : .off
        return button
    }()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "QuickFile"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        buildInterface()
        refresh()
    }

    // MARK: - Interface

    private func buildInterface() {
        guard let window, let contentView = window.contentView else { return }

        let icon = NSImageView()
        icon.image = NSImage(named: NSImage.applicationIconName)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "QuickFile")
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        let subtitle = NSTextField(labelWithString: "Create new files right from Finder's context menu.")
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabelColor

        let titleStack = NSStackView(views: [title, subtitle])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 2

        let header = NSStackView(views: [icon, titleStack])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 14

        let statusStack = NSStackView(views: [statusIcon, statusLabel])
        statusStack.orientation = .horizontal
        statusStack.alignment = .centerY
        statusStack.spacing = 6

        let buttons = NSStackView(views: [enableButton, restartButton, refreshButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let separator = NSBox()
        separator.boxType = .separator

        let shortcut = NSTextField(labelWithString: "⌃⌥⌘N creates a text file in the folder shown by the front Finder window.")
        shortcut.font = .systemFont(ofSize: 11)
        shortcut.textColor = .tertiaryLabelColor
        shortcut.isSelectable = true

        let stack = NSStackView(views: [
            header, statusStack, hintLabel, buttons, separator, loginItemCheckbox, shortcut
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        contentStack = stack

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
            statusIcon.widthAnchor.constraint(equalToConstant: 14),

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 44),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),

            separator.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        contentView.layoutSubtreeIfNeeded()
        let fitting = stack.fittingSize
        window.setContentSize(NSSize(width: 460, height: max(300, fitting.height + 44 + 24)))
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - State

    @objc func refresh() {
        let enabled = FIFinderSyncController.isExtensionEnabled

        statusLabel.stringValue = enabled ? "Finder extension active" : "Finder extension inactive"
        statusIcon.contentTintColor = enabled ? .systemGreen : .systemOrange
        enableButton.isHidden = enabled
        hintLabel.stringValue = enabled
            ? "Right-click inside a folder and choose \u{201C}New File\u{201D}."
            : "Enable \u{201C}QuickFile\u{201D} in System Settings → General → Login Items & Extensions, in the Finder extensions section, then restart Finder."
        loginItemCheckbox.state = LoginItem.isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func openExtensionSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.LoginItems-Settings.extension",
            "x-apple.systempreferences:com.apple.ExtensionsPreferences"
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) { break }
        }
    }

    @objc private func restartFinder() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Finder"]
        try? process.run()
        process.waitUntilExit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.refresh() }
    }

    @objc private func toggleLoginItem() {
        LoginItem.setEnabled(loginItemCheckbox.state == .on)
        loginItemCheckbox.state = LoginItem.isEnabled ? .on : .off
    }

    // MARK: - Presentation

    func present() {
        NSApp.setActivationPolicy(.regular)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        refresh()
    }
}

/// Login item registration so the hot key keeps working after a reboot.
enum LoginItem {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("QuickFile: login item update failed: %@", error.localizedDescription)
        }
    }
}
