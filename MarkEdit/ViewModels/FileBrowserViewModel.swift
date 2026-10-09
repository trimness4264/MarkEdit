import Foundation
import Combine

@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentDirectory: URL
    @Published var selectedFile: FileItem?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var recentFiles: [FileItem] = []
    @Published var searchText: String = ""

    private let recentFilesKey = "recentMarkdownFiles"
    private let recentBookmarksKey = "recentMarkdownFileBookmarks"
    private let fileAccess = FileAccessHelper.shared
    private var bookmarkURL: URL?

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.currentDirectory = documents
        loadRecentFiles()
        Task {
            await loadInitialFiles()
        }
    }

    private func loadInitialFiles() async {
        isLoading = true
        let documents = currentDirectory
        let result = await Task.detached { [fileAccess] in
            var directory = documents
            var bookmarkURL: URL?
            if let url = try? fileAccess.loadBookmark(),
               url.startAccessingSecurityScopedResource() {
                bookmarkURL = url
                directory = url
            }
            Self.ensureWelcomeFile(in: directory)
            let items = try fileAccess.listMarkdownFiles(in: directory)
            return (directory, bookmarkURL, items)
        }.result

        isLoading = false
        switch result {
        case .success(let value):
            currentDirectory = value.0
            bookmarkURL = value.1
            items = value.2
        case .failure(let error):
            errorMessage = "无法读取文件列表: \(error.localizedDescription)"
        }
    }

    func refresh() {
        isLoading = true
        let directory = currentDirectory
        Task {
            do {
                let loadedItems = try await Task.detached { [fileAccess] in
                    try fileAccess.listMarkdownFiles(in: directory)
                }.value
                items = loadedItems
            } catch {
                errorMessage = "无法读取文件列表: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func selectFolder(_ url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        do {
            // A sandbox directory needs no security scope. Let the actual read
            // decide whether the selected directory is accessible.
            let loadedItems = try fileAccess.listMarkdownFiles(in: url)
            if let oldURL = bookmarkURL {
                oldURL.stopAccessingSecurityScopedResource()
            }
            bookmarkURL = hasAccess ? url : nil
            currentDirectory = url
            items = loadedItems
            try? fileAccess.saveBookmark(for: url)
        } catch {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
            errorMessage = "无法打开文件夹: \(error.localizedDescription)"
        }
    }

    var filteredItems: [FileItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        let keyword = searchText.lowercased()
        return items.filter { $0.name.lowercased().contains(keyword) }
    }

    var filteredRecentFiles: [FileItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return recentFiles }
        let keyword = searchText.lowercased()
        return recentFiles.filter { $0.name.lowercased().contains(keyword) }
    }

    func createNewFile(named name: String) {
        do {
            let url = try fileAccess.createNewFile(named: name, in: currentDirectory)
            refresh()
            selectedFile = makeFileItem(from: url)
        } catch FileAccessError.fileAlreadyExists {
            errorMessage = "文件已存在"
        } catch {
            errorMessage = "创建文件失败: \(error.localizedDescription)"
        }
    }

    nonisolated private static func ensureWelcomeFile(in directory: URL) {
        let welcomeURL = directory.appendingPathComponent("Welcome.md")
        guard !FileManager.default.fileExists(atPath: welcomeURL.path) else { return }
        let content = """
        # 欢迎使用 MarkEdit

        这是一个简单的 Markdown 预览与编辑器。

        ## 功能

        - 在 App 内浏览和编辑 Markdown 文件
        - 实时预览渲染结果
        - 代码高亮
        - 浅色 / 深色 / 跟随系统主题
        - 导出为 HTML 或 PDF
        - 从系统「文件」App 中打开 .md 文件

        ## 示例

        **粗体**、*斜体*、`行内代码`。

        ```swift
        struct Welcome {
            let message = "Hello, MarkEdit!"
        }
        ```

        > 这是一个引用块。

        | 功能 | 状态 |
        |------|------|
        | 预览 | 已支持 |
        | 导出 | 已支持 |

        祝你使用愉快！
        """
        try? content.write(to: welcomeURL, atomically: true, encoding: .utf8)
    }

    func recordOpenedFile(_ url: URL) {
        guard ["md", "markdown", "mkd"].contains(url.pathExtension.lowercased()) else { return }
        var paths = UserDefaults.standard.stringArray(forKey: recentFilesKey) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        paths = Array(paths.prefix(10))
        UserDefaults.standard.set(paths, forKey: recentFilesKey)
        var bookmarks = UserDefaults.standard.dictionary(forKey: recentBookmarksKey) as? [String: Data] ?? [:]
        if let bookmark = try? url.bookmarkData() {
            bookmarks[url.path] = bookmark
        }
        bookmarks = bookmarks.filter { paths.contains($0.key) }
        UserDefaults.standard.set(bookmarks, forKey: recentBookmarksKey)
        loadRecentFiles()
    }

    func removeRecentFile(_ item: FileItem) {
        var paths = UserDefaults.standard.stringArray(forKey: recentFilesKey) ?? []
        paths.removeAll { $0 == item.url.path }
        UserDefaults.standard.set(paths, forKey: recentFilesKey)
        var bookmarks = UserDefaults.standard.dictionary(forKey: recentBookmarksKey) as? [String: Data] ?? [:]
        bookmarks.removeValue(forKey: item.url.path)
        UserDefaults.standard.set(bookmarks, forKey: recentBookmarksKey)
        loadRecentFiles()
    }

    private func loadRecentFiles() {
        let paths = UserDefaults.standard.stringArray(forKey: recentFilesKey) ?? []
        var bookmarks = UserDefaults.standard.dictionary(forKey: recentBookmarksKey) as? [String: Data] ?? [:]
        recentFiles = paths.compactMap { path in
            var url = URL(fileURLWithPath: path)
            var isStale = false
            if let bookmark = bookmarks[path],
               let resolved = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) {
                url = resolved
            }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }
            if isStale, let bookmark = try? url.bookmarkData() {
                bookmarks[path] = bookmark
            }
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey])
            return FileItem(
                url: url,
                name: url.lastPathComponent,
                isDirectory: values?.isDirectory ?? false,
                modificationDate: values?.contentModificationDate ?? .distantPast
            )
        }
        UserDefaults.standard.set(bookmarks, forKey: recentBookmarksKey)
    }

    func rename(item: FileItem, to name: String) -> URL? {
        do {
            let url = try fileAccess.renameFile(at: item.url, to: name)
            if selectedFile?.url == item.url {
                selectedFile = makeFileItem(from: url)
            }
            loadRecentFiles()
            refresh()
            return url
        } catch FileAccessError.fileAlreadyExists {
            errorMessage = "文件已存在"
        } catch {
            errorMessage = "重命名失败: \(error.localizedDescription)"
        }
        return nil
    }

    func delete(item: FileItem) {
        do {
            try fileAccess.deleteFile(at: item.url)
            if selectedFile == item {
                selectedFile = nil
            }
            loadRecentFiles()
            refresh()
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }

    private func makeFileItem(from url: URL) -> FileItem {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey])
        return FileItem(
            url: url,
            name: url.lastPathComponent,
            isDirectory: values?.isDirectory ?? false,
            modificationDate: values?.contentModificationDate ?? .distantPast
        )
    }
}
