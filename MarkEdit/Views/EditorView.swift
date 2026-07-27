import SwiftUI

struct EditorView: View {
    @ObservedObject var editor: EditorViewModel
    @EnvironmentObject private var settings: PreviewSettings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showPreview = true
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isExportingPDF = false
    @State private var phoneTab = 0
    @State private var showUnsavedAlert = false
    @State private var editorText = ""

    private var effectivePreviewTheme: PreviewTheme {
        settings.previewTheme == .system ? (colorScheme == .dark ? .dark : .light) : settings.previewTheme
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsToolbarView(
                showPreview: $showPreview,
                canSave: editor.isDirty,
                onSave: { editor.save() },
                onShareMarkdown: shareMarkdown,
                onExportHTML: exportHTML,
                onExportPDF: exportPDF
            )
            .environmentObject(settings)

            if showPreview {
                if horizontalSizeClass == .regular {
                    // iPad / 大屏：左右分屏
                    HStack(spacing: 0) {
                        editPane
                        Divider()
                        previewPane
                    }
                } else {
                    // iPhone：编辑 / 预览切换
                    VStack(spacing: 0) {
                        Picker("", selection: $phoneTab) {
                            Text("预览").tag(0)
                            Text("编辑").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)

                        if phoneTab == 0 {
                            previewPane
                        } else {
                            editPane
                        }
                    }
                }
            } else {
                editPane
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("错误", isPresented: Binding(
            get: { editor.errorMessage != nil },
            set: { if !$0 { editor.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(editor.errorMessage ?? "")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .overlay {
            if isExportingPDF {
                ProgressView("正在生成 PDF…")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
        }
        .onAppear {
            editorText = editor.text
            refreshPreview()
        }
        .onChange(of: settings.previewTheme) { _, _ in refreshPreview() }
        .onChange(of: settings.codeTheme) { _, _ in refreshPreview() }
        .onChange(of: colorScheme) { _, _ in refreshPreview() }
        .navigationBarBackButtonHidden(editor.isDirty)
        .toolbar {
            if editor.isDirty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showUnsavedAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                    }
                }
            }
        }
        .alert("修改尚未保存", isPresented: $showUnsavedAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("放弃修改", role: .destructive) {
                editor.discardChanges()
                editorText = editor.text
                dismiss()
            }
            Button("保存并退出") {
                editor.save()
                dismiss()
            }
        } message: {
            Text("你可以保存到文件，或放弃本次修改。")
        }
    }

    private var editPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(editor.fileURL?.lastPathComponent ?? "未选择文件")
                    .font(.headline)
                    .lineLimit(1)
                Text(saveStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let lastSavedAt = editor.lastSavedAt {
                    Text(lastSavedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    markdownButton("标题") { insertMarkup("# ") }
                    markdownButton("粗体") { insertMarkup("****", cursorOffset: 2) }
                    markdownButton("链接") { insertMarkup("[](url)", cursorOffset: 1) }
                    markdownButton("代码块") { insertMarkup("\n```\n\n```\n", cursorOffset: 5) }
                    markdownButton("列表") { insertMarkup("- ") }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            TextEditor(text: Binding(
                get: { editorText },
                set: {
                    editorText = $0
                    editor.updateText($0)
                }
            ))
            .font(.system(.body, design: .monospaced))
            .padding(4)
        }
    }

    private var previewPane: some View {
        PreviewView(html: editor.html, baseURL: editor.fileURL?.deletingLastPathComponent())
    }

    private func shareMarkdown() {
        if let fileURL = editor.fileURL, !editor.isDirty {
            shareURL = fileURL
            showShareSheet = true
            return
        }

        let filename = editor.fileURL?.deletingPathExtension().lastPathComponent ?? "Markdown"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("md")
        do {
            try editor.text.write(to: url, atomically: true, encoding: .utf8)
            shareURL = url
            showShareSheet = true
        } catch {
            editor.errorMessage = "Markdown 分享失败: \(error.localizedDescription)"
        }
    }

    private func exportHTML() {
        refreshPreview()
        let filename = editor.fileURL?.deletingPathExtension().lastPathComponent ?? "export"
        if let url = HTMLExporter.shared.export(html: editor.html, filename: filename) {
            shareURL = url
            showShareSheet = true
        }
    }

    private func exportPDF() {
        refreshPreview()
        isExportingPDF = true
        PDFExporter.shared.export(html: editor.html) { result in
            DispatchQueue.main.async {
                isExportingPDF = false
                switch result {
                case .success(let data):
                    let filename = editor.fileURL?.deletingPathExtension().lastPathComponent ?? "export"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename).appendingPathExtension("pdf")
                    try? data.write(to: url)
                    shareURL = url
                    showShareSheet = true
                case .failure(let error):
                    editor.errorMessage = "PDF 导出失败: \(error.localizedDescription)"
                }
            }
        }
    }

    private var saveStatusText: String {
        if editor.isSaving { return "正在保存…" }
        if editor.isDirty { return "未保存" }
        return "已保存"
    }

    private func markdownButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }

    private func insertMarkup(_ markup: String, cursorOffset: Int? = nil) {
        let updated = editorText + markup
        editorText = updated
        editor.updateText(updated)
    }

    private func refreshPreview() {
        editorText = editor.text
        editor.updatePreview(text: editor.text, previewTheme: effectivePreviewTheme, codeTheme: settings.codeTheme)
    }
}
