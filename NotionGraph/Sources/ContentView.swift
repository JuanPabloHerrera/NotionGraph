import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var notionService = NotionService()
    @State private var showingSettings = false

    // SwiftData and network monitoring
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    var body: some View {
        #if os(iOS)
        ZStack(alignment: .topTrailing) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)

            if notionService.isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("\(Int(notionService.loadingProgress * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray.opacity(0.6))

                        // Progress bar with actual progress
                        ProgressView(value: notionService.loadingProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if notionService.apiKey.isEmpty || notionService.databaseId.isEmpty {
                // Show welcome page if credentials are not configured
                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "circle.dotted")
                                .font(.system(size: 64, weight: .thin))
                                .foregroundColor(.gray)

                            VStack(spacing: 6) {
                                Text("Welcome to NotionGraph")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Add your Notion API and Database ID")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape")
                                Text("Configure Settings")
                            }
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let error = notionService.error {
                // Show error page
                VStack {
                    Spacer()
                    Button {
                        Task {
                            await notionService.loadGraphData()
                        }
                    } label: {
                        Text("Open Graph")
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if notionService.nodes.isEmpty {
                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "circle.dotted")
                                .font(.system(size: 64, weight: .thin))
                                .foregroundColor(.gray)

                            VStack(spacing: 6) {
                                Text("Welcome to NotionGraph")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Add your Notion API and Database ID")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape")
                                Text("Configure Settings")
                            }
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                KnowledgeGraphView(nodes: notionService.nodes, links: notionService.links)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Floating buttons overlay - always on top
            VStack {
                HStack {
                    // Status badge on the left
                    if !notionService.nodes.isEmpty {
                        StatusBadge(
                            isOffline: notionService.isOfflineMode,
                            lastSyncDate: notionService.lastSyncDate,
                            isConnected: networkMonitor.isConnected,
                            isSyncingInBackground: notionService.isSyncingInBackground
                        )
                        .padding(.top, 60)
                        .padding(.leading, 16)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await notionService.loadGraphData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(notionService.isLoading)

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingSettings) {
            SettingsView(notionService: notionService)
        }
        .task {
            // Inject services
            if notionService.cacheService == nil {
                notionService.cacheService = CacheService(modelContainer: modelContext.container)
                notionService.networkMonitor = networkMonitor
            }
            await notionService.loadGraphData()
        }
        #else
        NavigationStack {
            VStack {
                if notionService.isLoading {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("\(Int(notionService.loadingProgress * 100))%")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray.opacity(0.6))

                            // Progress bar with actual progress
                            ProgressView(value: notionService.loadingProgress, total: 1.0)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                        }
                        Spacer()
                    }
                } else if notionService.apiKey.isEmpty || notionService.databaseId.isEmpty {
                    // Show welcome page if credentials are not configured
                    VStack {
                        Spacer()

                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 64, weight: .thin))
                                    .foregroundColor(.gray)

                                VStack(spacing: 6) {
                                    Text("Welcome to NotionGraph")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("Add your Notion API and Database ID")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                            }

                            Button {
                                showingSettings = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape")
                                    Text("Configure Settings")
                                }
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if let error = notionService.error {
                    // Show error page
                    VStack {
                        Spacer()
                        Button {
                            Task {
                                await notionService.loadGraphData()
                            }
                        } label: {
                            Text("Open Graph")
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                } else if notionService.nodes.isEmpty {
                    VStack {
                        Spacer()

                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                Image(systemName: "circle.dotted")
                                    .font(.system(size: 64, weight: .thin))
                                    .foregroundColor(.gray)

                                VStack(spacing: 6) {
                                    Text("Welcome to NotionGraph")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("Add your Notion API and Database ID")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                            }

                            Button {
                                showingSettings = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape")
                                    Text("Configure Settings")
                                }
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()

                        Spacer()
                    }
                } else {
                    KnowledgeGraphView(nodes: notionService.nodes, links: notionService.links)
                }
            }
            .navigationTitle("Notion Knowledge Graph")
            .navigationSubtitle("")
            .toolbarBackground(Color(hex: "#fafafa"), for: .windowToolbar)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if !notionService.nodes.isEmpty {
                        StatusBadge(
                            isOffline: notionService.isOfflineMode,
                            lastSyncDate: notionService.lastSyncDate,
                            isConnected: networkMonitor.isConnected,
                            isSyncingInBackground: notionService.isSyncingInBackground
                        )
                    }
                }
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
                            await notionService.loadGraphData()
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
            // Inject services
            if notionService.cacheService == nil {
                notionService.cacheService = CacheService(modelContainer: modelContext.container)
                notionService.networkMonitor = networkMonitor
            }
            await notionService.loadGraphData()
        }
        #endif
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
