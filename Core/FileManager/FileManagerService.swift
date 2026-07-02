import Foundation

class FileManagerService {
    static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    private let projectsDirectory: URL
    
    private init() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Cannot access document directory")
        }
        projectsDirectory = documentsPath.appendingPathComponent("PyBoxProjects", isDirectory: true)
        
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
    }
    
    func getProjectsDirectory() -> URL {
        return projectsDirectory
    }
    
    func createProject(name: String) -> Project? {
        let id = UUID().uuidString
        let projectPath = projectsDirectory.appendingPathComponent(id, isDirectory: true)
        NSLog("[FileManagerService] Creating project '\(name)' at \(projectPath.path)")

        do {
            try fileManager.createDirectory(at: projectPath, withIntermediateDirectories: true)
            NSLog("[FileManagerService] Created directory: \(projectPath.path)")

            let project = Project(
                id: id,
                name: name,
                path: projectPath.path,
                createdAt: Date(),
                modifiedAt: Date(),
                files: []
            )

            saveProject(project)
            NSLog("[FileManagerService] Saved project: id=\(project.id)")
            return project
        } catch {
            NSLog("[FileManagerService] Error creating project: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getProject(id: String) -> Project? {
        let url = projectsDirectory.appendingPathComponent("\(id)/project.json")
        guard let projectData = try? Data(contentsOf: url) else {
            NSLog("[FileManagerService] getProject: failed to read data at \(url.path)")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let project = try decoder.decode(Project.self, from: projectData)
            return project
        } catch {
            NSLog("[FileManagerService] getProject: decode error: \(error)")
            return nil
        }
    }
    
    func saveProject(_ project: Project) {
        let projectPath = projectsDirectory.appendingPathComponent("\(project.id)/project.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(project)
            try data.write(to: projectPath)
        } catch {
            print("Error saving project: \(error)")
        }
    }
    
    func deleteProject(id: String) {
        let projectPath = projectsDirectory.appendingPathComponent(id)
        try? fileManager.removeItem(at: projectPath)
    }
    
    func createFile(name: String, in projectId: String) -> ProjectFile? {
        guard let project = getProject(id: projectId) else { return nil }
        
        let filePath = projectsDirectory
            .appendingPathComponent(projectId)
            .appendingPathComponent(name)
        
        do {
            try "".write(to: filePath, atomically: true, encoding: .utf8)
            
            let file = ProjectFile(
                id: UUID().uuidString,
                name: name,
                path: filePath.path,
                content: "",
                type: getFileType(from: name)
            )
            
            var updatedProject = project
            updatedProject.files.append(file)
            updatedProject.modifiedAt = Date()
            saveProject(updatedProject)
            
            return file
        } catch {
            print("Error creating file: \(error)")
            return nil
        }
    }
    
    func getFile(id: String) -> ProjectFile? {
        for project in getAllProjects() {
            if let file = project.files.first(where: { $0.id == id }) {
                return file
            }
        }
        return nil
    }
    
    func saveFile(_ file: ProjectFile) {
        guard let projectId = findProjectId(for: file.path),
              let project = getProject(id: projectId) else { return }
        
        let filePath = URL(fileURLWithPath: file.path)
        
        do {
            try file.content.write(to: filePath, atomically: true, encoding: .utf8)
            
            var updatedProject = project
            if let index = updatedProject.files.firstIndex(where: { $0.id == file.id }) {
                updatedProject.files[index] = file
            }
            updatedProject.modifiedAt = Date()
            saveProject(updatedProject)
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    func deleteFile(id: String) {
        guard let file = getFile(id: id),
              let projectId = findProjectId(for: file.path),
              let project = getProject(id: projectId) else { return }
        
        try? fileManager.removeItem(atPath: file.path)
        
        var updatedProject = project
        updatedProject.files.removeAll { $0.id == id }
        updatedProject.modifiedAt = Date()
        saveProject(updatedProject)
    }
    
    func readFileContent(at path: String) -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            print("Error reading file: \(error)")
            return ""
        }
    }
    
    func getAllProjects() -> [Project] {
        guard let contents = try? fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents.compactMap { url -> Project? in
            guard url.hasDirectoryPath,
                  let projectData = try? Data(contentsOf: url.appendingPathComponent("project.json")) else {
                return nil
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(Project.self, from: projectData)
        }
    }
    
    private func findProjectId(for filePath: String) -> String? {
        for project in getAllProjects() {
            if filePath.hasPrefix(project.path) {
                return project.id
            }
        }
        return nil
    }
    
    private func getFileType(from name: String) -> ProjectFile.FileType {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "py": return .python
        case "json": return .json
        case "txt": return .text
        default: return .text
        }
    }
}
