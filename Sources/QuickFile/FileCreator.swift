import Foundation

/// Creates new files with collision-free names.
enum FileCreator {

    static let baseName = "Untitled"

    struct Result {
        let url: URL
    }

    enum CreateError: LocalizedError {
        case notADirectory(URL)
        case writeFailed(URL, Error)

        var errorDescription: String? {
            switch self {
            case .notADirectory(let url):
                return "“\(url.lastPathComponent)” is not a folder."
            case .writeFailed(let url, let error):
                return "Could not create a file in “\(url.path)”: \(error.localizedDescription)"
            }
        }
    }

    /// Creates an empty file with the given extension inside `folder`.
    /// If the name is taken, the next free number is used: "Untitled 2.txt".
    @discardableResult
    static func create(in folder: URL, extension ext: String) throws -> Result {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw CreateError.notADirectory(folder)
        }

        let url = uniqueURL(in: folder, extension: ext)
        do {
            try Data().write(to: url, options: .withoutOverwriting)
        } catch {
            throw CreateError.writeFailed(folder, error)
        }
        return Result(url: url)
    }

    static func uniqueURL(in folder: URL, extension ext: String) -> URL {
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        var candidate = folder.appendingPathComponent(baseName + suffix)
        var index = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(baseName) \(index)\(suffix)")
            index += 1
        }
        return candidate
    }
}
