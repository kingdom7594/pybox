import XCTest
@testable import PyBox

final class FileManagerServiceTests: XCTestCase {

    private var service: FileManagerService!
    private var createdProjectIds: [String] = []

    override func setUp() {
        super.setUp()
        service = FileManagerService.shared
    }

    override func tearDown() {
        for id in createdProjectIds {
            service.deleteProject(id: id)
        }
        createdProjectIds.removeAll()
        super.tearDown()
    }

    func testCreateProject() {
        let projectName = "TestProject_\(UUID().uuidString.prefix(8))"
        let project = service.createProject(name: projectName)
        XCTAssertNotNil(project)
        XCTAssertEqual(project?.name, projectName)
        XCTAssertFalse(project?.id.isEmpty ?? true)
        XCTAssertTrue(project?.files.isEmpty ?? false)
        if let id = project?.id {
            createdProjectIds.append(id)
        }
    }

    func testGetProject() {
        let project = service.createProject(name: "GetTest_\(UUID().uuidString.prefix(8))")
        guard let id = project?.id else { return XCTFail("Project not created") }
        createdProjectIds.append(id)

        let retrieved = service.getProject(id: id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, id)
    }

    func testCreateFile() {
        let project = service.createProject(name: "FileTest_\(UUID().uuidString.prefix(8))")
        guard let pid = project?.id else { return XCTFail("Project not created") }
        createdProjectIds.append(pid)

        let file = service.createFile(name: "test.py", in: pid)
        XCTAssertNotNil(file)
        XCTAssertEqual(file?.name, "test.py")
        XCTAssertEqual(file?.content, "")
        XCTAssertEqual(file?.type, .python)
    }

    func testSaveFile() {
        let project = service.createProject(name: "SaveTest_\(UUID().uuidString.prefix(8))")
        guard let pid = project?.id else { return XCTFail("Project not created") }
        createdProjectIds.append(pid)

        let file = service.createFile(name: "save.py", in: pid)
        guard let fid = file?.id else { return XCTFail("File not created") }

        var toSave = file!
        toSave.content = "print('hello')"
        service.saveFile(toSave)

        let retrieved = service.getFile(id: fid)
        XCTAssertEqual(retrieved?.content, "print('hello')")
    }

    func testDeleteProject() {
        let project = service.createProject(name: "DeleteTest_\(UUID().uuidString.prefix(8))")
        guard let id = project?.id else { return XCTFail("Project not created") }

        service.deleteProject(id: id)
        let retrieved = service.getProject(id: id)
        XCTAssertNil(retrieved)
    }

    func testDeleteFile() {
        let project = service.createProject(name: "DelFileTest_\(UUID().uuidString.prefix(8))")
        guard let pid = project?.id else { return XCTFail("Project not created") }
        createdProjectIds.append(pid)

        let file = service.createFile(name: "del.py", in: pid)
        guard let fid = file?.id else { return XCTFail("File not created") }

        service.deleteFile(id: fid)
        let retrieved = service.getFile(id: fid)
        XCTAssertNil(retrieved)
    }

    func testGetAllProjects() {
        let p1 = service.createProject(name: "ListTest1_\(UUID().uuidString.prefix(8))")
        let p2 = service.createProject(name: "ListTest2_\(UUID().uuidString.prefix(8))")
        if let id = p1?.id { createdProjectIds.append(id) }
        if let id = p2?.id { createdProjectIds.append(id) }

        let all = service.getAllProjects()
        XCTAssertTrue(all.contains { $0.id == p1?.id })
        XCTAssertTrue(all.contains { $0.id == p2?.id })
    }
}