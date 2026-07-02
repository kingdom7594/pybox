import SwiftUI

class AppState: ObservableObject {
    @Published var currentProject: Project?
    @Published var openFiles: [ProjectFile] = []
    @Published var activeFileId: String?
    @Published var isRunning: Bool = false
    @Published var terminalOutput: [TerminalLine] = []
    @Published var aiMessages: [AIMessage] = []

    @Published var activeFileContent: String = ""
    @Published var activeFileName: String = ""
    @Published var activeFileLanguage: String = "python"
    
    private let fileManager = FileManagerService.shared
    private let pythonRuntime = PythonRuntimeService.shared
    
    init() {
        loadRecentProject()
        syncWidgetData()
    }

    /// 同步最近项目到 App Group (供 Widget 显示)
    func syncWidgetData() {
        let projects = fileManager.getAllProjects()
        SharedStorage.writeRecentProjects(projects)
        NSLog("[AppState] Synced \(projects.count) projects to App Group for Widget")
    }
    
    func loadRecentProject() {
        if let lastProjectId = UserDefaults.standard.string(forKey: "lastProjectId"),
           let projectData = try? Data(contentsOf: fileManager.getProjectsDirectory().appendingPathComponent("\(lastProjectId)/project.json")),
           let project = try? JSONDecoder().decode(Project.self, from: projectData) {
            currentProject = project
        }
    }
    
