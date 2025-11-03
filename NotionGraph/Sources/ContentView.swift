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
