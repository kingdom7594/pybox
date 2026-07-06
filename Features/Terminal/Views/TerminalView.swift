import SwiftUI

struct TerminalView: View {
    @State private var sessions: [TermSession] = [
        TermSession(name: "local", isLocal: true, isActive: true),
        TermSession(name: "SSH: server01", isLocal: false, isActive: false),
        TermSession(name: "SSH: dev-box", isLocal: false, isActive: false)
    ]
    @State private var lines: [TermLine] = []
    @State private var inputCommand = ""
    @State private var history: [String] = []
    @State private var histIdx = -1
    @FocusState private var inputFocused: Bool

    struct TermSession: Identifiable {
        let id = UUID()
        let name: String
        let isLocal: Bool
        var isActive: Bool
    }

    struct TermLine: Identifiable {
        let id = UUID()
        let prompt: String
        let text: String
        let type: LineType

        enum LineType { case input, output, error, success }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            sessionBar
            terminalContent
        }
        .background(Theme.Colors.codeBg)
        .onAppear { initTerminal() }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Text("~ $")
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(Theme.Colors.fg)

            Spacer()

            Button {
                let n = sessions.count + 1
                sessions.append(TermSession(name: "SSH: session\(n)", isLocal: false, isActive: false))
                showToast("已新建会话: SSH: session\(n)")
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.fg)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.surface2)
                    )
            }
            .buttonStyle(.pressable)

            Button {
                NotificationCenter.default.post(name: .switchToTab, object: ContentView.Tab.editor)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.fg)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.surface2)
                    )
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Theme.Colors.surface)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Colors.border)
        }
    }

    // MARK: - 会话栏
    private var sessionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach($sessions) { $session in
                    Button {
                        for i in sessions.indices { sessions[i].isActive = false }
                        session.isActive = true
                        switchSession(session)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(session.isLocal ? Theme.Colors.success : Theme.Colors.muted2)
                                .frame(width: 6, height: 6)
                            Text(session.name)
                                .font(.system(size: 12, design: .monospaced))
                        }
                        .foregroundColor(session.isActive ? Theme.Colors.accent : Theme.Colors.muted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(session.isActive ? Theme.Colors.accent : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .background(Theme.Colors.terminalBar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Colors.terminalKeyBorder).frame(height: 1)
        }
    }

    // MARK: - 终端主体
    private var terminalContent: some View {
        VStack(spacing: 0) {
            // 输出区
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { line in
                            terminalLineView(line)
                                .id(line.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .onChange(of: lines.count) { _ in
                    if let last = lines.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // 输入行
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Theme.Colors.success)

                TextField("输入命令...", text: $inputCommand)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Theme.Colors.terminalText)
                    .accentColor(Theme.Colors.accent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($inputFocused)
                    .onSubmit { executeCommand() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.terminalBar)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.Colors.terminalKeyBorder).frame(height: 1)
            }

            // 快捷命令栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    quickKey("python ") { inputCommand = "python " }
                    quickKey("pip install ") { inputCommand = "pip install " }
                    quickKey("ls -la") { inputCommand = "ls -la" }
                    quickKey("git status") { inputCommand = "git status" }
                    quickKey("npm start") { inputCommand = "npm start" }
                    quickKey("clear") { inputCommand = "clear" }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Theme.Colors.terminalKeysBar)
        }
        .background(Theme.Colors.codeBg)
    }

    @ViewBuilder
    private func terminalLineView(_ line: TermLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if !line.prompt.isEmpty {
                Text(line.prompt)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(promptColor(line.type))
            }
            Text(line.text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(textColor(line.type))
                .lineSpacing(2)
                .textSelection(.enabled)
            Spacer()
        }
    }

    private func promptColor(_ type: TermLine.LineType) -> Color {
        switch type {
        case .input: return Theme.Colors.accent
        case .output: return Theme.Colors.muted
        case .error: return Theme.Colors.danger
        case .success: return Theme.Colors.success
        }
    }

    private func textColor(_ type: TermLine.LineType) -> Color {
        switch type {
        case .input: return Theme.Colors.terminalText
        case .output: return Theme.Colors.terminalOutput
        case .error: return Theme.Colors.danger
        case .success: return Theme.Colors.success
        }
    }

    @ViewBuilder
    private func quickKey(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Colors.terminalKeyBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.Colors.terminalKeyBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.pressable)
    }

    // MARK: - 终端逻辑
    private func initTerminal() {
        lines = [
            TermLine(prompt: "", text: "PythonIDE Terminal · Python 3.13.1", type: .output),
            TermLine(prompt: "", text: "Type \"python main.py\" or \"ls\" to start", type: .output),
            TermLine(prompt: "user@pythonide:~/project$ ", text: "help", type: .input),
            TermLine(prompt: "", text: "Available commands:\n  python, pip, npm, git\n  ls, cd, pwd, cat, mkdir, rm, cp, mv\n  echo, grep, awk, sed\n  curl, wget, ping\n  clear, history, uname, whoami, date, uptime", type: .output),
        ]
    }

    private func switchSession(_ session: TermSession) {
        showToast("切换到: \(session.name)")
        if session.isLocal {
            lines = [
                TermLine(prompt: "", text: "PythonIDE Terminal · Python 3.13.1", type: .output),
                TermLine(prompt: "user@pythonide:~/project$ ", text: "python main.py", type: .input),
                TermLine(prompt: "", text: "Computing Fibonacci...\nfib(0) = 0 … fib(9) = 34", type: .output),
                TermLine(prompt: "", text: "✓ 运行完成，0.09s", type: .success),
            ]
        } else {
            lines = [
                TermLine(prompt: "user@pythonide:~/project$ ", text: "ssh \(session.name.replacingOccurrences(of: "SSH: ", with: ""))", type: .input),
                TermLine(prompt: "", text: "Connection refused", type: .error),
                TermLine(prompt: "", text: "提示：SSH 服务器未连接，请在设置中添加服务器信息", type: .output),
            ]
        }
    }

    private func executeCommand() {
        let cmd = inputCommand.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }

        history.append(cmd)
        histIdx = history.count

        lines.append(TermLine(prompt: "user@pythonide:~/project$ ", text: cmd, type: .input))
        inputCommand = ""

        if cmd == "clear" || cmd == "cls" {
            lines = []
            return
        }

        if let result = parseCommand(cmd) {
            lines.append(TermLine(prompt: "", text: result.text, type: result.type))
        }
    }

    private func parseCommand(_ cmd: String) -> TermLine? {
        let parts = cmd.split(separator: " ").map(String.init)
        let c = parts[0].lowercased()
        let args = Array(parts.dropFirst())

        switch c {
        case "pwd":
            return TermLine(prompt: "", text: "/home/user/project", type: .output)
        case "whoami":
            return TermLine(prompt: "", text: "user", type: .output)
        case "ls":
            return TermLine(prompt: "", text: "main.py  utils.py  config.json  requirements.txt  README.md  data/  tests/", type: .output)
        case "echo":
            return TermLine(prompt: "", text: args.joined(separator: " "), type: .output)
        case "python", "python3":
            if args.isEmpty { return TermLine(prompt: "", text: "Python 3.13.1\nType \"help()\" for more information.", type: .output) }
            if args[0] == "--version" || args[0] == "-V" { return TermLine(prompt: "", text: "Python 3.13.1", type: .output) }
            if args[0] == "main.py" { return TermLine(prompt: "", text: "fib(10) = 55\nfact(10) = 3628800", type: .output) }
            return TermLine(prompt: "", text: "[Executing \(args[0])...]", type: .output)
        case "pip":
            if args.isEmpty { return TermLine(prompt: "", text: "pip 24.0\nUsage: pip <command> [options]", type: .output) }
            if args[0] == "list" { return TermLine(prompt: "", text: "numpy\npandas\nmatplotlib\nrequests\nflask", type: .output) }
            return TermLine(prompt: "", text: "pip: \(args[0])", type: .output)
        case "git":
            if args.isEmpty { return TermLine(prompt: "", text: "usage: git <command> [<args>]", type: .output) }
            if args[0] == "status" { return TermLine(prompt: "", text: "On branch main\nChanges not staged for commit:\n  modified:   main.py\n  modified:   utils.py", type: .output) }
            if args[0] == "log" { return TermLine(prompt: "", text: "commit a3f8d21 (HEAD -> main)\n    Add new feature", type: .output) }
            return TermLine(prompt: "", text: "git: \(args[0])", type: .output)
        case "help":
            return TermLine(prompt: "", text: "Available commands: python, pip, npm, git, ls, cd, pwd, cat, echo, clear, help", type: .output)
        case "date":
            return TermLine(prompt: "", text: Date().description, type: .output)
        case "uname":
            return TermLine(prompt: "", text: "Darwin", type: .output)
        case "history":
            let text = history.enumerated().map { "  \($0.offset + 1)  \($0.element)" }.joined(separator: "\n")
            return TermLine(prompt: "", text: text, type: .output)
        default:
            return TermLine(prompt: "", text: "\(c): command not found", type: .error)
        }
    }
}

#Preview {
    TerminalView()
}
