import SwiftUI
import Combine

@MainActor
class AIAssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var currentContext: AIContext = .empty
    @Published var privacyMode: Bool {
        didSet { UserDefaults.standard.set(privacyMode, forKey: "aiPrivacyMode") }
    }
    @Published var selectedQuickPrompt: QuickPrompt?

    private let api = APIService.shared
    private var streamTask: Task<Void, Never>?

    init() {
        self.privacyMode = UserDefaults.standard.bool(forKey: "aiPrivacyMode")
        loadFromCache()
        if messages.isEmpty {
            messages.append(AIMessage(
                content: "你好！我是 PyBox AI，可以帮你编写、调试和解释 Python 代码。\n\n💡 你可以输入问题，或使用下方的快捷模板。",
                isUser: false,
                timestamp: Date()
            ))
        }
    }

    private func loadFromCache() {
        let cached = ChatHistoryStore.shared.loadRecent(limit: 200)
        if !cached.isEmpty {
            messages = cached
        }
    }

    private func persistMessage(_ message: AIMessage) {
        ChatHistoryStore.shared.save(message)
    }

    deinit {
        streamTask?.cancel()
    }

    // MARK: - Context

    struct AIContext: Equatable {
        let fileName: String
        let fileContent: String
        let language: String

        static let empty = AIContext(fileName: "", fileContent: "", language: "python")
        var hasFile: Bool { !fileName.isEmpty && !fileContent.isEmpty }
    }

    /// 从 AppState 更新上下文
    func updateContext(fileName: String, fileContent: String, language: String) {
        currentContext = AIContext(fileName: fileName, fileContent: fileContent, language: language)
    }

    // MARK: - Quick Prompts

    /// 应用快捷模板
    func applyQuickPrompt(_ prompt: QuickPrompt) {
        selectedQuickPrompt = prompt
        if inputText.isEmpty {
            inputText = prompt.genericPrompt
        }
    }

    // MARK: - Send Message

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = AIMessage(content: trimmed, isUser: true, timestamp: Date())
        messages.append(userMessage)
        persistMessage(userMessage)
        inputText = ""
        selectedQuickPrompt = nil
        errorMessage = nil

        streamTask?.cancel()
        streamTask = Task { await streamResponse(userQuestion: trimmed) }
    }

    /// 重发最后一条用户消息
    func retryLast() {
        guard let lastUser = messages.last(where: { $0.isUser }) else { return }
        if let last = messages.last, !last.isUser {
            messages.removeLast()
        }
        inputText = lastUser.content
        sendMessage()
    }

    private func streamResponse(userQuestion: String) async {
        let hasKey = await api.hasApiKey
        guard hasKey else {
            errorMessage = "未配置 DeepSeek API Key。请前往「设置 → AI 设置」配置。"
            return
        }

        isLoading = true
        let placeholderIndex = messages.count
        messages.append(AIMessage(content: "", isUser: false, timestamp: Date()))

        let systemPrompt = SystemPromptBuilder.build(
            fileName: currentContext.fileName,
            fileContent: currentContext.fileContent,
            language: currentContext.language,
            includeContext: !privacyMode
        )

        do {
            let fullResponse = try await api.sendMessageStream(
                messages: messages.dropLast().filter { !$0.content.isEmpty || $0.isUser },
                systemPrompt: systemPrompt
            ) { [weak self] delta in
                guard let self = self else { return }
                if placeholderIndex < self.messages.count {
                    self.messages[placeholderIndex].content += delta
                }
            }

            let parsed = MarkdownCodeBlockExtractor.parse(fullResponse)
            if placeholderIndex < messages.count {
                messages[placeholderIndex] = AIMessage(
                    content: parsed.plainText,
                    isUser: false,
                    codeBlocks: parsed.codeBlocks,
                    timestamp: messages[placeholderIndex].timestamp
                )
                persistMessage(messages[placeholderIndex])
            }
            errorMessage = nil
        } catch {
            if placeholderIndex < messages.count {
                messages[placeholderIndex] = AIMessage(
                    content: messages[placeholderIndex].content.isEmpty
                        ? "❌ \(error.localizedDescription)"
                        : messages[placeholderIndex].content + "\n\n❌ \(error.localizedDescription)",
                    isUser: false,
                    timestamp: messages[placeholderIndex].timestamp
                )
            }
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Message Actions

    /// 插入代码到编辑器（由 ChatBubbleView 的"插入编辑器"按钮触发）
    func insertCodeToEditor(_ code: String) -> String {
        NotificationCenter.default.post(
            name: .aiInsertCodeRequested,
            object: nil,
            userInfo: ["code": code]
        )
        return code
    }

    /// 复制代码到剪贴板
    func copyCode(_ code: String) {
        UIPasteboard.general.string = code
    }

    // MARK: - Chat Management

    func clearChat() {
        streamTask?.cancel()
        messages.removeAll()
        ChatHistoryStore.shared.clearAll()
        messages.append(AIMessage(
            content: "对话已清空。有什么新问题可以继续问我。",
            isUser: false,
            timestamp: Date()
        ))
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }
}

extension Notification.Name {
    static let aiInsertCodeRequested = Notification.Name("aiInsertCodeRequested")
}
