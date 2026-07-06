# PyMobile IDE - 产品规划文档

## 1. 产品愿景

**一句话定位**：面向 iOS 的现代 Python 集成开发环境，融合精美 GUI 编辑器与强大终端体验，为移动开发者、数据科学学习者和自动化爱好者提供随时随地的 Python 编程能力。

**品牌名称候选**：
- PyBox - 简洁有力
- PyShell - 强调终端
- PyStudio - 专业定位
- CodePy - 组合词

---

## 2. 目标用户与痛点

### 2.1 目标用户

| 用户群体 | 比例预估 | 核心需求 |
|----------|----------|----------|
| Python 初学者 | 35% | 易于上手、中文界面、教程丰富 |
| 移动开发者/极客 | 25% | 终端访问、自动化脚本、iOS 集成 |
| 数据科学入门者 | 20% | NumPy/Pandas、jupyter 兼容 |
| 教育工作者 | 10% | 课堂演示、学生管理、作业批改 |
| 专业开发者 | 10% | 快速原型、云同步、VS Code 联动 |

### 2.2 用户痛点（基于 Pythonista 评价分析）

```
痛点优先级排序：

P0（必须解决）：
├── 频繁闪退（影响 30%+ 用户）
├── 安装第三方库困难（pandas、pygame 等）
└── 无中文界面（影响中国用户）

P1（重要）：
├── 更新缓慢/长期无维护
├── 不支持 iCloud 同步
├── 无法与电脑端协同

P2（差异化机会）：
├── 无 AI 代码助手
├── 无实时协作
└── 缺乏教程/文档
```

---

## 3. MVP 功能规划

### 3.1 核心功能（Phase 1 - MVP）

#### 编辑器模块
- [ ] Python 3.11+ 运行时（基于 PythonKit）
- [ ] 语法高亮（支持 Python 3.11+ 特性）
- [ ] 代码自动补全
- [ ] 多标签页支持
- [ ] 项目文件浏览器
- [ ] 全局搜索与替换
- [ ] 代码格式化（black/autopep8）

#### 运行模块
- [ ] Python 脚本执行
- [ ] 交互式 REPL 控制台
- [ ] 输出日志面板
- [ ] 运行历史记录
- [ ] 环境变量配置

#### 文件管理
- [ ] iOS Files 应用集成
- [ ] 项目创建/导入/导出
- [ ] 文件夹层级浏览
- [ ] 最近打开项目

#### 基础 iOS 集成
- [ ] Shortcuts 应用集成
- [ ] 分享菜单扩展（Share Sheet）
- [ ] 通知中心小组件

### 3.2 预装库清单

```
标准库（内置）：
├── json, xml, html, re
├── os, sys, pathlib, shutil
├── datetime, time, calendar
├── math, random, itertools
├── urllib, http, ssl
└── sqlite3, csv, configparser

科学计算（预装）：
├── numpy>=1.24
├── matplotlib>=3.8
└── pandas>=2.0

可选安装（按需）：
├── scipy
├── scikit-learn
├── pillow
├── requests
└── tqdm
```

---

## 4. 差异化功能（Phase 2）

### 4.1 AI 助手集成
```
功能：
├── 代码补全建议（基于 DeepSeek API）
├── 代码解释/注释生成
├── Bug 检测与修复建议
├── 翻译注释（中英互译）
└── 文档查询

技术方案：
├── 对接 DeepSeek API（已有 key）
├── 本地缓存常用问答
├── 离线模式支持基础功能
└── 隐私模式（不上传代码）
```

### 4.2 云端同步
```
功能：
├── iCloud Drive 项目同步
├── GitHub/GitLab 仓库同步
├── 跨设备草稿同步
└── 版本历史记录

技术方案：
├── 利用 iOS CloudKit API
├── Git SSH/HTTPS 协议支持
└── 冲突解决机制
```

### 4.3 VS Code 远程协作
```
功能：
├── WiFi 连接到 VS Code
├── 实时代码同步
├── VS Code 终端映射
└── 远程调试

技术方案：
├── 基于 WebSocket
├── 自定义 VS Code 扩展
└── p2p 连接（无需服务器）
```

---

## 5. UI/UX 设计方向

### 5.1 设计语言

**风格**：Modern Minimal + Developer Focus

