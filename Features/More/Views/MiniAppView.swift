import SwiftUI

struct MiniAppTemplate: Identifiable, Hashable {
    enum Kind { case counter, todo, weather }
    let id = UUID()
    let kind: Kind
    let title: String
    let icon: String
    let code: String

    static let all: [MiniAppTemplate] = [
        MiniAppTemplate(kind: .counter, title: "计数器", icon: "plus.app",
            code: "count = 0\n\ndef on_tap():\n    global count\n    count += 1\n    update(count)"),
        MiniAppTemplate(kind: .todo, title: "待办事项", icon: "checklist",
            code: "todos = []\n\ndef add(text):\n    todos.append(text)\n    render(todos)"),
        MiniAppTemplate(kind: .weather, title: "天气", icon: "cloud.sun",
            code: "days = [\n  ('周一', 'sun.max', 28),\n  ('周二', 'cloud', 24),\n  ('周三', 'rain', 20),\n]\nrender(days)")
    ]
}

struct MiniAppView: View {
    @State private var templates: [MiniAppTemplate] = MiniAppTemplate.all
    @State private var selectedId: UUID = MiniAppTemplate.all[0].id
    @State private var code: String = MiniAppTemplate.all[0].code
    @State private var counterValue: Int = 0
    @State private var todoItems: [String] = ["学习 SwiftUI", "完成 MiniApp"]
    @State private var todoInput: String = ""

    private var selected: MiniAppTemplate? {
        templates.first { $0.id == selectedId }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            templatePicker
            codeEditor
            previewArea
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .background(Theme.Colors.background)
        .navigationTitle("MiniApp")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    refreshPreview()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("运行")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }

    private var templatePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(templates) { t in
                    Button {
                        selectTemplate(t)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: t.icon)
                                .font(.system(size: 18))
                            Text(t.title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedId == t.id ? .white : Theme.Colors.fg)
                        .frame(width: 76, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                .fill(selectedId == t.id ? Theme.Colors.accent : Theme.Colors.surface2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }

    private var codeEditor: some View {
        TextEditor(text: $code)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(Theme.Colors.fg)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.codeBg)
            .frame(height: 150)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var previewArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("预览")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.muted)
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Theme.Colors.surface)
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(Theme.Colors.border, lineWidth: 1)
                previewContent
            }
            .frame(height: 200)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch selected?.kind {
        case .counter:
            counterPreview
        case .todo:
            todoPreview
        case .weather:
            weatherPreview
        default:
            EmptyView()
        }
    }

    private var counterPreview: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("\(counterValue)")
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.Colors.fg)
            Button {
                counterValue += 1
            } label: {
                Text("+1")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.Colors.accent))
            }
            .buttonStyle(.pressable)
        }
    }

    private var todoPreview: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("添加待办", text: $todoInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.fg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                            .fill(Theme.Colors.surface2)
                    )
                Button {
                    addTodo()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.Colors.accent))
                }
                .buttonStyle(.pressable)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(todoItems.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Theme.Colors.accent)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.fg)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var weatherPreview: some View {
        let days: [(String, String, Int)] = [
            ("周一", "sun.max.fill", 28),
            ("周二", "cloud.fill", 24),
            ("周三", "cloud.rain.fill", 20)
        ]
        return HStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Text(day.0)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.muted)
                    Image(systemName: day.1)
                        .font(.system(size: 22))
                        .foregroundColor(Theme.Colors.accent)
                    Text("\(day.2)°")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.fg)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(Theme.Colors.surface2)
                )
            }
        }
        .padding(Theme.Spacing.md)
    }

    private func selectTemplate(_ t: MiniAppTemplate) {
        selectedId = t.id
        code = t.code
        counterValue = 0
        todoItems = ["学习 SwiftUI", "完成 MiniApp"]
        todoInput = ""
        showToast("已切换到\(t.title)模板")
    }

    private func refreshPreview() {
        counterValue = 0
        todoItems = ["学习 SwiftUI", "完成 MiniApp"]
        todoInput = ""
        showToast("预览已刷新")
    }

    private func addTodo() {
        let text = todoInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        todoItems.append(text)
        todoInput = ""
    }
}

#Preview {
    MiniAppView()
}
