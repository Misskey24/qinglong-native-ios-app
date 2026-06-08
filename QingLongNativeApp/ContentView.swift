import SwiftUI

struct ContentView: View {
    @StateObject private var client = QingLongClient()

    var body: some View {
        Group {
            if client.isLoggedIn {
                MainTabs().environmentObject(client)
            } else {
                LoginView().environmentObject(client)
            }
        }
        .tint(.green)
    }
}

struct LoginView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var useHTTPS = false
    @State private var host = "192.168.100.8"
    @State private var port = "15600"
    @State private var username = "admin"
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("QingLong Manager")
                        .font(.system(size: 36, weight: .black))
                    Text("Native iOS manager for your remote QingLong panel.")
                        .foregroundStyle(.secondary)

                    VStack(spacing: 14) {
                        Picker("Protocol", selection: $useHTTPS) {
                            Text("http://").tag(false)
                            Text("https://").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useHTTPS) { enabled in
                            port = enabled ? "443" : "5700"
                        }

                        TextField("Host or IP", text: $host)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .fieldStyle()
                        TextField("Port", text: $port)
                            .keyboardType(.numberPad)
                            .fieldStyle()
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .fieldStyle()
                        SecureField("Password", text: $password)
                            .fieldStyle()

                        Text(baseURL.absoluteString + "/api")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        if !client.errorMessage.isEmpty {
                            Text(client.errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
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
                                Text("Login and Load Panel").fontWeight(.bold)
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
            .navigationTitle("Remote Login")
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
            DashboardView().tabItem { Label("Home", systemImage: "house") }
            CronListView().tabItem { Label("Tasks", systemImage: "play.circle") }
            EnvListView().tabItem { Label("Env", systemImage: "circle.hexagongrid") }
            MoreView().tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("QingLong Management")
                        .font(.system(size: 34, weight: .black))
                    Text("Panel Status")
                        .font(.system(size: 30, weight: .black))
                    Text(client.baseURL.absoluteString)
                        .foregroundStyle(.secondary)

                    HStack {
                        metric("Tasks", "\(client.crons.count)")
                        metric("Env Vars", "\(client.envs.count)")
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
            .navigationTitle("QingLong")
            .toolbar { refreshButton { await client.refreshAll() } }
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
                    Button("Run") { Task { await client.runCron(cron) } }.tint(.green)
                    Button("Stop") { Task { await client.stopCron(cron) } }.tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button(cron.isDisabled == 1 ? "Enable" : "Disable") {
                        Task { await client.toggleCron(cron) }
                    }
                    .tint(cron.isDisabled == 1 ? .green : .red)
                }
            }
            .overlay { if client.crons.isEmpty { EmptyStateView(title: "No tasks", subtitle: "Pull to refresh or check the panel address.", icon: "tray") } }
            .navigationTitle("Tasks")
            .refreshable { await client.loadCrons() }
            .toolbar { refreshButton { await client.loadCrons() } }
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
                    Button(env.enabled ? "Disable" : "Enable") {
                        Task { await client.toggleEnv(env) }
                    }
                    .tint(env.enabled ? .red : .green)
                }
            }
            .overlay { if client.envs.isEmpty { EmptyStateView(title: "No env vars", subtitle: "Pull to refresh or check permissions.", icon: "tray") } }
            .navigationTitle("Environment")
            .refreshable { await client.loadEnvs() }
            .toolbar { refreshButton { await client.loadEnvs() } }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    Text(client.baseURL.absoluteString)
                    Button("Refresh All Data") { Task { await client.refreshAll() } }
                }
                Section("Management") {
                    NavigationLink("Script Files") { ScriptListView().environmentObject(client) }
                    NavigationLink("Dependencies") { DependencyListView().environmentObject(client) }
                    NavigationLink("Subscriptions") { SubscriptionListView().environmentObject(client) }
                    NavigationLink("Logs") { LogListView().environmentObject(client) }
                    NavigationLink("Config Files") { ConfigListView().environmentObject(client) }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct ScriptListView: View {
    @EnvironmentObject private var client: QingLongClient
    var body: some View {
        List(flattenScripts(client.scripts)) { row in
            HStack {
                Image(systemName: row.isDirectory ? "folder" : "doc.text").foregroundStyle(.green)
                Text(row.name).padding(.leading, CGFloat(row.level * 14))
            }
        }
            .navigationTitle("Scripts")
            .refreshable { await client.loadScripts() }
            .toolbar { refreshButton { await client.loadScripts() } }
    }
}

struct DependencyListView: View {
    @EnvironmentObject private var client: QingLongClient
    var body: some View {
        List(client.dependencies) { item in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title).fontWeight(.semibold)
                    Spacer()
                    Text(item.statusText).font(.caption).foregroundStyle(.green)
                }
                Text(item.subtitle).foregroundStyle(.secondary)
            }
            .swipeActions {
                Button("Reinstall") { Task { await client.reinstallDependency(item) } }.tint(.green)
            }
        }
        .navigationTitle("Dependencies")
        .refreshable { await client.loadDependencies() }
        .toolbar { refreshButton { await client.loadDependencies() } }
    }
}

