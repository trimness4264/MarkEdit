import SwiftUI
import WebKit

struct PreviewWebView: UIViewRepresentable {
    let html: String
    let baseURL: URL?
    @EnvironmentObject private var settings: PreviewSettings
    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = true
        context.coordinator.webView = webView

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedHTML != html {
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Preview", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            let htmlURL = tempDirectory.appendingPathComponent("preview.html")
            try? html.write(to: htmlURL, atomically: true, encoding: .utf8)
            let accessURL = baseURL?.deletingLastPathComponent() ?? tempDirectory
            uiView.loadFileURL(htmlURL, allowingReadAccessTo: accessURL)
            context.coordinator.lastLoadedHTML = html
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastLoadedHTML: String?
    }
}
