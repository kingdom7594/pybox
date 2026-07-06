import SwiftUI

/// 全局 Toast 管理器 — 对齐原型 .toast：底部上滑、自动消失
@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var message: String = ""
    @Published var isShown: Bool = false
    private var dismissTask: Task<Void, Never>?

    func show(_ text: String) {
        dismissTask?.cancel()
        withAnimation(Theme.Animation.toast) { message = text; isShown = true }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.toast) { isShown = false }
        }
    }
}

/// Toast 覆盖层 — 挂在根视图，底部 88pt 偏移
struct ToastOverlay: View {
    @ObservedObject var manager = ToastManager.shared

    var body: some View {
        VStack {
            Spacer()
            if manager.isShown {
                Text(manager.message)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.fg)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.surface3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
                    )
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
        .frame(maxWidth: .infinity)
    }
}

extension View {
    /// 挂载全局 toast 覆盖层
    func toastOverlay() -> some View {
        overlay(ToastOverlay())
    }

    /// 便捷：显示 toast
    func showToast(_ message: String) {
        ToastManager.shared.show(message)
    }
}
