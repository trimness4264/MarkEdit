import Foundation
import Down

struct MarkdownRenderer {
    static let shared = MarkdownRenderer()

    func renderHTML(from markdown: String) -> String {
        let down = Down(markdownString: markdown)
        do {
            return try down.toHTML()
        } catch {
            return "<p>Markdown 解析失败: \(error.localizedDescription)</p>"
        }
    }
}
