import Foundation
import PythonKit

class BlackFormatterService {
    static let shared = BlackFormatterService()

    private var isWarmedUp = false
    private var isBlackAvailable: Bool = false
    private var isAutopep8Available: Bool = false

    private init() {}

    /// 预热 - 在 Python 运行时初始化后调用,提前 import formatter 减少首次延迟
    /// 注意: iOS simulator 18.1 上, background thread 调 Python.attemptImport 会 crash
    /// 改成主线程异步 init. 如果 import 失败,不会 crash app,只是功能不可用.
    func warmup() {
        guard !isWarmedUp else { return }
        isWarmedUp = true
        DispatchQueue.main.async { [weak self] in
            self?.isAutopep8Available = self?.importAutopep8() ?? false
            if self?.isAutopep8Available == false {
                NSLog("[BlackFormatter] autopep8 不可用,格式化功能将降级")
            }
        }
    }

    /// 检查格式化器是否可用
    var isAvailable: Bool { isAutopep8Available }

    @discardableResult
    private func importAutopep8() -> Bool {
        do {
            _ = try Python.attemptImport("autopep8")
            return true
        } catch {
            NSLog("[BlackFormatter] Failed to import autopep8: \(error)")
            return false
        }
    }

    struct FormatResult {
        let success: Bool
        let formatted: String
        let error: String?
    }

    /// 格式化 Python 源码 - 使用 autopep8 (纯 Python,无原生依赖)
    /// 注意: iOS simulator 18.1 上, Python 调用必须在主线程,否则 GIL crash
    func format(_ code: String) async -> FormatResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let result = self.runFormatter(code)
                continuation.resume(returning: result)
            }
        }
    }

    private func runFormatter(_ code: String) -> FormatResult {
        let autopep8: PythonObject
        do {
            autopep8 = try Python.attemptImport("autopep8")
        } catch {
            return FormatResult(
                success: false,
                formatted: code,
                error: "autopep8 未安装或版本不兼容: \(error.localizedDescription)"
            )
        }

        do {
            // 用 StringIO 捕获 stdout/stderr
            let io = try Python.attemptImport("io")
            let sys = try Python.attemptImport("sys")
            let oldStdout = sys.stdout
            let oldStderr = sys.stderr
            let stdoutCapture = io.StringIO()
            let stderrCapture = io.StringIO()
            sys.stdout = stdoutCapture
            sys.stderr = stderrCapture

            let result: FormatResult
            do {
                // autopep8.fix_code(code, options={'max_line_length': 88})
                let fixedPy = autopep8.fix_code(code, Python.dict(max_line_length: 88))
                let formatted = String(fixedPy) ?? code
                result = FormatResult(success: true, formatted: formatted, error: nil)
            } catch let pyErr as PythonError {
                let errStr = String(describing: pyErr)
                result = FormatResult(success: false, formatted: code, error: errStr)
            }

            // 恢复 stdout/stderr
            sys.stdout = oldStdout
            sys.stderr = oldStderr

            return result
        } catch {
            return FormatResult(
                success: false,
                formatted: code,
                error: "autopep8 格式化失败: \(error.localizedDescription)"
            )
        }
    }
}
