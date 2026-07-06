import SwiftUI

// MARK: - 按钮按下反馈（opacity 0.65 + scale 0.97，对齐原型 .btn-press:active）

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var opacity: Double = 0.65

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - iOS 底部上滑 Sheet（对齐原型 .modal-overlay + .modal-sheet）

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isPresented {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial.opacity(0.3))
                    .onTapGesture { dismiss() }

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Theme.Colors.border)
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    content()
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                )
                .padding(.bottom, 0)
                .transition(.move(edge: .bottom))
            }
            .zIndex(1000)
        }
    }

    private func dismiss() {
        withAnimation(Theme.Animation.sheet) { isPresented = false }
    }
}

extension View {
    /// 挂载底部上滑 sheet（受 binding 控制）
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay(BottomSheet(isPresented: isPresented, content: content))
    }
}
