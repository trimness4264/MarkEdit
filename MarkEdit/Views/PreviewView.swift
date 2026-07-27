import SwiftUI

struct PreviewView: View {
    let html: String
    let baseURL: URL?

    var body: some View {
        PreviewWebView(html: html, baseURL: baseURL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).ignoresSafeArea())
    }
}
