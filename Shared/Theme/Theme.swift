import SwiftUI

// MARK: - 色板（7 套 × 浅色/深色 = 14 套主题）
// 对齐原型 data-theme × data-mode，每个组合独立声明全套 OKLch 变量

enum ThemePalette: String, CaseIterable, Identifiable {
    case emerald, ocean, lilac, sunset, rose, teal, graphite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emerald: return "翠绿"
        case .ocean: return "海洋蓝"
        case .lilac: return "丁香紫"
        case .sunset: return "日落橙"
        case .rose: return "玫瑰粉"
        case .teal: return "碧波青"
        case .graphite: return "石墨灰"
        }
    }

    var subtitle: String {
        switch self {
        case .emerald: return "Python 经典绿 · 默认"
        case .ocean: return "iOS 系统蓝 · 清爽专业"
        case .lilac: return "优雅紫 · 创意灵感"
        case .sunset: return "温暖橙 · 活力满满"
        case .rose: return "精致粉 · 独特风格"
        case .teal: return "清新青 · 沉浸开发"
        case .graphite: return "极简灰 · 专注代码"
        }
    }

    /// 设置页 swatch 预览圆色（取自原型 .theme-swatch background）
    var swatchColor: Color {
        switch self {
        case .emerald: return OKLch(0.62, 0.18, 150).color
        case .ocean:   return OKLch(0.55, 0.20, 250).color
        case .lilac:   return OKLch(0.55, 0.18, 290).color
        case .sunset:  return OKLch(0.62, 0.18, 70).color
        case .rose:    return OKLch(0.62, 0.18, 350).color
        case .teal:    return OKLch(0.62, 0.16, 190).color
        case .graphite:return OKLch(0.62, 0, 250).color
        }
    }
}

// MARK: - 单套主题的原始 OKLch 数据（24 个 token）

struct RawPalette {
    let bg, surface, surface2, surface3: OKLch
    let fg, muted, muted2: OKLch
    let border, border2: OKLch
    let accent, accent2, accentDim: OKLch
    let success, warn, danger: OKLch
    let key, fn, str, com, num, bui, dec: OKLch
    let tabBarBg, codeBg: OKLch
}

// MARK: - 解析后的主题（Color 属性，供视图使用）

struct ResolvedPalette {
    let bg, surface, surface2, surface3: Color
    let fg, muted, muted2: Color
    let border, border2: Color
    let accent, accent2, accentDim: Color
    let success, warn, danger: Color
    let key, fn, str, com, num, bui, dec: Color
    let tabBarBg, codeBg: Color

    init(_ r: RawPalette) {
        bg = r.bg.color; surface = r.surface.color; surface2 = r.surface2.color; surface3 = r.surface3.color
        fg = r.fg.color; muted = r.muted.color; muted2 = r.muted2.color
        border = r.border.color; border2 = r.border2.color
        accent = r.accent.color; accent2 = r.accent2.color; accentDim = r.accentDim.color
        success = r.success.color; warn = r.warn.color; danger = r.danger.color
        key = r.key.color; fn = r.fn.color; str = r.str.color; com = r.com.color
        num = r.num.color; bui = r.bui.color; dec = r.dec.color
        tabBarBg = r.tabBarBg.color; codeBg = r.codeBg.color
    }
}

// MARK: - 14 套主题原始数据（逐值对齐原型 CSS）

private let P = OKLch(1, 0, 0) // placeholder unused

