# PyBox UI/UE 视觉打磨 - 现状与 v3 原型 Gap 分析

> 时间：2026-07-05
> 来源：v3 原型 `python-ide-ios-3.html` + 当前 PyBox SwiftUI 实现
> 范围：仅 UI/UE 视觉打磨，不动功能逻辑

---

## 0. 全局问题（影响所有 Tab）

### 0.1 颜色体系严重错位

| 维度 | 当前实现 | v3 原型规范 | 差异 |
|---|---|---|---|
| 主背景 | `#0F172A`（Slate-900） | `#040704`（emerald bg，极深绿黑） | 当前偏蓝灰，原型偏深绿黑；层级更分明 |
| Surface | `#1E293B`（Slate-800） | `#0A0F0B`（emerald surface） | 当前太亮，破坏了"暗色为主"的感觉 |
| SurfaceElevated | `#334155`（Slate-700） | `#19221B`（surface3） | 同上 |
| 主品牌色 | `#6366F1`（Indigo-500） | `#00A245`（emerald accent，Python 绿） | **关键差异**！当前是靛蓝，原型是 Python 绿。这与"Python IDE"定位不符 |
| 强调色 | `#F59E0B`（Amber） | 同色域 | 差异小 |
| 文本主色 | `#F8FAFC` | `#E9E8E4` | 接近 |
| 文本次色 | `#94A3B8` | `#74716B` | 原型更暖 |

**结论**：当前是 **Slate/Indigo** 体系（generic iOS app），原型是 **Emerald/Custom** 体系（Python 主题）。**这是最大的视觉 gap**。

### 0.2 TabBar 视觉

- **当前**：SwiftUI 默认 `TabView` + `.tint(primary)` + UIKit `UITabBarAppearance` 注入 `surface` 背景
- **v3 原型**：
  - 容器背景 `var(--tab-bar-bg)`（比 surface 略深）
  - top border 1px `var(--border)`
  - padding 4-8px
  - icon 24px，text 10px（更小、更紧凑）
  - 颜色默认 `muted2`，激活 `accent`
  - **总高度 ≈ 50-54px**（当前 SwiftUI 默认 ≈ 49-83px，看设备）
- **Gap**：当前用系统默认样式，未自定义颜色/高度/字号/未激活文字色

### 0.3 NavigationBar 视觉

- **当前**：用 `Theme.Colors.background` 作 NavBar 背景，title 文字 `textPrimary` —— **与 Surface 同色，区分不开**
- **v3 原型**：
  - 背景 `var(--surface)`（比主背景亮一档）
  - 底 border 1px `var(--border)`
  - 高度 52px
  - title 17px / 590 weight / -0.02em letter-spacing
  - 按钮 36×36，背景 surface2，icon 20×20
- **Gap**：当前 NavBar 与主背景同色，视觉层次弱；按钮是系统默认

### 0.4 spacing/radius token 未贯彻

- `Theme.Spacing.xs/sm/md/lg/xl` 定义了但**几乎无调用**（全字面量）
- `Theme.Radius.sm/md/lg/xl` 定义了但**几乎无调用**
- **影响**：风格难统一，调一改全乱

### 0.5 字体未使用自定义字体

- `Theme.Fonts.mono = "JetBrainsMono"` 定义了但**未实际加载**（无 ttf 文件）
- 代码用 `Font.system(size: x, design: .monospaced)` 取系统等宽
- **结论**：v3 原型用 `'JetBrains Mono', 'SF Mono', ui-monospace, Menlo, monospace`，当前用 SF Mono（系统）。**视觉差异不大，先不修**

---

## 1. Editor Tab

| 组件 | 当前 | v3 原型 | Gap |
|---|---|---|---|
| 顶栏 | SwiftUI `.toolbar` 三个 button（Menu/History/Run）| 文件名标题 + Menu + Format + Run | 当前缺 file-tab 多文件 tab 标签、Format 独立按钮 |
| 代码区 | WKWebView + CodeMirror，bg `#1E1E1E`，font 14px | CodeMirror + `#010202` (code-bg) 极黑背景，13px，line-height 1.7 | 颜色和字号微调，行号区宽度、padding 不同 |
| 行号区 | bg `#252526`，40px 宽 | bg 略深，48px 宽，padding 16/10/16/8 | 字号 13，行高 1.7 |
| 输出区 | 用 SwiftUI `Text + ScrollView`，maxHeight 150，bg `#1E1E1E`，header 4px 14px | output-header 4px 14px + body 10px 14px，圆角明确 | 缺输出 tab 切换(Output/Errors)，缺关闭按钮设计 |
| 空态 | 简单图标 + 文字 | 应该有 icon + title + subtitle 模式 | 可优化 |
| Toast | 绿色胶囊 | **原型 toast 是 surface3 底 + border + shadow，居中浮在 tab bar 上方** | 视觉差距大 |

