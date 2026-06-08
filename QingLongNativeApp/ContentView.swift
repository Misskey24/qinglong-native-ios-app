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
                    Text("青龙管理")
                        .font(.system(size: 36, weight: .black))
                    Text("原生 iOS 管理端，登录远程青龙后可管理任务、变量、脚本、依赖、订阅、日志和配置。")
                        .foregroundStyle(.secondary)

                    VStack(spacing: 14) {
                        Picker("协议", selection: $useHTTPS) {
                            Text("http://").tag(false)
                            Text("https://").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useHTTPS) { enabled in
                            port = enabled ? "443" : "5700"
                        }

                        TextField("主机或 IP", text: $host)
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
                                Text("登录并读取面板").fontWeight(.bold)
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
            DashboardView().tabItem { Label("首页", systemImage: "house") }
            CronListView().tabItem { Label("任务", systemImage: "play.circle") }
            EnvListView().tabItem { Label("环境", systemImage: "circle.hexagongrid") }
            MoreView().tabItem { Label("更多", systemImage: "ellipsis.circle") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("青龙管理").font(.system(size: 34, weight: .black))
                    Text("面板状态").font(.system(size: 30, weight: .black))
                    Text(client.baseURL.absoluteString).foregroundStyle(.secondary)

                    HStack {
                        metric("定时任务", "\(client.crons.count)")
                        metric("环境变量", "\(client.envs.count)")
                    }
                    HStack {
                        metric("脚本文件", "\(flattenScripts(client.scripts).count)")
                        metric("依赖项目", "\(client.dependencies.count)")
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
            .navigationTitle("青龙")
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
    @State private var editing: CronItem?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            List(client.crons) { cron in
                Button { editing = cron } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(cron.title).fontWeight(.semibold).foregroundStyle(.primary)
                            Spacer()
                            Text(cron.statusText)
                                .font(.caption)
                                .foregroundStyle(cron.isDisabled == 1 ? .red : .green)
                        }
                        Text(cron.subtitle).foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("运行") { Task { await client.runCron(cron) } }.tint(.green)
                    Button("停止") { Task { await client.stopCron(cron) } }.tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button(cron.isDisabled == 1 ? "启用" : "禁用") {
                        Task { await client.toggleCron(cron) }
                    }
                    .tint(cron.isDisabled == 1 ? .green : .red)
                }
            }
            .overlay { if client.crons.isEmpty { EmptyStateView(title: "没有任务数据", subtitle: "下拉刷新或检查登录地址。", icon: "tray") } }
            .navigationTitle("定时任务")
            .refreshable { await client.loadCrons() }
            .toolbar {
                refreshButton { await client.loadCrons() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $editing) { item in CronEditorView(item: item).environmentObject(client) }
            .sheet(isPresented: $creating) { CronEditorView(item: nil).environmentObject(client) }
        }
    }
}

struct EnvListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: EnvItem?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            List(client.envs) { env in
                Button { editing = env } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(env.title).fontWeight(.semibold).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: env.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(env.enabled ? .green : .red)
                        }
                        Text(env.subtitle).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(env.enabled ? "禁用" : "启用") {
                        Task { await client.toggleEnv(env) }
                    }
                    .tint(env.enabled ? .red : .green)
                }
            }
            .overlay { if client.envs.isEmpty { EmptyStateView(title: "没有环境变量", subtitle: "下拉刷新或检查权限。", icon: "tray") } }
            .navigationTitle("环境变量")
            .refreshable { await client.loadEnvs() }
            .toolbar {
                refreshButton { await client.loadEnvs() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $editing) { item in EnvEditorView(item: item).environmentObject(client) }
            .sheet(isPresented: $creating) { EnvEditorView(item: nil).environmentObject(client) }
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
                    Button("刷新全部数据") { Task { await client.refreshAll() } }
                }
                Section("管理") {
                    NavigationLink("脚本文件管理") { ScriptListView().environmentObject(client) }
                    NavigationLink("依赖管理") { DependencyListView().environmentObject(client) }
                    NavigationLink("订阅管理") { SubscriptionListView().environmentObject(client) }
                    NavigationLink("日志查看") { LogListView().environmentObject(client) }
                    NavigationLink("配置文件编辑") { ConfigListView().environmentObject(client) }
                }
            }
            .navigationTitle("更多")
        }
    }
}

struct ScriptListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: TreeRow?
    @State private var creating = false

    var body: some View {
        List(flattenScripts(client.scripts)) { row in
            Button { if !row.isDirectory { editing = row } } label: {
                HStack {
                    Image(systemName: row.isDirectory ? "folder" : "doc.text").foregroundStyle(.green)
                    Text(row.name).padding(.leading, CGFloat(row.level * 14)).foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("脚本文件")
        .refreshable { await client.loadScripts() }
        .toolbar {
            refreshButton { await client.loadScripts() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { row in ScriptEditorView(filename: row.name, isNew: false).environmentObject(client) }
        .sheet(isPresented: $creating) { ScriptEditorView(filename: "", isNew: true).environmentObject(client) }
    }
}

struct DependencyListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: DependencyItem?
    @State private var creating = false

    var body: some View {
        List(client.dependencies) { item in
            Button { editing = item } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.title).fontWeight(.semibold).foregroundStyle(.primary)
                        Spacer()
                        Text(item.statusText).font(.caption).foregroundStyle(.green)
                    }
                    Text(item.subtitle).foregroundStyle(.secondary)
                }
            }
            .swipeActions { Button("重装") { Task { await client.reinstallDependency(item) } }.tint(.green) }
        }
        .navigationTitle("依赖管理")
        .refreshable { await client.loadDependencies() }
        .toolbar {
            refreshButton { await client.loadDependencies() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { item in DependencyEditorView(item: item).environmentObject(client) }
        .sheet(isPresented: $creating) { DependencyEditorView(item: nil).environmentObject(client) }
    }
}

struct SubscriptionListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: SubscriptionItem?
    @State private var creating = false

    var body: some View {
        List(client.subscriptions) { item in
            Button { editing = item } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title).fontWeight(.semibold).foregroundStyle(.primary)
                    Text(item.subtitle).foregroundStyle(.secondary)
                }
            }
            .swipeActions { Button("运行") { Task { await client.runSubscription(item) } }.tint(.green) }
        }
        .navigationTitle("订阅管理")
        .refreshable { await client.loadSubscriptions() }
        .toolbar {
            refreshButton { await client.loadSubscriptions() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { item in SubscriptionEditorView(item: item).environmentObject(client) }
        .sheet(isPresented: $creating) { SubscriptionEditorView(item: nil).environmentObject(client) }
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
        .navigationTitle("日志查看")
        .refreshable { await client.loadLogs() }
        .toolbar { refreshButton { await client.loadLogs() } }
    }
}

