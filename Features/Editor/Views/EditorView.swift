import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @EnvironmentObject var appState: AppState
    @FocusState private var isEditorFocused: Bool
    @State private var showInsertedToast = false
    @State private var showRunHistory = false
    @State private var showFormatSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.currentFile != nil {
                    editorContent
                } else {
                    emptyStateView
                }
            }
            .navigationTitle(viewModel.currentFile?.name ?? "Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showFormatSheet = true
                        } label: {
                            Label("Format (PEP 8)", systemImage: "paintbrush")
                        }
                        Divider()
                        Toggle("Auto Complete", isOn: .init(
                            get: { viewModel.autoCompleteEnabled },
                            set: { _ in viewModel.toggleAutoComplete() }
                        ))
                        Toggle("Line Numbers", isOn: .init(
                            get: { viewModel.showLineNumbers },
                            set: { _ in viewModel.toggleLineNumbers() }
                        ))
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showRunHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.runCode) {
                        Label("Run", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $showFormatSheet) {
                FormatSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $showRunHistory) {
                RunHistoryView()
            }
        }
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
            }
        }
        .overlay(alignment: .top) {
            if showInsertedToast {
                Text("✓ 已插入到编辑器")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func insertCode(_ code: String) {
        if viewModel.currentFile == nil {
            viewModel.openFile(ProjectFile(
                id: UUID().uuidString,
                name: "untitled.py",
                path: "",
                content: "",
                type: .python
            ))
        }
        let separator = viewModel.code.isEmpty || viewModel.code.hasSuffix("\n") ? "" : "\n\n"
        viewModel.code = viewModel.code + separator + code
        viewModel.currentFile?.content = viewModel.code
        appState.updateActiveFileContent(viewModel.code)

        withAnimation { showInsertedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showInsertedToast = false }
        }
    }

    private var editorContent: some View {
        VStack(spacing: 0) {
            CodeMirrorView(
                code: $viewModel.code,
                fontSize: CGFloat(viewModel.fontSize),
                onCodeChange: { newCode in
                    if viewModel.currentFile != nil {
                        viewModel.currentFile?.content = newCode
                    }
                }
            )
            .frame(minHeight: 400)
            .background(Theme.Colors.editorBackground)

            Divider()

            outputView
        }
    }
    
    private var outputView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Output")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button(action: { viewModel.output = "" }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                Text(viewModel.output.isEmpty ? "No output" : viewModel.output)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(viewModel.outputHasError ? .red : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .frame(maxHeight: 150)
            .background(Theme.Colors.outputBackground)
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No File Open")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Select a file from the Files tab or create a new one")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct FormatSheetView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("代码格式化")
                    .font(.title2.bold())
                Text("使用 autopep8 格式化 Python 代码（PEP 8 标准，line-length 88）。")
                    .font(.callout)
                    .foregroundColor(.secondary)

                if viewModel.isFormatting {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("正在格式化…").foregroundColor(.secondary)
                    }
                    .padding()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("当前代码（" + "\(viewModel.code.count) 字符）")
                        .font(.caption).foregroundColor(.secondary)
                    ScrollView {
                        Text(viewModel.code.isEmpty ? "(空)" : viewModel.code)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.formatCode()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    } label: {
                        Label("格式化", systemImage: "paintbrush")
                    }
                    .disabled(viewModel.isFormatting || viewModel.code.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    EditorView()
}