### 1.1 关键 Editor 修复项

1. **CodeMirror CSS**：bg 改为 `#010202`，font 改 13px，行高改 1.7，行号区宽度改 48px
2. **EditorView 顶栏**：增加 File Tab 横条（如果多文件），增加 Format 独立按钮
3. **Output 面板**：增加 tab 切换（Output / Errors）、关闭按钮、标题更紧凑
4. **Toast**：改为居中、surface3 底、border、shadow

---

## 2. FileBrowser Tab

| 组件 | 当前 | v3 原型 | Gap |
|---|---|---|---|
| 容器 | SwiftUI `List` + plain 样式 | 自定义列表（file-row），padding 0 16px 8px | 当前用 List，自带分割线/选中态；原型不用 List |
| 项目行 | ProjectRowView：HStack + folder icon + 名称 + 文件数 + 时间 | file-row 风格：36×36 gradient icon 容器 + name(15/500) + meta(12/muted) + ⋯ 按钮 | 当前缺渐变 icon、字体规格、⋯ 按钮 |
| 文件行 | FileRowView：HStack + icon + name | 同上，36×36 gradient icon 容器 | 同上 |
| Section 标签 | "Projects" / "Files" 系统默认样式 | uppercase 12px / 590 weight / 0.04em letter-spacing | 当前用系统样式 |
| 工具栏 | `+` Menu（New Project / Import / New File）| 同上 | 一致 |
| New Project Sheet | `Form + TextField` | modal-sheet 居底弹出 + drag handle + 大标题 | **关键差异**！当前用系统 Form sheet，原型是 iOS 大标题居底 sheet |
| 导入 | `UIDocumentPickerViewController` 桥接 | 一致 | 一致 |

### 2.1 关键 FileBrowser 修复项

1. **项目行/文件行重做**：用 36×36 gradient icon 容器（folder amber/py 主题色/md 主题色），f-name 15/500，f-meta 12/muted，右侧 ⋯ 按钮
2. **Section label**：uppercase 12px / 590 / 0.04em
3. **空态**：增加空态插图/CTA
4. **New Project Sheet 改写**：居底 sheet + drag handle + 居中大标题
5. **行间距**：增加 file-row 之间间距（原型有 margin-bottom 2px）

---

## 3. Terminal Tab

| 组件 | 当前 | v3 原型 | Gap |
|---|---|---|---|
| 顶栏 | "Terminal" title + Menu (Clear / Auto-scroll / Shortcuts) | "~ $" mono 15px + 2 按钮 (new / close) | 标题应该是 mono 字体 "~$" 风格 |
| 输出区 | bg `Theme.Colors.terminalBackground = #0D1117` | bg `var(--code-bg) = #010202`（极黑） | 颜色更深 |
| 行 | 14px mono，prompt `.blue` / `.red` / `.green` | 13px mono，prompt `var(--success)`，body `#e6edf3`（写死），error `var(--danger)` | 字号、prompt 颜色 |
| 输入区 | padding 16px，secondarySystemBackground 底 | padding 8px 16px，bg `oklch(15% 0.01 250) ≈ #06080B` | 当前用系统色，原型用写死深色（与 terminal 融为一体）|
| 快捷键栏 | 没有 | term-keys 6px 16px 10px，term-key 6px 12px 单键 | 当前**无**快捷键栏 |

### 3.1 关键 Terminal 修复项

1. **顶栏标题**：`Text("~$")`，mono 15px
2. **输出区背景**：`#010202`（与编辑器同色）
3. **行字号**：13px，line-height 1.7
4. **prompt 颜色**：用 `Theme.Colors.success`（绿）替代 `.blue`
5. **body 文字**：写死 `#E6EDF3`（GitHub 浅色，与背景对比强）
6. **输入区**：背景改 `#06080B`，更沉浸
7. **快捷键栏**：可选新增 ESC/Tab/↑/↓/Ctrl+C 等虚拟键（视情况）

---

## 4. AIAssistant Tab