```
设计原则：
1. 功能密度适中 - 不过于极简，也不过于拥挤
2. 暗色主题优先 - 开发者习惯，护眼
3. 触控优化 - 按钮 44pt+，间距合理
4. 可发现性 - 常用功能一目了然
```

### 5.2 配色方案

```
Primary:     #6366F1 (Indigo - 主操作)
Secondary:   #22D3EE (Cyan - 终端/代码)
Accent:      #F59E0B (Amber - 警告/高亮)
Success:     #10B981 (Green - 成功)
Error:       #EF4444 (Red - 错误)

背景色：
Dark:        #0F172A (主背景)
Dark+:       #1E293B (卡片/面板)
Dark++:      #334155 (输入框/高亮)

文字色：
Primary:     #F8FAFC (主要)
Secondary:   #94A3B8 (次要)
Muted:       #64748B (占位符)
```

### 5.3 布局结构

```
┌─────────────────────────────────────┐
│  Navigation Bar                     │
│  [≡] Project Name     [▶] [⚙] [AI] │
├─────────────────────────────────────┤
│                                     │
│  Code Editor Area                   │
│  (可折叠文件浏览器)                  │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  Bottom Toolbar                     │
│  [文件] [运行] [终端] [AI] [更多]    │
└─────────────────────────────────────┘

终端模式（全屏）：
┌─────────────────────────────────────┐
│  [×] Terminal - main.py    [⌨] [📋]│
├─────────────────────────────────────┤
│  $ python main.py                   │
│  Hello World!                       │
│                                     │
│                                     │
│                                     │
│  ─────────────────────────────────  │
│  [虚拟键盘 + 功能键行]               │
└─────────────────────────────────────┘
```

### 5.4 关键界面

| 界面 | 核心元素 |
|------|----------|
| **主编辑页** | 文件树、代码区、输出面板 |
| **文件浏览器** | 层级列表、收藏夹、最近 |
| **运行面板** | 输出日志、错误追溯、停止按钮 |
| **AI 助手** | 对话式界面、代码高亮插入 |
| **设置页** | 主题、快捷键、账户、云同步 |
| **新手引导** | 3 步上手、示例项目、教程入口 |

---

## 6. 技术架构

### 6.1 整体架构

```
┌─────────────────────────────────────────────────────┐
│                    Presentation Layer               │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ SwiftUI  │  │  UIKit   │  │  CodeMirror 6    │  │
│  │  Views   │  │  Views   │  │  (Web Editor)    │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────┤
│                    Business Logic Layer            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Python   │  │  File     │  │    AI Service    │  │
│  │ Runtime  │  │  Manager  │  │   (DeepSeek)     │  │
│  │ Service  │  │  Service  │  │                  │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────┤
│                    Data Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ PythonKit │  │ CloudKit  │  │   Keychain       │  │
│  │ (Embedded)│  │  (iCloud) │  │   (Credentials)  │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────┤
│                    Platform Layer                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  iOS SDK │  │  Files    │  │   Shortcuts      │  │
│  │          │  │  App API  │  │   Integration    │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### 6.2 技术选型

| 模块 | 技术选型 | 说明 |
|------|----------|------|
| **原生框架** | SwiftUI + UIKit | SwiftUI 为主，UIKit 用于复杂手势 |
| **代码编辑器** | CodeMirror 6 (Web) | 成熟、跨平台、插件丰富 |
| **Python 运行时** | PythonKit | Apple 官方，支持 pip |
| **状态管理** | Swift Concurrency | async/await + Actors |
| **本地存储** | SQLite.swift | 项目配置、运行历史 |
| **云同步** | CloudKit | iCloud 集成 |
| **AI 服务** | DeepSeek API | 已有 key |
| **布局引擎** | SnapKit | UIKit Auto Layout |
| **网络层** | URLSession | AI API 调用 |
| **代码高亮** | highlight.js / Prism | 输出日志高亮 |

### 6.3 核心模块设计

#### PythonRuntimeService
```swift
class PythonRuntimeService {
    // 单例模式，管理 Python 进程
    func execute(script: String) async throws -> ExecutionResult
    func startREPL() async -> AsyncStream<String>
    func installPackage(name: String) async throws
    func getInstalledPackages() -> [Package]
}
```

#### FileManagerService
```swift
class FileManagerService {
    // 项目文件管理
    func listProjects() -> [Project]
    func createProject(name: String) async throws -> Project
    func importFromFilesApp(url: URL) async throws
    func exportToFilesApp(project: Project) async throws
}
```

#### AIService
```swift
class AIService {
    // DeepSeek API 封装
    func completeCode(context: CodeContext) async throws -> String
    func explainCode(code: String) async throws -> String
    func suggestFix(error: PythonError) async throws -> Fix
}
```

### 6.4 项目结构

```
PyMobileIDE/
├── App/
│   ├── PyMobileIDEApp.swift
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Features/
│   ├── Editor/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── Terminal/
│   ├── FileBrowser/
│   ├── AIAssistant/
│   └── Settings/
├── Core/
│   ├── Python/
│   │   ├── PythonRuntimeService.swift
│   │   ├── REPLManager.swift
│   │   └── PackageManager.swift
│   ├── FileManager/
│   ├── CloudSync/
│   └── AI/
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   ├── Theme/
│   └── Utils/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Python/
│       └── stdlib/  (嵌入式 Python)
└── Tests/
```

---

## 7. 开发计划

### Phase 1：基础能力（8-10 周）

```
Week 1-2: 项目初始化
├── 项目模板搭建
├── SwiftUI 架构搭建
├── CodeMirror 集成
└── 文件系统搭建

