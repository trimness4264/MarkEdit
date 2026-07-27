import Foundation

enum FileAccessError: Error {
    case readFailed
    case writeFailed
    case fileAlreadyExists
}

class FileAccessHelper {
    static let shared = FileAccessHelper()

    private let bookmarkKey = "selectedFolderBookmark"

    func saveBookmark(for url: URL) throws {
        // iOS 不支持 .withSecurityScope（macOS 专用），使用默认选项即可
        let bookmark = try url.bookmarkData()
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
    }

    func loadBookmark() throws -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var isStale = false
        let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        if isStale {
            let newBookmark = try url.bookmarkData()
            UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
        }
        return url
    }

    func readFile(at url: URL) throws -> String {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var result: String?
        var readError: Error?
        var coordinatorError: NSError?

        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { url in
            do {
                result = try String(contentsOf: url, encoding: .utf8)
            } catch {
                readError = error
            }
        }

        if let error = coordinatorError {
            throw error
        }
        if let error = readError {
            throw error
        }
        guard let string = result else {
            throw FileAccessError.readFailed
        }
        return string
    }

    func writeFile(_ content: String, to url: URL) throws {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var writeError: Error?
        var coordinatorError: NSError?

        coordinator.coordinate(writingItemAt: url, options: [], error: &coordinatorError) { url in
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                writeError = error
            }
        }

        if let error = coordinatorError {
            throw error
        }
        if let error = writeError {
            throw error
        }
    }

    func listMarkdownFiles(in directory: URL) throws -> [FileItem] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey]
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)

        return urls.compactMap { url in
            let resourceValues = try? url.resourceValues(forKeys: Set(keys))
            let isDirectory = resourceValues?.isDirectory ?? false
            let modificationDate = resourceValues?.contentModificationDate ?? Date()
            let name = url.lastPathComponent

            if isDirectory {
                return nil
            } else {
                let ext = url.pathExtension.lowercased()
                if ["md", "markdown", "mkd"].contains(ext) {
                    return FileItem(url: url, name: name, isDirectory: false, modificationDate: modificationDate)
                }
            }
            return nil
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func createNewFile(named name: String, in directory: URL) throws -> URL {
        let safeName = name.hasSuffix(".md") ? name : name + ".md"
        let url = directory.appendingPathComponent(safeName)

        if FileManager.default.fileExists(atPath: url.path) {
            throw FileAccessError.fileAlreadyExists
        }
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        return url
    }

    func renameFile(at url: URL, to name: String) throws -> URL {
        let safeName = name.hasSuffix(".md") ? name : name + ".md"
        let destinationURL = url.deletingLastPathComponent().appendingPathComponent(safeName)

        if destinationURL != url, FileManager.default.fileExists(atPath: destinationURL.path) {
            throw FileAccessError.fileAlreadyExists
        }

        try FileManager.default.moveItem(at: url, to: destinationURL)
        return destinationURL
    }

    func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
