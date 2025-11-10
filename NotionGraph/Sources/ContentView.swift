import SwiftUI

struct ContentView: View {
    @StateObject private var notionService = NotionService()
    @State private var showingSettings = false

    var body: some View {
        #if os(iOS)
        ZStack(alignment: .topTrailing) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)

            if notionService.isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your graph...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                // Show error page only for actual connection errors
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.orange)

                        VStack(spacing: 8) {
                            Text("Connection Error")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Button {
                            Task {
                                await notionService.fetchDatabase()
                            }
                        } label: {
                            Text("Try Again")
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
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await notionService.fetchDatabase()
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
            await notionService.fetchDatabase()
        }
        #else
        NavigationStack {
            VStack {
                if notionService.isLoading {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading your graph...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    // Show error page only for actual connection errors
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 56, weight: .light))
                                .foregroundColor(.orange)

                            VStack(spacing: 8) {
                                Text("Connection Error")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }

                            Button {
                                Task {
                                    await notionService.fetchDatabase()
                                }
                            } label: {
                                Text("Try Again")
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
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
