import Foundation
import SwiftData

// SwiftData models for offline caching
@Model
final class CachedGraphNode {
    @Attribute(.unique) var id: String
    var name: String
    var type: String?
    var group: Int
    var url: String?
    var lastUpdated: Date

    init(id: String, name: String, type: String? = nil, group: Int = 1, url: String? = nil, lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.group = group
        self.url = url
        self.lastUpdated = lastUpdated
    }

    // Convert to GraphNode for display
    func toGraphNode() -> GraphNode {
        GraphNode(id: id, name: name, type: type, group: group, url: url)
    }

    // Create from GraphNode
    static func from(_ node: GraphNode) -> CachedGraphNode {
        CachedGraphNode(id: node.id, name: node.name, type: node.type, group: node.group, url: node.url)
    }
}

@Model
final class CachedGraphLink {
    @Attribute(.unique) var id: String
    var source: String
    var target: String
    var value: Int
    var lastUpdated: Date

    init(id: String, source: String, target: String, value: Int = 1, lastUpdated: Date = Date()) {
        self.id = id
        self.source = source
        self.target = target
        self.value = value
        self.lastUpdated = lastUpdated
    }

    // Convert to GraphLink for display
    func toGraphLink() -> GraphLink {
        GraphLink(id: id, source: source, target: target, value: value)
    }

    // Create from GraphLink
    static func from(_ link: GraphLink) -> CachedGraphLink {
        CachedGraphLink(id: link.id, source: link.source, target: link.target, value: link.value)
    }
}

// Metadata to track sync status
@Model
final class SyncMetadata {
    @Attribute(.unique) var key: String
    var lastSyncDate: Date?
    var databaseId: String

    init(key: String = "main", lastSyncDate: Date? = nil, databaseId: String = "") {
        self.key = key
        self.lastSyncDate = lastSyncDate
        self.databaseId = databaseId
    }
}
