import SwiftUI

struct NotebookCell: Identifiable {
    enum CellType { case code, markdown }
    let id = UUID()
    var type: CellType
    var content: String
    var output: String = ""
    var executionCount: Int = 0
}

struct NotebookView: View {
    @State private var cells: [NotebookCell] = [
        NotebookCell(type: .markdown, content: "# Notebook\n这是一个 **SwiftUI** 实现的 Notebook 演示。"),
        NotebookCell(type: .code, content: "print('Hello, Jupyter!')"),
        NotebookCell(type: .code, content: "x = 1 + 2\nprint(x)")
    ]
    @State private var counter = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(cells) { cell in
                    cellView(cell)
                }
                addCodeButton
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Notebook")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addCodeCell()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }

    private func cellView(_ cell: NotebookCell) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cellToolbar(cell)
            editor(for: cell)
            if cell.type == .code && !cell.output.isEmpty {
                outputView(cell.output)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(Theme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private func cellToolbar(_ cell: NotebookCell) -> some View {
        HStack(spacing: 8) {
            if cell.type == .code {
                Text("In [\(cell.executionCount)]")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.Colors.muted)
                Spacer()
                Button {
                    runCell(cell)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("运行")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.Colors.success.opacity(0.15)))
                }
                .buttonStyle(.pressable)
            } else {
                Text("MD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.Colors.accent))
                Spacer()
            }
            Button {
                deleteCell(cell)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.muted2)
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 8)
    }

    private func editor(for cell: NotebookCell) -> some View {
        TextEditor(text: contentBinding(for: cell))
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(Theme.Colors.fg)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.codeBg)
            .frame(minHeight: 64)
            .padding(Theme.Spacing.md)
    }

    private func outputView(_ output: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().background(Theme.Colors.border)
            Text(output)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Theme.Colors.muted)
                .textSelection(.enabled)
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Colors.codeBg.opacity(0.5))
    }

    private var addCodeButton: some View {
        Button {
            addCodeCell()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("添加代码单元格")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(
                        Theme.Colors.accent.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [6])
                    )
            )
        }
        .buttonStyle(.pressable)
    }

    private func contentBinding(for cell: NotebookCell) -> Binding<String> {
        Binding<String>(
            get: { cell.content },
            set: { newValue in
                if let idx = cells.firstIndex(where: { $0.id == cell.id }) {
                    cells[idx].content = newValue
                }
            }
        )
    }

    private func runCell(_ cell: NotebookCell) {
        guard let idx = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        counter += 1
        cells[idx].executionCount = counter
        cells[idx].output = simulateNotebook(cells[idx].content)
        showToast("单元格已执行 (In [\(counter)])")
    }

    private func simulateNotebook(_ code: String) -> String {
        var outputs: [String] = []
        for line in code.split(separator: "\n") {
            let s = line.trimmingCharacters(in: .whitespaces)
            if s.hasPrefix("print(") && s.hasSuffix(")") {
                var inner = String(s.dropFirst(6).dropLast())
                if inner.hasPrefix("'") || inner.hasPrefix("\"") {
                    inner = String(inner.dropFirst())
                }
                if inner.hasSuffix("'") || inner.hasSuffix("\"") {
                    inner = String(inner.dropLast())
                }
                outputs.append(inner)
            }
        }
        return outputs.isEmpty ? "(无输出)" : outputs.joined(separator: "\n")
    }

    private func deleteCell(_ cell: NotebookCell) {
        cells.removeAll { $0.id == cell.id }
        showToast("已删除单元格")
    }

    private func addCodeCell() {
        cells.append(NotebookCell(type: .code, content: ""))
        showToast("已添加代码单元格")
    }
}

#Preview {
    NotebookView()
}
