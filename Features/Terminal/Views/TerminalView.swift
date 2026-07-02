import SwiftUI

struct TerminalView: View {
    @StateObject private var viewModel = TerminalViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                outputView
                Divider()
                inputView
            }
            .navigationTitle("Terminal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: viewModel.clearTerminal) {
                            Label("Clear", systemImage: "trash")
                        }
                        Button(action: viewModel.toggleAutoScroll) {
                            Label(viewModel.autoScroll ? "Auto-scroll On" : "Auto-scroll Off", 
                                  systemImage: viewModel.autoScroll ? "arrow.down.to.line" : "arrow.down")
                        }
                        Divider()
                        Button(action: viewModel.showKeyboardShortcuts) {
                            Label("Keyboard Shortcuts", systemImage: "keyboard")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.initialize()
        }
    }
    
    private var outputView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.outputLines) { line in
                        TerminalLineView(line: line)
                            .id(line.id)
                    }
                }
                .padding()
            }
            .background(Theme.Colors.terminalBackground)
            .onChange(of: viewModel.outputLines.count) { _ in
                if viewModel.autoScroll, let lastLine = viewModel.outputLines.last {
                    withAnimation {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            Text(viewModel.prompt)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Theme.Colors.terminalPrompt)
            
            TextField("Enter command...", text: $viewModel.inputCommand)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .focused($isInputFocused)
                .submitLabel(.send)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .onSubmit {
                    viewModel.executeCommand()
                }
            
            Button(action: viewModel.executeCommand) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(Theme.Colors.primary)
            }
            .disabled(viewModel.inputCommand.isEmpty)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

struct TerminalLineView: View {
    let line: TerminalLine
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.prompt)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(promptColor)
                .frame(width: 20, alignment: .leading)
            
            Text(line.output)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(textColor)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
    
    private var promptColor: Color {
        switch line.type {
        case .input: return .blue
        case .output: return Theme.Colors.terminalPrompt
        case .error: return .red
        case .success: return .green
        }
    }
    
    private var textColor: Color {
        switch line.type {
        case .input: return .primary
        case .output: return .primary
        case .error: return .red
        case .success: return .green
        }
    }
}

#Preview {
    TerminalView()
}
