import SwiftUI

struct FileBrowserView: View {
    @StateObject private var viewModel = FileBrowserViewModel()
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var showNewFolder = false
    @State private var showNewFile = false
    @State private var showCtxMenu = false
    @State private var ctxTarget: ProjectFile?
    @State private var showRename = false
    @State private var renameText = ""
    @State private var newFolderName = ""
    @State private var newFileName = ""
    @State private var selectedFileType = "py"

    var body: some View {
        VStack(spacing: 0) {
            // 自定义 nav bar
            navBar

            // 搜索栏
            searchBar

            // 文件列表
            if viewModel.currentProject != nil {
                filesList
            } else {
                projectsList
            }
        }
        .background(Theme.Colors.background)
        .bottomSheet(isPresented: $showNewFolder) {
            newFolderSheet
        }
        .bottomSheet(isPresented: $showNewFile) {
            newFileSheet
        }
        .bottomSheet(isPresented: $showCtxMenu) {
            ctxMenuSheet
        }
        .bottomSheet(isPresented: $showRename) {
            renameSheet
        }
        .onAppear {
            viewModel.loadProjects()
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Text(viewModel.currentProject?.name ?? "文件")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.34)
                .foregroundColor(Theme.Colors.fg)

            if viewModel.currentProject != nil {
                Button {
                    viewModel.goBackToProjects()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.accent)
                }
                .buttonStyle(.pressable)
                .padding(.leading, 8)
            }

            Spacer()

