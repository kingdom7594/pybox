import Foundation

/// 构造发给 DeepSeek 的 system prompt
enum SystemPromptBuilder {

    /// 基础 prompt + 文件上下文
    /// - Parameters:
    ///   - fileName: 当前文件名（空字符串表示无文件）
    ///   - fileContent: 当前文件内容
    ///   - language: 语言
    ///   - includeContext: 是否附加文件内容（隐私模式时为 false）
    static func build(
        fileName: String,
        fileContent: String,
        language: String,
        includeContext: Bool
    ) -> String {
        var parts: [String] = [
            "你是 PyBox iOS IDE 的 AI 助手，名字叫 PyBox AI。",
            "你的职责是帮助用户编写、调试、解释和优化 Python 代码。",
            "回答要简洁清晰，优先使用中文。",
            "当你提供代码时，必须用 ```\(language)\\n...\\n``` 包裹代码块。",
        ]

        guard includeContext, !fileContent.isEmpty else {
            parts.append("\n注意: 当前未启用文件上下文，用户的代码不会被上传（隐私模式）。")
            return parts.joined(separator: "\n")
        }

        let maxLen = 4000
        let truncated = fileContent.count > maxLen
            ? String(fileContent.prefix(maxLen)) + "\n# ... (文件过长已截断) ..."
            : fileContent

        parts.append("\n--- 当前文件: \(fileName) (\(language)) ---")
        parts.append("```\(language)")
        parts.append(truncated)
        parts.append("```")
        parts.append("\n请基于上面的文件内容回答用户的问题。")

        return parts.joined(separator: "\n")
    }
}
