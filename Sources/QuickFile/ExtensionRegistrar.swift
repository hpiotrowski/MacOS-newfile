import Cocoa
import FinderSync

/// Registers the bundled Finder extension on first launch.
///
/// People who install from a release archive never run `install.sh`, so the
/// app does the `pluginkit` registration itself once. macOS still owns the
/// final say (System Settings toggle); this only removes the terminal step.
enum ExtensionRegistrar {

    private static let attemptKey = "extensionRegistrationAttempted"

    static func registerOnceIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: attemptKey) else { return }
        defaults.set(true, forKey: attemptKey)

        guard let appex = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("QuickFileExtension.appex"),
            FileManager.default.fileExists(atPath: appex.path) else {
            NSLog("QuickFile: extension bundle not found")
            return
        }

        let identifier = Bundle(url: appex)?.bundleIdentifier
            ?? "pl.hpiotrowski.quickfile.extension"

        if !isRegistered(identifier) {
            run("/usr/bin/pluginkit", ["-a", appex.path])
        }

        if !FIFinderSyncController.isExtensionEnabled {
            run("/usr/bin/pluginkit", ["-e", "use", "-i", identifier])

            // Finder only picks up a newly enabled extension after a restart.
            if FIFinderSyncController.isExtensionEnabled {
                run("/usr/bin/killall", ["Finder"])
            }
        }
    }

    private static func isRegistered(_ identifier: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-i", identifier]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return output.contains(identifier)
    }

    private static func run(_ executable: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("QuickFile: %@ %@ failed: %@",
                  executable, arguments.joined(separator: " "), error.localizedDescription)
        }
    }
}
