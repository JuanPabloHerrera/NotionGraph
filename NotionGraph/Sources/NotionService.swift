import Foundation
import SwiftUI

@MainActor
class NotionService: ObservableObject {
    @Published var nodes: [GraphNode] = []
    @Published var links: [GraphLink] = []
    @Published var isLoading = false
    @Published var error: String?

    @AppStorage("notionApiKey") var apiKey: String = ""
    @AppStorage("notionDatabaseId") var databaseId: String = ""

    private let baseURL = "https://api.notion.com/v1"
    private let notionVersion = "2022-06-28"

    func fetchDatabase() async {
        // Trim whitespace from credentials
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDatabaseId = databaseId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedApiKey.isEmpty, !trimmedDatabaseId.isEmpty else {
            error = "Please configure your Notion API key and database ID"
            return
        }

        isLoading = true
        error = nil

        do {
            // Normalize the database ID by removing dashes and ensuring proper format
            let normalizedId = normalizeDatabaseId(trimmedDatabaseId)

            guard let url = URL(string: "\(baseURL)/databases/\(normalizedId)/query") else {
                throw NotionError.apiError(statusCode: 400, message: "Invalid database ID format")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(trimmedApiKey)", forHTTPHeaderField: "Authorization")
            request.addValue(notionVersion, forHTTPHeaderField: "Notion-Version")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            // Empty body for now, but can be extended for filtering
            request.httpBody = try JSONEncoder().encode(["page_size": 100])

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NotionError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw NotionError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
                throw NotionError.apiError(statusCode: httpResponse.statusCode, message: "Unknown error")
            }

            let database = try JSONDecoder().decode(NotionDatabase.self, from: data)

            print("✅ Fetched \(database.results.count) pages from database")

            // Fetch content blocks for each page to find page mentions
            await fetchPageContent(for: database.results)

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchPageContent(for pages: [NotionPage]) async {
        var allMentions: [(sourceId: String, targetId: String)] = []
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        print("📝 Fetching page content for \(pages.count) pages to find mentions...")

        // Fetch blocks for each page to find page mentions
        for page in pages {
            do {
                let url = URL(string: "\(baseURL)/blocks/\(page.id)/children")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("Bearer \(trimmedApiKey)", forHTTPHeaderField: "Authorization")
                request.addValue(notionVersion, forHTTPHeaderField: "Notion-Version")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("⚠️ Failed to fetch blocks for page '\(page.title)' - status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    continue
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    print("📄 Page '\(page.title)' has \(results.count) blocks")
                    for block in results {
                        // Extract page mentions from block content
                        let mentions = extractPageMentions(from: block)
                        if !mentions.isEmpty {
                            print("🔗 Found \(mentions.count) page mention(s) in '\(page.title)'")
                        }
                        for mentionId in mentions {
                            allMentions.append((sourceId: page.id, targetId: mentionId))
                        }
                    }
                }
            } catch {
                print("❌ Error fetching blocks for page \(page.title): \(error)")
            }
        }

        print("✅ Total page mentions found: \(allMentions.count)")
        for mention in allMentions {
            print("   🔗 \(mention.sourceId) → \(mention.targetId)")
        }

        processPages(pages, mentions: allMentions)
    }

    private func extractPageMentions(from block: [String: Any]) -> [String] {
        var mentions: [String] = []
        let blockType = block["type"] as? String ?? "unknown"

        // Function to recursively search for mentions in rich text
        func searchRichText(_ richTextArray: [[String: Any]]) {
            for item in richTextArray {
                if let mention = item["mention"] as? [String: Any],
                   let type = mention["type"] as? String,
                   type == "page",
                   let page = mention["page"] as? [String: Any],
                   let id = page["id"] as? String {
                    mentions.append(id)
                    print("   🔗 Found page mention in \(blockType) block: \(id)")
                }
            }
        }

        // Check different block types for rich_text content
        if let paragraph = block["paragraph"] as? [String: Any],
           let richText = paragraph["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        if let heading1 = block["heading_1"] as? [String: Any],
           let richText = heading1["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        if let heading2 = block["heading_2"] as? [String: Any],
           let richText = heading2["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        if let heading3 = block["heading_3"] as? [String: Any],
           let richText = heading3["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        if let bulletedListItem = block["bulleted_list_item"] as? [String: Any],
           let richText = bulletedListItem["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        if let numberedListItem = block["numbered_list_item"] as? [String: Any],
           let richText = numberedListItem["rich_text"] as? [[String: Any]] {
            searchRichText(richText)
        }

        return mentions
    }

    private func normalizeDatabaseId(_ id: String) -> String {
        // Remove common URL prefixes and clean the ID
        var cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove any URL prefix if present
        if let urlComponents = URLComponents(string: cleanId),
           let path = urlComponents.path.split(separator: "/").last {
            cleanId = String(path)
        }

        // Extract just the ID part if there's a query string
        if let questionMarkIndex = cleanId.firstIndex(of: "?") {
            cleanId = String(cleanId[..<questionMarkIndex])
        }

        // Remove all dashes to get the raw ID
        let rawId = cleanId.replacingOccurrences(of: "-", with: "")

        // Notion IDs should be 32 characters (hex). If we have that, format it properly
        if rawId.count == 32 {
            // Insert dashes to make it a proper UUID format
            let index8 = rawId.index(rawId.startIndex, offsetBy: 8)
            let index12 = rawId.index(rawId.startIndex, offsetBy: 12)
            let index16 = rawId.index(rawId.startIndex, offsetBy: 16)
            let index20 = rawId.index(rawId.startIndex, offsetBy: 20)

            let part1 = String(rawId[..<index8])
            let part2 = String(rawId[index8..<index12])
            let part3 = String(rawId[index12..<index16])
            let part4 = String(rawId[index16..<index20])
            let part5 = String(rawId[index20...])

            return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
        }

        // If already in correct format or different length, return as is
        return cleanId
    }

    private func processPages(_ pages: [NotionPage], mentions: [(sourceId: String, targetId: String)] = []) {
        var graphNodes: [GraphNode] = []
        var graphLinks: [GraphLink] = []

        print("\n📊 Processing \(pages.count) pages and \(mentions.count) mentions...")

        // Collect all unique tags
        var uniqueTags = Set<String>()
        for page in pages {
            uniqueTags.formUnion(page.tags)
        }
        print("📑 Found \(uniqueTags.count) unique tags")

        // Create nodes from pages
        for (index, page) in pages.enumerated() {
            let node = GraphNode(
                id: page.id,
                name: page.title,
                type: "page",
                group: index % 10 + 1 // Distribute across groups for coloring
            )
            graphNodes.append(node)
        }
        print("✅ Created \(graphNodes.count) page nodes")

        // Create nodes from tags
        for tag in uniqueTags {
            let tagNode = GraphNode(
                id: "tag-\(tag)",
                name: tag,
                type: "tag",
                group: 0 // Special group for tags
            )
            graphNodes.append(tagNode)
        }
        print("✅ Created \(uniqueTags.count) tag nodes")

        // Create links from pages to tags
        var tagLinksCount = 0
        for page in pages {
            for tag in page.tags {
                let tagNodeId = "tag-\(tag)"
                let link = GraphLink(
                    source: page.id,
                    target: tagNodeId,
                    value: 1
                )
                graphLinks.append(link)
                tagLinksCount += 1
            }
        }
        print("✅ Created \(tagLinksCount) links from pages to tags")

        // Create links from relation properties
        var relationLinksCount = 0
        for page in pages {
            let sourceId = page.id
            let relatedIds = page.relations

            for targetId in relatedIds {
                if graphNodes.contains(where: { $0.id == targetId }) {
                    let link = GraphLink(
                        source: sourceId,
                        target: targetId,
                        value: 1
                    )
                    graphLinks.append(link)
                    relationLinksCount += 1
                }
            }
        }
        print("✅ Created \(relationLinksCount) links from relation properties")

        // Create links from page mentions in content
        var mentionLinksCount = 0
        for mention in mentions {
            // Only create link if both source and target exist in our nodes
            if graphNodes.contains(where: { $0.id == mention.sourceId }) &&
               graphNodes.contains(where: { $0.id == mention.targetId }) {
                let link = GraphLink(
                    source: mention.sourceId,
                    target: mention.targetId,
                    value: 1
                )
                graphLinks.append(link)
                mentionLinksCount += 1
            } else {
                print("⚠️ Skipping mention link (source or target not in database): \(mention.sourceId) → \(mention.targetId)")
            }
        }
        print("✅ Created \(mentionLinksCount) links from page mentions")
        print("📈 Total links in graph: \(graphLinks.count)\n")

        self.nodes = graphNodes
        self.links = graphLinks
    }
}

enum NotionError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Notion API"
        case .apiError(let statusCode, let message):
            return "Notion API error (\(statusCode)): \(message)"
        }
    }
}
