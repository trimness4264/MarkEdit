import Foundation
import WebKit

class PDFExporter: NSObject, ObservableObject {
    static let shared = PDFExporter()

    private var webView: WKWebView?
    private var completion: ((Result<Data, Error>) -> Void)?

    func export(html: String, completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 792), configuration: config)
        webView.navigationDelegate = self
        self.webView = webView

        webView.loadHTMLString(html, baseURL: nil)
    }
}

extension PDFExporter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") { [weak self] value, error in
            guard let self else { return }
            if let error {
                self.completion?(.failure(error))
                self.webView = nil
                self.completion = nil
                return
            }

            let height = max((value as? CGFloat) ?? 792, 792)
            webView.frame = CGRect(x: 0, y: 0, width: 612, height: height)

            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: 612, height: height)

            webView.createPDF(configuration: config) { [weak self] result in
                self?.completion?(result)
                self?.webView = nil
                self?.completion = nil
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(error))
        self.webView = nil
        self.completion = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        completion?(.failure(error))
        self.webView = nil
        self.completion = nil
    }
}