private let emeraldDark = RawPalette(
    bg: OKLch(0.12, 0.01, 150), surface: OKLch(0.16, 0.012, 150), surface2: OKLch(0.20, 0.015, 150), surface3: OKLch(0.24, 0.018, 150),
    fg: OKLch(0.93, 0.005, 90), muted: OKLch(0.55, 0.01, 90), muted2: OKLch(0.42, 0.008, 90),
    border: OKLch(0.26, 0.01, 150), border2: OKLch(0.30, 0.012, 150),
    accent: OKLch(0.62, 0.18, 150), accent2: OKLch(0.52, 0.18, 150), accentDim: OKLch(0.35, 0.18, 150, 0.3),
    success: OKLch(0.65, 0.18, 145), warn: OKLch(0.72, 0.16, 85), danger: OKLch(0.60, 0.20, 25),
    key: OKLch(0.72, 0.14, 300), fn: OKLch(0.72, 0.12, 210), str: OKLch(0.68, 0.14, 145), com: OKLch(0.48, 0.02, 240),
    num: OKLch(0.72, 0.14, 40), bui: OKLch(0.68, 0.10, 180), dec: OKLch(0.68, 0.12, 280),
    tabBarBg: OKLch(0.15, 0.012, 150), codeBg: OKLch(0.08, 0.005, 250)
)
private let emeraldLight = RawPalette(
    bg: OKLch(0.98, 0.008, 150), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.012, 150), surface3: OKLch(0.92, 0.015, 150),
    fg: OKLch(0.22, 0.015, 150), muted: OKLch(0.48, 0.015, 150), muted2: OKLch(0.62, 0.012, 150),
    border: OKLch(0.88, 0.012, 150), border2: OKLch(0.82, 0.015, 150),
    accent: OKLch(0.52, 0.18, 150), accent2: OKLch(0.42, 0.18, 150), accentDim: OKLch(0.52, 0.18, 150, 0.15),
    success: OKLch(0.50, 0.18, 145), warn: OKLch(0.60, 0.16, 85), danger: OKLch(0.52, 0.20, 25),
    key: OKLch(0.50, 0.16, 300), fn: OKLch(0.50, 0.14, 210), str: OKLch(0.46, 0.16, 145), com: OKLch(0.60, 0.015, 240),
    num: OKLch(0.50, 0.16, 40), bui: OKLch(0.48, 0.12, 180), dec: OKLch(0.48, 0.14, 280),
    tabBarBg: OKLch(0.97, 0.01, 150), codeBg: OKLch(0.08, 0.008, 150)
)

private let oceanDark = RawPalette(
    bg: OKLch(0.11, 0.015, 240), surface: OKLch(0.15, 0.018, 240), surface2: OKLch(0.19, 0.02, 240), surface3: OKLch(0.23, 0.022, 240),
    fg: OKLch(0.94, 0.005, 240), muted: OKLch(0.56, 0.01, 240), muted2: OKLch(0.43, 0.008, 240),
    border: OKLch(0.25, 0.015, 240), border2: OKLch(0.29, 0.018, 240),
    accent: OKLch(0.60, 0.22, 240), accent2: OKLch(0.50, 0.22, 240), accentDim: OKLch(0.33, 0.22, 240, 0.3),
    success: OKLch(0.62, 0.18, 160), warn: OKLch(0.70, 0.16, 90), danger: OKLch(0.58, 0.22, 350),
    key: OKLch(0.72, 0.14, 280), fn: OKLch(0.72, 0.14, 230), str: OKLch(0.66, 0.14, 160), com: OKLch(0.48, 0.02, 240),
    num: OKLch(0.72, 0.14, 30), bui: OKLch(0.68, 0.08, 200), dec: OKLch(0.68, 0.12, 270),
    tabBarBg: OKLch(0.14, 0.018, 240), codeBg: OKLch(0.08, 0.005, 250)
)
private let oceanLight = RawPalette(
    bg: OKLch(0.98, 0.01, 240), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.015, 240), surface3: OKLch(0.92, 0.018, 240),
    fg: OKLch(0.22, 0.018, 240), muted: OKLch(0.48, 0.018, 240), muted2: OKLch(0.62, 0.015, 240),
    border: OKLch(0.88, 0.015, 240), border2: OKLch(0.82, 0.018, 240),
    accent: OKLch(0.50, 0.22, 240), accent2: OKLch(0.40, 0.22, 240), accentDim: OKLch(0.50, 0.22, 240, 0.15),
    success: OKLch(0.50, 0.18, 160), warn: OKLch(0.58, 0.16, 90), danger: OKLch(0.50, 0.22, 350),
    key: OKLch(0.50, 0.16, 280), fn: OKLch(0.50, 0.16, 230), str: OKLch(0.46, 0.16, 160), com: OKLch(0.60, 0.018, 240),
    num: OKLch(0.50, 0.16, 30), bui: OKLch(0.48, 0.12, 200), dec: OKLch(0.48, 0.14, 270),
    tabBarBg: OKLch(0.97, 0.012, 240), codeBg: OKLch(0.08, 0.005, 250)
)

