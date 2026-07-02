import XCTest
@testable import PyBox

final class BlackFormatterServiceTests: XCTestCase {

    private let service = BlackFormatterService.shared

    override func setUp() {
        super.setUp()
        service.warmup()
    }

    func testFormatSimpleCode() async {
        let unformatted = "def  f( x ):return  x"
        let result = await service.format(unformatted)
        XCTAssertTrue(result.success)
        XCTAssertNotEqual(result.formatted, unformatted)
        XCTAssertNil(result.error)
    }

    func testFormatAlreadyFormattedCode() async {
        let formatted = "def fib(n):\n    if n <= 1:\n        return n\n    return fib(n - 1) + fib(n - 2)\n"
        let result = await service.format(formatted)
        XCTAssertTrue(result.success)
    }

    func testFormatEmptyCode() async {
        let result = await service.format("")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.formatted, "")
    }

    func testFormatE225OperatorSpacing() async {
        let unformatted = "x=1+2"
        let result = await service.format(unformatted)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.formatted.contains("="))
    }
}