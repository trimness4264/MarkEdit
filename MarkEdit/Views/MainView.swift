import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var fileBrowser = FileBrowserViewModel()
    @StateObject private var editor = EditorViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showPicker = false
    @State private var pickDirectory = false
    @State private var showNewFileSheet = false
    @State private var newFileName = ""
    @State private var isEditing = false
    @State private var renameTarget: FileItem?
    @State private var renameFileName = ""

    var body: some View {
        NavigationStack {
            FileBrowserView(
                viewModel: fileBrowser,
                onSelectFile: { item in
                    openFile(item.url)
                },
                onOpenFile: {
                    pickDirectory = false
                    showPicker = true
                },
                onSelectFolder: {
                    pickDirectory = true
                    showPicker = true
                },
                onCreateFile: { showNewFileSheet = true },
                onRenameFile: { item in
                    renameTarget = item
                    renameFileName = item.url.deletingPathExtension().lastPathComponent
                }
            )
            .navigationDestination(isPresented: $isEditing) {
                EditorView(editor: editor)
                    .navigationTitle(editor.fileURL?.lastPathComponent ?? "编辑")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationTitle("文件")
            .fileImporter(
                isPresented: $showPicker,
                allowedContentTypes: pickDirectory ? [.folder] : DocumentPicker.markdownTypes
            ) { result in
                switch result {
                case .success(let url):
                    if pickDirectory {
                        fileBrowser.selectFolder(url)
                    } else {
                        openFile(url)
                    }
                case .failure(let error):
                    fileBrowser.errorMessage = "无法选择文件: \(error.localizedDescription)"
                }
            }
            .alert("新建文件", isPresented: $showNewFileSheet) {
                TextField("文件名", text: $newFileName)
                Button("取消", role: .cancel) {
                    newFileName = ""
                }
                Button("创建") {
                    fileBrowser.createNewFile(named: newFileName)
                    if let item = fileBrowser.selectedFile {
                        openFile(item.url)
                    }
                    newFileName = ""
                }
            } message: {
                Text("输入 Markdown 文件名")
            }
            .alert("重命名文件", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("文件名", text: $renameFileName)
                Button("取消", role: .cancel) {
                    renameTarget = nil
                    renameFileName = ""
                }
                Button("确定") {
                    if let item = renameTarget,
                       let url = fileBrowser.rename(item: item, to: renameFileName) {
                        if editor.fileURL == item.url {
                            editor.renameCurrentFile(to: url)
                        }
                    }
                    renameTarget = nil
                    renameFileName = ""
                }
            } message: {
                Text("输入新的 Markdown 文件名")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onChange(of: appState.pendingURL, initial: true) { _, url in
            guard let url = url else { return }
            openFile(url)
            appState.pendingURL = nil
        }
        .onAppear {
            if editor.fileURL == nil,
               let firstFile = fileBrowser.items.first(where: { !$0.isDirectory }) {
                editor.openFile(at: firstFile.url)
            }
        }
    }

    @discardableResult
    private func openFile(_ url: URL) -> Bool {
        if editor.isDirty {
            editor.save()
            guard !editor.isDirty else {
                fileBrowser.errorMessage = editor.errorMessage
                editor.errorMessage = nil
                return false
            }
        }
        guard editor.openFile(at: url) else {
            fileBrowser.errorMessage = editor.errorMessage
            editor.errorMessage = nil
            return false
        }
        fileBrowser.recordOpenedFile(url)
        isEditing = true
        return true
    }
}
