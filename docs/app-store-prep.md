# PyBox App Store 上架准备

## 1. App Store Connect API Key 创建指南

前往 https://appstoreconnect.apple.com/access/integrations/api

1. 点击 **+** 新建密钥
2. 名称：`PyBox CI`
3. 权限：`Admin` 或 `Developer`
4. 下载 `.p8` 密钥文件（**只能下载一次，妥善保存**）
5. 记下 **Issuer ID** 和 **Key ID**

创建好后告诉我以下信息，我能继续帮你完成后续步骤：
- **Issuer ID** (格式: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- **Key ID** (格式: `XXXXXXXXXX`)
- **.p8 密钥文件内容**

## 2. App Metadata

### 基本信息

| 字段 | 内容 |
|------|------|
| App Name | PyBox |
| Bundle ID | com.huang.pybox.ide |
| SKU | PYBOX_MVP_1_0 |
| Primary Language | 简体中文 |
| Category | Developer Tools |
| Subcategory | (none) |

### 描述文案

**English Description:**
> PyBox is a modern Python IDE built natively for iOS. Write, run, and debug Python code directly on your iPhone or iPad.
>
> Features:
> - Code editor with syntax highlighting and autocomplete
> - Built-in Python 3.14 runtime with standard library
> - PEP 8 auto-formatting via autopep8
> - Project-based file management
> - Run Python scripts and view output in real-time
> - AI assistant powered by DeepSeek API
> - Terminal with command history
> - Shortcuts & Siri integration
> - Share extension for quick scripts
>
> Whether you're learning Python, prototyping ideas, or need a mobile coding environment, PyBox brings professional-grade Python development to iOS.

**中文描述：**
> PyBox 是一款原生 iOS Python IDE。直接在 iPhone 或 iPad 上编写、运行和调试 Python 代码。
>
> 功能特性：
> - 代码编辑器，支持语法高亮和自动补全
> - 内置 Python 3.14 运行环境与标准库
> - 基于 autopep8 的 PEP 8 自动格式化
> - 基于项目的文件管理
> - 实时运行 Python 脚本并查看输出
> - 基于 DeepSeek API 的 AI 编程助手
> - 终端模拟器，支持命令历史
> - 快捷指令与 Siri 集成
> - 共享扩展，快速编写脚本
>
> 无论你是学习 Python、快速原型开发，还是需要一个移动端编程环境，PyBox 都能将专业级的 Python 开发体验带到 iOS 上。

### 关键词 Keywords

```
Python,IDE,code,editor,programming,script,developer,tools,learn,python3,autopep8,PEP8,AI,coding
```

### 技术支持 URL

```
https://github.com/kingdom7594/pybox
```

### 营销 URL

```
https://pybox.app
```

## 3. 隐私政策

隐私政策页面已在 GitHub Pages 部署：
```
https://kingdom7594.github.io/pybox/privacy/
```

页面内容：

**PyBox Privacy Policy / 隐私政策**

> **Data Collection**
>
> PyBox does not collect any personal data. All code and files you create are stored locally on your device. We do not transmit, share, or sell any user data.
>
> **Third-Party Services**
>
> PyBox integrates with the DeepSeek AI API for code assistance features. When you use the AI assistant, your code snippets and prompts are sent to DeepSeek's servers for processing. No other data is shared with third parties.
>
> **Data Storage**
>
> - Python scripts and projects: stored locally in the app's Documents directory
> - Run history and chat history: stored locally using SQLite
> - Settings: stored in UserDefaults
>
> **Contact**
>
> If you have any questions, please open an issue at https://github.com/kingdom7594/pybox/issues

## 4. 截图素材

截图已在 `docs/screenshots/appstore-*.png` 中生成，共 7 张：

 | 文件名 (jpg-6.5/) | 内容 | 用途 |
|--------------------|------|------|
| appstore-6.5-01-files-tab.jpg | 项目列表 | 第一张截图 |
| appstore-6.5-02-files-list.jpg | 文件列表 | 第二张截图 |
| appstore-6.5-03-editor-loaded.jpg | 代码编辑器 | 第三张截图 |
| appstore-6.5-04-run-output.jpg | 运行输出 | 第四张截图 |
| appstore-6.5-05-format-sheet.jpg | 代码格式化 | 第五张截图 |
| appstore-6.5-06-settings.jpg | 设置页面 | 第六张截图 |
| appstore-6.5-07-ai-assistant.jpg | AI 助手 | 第七张截图 |

规格：**1242x2688, JPEG, sRGB**（6.5" 显示屏标准），上传到 App Store Connect **6.5" Display** 截图区域。

## 5. App Icon

需要准备一个 1024x1024 PNG 应用图标，放入：
`Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

## 6. Xcode GUI 手动 Archive 上架步骤

### 前置条件

1. **Apple Developer Program 账号**（年费 ¥688/¥99）
2. **在 Xcode 中登录账号**：
   - Xcode → Settings → Accounts → 点 `+` → Add Apple ID
   - 输入你的 Apple Developer 账号和密码
3. **App Icon**：准备一张 1024x1024 PNG 放在 `Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

### 步骤 1: 打开项目

```bash
open /Users/xiaowei.huang/app/pybox-ide/PyBox.xcodeproj
```

### 步骤 2: 配置自动签名

1. 在 Xcode 中选择 `PyBox` target → **Signing & Capabilities**
2. ✅ 勾选 **Automatically manage signing**
3. **Team** 下拉选择你的开发者团队
4. 确保 Bundle Identifier 为 `com.pybox.ide`
5. 对 `PyBoxShare` 和 `PyBoxWidget` target 重复以上步骤
5. 选择 **Any iOS Device** 或 **Generic iOS Device** 作为目标设备

### 步骤 3: Archive

- Product → Archive
- 等待构建完成（约 5-10 分钟，取决于 Python 框架大小）
- 构建完成后 Organizer 会自动弹出

### 步骤 4: 上传到 App Store Connect

1. 在 Organizer 中选择刚生成的 Archive
2. 点击右侧 **Distribute App**
3. 选择 **App Store Connect**
4. ⚠️ Upload
5. 选择正确的团队
6. 去掉所有额外选项（bitcode、strip等）
7. 点击 Upload 等待上传完成

### 步骤 5: App Store Connect 配置

1. 打开 https://appstoreconnect.apple.com
2. 进入 **Apps** → 点 `+` → **New App**
3. 填写：
   - Platform: iOS
   - Name: PyBox
   - Primary Language: Simplified Chinese
   - Bundle ID: com.pybox.ide
   - SKU: PYBOX_MVP_1_0
   - User Access: Full Access
4. 在 App Information 页面填写：
   - Subtitle (optional): iOS Python IDE
   - Category: Developer Tools
5. 上传截图（7张 iPhone 6.7" 截图，位于 `docs/screenshots/for-upload/appstore-6.7-*.png`）
6. 填写：
   - 描述、关键词、技术支持URL等（见本文第2节）
   - **隐私政策 URL**: `https://kingdom7594.github.io/pybox/privacy/`

### 步骤 6: TestFlight

1. 在 App Store Connect 中进入 App → TestFlight
2. 添加测试员（内部测试员需要 Apple ID）
3. 构建版本会自动处理，审核通过后即可分发

### 步骤 7: 正式提交

1. App Store Connect → App → 准备提交
2. 选择构建版本
3. 提交审核

## 7. 上架清单

### ✅ 已完成

- [x] **App Icon** (1024x1024 PNG)
  - 已生成并放在 `Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- [x] **App 截图**（7张）
  - 位于 `docs/screenshots/for-upload/`（6.7" PNG / 6.5" JPG / 6.3" 等多尺寸）
- [x] **App 描述文案**（中/英）
  - 见本文第 2 节
- [x] **关键词 Keywords**
  - `Python,IDE,code,editor,programming,script,developer,tools,learn,python3,autopep8,PEP8,AI,coding`
- [x] **隐私政策页面**
  - GitHub Pages 部署: https://kingdom7594.github.io/pybox/privacy/
  - 源码: `pybox-ide/docs/privacy/index.html`

### ⬜ 待处理（你手动操作）

以下步骤需要你在 Xcode 中手动完成（你决定自己操作）：

1. [ ] **Xcode 登录 Apple 账号**
   - Xcode → Settings → Accounts → `+` → Add Apple ID
2. [ ] **Signing & Capabilities 配置自动签名**
   - 选中 `PyBox` target → Signing & Capabilities → 勾选 Automatically manage signing → 选择 Team
   - 对 `PyBoxShare` 和 `PyBoxWidget` 重复
3. [ ] **Product → Archive 构建**
   - 选择 Any iOS Device → Product → Archive
4. [ ] **Distribute App → Upload**
   - Organizer → Distribute App → App Store Connect → Upload
5. [ ] **App Store Connect 创建记录**
   - https://appstoreconnect.apple.com → Apps → `+` → New App
   - Name: PyBox, Bundle ID: com.pybox.ide, SKU: PYBOX_MVP_1_0
6. [ ] **上传截图、填写元数据**
   - 截图: `docs/screenshots/for-upload/appstore-6.7-*.png`
   - 隐私政策 URL: `https://kingdom7594.github.io/pybox/privacy/`
   - 描述、关键词见本文第 2 节
7. [ ] **TestFlight 内测分发**
   - App Store Connect → App → TestFlight → 添加测试员
8. [ ] **正式提交审核**
