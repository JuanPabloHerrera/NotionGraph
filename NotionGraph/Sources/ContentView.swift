import SwiftUI

struct ContentView: View {
    @StateObject private var notionService = NotionService()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                if notionService.isLoading {
                    ProgressView("Loading Notion database...")
                } else if let error = notionService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await notionService.fetchDatabase()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if notionService.nodes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No data")
                            .font(.headline)
                        Text("Configure your Notion API key and database ID in settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Settings") {
                            showingSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    KnowledgeGraphView(nodes: notionService.nodes, links: notionService.links)
                }
            }
            .navigationTitle("Notion Knowledge Graph")
            #if os(macOS)
            .navigationSubtitle("")
            .toolbarBackground(Color(hex: "#fafafa"), for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            await notionService.fetchDatabase()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(notionService.isLoading)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(notionService: notionService)
            }
        }
        .task {
            await notionService.fetchDatabase()
        }
    }
}

#Preview {
    ContentView()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
