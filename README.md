# 青龙面板原生 iOS App

这是一个 SwiftUI 原生 iOS App 项目，不是网页/PWA。最低系统版本设置为 iOS 16.5。

## GitHub 打包无签名 IPA

1. 在 GitHub 新建仓库。
2. 上传本目录所有文件到仓库根目录。
3. 打开仓库的 `Actions`。
4. 选择 `Build unsigned IPA`。
5. 点击 `Run workflow`。
6. 构建完成后，在页面底部 `Artifacts` 下载 `QingLongNativeApp-unsigned-ipa`。

下载得到的 `QingLongNativeApp-unsigned.ipa` 是未签名 IPA，可用于 TrollStore 安装。

## 当前功能

- 远程登录页，支持 `http` 和 `https`
- 账号密码 / OpenAPI 登录方式切换
- 首页状态面板
- 定时任务列表
- 环境变量列表
- 脚本管理列表
- 依赖、订阅、日志、配置编辑入口

## 说明

当前是原生 UI 原型，列表数据是本地演示数据。后续要真实连接青龙，需要接入青龙 OpenAPI，请求登录、任务、环境变量、脚本、依赖、日志等接口。