private let lilacDark = RawPalette(
    bg: OKLch(0.12, 0.02, 280), surface: OKLch(0.16, 0.022, 280), surface2: OKLch(0.20, 0.025, 280), surface3: OKLch(0.24, 0.028, 280),
    fg: OKLch(0.93, 0.008, 280), muted: OKLch(0.55, 0.015, 280), muted2: OKLch(0.42, 0.012, 280),
    border: OKLch(0.26, 0.02, 280), border2: OKLch(0.30, 0.022, 280),
    accent: OKLch(0.60, 0.20, 290), accent2: OKLch(0.50, 0.20, 290), accentDim: OKLch(0.33, 0.20, 290, 0.3),
    success: OKLch(0.62, 0.18, 150), warn: OKLch(0.70, 0.16, 80), danger: OKLch(0.58, 0.20, 20),
    key: OKLch(0.72, 0.14, 310), fn: OKLch(0.70, 0.12, 220), str: OKLch(0.66, 0.14, 150), com: OKLch(0.48, 0.02, 260),
    num: OKLch(0.70, 0.14, 35), bui: OKLch(0.66, 0.10, 185), dec: OKLch(0.68, 0.12, 285),
    tabBarBg: OKLch(0.15, 0.022, 280), codeBg: OKLch(0.08, 0.005, 250)
)
private let lilacLight = RawPalette(
    bg: OKLch(0.98, 0.015, 280), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.018, 280), surface3: OKLch(0.92, 0.022, 280),
    fg: OKLch(0.22, 0.02, 280), muted: OKLch(0.48, 0.02, 280), muted2: OKLch(0.62, 0.018, 280),
    border: OKLch(0.88, 0.018, 280), border2: OKLch(0.82, 0.022, 280),
    accent: OKLch(0.50, 0.20, 290), accent2: OKLch(0.40, 0.20, 290), accentDim: OKLch(0.50, 0.20, 290, 0.15),
    success: OKLch(0.50, 0.18, 150), warn: OKLch(0.58, 0.16, 80), danger: OKLch(0.50, 0.20, 20),
    key: OKLch(0.50, 0.16, 310), fn: OKLch(0.50, 0.14, 220), str: OKLch(0.46, 0.16, 150), com: OKLch(0.60, 0.018, 260),
    num: OKLch(0.50, 0.16, 35), bui: OKLch(0.48, 0.12, 185), dec: OKLch(0.48, 0.14, 285),
    tabBarBg: OKLch(0.97, 0.015, 280), codeBg: OKLch(0.08, 0.005, 250)
)

private let sunsetDark = RawPalette(
    bg: OKLch(0.13, 0.015, 60), surface: OKLch(0.17, 0.018, 60), surface2: OKLch(0.21, 0.02, 60), surface3: OKLch(0.25, 0.022, 60),
    fg: OKLch(0.93, 0.008, 60), muted: OKLch(0.55, 0.015, 60), muted2: OKLch(0.42, 0.012, 60),
    border: OKLch(0.27, 0.018, 60), border2: OKLch(0.31, 0.02, 60),
    accent: OKLch(0.62, 0.18, 65), accent2: OKLch(0.50, 0.18, 65), accentDim: OKLch(0.34, 0.18, 65, 0.3),
    success: OKLch(0.62, 0.18, 145), warn: OKLch(0.68, 0.18, 60), danger: OKLch(0.58, 0.22, 15),
    key: OKLch(0.70, 0.14, 295), fn: OKLch(0.70, 0.12, 215), str: OKLch(0.66, 0.14, 140), com: OKLch(0.48, 0.02, 250),
    num: OKLch(0.70, 0.14, 30), bui: OKLch(0.66, 0.10, 180), dec: OKLch(0.68, 0.12, 275),
    tabBarBg: OKLch(0.16, 0.018, 60), codeBg: OKLch(0.08, 0.005, 250)
)
private let sunsetLight = RawPalette(
    bg: OKLch(0.98, 0.012, 60), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.018, 60), surface3: OKLch(0.92, 0.022, 60),
    fg: OKLch(0.25, 0.018, 60), muted: OKLch(0.50, 0.018, 60), muted2: OKLch(0.64, 0.015, 60),
    border: OKLch(0.88, 0.018, 60), border2: OKLch(0.82, 0.022, 60),
    accent: OKLch(0.55, 0.18, 60), accent2: OKLch(0.45, 0.18, 60), accentDim: OKLch(0.55, 0.18, 60, 0.15),
    success: OKLch(0.50, 0.18, 145), warn: OKLch(0.55, 0.18, 60), danger: OKLch(0.50, 0.22, 15),
    key: OKLch(0.50, 0.16, 295), fn: OKLch(0.50, 0.14, 215), str: OKLch(0.46, 0.16, 140), com: OKLch(0.60, 0.018, 250),
    num: OKLch(0.50, 0.16, 30), bui: OKLch(0.48, 0.12, 180), dec: OKLch(0.48, 0.14, 275),
    tabBarBg: OKLch(0.97, 0.015, 60), codeBg: OKLch(0.08, 0.005, 250)
)

