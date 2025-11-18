import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var notionService = NotionService()
    @State private var showingSettings = false

    // Local graph state
    @State private var isLocalGraphMode = false
    @State private var localGraphCenterNodeId: String?

    // SwiftData and network monitoring
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    // Computed property for filtered nodes and links based on local graph mode
    private var displayNodes: [GraphNode] {
        guard isLocalGraphMode, let centerNodeId = localGraphCenterNodeId else {
            return notionService.nodes
        }
        return filterNodesToDepth(centerNodeId: centerNodeId, maxDepth: 2)
    }

    private var displayLinks: [GraphLink] {
        guard isLocalGraphMode, let centerNodeId = localGraphCenterNodeId else {
            return notionService.links
        }
        let nodeIds = Set(displayNodes.map { $0.id })
        return notionService.links.filter { link in
            nodeIds.contains(link.source) && nodeIds.contains(link.target)
        }
    }

    // Filter nodes to a specific depth from a center node using BFS
    private func filterNodesToDepth(centerNodeId: String, maxDepth: Int) -> [GraphNode] {
        var visitedNodes = Set<String>()
        var nodesToVisit: [(id: String, depth: Int)] = [(centerNodeId, 0)]
        var currentIndex = 0

        // BFS to find all nodes within maxDepth
        while currentIndex < nodesToVisit.count {
            let (currentId, currentDepth) = nodesToVisit[currentIndex]
            currentIndex += 1

            if visitedNodes.contains(currentId) || currentDepth > maxDepth {
                continue
            }

            visitedNodes.insert(currentId)

            if currentDepth < maxDepth {
                // Find all connected nodes
                for link in notionService.links {
                    if link.source == currentId && !visitedNodes.contains(link.target) {
                        nodesToVisit.append((link.target, currentDepth + 1))
                    } else if link.target == currentId && !visitedNodes.contains(link.source) {
                        nodesToVisit.append((link.source, currentDepth + 1))
                    }
                }
            }
        }

        return notionService.nodes.filter { visitedNodes.contains($0.id) }
    }

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
                KnowledgeGraphView(
                    nodes: displayNodes,
                    links: displayLinks,
                    isLocalGraphMode: isLocalGraphMode,
                    centerNodeId: localGraphCenterNodeId,
                    onOpenLocalGraph: { nodeId in
                        localGraphCenterNodeId = nodeId
                        isLocalGraphMode = true
                    },
                    onReturnToFullGraph: {
                        isLocalGraphMode = false
                        localGraphCenterNodeId = nil
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Floating buttons overlay - always on top
            VStack {
                HStack {
                    Spacer()

                    HStack(spacing: 12) {
                        // Only show back button in local graph mode
                        if isLocalGraphMode {
                            Button {
                                // Return to full graph
                                isLocalGraphMode = false
                                localGraphCenterNodeId = nil
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }

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
                    KnowledgeGraphView(
                        nodes: displayNodes,
                        links: displayLinks,
                        isLocalGraphMode: isLocalGraphMode,
                        centerNodeId: localGraphCenterNodeId,
                        onOpenLocalGraph: { nodeId in
                            localGraphCenterNodeId = nodeId
                            isLocalGraphMode = true
                        },
                        onReturnToFullGraph: {
                            isLocalGraphMode = false
                            localGraphCenterNodeId = nil
                        }
                    )
                }
            }
            .navigationTitle("Notion Knowledge Graph")
            .navigationSubtitle("")
            .toolbarBackground(Color(hex: "#fafafa"), for: .windowToolbar)
            .toolbar {
                // Back button to the left of settings (only in local graph mode)
                if isLocalGraphMode {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            // Return to full graph
                            isLocalGraphMode = false
                            localGraphCenterNodeId = nil
                        } label: {
                            Image(systemName: "arrow.left")
                        }
                    }
                }
                // Settings button - rightmost position
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
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