    func openFile(_ file: ProjectFile) {
        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
        }
        activeFileId = file.id
        updateActiveFileContext(file)
    }

    /// 更新当前文件上下文（供 AI Assistant 注入 system prompt）
    func updateActiveFileContext(_ file: ProjectFile) {
        activeFileContent = file.content
        activeFileName = file.name
        activeFileLanguage = languageFromExtension(file.name)
    }

    /// 更新当前代码内容（编辑器每次输入时调用）
    func updateActiveFileContent(_ content: String) {
        activeFileContent = content
    }

    private func languageFromExtension(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "py": return "python"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "swift": return "swift"
        case "json": return "json"
        case "md": return "markdown"
        case "html": return "html"
        case "css": return "css"
        case "sh": return "bash"
        default: return "text"
        }
    }

    func closeFile(_ file: ProjectFile) {
        openFiles.removeAll { $0.id == file.id }
        if activeFileId == file.id {
            activeFileId = openFiles.last?.id
        }
    }

    /// 处理来自 Shortcuts/Share Extension/外部打开的 URL 或 file
    func handleIncomingURL(_ url: URL) {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let imported = FileManagerService.shared.importFile(from: url)
        if let file = imported {
            let projectId = importedFlatProjectId(for: url) ?? currentProject?.id
            if let pid = projectId {
                currentProject = fileManager.getProject(id: pid) ?? currentProject
            }
            openFile(file)
        }
    }

    /// 主 app 启动时检查 Shortcuts 写入的待运行脚本
    func checkPendingScript() {
        guard let pending = SharedStorage.consumePendingScript() else { return }
        NSLog("[AppState] Found pending script: \(pending.filename)")

        // 找到或创建 Quick Scripts 项目
        let quickProject = ensureQuickScriptsProject()
        let projectDir = FileManagerService.shared.projectPath(for: quickProject.id)

        // 确保目录存在
        if !FileManager.default.fileExists(atPath: projectDir.path) {
            try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        }

        let fileURL = projectDir.appendingPathComponent(pending.filename)

        do {
            try pending.code.write(to: fileURL, atomically: true, encoding: .utf8)
            let file = ProjectFile(
                id: UUID().uuidString,
                name: pending.filename,
                path: fileURL.path,
                content: pending.code,
                type: .python
            )

            // 重新从 fileManager 读取最新的项目状态
            if var project = FileManagerService.shared.getProject(id: quickProject.id) {
                project.files.removeAll { $0.name == pending.filename }
                project.files.insert(file, at: 0)
                project.modifiedAt = Date()
                FileManagerService.shared.saveProject(project)
            } else {
                NSLog("[AppState] Project \(quickProject.id) not found after creation")
                return
            }

            currentProject = quickProject
            openFile(file)
            NSLog("[AppState] Successfully loaded pending script: \(pending.filename)")

            // 通知 FileBrowserViewModel 刷新
            NotificationCenter.default.post(name: .pendingScriptLoaded, object: quickProject)
        } catch {
            NSLog("[AppState] Failed to save pending script: \(error.localizedDescription)")
        }
    }

    /// 主 app 启动时检查 Share Extension 写入的 Inbox 文件
    func checkSharedInbox() {
        guard let containerURL = SharedStorage.containerURL else { return }
        let inbox = containerURL.appendingPathComponent("Inbox", isDirectory: true)

        guard FileManager.default.fileExists(atPath: inbox.path),
              let files = try? FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil),
              !files.isEmpty else {
            return
        }

        NSLog("[AppState] Found \(files.count) files in shared inbox")
        let quickProject = ensureQuickScriptsProject()
        let projectDir = FileManagerService.shared.projectPath(for: quickProject.id)

        if !FileManager.default.fileExists(atPath: projectDir.path) {
            try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        }

        for srcURL in files {
            let destURL = projectDir.appendingPathComponent(srcURL.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: srcURL, to: destURL)
                try? FileManager.default.removeItem(at: srcURL)

                let content = (try? String(contentsOf: destURL, encoding: .utf8)) ?? ""
                let file = ProjectFile(
                    id: UUID().uuidString,
                    name: srcURL.lastPathComponent,
                    path: destURL.path,
                    content: content,
                    type: .python
                )

                if var project = FileManagerService.shared.getProject(id: quickProject.id) {
                    project.files.removeAll { $0.name == srcURL.lastPathComponent }
                    project.files.insert(file, at: 0)
                    project.modifiedAt = Date()
                    FileManagerService.shared.saveProject(project)
                }
                NSLog("[AppState] Imported from inbox: \(srcURL.lastPathComponent)")
            } catch {
                NSLog("[AppState] Failed to import from inbox: \(error.localizedDescription)")
            }
        }

        NotificationCenter.default.post(name: .pendingScriptLoaded, object: quickProject)
    }

    private func ensureQuickScriptsProject() -> Project {
        let projects = fileManager.getAllProjects()
        if let existing = projects.first(where: { $0.name == "Quick Scripts" }) {
            return existing
        }
        guard let project = fileManager.createProject(name: "Quick Scripts") else {
            let id = UUID().uuidString
            let path = fileManager.getProjectsDirectory().appendingPathComponent(id).path
            let project = Project(id: id, name: "Quick Scripts", path: path, createdAt: Date(), modifiedAt: Date(), files: [])
            try? FileManager.default.createDirectory(at: fileManager.getProjectsDirectory().appendingPathComponent(id), withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(project) {
                try? data.write(to: fileManager.getProjectsDirectory().appendingPathComponent("\(id)/project.json"))
            }
            return project
        }
        return project
    }

    private func importedFlatProjectId(for url: URL) -> String? {
        let components = url.pathComponents
        guard let idx = components.firstIndex(where: { $0 == "PyBoxProjects" }), idx + 1 < components.count else {
            return nil
        }
        return components[idx + 1]
    }
}

struct Project: Codable, Identifiable {
    let id: String
    var name: String
    var path: String
    var createdAt: Date
    var modifiedAt: Date
    var files: [ProjectFile]
}

struct ProjectFile: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var path: String
    var content: String
    var type: FileType
    
    enum FileType: String, Codable {
        case python, json, text, folder
    }
}

struct TerminalLine: Identifiable {
    let id = UUID()
    let prompt: String
    let output: String
    let type: LineType
    
    enum LineType {
        case input, output, error, success
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    var content: String
    let isUser: Bool
    var codeBlocks: [AICodeBlock] = []
    let timestamp: Date

    /// 兼容旧字段
    var codeBlock: String? { codeBlocks.first?.code }

    init(content: String, isUser: Bool, codeBlock: String? = nil, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        if let codeBlock = codeBlock {
            self.codeBlocks = [AICodeBlock(code: codeBlock, language: nil)]
        }
    }

    init(content: String, isUser: Bool, codeBlocks: [AICodeBlock], timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.codeBlocks = codeBlocks
        self.timestamp = timestamp
    }
}

struct AICodeBlock: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let language: String?
}