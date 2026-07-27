import Foundation

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let modificationDate: Date

    var displayName: String {
        name
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }

    var isMarkdown: Bool {
        ["md", "markdown", "mkd"].contains(fileExtension)
    }
}
