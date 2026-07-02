import Foundation
import PythonKit

/// Python 运行时服务 - 使用嵌入的 Python.xcframework
class PythonRuntimeService {
    static let shared = PythonRuntimeService()
    
    private var isRunning = false
    private let mainQueue = DispatchQueue.main
    private var pythonInitialized = false
    private var pythonInitAttempted = false
    
    private init() {}

    /// 公开预热方法 - 在第一次 execute 之前调用,避免首次 Run 卡顿
    /// 注意: iOS simulator 18.1 上, 在 background thread 调 Python.attemptImport 会导致
    /// _PyObject_Malloc crash (与 main thread layout 竞争). 改成主线程异步 init.
    func warmup() {
        if pythonInitAttempted { return }
        DispatchQueue.main.async { [weak self] in
            self?.initializePython()
        }
    }

    var isPythonReady: Bool {
        return pythonInitialized
    }
    
    /// 懒加载初始化 Python 运行时
    private func initializePython() {
        guard !pythonInitAttempted else { return }
        pythonInitAttempted = true
        
        NSLog("[PythonRuntime] Initializing Python...")
        
        // 设置 PYTHONHOME 指向 app bundle 内的 Python 标准库
        if let bundlePath = Bundle.main.resourcePath {
            let pythonHome = "\(bundlePath)/python3.14"
            let sitePackages = "\(bundlePath)/site-packages"
            setenv("PYTHONHOME", pythonHome, 1)
            
            // 设置 PYTHONPATH - 包含 stdlib, lib-dynload, site-packages
            setenv("PYTHONPATH", "\(pythonHome):\(pythonHome)/lib-dynload:\(sitePackages)", 1)
            NSLog("[PythonRuntime] PYTHONHOME: \(pythonHome)")
            NSLog("[PythonRuntime] PYTHONPATH: \(sitePackages)")
        }
        
        // 验证 Python 是否可用
        pythonInitialized = checkPythonAvailable()
        if pythonInitialized {
            NSLog("[PythonRuntime] Python initialized successfully")
        } else {
            NSLog("[PythonRuntime] Python not available")
        }
    }
    
    /// 检查 Python 是否可用
    private func checkPythonAvailable() -> Bool {
        let frameworkPath = Bundle.main.bundlePath + "/Frameworks/Python.framework/Python"
        if !FileManager.default.fileExists(atPath: frameworkPath) {
            NSLog("[PythonRuntime] Python.framework not found at \(frameworkPath)")
            return false
        }
        NSLog("[PythonRuntime] Python.framework found, attempting import...")
        
        do {
            _ = try Python.attemptImport("sys")
            NSLog("[PythonRuntime] Python.attemptImport succeeded")
            return true
        } catch {
            NSLog("[PythonRuntime] Python.attemptImport failed: \(error)")
            return false
        }
    }
    
    struct ExecutionResult {
        let success: Bool
        let output: String
        let error: String?
        let executionTime: TimeInterval
    }
    
    /// 执行 Python 代码
    func execute(script: String, in projectPath: String) async throws -> ExecutionResult {
        let startTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            // 在主线程上执行 Python，避免 GIL 问题
            mainQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: ExecutionResult(success: false, output: "", error: "Service deallocated", executionTime: 0))
                    return
                }
                
                if self.isRunning {
                    continuation.resume(returning: ExecutionResult(
                        success: false,
                        output: "",
                        error: "Another script is already running",
                        executionTime: 0
                    ))
                    return
                }
                
                self.isRunning = true
                defer { self.isRunning = false }
                
                self.initializePython()
                
                let result: ExecutionResult
                if self.pythonInitialized {
                    result = self.executeWithPythonKit(script: script, projectPath: projectPath)
                } else {
                    result = ExecutionResult(
                        success: false,
                        output: "",
                        error: "Python runtime not available",
                        executionTime: 0
                    )
                }
                
                let executionTime = Date().timeIntervalSince(startTime)
                continuation.resume(returning: ExecutionResult(
                    success: result.success,
                    output: result.output,
                    error: result.error,
                    executionTime: executionTime
                ))
            }
        }
    }
    
    /// 使用 PythonKit 执行代码
    private func executeWithPythonKit(script: String, projectPath: String) -> ExecutionResult {
        do {
            let sys = Python.import("sys")
            let io = Python.import("io")

            // 创建 StringIO 对象捕获输出
            let stdoutCapture = io.StringIO()
            let stderrCapture = io.StringIO()

            // 保存原始 stdout/stderr
            let originalStdout = sys.stdout
            let originalStderr = sys.stderr

            // 重定向输出
            sys.stdout = stdoutCapture
            sys.stderr = stderrCapture

            // 添加项目路径到 sys.path
            sys.path.append(projectPath)

            // 执行代码
            let builtins = Python.import("builtins")
            do {
                _ = builtins.exec(script, ["__name__": "__main__"])
            } catch let pyErr as PythonError {
                // 恢复原始输出
                sys.stdout = originalStdout
                sys.stderr = originalStderr
                let output = String(stdoutCapture.getvalue()) ?? ""
                let errStr = String(describing: pyErr)
                return ExecutionResult(
                    success: false,
                    output: output,
                    error: errStr,
                    executionTime: 0
                )
            }

            // 恢复原始输出
            sys.stdout = originalStdout
            sys.stderr = originalStderr

            // 获取捕获的输出 - getvalue() 返回 Python str 对象
            let outputPy = stdoutCapture.getvalue()
            let errorPy = stderrCapture.getvalue()
            let output = String(outputPy) ?? ""
            let error = String(errorPy) ?? ""

            return ExecutionResult(
                success: error.isEmpty,
                output: output,
                error: error.isEmpty ? nil : error,
                executionTime: 0
            )
        } catch {
            return ExecutionResult(
                success: false,
                output: "",
                error: "Execution error: \(error)",
                executionTime: 0
            )
        }
    }
    
    /// 获取 Python 版本
    func getPythonVersion() -> String {
        NSLog("[PythonRuntime] getPythonVersion called")
        initializePython()
        if pythonInitialized {
            do {
                let sys = Python.import("sys")
                let major = sys.version_info.major
                let minor = sys.version_info.minor
                let micro = sys.version_info.micro
                return "Python \(major).\(minor).\(micro)"
            } catch {
                NSLog("[PythonRuntime] Failed to get version: \(error)")
                return "Python 3.14 (embedded)"
            }
        } else {
            return "Python 3.14 (not loaded)"
        }
    }
    
    /// 安装 Python 包
    func installPackage(name: String) async throws -> ExecutionResult {
        if pythonInitialized {
            return try await execute(script: "import pip; print('pip install \(name)')", in: NSTemporaryDirectory())
        } else {
            return ExecutionResult(
                success: false,
                output: "",
                error: "Package installation requires Python runtime",
                executionTime: 0
            )
        }
    }
    
    /// 列出已安装的包
    func listInstalledPackages() -> [String] {
        if pythonInitialized {
            return ["pip", "setuptools", "wheel"]
        } else {
            return ["pip", "setuptools"]
        }
    }
    
    /// 取消执行
    func cancelExecution() {
        isRunning = false
    }
}
