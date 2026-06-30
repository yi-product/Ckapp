# Acue · TestFlight 发布清单

> 若开发者网站里只有旧名 **Accomi**（`com.ccKu.Accomi`），需要**新建** Acue 的 App ID，不能直接把旧 ID 改名。旧 Accomi 可保留不管，不影响 Acue。

## 一、注册新的 App ID（必做）

打开 [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → 右上角 **+**

### 1. 主 App

| 字段 | 填写 |
|------|------|
| 类型 | **App IDs** → App |
| Description | `Acue` |
| Bundle ID | **Explicit** → `com.ccKu.Acue` |
| Capabilities | 勾选 **iCloud** → 选 **CloudKit** → 新建容器 **`iCloud.com.ccKu.Acue`** |

点 **Register** 保存。

### 2. Live Activity Extension

再点 **+** 新建一条：

| 字段 | 填写 |
|------|------|
| Bundle ID | `com.ccKu.Acue.AcueLiveActivity` |
| Capabilities | **不用**勾 iCloud（Extension 不需要） |

### 3. 旧 Accomi 怎么办？

| 旧资源 | 处理 |
|--------|------|
| `com.ccKu.Accomi` | 可留着，不用删 |
| `iCloud.com.ccKu.Accomi` | 与 Acue 无关，配对数据不互通 |
| App Store Connect 里的 Accomi | 若建过可忽略，**新建 Acue App** |

---

## 二、App Store Connect 新建 App

1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → **我的 App** → **+** → 新建 App（**不要**选 Accomi 那条）
2. 名称：**Acue**
3. Bundle ID：选刚注册的 **`com.ccKu.Acue`**
4. SKU：随意，如 `acue-ios`

## 三、CloudKit 容器

1. 打开 [CloudKit Dashboard](https://icloud.developer.apple.com)
2. 确认有容器 **`iCloud.com.ccKu.Acue`**（注册主 App ID 时若已创建则跳过）
3. TestFlight 上线前：在 **Development** 跑通配对后，点 **Deploy Schema to Production**

## 四、在 Xcode 里加 iCloud（解决 ICLOUD could not be determined）

**不要**手写 entitlements 文件。工程默认不含 iCloud，避免签名报错。按下面做：

### 前提（网站先做完）

1. `com.ccKu.Acue` 已注册，勾选 **iCloud → Include CloudKit support**（不要勾 Xcode 5）
2. [CloudKit Dashboard](https://icloud.developer.apple.com) 已有容器 **`iCloud.com.ccKu.Acue`**
3. 编辑 App ID → iCloud → Configure → **勾选**该容器并保存

### Xcode 操作

1. **TARGETS → Acue → Signing & Capabilities**
2. Team 选**付费团队**
3. 点 **+ Capability** → **iCloud**
4. 勾选 **CloudKit**
5. Containers 下点 **+** → 选或创建 **`iCloud.com.ccKu.Acue`**
6. **Settings → Accounts → Download Manual Profiles**
7. **Product → Clean Build Folder** → 再 **Archive**

Xcode 会自动生成 `Acue.entitlements` 并写入工程，与 Apple 后台同步。

> 若仍报 ICLOUD 错误：删掉 Capabilities 里的 iCloud，Clean 后按上面重加；或确认 Bundle ID 与网站完全一致（大小写：`com.ccKu.Acue`）。

---

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
| **Debug / Release（默认）** | `AcuePersonal.entitlements`（空，无 iCloud） | 可 Archive 上传；**配对不可用** |
| **加 Capability 后** | Xcode 自动生成的 `Acue.entitlements` | TestFlight + CloudKit 配对 |

## 真机测试配对

- 两台设备都登录 **iCloud**
- TestFlight 版使用 CloudKit **Production** 环境
- 首次配对前务必完成 **Deploy Schema to Production**

## 常见问题

| 问题 | 处理 |
|------|------|
| Archive 报 iCloud capability / could not be determined | 见上文 **第四节**；不要手写 entitlements，用 Xcode + Capability 添加 |
| 上传缺图标 | 已提供 1024 图标于 `Assets.xcassets/AppIcon` |
| 配对失败 | CloudKit Production schema 是否已部署 |
| 构建一直 Processing | 等 30 分钟；查邮箱是否有合规邮件 |
