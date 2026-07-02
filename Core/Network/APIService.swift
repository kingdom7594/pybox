import Foundation

/// DeepSeek API 客户端 (OpenAI 兼容)
/// 支持流式响应、自动重试、新模型 (deepseek-v4-flash, deepseek-v4-pro, deepseek-reasoner)
actor APIService {
    static let shared = APIService()

    private let baseURL = "https://api.deepseek.com/v1"

    /// 可用模型 (按 2026-06 官网)
    static let availableModels: [String] = [
        "deepseek-v4-flash",     // 快速模型 (默认)
        "deepseek-v4-pro",       // 高质量模型
        "deepseek-reasoner",     // 推理模型 (CoT)
    ]

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "deepseekApiKey") ?? ""
    }

    private var model: String {
        let stored = UserDefaults.standard.string(forKey: "aiModel") ?? "deepseek-v4-flash"
        return Self.availableModels.contains(stored) ? stored : "deepseek-v4-flash"
    }

    // MARK: - Types

    enum ChatRole: String, Codable {
        case system, user, assistant
    }

    struct ChatMessage: Codable {
        let role: ChatRole
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int
        let stream: Bool
    }

    struct ChatChoice: Codable {
        let message: ChatMessage
    }

    struct ChatResponse: Codable {
        let choices: [ChatChoice]
    }

    struct StreamDelta: Codable {
        struct Delta: Codable {
            let role: ChatRole?
            let content: String?
        }
        let choices: [Choice]
        struct Choice: Codable {
            let delta: Delta
        }
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized
        case rateLimited
        case serverError(statusCode: Int)
        case noContent
        case streaming(String)
        case decoding(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from server"
            case .unauthorized: return "Invalid API key. Please check your DeepSeek API key in Settings."
            case .rateLimited: return "Rate limited. Please wait a moment and try again."
            case .serverError(let s): return "Server error: \(s)"
            case .noContent: return "No response content"
            case .streaming(let m): return "Streaming error: \(m)"
            case .decoding(let m): return "Decoding error: \(m)"
            }
        }
    }

    // MARK: - Public API

    /// 非流式对话
    func sendMessage(messages: [AIMessage], systemPrompt: String? = nil) async throws -> String {
        let chatMessages = buildChatMessages(from: messages, systemPrompt: systemPrompt)
        let request = makeRequest(messages: chatMessages, stream: false)
        let (data, response) = try await performWithRetry(request: request)
        try validate(response: response)
        do {
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content else {
                throw APIError.noContent
            }
            return content
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    /// 流式对话 - 逐 chunk 回调
    /// - Parameters:
    ///   - onDelta: 每个文本片段回调（用于实时 UI 更新）
    ///   - onComplete: 完整响应回调
    func sendMessageStream(
        messages: [AIMessage],
        systemPrompt: String? = nil,
        onDelta: @MainActor @escaping (String) -> Void
    ) async throws -> String {
        let chatMessages = buildChatMessages(from: messages, systemPrompt: systemPrompt)
        var request = makeRequest(messages: chatMessages, stream: true)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        try validate(response: response)

        var fullContent = ""
        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }
            if line.hasPrefix("data:") {
                let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" { break }
                if let data = payload.data(using: .utf8) {
                    do {
                        let chunk = try JSONDecoder().decode(StreamDelta.self, from: data)
                        if let contentDelta = chunk.choices.first?.delta.content {
                            fullContent += contentDelta
                            await onDelta(contentDelta)
                        }
                    } catch {
                        // 跳过非 JSON 行（心跳等）
                        continue
                    }
                }
            }
        }
        return fullContent
    }

    /// 带指数退避的重试
    private func performWithRetry(request: URLRequest, maxAttempts: Int = 3) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await URLSession.shared.data(for: request)
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delayMs = Int(pow(2.0, Double(attempt))) * 500 // 500ms, 1s, 2s
                    try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
                }
            }
        }
        throw lastError ?? APIError.invalidResponse
    }

    // MARK: - Helpers

    private func buildChatMessages(from messages: [AIMessage], systemPrompt: String?) -> [ChatMessage] {
        var result: [ChatMessage] = []
        if let sys = systemPrompt, !sys.isEmpty {
            result.append(ChatMessage(role: .system, content: sys))
        }
        for m in messages {
            let role: ChatRole = m.isUser ? .user : .assistant
            result.append(ChatMessage(role: role, content: m.content))
        }
        return result
    }

    private func makeRequest(messages: [ChatMessage], stream: Bool) -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            fatalError("Invalid baseURL: \(baseURL)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body = ChatRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            max_tokens: 2048,
            stream: stream
        )
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw APIError.unauthorized
        case 429: throw APIError.rateLimited
        default: throw APIError.serverError(statusCode: http.statusCode)
        }
    }

    // MARK: - Public Convenience

    var hasApiKey: Bool { !apiKey.isEmpty }
    var currentModel: String { model }
}
