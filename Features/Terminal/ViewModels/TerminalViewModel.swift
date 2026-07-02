import SwiftUI

class TerminalViewModel: ObservableObject {
    @Published var outputLines: [TerminalLine] = []
    @Published var inputCommand: String = ""
    @Published var autoScroll: Bool = true
    @Published var prompt: String = "$ "
    @Published var isPythonMode: Bool = false
    
    private var commandHistory: [String] = []
    private var historyIndex: Int = -1
    private let pythonRuntime = PythonRuntimeService.shared
    
    func initialize() {
        if outputLines.isEmpty {
            outputLines.append(TerminalLine(
                prompt: "",
                output: "PyBox Terminal v1.0",
                type: .success
            ))
            outputLines.append(TerminalLine(
                prompt: "",
                output: pythonRuntime.getPythonVersion(),
                type: .success
            ))
            outputLines.append(TerminalLine(
                prompt: "",
                output: "Type 'help' for available commands",
                type: .output
            ))
            outputLines.append(TerminalLine(
                prompt: "",
                output: "",
                type: .output
            ))
        }
    }
    
    func executeCommand() {
        let command = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        
        commandHistory.append(command)
        historyIndex = commandHistory.count
        
        outputLines.append(TerminalLine(
            prompt: prompt,
            output: command,
            type: .input
        ))
        
        inputCommand = ""
        
        processCommand(command)
    }
    
    private func processCommand(_ command: String) {
        let components = command.components(separatedBy: " ")
        let cmd = components[0].lowercased()
        let args = Array(components.dropFirst())
        
        switch cmd {
        case "clear", "cls":
            outputLines.removeAll()
            
        case "help":
            showHelp()
            
        case "history":
            for (i, cmd) in commandHistory.enumerated() {
                outputLines.append(TerminalLine(
                    prompt: "",
                    output: "  \(i + 1)  \(cmd)",
                    type: .output
                ))
            }
            
        case "echo":
            let text = args.joined(separator: " ")
            outputLines.append(TerminalLine(
                prompt: "",
                output: text,
                type: .output
            ))
            
        case "date":
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .full
            outputLines.append(TerminalLine(
                prompt: "",
                output: formatter.string(from: Date()),
                type: .output
            ))
            
        case "python", "py":
            if args.isEmpty {
                // 进入 Python 交互模式
                isPythonMode = true
                prompt = ">>> "
                outputLines.append(TerminalLine(
                    prompt: "",
                    output: "Python Interactive Mode (type 'exit()' to quit)",
                    type: .success
                ))
            } else {
                // 直接执行 Python 代码
                let pythonCode = args.joined(separator: " ")
                executePythonCode(pythonCode)
            }
            
        case "ls", "dir":
            outputLines.append(TerminalLine(
                prompt: "",
                output: "main.py  utils/  hello.py  README.md",
                type: .output
            ))
            
        case "pwd":
            outputLines.append(TerminalLine(
                prompt: "",
                output: "/Users/pybox/Documents",
                type: .output
            ))
            
        case "whoami":
            outputLines.append(TerminalLine(
                prompt: "",
                output: "pybox",
                type: .output
            ))
            
        case "uname":
            outputLines.append(TerminalLine(
                prompt: "",
                output: "Darwin PyBox-iPhone 23.0.0 Kernel",
                type: .output
            ))
            
        case "exit", "quit":
            if isPythonMode {
                isPythonMode = false
                prompt = "$ "
                outputLines.append(TerminalLine(
                    prompt: "",
                    output: "Exited Python mode",
                    type: .output
                ))
            }
            
        default:
            // 如果在 Python 模式下，执行 Python 代码
            if isPythonMode {
                if command == "exit()" || command == "quit()" {
                    isPythonMode = false
                    prompt = "$ "
                    outputLines.append(TerminalLine(
                        prompt: "",
                        output: "Exited Python mode",
                        type: .output
                    ))
                } else {
                    executePythonCode(command)
                }
            } else {
                outputLines.append(TerminalLine(
                    prompt: "",
                    output: "Command not found: \(cmd). Type 'help' for available commands.",
                    type: .error
                ))
            }
        }
    }
    
    /// 执行 Python 代码
    private func executePythonCode(_ code: String) {
        Task {
            do {
                let result = try await pythonRuntime.execute(script: code, in: FileManager.default.temporaryDirectory.path)
                await MainActor.run {
                    if !result.output.isEmpty {
                        outputLines.append(TerminalLine(
                            prompt: "",
                            output: result.output,
                            type: .output
                        ))
                    }
                    if let error = result.error {
                        outputLines.append(TerminalLine(
                            prompt: "",
                            output: error,
                            type: .error
                        ))
                    }
                }
            } catch {
                await MainActor.run {
                    outputLines.append(TerminalLine(
                        prompt: "",
                        output: "Error: \(error.localizedDescription)",
                        type: .error
                    ))
                }
            }
        }
    }
    
    private func showHelp() {
        let helpText = """
        Available commands:
          clear, cls    - Clear terminal
          help          - Show this help message
          history       - Show command history
          echo <text>   - Print text
          date          - Show current date
          python, py    - Show Python version
          ls, dir       - List files
          pwd           - Print working directory
          whoami        - Show current user
          uname         - Show system information
        """
        for line in helpText.components(separatedBy: "\n") {
            outputLines.append(TerminalLine(
                prompt: "",
                output: line,
                type: .output
            ))
        }
    }
    
    func clearTerminal() {
        outputLines.removeAll()
    }
    
    func toggleAutoScroll() {
        autoScroll.toggle()
    }
    
    func showKeyboardShortcuts() {
    }
    
    func navigateHistory(direction: Int) {
        guard !commandHistory.isEmpty else { return }
        
        historyIndex += direction
        
        if historyIndex < 0 {
            historyIndex = 0
        } else if historyIndex >= commandHistory.count {
            historyIndex = commandHistory.count - 1
            inputCommand = ""
            return
        }
        
        inputCommand = commandHistory[historyIndex]
    }
}