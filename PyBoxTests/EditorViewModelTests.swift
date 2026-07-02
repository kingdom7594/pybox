import XCTest
@testable import PyBox

@MainActor
final class EditorViewModelTests: XCTestCase {

    private var viewModel: EditorViewModel!

    override func setUp() {
        super.setUp()
        viewModel = EditorViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "lastOpenedFileId")
        RunHistoryStore.shared.clearAll()
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.code, "")
        XCTAssertNil(viewModel.currentFile)
        XCTAssertEqual(viewModel.output, "Ready to run...")
        XCTAssertFalse(viewModel.outputHasError)
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertFalse(viewModel.isFormatting)
        XCTAssertEqual(viewModel.fontSize, 14)
        XCTAssertTrue(viewModel.showLineNumbers)
        XCTAssertTrue(viewModel.autoCompleteEnabled)
    }

    func testOpenFile() {
        let file = ProjectFile(
            id: "test-file-1",
            name: "hello.py",
            path: "/tmp/hello.py",
            content: "print('hello')",
            type: .python
        )
        viewModel.openFile(file)
        XCTAssertEqual(viewModel.currentFile?.id, "test-file-1")
        XCTAssertEqual(viewModel.code, "print('hello')")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "lastOpenedFileId"), "test-file-1")
    }

    func testCodeDidChangeUpdatesCurrentFile() {
        let file = ProjectFile(
            id: "test-file-2",
            name: "test.py",
            path: "/tmp/test.py",
            content: "# original",
            type: .python
        )
        viewModel.openFile(file)
        viewModel.code = "# modified"
        XCTAssertEqual(viewModel.currentFile?.content, "# modified")
    }

    func testToggleLineNumbers() {
        let initial = viewModel.showLineNumbers
        viewModel.toggleLineNumbers()
        XCTAssertNotEqual(viewModel.showLineNumbers, initial)
    }

    func testToggleAutoComplete() {
        let initial = viewModel.autoCompleteEnabled
        viewModel.toggleAutoComplete()
        XCTAssertNotEqual(viewModel.autoCompleteEnabled, initial)
    }

    func testFormatCodeNoFile() {
        viewModel.code = "x=1"
        viewModel.formatCode()
        XCTAssertTrue(viewModel.isFormatting)
    }

    func testFormatCodeEmptyCode() {
        viewModel.code = ""
        viewModel.formatCode()
        XCTAssertFalse(viewModel.isFormatting)
    }

    func testFormatCodeNonPythonFile() {
        let file = ProjectFile(
            id: "json-file",
            name: "data.json",
            path: "/tmp/data.json",
            content: "{}",
            type: .json
        )
        viewModel.openFile(file)
        viewModel.formatCode()
        XCTAssertFalse(viewModel.isFormatting)
    }

    func testLoadLastOpenedFileNotExist() {
        UserDefaults.standard.set("nonexistent-id-12345", forKey: "lastOpenedFileId")
        viewModel.loadLastOpenedFile()
        XCTAssertNil(viewModel.currentFile)
    }
}