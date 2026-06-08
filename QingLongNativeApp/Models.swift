import Foundation

struct CronItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let command: String?
    let schedule: String?
    let status: Int?
    let isDisabled: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, command, schedule, status, isDisabled
    }

    var title: String { nonEmpty(name) ?? nonEmpty(command) ?? "Task" }
    var subtitle: String { nonEmpty(schedule) ?? nonEmpty(command) ?? "" }
    var statusText: String {
        if isDisabled == 1 { return "Disabled" }
        if status == 1 { return "Running" }
        return "Idle"
    }
}

struct EnvItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let value: String?
    let remarks: String?
    let status: Int?

    var title: String { nonEmpty(name) ?? "Variable" }
    var subtitle: String { nonEmpty(remarks) ?? masked(value) }
    var enabled: Bool { status != 1 }
}

struct ScriptNode: Identifiable, Codable {
    let title: String?
    let key: String?
    let type: String?
    let children: [ScriptNode]?

    var id: String { key ?? title ?? UUID().uuidString }
    var name: String { title ?? key ?? "File" }
    var isDirectory: Bool { type == "directory" || type == "folder" }
}

struct DependencyItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let type: String?
    let status: Int?
    let remarks: String?
    let log: String?

    var title: String { nonEmpty(name) ?? "Dependency" }
    var subtitle: String { nonEmpty(remarks) ?? (type ?? "") }
    var statusText: String {
        switch status {
        case 0: return "Queued"
        case 1: return "Installing"
        case 2: return "Installed"
        case 3: return "Failed"
        default: return "Unknown"
        }
    }
}

struct SubscriptionItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let url: String?
    let schedule: String?
    let branch: String?
    let status: Int?
    let isDisabled: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, url, schedule, branch, status
        case isDisabled = "is_disabled"
    }

    var title: String { nonEmpty(name) ?? "Subscription" }
    var subtitle: String { nonEmpty(url) ?? nonEmpty(schedule) ?? "" }
}

struct LogNode: Identifiable, Codable {
    let title: String?
    let key: String?
    let path: String?
    let type: String?
    let children: [LogNode]?

    var id: String { key ?? path ?? title ?? UUID().uuidString }
    var name: String { title ?? key ?? path ?? "Log" }
    var isDirectory: Bool { type == "directory" || type == "folder" }
}

struct ConfigFile: Identifiable, Codable {
    let title: String?
    let name: String?
    let value: String?
    let key: String?

    var id: String { key ?? name ?? title ?? UUID().uuidString }
    var displayName: String { title ?? name ?? value ?? key ?? "Config" }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginData: Decodable {
    let token: String?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case token
        case tokenType = "token_type"
    }
}

struct APIResponse<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}

struct FlexibleList<T: Decodable>: Decodable {
    let items: [T]

    enum CodingKeys: String, CodingKey {
        case data, list, items
    }

    init(from decoder: Decoder) throws {
        if let array = try? [T](from: decoder) {
            items = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let array = try? container.decode([T].self, forKey: .data) {
            items = array
        } else if let array = try? container.decode([T].self, forKey: .list) {
            items = array
        } else if let array = try? container.decode([T].self, forKey: .items) {
            items = array
        } else {
            items = []
        }
    }
}

struct EmptyData: Decodable {}

func nonEmpty(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
        return nil
    }
    return value
}

func masked(_ value: String?) -> String {
    guard let value = nonEmpty(value) else { return "" }
    if value.count <= 12 { return value }
    return String(value.prefix(8)) + "..." + String(value.suffix(4))
}
