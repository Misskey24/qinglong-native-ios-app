import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabs()
            } else {
                LoginView {
                    isLoggedIn = true
                }
            }
        }
        .tint(.green)
    }
}

struct LoginView: View {
    let onLogin: () -> Void
    @State private var useHTTPS = false
    @State private var authMode = 0
    @State private var host = "192.168.1.20"
    @State private var port = "5700"
    @State private var username = "admin"
    @State private var password = "qinglong"
    @State private var clientID = "openapi-mobile"
    @State private var clientSecret = "demo-secret"

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

                        Text("远程登录")
                            .font(.system(size: 36, weight: .black))
                        Text("支持 http 和 https 青龙面板地址，适合局域网、域名反代和公网远程访问。")
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
                            host = enabled ? "ql.example.com" : "192.168.1.20"
                            port = enabled ? "443" : "5700"
                        }

                        TextField("IP 或域名", text: $host)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .fieldStyle()

                        HStack {
                            TextField("端口", text: $port)
                                .keyboardType(.numberPad)
                                .fieldStyle()
                            TextField("路径", text: .constant("/"))
                                .fieldStyle()
                                .frame(width: 92)
                        }

                        Picker("登录方式", selection: $authMode) {
                            Text("账号登录").tag(0)
                            Text("OpenAPI").tag(1)
                        }
                        .pickerStyle(.segmented)

                        if authMode == 0 {
                            TextField("用户名", text: $username)
                                .fieldStyle()
                            SecureField("密码", text: $password)
                                .fieldStyle()
                        } else {
                            TextField("Client ID", text: $clientID)
                                .fieldStyle()
                            SecureField("Client Secret", text: $clientSecret)
                                .fieldStyle()
                        }

                        Text("当前连接预览：\(useHTTPS ? "https" : "http")://\(host):\(port)")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button(action: onLogin) {
                            Text("登录面板")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.06), radius: 18, y: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近连接")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                        recent("http://192.168.1.20:5700", detail: "局域网青龙 · 账号登录")
                        recent("https://ql.example.com", detail: "远程反代 · OpenAPI")
                    }
                }
                .padding(18)
            }
            .background(LinearGradient(colors: [.white, Color.green.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("远程登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func recent(_ title: String, detail: String) -> some View {
        Button {
            useHTTPS = title.hasPrefix("https")
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).fontWeight(.semibold)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house") }
            TaskListView()
                .tabItem { Label("任务", systemImage: "play.circle") }
            EnvListView()
                .tabItem { Label("环境", systemImage: "circle.hexagongrid") }
            ScriptListView()
                .tabItem { Label("脚本", systemImage: "doc.text") }
            MoreView()
                .tabItem { Label("更多", systemImage: "ellipsis.circle") }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("所有功能")
                        .font(.system(size: 34, weight: .black))
                    Text("已连接 qinglong.local，任务队列运行正常。")
                        .foregroundStyle(.secondary)

                    SummaryCard()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FeatureCard(icon: "play.fill", title: "定时任务", subtitle: "编辑、运行、置顶、禁用")
                        FeatureCard(icon: "circle.hexagongrid.fill", title: "环境变量", subtitle: "新增、搜索、批量、启停")
                        FeatureCard(icon: "doc.text.fill", title: "脚本管理", subtitle: "多层级显示、新增文件")
                        FeatureCard(icon: "checkmark.circle.fill", title: "依赖文件", subtitle: "添加、重装、常用依赖")
                        FeatureCard(icon: "arrow.triangle.2.circlepath", title: "订阅管理", subtitle: "仓库拉取、定时同步")
                        FeatureCard(icon: "gearshape.fill", title: "系统设置", subtitle: "通知、安全、应用、更新")
                    }
                }
                .padding(18)
            }
            .navigationTitle("青龙面板")
        }
    }
}

struct SummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("面板状态").font(.headline)
            HStack {
                metric("定时任务", "128")
                metric("运行中", "3")
                metric("环境变量", "24")
            }
        }
        .padding(16)
        .background(LinearGradient(colors: [Color.green.opacity(0.13), .white], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.green.opacity(0.18)))
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct TaskListView: View {
    var body: some View {
        NavigationStack {
            List(DemoData.tasks) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name).fontWeight(.semibold)
                        Text(item.status)
                            .font(.caption)
                            .foregroundStyle(item.status == "已禁用" ? .red : .green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((item.status == "已禁用" ? Color.red : Color.green).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Text(item.cron).foregroundStyle(.secondary)
                    Text(item.file).font(.caption).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("运行") {}
                    Button("禁用", role: .destructive) {}
                }
            }
            .navigationTitle("定时任务")
            .toolbar {
                Button { } label: { Image(systemName: "plus") }
            }
        }
    }
}

struct EnvListView: View {
    var body: some View {
        NavigationStack {
            List(DemoData.envs) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.key).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: item.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.enabled ? .green : .red)
                    }
                    Text(item.note).foregroundStyle(.secondary)
                    Text(item.value).font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("环境变量")
            .toolbar {
                Button { } label: { Image(systemName: "plus") }
            }
        }
    }
}

struct ScriptListView: View {
    var body: some View {
        NavigationStack {
            List(DemoData.scripts) { item in
                HStack {
                    Image(systemName: item.isFolder ? "folder" : "doc")
                        .foregroundStyle(.green)
                    Text(item.name)
                        .padding(.leading, CGFloat(item.level * 18))
                    Spacer()
                    if item.isFolder {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("脚本管理")
            .toolbar {
                Button { } label: { Image(systemName: "plus") }
            }
        }
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("管理") {
                    NavigationLink("依赖文件") { DependencyView() }
                    NavigationLink("订阅管理") { SubscriptionView() }
                    NavigationLink("日志管理") { LogView() }
                    NavigationLink("配置文件") { ConfigEditorView() }
                }
                Section("系统") {
                    NavigationLink("通知设置") { Text("PushPlus / Telegram / 企业微信") }
                    NavigationLink("应用授权") { Text("OpenAPI Client ID / Secret") }
                    NavigationLink("登录日志") { Text("最近登录记录") }
                }
            }
            .navigationTitle("更多")
        }
    }
}

struct DependencyView: View {
    var body: some View {
        List(DemoData.dependencies) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).fontWeight(.semibold)
                Text("\(item.type) · \(item.installedAt)").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("依赖文件")
    }
}

struct SubscriptionView: View {
    var body: some View {
        List {
            Text("faker2_main · main · 0 2 * * *")
            Text("KingRan_KR · main · 10 3 * * *")
            Text("smzdm_script · master · 25 6 * * *")
        }
        .navigationTitle("订阅管理")
    }
}

struct LogView: View {
    var body: some View {
        List {
            Text("shufflewzc_faker2_main")
            Text("2025-03-08-14-00-00.log")
            Text("2025-03-08-03-00-00.log")
        }
        .navigationTitle("日志管理")
    }
}

struct ConfigEditorView: View {
    @State private var text = """
    ## ql repo 命令拉取文件后缀
    RepoFileExtensions="js py ts"

    ## 代理地址，支持 HTTP / SOCKS5
    ProxyUrl="127.0.0.1:7890"

    ## 资源告警阈值
    CpuWarn=80
    MemoryWarn=80
    DiskWarn=90
    """

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .padding()
            .navigationTitle("config.sh")
            .toolbar {
                Button("保存") {}
            }
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