struct ConfigListView: View {
    @EnvironmentObject private var client: QingLongClient

    var body: some View {
        List(client.configFiles) { file in
            NavigationLink(file.displayName) {
                ConfigEditorView(name: file.displayName).environmentObject(client)
            }
        }
        .navigationTitle("配置文件")
        .refreshable { await client.loadConfigFiles() }
        .toolbar { refreshButton { await client.loadConfigFiles() } }
    }
}

struct CronEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let item: CronItem?
    @State private var name: String
    @State private var command: String
    @State private var schedule: String

    init(item: CronItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _command = State(initialValue: item?.command ?? "")
        _schedule = State(initialValue: item?.schedule ?? "")
    }

    var body: some View {
        editorShell(title: item == nil ? "新增任务" : "编辑任务") {
            Form {
                TextField("任务名称", text: $name)
                TextField("命令", text: $command)
                TextField("定时规则", text: $schedule)
            }
        } cancel: {
            dismiss()
        } save: {
            await client.saveCron(CronPayload(id: item?.id, name: name, command: command, schedule: schedule, labels: nil))
            dismiss()
        }
    }
}

struct EnvEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let item: EnvItem?
    @State private var name: String
    @State private var value: String
    @State private var remarks: String

    init(item: EnvItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _value = State(initialValue: item?.value ?? "")
        _remarks = State(initialValue: item?.remarks ?? "")
    }

    var body: some View {
        editorShell(title: item == nil ? "新增变量" : "编辑变量") {
            Form {
                TextField("变量名", text: $name)
                TextEditor(text: $value).frame(minHeight: 120)
                TextField("备注", text: $remarks)
            }
        } cancel: {
            dismiss()
        } save: {
            await client.saveEnv(EnvPayload(id: item?.id, name: name, value: value, remarks: remarks))
            dismiss()
        }
    }
}

struct DependencyEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let item: DependencyItem?
    @State private var name: String
    @State private var type: String
    @State private var remarks: String

    init(item: DependencyItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _type = State(initialValue: item?.type ?? "nodejs")
        _remarks = State(initialValue: item?.remarks ?? "")
    }

    var body: some View {
        editorShell(title: item == nil ? "新增依赖" : "编辑依赖") {
            Form {
                TextField("依赖名称", text: $name)
                Picker("类型", selection: $type) {
                    Text("NodeJs").tag("nodejs")
                    Text("Python").tag("python3")
                    Text("Linux").tag("linux")
                }
                TextField("备注", text: $remarks)
            }
        } cancel: {
            dismiss()
        } save: {
            await client.saveDependency(DependencyPayload(id: item?.id, name: name, type: type, remarks: remarks))
            dismiss()
        }
    }
}

struct SubscriptionEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let item: SubscriptionItem?
    @State private var name: String
    @State private var url: String
    @State private var branch: String
    @State private var schedule: String

    init(item: SubscriptionItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _url = State(initialValue: item?.url ?? "")
        _branch = State(initialValue: item?.branch ?? "main")
        _schedule = State(initialValue: item?.schedule ?? "0 2 * * *")
    }

    var body: some View {
        editorShell(title: item == nil ? "新增订阅" : "编辑订阅") {
            Form {
                TextField("订阅名称", text: $name)
                TextField("仓库链接", text: $url)
                TextField("分支", text: $branch)
                TextField("定时规则", text: $schedule)
            }
        } cancel: {
            dismiss()
        } save: {
            await client.saveSubscription(SubscriptionPayload(id: item?.id, name: name, url: url, branch: branch, schedule: schedule))
            dismiss()
        }
    }
}

struct ScriptEditorView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let isNew: Bool
    @State private var filename: String
    @State private var content = ""

    init(filename: String, isNew: Bool) {
        self.isNew = isNew
        _filename = State(initialValue: filename)
    }

    var body: some View {
        editorShell(title: isNew ? "新增脚本" : "编辑脚本") {
            Form {
                TextField("文件名", text: $filename)
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 360)
            }
            .task {
                if !isNew {
                    await client.loadScriptDetail(file: filename)
                    content = client.scriptContent
                }
            }
        } cancel: {
            dismiss()
        } save: {
            await client.saveScript(filename: filename, path: "", content: content)
            dismiss()
        }
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
                Button("保存") { Task { await client.saveConfig(name: name, content: text) } }
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

func editorShell<Content: View>(title: String, @ViewBuilder content: () -> Content, cancel: @escaping () -> Void, save: @escaping () async -> Void) -> some View {
    NavigationStack {
        content()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await save() } }
                }
            }
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
