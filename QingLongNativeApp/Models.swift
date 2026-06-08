import Foundation

struct TaskItem: Identifiable {
    let id = UUID()
    let name: String
    let cron: String
    let status: String
    let file: String
    let lastRun: String
}

struct EnvItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let note: String
    let enabled: Bool
}

struct ScriptItem: Identifiable {
    let id = UUID()
    let name: String
    let isFolder: Bool
    let level: Int
}

struct DependencyItem: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let installedAt: String
}

enum DemoData {
    static let tasks = [
        TaskItem(name: "3.12 大牌惠聚 悦享好礼", cron: "59 23 29 2 *", status: "空闲中", file: "shufflewzc_faker2_main/jd_loreal.js", lastRun: "2 天前"),
        TaskItem(name: "大牌联合 0305", cron: "59 23 29 2 *", status: "空闲中", file: "shufflewzc_faker2_main/jd_union.js", lastRun: "刚刚"),
        TaskItem(name: "快手极速版", cron: "5 * * * *", status: "运行中", file: "ks_fast/ks_task.js", lastRun: "44 分钟前"),
        TaskItem(name: "3.8 真我不设限女王自定义", cron: "59 23 29 2 *", status: "已禁用", file: "shufflewzc_faker2_main/jd_queen.js", lastRun: "2 天前")
    ]

    static let envs = [
        EnvItem(key: "JD_COOKIE", value: "pt_key=AAJ...;pt_pin=rebels;", note: "京东主账号", enabled: true),
        EnvItem(key: "PUSH_PLUS_TOKEN", value: "******", note: "PushPlus 通知", enabled: true),
        EnvItem(key: "QLAPI_CLIENT_ID", value: "openapi-mobile", note: "移动端授权", enabled: true),
        EnvItem(key: "BILI_COOKIE", value: "SESSDATA=******", note: "B 站签到", enabled: false)
    ]

    static let scripts = [
        ScriptItem(name: "shufflewzc_faker2_main", isFolder: true, level: 0),
        ScriptItem(name: "function", isFolder: true, level: 0),
        ScriptItem(name: "utils", isFolder: true, level: 0),
        ScriptItem(name: "Rebels", isFolder: true, level: 0),
        ScriptItem(name: "rebelsa.js", isFolder: false, level: 1),
        ScriptItem(name: "rebelsb.js", isFolder: false, level: 1),
        ScriptItem(name: "baseCookie.js", isFolder: false, level: 0),
        ScriptItem(name: "baseUtils.js", isFolder: false, level: 0)
    ]

    static let dependencies = [
        DependencyItem(name: "json5", type: "NodeJs", installedAt: "2026-06-08 21:39"),
        DependencyItem(name: "js-base64", type: "NodeJs", installedAt: "2026-06-08 21:39"),
        DependencyItem(name: "requests", type: "Python", installedAt: "2026-06-08 21:39"),
        DependencyItem(name: "curl", type: "Linux", installedAt: "2026-06-08 21:39")
    ]
}
