import Foundation

/// 从 AI 响应中提取 ```代码块``` 标记
enum MarkdownCodeBlockExtractor {

    struct Parsed {
        let plainText: String
        let codeBlocks: [AICodeBlock]
    }

    /// 解析 markdown 文本
    /// - Parameter raw: 原始 AI 响应
    /// - Returns: 纯文本（代码块替换为占位符）+ 提取的代码块列表
    static func parse(_ raw: String) -> Parsed {
        var codeBlocks: [AICodeBlock] = []
        let pattern = "```([a-zA-Z0-9_+\\-]*)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return Parsed(plainText: raw, codeBlocks: [])
        }

        let nsString = raw as NSString
        let matches = regex.matches(in: raw, options: [], range: NSRange(location: 0, length: nsString.length))

        var plainText = raw
        var offset = 0
        for match in matches {
            let langRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let fullRange = match.range(at: 0)

            let language: String?
            if langRange.location != NSNotFound {
                let langStr = nsString.substring(with: langRange)
                language = langStr.isEmpty ? nil : langStr
            } else {
                language = nil
            }
            let code = nsString.substring(with: codeRange)

            codeBlocks.append(AICodeBlock(code: code, language: language))

            let placeholder = "\n[代码 #\(codeBlocks.count)]\n"
            if let r = Range(fullRange, in: plainText) {
                let adjustedStart = plainText.index(plainText.startIndex, offsetBy: fullRange.location - offset)
                let adjustedEnd = plainText.index(adjustedStart, offsetBy: fullRange.length)
                plainText.replaceSubrange(adjustedStart..<adjustedEnd, with: placeholder)
                offset += fullRange.length - placeholder.count
            }
        }

        return Parsed(plainText: plainText.trimmingCharacters(in: .whitespacesAndNewlines), codeBlocks: codeBlocks)
    }
}