| 组件 | 当前 | v3 原型 | Gap |
|---|---|---|---|
| 上下文 banner | HStack + 文件名 + 状态标签，bg `secondarySystemBackground` | 类似但更紧凑，padding 8px 14px | 当前 padding 12/6，原型 8/14 |
| 快捷 prompt | ScrollView + Chip，padding 6/12 | 同样 chip，padding 5/12，icon 在前 | 当前 chip icon 用 emoji，原型无 icon；当前 chip padding 偏大 |
| 用户气泡 | 蓝底白字，cornerRadius 16，padding 12 | accent 底（绿），黑字，cornerRadius 18，padding 12/16，右下 4px 破口 | **关键差异**！当前蓝+白字，原型 accent+黑字；圆角/破口不同 |
| AI 气泡 | secondarySystemBackground 底，cornerRadius 16 | surface 底，cornerRadius 18，左下 4px 破口 | 圆角和破口 |
| 代码块 | 黑色底 + 绿字 + 复制/插入按钮，cornerRadius 8 | code-bg 底 + `#e6edf3` 文字 + 复制按钮右上角，cornerRadius 8，10/12 padding | **关键差异**！当前绿字，原型浅色文字（更像终端代码）|
| 输入框 | `.roundedBorder` TextField + 发送按钮 | ai-input 自定义：22px 圆角，surface2 底，accent border focus | **关键差异**！当前用系统 roundedBorder，原型是聊天气泡风 |
| 工具栏 | Menu：Privacy/Clear/Stop | 类似 | 一致 |

### 4.1 关键 AIAssistant 修复项

1. **用户气泡**：bg 改 accent，文字改黑，cornerRadius 18，右下 4px 破口
2. **AI 气泡**：bg 改 surface，cornerRadius 18，左下 4px 破口
3. **代码块**：文字改 `#E6EDF3`（移除绿色），按钮更紧凑
4. **输入框**：自定义 22px 圆角 input，surface2 底
5. **快捷 prompt chip**：padding 5/12，去掉 emoji，改用对应 SF Symbol 或纯文字
6. **context banner**：padding 8/14，更紧凑

---

## 5. Settings Tab

| 组件 | 当前 | v3 原型 | Gap |
|---|---|---|---|
| 整体 | Form + Section（系统默认样式）| settings-content 自定义：h1 大标题 + section-title 12px uppercase + settings-group 卡片 (surface 底，14px 圆角) + settings-item (13px 16px padding) | **关键差异**！当前用系统 Form，原型是分组卡片 |
| 行 | 系统默认 44pt 高度 | 48px min-height，13px 16px padding | 当前更紧凑 |
| 左侧 icon | 部分行有 (keyboard) | settings-sicon 28×28，cornerRadius 7px，accent-dim 底 + accent icon | 当前缺统一 icon 容器 |
| 右侧值 | "14" / "未配置" / chevron | 14px muted，margin-right 6px + chevron muted2 | 接近 |
| Toggle | 系统默认 | 自定义：46×28 圆角 14px 滑轨，success 绿，22×22 滑块 | 当前用系统 Toggle |
| 颜色 | 文字 `.primary` | 文字 `var(--fg) = #E9E8E4` | 接近 |
| Section title | 系统 header | 12/590 uppercase 0.04em letter-spacing，padding-left 4px，margin-bottom 6px | 当前系统样式 |

### 5.1 关键 Settings 修复项

1. **改用自定义 settings-group 卡片**（而不是 Form）
2. **统一 icon 容器**（28×28，cornerRadius 7px，accent-dim 底 + accent icon）
3. **section title 改为 uppercase**
4. **行高统一 48px min-height**
5. **字体颜色统一用 Theme.Colors.textPrimary/textSecondary**

---

## 6. 优先级总结

| 优先级 | 修复项 | 工作量 |
|---|---|---|
| **P0** | 颜色 token 重构（emerald 色板） | 中 |
| **P0** | Theme 增加 surface2/surface3/muted/muted2/border/border2/tabBarBg/codeBg | 小 |
| **P0** | AIAssistant 气泡视觉（用户 accent 底，AI surface 底，18px 圆角 + 破口） | 小 |
| **P0** | AI 代码块文字颜色改 #E6EDF3 | 极小 |
| **P0** | CodeMirror CSS 调整（bg、字号、行高、行号宽度） | 极小 |
| **P0** | Toast 居中 + surface3 底 + border + shadow | 小 |
| **P1** | Editor 输出面板 tab 化（Output/Errors） | 中 |
| **P1** | FileBrowser file-row 重做（gradient icon + ⋯ 按钮 + 规格化） | 中 |
| **P1** | Settings 改用 settings-group 卡片 | 中 |
| **P1** | Terminal 背景/字号/prompt 颜色 | 小 |
| **P2** | TabBar 自定义（高度、字号、激活色） | 中 |
| **P2** | NavBar 自定义（按钮、title 字体） | 中 |
| **P2** | Section label 改 uppercase | 极小 |
| **P2** | 输入框/按钮 token 化（统一用 spacing/radius） | 中 |

---

## 7. 不在本期范围

- 多色板切换（emerald/ocean/lilac/...）— **架构改动大，不在本期**
- iCloud 同步 UI
- VS Code 协作 UI
- 业务逻辑修改（仅视觉）
- App Store 准备（已有 `app-store-prep.md`）
