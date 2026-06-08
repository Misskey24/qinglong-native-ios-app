import Foundation

@MainActor
final class QingLongClient: ObservableObject {
    @Published var baseURL = URL(string: "http://192.168.1.20:5700")!
    @Published var token = ""
    @Published var crons: [CronItem] = []
    @Published var envs: [EnvItem] = []
    @Published var scripts: [ScriptNode] = []
    @Published var dependencies: [DependencyItem] = []
    @Published var subscriptions: [SubscriptionItem] = []
    @Published var logs: [LogNode] = []
    @Published var configFiles: [ConfigFile] = []
    @Published var configContent = ""
    @Published var scriptContent = ""
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
                throw QingLongError.message(response.message ?? "Login failed")
            }
            guard let token = response.data?.token, !token.isEmpty else {
                throw QingLongError.message("No token returned")
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
        await loadScripts()
        await loadDependencies()
        await loadSubscriptions()
        await loadLogs()
        await loadConfigFiles()
    }

    func loadCrons() async {
        do {
            let response: APIResponse<FlexibleList<CronItem>> = try await request("crons", method: "GET", query: ["page": "1", "size": "100"], authorized: true)
            crons = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEnvs() async {
        do {
            let response: APIResponse<FlexibleList<EnvItem>> = try await request("envs", method: "GET", authorized: true)
            envs = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadScripts() async {
        do {
            let response: APIResponse<FlexibleList<ScriptNode>> = try await request("scripts", method: "GET", authorized: true)
            scripts = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDependencies() async {
        do {
            let response: APIResponse<FlexibleList<DependencyItem>> = try await request("dependencies", method: "GET", query: ["page": "1", "size": "100"], authorized: true)
            dependencies = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSubscriptions() async {
        do {
            let response: APIResponse<FlexibleList<SubscriptionItem>> = try await request("subscriptions", method: "GET", authorized: true)
            subscriptions = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadLogs() async {
        do {
            let response: APIResponse<FlexibleList<LogNode>> = try await request("logs", method: "GET", authorized: true)
            logs = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadConfigFiles() async {
        do {
            let response: APIResponse<FlexibleList<ConfigFile>> = try await request("configs/files", method: "GET", authorized: true)
            configFiles = response.data?.items ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadConfigDetail(_ name: String) async {
        do {
            let response: APIResponse<String> = try await request("configs/detail", method: "GET", query: ["path": name], authorized: true)
            configContent = response.data ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveConfig(name: String, content: String) async {
        do {
            let _: APIResponse<EmptyData> = try await request("configs/save", method: "POST", body: ["name": name, "content": content], authorized: true)
            errorMessage = "Saved"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCron(_ payload: CronPayload) async {
        do {
            let method = payload.id == nil ? "POST" : "PUT"
            let _: APIResponse<EmptyData> = try await request("crons", method: method, body: payload, authorized: true)
            errorMessage = payload.id == nil ? "任务已创建" : "任务已保存"
            await loadCrons()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveEnv(_ payload: EnvPayload) async {
        do {
            let method = payload.id == nil ? "POST" : "PUT"
            let _: APIResponse<EmptyData> = try await request("envs", method: method, body: payload, authorized: true)
            errorMessage = payload.id == nil ? "变量已创建" : "变量已保存"
            await loadEnvs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDependency(_ payload: DependencyPayload) async {
        do {
            let method = payload.id == nil ? "POST" : "PUT"
            let _: APIResponse<EmptyData> = try await request("dependencies", method: method, body: payload, authorized: true)
            errorMessage = payload.id == nil ? "依赖已创建" : "依赖已保存"
            await loadDependencies()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSubscription(_ payload: SubscriptionPayload) async {
        do {
            let method = payload.id == nil ? "POST" : "PUT"
            let _: APIResponse<EmptyData> = try await request("subscriptions", method: method, body: payload, authorized: true)
            errorMessage = payload.id == nil ? "订阅已创建" : "订阅已保存"
            await loadSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadScriptDetail(file: String, path: String = "") async {
        do {
            let response: APIResponse<String> = try await request("scripts/detail", method: "GET", query: ["file": file, "path": path], authorized: true)
            scriptContent = response.data ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveScript(filename: String, path: String, content: String) async {
        do {
            let payload = ScriptPayload(filename: filename, path: path, content: content)
            let _: APIResponse<EmptyData> = try await request("scripts", method: "PUT", body: payload, authorized: true)
            errorMessage = "脚本已保存"
            await loadScripts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runCron(_ cron: CronItem) async {
        await operate("crons/run", ids: [cron.id])
        await loadCrons()
    }

    func stopCron(_ cron: CronItem) async {
        await operate("crons/stop", ids: [cron.id])
        await loadCrons()
    }

    func toggleCron(_ cron: CronItem) async {
        await operate(cron.isDisabled == 1 ? "crons/enable" : "crons/disable", ids: [cron.id])
        await loadCrons()
    }

    func toggleEnv(_ env: EnvItem) async {
        await operate(env.enabled ? "envs/disable" : "envs/enable", ids: [env.id])
        await loadEnvs()
    }

    func reinstallDependency(_ item: DependencyItem) async {
        await operate("dependencies/reinstall", ids: [item.id])
        await loadDependencies()
    }

    func runSubscription(_ item: SubscriptionItem) async {
        await operate("subscriptions/run", ids: [item.id])
        await loadSubscriptions()
    }

    private func operate(_ path: String, ids: [Int]) async {
        do {
            let _: APIResponse<EmptyData> = try await request(path, method: "PUT", body: ids, authorized: true)
            errorMessage = "Done"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func request<T: Decodable>(_ path: String, method: String, query: [String: String] = [:], authorized: Bool) async throws -> T {
        var request = URLRequest(url: endpoint(path, query: query))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        return try await send(request)
    }

    private func request<T: Decodable, B: Encodable>(_ path: String, method: String, body: B, authorized: Bool) async throws -> T {
        var request = URLRequest(url: endpoint(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QingLongError.message("No server response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw QingLongError.message("HTTP \(http.statusCode) \(text)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func endpoint(_ path: String, query: [String: String] = [:]) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var clean = path
        if clean.hasPrefix("/") { clean.removeFirst() }
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = ([basePath, "api", clean]).filter { !$0.isEmpty }
        components.path = "/" + parts.joined(separator: "/")
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url!
    }

    private var authHeader: String {
        token.lowercased().hasPrefix("bearer ") ? token : "Bearer \(token)"
    }
}

enum QingLongError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let message): return message
        }
    }
}
