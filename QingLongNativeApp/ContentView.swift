import SwiftUI

struct ContentView: View {
    @StateObject private var client = QingLongClient()

    var body: some View {
        Group {
            if client.isLoggedIn {
                MainTabs()
                    .environmentObject(client)
            } else {
                LoginView()
                    .environmentObject(client)
            }
        }
        .tint(.green)
    }
}

struct LoginView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var useHTTPS = false
    @State private var host = "192.168.1.20"
    @State private var port = "5700"
    @State private var username = "admin"
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("青")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.green)
                            .frame(width: 64, height: 64)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Text("青龙管理")
                            .font(.system(size: 36, weight: .black))
                        Text("原生 App 管理远程青龙面板。输入面板地址和账号密码后，直接读取任务、环境变量等真实数据。")
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.top, 18)

                    VStack(spacing: 14) {
                        Picker("协议", selection: $useHTTPS) {
                            Text("http://").tag(false)
                            Text("https://").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useHTTPS) { enabled in
                            if host == "192.168.1.20" || host == "ql.example.com" {
                                host = enabled ? "ql.example.com" : "192.168.1.20"
                            }
                            port = enabled ? "443" : "5700"
                        }

                        TextField("IP 或域名", text: $host)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .fieldStyle()

                        TextField("端口", text: $port)
                            .keyboardType(.numberPad)
                            .fieldStyle()

                        TextField("用户名", text: $username)
                            .textInputAutocapitalization(.never)
                            .fieldStyle()

                        SecureField("密码", text: $password)
                            .fieldStyle()

                        Text("接口地址：\(baseURL.absoluteString)/api")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        if !client.errorMessage.isEmpty {
                            Text(client.errorMessage)
                                .font(.footnote)
                                .foregroundStyle(client.errorMessage.contains("已") ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task {
                                client.configure(baseURL: baseURL)
                                await client.login(username: username, password: password)
                            }
                        } label: {
                            HStack {
                                if client.isLoading { ProgressView().tint(.white) }
                                Text("登录并读取面板")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                        .disabled(client.isLoading)
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.06), radius: 18, y: 10)
                }
                .padding(18)
            }
            .background(LinearGradient(colors: [.white, Color.green.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("远程登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var baseURL: URL {
        let scheme = useHTTPS ? "https" : "http"
        let defaultPort = useHTTPS ? "443" : "80"
        let portPart = port.isEmpty || port == defaultPort ? "" : ":\(port)"
        return URL(string: "\(scheme)://\(host.trimmingCharacters(in: .whitespacesAndNewlines))\(portPart)")!
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("首页", systemImage: "house") }
            CronListView()
                .tabItem { Label("任务", systemImage: "play.circle") }
            EnvListView()
                .tabItem { Label("环境", systemImage: "circle.hexagongrid") }
            MoreView()
                .tabItem { Label("更多", systemImage: "ellipsis.circle") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("面板状态")
                        .font(.system(size: 34, weight: .black))
                    Text(client.baseURL.absoluteString)
                        .foregroundStyle(.secondary)

                    HStack {
                        metric("定时任务", "\(client.crons.count)")
                        metric("环境变量", "\(client.envs.count)")
                    }

                    if !client.errorMessage.isEmpty {
                        Text(client.errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(18)
            }
            .navigationTitle("青龙管理")
            .toolbar {
                Button {
                    Task { await client.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CronListView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            List(client.crons) { cron in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(cron.title).fontWeight(.semibold)
                        Spacer()
                        Text(cron.statusText)
                            .font(.caption)
                            .foregroundStyle(cron.isDisabled == 1 ? .red : .green)
                    }
                    Text(cron.subtitle).foregroundStyle(.secondary)
                }
                .swipeActions(edge: .leading) {
                    Button("运行") { Task { await client.runCron(cron) } }
                        .tint(.green)
                    Button("停止") { Task { await client.stopCron(cron) } }
                        .tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button(cron.isDisabled == 1 ? "启用" : "禁用") {
                        Task { await client.toggleCron(cron) }
                    }
                    .tint(cron.isDisabled == 1 ? .green : .red)
                }
            }
            .overlay {
                if client.crons.isEmpty {
                    EmptyStateView(title: "没有任务数据", subtitle: "下拉刷新或检查登录地址。", icon: "tray")
                }
            }
            .navigationTitle("定时任务")
            .refreshable { await client.loadCrons() }
            .toolbar {
                Button { Task { await client.loadCrons() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
    }
}

struct EnvListView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            List(client.envs) { env in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(env.title).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: env.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(env.enabled ? .green : .red)
                    }
                    Text(env.subtitle).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button(env.enabled ? "禁用" : "启用") {
                        Task { await client.toggleEnv(env) }
                    }
                    .tint(env.enabled ? .red : .green)
                }
            }
            .overlay {
                if client.envs.isEmpty {
                    EmptyStateView(title: "没有环境变量", subtitle: "下拉刷新或检查登录权限。", icon: "tray")
                }
            }
            .navigationTitle("环境变量")
            .refreshable { await client.loadEnvs() }
            .toolbar {
                Button { Task { await client.loadEnvs() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            List {
                Section("连接") {
                    Text(client.baseURL.absoluteString)
                    Button("刷新全部数据") {
                        Task { await client.refreshAll() }
                    }
                }
                Section("后续可继续接入") {
                    Text("脚本文件管理")
                    Text("依赖管理")
                    Text("日志查看")
                    Text("配置文件编辑")
                }
            }
            .navigationTitle("更多")
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}
