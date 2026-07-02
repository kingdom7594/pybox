import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AIAssistantViewModel()

    var body: some View {
        VStack(spacing: 0) {
            contextBanner

            quickPromptsBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(
                                message: message,
                                onInsertCode: { code in
                                    viewModel.insertCodeToEditor(code)
                                },
                                onCopyCode: { code in
                                    viewModel.copyCode(code)
                                }
                            )
                            .id(message.id)
                        }

                        if viewModel.isLoading && viewModel.messages.last?.content.isEmpty == true {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI 正在思考...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("重试") { viewModel.retryLast() }
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }

            inputBar
        }
        .navigationTitle("AI Assistant")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Toggle(isOn: $viewModel.privacyMode) {
                        Label("隐私模式", systemImage: viewModel.privacyMode ? "eye.slash" : "eye")
                    }
                    Divider()
                    Button(role: .destructive, action: viewModel.clearChat) {
                        Label("清空对话", systemImage: "trash")
                    }
                    if viewModel.isLoading {
                        Button(action: viewModel.cancelStream) {
                            Label("停止生成", systemImage: "stop.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.updateContext(
                fileName: appState.activeFileName,
                fileContent: appState.activeFileContent,
                language: appState.activeFileLanguage
            )
        }
        .onChange(of: appState.activeFileName) { _ in
            viewModel.updateContext(
                fileName: appState.activeFileName,
                fileContent: appState.activeFileContent,
                language: appState.activeFileLanguage
            )
        }
        .onChange(of: appState.activeFileContent) { _ in
            viewModel.updateContext(
                fileName: appState.activeFileName,
                fileContent: appState.activeFileContent,
                language: appState.activeFileLanguage
            )
        }
    }

    // MARK: - Context Banner

    @ViewBuilder
    private var contextBanner: some View {
        if viewModel.currentContext.hasFile {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(viewModel.currentContext.fileName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if viewModel.privacyMode {
                    Label("隐私模式", systemImage: "eye.slash.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Label("已附加上下文", systemImage: "link")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemBackground))
        }
    }

    // MARK: - Quick Prompts Bar

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickPrompt.allCases) { prompt in
                    Button {
                        viewModel.applyQuickPrompt(prompt)
                    } label: {
                        HStack(spacing: 4) {
                            Text(prompt.icon)
                            Text(prompt.label)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(
                                viewModel.selectedQuickPrompt == prompt
                                    ? Color.blue.opacity(0.2)
                                    : Color(uiColor: .tertiarySystemBackground)
                            )
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("问 AI 一个问题...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isLoading)
                .onSubmit { viewModel.sendMessage() }

            if viewModel.isLoading {
                Button(action: viewModel.cancelStream) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            } else {
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: AIMessage
    let onInsertCode: (String) -> Void
    let onCopyCode: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                userBubble
            } else {
                aiBubble
                Spacer(minLength: 40)
            }
        }
    }

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !message.content.isEmpty {
                Text(message.content)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
            }

            ForEach(message.codeBlocks) { block in
                CodeBlockView(
                    block: block,
                    onInsert: { onInsertCode(block.code) },
                    onCopy: { onCopyCode(block.code) }
                )
            }

            if !message.isUser {
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Code Block

struct CodeBlockView: View {
    let block: AICodeBlock
    let onInsert: () -> Void
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(block.language ?? "code")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.green)
                Spacer()
                Button(action: {
                    onCopy()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.caption)
                        Text(showCopied ? "已复制" : "复制")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.85))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(10)
            }
            .background(Color.black)

            HStack {
                Spacer()
                Button(action: onInsert) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.caption)
                        Text("插入到编辑器")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(8)
            }
            .background(Color.black.opacity(0.95))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        AIAssistantView()
            .environmentObject(AppState())
    }
}
