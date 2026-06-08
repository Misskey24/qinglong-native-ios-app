# 青龙面板原生 iOS App

这是一个 SwiftUI 原生 iOS App 项目，不是 PWA，也不是网页壳。最低系统版本设置为 iOS 16.5。

它不使用本地演示数据。App 用青龙面板账号密码登录远程服务器，然后调用青龙面板后端接口读取和操作数据。

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
- 青龙用户名/密码登录
- 原生首页，显示远程任务和环境变量数量
- 原生定时任务列表
- 原生环境变量列表
- 任务运行、停止、启用、禁用
- 环境变量启用、禁用
- 支持 HTTP 访问，已在 `Info.plist` 里放开 ATS

## 说明

当前已接入登录、任务、环境变量的核心接口。脚本文件、依赖、订阅、日志、配置文件编辑可以继续按青龙后端接口补齐。

如果你的青龙面板在公网，建议使用 HTTPS 反向代理。HTTP 更适合局域网或内网穿透测试。
