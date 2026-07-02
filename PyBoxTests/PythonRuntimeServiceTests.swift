import XCTest
@testable import PyBox

final class PythonRuntimeServiceTests: XCTestCase {

    private let service = PythonRuntimeService.shared

    func testGetPythonVersion() {
        let version = service.getPythonVersion()
        XCTAssertTrue(version.contains("Python"))
    }

    func testListInstalledPackages() {
        let packages = service.listInstalledPackages()
        XCTAssertFalse(packages.isEmpty)
        XCTAssertTrue(packages.contains("pip"))
    }

    func testExecuteSimpleScript() async throws {
        let result = try await service.execute(script: "print(2 + 3)", in: "")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("5"))
        XCTAssertNil(result.error)
    }

    func testExecuteScriptWithError() async throws {
        let script = """
        import sys
        print("before output")
        """
        let result = try await service.execute(script: script, in: "")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("before output"))
        XCTAssertNil(result.error)
    }

    func testExecuteScriptWithLoop() async throws {
        let script = """
        for i in range(5):
            print(i)
        """
        let result = try await service.execute(script: script, in: "")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("0"))
        XCTAssertTrue(result.output.contains("4"))
    }

    // MARK: - Performance Tests

    func testPerformanceLargeLoop() {
        let script = """
total = 0
for i in range(100000):
    total += i
print(total)
"""
        let exp = expectation(description: "Large loop")
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let result = try await service.execute(script: script, in: "")
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                XCTAssertTrue(result.success)
                XCTAssertTrue(result.output.contains("4999950000"))
                NSLog("[Perf] Large loop 100k iterations: \(String(format: "%.3f", elapsed))s, executionTime reported: \(String(format: "%.3f", result.executionTime))s")
            } catch {
                XCTFail("\(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }

    func testPerformanceHeavyMath() {
        let script = """
# Prime sieve - compute primes up to 50000
n = 50000
sieve = [True] * (n + 1)
sieve[0] = sieve[1] = False
for i in range(2, int(n ** 0.5) + 1):
    if sieve[i]:
        for j in range(i * i, n + 1, i):
            sieve[j] = False
primes = [i for i, is_prime in enumerate(sieve) if is_prime]
print(len(primes))
"""
        let exp = expectation(description: "Heavy math")
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let result = try await service.execute(script: script, in: "")
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                XCTAssertTrue(result.success)
                XCTAssertTrue(result.output.contains("5133"))
                NSLog("[Perf] Prime sieve up to 50000: \(String(format: "%.3f", elapsed))s, reported: \(String(format: "%.3f", result.executionTime))s")
            } catch {
                XCTFail("\(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }

    func testPerformanceMultipleExecutions() {
        let scripts = [
            "print(sum(range(1000)))",
            "print('hello' * 100)",
            "print([x ** 2 for x in range(500)][-1])",
            "s = set(); [s.add(i % 50) for i in range(2000)]; print(len(s))",
            "print(str(2 ** 128))"
        ]
        let exp = expectation(description: "Multiple executions")
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            var totalTime: TimeInterval = 0
            for (i, script) in scripts.enumerated() {
                do {
                    let result = try await service.execute(script: script, in: "")
                    XCTAssertTrue(result.success)
                    totalTime += result.executionTime
                    NSLog("[Perf] Script #\(i+1): \(String(format: "%.3f", result.executionTime))s")
                } catch {
                    XCTFail("Script #\(i) failed: \(error)")
                }
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            NSLog("[Perf] Total \(scripts.count) scripts: \(String(format: "%.3f", elapsed))s wall, \(String(format: "%.3f", totalTime))s cumulative")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }
}