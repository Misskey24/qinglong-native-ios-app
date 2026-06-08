# 青龙面板原生 iOS App

这是一个 SwiftUI + WKWebView 原生 iOS App 项目，不是 PWA。最低系统版本设置为 iOS 16.5。

它不使用 OpenAPI，也不使用本地演示数据。App 会加载你输入的远程青龙面板地址，因此登录、任务、环境变量、脚本、日志等操作都发生在真实青龙服务器上。

## GitHub 打包无签名 IPA

1. 在 GitHub 新建仓库。
2. 上传本目录所有文件到仓库根目录。
3. 打开仓库的 `Actions`。
4. 选择 `Build unsigned IPA`。
5. 点击 `Run workflow`。
6. 构建完成后，在页面底部 `Artifacts` 下载 `QingLongNativeApp-unsigned-ipa`。

下载得到的 `QingLongNativeApp-unsigned.ipa` 是未签名 IPA，可用于 TrollStore 安装。

## 当前功能

- 远程青龙地址输入，支持 `http` 和 `https`
- 支持端口和路径，例如 `http://192.168.1.20:5700/`
- 原生顶部工具栏：关闭、返回、刷新、回首页
- 直接操作真实青龙面板网页
- 支持 HTTP 访问，已在 `Info.plist` 里放开 ATS

## 说明

如果你的青龙面板在公网，建议使用 HTTPS 反向代理。HTTP 更适合局域网或内网穿透测试。
