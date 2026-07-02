import Foundation

extension FileManagerService {

    // MARK: - Import

    @discardableResult
    func importFile(from sourceURL: URL, into projectId: String? = nil) -> ProjectFile? {
        let didStart = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let targetProjectId: String
        if let provided = projectId {
            targetProjectId = provided
        } else if let firstProject = getAllProjects().first {
            targetProjectId = firstProject.id
        } else {
            guard let newProject = createProject(name: "Imported") else { return nil }
            targetProjectId = newProject.id
        }

        guard let project = getProject(id: targetProjectId) else { return nil }

        let fileName = sourceURL.lastPathComponent
        let destinationURL = projectPath(for: targetProjectId).appendingPathComponent(fileName)

        do {
            if Self.sharedFileManager.fileExists(atPath: destinationURL.path) {
                try Self.sharedFileManager.removeItem(at: destinationURL)
            }
            try Self.sharedFileManager.copyItem(at: sourceURL, to: destinationURL)

            let content = (try? String(contentsOf: destinationURL, encoding: .utf8)) ?? ""
            let newFile = ProjectFile(
                id: UUID().uuidString,
                name: fileName,
                path: destinationURL.path,
                content: content,
                type: fileTypeFromExtension(fileName)
            )

            var updatedProject = project
            if !updatedProject.files.contains(where: { $0.name == fileName }) {
                updatedProject.files.append(newFile)
                updatedProject.modifiedAt = Date()
                saveProject(updatedProject)
            }

            return newFile
        } catch {
            NSLog("[FileManagerService] Import failed: \(error.localizedDescription)")
            return nil
        }
    }

    @discardableResult
    func importFiles(_ urls: [URL], into projectId: String? = nil) -> [ProjectFile] {
        var imported: [ProjectFile] = []
        for url in urls {
            if let file = importFile(from: url, into: projectId) {
                imported.append(file)
            }
        }
        return imported
    }

    // MARK: - Export

    func exportFile(_ file: ProjectFile) -> URL? {
        let sourceURL = URL(fileURLWithPath: file.path)
        guard Self.sharedFileManager.fileExists(atPath: sourceURL.path) else { return nil }

        let tempDir = Self.sharedFileManager.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent(file.name)

        do {
            if Self.sharedFileManager.fileExists(atPath: exportURL.path) {
                try Self.sharedFileManager.removeItem(at: exportURL)
            }
            try Self.sharedFileManager.copyItem(at: sourceURL, to: exportURL)
            return exportURL
        } catch {
            NSLog("[FileManagerService] Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    func projectPath(for projectId: String) -> URL {
        getProjectsDirectory().appendingPathComponent(projectId, isDirectory: true)
    }

    private func fileTypeFromExtension(_ name: String) -> ProjectFile.FileType {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "py": return .python
        case "json": return .json
        case "txt": return .text
        case "md": return .text
        default: return .text
        }
    }
}

private extension FileManagerService {
    static var sharedFileManager: FileManager { FileManager.default }
}