private let roseDark = RawPalette(
    bg: OKLch(0.13, 0.02, 350), surface: OKLch(0.17, 0.022, 350), surface2: OKLch(0.21, 0.025, 350), surface3: OKLch(0.25, 0.028, 350),
    fg: OKLch(0.93, 0.008, 350), muted: OKLch(0.55, 0.015, 350), muted2: OKLch(0.42, 0.012, 350),
    border: OKLch(0.27, 0.02, 350), border2: OKLch(0.31, 0.022, 350),
    accent: OKLch(0.62, 0.20, 345), accent2: OKLch(0.50, 0.20, 345), accentDim: OKLch(0.34, 0.20, 345, 0.3),
    success: OKLch(0.62, 0.18, 150), warn: OKLch(0.68, 0.16, 85), danger: OKLch(0.60, 0.22, 10),
    key: OKLch(0.70, 0.14, 320), fn: OKLch(0.70, 0.12, 225), str: OKLch(0.66, 0.14, 155), com: OKLch(0.48, 0.02, 260),
    num: OKLch(0.70, 0.14, 40), bui: OKLch(0.66, 0.10, 190), dec: OKLch(0.68, 0.12, 285),
    tabBarBg: OKLch(0.16, 0.022, 350), codeBg: OKLch(0.08, 0.005, 250)
)
private let roseLight = RawPalette(
    bg: OKLch(0.98, 0.015, 350), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.02, 350), surface3: OKLch(0.92, 0.025, 350),
    fg: OKLch(0.25, 0.02, 350), muted: OKLch(0.50, 0.02, 350), muted2: OKLch(0.64, 0.018, 350),
    border: OKLch(0.88, 0.02, 350), border2: OKLch(0.82, 0.025, 350),
    accent: OKLch(0.55, 0.20, 345), accent2: OKLch(0.45, 0.20, 345), accentDim: OKLch(0.55, 0.20, 345, 0.15),
    success: OKLch(0.50, 0.18, 150), warn: OKLch(0.55, 0.16, 85), danger: OKLch(0.50, 0.22, 10),
    key: OKLch(0.50, 0.16, 320), fn: OKLch(0.50, 0.14, 225), str: OKLch(0.46, 0.16, 155), com: OKLch(0.60, 0.018, 260),
    num: OKLch(0.50, 0.16, 40), bui: OKLch(0.48, 0.12, 190), dec: OKLch(0.48, 0.14, 285),
    tabBarBg: OKLch(0.97, 0.018, 350), codeBg: OKLch(0.08, 0.005, 250)
)

