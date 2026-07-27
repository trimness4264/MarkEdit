import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var previewTheme: PreviewTheme = .system
    @Published var codeTheme: CodeTheme = .github

    var currentCodeThemePath: String {
        codeTheme.fileName + ".css"
    }

    var markdownCSS: String {
        resource(named: "markdown", extension: "css")
    }

    var printCSS: String {
        resource(named: "print", extension: "css")
    }

    var highlightJS: String {
        resource(named: "highlight.min", extension: "js")
    }

    func css(for codeTheme: CodeTheme) -> String {
        resource(named: codeTheme.fileName, extension: "css")
    }

    private func resource(named name: String, extension ext: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let content = try? String(contentsOf: url) else {
            return ""
        }
        return content
    }

    func effectiveTheme(for colorScheme: ColorScheme) -> PreviewTheme {
        if previewTheme == .system {
            return colorScheme == .dark ? .dark : .light
        }
        return previewTheme
    }
}
