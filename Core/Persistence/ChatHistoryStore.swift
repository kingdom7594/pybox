import Foundation
import SQLite

/// 本地对话历史存储 (SQLite)
/// - 容量上限: 1000 条
/// - 路径: Documents/chat_history.sqlite3
final class ChatHistoryStore {
    static let shared = ChatHistoryStore()

    private let db: Connection?
    private let messages = Table("messages")
    private let id = SQLite.Expression<String>("id")
    private let role = SQLite.Expression<String>("role")
    private let content = SQLite.Expression<String>("content")
    private let codeBlocks = SQLite.Expression<String?>("code_blocks")
    private let timestamp = SQLite.Expression<Double>("timestamp")

    private let maxRecords = 1000

    private init() {
        let opened: Connection?
        do {
            let docs = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbPath = docs.appendingPathComponent("chat_history.sqlite3").path
            opened = try Connection(dbPath)
        } catch {
            NSLog("[ChatHistoryStore] Failed to open: \(error)")
            opened = nil
        }
        self.db = opened
        do {
            try createTable()
        } catch {
            NSLog("[ChatHistoryStore] createTable error: \(error)")
        }
    }

    private func createTable() throws {
        guard let db = db else { return }
        try db.run(messages.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(role)
            t.column(content)
            t.column(codeBlocks)
            t.column(timestamp)
        })
    }

    // MARK: - Save

    func save(_ message: AIMessage) {
        guard let db = db else { return }
        do {
            let codeBlocksJSON = encodeCodeBlocks(message.codeBlocks)
            try db.run(messages.insert(or: .replace,
                id <- message.id.uuidString,
                role <- message.isUser ? "user" : "assistant",
                content <- message.content,
                codeBlocks <- codeBlocksJSON,
                timestamp <- message.timestamp.timeIntervalSince1970
            ))
            enforceLimit()
        } catch {
            NSLog("[ChatHistoryStore] save error: \(error)")
        }
    }

    func saveAll(_ list: [AIMessage]) {
        guard let db = db else { return }
        do {
            try db.transaction {
                for m in list {
                    let json = encodeCodeBlocks(m.codeBlocks)
                    try db.run(messages.insert(or: .replace,
                        id <- m.id.uuidString,
                        role <- m.isUser ? "user" : "assistant",
                        content <- m.content,
                        codeBlocks <- json,
                        timestamp <- m.timestamp.timeIntervalSince1970
                    ))
                }
            }
            enforceLimit()
        } catch {
            NSLog("[ChatHistoryStore] saveAll error: \(error)")
        }
    }

    // MARK: - Load

    func loadRecent(limit: Int = 200) -> [AIMessage] {
        guard let db = db else { return [] }
        var result: [AIMessage] = []
        do {
            let query = messages.order(timestamp.desc).limit(limit)
            for row in try db.prepare(query) {
                let isUser = row[role] == "user"
                let codeBlockList = decodeCodeBlocks(row[codeBlocks])
                var msg = AIMessage(
                    content: row[content],
                    isUser: isUser,
                    codeBlocks: codeBlockList,
                    timestamp: Date(timeIntervalSince1970: row[timestamp])
                )
                // 保留原始 id 让 ChatHistoryStore 持久化幂等
                _ = UUID(uuidString: row[id]) // validate only
                result.append(msg)
            }
            return result.reversed()
        } catch {
            NSLog("[ChatHistoryStore] loadRecent error: \(error)")
            return []
        }
    }

    // MARK: - Clear

    func clearAll() {
        guard let db = db else { return }
        do {
            try db.run(messages.delete())
        } catch {
            NSLog("[ChatHistoryStore] clearAll error: \(error)")
        }
    }

    // MARK: - Helpers

    private func enforceLimit() {
        guard let db = db else { return }
        do {
            let count = try db.scalar(messages.count)
            if count > maxRecords {
                let overflow = count - maxRecords
                let oldest = messages.order(timestamp.asc).limit(overflow)
                try db.run(oldest.delete())
            }
        } catch {
            NSLog("[ChatHistoryStore] enforceLimit error: \(error)")
        }
    }

    private func encodeCodeBlocks(_ blocks: [AICodeBlock]) -> String? {
        guard !blocks.isEmpty else { return nil }
        let data = blocks.map { ["code": $0.code, "language": $0.language ?? ""] }
        if let json = try? JSONSerialization.data(withJSONObject: data),
           let str = String(data: json, encoding: .utf8) {
            return str
        }
        return nil
    }

    private func decodeCodeBlocks(_ json: String?) -> [AICodeBlock] {
        guard let json = json,
              let data = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        return arr.map { dict in
            AICodeBlock(
                code: dict["code"] ?? "",
                language: dict["language"]?.isEmpty == false ? dict["language"] : nil
            )
        }
    }
}
