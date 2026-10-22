import Cocoa

/// Reads the folder shown in Finder's frontmost window.
enum FinderBridge {

    enum BridgeError: LocalizedError {
        case automationDenied
        case noFolder

        var errorDescription: String? {
            switch self {
            case .automationDenied:
                return "QuickFile potrzebuje zgody na sterowanie Finderem. Włącz ją w Ustawieniach → Prywatność i bezpieczeństwo → Automatyzacja."
            case .noFolder:
                return "Nie udało się ustalić folderu otwartego w Finderze."
            }
        }
    }

    static func frontFolder() throws -> URL {
        // `insertion location` is the folder shown in the front Finder window
        // (or the Desktop when no window is open).
        let source = """
        tell application "Finder"
            return POSIX path of (insertion location as alias)
        end tell
        """

        guard let script = NSAppleScript(source: source) else { throw BridgeError.noFolder }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            // -1743: user denied Automation access
            if code == -1743 || code == -10004 {
                throw BridgeError.automationDenied
            }
            throw BridgeError.noFolder
        }

        guard let path = result.stringValue, !path.isEmpty else {
            throw BridgeError.noFolder
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}
