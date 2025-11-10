import SwiftUI

struct SettingsView: View {
    @ObservedObject var notionService: NotionService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Setup")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Connect your Notion database in 3 simple steps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)

                    // Step 1: Create Integration
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("1")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Create Notion Integration")
                                    .font(.headline)
                                Link(destination: URL(string: "https://www.notion.so/my-integrations")!) {
                                    HStack(spacing: 4) {
                                        Text("notion.so/my-integrations")
                                            .font(.subheadline)
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                    }
                                }
                                Text("• Click \"+ New integration\"\n• Give it a name\n• Copy the \"Internal Integration Secret\"")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }

                        SecureField("Paste your API key here", text: $notionService.apiKey)
                            .textContentType(.password)
                        #if os(iOS)
                            .padding(12)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(8)
                        #else
                            .textFieldStyle(.roundedBorder)
                        #endif
                            .onChange(of: notionService.apiKey) { oldValue, newValue in
                                notionService.apiKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                    }
                    .padding(16)
                    .background(Color(hex: "#fafafa"))
                    .cornerRadius(12)

                    // Step 2: Get Database ID
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("2")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Get Database ID")
                                    .font(.headline)
                                Text("• Open your database in Notion\n• Copy the page URL\n• Paste it below (we'll extract the ID)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }

                        TextField("Paste database URL or ID", text: $notionService.databaseId)
                        #if os(iOS)
                            .padding(12)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(8)
                        #else
                            .textFieldStyle(.roundedBorder)
                        #endif
                            .onChange(of: notionService.databaseId) { oldValue, newValue in
                                notionService.databaseId = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                    }
                    .padding(16)
                    .background(Color(hex: "#fafafa"))
                    .cornerRadius(12)

                    // Step 3: Share Database
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("3")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Share Database")
                                    .font(.headline)
                                Text("• Click \"⋯\" in your Notion database\n• Select \"Add connections\"\n• Choose your integration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "#fafafa"))
                    .cornerRadius(12)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
