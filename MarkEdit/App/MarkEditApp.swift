import SwiftUI

@main
struct MarkEditApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var previewSettings = PreviewSettings()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                MainView()
                    .environmentObject(appState)
                    .environmentObject(previewSettings)
                    .onOpenURL { url in
                        appState.open(url: url)
                    }
            }
        }
    }
}
