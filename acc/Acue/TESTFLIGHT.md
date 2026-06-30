# Acue · TestFlight 发布清单

## 上传前（开发者网站）

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) 已注册：
   - `com.ccKu.Acue`（勾选 **iCloud → CloudKit**，容器 `iCloud.com.ccKu.Acue`）
   - `com.ccKu.Acue.AcueLiveActivity`
2. [App Store Connect](https://appstoreconnect.apple.com) → **我的 App** → **+** → 新建 App：
   - 名称：**Acue**
   - Bundle ID：**com.ccKu.Acue**
   - SKU：随意，如 `acue-ios`
3. [CloudKit Dashboard](https://icloud.developer.apple.com) → 容器 `iCloud.com.ccKu.Acue`：
   - **Development** 环境跑过配对后，点 **Deploy Schema to Production**（TestFlight 用 **Production** 环境）

## Xcode 上传

1. 打开 `Acue.xcodeproj`
2. **Signing**：Team 选**付费开发者团队**（不要 Personal Team）
3. 顶部选 **Any iOS Device (arm64)**（不要选模拟器）
4. **Product → Archive**
5. Organizer 窗口 → **Distribute App** → **App Store Connect** → **Upload**
6. 加密合规：选 **否**（工程已设 `ITSAppUsesNonExemptEncryption = NO`）

## TestFlight 安装

1. App Store Connect → 你的 App → **TestFlight**
2. 构建处理完成后（约 10–30 分钟）→ **内部测试** 或 **外部测试**
3. 添加测试员（你的 Apple ID 邮箱）
4. iPhone 安装 **TestFlight** App → 接受邀请 → 安装 **Acue**

## 构建配置说明

| 配置 | Entitlements | 用途 |
|------|--------------|------|
| **Debug** | `AcuePersonal.entitlements`（无 iCloud） | 模拟器 / 本地调试 |
| **Release** | `Acue.entitlements`（含 CloudKit） | Archive → TestFlight |

## 真机测试配对

- 两台设备都登录 **iCloud**
- TestFlight 版使用 CloudKit **Production** 环境
- 首次配对前务必完成 **Deploy Schema to Production**

## 常见问题

| 问题 | 处理 |
|------|------|
| Archive 报 iCloud capability | 确认网站 App ID 已开 iCloud，Xcode Team 为付费团队 |
| 上传缺图标 | 已提供 1024 图标于 `Assets.xcassets/AppIcon` |
| 配对失败 | CloudKit Production schema 是否已部署 |
| 构建一直 Processing | 等 30 分钟；查邮箱是否有合规邮件 |
