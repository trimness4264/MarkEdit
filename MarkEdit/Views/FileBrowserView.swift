import SwiftUI
import UIKit

struct FileBrowserView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    var onSelectFile: (FileItem) -> Void
    var onSelectFolder: () -> Void
    var onCreateFile: () -> Void
    var onRenameFile: (FileItem) -> Void
    @State private var openedSwipeRowID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                primaryActions
                recentFilesSection
                currentDirectorySection
            }
            .padding(20)
            .contentShape(Rectangle())
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture(perform: dismissTransientState)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .searchable(text: $viewModel.searchText, prompt: "搜索文件")
        .toolbar(.hidden, for: .navigationBar)
        .alert("错误", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text("MarkEdit")
                .font(.largeTitle.bold())

            Spacer()

            Button {
                if openedSwipeRowID != nil {
                    dismissTransientState()
                } else {
                    viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.top, 8)
    }

    private var primaryActions: some View {
        HStack(spacing: 12) {
            Button {
                if openedSwipeRowID != nil {
                    dismissTransientState()
                } else {
                    onSelectFolder()
                }
            } label: {
                Label("打开文件", systemImage: "folder")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))

            Button {
                if openedSwipeRowID != nil {
                    dismissTransientState()
                } else {
                    onCreateFile()
                }
            } label: {
                Label("新建 MD", systemImage: "doc.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        }
    }

    @ViewBuilder
    private var recentFilesSection: some View {
        if !viewModel.filteredRecentFiles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("最近打开")
                    .font(.title3.bold())

                fileList(viewModel.filteredRecentFiles) { item in
                    viewModel.removeRecentFile(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var currentDirectorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当前目录")
                    .font(.title3.bold())

                Spacer()

                Button("更换") {
                    if openedSwipeRowID != nil {
                        openedSwipeRowID = nil
                    } else {
                        onSelectFolder()
                    }
                }
                .font(.subheadline)
            }

            VStack(spacing: 0) {
                if viewModel.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("正在加载文件…")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                } else if viewModel.filteredItems.isEmpty {
                    Text(viewModel.searchText.isEmpty ? "当前目录没有 Markdown 文件" : "没有匹配的文件")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            SwipeToDeleteRow(
                                id: item.id,
                                openedRowID: $openedSwipeRowID,
                                onDelete: { viewModel.delete(item: item) },
                                onRename: { onRenameFile(item) },
                                onTap: { open(item) }
                            ) {
                                fileRow(item)
                            }
                            if index < viewModel.filteredItems.count - 1 {
                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fileList(_ items: [FileItem], onDelete: @escaping (FileItem) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    SwipeToDeleteRow(
                        id: item.id,
                        openedRowID: $openedSwipeRowID,
                        onDelete: { onDelete(item) },
                        onRename: { onRenameFile(item) },
                        onTap: { open(item) }
                    ) {
                        fileRow(item)
                    }
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func open(_ item: FileItem) {
        viewModel.selectedFile = item
        if item.isDirectory {
            dismissTransientState()
            viewModel.selectFolder(item.url)
        } else {
            dismissTransientState()
            onSelectFile(item)
        }
    }

    private func dismissTransientState() {
        openedSwipeRowID = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func fileRow(_ item: FileItem) -> some View {
        FileRowView(item: item)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
    }
}

private struct SwipeToDeleteRow<Content: View>: View {
    let id: UUID
    @Binding var openedRowID: UUID?
    let onDelete: () -> Void
    let onRename: () -> Void
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Button(action: onRename) {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                            .font(.headline)
                        Text("重命名")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 88)
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                }

                Button(role: .destructive, action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.headline)
                        Text("删除")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }

            content()
                .background(Color(.secondarySystemGroupedBackground))
                .offset(x: offset)
                .onTapGesture {
                    if openedRowID != nil {
                        openedRowID = nil
                    } else if !isDragging {
                        onTap()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height), value.translation.width < 0 else { return }
                            isDragging = true
                            openedRowID = id
                            offset = min(0, max(value.translation.width, -160))
                        }
                        .onEnded { value in
                            defer { isDragging = false }
                            guard abs(value.translation.width) > abs(value.translation.height) else {
                                offset = 0
                                return
                            }
                            if value.translation.width < -80 {
                                offset = -160
                                openedRowID = id
                            } else {
                                offset = 0
                                openedRowID = nil
                            }
                        }
                )
        }
        .clipped()
        .onChange(of: openedRowID) { _, newValue in
            if newValue != id {
                offset = 0
            }
        }
    }
}
