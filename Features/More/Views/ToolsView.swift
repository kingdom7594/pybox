import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ToolsView: View {
    @State private var jsonInput: String = "{\"name\":\"PyBox\",\"version\":2,\"tags\":[\"ide\",\"python\"]}"
    @State private var jsonOutput: String = ""
    @State private var base64Input: String = "Hello, PyBox!"
    @State private var base64Output: String = ""
    @State private var qrInput: String = "https://opencode.ai"
    @State private var qrImage: CGImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                jsonSection
                qrSection
                base64Section
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("工具集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var jsonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("JSON 格式化", icon: "curlybraces")
            inputField(text: $jsonInput, placeholder: "输入 JSON")
            HStack(spacing: Theme.Spacing.sm) {
                actionButton("格式化", color: Theme.Colors.accent) { formatJSON() }
                actionButton("压缩", color: Theme.Colors.accent2) { minifyJSON() }
            }
            outputField(jsonOutput)
        }
    }

    private var qrSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("QR 码生成", icon: "qrcode")
            inputField(text: $qrInput, placeholder: "输入文本或链接")
            HStack(spacing: Theme.Spacing.sm) {
                actionButton("生成", color: Theme.Colors.accent) { generateQR() }
                actionButton("保存", color: Theme.Colors.success) { saveQR() }
                    .disabled(qrImage == nil)
            }
            if let qrImage {
                Image(decorative: qrImage, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            } else {
                Text("点击「生成」创建 QR 码")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.muted2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
    }

    private var base64Section: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Base64 编解码", icon: "doc.on.clipboard")
            inputField(text: $base64Input, placeholder: "输入文本")
            HStack(spacing: Theme.Spacing.sm) {
                actionButton("编码", color: Theme.Colors.accent) { encodeBase64() }
                actionButton("解码", color: Theme.Colors.accent2) { decodeBase64() }
            }
            outputField(base64Output)
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.accent)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.fg)
        }
    }

    private func inputField(text: Binding<String>, placeholder: String) -> some View {
        TextEditor(text: text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(Theme.Colors.fg)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.surface2)
            .frame(minHeight: 64)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.Colors.muted2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
    }

    private func outputField(_ content: String) -> some View {
        ScrollView {
            Text(content.isEmpty ? "(无输出)" : content)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Theme.Colors.muted)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
        }
        .frame(minHeight: 64, maxHeight: 160)
        .background(Theme.Colors.codeBg)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }

    private func actionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(color)
                )
        }
        .buttonStyle(.pressable)
    }

    private func formatJSON() {
        guard let data = jsonInput.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []),
              let pretty = try? JSONSerialization.data(
                withJSONObject: obj,
                options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
              ),
              let result = String(data: pretty, encoding: .utf8) else {
            jsonOutput = "JSON 解析失败"
            showToast("格式化失败")
            return
        }
        jsonOutput = result
        showToast("已格式化 JSON")
    }

    private func minifyJSON() {
        guard let data = jsonInput.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []),
              let minified = try? JSONSerialization.data(
                withJSONObject: obj,
                options: [.fragmentsAllowed]
              ),
              let result = String(data: minified, encoding: .utf8) else {
            jsonOutput = "JSON 解析失败"
            showToast("压缩失败")
            return
        }
        jsonOutput = result
        showToast("已压缩 JSON")
    }

    private func generateQR() {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(qrInput.utf8)
        filter.correctionLevel = "M"
        guard let ci = filter.outputImage else {
            showToast("QR 码生成失败")
            return
        }
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let context = CIContext()
        if let cg = context.createCGImage(scaled, from: scaled.extent) {
            qrImage = cg
            showToast("QR 码已生成")
        } else {
            showToast("QR 码生成失败")
        }
    }

    private func saveQR() {
        showToast("已保存 QR 码图片")
    }

    private func encodeBase64() {
        base64Output = Data(base64Input.utf8).base64EncodedString()
        showToast("已编码")
    }

    private func decodeBase64() {
        if let data = Data(base64Encoded: base64Input),
           let result = String(data: data, encoding: .utf8) {
            base64Output = result
            showToast("已解码")
        } else {
            base64Output = "解码失败：输入不是有效的 Base64 字符串"
            showToast("Base64 解码失败")
        }
    }
}

#Preview {
    ToolsView()
}