Week 3-4: 编辑器核心
├── 代码高亮
├── 基础补全
├── 文件浏览器
└── 项目 CRUD

Week 5-6: Python 运行时
├── PythonKit 集成
├── 脚本执行
├── REPL 控制台
└── 输出面板

Week 7-8: iOS 集成
├── Files 应用集成
├── Shortcuts 集成
├── 分享扩展
└── 小组件

Week 9-10: 测试与优化
├── Beta 测试
├── 闪退修复
├── 性能优化
└── App Store 准备
```

### Phase 2：差异化（6-8 周）

```
Week 11-12: AI 助手
├── DeepSeek API 集成
├── 代码补全
├── 错误解释
└── 隐私模式

Week 13-14: 云同步
├── iCloud 集成
├── 项目同步
└── 冲突解决

Week 15-16: 增强功能
├── 代码格式化
├── Git 基础支持
├── 主题定制
└── 快捷键配置
```

### Phase 3：生态（4-6 周）

```
Week 17-18: VS Code 协作
├── WiFi 连接协议
├── 实时同步
└── VS Code 扩展

Week 19-20: 社区功能
├── 代码分享
├── 教程系统
└── 社区论坛
```

---

## 8. 关键指标（KPIs）

### 8.1 产品指标

| 指标 | 目标值 | 测量方式 |
|------|--------|----------|
| DAU | 5,000+ | Analytics |
| 次日留存 | 40%+ | Analytics |
| 7 日留存 | 25%+ | Analytics |
| 付费转化 | 5%+ | StoreKit |
| NPS 分数 | 50+ | 问卷调查 |

### 8.2 技术指标

| 指标 | 目标值 | 测量方式 |
|------|--------|----------|
| 启动时间 | < 2s | Instruments |
| 编辑响应 | < 50ms | Performance |
| 脚本执行 | 与 Pythonista 持平 | Benchmark |
| 闪退率 | < 0.5% | Crashlytics |
| 内存占用 | < 200MB | Instruments |

---

## 9. 风险与应对

| 风险 | 影响 | 应对策略 |
|------|------|----------|
| PythonKit 功能限制 | 高 | 提前验证，备选 PythonKit 的 C 扩展方案 |
| App Store 审核拒绝 | 中 | 预研 Apple 政策，准备 Appeal |
| DeepSeek API 成本 | 中 | 设计缓存策略，设置用量上限 |
| 竞品免费压力 | 中 | Freemium 模式，差异化功能 |
| iOS 版本兼容 | 低 | 支持 iOS 16+，逐步适配 |

---

## 10. 附录

### 10.1 参考资源

- [Pythonista 3](https://apps.apple.com/cn/app/pythonista-3/id1085978097)
- [a-Shell](https://apps.apple.com/cn/app/a-shell/id1473800423)
- [PythonKit](https://github.com/pvieito/PythonKit)
- [CodeMirror 6](https://codemirror.net/)

### 10.2 术语表

| 术语 | 定义 |
|------|------|
| REPL | Read-Eval-Print Loop，交互式解释器 |
|_stdlib | Python 标准库 |
| pip | Python 包管理器 |
| CloudKit | Apple 的 iCloud 后端服务 |
| Shortcuts | iOS 自动化应用（原 Workflow） |
