import Foundation

struct HTMLRenderer {
    static let shared = HTMLRenderer()

    func renderFullHTML(bodyHTML: String, previewTheme: PreviewTheme = .light, codeTheme: CodeTheme = .github) -> String {
        let themeManager = ThemeManager.shared
        let css = themeManager.markdownCSS
        let codeCSS = themeManager.css(for: codeTheme)
        let highlightJS = themeManager.highlightJS

        return """
        <!DOCTYPE html>
        <html data-theme="\(previewTheme.rawValue)">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>\(css)</style>
            <style id="code-theme">\(codeCSS)</style>
            <style>\(themeManager.printCSS)</style>
        </head>
        <body>
            <div class="markdown-body">\(bodyHTML)</div>
            <script>\(highlightJS)</script>
            <script>
                function highlightCode() {
                    if (window.hljs) { window.hljs.highlightAll(); }
                }
                document.addEventListener('DOMContentLoaded', highlightCode);
                function setTheme(name) {
                    document.documentElement.setAttribute('data-theme', name);
                }
                function setCodeTheme(css) {
                    var style = document.getElementById('code-theme');
                    if (style) {
                        style.textContent = css;
                        setTimeout(highlightCode, 100);
                    }
                }
            </script>
        </body>
        </html>
        """
    }
}
