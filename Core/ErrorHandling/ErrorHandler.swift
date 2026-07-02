import Foundation
import SwiftUI

@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentAlert: AppError?

    private var logFileURL: URL?
    private let logQueue = DispatchQueue(label: "com.pybox.ide.errorlog", qos: .utility)
    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docsURL = docs else { return }
        logFileURL = docsURL.appendingPathComponent("pybox-error.log")
        if let url = logFileURL, !FileManager.default.fileExists(atPath: url.path) {
            try? "=== PyBox Error Log ===\n".write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func handle(_ error: AppError) {
        NSLog("[ErrorHandler] \(error.title): \(error.message)")
        writeToLog(error)
        currentAlert = error
    }

    func handleError(_ error: Error, title: String = "出错了") {
        handle(AppError(title: title, message: error.localizedDescription, severity: .error))
    }

    func handleMessage(_ message: String, title: String = "提示", severity: AppError.Severity = .info) {
        let err = AppError(title: title, message: message, severity: severity)
        writeToLog(err)
        currentAlert = err
    }

    func clearAlert() {
        currentAlert = nil
    }

    private func writeToLog(_ error: AppError) {
        logQueue.async { [logFileURL, dateFormatter] in
            guard let url = logFileURL else { return }
            let line = "[\(dateFormatter.string(from: Date()))] [\(error.severity.rawValue)] \(error.title): \(error.message)\n"
            if let data = line.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                    try? handle.close()
                }
            }
        }
    }

    func readRecentLogs(maxLines: Int = 100) -> String {
        guard let url = logFileURL, let data = try? Data(contentsOf: url), let str = String(data: data, encoding: .utf8) else {
            return "暂无日志"
        }
        let lines = str.split(separator: "\n")
        return lines.suffix(maxLines).joined(separator: "\n")
    }
}

struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: Severity
    let timestamp = Date()

    enum Severity: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case critical = "CRIT"
    }
}