private let tealDark = RawPalette(
    bg: OKLch(0.11, 0.015, 190), surface: OKLch(0.15, 0.018, 190), surface2: OKLch(0.19, 0.02, 190), surface3: OKLch(0.23, 0.022, 190),
    fg: OKLch(0.93, 0.005, 190), muted: OKLch(0.55, 0.01, 190), muted2: OKLch(0.42, 0.008, 190),
    border: OKLch(0.25, 0.015, 190), border2: OKLch(0.29, 0.018, 190),
    accent: OKLch(0.62, 0.18, 190), accent2: OKLch(0.50, 0.18, 190), accentDim: OKLch(0.34, 0.18, 190, 0.3),
    success: OKLch(0.63, 0.18, 155), warn: OKLch(0.68, 0.16, 90), danger: OKLch(0.58, 0.20, 30),
    key: OKLch(0.70, 0.14, 305), fn: OKLch(0.70, 0.12, 220), str: OKLch(0.66, 0.14, 150), com: OKLch(0.48, 0.02, 250),
    num: OKLch(0.70, 0.14, 35), bui: OKLch(0.66, 0.10, 185), dec: OKLch(0.68, 0.12, 280),
    tabBarBg: OKLch(0.14, 0.018, 190), codeBg: OKLch(0.08, 0.005, 250)
)
private let tealLight = RawPalette(
    bg: OKLch(0.98, 0.012, 190), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.96, 0.018, 190), surface3: OKLch(0.92, 0.022, 190),
    fg: OKLch(0.22, 0.018, 190), muted: OKLch(0.48, 0.018, 190), muted2: OKLch(0.62, 0.015, 190),
    border: OKLch(0.88, 0.018, 190), border2: OKLch(0.82, 0.022, 190),
    accent: OKLch(0.50, 0.18, 190), accent2: OKLch(0.40, 0.18, 190), accentDim: OKLch(0.50, 0.18, 190, 0.15),
    success: OKLch(0.50, 0.18, 155), warn: OKLch(0.55, 0.16, 90), danger: OKLch(0.50, 0.20, 30),
    key: OKLch(0.50, 0.16, 305), fn: OKLch(0.50, 0.14, 220), str: OKLch(0.46, 0.16, 150), com: OKLch(0.60, 0.018, 250),
    num: OKLch(0.50, 0.16, 35), bui: OKLch(0.48, 0.12, 185), dec: OKLch(0.48, 0.14, 280),
    tabBarBg: OKLch(0.97, 0.012, 190), codeBg: OKLch(0.08, 0.005, 250)
)

private let graphiteDark = RawPalette(
    bg: OKLch(0.12, 0.002, 250), surface: OKLch(0.16, 0.003, 250), surface2: OKLch(0.20, 0.004, 250), surface3: OKLch(0.24, 0.005, 250),
    fg: OKLch(0.92, 0.002, 250), muted: OKLch(0.54, 0.003, 250), muted2: OKLch(0.41, 0.003, 250),
    border: OKLch(0.26, 0.004, 250), border2: OKLch(0.30, 0.005, 250),
    accent: OKLch(0.65, 0.04, 250), accent2: OKLch(0.55, 0.04, 250), accentDim: OKLch(0.38, 0.04, 250, 0.25),
    success: OKLch(0.62, 0.06, 145), warn: OKLch(0.68, 0.06, 80), danger: OKLch(0.58, 0.06, 20),
    key: OKLch(0.70, 0.06, 300), fn: OKLch(0.70, 0.05, 220), str: OKLch(0.66, 0.06, 150), com: OKLch(0.48, 0.02, 250),
    num: OKLch(0.70, 0.05, 40), bui: OKLch(0.66, 0.04, 180), dec: OKLch(0.66, 0.05, 280),
    tabBarBg: OKLch(0.15, 0.003, 250), codeBg: OKLch(0.08, 0.005, 250)
)
private let graphiteLight = RawPalette(
    bg: OKLch(0.97, 0.003, 250), surface: OKLch(1.0, 0, 0), surface2: OKLch(0.95, 0.004, 250), surface3: OKLch(0.91, 0.005, 250),
    fg: OKLch(0.20, 0.004, 250), muted: OKLch(0.46, 0.004, 250), muted2: OKLch(0.60, 0.003, 250),
    border: OKLch(0.87, 0.005, 250), border2: OKLch(0.80, 0.006, 250),
    accent: OKLch(0.40, 0.05, 250), accent2: OKLch(0.30, 0.05, 250), accentDim: OKLch(0.40, 0.05, 250, 0.12),
    success: OKLch(0.46, 0.10, 145), warn: OKLch(0.52, 0.12, 80), danger: OKLch(0.48, 0.15, 20),
    key: OKLch(0.48, 0.10, 300), fn: OKLch(0.46, 0.08, 220), str: OKLch(0.44, 0.10, 150), com: OKLch(0.58, 0.005, 250),
    num: OKLch(0.46, 0.10, 40), bui: OKLch(0.44, 0.08, 180), dec: OKLch(0.44, 0.08, 280),
    tabBarBg: OKLch(0.96, 0.003, 250), codeBg: OKLch(0.08, 0.005, 250)
)

