import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AIAssistantViewModel()
    @ObservedObject private var usage = UsageManager.shared
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            aiHeader

            // 对话区
            messagesScroll

            // 快捷操作
            quickActions

            // 输入栏
            inputBar
        }
        .background(Theme.Colors.background)
        .overlay {
            PaywallView(isPresented: $showPaywall)
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
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionActivated)) { _ in
            showPaywall = false
        }
    }

    // MARK: - 头部（对齐原型 .ai-header）
    private var aiHeader: some View {
        HStack(spacing: 10) {
            // Avatar
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.dec],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .frame(width: 32, height: 32)

            // 标题 + 状态
            VStack(alignment: .leading, spacing: 1) {
                Text("AI 助手")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundColor(Theme.Colors.fg)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text("在线 · DeepSeek · 代码模型")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.muted)
                }
            }

            Spacer()

            // 额度 badge
            badgeView
                .onTapGesture {
                    if !subscription.isSubscribed && usage.remaining <= 0 {
                        showPaywall = true
                    }
                }

            // 模型 badge
            Text("v3")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.Colors.surface2)
                        .overlay(Capsule().stroke(Theme.Colors.border, lineWidth: 1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.surface)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Colors.border)
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        if subscription.isSubscribed {
            Text("∞ 已订阅")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.Colors.accentDim))
                .overlay(Capsule().stroke(Theme.Colors.border, lineWidth: 1))
        } else if usage.remaining <= 0 {
            Text("已用完 · 订阅")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.danger)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.Colors.danger.opacity(0.2)))
                .overlay(Capsule().stroke(Theme.Colors.danger, lineWidth: 1))
        } else if usage.remaining <= 3 {
            Text("剩余 \(usage.remaining) 次")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.danger)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.Colors.danger.opacity(0.2)))
                .overlay(Capsule().stroke(Theme.Colors.danger, lineWidth: 1))
        } else {
            Text("剩余 \(usage.remaining) 次")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.Colors.accentDim))
                .overlay(Capsule().stroke(Theme.Colors.border, lineWidth: 1))
        }
    }

    // MARK: - 对话区
    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(
                            message: message,
                            onInsertCode: { code in
                                _ = viewModel.insertCodeToEditor(code)
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
                                .tint(Theme.Colors.accent)
                            Text("AI 正在思考...")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.muted)
                        }
                        .padding(.horizontal, 16)
                    }

                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Theme.Colors.warn)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.warn)
                            Spacer()
                            Button("重试") { viewModel.retryLast() }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.warn)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.warn.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Theme.Colors.background)
    }

    // MARK: - 快捷操作（对齐原型 .ai-actions）
    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(QuickPrompt.allCases) { prompt in
                    Button {
                        applyQuick(prompt)
                    } label: {
                        Text(prompt.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(
                                viewModel.selectedQuickPrompt == prompt
                                    ? Theme.Colors.accent
                                    : Theme.Colors.muted
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        viewModel.selectedQuickPrompt == prompt
                                            ? Theme.Colors.accentDim
                                            : Theme.Colors.surface2
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            viewModel.selectedQuickPrompt == prompt
                                                ? Theme.Colors.accent
                                                : Theme.Colors.border,
                                            lineWidth: 1
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.pressable)
                    .disabled(!usage.canUse)
                    .opacity(usage.canUse ? 1 : 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.Colors.background)
    }

    private func applyQuick(_ prompt: QuickPrompt) {
        guard usage.canUse else {
            showPaywall = true
            return
        }
        viewModel.applyQuickPrompt(prompt)
        viewModel.sendMessage()
        usage.consume()
    }

    // MARK: - 输入栏（对齐原型 .ai-input-row）
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("输入问题...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Theme.Colors.surface2)
                        .overlay(
                            Capsule().stroke(
                                viewModel.inputText.isEmpty ? Theme.Colors.border : Theme.Colors.accent,
                                lineWidth: 1
                            )
                        )
                )
                .foregroundColor(Theme.Colors.fg)
                .accentColor(Theme.Colors.accent)
                .disabled(viewModel.isLoading || !usage.canUse)
                .opacity(usage.canUse ? 1 : 0.4)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canSend ? Theme.Colors.accent : Theme.Colors.surface2))
            }
            .buttonStyle(.pressable)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Theme.Colors.surface)
        .overlay(alignment: .top) {
            Divider().background(Theme.Colors.border)
        }
    }

    private var canSend: Bool {
        !viewModel.isLoading &&
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        usage.canUse
    }

    private func sendMessage() {
        guard usage.canUse else {
            showPaywall = true
            return
        }
        viewModel.sendMessage()
        usage.consume()
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(AppState())
}

// MARK: - Chat Bubble（对齐原型 .ai-msg）

struct ChatBubbleView: View {
    let message: AIMessage
    let onInsertCode: (String) -> Void
    let onCopyCode: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
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
                .font(.system(size: 14))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedCorners(tl: 18, tr: 18, bl: 4, br: 18)
                        .fill(Theme.Colors.accent)
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.fg)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedCorners(tl: 18, tr: 18, bl: 18, br: 4)
                            .fill(Theme.Colors.surface)
                    )
                    .overlay(
                        RoundedCorners(tl: 18, tr: 18, bl: 18, br: 4)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
            }

            ForEach(message.codeBlocks) { block in
                CodeBlockView(
                    block: block,
                    onInsert: { onInsertCode(block.code) },
                    onCopy: { onCopyCode(block.code) }
                )
            }
        }
    }
}

// MARK: - Code Block（对齐原型 .code-b）

struct CodeBlockView: View {
    let block: AICodeBlock
    let onInsert: () -> Void
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(block.language ?? "code")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.accent)
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
                            .font(.system(size: 10))
                        Text(showCopied ? "已复制" : "复制")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.surface3)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.Colors.codeBg)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(block.code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.Colors.terminalText)
                    .padding(10)
            }
            .background(Theme.Colors.codeBg)

            HStack {
                Spacer()
                Button(action: onInsert) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11))
                        Text("插入到编辑器")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.accent)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.codeBg)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Rounded Corners Helper

struct RoundedCorners: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: tl, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: tr), control: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addQuadCurve(to: CGPoint(x: w - br, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - bl), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addQuadCurve(to: CGPoint(x: tl, y: 0), control: CGPoint(x: 0, y: 0))
        return path
    }
}
