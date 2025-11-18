import SwiftUI

struct SettingsView: View {
    @ObservedObject var notionService: NotionService
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case apiKey
        case databaseId
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 48) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Connect to Notion")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Follow these steps to set up your integration")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)

                    // Step 1: Create Integration
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Integration")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Set up a new Notion integration to access your database")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Link(destination: URL(string: "https://www.notion.so/my-integrations")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    Text("notion.so/my-integrations")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                StepText("Click \"+ New integration\"")
                                StepText("Name it (e.g., \"NotionGraph\")")
                                StepText("Select your workspace")
                                StepText("Copy the \"Internal Integration Secret\"")
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Integration Secret")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            SecureField("", text: $notionService.apiKey, prompt: Text("secret_..."))
                                .textContentType(.password)
                                .focused($focusedField, equals: .apiKey)
                            #if os(iOS)
                                .padding(12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            #else
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            #endif
                                .onChange(of: notionService.apiKey) { oldValue, newValue in
                                    notionService.apiKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                        }
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                    // Step 2: Get Database ID
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Get Database ID")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Locate and copy your database identifier")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                StepText("Open your database in Notion")
                                StepText("Click \"Share\" or ⋯ menu")
                                StepText("Copy the database link")
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Database URL or ID")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("", text: $notionService.databaseId, prompt: Text("https://notion.so/..."))
                                .focused($focusedField, equals: .databaseId)
                            #if os(iOS)
                                .padding(12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            #else
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            #endif
                                .onChange(of: notionService.databaseId) { oldValue, newValue in
                                    notionService.databaseId = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                        }
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                    // Step 3: Share Database
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share Database")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Grant your integration access to the database")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                StepText("Go to your database in Notion")
                                StepText("Click ⋯ menu in the top right")
                                StepText("Select \"Add connections\"")
                                StepText("Choose your integration")
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirmation")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Click \"Done\" above once you've completed this step")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            #else
            .toolbarBackground(.hidden, for: .windowToolbar)
            #endif
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

// Helper view for step text with bullet points
struct StepText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
