import Foundation

struct CronItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let command: String?
    let schedule: String?
    let status: Int?
    let isDisabled: Int?
    let lastRunningTime: Int?
    let nextRunTime: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, command, schedule, status
        case isDisabled
        case lastRunningTime = "last_running_time"
        case nextRunTime
    }

    var title: String { name ?? command ?? "未命名任务" }
    var subtitle: String { schedule ?? command ?? "" }
    var statusText: String {
        if isDisabled == 1 { return "已禁用" }
        if status == 1 { return "运行中" }
        return "空闲中"
    }
}

struct EnvItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let value: String?
    let remarks: String?
    let status: Int?

    var title: String { name ?? "未命名变量" }
    var subtitle: String { remarks?.isEmpty == false ? remarks! : (value ?? "") }
    var enabled: Bool { status != 1 }
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

struct ListPage<T: Decodable>: Decodable {
    let data: [T]?
}
