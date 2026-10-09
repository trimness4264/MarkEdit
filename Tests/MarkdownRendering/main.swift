import Foundation
import JavaScriptCore

let appPath = CommandLine.arguments[1]
guard let bundle = Bundle(path: appPath) else { fatalError("Cannot open app bundle: \(appPath)") }
let renderer = MarkdownRenderer(bundle: bundle)
var assertions = 0

func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    assertions += 1
    guard condition() else { fatalError("FAIL: \(name)") }
}

let table = renderer.renderHTML(from: """
| 左 | 中 | 右 |
| :--- | :---: | ---: |
| **粗体** | `a\u{005c}|b` | [链接](https://example.com) |
| 中文 | a\u{005c}|b | ~~旧值~~ |
""")
check(table.contains("<table>"), "pipe table is parsed")
check(table.contains("class=\"table-scroll\""), "table has a scroll container")
check(table.contains("align=\"center\""), "center alignment")
check(table.contains("align=\"right\""), "right alignment")
check(table.contains("<strong>粗体</strong>"), "formatting inside cells")
check(table.contains("<code>a|b</code>"), "escaped pipe inside code cell")
check(table.contains("<td align=\"center\">a|b</td>"), "escaped pipe does not split a cell")
check(table.contains("<del>旧值</del>"), "strikethrough")
check(table.components(separatedBy: "<td").count == 7, "table column count")
check(renderer.renderHTML(from: "甲 | 乙\n--- | ---\n一 | 二").contains("<table>"), "table without outer pipes")
check(!renderer.renderHTML(from: "甲 | 乙\n正文 | 内容").contains("<table>"), "ordinary pipes stay text")

let tasks = renderer.renderHTML(from: """
- [ ] 待办
- [x] 完成
  - [X] 嵌套任务
- 普通项目

- [ ] 多段落任务

  第二段
""")
check(tasks.components(separatedBy: "type=\"checkbox\"").count == 5, "task checkboxes, including nested and loose items")
check(tasks.components(separatedBy: "checked=\"\"").count == 3, "checked task state")
check(tasks.contains("disabled=\"\""), "preview checkboxes are read only")
check(tasks.contains("普通项目"), "regular list item preserved")

let blocks = renderer.renderHTML(from: """
# 标题

> 引用
>
> | 项目 | 状态 |
> | --- | --- |
> | 表格 | 正常 |

3. 第三项
   - 嵌套项目

---

```swift
let value = "<tag>"
| a | b |
| --- | --- |
- [x] 示例
~~原样~~
```

    <indented>

行内 `~~原样~~`，正文 ~~删除~~。
""")
check(blocks.contains("<h1>标题</h1>"), "heading")
check(blocks.contains("<blockquote>"), "blockquote")
check(blocks.contains("<table>"), "nested table")
check(blocks.contains("<ol start=\"3\">"), "ordered list starting number")
check(blocks.contains("<hr>"), "thematic break")
check(blocks.contains("class=\"language-swift\""), "code language")
check(blocks.contains("&lt;tag&gt;"), "code HTML is escaped")
check(blocks.contains("| --- | --- |\n- [x] 示例\n~~原样~~"), "fenced code remains literal")
check(blocks.contains("&lt;indented&gt;"), "indented code")
check(blocks.contains("<code>~~原样~~</code>"), "inline code remains literal")
check(blocks.contains("<del>删除</del>"), "inline deletion outside code")

let links = renderer.renderHTML(from: "https://example.com\n\n[bad](javascript:alert%281%29)\n\n[bad](java&#x73;cript:alert%281%29)\n\n<script>alert(1)</script>")
check(links.contains("href=\"https://example.com\""), "GFM bare URL")
check(!links.contains("href=\"javascript:"), "unsafe link blocked")
check(!links.contains("href=\"java&#x73;cript:"), "entity-obfuscated unsafe link blocked")
check(!links.contains("<script>"), "raw HTML stays disabled")
check(renderer.renderHTML(from: "").isEmpty, "empty document")
check(renderer.renderHTML(from: "引号 ' \" 和反斜线 \\，中文 😀").contains("中文 😀"), "document is passed as data to JavaScriptCore")

let samples = URL(fileURLWithPath: "SampleDocuments", isDirectory: true)
for url in try FileManager.default.contentsOfDirectory(at: samples, includingPropertiesForKeys: nil)
    .filter({ $0.pathExtension == "md" }) {
    let html = renderer.renderHTML(from: try String(contentsOf: url, encoding: .utf8))
    check(!html.contains("Markdown 解析"), "sample \(url.lastPathComponent)")
    if url.lastPathComponent.hasPrefix("08-") {
        check(html.contains("<table>"), "existing imported table sample")
    }
}
print("PASS: \(assertions) Markdown rendering checks in JavaScriptCore")

// A standalone page for checking the same packaged CSS at phone and tablet widths.
let sample = try String(contentsOf: samples.appendingPathComponent("21-功能块回归测试.md"), encoding: .utf8)
let css = try String(contentsOf: bundle.url(forResource: "markdown", withExtension: "css")!, encoding: .utf8)
let printCSS = try String(contentsOf: bundle.url(forResource: "print", withExtension: "css")!, encoding: .utf8)
let page = """
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<style>\(css)</style><style>\(printCSS)</style></head><body><div class="markdown-body">\(renderer.renderHTML(from: sample))</div></body></html>
"""
try page.write(toFile: ".build/MarkdownRendering/preview.html", atomically: true, encoding: .utf8)
