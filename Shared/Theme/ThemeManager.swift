import SwiftUI

/// 全局主题管理器 — 管理 色板(palette) × 模式(mode)，持久化到 UserDefaults
/// 监听变化并实时解析为 ResolvedPalette 供 Theme.Colors 动态读取
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var palette: ThemePalette {
        didSet {
            UserDefaults.standard.set(palette.rawValue, forKey: "themePalette")
            recompute()
        }
    }

    @Published var mode: Theme.AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
            recompute()
        }
    }

    /// 当前解析后的 Color 集合（Theme.Colors 读取此属性）
    @Published private(set) var resolved: ResolvedPalette

    private init() {
        let savedPalette = UserDefaults.standard.string(forKey: "themePalette")
            .flatMap(ThemePalette.init(rawValue:)) ?? .emerald
        let savedMode = Theme.AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "")
            ?? .dark
        self.palette = savedPalette
        self.mode = savedMode
        self.resolved = resolvePalette(savedPalette, savedMode)
    }

    private func recompute() {
        resolved = resolvePalette(palette, mode)
    }

    /// 设置色板（带 toast 提示由调用方处理）
    func setPalette(_ p: ThemePalette) {
        guard p != palette else { return }
        palette = p
    }

    /// 设置模式
    func setMode(_ m: Theme.AppearanceMode) {
        guard m != mode else { return }
        mode = m
    }
}

/// 根视图注入主题：响应 palette/mode 变化 → 切换 ColorScheme + 触发全局重渲染
struct ThemedRoot: ViewModifier {
    @ObservedObject var manager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .environmentObject(manager)
            .preferredColorScheme(manager.mode.swiftUIScheme)
            .tint(manager.resolved.accent)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedRoot())
    }
}