struct SubscriptionListView: View {
    @EnvironmentObject private var client: QingLongClient
    var body: some View {
        List(client.subscriptions) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).fontWeight(.semibold)
                Text(item.subtitle).foregroundStyle(.secondary)
            }
            .swipeActions {
                Button("Run") { Task { await client.runSubscription(item) } }.tint(.green)
            }
        }
        .navigationTitle("Subscriptions")
        .refreshable { await client.loadSubscriptions() }
        .toolbar { refreshButton { await client.loadSubscriptions() } }
    }
}

struct LogListView: View {
    @EnvironmentObject private var client: QingLongClient
    var body: some View {
        List(flattenLogs(client.logs)) { row in
            HStack {
                Image(systemName: row.isDirectory ? "folder" : "doc.text").foregroundStyle(.green)
                Text(row.name).padding(.leading, CGFloat(row.level * 14))
            }
        }
            .navigationTitle("Logs")
            .refreshable { await client.loadLogs() }
            .toolbar { refreshButton { await client.loadLogs() } }
    }
}

struct ConfigListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var selected = ""
    @State private var content = ""

    var body: some View {
        List {
            ForEach(client.configFiles) { file in
                NavigationLink(file.displayName) {
                    ConfigEditorView(name: file.displayName).environmentObject(client)
                }
            }
        }
        .navigationTitle("Config")
        .refreshable { await client.loadConfigFiles() }
        .toolbar { refreshButton { await client.loadConfigFiles() } }
    }
}

struct ConfigEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    let name: String
    @State private var text = ""

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .padding()
            .navigationTitle(name)
            .task {
                await client.loadConfigDetail(name)
                text = client.configContent
            }
            .toolbar {
                Button("Save") { Task { await client.saveConfig(name: name, content: text) } }
            }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
    }
}

@ToolbarContentBuilder
func refreshButton(_ action: @escaping () async -> Void) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button { Task { await action() } } label: { Image(systemName: "arrow.clockwise") }
    }
}

struct TreeRow: Identifiable {
    let id: String
    let name: String
    let isDirectory: Bool
    let level: Int
}

func flattenScripts(_ nodes: [ScriptNode], level: Int = 0) -> [TreeRow] {
    nodes.flatMap { node -> [TreeRow] in
        let current = TreeRow(id: node.id, name: node.name, isDirectory: node.isDirectory, level: level)
        return [current] + flattenScripts(node.children ?? [], level: level + 1)
    }
}

func flattenLogs(_ nodes: [LogNode], level: Int = 0) -> [TreeRow] {
    nodes.flatMap { node -> [TreeRow] in
        let current = TreeRow(id: node.id, name: node.name, isDirectory: node.isDirectory, level: level)
        return [current] + flattenLogs(node.children ?? [], level: level + 1)
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
