import Foundation
import SwiftUI

enum PreviewTheme: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
}

enum CodeTheme: String, CaseIterable, Identifiable {
    case github, githubDark, atomOneDark
    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .github: return "github.min"
        case .githubDark: return "github-dark.min"
        case .atomOneDark: return "atom-one-dark.min"
        }
    }

    var displayName: String {
        switch self {
        case .github: return "GitHub"
        case .githubDark: return "GitHub Dark"
        case .atomOneDark: return "Atom One Dark"
        }
    }
}

class PreviewSettings: ObservableObject {
    @Published var previewTheme: PreviewTheme = .system
    @Published var codeTheme: CodeTheme = .github
}
