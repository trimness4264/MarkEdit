import SwiftUI
import WebKit

struct PreviewWebView: UIViewRepresentable {
    let html: String
    let baseURL: URL?

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
        if context.coordinator.lastLoadedHTML != html || context.coordinator.lastBaseURL != baseURL {
            // The generated page lives in memory; its document directory only resolves relative URLs.
            // Loading a temporary HTML file with an unrelated read-access directory can show a blank page.
            uiView.loadHTMLString(html, baseURL: baseURL)
            context.coordinator.lastLoadedHTML = html
            context.coordinator.lastBaseURL = baseURL
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastLoadedHTML: String?
        var lastBaseURL: URL?
    }
}
