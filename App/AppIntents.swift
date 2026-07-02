import Foundation
import AppIntents
import UniformTypeIdentifiers

/// 通用 Python 脚本 Intent
/// 由 Shortcuts / Siri 调用
@available(iOS 16.0, *)
struct RunPythonScriptIntent: AppIntent {
    static var title: LocalizedStringResource = "运行 Python 脚本"
    static var description = IntentDescription("在 PyBox 中运行 Python 脚本，可直接输入代码或选择一个脚本文件。")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "脚本代码", description: "要执行的 Python 代码", default: "print('Hello from PyBox!')")
    var code: String

    @Parameter(title: "文件名", description: "可选：脚本名称")
    var filename: String?

    static var parameterSummary: some ParameterSummary {
        Summary("运行 Python 脚本 \(\.$code)") {
            \.$filename
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let safeName = filename.flatMap { $0.isEmpty ? nil : $0 } ?? "shortcut_script.py"

        if let url = SharedStorage.writePendingScript(code: code, filename: safeName) {
            NSLog("[RunPythonScriptIntent] Wrote script to \(url.path), filename=\(safeName)")
        }

        // 把待运行脚本元数据也写入 (供主 app 启动读取)
        let defaults = UserDefaults(suiteName: SharedStorage.appGroupID)
        defaults?.set(safeName, forKey: "pending_script_name")

        return .result(dialog: "正在 PyBox 中运行 \(safeName)")
    }
}

/// 打开项目 Intent
@available(iOS 16.0, *)
struct OpenProjectIntent: AppIntent {
    static var title: LocalizedStringResource = "打开 PyBox 项目"
    static var description = IntentDescription("在 PyBox 中打开最近的项目。")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "正在打开 PyBox")
    }
}

/// 在 PyBox 中创建文件 Intent
@available(iOS 16.0, *)
struct CreateFileIntent: AppIntent {
    static var title: LocalizedStringResource = "在 PyBox 中创建文件"
    static var description = IntentDescription("在 PyBox 中创建一个新文件。")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "文件名", default: "untitled.py")
    var name: String

    @Parameter(title: "内容", default: "")
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if let url = SharedStorage.writePendingScript(code: content, filename: name) {
            NSLog("[CreateFileIntent] Wrote new file to \(url.path), name=\(name)")
        }
        return .result(dialog: "已在 PyBox 中创建 \(name)")
    }
}

/// App Shortcuts Provider - 让 App 出现在 Shortcuts 列表中
@available(iOS 16.0, *)
struct PyBoxShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunPythonScriptIntent(),
            phrases: [
                "用 \(.applicationName) 运行 Python",
                "在 \(.applicationName) 中执行 Python 代码"
            ],
            shortTitle: "运行 Python 脚本",
            systemImageName: "terminal.fill"
        )
        AppShortcut(
            intent: OpenProjectIntent(),
            phrases: [
                "打开 \(.applicationName)",
                "用 \(.applicationName) 编程"
            ],
            shortTitle: "打开 PyBox",
            systemImageName: "chevron.left.forwardslash.chevron.right"
        )
        AppShortcut(
            intent: CreateFileIntent(),
            phrases: [
                "在 \(.applicationName) 中创建脚本"
            ],
            shortTitle: "创建文件",
            systemImageName: "doc.badge.plus"
        )
    }
}