/// 解析指定色板+模式为 Color 集合
func resolvePalette(_ palette: ThemePalette, _ mode: Theme.AppearanceMode) -> ResolvedPalette {
    let raw: RawPalette
    switch (palette, mode) {
    case (.emerald, .dark): raw = emeraldDark
    case (.emerald, .light): raw = emeraldLight
    case (.ocean, .dark): raw = oceanDark
    case (.ocean, .light): raw = oceanLight
    case (.lilac, .dark): raw = lilacDark
    case (.lilac, .light): raw = lilacLight
    case (.sunset, .dark): raw = sunsetDark
    case (.sunset, .light): raw = sunsetLight
    case (.rose, .dark): raw = roseDark
    case (.rose, .light): raw = roseLight
    case (.teal, .dark): raw = tealDark
    case (.teal, .light): raw = tealLight
    case (.graphite, .dark): raw = graphiteDark
    case (.graphite, .light): raw = graphiteLight
    default: raw = emeraldDark
    }
    return ResolvedPalette(raw)
}

// MARK: - Theme 公共接口（保持向后兼容）

enum Theme {
    enum AppearanceMode: String, CaseIterable, Identifiable {
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .light: return "浅色"
            case .dark: return "深色"
            }
        }

        var swiftUIScheme: SwiftUI.ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    // MARK: - Colors（动态读取当前主题，调用点不变）
    enum Colors {
        static var p: ResolvedPalette { ThemeManager.shared.resolved }

        static var accent: Color { p.accent }
        static var accent2: Color { p.accent2 }
        static var accentDim: Color { p.accentDim }
        static var success: Color { p.success }
        static var warn: Color { p.warn }
        static var danger: Color { p.danger }

        static var primary: Color { p.accent }
        static var primaryDark: Color { p.accent2 }
        static var secondary: Color { p.fn }
        static var error: Color { p.danger }

        static var background: Color { p.bg }
        static var surface: Color { p.surface }
        static var surface2: Color { p.surface2 }
        static var surface3: Color { p.surface3 }
        static var surfaceElevated: Color { p.surface2 }

        static var textPrimary: Color { p.fg }
        static var textSecondary: Color { p.muted }
        static var textMuted: Color { p.muted2 }
        static var fg: Color { p.fg }
        static var muted: Color { p.muted }
        static var muted2: Color { p.muted2 }

        static var border: Color { p.border }
        static var border2: Color { p.border2 }

        static var tabBarBg: Color { p.tabBarBg }
        static var codeBg: Color { p.codeBg }
        static var terminalBackground: Color { p.codeBg }
        static var editorBackground: Color { p.codeBg }
        static var outputBackground: Color { p.codeBg }

        static var terminalPrompt: Color { p.success }

        static var codeKeyword: Color { p.key }
        static var codeFunction: Color { p.fn }
        static var codeString: Color { p.str }
        static var codeComment: Color { p.com }
        static var codeNumber: Color { p.num }
        static var codeClass: Color { p.bui }
        static var codeBuiltin: Color { p.bui }
        static var key: Color { p.key }
        static var fn: Color { p.fn }
        static var str: Color { p.str }
        static var com: Color { p.com }
        static var num: Color { p.num }
        static var bui: Color { p.bui }
        static var dec: Color { p.dec }

        static var lineNumbersBackground: Color { p.surface2 }
        static var lineNumbers: Color { p.muted2 }

        // 终端专用固定颜色（原型中始终深色，不随主题变）
        static var terminalBar: Color { OKLch(0.15, 0.01, 250).color }
        static var terminalKeysBar: Color { OKLch(0.14, 0.01, 250).color }
        static var terminalKeyBg: Color { OKLch(0.20, 0.015, 250).color }
        static var terminalKeyBorder: Color { OKLch(0.25, 0.01, 250).color }
        static var terminalText: Color { Color(red: 0.902, green: 0.929, blue: 0.953) } // #E6EDF3
        static var terminalOutput: Color { Color(red: 0.545, green: 0.576, blue: 0.620) } // #8B949E
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 18
        static let pill: CGFloat = 9999
        static let button: CGFloat = 10
        static let card: CGFloat = 14
    }

    // MARK: - Animation
    enum Animation {
        static let springEase: SwiftUI.Animation = .timingCurve(0.32, 0.94, 0.6, 1, duration: 0.25)
        static let sheet: SwiftUI.Animation = .timingCurve(0.32, 0.94, 0.6, 1, duration: 0.35)
        static let toast: SwiftUI.Animation = .timingCurve(0.33, 1, 0.68, 1, duration: 0.28)
    }

    // MARK: - Font
    enum Fonts {
        static let mono = "JetBrainsMono"
        static let regular = "SF Pro Display"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
