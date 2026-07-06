import SwiftUI

enum SceneShape {
    case rect(x: Double, y: Double, w: Double, h: Double, color: Color, radius: CGFloat, fill: Bool)
    case circle(x: Double, y: Double, r: Double, color: Color, fill: Bool)
    case line(x1: Double, y1: Double, x2: Double, y2: Double, color: Color, width: CGFloat)
    case text(x: Double, y: Double, str: String, color: Color, size: CGFloat)
}

struct SceneView: View {
    @State private var shapes: [SceneShape] = []
    @State private var script: String = "Rect(20, 20, 120, 80, \"#3b82f6\", 8, True)\nCircle(200, 60, 40, \"#ef4444\", True)\nLine(20, 130, 240, 130, \"#10b981\", 2)\nText(20, 150, \"Scene Canvas\", \"#f59e0b\", 16)"

    private let defaultScript = "Rect(20, 20, 120, 80, \"#3b82f6\", 8, True)\nCircle(200, 60, 40, \"#ef4444\", True)\nLine(20, 130, 240, 130, \"#10b981\", 2)\nText(20, 150, \"Scene Canvas\", \"#f59e0b\", 16)"

    var body: some View {
        VStack(spacing: 0) {
            toolBar
            canvasView
            scriptEditor
        }
        .background(Theme.Colors.background)
        .navigationTitle("Scene 画布")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    runScript()
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

    private var toolBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            toolButton("矩形", "rectangle") { appendTemplate("Rect(30, 30, 80, 60, \"#3b82f6\", 8, True)") }
            toolButton("圆形", "circle") { appendTemplate("Circle(150, 60, 30, \"#ef4444\", True)") }
            toolButton("直线", "line.diagonal") { appendTemplate("Line(10, 10, 100, 100, \"#10b981\", 2)") }
            toolButton("文字", "textformat") { appendTemplate("Text(20, 20, \"Text\", \"#f59e0b\", 16)") }
            Spacer()
            Button {
                shapes.removeAll()
                showToast("已清空画布")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("清空")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.danger)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.Colors.danger.opacity(0.15)))
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Colors.border)
        }
    }

    private func toolButton(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(Theme.Colors.fg)
            .frame(width: 52, height: 44)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Colors.surface2)
            )
        }
        .buttonStyle(.pressable)
    }

    private var canvasView: some View {
        Canvas { context, size in
            for shape in shapes {
                draw(shape, in: context)
            }
        }
        .background(Theme.Colors.codeBg)
        .frame(height: 280)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }

    private func draw(_ shape: SceneShape, in context: GraphicsContext) {
        switch shape {
        case let .rect(x, y, w, h, color, radius, fill):
            let rect = CGRect(x: x, y: y, width: w, height: h)
            let path = Path(roundedRect: rect, cornerRadius: radius)
            if fill {
                context.fill(path, with: .color(color))
            } else {
                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        case let .circle(x, y, r, color, fill):
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            let path = Path(ellipseIn: rect)
            if fill {
                context.fill(path, with: .color(color))
            } else {
                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        case let .line(x1, y1, x2, y2, color, width):
            var path = Path()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            context.stroke(path, with: .color(color), lineWidth: width)
        case let .text(x, y, str, color, size):
            context.draw(
                Text(str)
                    .font(.system(size: size))
                    .foregroundColor(color),
                at: CGPoint(x: x, y: y),
                anchor: .topLeading
            )
        }
    }

    private var scriptEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("脚本")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.muted)
            TextEditor(text: $script)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Theme.Colors.fg)
                .scrollContentBackground(.hidden)
                .background(Theme.Colors.codeBg)
                .frame(minHeight: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }

    private func appendTemplate(_ line: String) {
        if !script.isEmpty && !script.hasSuffix("\n") {
            script += "\n"
        }
        script += line + "\n"
        showToast("已添加模板代码")
    }

    private func runScript() {
        var result: [SceneShape] = []
        let pattern = "(\\w+)\\(([^)]*)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            shapes = result
            showToast("脚本解析失败")
            return
        }
        let ns = script as NSString
        let matches = regex.matches(in: script, range: NSRange(location: 0, length: ns.length))
        for m in matches {
            let name = ns.substring(with: m.range(at: 1))
            let args = parseArgs(ns.substring(with: m.range(at: 2)))
            switch name {
            case "Rect":
                if args.count >= 5 {
                    let radius = args.count > 5 ? CGFloat(double(args, 5)) : 0
                    let fill = args.count > 6 ? boolArg(args, 6) : true
                    result.append(.rect(
                        x: double(args, 0), y: double(args, 1), w: double(args, 2), h: double(args, 3),
                        color: colorArg(args, 4), radius: radius, fill: fill))
                }
            case "Circle":
                if args.count >= 5 {
                    result.append(.circle(
                        x: double(args, 0), y: double(args, 1), r: double(args, 2),
                        color: colorArg(args, 3), fill: boolArg(args, 4)))
                }
            case "Line":
                if args.count >= 6 {
                    result.append(.line(
                        x1: double(args, 0), y1: double(args, 1), x2: double(args, 2), y2: double(args, 3),
                        color: colorArg(args, 4), width: CGFloat(double(args, 5))))
                }
            case "Text":
                if args.count >= 5 {
                    result.append(.text(
                        x: double(args, 0), y: double(args, 1), str: args[2],
                        color: colorArg(args, 3), size: CGFloat(double(args, 4))))
                }
            default:
                break
            }
        }
        shapes = result
        showToast("已运行脚本，绘制 \(result.count) 个图形")
    }

    private func parseArgs(_ s: String) -> [String] {
        var args: [String] = []
        var current = ""
        var inQuote = false
        var quoteChar: Character = " "
        for ch in s {
            if !inQuote && (ch == "\"" || ch == "'") {
                inQuote = true
                quoteChar = ch
                continue
            }
            if inQuote && ch == quoteChar {
                inQuote = false
                continue
            }
            if !inQuote && ch == "," {
                args.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                continue
            }
            current.append(ch)
        }
        if !current.isEmpty {
            args.append(current.trimmingCharacters(in: .whitespaces))
        }
        return args
    }

    private func double(_ a: [String], _ i: Int) -> Double {
        guard i < a.count else { return 0 }
        return Double(a[i]) ?? 0
    }

    private func colorArg(_ a: [String], _ i: Int) -> Color {
        guard i < a.count else { return Theme.Colors.accent }
        let v = a[i]
        if v.hasPrefix("#") { return Color(hex: v) }
        switch v.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "white": return .white
        case "black": return .black
        case "gray", "grey": return .gray
        case "orange": return .orange
        case "purple": return .purple
        default: return Theme.Colors.accent
        }
    }

    private func boolArg(_ a: [String], _ i: Int) -> Bool {
        guard i < a.count else { return true }
        let v = a[i].lowercased()
        return v == "true" || v == "1" || v == "yes"
    }
}

#Preview {
    SceneView()
}
