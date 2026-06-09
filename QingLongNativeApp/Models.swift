import Foundation

struct PanelAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var baseURL: URL
    var username: String
    var token: String
    var lastLoginAt: Date

    init(id: UUID = UUID(), name: String, baseURL: URL, username: String, token: String, lastLoginAt: Date = Date()) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.username = username
        self.token = token
        self.lastLoginAt = lastLoginAt
    }
}

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
    var isCronDisabled: Bool { isDisabled == 1 || status == 2 }
    var isCronRunning: Bool { !isCronDisabled && status == 0 }
    var statusText: String {
        if isCronDisabled { return "已禁用" }
        if isCronRunning { return "运行中" }
        return "空闲中"
    }
}

struct CronPayload: Encodable {
    var id: Int?
    var name: String
    var command: String
    var schedule: String
    var labels: [String]?
}

struct EnvItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let value: String?
    let remarks: String?
    let status: Int?

    var title: String { nonEmpty(name) ?? "变量" }
    var subtitle: String { nonEmpty(remarks) ?? masked(value) }
    var enabled: Bool { status != 1 }
}

struct EnvPayload: Encodable {
    var id: Int?
    var name: String
    var value: String
    var remarks: String
}

struct ScriptNode: Identifiable, Codable {
    let title: String?
    let key: String?
    let path: String?
    let type: String?
    let children: [ScriptNode]?

    var id: String { key ?? path ?? title ?? UUID().uuidString }
    var name: String { title ?? key ?? path ?? "文件" }
    var isDirectory: Bool { type == "directory" || type == "folder" }
}

struct DependencyItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let type: String?
    let status: Int?
    let remarks: String?
    let log: String?

    var title: String { nonEmpty(name) ?? "依赖" }
    var subtitle: String { nonEmpty(remarks) ?? (type ?? "") }
    var statusText: String {
        switch status {
        case 0: return "队列中"
        case 1: return "安装中"
        case 2: return "已安装"
        case 3: return "安装失败"
        default: return "未知"
        }
    }
}

struct DependencyPayload: Encodable {
    var id: Int?
    var name: String
    var type: String
    var remarks: String
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

    var title: String { nonEmpty(name) ?? "订阅" }
    var subtitle: String { nonEmpty(url) ?? nonEmpty(schedule) ?? "" }
}

struct SubscriptionPayload: Encodable {
    var id: Int?
    var name: String
    var url: String
    var branch: String
    var schedule: String
}

struct ScriptPayload: Encodable {
    var filename: String
    var path: String
    var content: String
}

struct ScriptDeletePayload: Encodable {
    var filename: String
    var path: String
    var type: String?
}

struct ScriptRenamePayload: Encodable {
    var filename: String
    var path: String
    var newFilename: String
}

struct CommandRunPayload: Encodable {
    var command: String
}

struct CommandRunResult {
    var output: String
    var pid: Int?
}

struct LogNode: Identifiable, Codable {
    let title: String?
    let key: String?
    let path: String?
    let type: String?
    let children: [LogNode]?

    var id: String { key ?? path ?? title ?? UUID().uuidString }
    var name: String { title ?? key ?? path ?? "日志" }
    var isDirectory: Bool { type == "directory" || type == "folder" }
}

struct ConfigFile: Identifiable, Codable {
    let title: String?
    let name: String?
    let value: String?
    let key: String?

    var id: String { key ?? name ?? title ?? UUID().uuidString }
    var displayName: String { title ?? name ?? value ?? key ?? "配置" }
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
        let single = try decoder.singleValueContainer()
        if let array = try? single.decode([T].self) {
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
