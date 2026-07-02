import SwiftUI

@MainActor
class EditorViewModel: ObservableObject {
    @Published var code: String = "" {
        didSet {
            if currentFile != nil {
                currentFile?.content = code
            }
        }
    }
    @Published var currentFile: ProjectFile?
    @Published var output: String = "Ready to run..."
    @Published var outputHasError: Bool = false
    @Published var isRunning: Bool = false
    @Published var isFormatting: Bool = false
    @Published var fontSize: Double = 14
    @Published var showLineNumbers: Bool = true
    @Published var autoCompleteEnabled: Bool = true

    private let pythonRuntime = PythonRuntimeService.shared
    private let fileManager = FileManagerService.shared
    private let blackFormatter = BlackFormatterService.shared
    
    func loadLastOpenedFile() {
        let lastFileId = UserDefaults.standard.string(forKey: "lastOpenedFileId")
        NSLog("[EditorViewModel] loadLastOpenedFile: id=\(lastFileId ?? "nil")")
        if let lastFileId = lastFileId,
           let file = fileManager.getFile(id: lastFileId) {
            NSLog("[EditorViewModel] Found file: \(file.name), content length: \(file.content.count)")
            openFile(file)
        } else {
            NSLog("[EditorViewModel] No file found for id: \(lastFileId ?? "nil")")
        }
    }
    
    func openFile(_ file: ProjectFile) {
        currentFile = file
        code = file.content
        UserDefaults.standard.set(file.id, forKey: "lastOpenedFileId")
    }
    
    func runCode() {
        guard !code.isEmpty else {
            output = "No code to run"
            return
        }

        isRunning = true
        output = "Running..."
        outputHasError = false

        let startTime = Date()
        let fileName = currentFile?.name ?? "untitled.py"
        let filePath = currentFile?.path ?? ""
        let codeToRun = code

        Task {
            do {
                let result = try await pythonRuntime.execute(script: codeToRun, in: "")
                let duration = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    self.output = result.output
                    self.outputHasError = result.error != nil
                    if let error = result.error {
                        self.output += "\nError: \(error)"
                    }
                    self.isRunning = false
                }
                let record = RunRecord(
                    fileName: fileName,
                    filePath: filePath,
                    code: codeToRun,
                    output: result.output.isEmpty ? nil : result.output,
                    error: result.error,
                    duration: duration,
                    timestamp: Date(),
                    exitCode: result.error == nil ? 0 : 1
                )
                RunHistoryStore.shared.save(record)
                NotificationCenter.default.post(name: .runHistoryUpdated, object: nil)
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                let errorMessage = error.localizedDescription
                await MainActor.run {
                    self.output = "Error: \(errorMessage)"
                    self.outputHasError = true
                    self.isRunning = false
                    ErrorHandler.shared.handleError(error, title: "运行失败")
                }
                let record = RunRecord(
                    fileName: fileName,
                    filePath: filePath,
                    code: codeToRun,
                    output: nil,
                    error: errorMessage,
                    duration: duration,
                    timestamp: Date(),
                    exitCode: -1
                )
                RunHistoryStore.shared.save(record)
                NotificationCenter.default.post(name: .runHistoryUpdated, object: nil)
            }
        }
    }
    
    func toggleLineNumbers() {
        showLineNumbers.toggle()
    }

    func toggleAutoComplete() {
        autoCompleteEnabled.toggle()
    }

    func formatCode() {
        guard !isRunning, !isFormatting else { return }
        guard !code.isEmpty else {
            Task { @MainActor in
                ErrorHandler.shared.handleMessage("没有可格式化的代码", title: "格式化", severity: .warning)
            }
            return
        }
        guard currentFile?.type == .python || currentFile == nil else {
            Task { @MainActor in
                ErrorHandler.shared.handleMessage("仅支持 Python 文件", title: "格式化", severity: .warning)
            }
            return
        }

        isFormatting = true
        let originalCode = code
        Task {
            let result = await blackFormatter.format(code)
            await MainActor.run {
                self.isFormatting = false
                if result.success, result.formatted != originalCode {
                    self.code = result.formatted
                    self.currentFile?.content = result.formatted
                    self.appStateRef?.updateActiveFileContent(result.formatted)
                    ErrorHandler.shared.handleMessage("格式化完成 (PEP 8 / autopep8)", title: "✓ 已格式化", severity: .info)
                } else if result.success {
                    ErrorHandler.shared.handleMessage("代码已经符合 PEP 8 规范", title: "格式化", severity: .info)
                } else {
                    self.output = "Format error: \(result.error ?? "unknown")"
                    self.outputHasError = true
                    ErrorHandler.shared.handleError(
                        NSError(domain: "BlackFormatter", code: -1, userInfo: [NSLocalizedDescriptionKey: result.error ?? "unknown"]),
                        title: "格式化失败"
                    )
                }
            }
        }
    }

    func setAppState(_ appState: AppState) {
        self.appStateRef = appState
    }

    private var appStateRef: AppState?
}

extension Notification.Name {
    static let runHistoryUpdated = Notification.Name("runHistoryUpdated")
}