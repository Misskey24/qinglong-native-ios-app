import SwiftUI
import UniformTypeIdentifiers

private let qlAccentColor = Color(red: 1.0, green: 0.28, blue: 0.55)

struct ScriptTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

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
        .tint(qlAccentColor)
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
                    Text("支持多个青龙面板。登录状态会一直保留，直到你手动退出。")
                        .foregroundStyle(.secondary)

                    loginCard

                    if !client.accounts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("已保存面板")
                                .font(.footnote.bold())
                                .foregroundStyle(.secondary)
                            ForEach(client.accounts) { account in
                                Button {
                                    Task { await client.switchAccount(account) }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.name).fontWeight(.semibold)
                                            Text(account.baseURL.absoluteString)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(qlAccentColor)
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(LinearGradient(colors: [.white, qlAccentColor.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("远程登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var loginCard: some View {
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
                .foregroundStyle(qlAccentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(qlAccentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if let visibleError = client.visibleErrorMessage {
                Text(visibleError)
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

                    if let visibleError = client.visibleErrorMessage {
                        Text(visibleError)
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
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(qlAccentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CronListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: CronItem?
    @State private var showingLog: CronItem?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            List(client.crons) { cron in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cron.title).fontWeight(.semibold).foregroundStyle(.primary)
                            Text(cron.subtitle).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = cron }

                        CronStatusBadge(cron: cron) {
                            showingLog = cron
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task { await client.runCron(cron) }
                    } label: {
                        Text("运行")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(qlAccentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(qlAccentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .swipeActions(edge: .leading) {
                    Button("运行") { Task { await client.runCron(cron) } }.tint(qlAccentColor)
                    Button("停止") { Task { await client.stopCron(cron) } }.tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button(cron.isDisabled == 1 ? "启用" : "禁用") {
                        Task { await client.toggleCron(cron) }
                    }
                    .tint(cron.isDisabled == 1 ? qlAccentColor : .red)
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
            .sheet(item: $showingLog) { item in CronLogDetailView(cron: item).environmentObject(client) }
            .sheet(isPresented: $creating) { CronEditorView(item: nil).environmentObject(client) }
            .task {
                await autoRefreshCrons()
            }
        }
    }

    private func autoRefreshCrons() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if Task.isCancelled { break }
            await client.loadCrons()
        }
    }
}

struct CronStatusBadge: View {
    let cron: CronItem
    var onOpenLog: (() -> Void)? = nil

    private var title: String {
        if cron.isCronDisabled { return "已禁用" }
        if cron.isCronRunning { return "运行中" }
        return "空闲中"
    }

    private var tint: Color {
        if cron.isCronDisabled { return .red }
        if cron.isCronRunning { return .blue }
        return .primary
    }

    @ViewBuilder
    var body: some View {
        if cron.isCronRunning, let onOpenLog {
            Button(action: onOpenLog) {
                badgeContent
            }
            .buttonStyle(.plain)
        } else {
            badgeContent
        }
    }

    private var badgeContent: some View {
        HStack(spacing: 5) {
            if cron.isCronRunning {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 14, height: 14)
                    .tint(tint)
            } else {
                Image(systemName: cron.isCronDisabled ? "xmark.circle" : "clock")
                    .font(.caption)
            }
            Text(title)
                .font(.caption)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct CronLogDetailView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let cron: CronItem

    var body: some View {
        NavigationStack {
            Group {
                if client.isLoading && client.cronLogContent.isEmpty {
                    ProgressView("正在读取运行日志")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if client.cronLogContent.isEmpty {
                    EmptyStateView(title: "暂无运行日志", subtitle: "请确认任务仍在执行，或稍后刷新。", icon: "doc.text.magnifyingglass")
                } else {
                    ScrollView {
                        Text(client.cronLogContent)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .background(Color(.secondarySystemBackground))
                }
            }
            .navigationTitle(cron.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await client.loadCronLog(cron) } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                client.cronLogContent = ""
                await autoRefreshLog()
            }
        }
    }

    private func autoRefreshLog() async {
        while !Task.isCancelled {
            await client.loadCronLog(cron)
            await client.loadCrons()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
                                .foregroundStyle(env.enabled ? qlAccentColor : .red)
                        }
                        Text(env.subtitle).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(env.enabled ? "禁用" : "启用") {
                        Task { await client.toggleEnv(env) }
                    }
                    .tint(env.enabled ? .red : qlAccentColor)
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
                    if !client.accounts.isEmpty {
                        ForEach(client.accounts) { account in
                            Button {
                                Task { await client.switchAccount(account) }
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.name)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text(account.baseURL.absoluteString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(account.username)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if client.selectedAccountID == account.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(qlAccentColor)
                                    }
                                }
                            }
                            .swipeActions {
                                Button("删除", role: .destructive) { client.removeAccount(account) }
                            }
                        }
                    }
                    Button("添加青龙面板") { client.beginAddingPanel() }
                    Button("退出当前面板", role: .destructive) { client.logoutCurrentAccount() }
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

struct AccountManagerView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("已保存面板") {
                    ForEach(client.accounts) { account in
                        Button {
                            Task {
                                await client.switchAccount(account)
                                dismiss()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(account.name).fontWeight(.semibold).foregroundStyle(.primary)
                                    if client.selectedAccountID == account.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(qlAccentColor)
                                    }
                                }
                                Text(account.baseURL.absoluteString).font(.caption).foregroundStyle(.secondary)
                                Text(account.username).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("删除", role: .destructive) { client.removeAccount(account) }
                        }
                    }
                }
            }
            .navigationTitle("面板管理")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct ScriptListView: View {
    @EnvironmentObject private var client: QingLongClient
    @State private var editing: TreeRow?
    @State private var renaming: TreeRow?
    @State private var renameName = ""
    @State private var debugging: TreeRow?
    @State private var creating = false
    @State private var importing = false
    @State private var exporting = false
    @State private var exportDocument = ScriptTextDocument()
    @State private var exportName = "script.js"

    var body: some View {
        List(flattenScripts(client.scripts)) { row in
            Button { if !row.isDirectory { editing = row } } label: {
                HStack {
                    Image(systemName: row.isDirectory ? "folder" : "doc.text").foregroundStyle(qlAccentColor)
                    Text(row.name).padding(.leading, CGFloat(row.level * 14)).foregroundStyle(.primary)
                }
            }
            .swipeActions(edge: .leading) {
                if !row.isDirectory {
                    Button("调试") { debugging = row }.tint(.orange)
                }
            }
            .swipeActions(edge: .trailing) {
                if !row.isDirectory {
                    Button("下载") { Task { await prepareDownload(row) } }.tint(qlAccentColor)
                    Button("改名") {
                        renameName = row.name
                        renaming = row
                    }
                    .tint(.blue)
                    Button("删除", role: .destructive) {
                        Task { await client.deleteScript(filename: row.name) }
                    }
                }
            }
        }
        .navigationTitle("脚本文件")
        .refreshable { await client.loadScripts() }
        .toolbar {
            refreshButton { await client.loadScripts() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { creating = true } label: {
                        Label("新建脚本", systemImage: "doc.badge.plus")
                    }
                    Button { importing = true } label: {
                        Label("从本地上传", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editing) { row in ScriptEditorView(filename: row.name, isNew: false).environmentObject(client) }
        .sheet(item: $renaming) { row in
            RenameScriptView(row: row, name: $renameName).environmentObject(client)
        }
        .sheet(item: $debugging) { row in
            ScriptDebugView(row: row).environmentObject(client)
        }
        .sheet(isPresented: $creating) { ScriptEditorView(filename: "", isNew: true).environmentObject(client) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            importScript(result)
        }
        .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .plainText, defaultFilename: exportName) { result in
            if case .failure(let error) = result {
                client.errorMessage = error.localizedDescription
            }
        }
    }

    private func importScript(_ result: Result<[URL], Error>) {
        Task {
            do {
                guard let url = try result.get().first else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer {
                    if scoped { url.stopAccessingSecurityScopedResource() }
                }
                let data = try Data(contentsOf: url)
                let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) ?? ""
                await client.uploadScript(filename: url.lastPathComponent, content: content)
            } catch {
                client.errorMessage = error.localizedDescription
            }
        }
    }

    private func prepareDownload(_ row: TreeRow) async {
        let content = await client.downloadScript(filename: row.name)
        exportName = row.name
        exportDocument = ScriptTextDocument(text: content)
        exporting = true
    }
}

struct RenameScriptView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let row: TreeRow
    @Binding var name: String

    var body: some View {
        editorShell(title: "脚本改名", cancel: { dismiss() }) {
            Form {
                TextField("文件名", text: $name)
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
            }
        } save: {
            await client.renameScript(filename: row.name, newFilename: name)
            dismiss()
        }
    }
}

struct ScriptDebugView: View {
    @EnvironmentObject private var client: QingLongClient
    @Environment(\.dismiss) private var dismiss
    let row: TreeRow

    var body: some View {
        NavigationStack {
            Group {
                if client.isLoading && client.scriptDebugOutput.isEmpty {
                    ProgressView("正在调试脚本")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(client.scriptDebugOutput.isEmpty ? "暂无调试输出" : client.scriptDebugOutput)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .background(Color(.secondarySystemBackground))
                }
            }
            .navigationTitle(row.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await client.debugScript(filename: row.name) } } label: {
                        Image(systemName: "play.fill")
                    }
                }
            }
            .task {
                await autoRefreshDebugLog()
            }
        }
    }

    private func autoRefreshDebugLog() async {
        await client.debugScript(filename: row.name)
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled { break }
            await client.refreshScriptDebugLog()
        }
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
                        Text(item.statusText).font(.caption).foregroundStyle(qlAccentColor)
                    }
                    Text(item.subtitle).foregroundStyle(.secondary)
                }
            }
            .swipeActions { Button("重装") { Task { await client.reinstallDependency(item) } }.tint(qlAccentColor) }
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
            .swipeActions { Button("运行") { Task { await client.runSubscription(item) } }.tint(qlAccentColor) }
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
                Image(systemName: row.isDirectory ? "folder" : "doc.text").foregroundStyle(qlAccentColor)
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
        editorShell(title: item == nil ? "新增任务" : "编辑任务", cancel: { dismiss() }) {
            Form {
                TextField("任务名称", text: $name)
                TextField("命令", text: $command)
                TextField("定时规则", text: $schedule)
            }
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
        editorShell(title: item == nil ? "新增变量" : "编辑变量", cancel: { dismiss() }) {
            Form {
                TextField("变量名", text: $name)
                TextEditor(text: $value).frame(minHeight: 120)
                TextField("备注", text: $remarks)
            }
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
        editorShell(title: item == nil ? "新增依赖" : "编辑依赖", cancel: { dismiss() }) {
            Form {
                TextField("依赖名称", text: $name)
                Picker("类型", selection: $type) {
                    Text("NodeJs").tag("nodejs")
                    Text("Python").tag("python3")
                    Text("Linux").tag("linux")
                }
                TextField("备注", text: $remarks)
            }
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
        editorShell(title: item == nil ? "新增订阅" : "编辑订阅", cancel: { dismiss() }) {
            Form {
                TextField("订阅名称", text: $name)
                TextField("仓库链接", text: $url)
                TextField("分支", text: $branch)
                TextField("定时规则", text: $schedule)
            }
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
    @State private var isLoading = false

    init(filename: String, isNew: Bool) {
        self.isNew = isNew
        _filename = State(initialValue: filename)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("文件名", text: $filename)
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(.secondarySystemBackground))

                if isLoading {
                    ProgressView("正在加载脚本内容")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TextEditor(text: $content)
                        .font(.system(size: 14, design: .monospaced))
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .padding(8)
                }

                HStack {
                    Text("\(content.components(separatedBy: .newlines).count) 行")
                    Spacer()
                    Text("\(content.count) 字符")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle(isNew ? "新增脚本" : "编辑脚本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await client.saveScript(filename: filename, path: "", content: content)
                            dismiss()
                        }
                    }
                }
            }
            .task {
                guard !isNew else { return }
                isLoading = true
                await client.loadScriptDetail(file: filename)
                content = client.scriptContent
                isLoading = false
            }
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

func editorShell<Content: View>(title: String, cancel: @escaping () -> Void, @ViewBuilder content: () -> Content, save: @escaping () async -> Void) -> some View {
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