            if viewModel.currentProject != nil {
                Button {
                    newFolderName = ""
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.fg)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.Colors.surface2)
                        )
                }
                .buttonStyle(.pressable)

                Button {
                    newFileName = ""
                    selectedFileType = "py"
                    showNewFile = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.fg)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.Colors.surface2)
                        )
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Theme.Colors.surface)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Colors.border)
        }
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.muted2)
            TextField("搜索文件...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.fg)
                .accentColor(Theme.Colors.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.surface2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 文件列表
    private var filesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(filteredFiles, id: \.id) { file in
                    fileRow(file)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var filteredFiles: [ProjectFile] {
        guard !searchText.isEmpty else { return viewModel.files }
        return viewModel.files.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    @ViewBuilder
    private func fileRow(_ file: ProjectFile) -> some View {
        let isActive = appState.activeFileId == file.id
        Button {
            if file.type != .folder {
                viewModel.openFile(file)
                appState.openFile(file)
                NotificationCenter.default.post(name: .switchToTab, object: ContentView.Tab.editor)
                showToast("打开 \(file.name)")
            }
        } label: {
            HStack(spacing: 10) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconGradient(file.type))
                    Image(systemName: iconSymbol(file.type))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)

                // 文件名 + 副标题
                VStack(alignment: .leading, spacing: 1) {
                    Text(file.name)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(-0.15)
                        .foregroundColor(Theme.Colors.fg)
                        .lineLimit(1)
                    Text(fileSubtitle(file))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.muted)
                        .lineLimit(1)
                }

                Spacer()

                // ⋯ 按钮
                Button {
                    ctxTarget = file
                    showCtxMenu = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.muted2)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Theme.Colors.accentDim : Color.clear)
            )
        }
        .buttonStyle(.pressable)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteFile(file)
                showToast("已删除: \(file.name)")
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func iconSymbol(_ type: ProjectFile.FileType) -> String {
        switch type {
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .json: return "curlybraces"
        case .text: return "doc.text"
        case .folder: return "folder.fill"
        }
    }

    private func iconGradient(_ type: ProjectFile.FileType) -> LinearGradient {
        switch type {
        case .python:
            return LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .json:
            return LinearGradient(colors: [Color(hex: "#F97316"), Color(hex: "#EA580C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .text:
            return LinearGradient(colors: [Theme.Colors.surface3, Theme.Colors.surface2], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .folder:
            return LinearGradient(colors: [Color(hex: "#F59E0B"), Color(hex: "#D97706")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func fileSubtitle(_ file: ProjectFile) -> String {
        let sizeText = ByteCountFormatter.string(fromByteCount: Int64(file.content.count), countStyle: .file)
        switch file.type {
        case .python: return "Python · \(sizeText)"
        case .json: return "JSON · \(sizeText)"
        case .text: return "Text · \(sizeText)"
        case .folder: return "文件夹"
        }
    }

    // MARK: - 项目列表
    private var projectsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                sectionLabel("项目")
                ForEach(viewModel.projects, id: \.id) { project in
                    projectRow(project)
                }
                if viewModel.projects.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        Button {
            viewModel.openProject(project)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [Color(hex: "#F59E0B"), Color(hex: "#D97706")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(-0.2)
                        .foregroundColor(Theme.Colors.fg)
                        .lineLimit(1)
                    Text("\(project.files.count) 个文件")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.muted)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.surface)
            )
        }
        .buttonStyle(.pressable)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let idx = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                    viewModel.deleteProjects(at: IndexSet(integer: idx))
                    showToast("已删除项目: \(project.name)")
                }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.muted2)
                .padding(.top, 32)
            Text("暂无项目")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.fg)
            Text("从「文件」应用导入或新建项目")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.4)
            .foregroundColor(Theme.Colors.muted)
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    // MARK: - 新建文件夹弹窗
    private var newFolderSheet: some View {
        VStack(spacing: 0) {
            Text("新建文件夹")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.fg)
                .padding(.bottom, 16)

            TextField("文件夹名称", text: $newFolderName)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.surface2)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.border, lineWidth: 1))
                )
                .foregroundColor(Theme.Colors.fg)
                .accentColor(Theme.Colors.accent)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            sheetActionRow(icon: "folder.badge.plus", label: "创建", sub: "在项目根目录下新建文件夹") {
                guard !newFolderName.isEmpty else { showToast("请输入文件夹名称"); return }
                showToast("已创建文件夹: \(newFolderName)")
                showNewFolder = false
            }
            sheetCancelRow { showNewFolder = false }
        }
    }

    // MARK: - 新建文件弹窗
    private var newFileSheet: some View {
        VStack(spacing: 0) {
            Text("新建文件")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.fg)
                .padding(.bottom, 16)

            TextField("文件名，例如 main.py", text: $newFileName)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.surface2)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.border, lineWidth: 1))
                )
                .foregroundColor(Theme.Colors.fg)
                .accentColor(Theme.Colors.accent)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // 类型选择
            HStack(spacing: 8) {
                fileTypeButton("py", "Python", "chevron.left.forwardslash.chevron.right")
                fileTypeButton("json", "JSON", "curlybraces")
                fileTypeButton("md", "Markdown", "doc.richtext")
                fileTypeButton("txt", "Text", "doc.text")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            sheetActionRow(icon: "doc.badge.plus", label: "创建", sub: "在项目根目录下新建文件") {
                guard !newFileName.isEmpty else { showToast("请输入文件名称"); return }
                var name = newFileName
                if !name.contains(".") { name += ".\(selectedFileType)" }
                viewModel.createFile(name: name)
                showToast("已创建文件: \(name)")
                showNewFile = false
            }
            sheetCancelRow { showNewFile = false }
        }
    }

    @ViewBuilder
    private func fileTypeButton(_ type: String, _ label: String, _ icon: String) -> some View {
        Button {
            selectedFileType = type
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(selectedFileType == type ? Theme.Colors.accent : Theme.Colors.muted)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedFileType == type ? Theme.Colors.accentDim : Theme.Colors.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedFileType == type ? Theme.Colors.accent : Theme.Colors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.pressable)
    }

    // MARK: - 上下文菜单
    private var ctxMenuSheet: some View {
        VStack(spacing: 0) {
            if let target = ctxTarget {
                Text(target.name)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.muted)
                    .lineLimit(1)
                    .padding(.bottom, 8)
            }

            ctxActionRow(icon: "pencil", label: "重命名") {
                showCtxMenu = false
                if let target = ctxTarget {
                    renameText = target.name
                    showRename = true
                }
            }
            ctxActionRow(icon: "doc.on.doc", label: "复制") {
                if let target = ctxTarget {
                    showToast("已复制为 \(target.name)_copy")
                }
                showCtxMenu = false
            }
            ctxActionRow(icon: "trash", label: "删除", color: Theme.Colors.danger) {
                if let target = ctxTarget {
                    viewModel.deleteFile(target)
                    showToast("已删除: \(target.name)")
                }
                showCtxMenu = false
            }
            sheetCancelRow { showCtxMenu = false }
        }
    }

    @ViewBuilder
    private func ctxActionRow(icon: String, label: String, color: Color = Theme.Colors.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - 重命名弹窗
    private var renameSheet: some View {
        VStack(spacing: 0) {
            Text("重命名")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.fg)
                .padding(.bottom, 16)

            TextField("新名称", text: $renameText)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.surface2)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.border, lineWidth: 1))
                )
                .foregroundColor(Theme.Colors.fg)
                .accentColor(Theme.Colors.accent)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            sheetActionRow(icon: "checkmark", label: "确认", sub: nil) {
                guard !renameText.isEmpty, let target = ctxTarget else { return }
                showToast("已重命名: \(target.name) → \(renameText)")
                showRename = false
            }
            sheetCancelRow { showRename = false }
        }
    }

    // MARK: - Sheet 通用行
    @ViewBuilder
    private func sheetActionRow(icon: String, label: String, sub: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.fg)
                    if let sub = sub {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.muted)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .overlay(alignment: .top) {
                Divider().background(Theme.Colors.border)
            }
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func sheetCancelRow(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.muted)
                    .frame(width: 22)
                Text("取消")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.muted)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .overlay(alignment: .top) {
                Divider().background(Theme.Colors.border)
            }
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    FileBrowserView()
        .environmentObject(AppState())
}
