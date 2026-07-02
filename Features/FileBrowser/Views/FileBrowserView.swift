import SwiftUI
import UniformTypeIdentifiers

struct FileBrowserView: View {
    @StateObject private var viewModel = FileBrowserViewModel()
    @State private var showingNewProjectSheet = false
    @State private var showingNewFileAlert = false
    @State private var newItemName = ""
    @State private var showingImportPicker = false
    @State private var exportingFile: ProjectFile?
    @State private var alertMessage: AlertMessage?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.currentProject != nil {
                    projectFilesSection
                } else {
                    projectsSection
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(viewModel.currentProject?.name ?? "Projects")
            .onAppear {
                viewModel.loadProjects()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingNewProjectSheet = true }) {
                            Label("New Project", systemImage: "folder.badge.plus")
                        }
                        Button(action: { showingImportPicker = true }) {
                            Label("Import File", systemImage: "square.and.arrow.down")
                        }
                        if viewModel.currentProject != nil {
                            Divider()
                            Button(action: { showingNewFileAlert = true }) {
                                Label("New File", systemImage: "doc.badge.plus")
                            }
                            Divider()
                            Button(action: viewModel.goBackToProjects) {
                                Label("All Projects", systemImage: "arrow.left")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingImportPicker) {
                DocumentPicker(
                    contentTypes: [.pythonScript, .plainText, .json, .text, .data],
                    allowsMultipleSelection: true,
                    onPicked: { urls in
                        showingImportPicker = false
                        let imported = FileManagerService.shared.importFiles(urls, into: viewModel.currentProject?.id)
                        viewModel.refreshFiles()
                        if imported.isEmpty {
                            alertMessage = AlertMessage(title: "Import Failed", message: "No files were imported.")
                        } else {
                            alertMessage = AlertMessage(
                                title: "Import Successful",
                                message: "Imported \(imported.count) file\(imported.count == 1 ? "" : "s") to \(viewModel.currentProject?.name ?? "Imported")."
                            )
                        }
                    },
                    onCancel: { showingImportPicker = false }
                )
            }
            .sheet(item: $exportingFile) { file in
                if let exportURL = FileManagerService.shared.exportFile(file) {
                    FileExporter(url: exportURL) { _ in
                        exportingFile = nil
                    }
                } else {
                    Color.clear.onAppear { exportingFile = nil }
                }
            }
            .alert("New File", isPresented: $showingNewFileAlert) {
                TextField("File name", text: $newItemName)
                Button("Create") {
                    viewModel.createFile(name: newItemName)
                    newItemName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(item: $alertMessage) { message in
                Alert(title: Text(message.title), message: Text(message.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var projectsSection: some View {
        Section("Projects") {
            ForEach(viewModel.projects) { project in
                Button {
                    viewModel.openProject(project)
                } label: {
                    ProjectRowView(project: project)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: viewModel.deleteProjects)

            if viewModel.projects.isEmpty {
                Text("No projects yet")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    private var projectFilesSection: some View {
        Section("Files") {
            ForEach(viewModel.files) { file in
                Button {
                    viewModel.openFile(file)
                } label: {
                    FileRowView(file: file)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        exportingFile = file
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        viewModel.deleteFile(file)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                viewModel.deleteFiles(at: indexSet)
            }

            if viewModel.files.isEmpty {
                Text("No files in this project. Tap + to add or import.")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(project.name)
                    .font(.body)
                Text("\(project.files.count) files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(project.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FileRowView: View {
    let file: ProjectFile

    var body: some View {
        HStack {
            Image(systemName: iconForFileType(file.type))
                .foregroundColor(colorForFileType(file.type))
            Text(file.name)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func iconForFileType(_ type: ProjectFile.FileType) -> String {
        switch type {
        case .python: return "doc.text.fill"
        case .json: return "doc.badge.gearshape"
        case .text: return "doc.text"
        case .folder: return "folder.fill"
        }
    }

    private func colorForFileType(_ type: ProjectFile.FileType) -> Color {
        switch type {
        case .python: return .green
        case .json: return .orange
        case .text: return .gray
        case .folder: return .blue
        }
    }
}

struct NewProjectSheet: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Name") {
                    TextField("My Project", text: $projectName)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createProject(name: projectName)
                        dismiss()
                    }
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
}

extension ProjectFile {
    var url: URL? { URL(fileURLWithPath: path) }
}

#Preview {
    FileBrowserView()
}
