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

                    TextField("Database ID", text: $notionService.databaseId)
                    #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                    #endif
                } header: {
                    Text("Notion Configuration")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To get your Notion API key:")
                        Text("1. Go to notion.so/my-integrations")
                        Text("2. Create a new integration")
                        Text("3. Copy the Internal Integration Token")
                        Text("\nTo get your Database ID:")
                        Text("Open your database in Notion and copy the ID from the URL:")
                        Text("notion.so/[workspace]/[DATABASE_ID]?v=...")
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
