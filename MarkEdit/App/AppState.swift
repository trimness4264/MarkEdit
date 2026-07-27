import Foundation

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var pendingURL: URL?

    func open(url: URL) {
        pendingURL = url
    }
}
