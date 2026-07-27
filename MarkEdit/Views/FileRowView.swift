import SwiftUI

struct FileRowView: View {
    let item: FileItem

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            VStack(alignment: .leading) {
                Text(item.displayName)
                    .lineLimit(1)
                if !item.isDirectory {
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var iconName: String {
        if item.isDirectory {
            return "folder.fill"
        } else if item.isMarkdown {
            return "doc.text.fill"
        } else {
            return "doc.fill"
        }
    }

    private var iconColor: Color {
        if item.isDirectory {
            return .blue
        } else if item.isMarkdown {
            return .green
        } else {
            return .gray
        }
    }

    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: item.modificationDate, relativeTo: Date())
    }
}
