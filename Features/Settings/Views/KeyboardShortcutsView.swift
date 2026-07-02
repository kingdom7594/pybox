import SwiftUI

struct KeyboardShortcutsView: View {
    private let categories: [ShortcutCategory] = [
        ShortcutCategory(
            title: "编辑器",
            icon: "chevron.left.forwardslash.chevron.right",
            shortcuts: [
                ShortcutEntry(keys: "⌘ + R", desc: "运行脚本"),
                ShortcutEntry(keys: "⌘ + S", desc: "保存文件"),
                ShortcutEntry(keys: "⌘ + Z", desc: "撤销"),
                ShortcutEntry(keys: "⌘ + ⇧ + Z", desc: "重做"),
                ShortcutEntry(keys: "⌥ + ←/→", desc: "按词移动光标"),
                ShortcutEntry(keys: "⌘ + /", desc: "注释/取消注释当前行"),
                ShortcutEntry(keys: "Tab", desc: "缩进 / 自动补全"),
                ShortcutEntry(keys: "Tab Tab (2次)", desc: "强制触发补全"),
            ]
        ),
        ShortcutCategory(
            title: "文件浏览器",
            icon: "folder.fill",
            shortcuts: [
                ShortcutEntry(keys: "长按文件", desc: "弹出操作菜单（重命名/删除/导出）"),
                ShortcutEntry(keys: "右键 (Mac)", desc: "同长按菜单"),
                ShortcutEntry(keys: "拖拽文件", desc: "移动到其他项目"),
            ]
        ),
        ShortcutCategory(
            title: "终端",
            icon: "terminal.fill",
            shortcuts: [
                ShortcutEntry(keys: "↑ / ↓", desc: "浏览命令历史"),
                ShortcutEntry(keys: "Tab", desc: "自动补全命令/路径"),
                ShortcutEntry(keys: "Ctrl + C", desc: "终止当前执行"),
                ShortcutEntry(keys: "Ctrl + L", desc: "清屏"),
            ]
        ),
        ShortcutCategory(
            title: "AI 助手",
            icon: "sparkles",
            shortcuts: [
                ShortcutEntry(keys: "💡 解释代码", desc: "解释当前选中/打开的代码"),
                ShortcutEntry(keys: "🐛 调试 Bug", desc: "分析代码潜在 Bug"),
                ShortcutEntry(keys: "✨ 补全代码", desc: "基于现有代码给补全建议"),
                ShortcutEntry(keys: "📝 添加注释", desc: "为代码生成中文注释"),
                ShortcutEntry(keys: "🔧 重构优化", desc: "提供重构后的版本"),
            ]
        ),
        ShortcutCategory(
            title: "系统集成",
            icon: "iphone",
            shortcuts: [
                ShortcutEntry(keys: "Siri/Shortcuts", desc: "用 ${+applicationName} 运行 Python 脚本"),
                ShortcutEntry(keys: "分享菜单", desc: "从其他 App 分享 .py 文件到 ${+applicationName}"),
                ShortcutEntry(keys: "主屏幕 Widget", desc: "快速运行最近项目"),
            ]
        ),
    ]

    var body: some View {
        List {
            ForEach(categories) { category in
                Section {
                    ForEach(category.shortcuts) { shortcut in
                        HStack(alignment: .top, spacing: 12) {
                            Text(shortcut.keys)
                                .font(.system(size: 12, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(6)
                                .frame(minWidth: 90, alignment: .leading)
                            Text(shortcut.desc)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.accentColor)
                        Text(category.title)
                    }
                }
            }
        }
        .navigationTitle("快捷键参考")
        .navigationBarTitleDisplayMode(.inline)
    }

    struct ShortcutCategory: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let shortcuts: [ShortcutEntry]
    }

    struct ShortcutEntry: Identifiable {
        let id = UUID()
        let keys: String
        let desc: String
    }
}

#Preview {
    NavigationStack {
        KeyboardShortcutsView()
    }
}
