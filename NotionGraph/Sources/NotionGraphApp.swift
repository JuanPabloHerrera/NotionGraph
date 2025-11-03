import SwiftUI

@main
struct NotionGraphApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
