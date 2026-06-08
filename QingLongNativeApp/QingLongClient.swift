import Foundation

@MainActor
final class QingLongClient: ObservableObject {
    @Published var baseURL = URL(string: "http://192.168.1.20:5700")!
    @Published var token = ""
    @Published var crons: [CronItem] = []
    @Published var envs: [EnvItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    var isLoggedIn: Bool { !token.isEmpty }

    func configure(baseURL: URL) {
        self.baseURL = baseURL
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let body = LoginRequest(username: username, password: password)
            let response: APIResponse<LoginData> = try await request("user/login", method: "POST", body: body, authorized: false)
            guard response.code == nil || response.code == 200 else {
                throw QingLongError.message(response.message ?? "登录失败")
            }
            guard let token = response.data?.token, !token.isEmpty else {
                throw QingLongError.message("登录成功但没有返回 token")
            }
            self.token = token
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAll() async {
        await loadCrons()
        await loadEnvs()
    }

    func loadCrons() async {
        do {
            let response: APIResponse<ListPage<CronItem>> = try await request("crons?page=1&size=100", method: "GET", authorized: true)
            crons = response.data?.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEnvs() async {
        do {
            let response: APIResponse<[EnvItem]> = try await request("envs", method: "GET", authorized: true)
            envs = response.data ?? []
        } catch {
            do {
                let response: APIResponse<ListPage<EnvItem>> = try await request("envs", method: "GET", authorized: true)
                envs = response.data?.data ?? []
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func runCron(_ cron: CronItem) async {
        await operateCron("crons/run", ids: [cron.id], toast: "任务已运行")
    }

    func stopCron(_ cron: CronItem) async {
        await operateCron("crons/stop", ids: [cron.id], toast: "任务已停止")
    }

    func toggleCron(_ cron: CronItem) async {
        let path = cron.isDisabled == 1 ? "crons/enable" : "crons/disable"
        await operateCron(path, ids: [cron.id], toast: "任务状态已更新")
    }

    func toggleEnv(_ env: EnvItem) async {
        let path = env.enabled ? "envs/disable" : "envs/enable"
        await operateCron(path, ids: [env.id], toast: "变量状态已更新")
        await loadEnvs()
    }

    private func operateCron(_ path: String, ids: [Int], toast: String) async {
        do {
            let _: APIResponse<EmptyData> = try await request(path, method: "PUT", body: ids, authorized: true)
            errorMessage = toast
            await loadCrons()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func request<T: Decodable>(_ path: String, method: String, authorized: Bool) async throws -> T {
        var request = URLRequest(url: endpoint(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await send(request)
    }

    private func request<T: Decodable, B: Encodable>(_ path: String, method: String, body: B, authorized: Bool) async throws -> T {
        var request = URLRequest(url: endpoint(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QingLongError.message("服务器无响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw QingLongError.message("HTTP \(http.statusCode) \(text)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func endpoint(_ path: String) -> URL {
        var clean = path
        if clean.hasPrefix("/") { clean.removeFirst() }
        return baseURL.appendingPathComponent("api").appendingPathComponent(clean)
    }
}

struct EmptyData: Decodable {}

enum QingLongError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let message): return message
        }
    }
}
