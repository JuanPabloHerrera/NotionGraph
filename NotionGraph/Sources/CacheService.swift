import Foundation
import SwiftData

@MainActor
class CacheService {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }

    // MARK: - Save to Cache

    func saveGraphData(nodes: [GraphNode], links: [GraphLink], databaseId: String) throws {
        print("💾 Saving \(nodes.count) nodes and \(links.count) links to cache...")

        // Delete old data
        try clearCache()

        // Save nodes
        for node in nodes {
            let cachedNode = CachedGraphNode.from(node)
            modelContext.insert(cachedNode)
        }

        // Save links
        for link in links {
            let cachedLink = CachedGraphLink.from(link)
            modelContext.insert(cachedLink)
        }

        // Update sync metadata
        let metadata = SyncMetadata(key: "main", lastSyncDate: Date(), databaseId: databaseId)
        modelContext.insert(metadata)

        try modelContext.save()
        print("✅ Cache saved successfully")
    }

    // MARK: - Load from Cache

    func loadGraphData() throws -> (nodes: [GraphNode], links: [GraphLink], lastSync: Date?) {
        print("📂 Loading graph data from cache...")

        // Fetch nodes
        let nodeDescriptor = FetchDescriptor<CachedGraphNode>(
            sortBy: [SortDescriptor(\.name)]
        )
        let cachedNodes = try modelContext.fetch(nodeDescriptor)
        let nodes = cachedNodes.map { $0.toGraphNode() }

        // Fetch links
        let linkDescriptor = FetchDescriptor<CachedGraphLink>()
        let cachedLinks = try modelContext.fetch(linkDescriptor)
        let links = cachedLinks.map { $0.toGraphLink() }

        // Fetch metadata
        let metadataDescriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == "main" }
        )
        let metadata = try modelContext.fetch(metadataDescriptor).first

        print("✅ Loaded \(nodes.count) nodes and \(links.count) links from cache")
        if let lastSync = metadata?.lastSyncDate {
            print("🕒 Last synced: \(lastSync.formatted())")
        }

        return (nodes, links, metadata?.lastSyncDate)
    }

    // MARK: - Check if cache exists

    func hasCachedData(for databaseId: String) -> Bool {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.databaseId == databaseId }
        )

        do {
            let metadata = try modelContext.fetch(descriptor)
            return !metadata.isEmpty
        } catch {
            print("❌ Error checking cache: \(error)")
            return false
        }
    }

    // MARK: - Clear Cache

    func clearCache() throws {
        print("🗑️ Clearing cache...")

        // Delete all nodes
        try modelContext.delete(model: CachedGraphNode.self)

        // Delete all links
        try modelContext.delete(model: CachedGraphLink.self)

        // Delete metadata
        try modelContext.delete(model: SyncMetadata.self)

        try modelContext.save()
        print("✅ Cache cleared")
    }

    // MARK: - Get Last Sync Date

    func getLastSyncDate() -> Date? {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == "main" }
        )

        do {
            let metadata = try modelContext.fetch(descriptor).first
            return metadata?.lastSyncDate
        } catch {
            print("❌ Error fetching sync date: \(error)")
            return nil
        }
    }
}
