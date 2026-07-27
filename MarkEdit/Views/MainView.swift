import SwiftUI

struct MainView: View {
    @StateObject private var fileBrowser = FileBrowserViewModel()
    @StateObject private var editor = EditorViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showFolderPicker = false
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
                    editor.save()
                    editor.openFile(at: item.url)
                    fileBrowser.recordOpenedFile(item.url)
                    isEditing = true
                },
                onSelectFolder: { showFolderPicker = true },
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
            .sheet(isPresented: $showFolderPicker) {
                DocumentPicker(forDirectory: true) { url in
                    fileBrowser.selectFolder(url)
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
                        editor.openFile(at: item.url)
                        fileBrowser.recordOpenedFile(item.url)
                        isEditing = true
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
        .onChange(of: appState.pendingURL) { _, url in
            guard let url = url else { return }
            editor.openFile(at: url)
            fileBrowser.recordOpenedFile(url)
            isEditing = true
            appState.pendingURL = nil
        }
        .onAppear {
            if editor.fileURL == nil,
               let firstFile = fileBrowser.items.first(where: { !$0.isDirectory }) {
                editor.openFile(at: firstFile.url)
            }
        }
    }
}
