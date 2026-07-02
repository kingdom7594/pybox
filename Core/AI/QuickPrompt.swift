import Foundation

/// 5 个快捷问题模板 - 注入上下文后向 AI 发送
enum QuickPrompt: String, CaseIterable, Identifiable {
    case explain = "explain"
    case debug = "debug"
    case complete = "complete"
    case comment = "comment"
    case refactor = "refactor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .explain:   return "💡"
        case .debug:     return "🐛"
        case .complete:  return "✨"
        case .comment:   return "📝"
        case .refactor:  return "🔧"
        }
    }

    var label: String {
        switch self {
        case .explain:   return "解释代码"
        case .debug:     return "调试 Bug"
        case .complete:  return "补全代码"
        case .comment:   return "添加注释"
        case .refactor:  return "重构优化"
        }
    }

    /// 当用户没有附加具体问题时使用的通用 prompt
    var genericPrompt: String {
        switch self {
        case .explain:
            return "请详细解释这段代码的作用、关键逻辑和潜在风险。"
        case .debug:
            return "请仔细检查这段代码，找出可能的 Bug 并给出修复建议。"
        case .complete:
            return "请基于现有代码，给出合理的代码补全或后续实现。"
        case .comment:
            return "请为这段代码添加清晰的中文注释，解释每个函数和关键步骤。"
        case .refactor:
            return "请重构这段代码以提升可读性、性能和可维护性，并给出重构后的版本。"
        }
    }

    /// 构造带用户问题的完整 prompt
    func buildPrompt(userQuestion: String, fileName: String) -> String {
        if userQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return genericPrompt + "\n\n文件名: \(fileName)"
        }
        return "\(genericPrompt)\n\n用户补充问题: \(userQuestion)\n\n文件名: \(fileName)"
    }
}
