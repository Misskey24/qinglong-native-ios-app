import SwiftUI
import WebKit

struct ContentView: View {
    @State private var remoteURL: URL?

    var body: some View {
        Group {
            if let remoteURL {
                QingLongWebShell(url: remoteURL) {
                    self.remoteURL = nil
                }
            } else {
                RemoteLoginView { url in
                    remoteURL = url
                }
            }
        }
        .tint(.green)
    }
}

struct RemoteLoginView: View {
    let onConnect: (URL) -> Void

    @State private var useHTTPS = false
    @State private var host = "192.168.1.20"
    @State private var port = "5700"
    @State private var path = "/"
    @State private var errorMessage = ""

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

                        Text("远程青龙")
                            .font(.system(size: 36, weight: .black))

                        Text("输入你的青龙面板地址，App 会直接打开远程面板。登录、任务、环境变量、脚本、日志都在真实服务器上操作。")
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

                        TextField("IP 或域名，例如 192.168.1.20", text: $host)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .fieldStyle()

                        HStack {
                            TextField("端口", text: $port)
                                .keyboardType(.numberPad)
                                .fieldStyle()
                            TextField("路径", text: $path)
                                .textInputAutocapitalization(.never)
                                .fieldStyle()
                                .frame(width: 104)
                        }

                        Text("当前地址：\(previewAddress)")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            connect()
                        } label: {
                            Text("打开青龙面板")
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
                        Text("常用地址")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                        recent("http://192.168.1.20:5700")
                        recent("http://qinglong.local:5700")
                        recent("https://ql.example.com")
                    }
                }
                .padding(18)
            }
            .background(LinearGradient(colors: [.white, Color.green.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            .navigationTitle("远程登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var previewAddress: String {
        let scheme = useHTTPS ? "https" : "http"
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        let defaultPort = useHTTPS ? "443" : "80"
        let portPart = port.isEmpty || port == defaultPort ? "" : ":\(port)"
        return "\(scheme)://\(cleanHost)\(portPart)\(cleanPath)"
    }

    private func connect() {
        guard let url = URL(string: previewAddress), !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "请输入正确的青龙面板地址"
            return
        }
        errorMessage = ""
        onConnect(url)
    }

    private func recent(_ address: String) -> some View {
        Button {
            apply(address)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(address).fontWeight(.semibold)
                    Text(address.hasPrefix("https") ? "HTTPS 远程反代" : "HTTP 局域网 / 内网穿透")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
    }

    private func apply(_ address: String) {
        guard let url = URL(string: address) else { return }
        useHTTPS = url.scheme == "https"
        host = url.host ?? host
        port = url.port.map(String.init) ?? (useHTTPS ? "443" : "5700")
        path = url.path.isEmpty ? "/" : url.path
    }
}

struct QingLongWebShell: View {
    let url: URL
    let onClose: () -> Void

    @StateObject private var model = WebViewModel()

    var body: some View {
        NavigationStack {
            QingLongWebView(url: url, model: model)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(model.title.isEmpty ? "青龙面板" : model.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                        }
                        Button {
                            model.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!model.canGoBack)
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            model.reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            model.goHome(url)
                        } label: {
                            Image(systemName: "house")
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if model.isLoading {
                        ProgressView(value: model.estimatedProgress)
                            .progressViewStyle(.linear)
                    }
                }
        }
    }
}

final class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    weak var webView: WKWebView?
    @Published var title = ""
    @Published var canGoBack = false
    @Published var isLoading = false
    @Published var estimatedProgress = 0.0

    private var observations: [NSKeyValueObservation] = []

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }
        self.webView = webView
        webView.navigationDelegate = self
        observations = [
            webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.title = webView.title ?? ""
                }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoBack = webView.canGoBack
                }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.isLoading = webView.isLoading
                }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.estimatedProgress = webView.estimatedProgress
                }
            }
        ]
    }

    func goBack() {
        webView?.goBack()
    }

    func reload() {
        webView?.reload()
    }

    func goHome(_ url: URL) {
        webView?.load(URLRequest(url: url))
    }
}

struct QingLongWebView: UIViewRepresentable {
    let url: URL
    let model: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        model.attach(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        model.attach(uiView)
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
