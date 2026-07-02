import Foundation
import SQLite

/// 脚本运行历史存储 (SQLite)
/// - 容量上限: 500 条
/// - 路径: Documents/run_history.sqlite3
final class RunHistoryStore {
    static let shared = RunHistoryStore()

    private let db: Connection?
    private let history = Table("run_history")
    private let id = SQLite.Expression<String>("id")
    private let fileName = SQLite.Expression<String>("file_name")
    private let filePath = SQLite.Expression<String>("file_path")
    private let code = SQLite.Expression<String>("code")
    private let output = SQLite.Expression<String?>("output")
    private let error = SQLite.Expression<String?>("error")
    private let duration = SQLite.Expression<Double>("duration")
    private let timestamp = SQLite.Expression<Double>("timestamp")
    private let exitCode = SQLite.Expression<Int>("exit_code")

    private let maxRecords = 500

    private init() {
        let opened: Connection?
        do {
            let docs = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbPath = docs.appendingPathComponent("run_history.sqlite3").path
            opened = try Connection(dbPath)
        } catch {
            NSLog("[RunHistoryStore] Failed to open: \(error)")
            opened = nil
        }
        self.db = opened
        do {
            try createTable()
        } catch {
            NSLog("[RunHistoryStore] createTable error: \(error)")
        }
    }

    private func createTable() throws {
        guard let db = db else { return }
        try db.run(history.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(fileName)
            t.column(filePath)
            t.column(code)
            t.column(output)
            t.column(error)
            t.column(duration)
            t.column(timestamp)
            t.column(exitCode)
        })
        try db.run(history.createIndex(timestamp, ifNotExists: true))
    }

    // MARK: - Save

    /// 保存一次运行记录
    func save(_ record: RunRecord) {
        guard let db = db else { return }
        do {
            try db.run(history.insert(or: .replace,
                id <- record.id.uuidString,
                fileName <- record.fileName,
                filePath <- record.filePath,
                code <- record.code,
                output <- record.output,
                error <- record.error,
                duration <- record.duration,
                timestamp <- record.timestamp.timeIntervalSince1970,
                exitCode <- record.exitCode
            ))
            enforceLimit()
        } catch {
            NSLog("[RunHistoryStore] save error: \(error)")
        }
    }

    // MARK: - Load

    /// 加载最近的 N 条记录
    func loadRecent(limit: Int = 100) -> [RunRecord] {
        guard let db = db else { return [] }
        var result: [RunRecord] = []
        do {
            let query = history.order(timestamp.desc).limit(limit)
            for row in try db.prepare(query) {
                result.append(RunRecord(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    fileName: row[fileName],
                    filePath: row[filePath],
                    code: row[code],
                    output: row[output],
                    error: row[error],
                    duration: row[duration],
                    timestamp: Date(timeIntervalSince1970: row[timestamp]),
                    exitCode: row[exitCode]
                ))
            }
            return result
        } catch {
            NSLog("[RunHistoryStore] loadRecent error: \(error)")
            return []
        }
    }

    /// 按文件加载历史
    func loadByFile(filePath path: String, limit: Int = 20) -> [RunRecord] {
        guard let db = db else { return [] }
        var result: [RunRecord] = []
        do {
            let query = history
                .filter(self.filePath == path)
                .order(timestamp.desc)
                .limit(limit)
            for row in try db.prepare(query) {
                result.append(RunRecord(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    fileName: row[fileName],
                    filePath: row[filePath],
                    code: row[code],
                    output: row[output],
                    error: row[error],
                    duration: row[duration],
                    timestamp: Date(timeIntervalSince1970: row[timestamp]),
                    exitCode: row[exitCode]
                ))
            }
            return result
        } catch {
            NSLog("[RunHistoryStore] loadByFile error: \(error)")
            return []
        }
    }

    // MARK: - Delete

    /// 删除单条
    func delete(_ record: RunRecord) {
        guard let db = db else { return }
        do {
            let target = history.filter(id == record.id.uuidString)
            try db.run(target.delete())
        } catch {
            NSLog("[RunHistoryStore] delete error: \(error)")
        }
    }

    /// 清空全部
    func clearAll() {
        guard let db = db else { return }
        do {
            try db.run(history.delete())
        } catch {
            NSLog("[RunHistoryStore] clearAll error: \(error)")
        }
    }

    // MARK: - Stats

    /// 总数
    func count() -> Int {
        guard let db = db else { return 0 }
        return (try? db.scalar(history.count)) ?? 0
    }

    // MARK: - Helpers

    private func enforceLimit() {
        guard let db = db else { return }
        do {
            let total = try db.scalar(history.count)
            if total > maxRecords {
                let overflow = total - maxRecords
                let oldest = history.order(timestamp.asc).limit(overflow)
                try db.run(oldest.delete())
            }
        } catch {
            NSLog("[RunHistoryStore] enforceLimit error: \(error)")
        }
    }
}

/// 一次脚本运行的记录
struct RunRecord: Identifiable, Equatable {
    let id: UUID
    let fileName: String
    let filePath: String
    let code: String
    let output: String?
    let error: String?
    let duration: Double
    let timestamp: Date
    let exitCode: Int

    init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        code: String,
        output: String? = nil,
        error: String? = nil,
        duration: Double = 0,
        timestamp: Date = Date(),
        exitCode: Int = 0
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.code = code
        self.output = output
        self.error = error
        self.duration = duration
        self.timestamp = timestamp
        self.exitCode = exitCode
    }

    var wasSuccess: Bool { exitCode == 0 && error == nil }

    var durationFormatted: String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.2f s", duration)
        } else {
            let m = Int(duration / 60)
            let s = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(m)m \(s)s"
        }
    }
}
