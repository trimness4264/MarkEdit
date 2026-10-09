import Foundation
import JavaScriptCore

final class MarkdownRenderer {
    static let shared = MarkdownRenderer()
    private let lock = NSLock()
    private let context: JSContext?

    init(bundle: Bundle = .main) {
        guard let context = JSContext(),
              let parserURL = bundle.url(forResource: "marked", withExtension: "js"),
              let configurationURL = bundle.url(forResource: "markdown-parser", withExtension: "js"),
              let parser = try? String(contentsOf: parserURL, encoding: .utf8),
              let configuration = try? String(contentsOf: configurationURL, encoding: .utf8) else {
            self.context = nil
            return
        }
        context.evaluateScript(parser)
        context.evaluateScript(configuration)
        self.context = context.exception == nil ? context : nil
    }

    func renderHTML(from markdown: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        guard let context else {
            return "<p>Markdown 解析器加载失败。</p>"
        }
        context.exception = nil
        // Pass the document as a value, never interpolate it into executable JavaScript.
        let result = context.objectForKeyedSubscript("renderMarkdown")?.call(withArguments: [markdown])
        guard context.exception == nil, let result, result.isString else {
            return "<p>Markdown 解析失败。</p>"
        }
        return result.toString()
    }
}
