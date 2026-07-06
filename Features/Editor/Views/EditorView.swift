import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showInsertedToast = false
    @State private var showFormatSheet = false
    @State private var outputTab: OutputTab = .output
    @State private var outputOpen = false
    @State private var splitMode = false

    enum OutputTab: String, CaseIterable {
        case output = "输出"
        case problems = "问题"
        case debug = "调试"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 自定义 nav bar
            navBar

            // 代码标签页
            if !appState.openFiles.isEmpty {
                fileTabs
            }

            // 编辑区 + 输出面板
            if viewModel.currentFile != nil {
                editorContent
            } else {
                emptyStateView
            }
        }
        .background(Theme.Colors.background)
        .onAppear {
            viewModel.setAppState(appState)
            viewModel.loadLastOpenedFile()
            if let file = viewModel.currentFile {
                appState.updateActiveFileContext(file)
            }
        }
        .onChange(of: viewModel.currentFile?.id) { _ in
            if let file = viewModel.currentFile {
                appState.updateActiveFileContext(file)
            }
        }
        .onChange(of: viewModel.code) { newCode in
            appState.updateActiveFileContent(newCode)
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiInsertCodeRequested)) { note in
            if let code = note.userInfo?["code"] as? String {
                insertCode(code)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { note in
            if let file = note.object as? ProjectFile {
                viewModel.openFile(file)
                appState.openFile(file)
                outputOpen = false
            }
        }
        .sheet(isPresented: $showFormatSheet) {
            FormatSheetView(viewModel: viewModel)
        }
    }

    // MARK: - Nav Bar（对齐原型 .nav-bar）
    private var navBar: some View {
        HStack {
            // 左：菜单按钮 + 文件名
            Button {
                NotificationCenter.default.post(name: .switchToTab, object: ContentView.Tab.files)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.fg)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.surface2)
                    )
            }
            .buttonStyle(.pressable)

            Text(viewModel.currentFile?.name ?? "编辑")
                .font(.system(size: 17, weight: .medium))
                .tracking(-0.34)
                .foregroundColor(Theme.Colors.fg)
                .lineLimit(1)

            Spacer()

            // 右：格式化 + RUN
            Button {
                showFormatSheet = true
            } label: {
                Image(systemName: "arrow.up.and.down.circle")
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
                viewModel.runCode()
                withAnimation(Theme.Animation.springEase) { outputOpen = true }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.accent)
                    )
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Theme.Colors.surface)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Colors.border)
        }
    }

    // MARK: - 文件标签页（对齐原型 .file-tabs）
    private var fileTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appState.openFiles, id: \.id) { file in
                    fileTab(file)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .frame(height: 36)
        .background(Theme.Colors.surface)
    }

    @ViewBuilder
    private func fileTab(_ file: ProjectFile) -> some View {
        let isActive = appState.activeFileId == file.id
        Button {
            viewModel.openFile(file)
            appState.activeFileId = file.id
        } label: {
            HStack(spacing: 5) {
                Image(systemName: iconForFile(file))
                    .font(.system(size: 11))
                    .foregroundColor(isActive ? Theme.Colors.fg : Theme.Colors.muted)
                Text(file.name)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(isActive ? Theme.Colors.fg : Theme.Colors.muted)
                Button {
                    closeTab(file)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.muted)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Theme.Colors.background : Theme.Colors.surface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Theme.Colors.border : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
    }

    private func iconForFile(_ file: ProjectFile) -> String {
        switch file.type {
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .json: return "curlybraces"
        case .text: return "doc.text"
        case .folder: return "folder.fill"
        }
    }

    private func closeTab(_ file: ProjectFile) {
        appState.closeFile(file)
        if appState.activeFileId == nil {
            viewModel.currentFile = nil
            viewModel.code = ""
        } else if let activeId = appState.activeFileId,
                  let active = appState.openFiles.first(where: { $0.id == activeId }) {
            viewModel.openFile(active)
        }
        showToast("已关闭 \(file.name)")
    }

    // MARK: - 编辑区 + 输出面板（对齐原型 .editor-wrap）
    @ViewBuilder
    private var editorContent: some View {
        if splitMode {
            // 分栏：左编辑 右输出
            HStack(spacing: 0) {
                codeArea
                    .frame(maxWidth: .infinity)
                outputPanel
                    .frame(width: UIScreen.main.bounds.width * 0.45)
                    .background(Theme.Colors.border.opacity(0.5))
            }
        } else {
            // 标准：上编辑 下输出
            VStack(spacing: 0) {
                codeArea
                    .frame(maxHeight: .infinity)
                if outputOpen {
                    outputPanel
                        .frame(height: 160)
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }

    private var codeArea: some View {
        ZStack(alignment: .bottomTrailing) {
            CodeMirrorView(
                code: $viewModel.code,
                fontSize: CGFloat(viewModel.fontSize),
                onCodeChange: { newCode in
                    if viewModel.currentFile != nil {
                        viewModel.currentFile?.content = newCode
                    }
                }
            )

            // 分栏切换按钮（对齐原型 .split-toggle）
            Button {
                withAnimation(Theme.Animation.springEase) {
                    splitMode.toggle()
                    if splitMode { outputOpen = true }
                }
                showToast(splitMode ? "分栏模式" : "标准模式")
            } label: {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.muted)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.Colors.surface2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.pressable)
            .padding(4)
        }
    }

    // MARK: - 输出面板（对齐原型 .output-panel）
    private var outputPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(OutputTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { outputTab = tab }
                    } label: {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: outputTab == tab ? .semibold : .medium))
                                .tracking(0.36)
                                .foregroundColor(outputTab == tab ? Theme.Colors.accent : Theme.Colors.muted)
                            Rectangle()
                                .fill(outputTab == tab ? Theme.Colors.accent : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                }

                Spacer()

                if viewModel.isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Theme.Colors.accent)
                }

                Button {
                    withAnimation(Theme.Animation.springEase) { outputOpen = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.muted)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(Theme.Colors.surface)
            .overlay(alignment: .bottom) {
                Divider().background(Theme.Colors.border)
            }

            // Body
            ScrollView {
                Text(currentOutput)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(currentOutputColor)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .textSelection(.enabled)
            }
            .background(Theme.Colors.codeBg)
        }
        .background(Theme.Colors.surface)
        .overlay(alignment: .top) {
            Divider().background(Theme.Colors.border)
        }
    }

    private var currentOutput: String {
        switch outputTab {
        case .output:
            return viewModel.output.isEmpty ? "无输出" : viewModel.output
        case .problems:
            return viewModel.outputHasError ? viewModel.output : "无问题"
        case .debug:
            return "调试器就绪"
        }
    }

    private var currentOutputColor: Color {
        switch outputTab {
        case .output:
            return viewModel.outputHasError ? Theme.Colors.danger : Theme.Colors.fg
        case .problems:
            return viewModel.outputHasError ? Theme.Colors.danger : Theme.Colors.muted
        case .debug:
            return Theme.Colors.muted
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(Theme.Colors.muted)
            VStack(spacing: 6) {
                Text("未打开文件")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.fg)
                Text("从「文件」标签选择或创建文件")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private func insertCode(_ code: String) {
        if viewModel.currentFile == nil {
            let file = ProjectFile(
                id: UUID().uuidString,
                name: "untitled.py",
                path: "",
                content: "",
                type: .python
            )
            viewModel.openFile(file)
            appState.openFile(file)
        }
        let separator = viewModel.code.isEmpty || viewModel.code.hasSuffix("\n") ? "" : "\n\n"
        viewModel.code = viewModel.code + separator + code
        viewModel.currentFile?.content = viewModel.code
        appState.updateActiveFileContent(viewModel.code)

        withAnimation { showInsertedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showInsertedToast = false }
        }
        showToast("已插入到编辑器")
    }
}

#Preview {
    EditorView()
        .environmentObject(AppState())
}

struct FormatSheetView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.Colors.muted2)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("代码格式化")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.Colors.fg)
                Text("使用 autopep8 格式化 Python 代码（PEP 8 标准，line-length 88）")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("当前代码 · \(viewModel.code.count) 字符")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundColor(Theme.Colors.muted)

                ScrollView {
                    Text(viewModel.code.isEmpty ? "(空)" : viewModel.code)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Theme.Colors.fg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(Theme.Colors.codeBg)
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            if viewModel.isFormatting {
                HStack {
                    ProgressView().scaleEffect(0.8).tint(Theme.Colors.accent)
                    Text("正在格式化…").foregroundColor(Theme.Colors.muted)
                }
                .padding()
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    viewModel.formatCode()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("格式化")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.isFormatting || viewModel.code.isEmpty ? Theme.Colors.muted2.opacity(0.3) : Theme.Colors.accent)
                    )
                }
                .disabled(viewModel.isFormatting || viewModel.code.isEmpty)

                Button("关闭") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.muted)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Theme.Colors.surface)
        .presentationDetents([.medium, .large])
    }
}
