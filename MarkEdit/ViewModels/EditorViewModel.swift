import Foundation
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var html: String = ""
    @Published var fileURL: URL?
    @Published var isDirty: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving: Bool = false
    @Published var lastSavedAt: Date?

    private let fileAccess = FileAccessHelper.shared
    private let renderer = MarkdownRenderer.shared
    private var originalText: String = ""
    private var securityScopedURL: URL?
    init() {}

    deinit {
        securityScopedURL?.stopAccessingSecurityScopedResource()
    }

    @discardableResult
    func openFile(at url: URL) -> Bool {
        // Keep access for the entire editing session, including subsequent saves.
        // Local sandbox URLs may return false and are still readable.
        let hasAccess = url.startAccessingSecurityScopedResource()
        do {
            let content = try fileAccess.readFile(at: url)
            securityScopedURL?.stopAccessingSecurityScopedResource()
            securityScopedURL = hasAccess ? url : nil
            errorMessage = nil
            self.fileURL = url
            self.text = content
            self.originalText = content
            self.isDirty = false
            self.isSaving = false
            self.lastSavedAt = fileModificationDate(for: url)
            updatePreview(text: content)
            return true
        } catch {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
            errorMessage = "无法打开文件: \(error.localizedDescription)"
            return false
        }
    }

    func updatePreview(text: String, previewTheme: PreviewTheme = .light, codeTheme: CodeTheme = .github) {
        let bodyHTML = renderer.renderHTML(from: text)
        html = HTMLRenderer.shared.renderFullHTML(bodyHTML: bodyHTML, previewTheme: previewTheme, codeTheme: codeTheme)
    }

    func save() {
        guard let url = fileURL else { return }
        isSaving = true
        do {
            try fileAccess.writeFile(text, to: url)
            originalText = text
            isDirty = false
            lastSavedAt = Date()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func discardChanges() {
        text = originalText
        isDirty = false
        updatePreview(text: originalText)
    }

    func renameCurrentFile(to url: URL) {
        fileURL = url
        lastSavedAt = fileModificationDate(for: url)
    }

    func updateText(_ newText: String) {
        text = newText
        isDirty = newText != originalText
        updatePreview(text: newText)
    }

    private func fileModificationDate(for url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
