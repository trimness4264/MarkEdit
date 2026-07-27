import SwiftUI

struct SettingsToolbarView: View {
    @Binding var showPreview: Bool
    @EnvironmentObject private var settings: PreviewSettings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var canSave: Bool
    var onSave: () -> Void
    var onShareMarkdown: () -> Void
    var onExportHTML: () -> Void
    var onExportPDF: () -> Void

    var body: some View {
        HStack {
            if horizontalSizeClass == .regular {
                Toggle("预览", isOn: $showPreview)
                    .toggleStyle(.button)
                    .fixedSize()
                regularControls
            } else {
                compactControls
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial)
    }

    // iPad / 大屏：全部展开
    private var regularControls: some View {
        HStack {
            Picker("主题", selection: $settings.previewTheme) {
                ForEach(PreviewTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()

            Picker("代码主题", selection: $settings.codeTheme) {
                ForEach(CodeTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Spacer()
            saveButton
            exportMenu
        }
    }

    // iPhone：折叠进菜单
    private var compactControls: some View {
        HStack {
            Spacer()

            Menu {
                Section("预览主题") {
                    ForEach(PreviewTheme.allCases) { theme in
                        Button {
                            settings.previewTheme = theme
                        } label: {
                            Label(theme.displayName, systemImage: settings.previewTheme == theme ? "checkmark" : "")
                        }
                    }
                }

                Section("代码主题") {
                    ForEach(CodeTheme.allCases) { theme in
                        Button {
                            settings.codeTheme = theme
                        } label: {
                            Label(theme.displayName, systemImage: settings.codeTheme == theme ? "checkmark" : "")
                        }
                    }
                }
            } label: {
                Label(settings.previewTheme.displayName, systemImage: "paintpalette")
                    .font(.headline)
                    .frame(minWidth: 88, minHeight: 44)
                    .contentShape(Rectangle())
            }

            saveButton
            exportMenu
        }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            Label("保存", systemImage: "checkmark.circle")
                .font(.headline)
                .frame(minWidth: 72, minHeight: 44)
                .contentShape(Rectangle())
        }
        .disabled(!canSave)
    }

    private var exportMenu: some View {
        Menu {
            Button(action: onShareMarkdown) {
                Label("分享 Markdown", systemImage: "doc.text")
            }
            Button(action: onExportHTML) {
                Label("导出 HTML", systemImage: "doc.html")
            }
            Button(action: onExportPDF) {
                Label("导出 PDF", systemImage: "doc.pdf")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
