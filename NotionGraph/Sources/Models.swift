import Foundation

struct GraphNode: Identifiable, Codable {
    let id: String
    let name: String
    let type: String?
    var group: Int

    init(id: String, name: String, type: String? = nil, group: Int = 1) {
        self.id = id
        self.name = name
        self.type = type
        self.group = group
    }
}

struct GraphLink: Identifiable, Codable {
    let id: String
    let source: String
    let target: String
    let value: Int

    init(id: String? = nil, source: String, target: String, value: Int = 1) {
        self.id = id ?? "\(source)-\(target)"
        self.source = source
        self.target = target
        self.value = value
    }
}

struct GraphData: Codable {
    let nodes: [GraphNode]
    let links: [GraphLink]
}

// Notion API Models
struct NotionDatabase: Codable {
    let results: [NotionPage]
}

struct NotionPage: Codable {
    let id: String
    let properties: [String: NotionProperty]

    var title: String {
        for (_, property) in properties {
            if case .title(let titleArray) = property, let first = titleArray.first {
                return first.plainText
            }
        }
        return "Untitled"
    }

    var relations: [String] {
        var relationIds: [String] = []
        for (_, property) in properties {
            if case .relation(let relations) = property {
                relationIds.append(contentsOf: relations.map { $0.id })
            }
        }
        return relationIds
    }

    var tags: [String] {
        var tagNames: [String] = []
        for (_, property) in properties {
            if case .multiSelect(let tags) = property {
                tagNames.append(contentsOf: tags.map { $0.name })
            }
        }
        return tagNames
    }
}

enum NotionProperty: Codable {
    case title([NotionText])
    case richText([NotionText])
    case relation([NotionRelation])
    case multiSelect([NotionTag])
    case other

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "title":
            let titles = try container.decode([NotionText].self, forKey: .title)
            self = .title(titles)
        case "rich_text":
            let texts = try container.decode([NotionText].self, forKey: .richText)
            self = .richText(texts)
        case "relation":
            let relations = try container.decode([NotionRelation].self, forKey: .relation)
            self = .relation(relations)
        case "multi_select":
            let tags = try container.decode([NotionTag].self, forKey: .multiSelect)
            self = .multiSelect(tags)
        default:
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .title(let titles):
            try container.encode("title", forKey: .type)
            try container.encode(titles, forKey: .title)
        case .richText(let texts):
            try container.encode("rich_text", forKey: .type)
            try container.encode(texts, forKey: .richText)
        case .relation(let relations):
            try container.encode("relation", forKey: .type)
            try container.encode(relations, forKey: .relation)
        case .multiSelect(let tags):
            try container.encode("multi_select", forKey: .type)
            try container.encode(tags, forKey: .multiSelect)
        case .other:
            try container.encode("other", forKey: .type)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case richText = "rich_text"
        case relation
        case multiSelect = "multi_select"
    }
}

struct NotionText: Codable {
    let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

struct NotionRelation: Codable {
    let id: String
}

struct NotionTag: Codable {
    let id: String?
    let name: String
}
