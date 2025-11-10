import SwiftUI
import SwiftData

@main
struct NotionGraphApp: App {
    // SwiftData model container
    let modelContainer: ModelContainer

    // Shared services
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        // Set up SwiftData model container
        do {
            modelContainer = try ModelContainer(
                for: CachedGraphNode.self, CachedGraphLink.self, SyncMetadata.self
            )
            print("✅ SwiftData container initialized")
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(networkMonitor)
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 400)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }
}
