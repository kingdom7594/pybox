import SwiftUI
import Combine

class FileBrowserViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var currentProject: Project?
    @Published var files: [ProjectFile] = []

    private let fileManager = FileManagerService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadProjects()

        // 监听 pending script 加载完成事件
        NotificationCenter.default.publisher(for: .pendingScriptLoaded)
            .sink { [weak self] notification in
                guard let self = self,
                      let project = notification.object as? Project else { return }
                self.loadProjects()
                self.openProject(project)
                if let firstFile = project.files.first {
                    self.openFile(firstFile)
                }
            }
            .store(in: &cancellables)
    }

    func loadProjects() {
        projects = fileManager.getAllProjects()
    }

    func openProject(_ project: Project) {
        currentProject = project
        files = project.files
    }
    
    func goBackToProjects() {
        currentProject = nil
        files = []
        loadProjects()
    }
    
    func createProject(name: String) {
        if let project = fileManager.createProject(name: name) {
            projects.insert(project, at: 0)
            openProject(project)
        }
    }
    
    func createFile(name: String) {
        guard let projectId = currentProject?.id else { return }
        if let file = fileManager.createFile(name: name, in: projectId) {
            files.insert(file, at: 0)
        }
    }
    
    func openFile(_ file: ProjectFile) {
        // 保存 lastOpenedFileId 让 EditorViewModel.loadLastOpenedFile 找到
        UserDefaults.standard.set(file.id, forKey: "lastOpenedFileId")
        NotificationCenter.default.post(name: .openFile, object: file)
    }

    func refreshFiles() {
        loadProjects()
        if let current = currentProject {
            files = current.files
        }
    }

    func deleteFile(_ file: ProjectFile) {
        fileManager.deleteFile(id: file.id)
        files.removeAll { $0.id == file.id }
    }

    func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            fileManager.deleteProject(id: project.id)
        }
        projects.remove(atOffsets: offsets)
    }
    
    func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            let file = files[index]
            fileManager.deleteFile(id: file.id)
        }
        files.remove(atOffsets: offsets)
    }
}

extension Notification.Name {
    static let openFile = Notification.Name("openFile")
    static let pendingScriptLoaded = Notification.Name("pendingScriptLoaded")
}