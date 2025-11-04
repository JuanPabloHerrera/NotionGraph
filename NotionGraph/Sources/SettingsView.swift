import SwiftUI

struct SettingsView: View {
    @ObservedObject var notionService: NotionService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Notion API Key", text: $notionService.apiKey)
                        .textContentType(.password)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                        .onChange(of: notionService.apiKey) { oldValue, newValue in
                            notionService.apiKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }

                    TextField("Database ID", text: $notionService.databaseId)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                        .onChange(of: notionService.databaseId) { oldValue, newValue in
                            notionService.databaseId = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                } header: {
                    Text("Notion Configuration")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To get your Notion API key:")
                        Text("1. Go to notion.so/my-integrations")
                        Text("2. Create a new integration")
                        Text("3. Copy the Internal Integration Token")
                        Text("\nTo get your Database ID:")
                        Text("1. Open your database in Notion")
                        Text("2. Copy the URL or just the database ID")
                        Text("   Example: notion.so/workspace/DATABASE_ID?v=...")
                        Text("3. You can paste the full URL or just the ID")
                        Text("\nDon't forget to share the database with your integration!")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Section {
                    Link("Notion API Documentation", destination: URL(string: "https://developers.notion.com")!)
                } header: {
                    Text("Resources")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
