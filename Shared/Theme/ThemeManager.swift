import SwiftUI

/// 全局主题管理器 - 监听 @AppStorage 变化并应用到所有视图
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var mode: Theme.AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "themeMode") ?? Theme.AppearanceMode.dark.rawValue
        self.mode = Theme.AppearanceMode(rawValue: stored) ?? .dark
    }
}

/// 用于根 View 注入主题
struct ThemedRoot: ViewModifier {
    @ObservedObject var manager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(manager.mode.swiftUIScheme)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedRoot())
    }
}
