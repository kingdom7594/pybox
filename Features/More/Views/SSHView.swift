import SwiftUI

struct SSHServer: Identifiable {
    let id = UUID()
    var name: String
    var host: String
    var port: Int
    var user: String
    var isConnected: Bool = false
}

struct SSHView: View {
    @State private var servers: [SSHServer] = [
        SSHServer(name: "生产服务器", host: "1.2.3.4", port: 22, user: "root"),
        SSHServer(name: "测试服务器", host: "5.6.7.8", port: 22, user: "ubuntu"),
        SSHServer(name: "树莓派", host: "192.168.1.100", port: 22, user: "pi")
    ]
    @State private var terminalLines: [String] = []
    @State private var commandText: String = ""
    @State private var connectedServerId: UUID?
    @State private var showAddSheet: Bool = false
    @State private var newName: String = ""
    @State private var newHost: String = ""
    @State private var newUser: String = ""
    @State private var newPort: String = "22"
    @FocusState private var inputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(servers) { server in
                    serverCard(server)
                }
                if let cid = connectedServerId,
                   let idx = servers.firstIndex(where: { $0.id == cid }) {
                    terminalArea(for: servers[idx])
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("SSH 终端")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addSheet
        }
    }

    private func serverCard(_ s: SSHServer) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(s.isConnected ? Theme.Colors.success : Theme.Colors.muted2)
                    .frame(width: 8, height: 8)
                Text(s.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.fg)
                Spacer()
                Button {
                    toggleConnection(s)
                } label: {
                    Text(s.isConnected ? "断开" : "连接")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(s.isConnected ? Theme.Colors.danger : Theme.Colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(
                                (s.isConnected ? Theme.Colors.danger : Theme.Colors.accent).opacity(0.15)
                            )
                        )
                }
                .buttonStyle(.pressable)
            }
            Text("\(s.user)@\(s.host):\(s.port)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Theme.Colors.muted)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(Theme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private func terminalArea(for s: SSHServer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(s.user)@\(s.host):~$")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.Colors.success)
                Spacer()
                Text("已连接")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.success)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 8)
            .background(Theme.Colors.surface2)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(terminalLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Theme.Colors.fg)
                            .textSelection(.enabled)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .frame(minHeight: 120, maxHeight: 220)
            .background(Theme.Colors.codeBg)

            HStack(spacing: 8) {
                Text("$")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Theme.Colors.success)
                TextField("输入命令", text: $commandText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Theme.Colors.fg)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($inputFocused)
                    .onSubmit { executeCommand() }
                Button {
                    executeCommand()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(commandText.isEmpty ? Theme.Colors.muted2 : Theme.Colors.accent)
                }
                .disabled(commandText.isEmpty)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 10)
            .background(Theme.Colors.surface)
            .overlay(alignment: .top) {
                Divider().background(Theme.Colors.border)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(Theme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("服务器信息") {
                    TextField("名称", text: $newName)
                    TextField("主机", text: $newHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("用户", text: $newUser)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("端口", text: $newPort)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("添加服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showAddSheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") { addServer() }
                        .disabled(newName.isEmpty || newHost.isEmpty || newUser.isEmpty)
                }
            }
        }
    }

    private func toggleConnection(_ s: SSHServer) {
        guard let idx = servers.firstIndex(where: { $0.id == s.id }) else { return }
        servers[idx].isConnected.toggle()
        if servers[idx].isConnected {
            connectedServerId = s.id
            terminalLines = [
                "# 已连接到 \(s.name) (\(s.user)@\(s.host):\(s.port))",
                "# 欢迎使用 SSH 终端，输入 help 查看可用命令"
            ]
            showToast("已连接 \(s.name)")
        } else {
            if connectedServerId == s.id {
                connectedServerId = nil
                terminalLines = []
            }
            showToast("已断开 \(s.name)")
        }
    }

    private func executeCommand() {
        let cmd = commandText.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }
        if cmd == "clear" {
            terminalLines.removeAll()
            commandText = ""
            return
        }
        terminalLines.append("$ \(cmd)")
        terminalLines.append(simulate(cmd))
        commandText = ""
    }

    private func simulate(_ cmd: String) -> String {
        let parts = cmd.split(separator: " ")
        let base = parts.first.map(String.init) ?? cmd
        switch base {
        case "ls":
            return "Desktop  Documents  Downloads  Music  Pictures  Public"
        case "pwd":
            return "/home/\(parts.count > 1 ? String(parts[1]) : "user")"
        case "whoami":
            return "user"
        case "uptime":
            return " 14:23:01 up 3 days,  2:15,  1 user,  load average: 0.12, 0.18, 0.20"
        case "date":
            return "Mon Jul  6 14:23:01 CST 2026"
        case "echo":
            return parts.dropFirst().joined(separator: " ")
        case "hostname":
            return "prod-server-01"
        case "help":
            return "可用命令: ls, pwd, whoami, uptime, date, echo, hostname, clear"
        default:
            return "command not found: \(base)"
        }
    }

    private func addServer() {
        let port = Int(newPort) ?? 22
        servers.append(SSHServer(name: newName, host: newHost, port: port, user: newUser))
        newName = ""
        newHost = ""
        newUser = ""
        newPort = "22"
        showAddSheet = false
        showToast("已添加服务器")
    }
}

#Preview {
    SSHView()
}
