import Foundation

/// App Group 共享存储 - 用于 Shortcuts, Widget, Share Extension 共享数据
/// 主 app 和 extension 都需要读取这里的数据
enum SharedStorage {
    static let appGroupID = "group.com.pybox.ide"

    /// 共享容器 URL (UserDefaults 等)
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// Shortcuts 接收到的待运行脚本
    static var pendingScriptURL: URL? {
        containerURL?.appendingPathComponent("pending_script.py")
    }

    /// 写入待运行脚本
    static func writePendingScript(code: String, filename: String) -> URL? {
        guard let url = containerURL?.appendingPathComponent("pending_script.py") else {
            return nil
        }
        do {
            try code.write(to: url, atomically: true, encoding: .utf8)
            writePendingScriptName(filename)
            return url
        } catch {
            NSLog("[SharedStorage] Failed to write pending script: \(error.localizedDescription)")
            return nil
        }
    }

    /// 读取并清除待运行脚本
    static func consumePendingScript() -> (code: String, filename: String)? {
        guard let url = pendingScriptURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let code = try String(contentsOf: url, encoding: .utf8)
            let filename = readPendingScriptName() ?? "script.py"
            try? FileManager.default.removeItem(at: url)
            UserDefaults(suiteName: appGroupID)?.removeObject(forKey: "pending_script_name")
            return (code, filename)
        } catch {
            NSLog("[SharedStorage] Failed to read pending script: \(error.localizedDescription)")
            return nil
        }
    }

    /// 写入最近的运行结果
    static func writeLastOutput(_ output: String) {
        UserDefaults(suiteName: appGroupID)?.set(output, forKey: "last_output")
    }

    /// 读取最近的运行结果
    static func readLastOutput() -> String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "last_output") ?? ""
    }

    /// 写入项目列表 (供 widget 显示)
    static func writeRecentProjects(_ projects: [Project]) {
        let summaries = projects.prefix(5).map { project in
            RecentProjectSummary(id: project.id, name: project.name, modifiedAt: project.modifiedAt)
        }
        if let data = try? JSONEncoder().encode(Array(summaries)) {
            // 直接写文件而不是 UserDefaults (UserDefaults 需要 Preferences 目录)
            if let url = preferencesFileURL {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    /// 读取项目列表
    static func readRecentProjects() -> [RecentProjectSummary] {
        if let url = preferencesFileURL,
           let data = try? Data(contentsOf: url),
           let projects = try? JSONDecoder().decode([RecentProjectSummary].self, from: data) {
            return projects
        }
        return []
    }

    /// 写入 pending script meta
    static func writePendingScriptName(_ name: String) {
        UserDefaults(suiteName: appGroupID)?.set(name, forKey: "pending_script_name")
    }

    static func readPendingScriptName() -> String? {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "pending_script_name")
    }

    private static var preferencesFileURL: URL? {
        guard let container = containerURL else { return nil }
        let prefsDir = container.appendingPathComponent("Library/Preferences", isDirectory: true)
        try? FileManager.default.createDirectory(at: prefsDir, withIntermediateDirectories: true)
        return prefsDir.appendingPathComponent("recent_projects.json")
    }
}

struct RecentProjectSummary: Codable, Identifiable {
    let id: String
    let name: String
    let modifiedAt: Date
}
