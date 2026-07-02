import SwiftUI

enum Theme {
    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色"
            case .dark: return "深色"
            }
        }

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }

        var swiftUIScheme: SwiftUI.ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    enum Colors {
        static let primary = Color(hex: "#6366F1")
        static let primaryDark = Color(hex: "#4F46E5")
        static let secondary = Color(hex: "#22D3EE")
        static let accent = Color(hex: "#F59E0B")
        static let success = Color(hex: "#10B981")
        static let error = Color(hex: "#EF4444")
        
        static let background = Color(hex: "#0F172A")
        static let surface = Color(hex: "#1E293B")
        static let surfaceElevated = Color(hex: "#334155")
        
        static let textPrimary = Color(hex: "#F8FAFC")
        static let textSecondary = Color(hex: "#94A3B8")
        static let textMuted = Color(hex: "#64748B")
        
        static let border = Color(hex: "#475569")
        
        static let codeKeyword = Color(hex: "#C678DD")
        static let codeFunction = Color(hex: "#61AFEF")
        static let codeString = Color(hex: "#98C379")
        static let codeComment = Color(hex: "#5C6370")
        static let codeNumber = Color(hex: "#D19A66")
        static let codeClass = Color(hex: "#E5C07B")
        static let codeBuiltin = Color(hex: "#56B6C2")
        
        static let terminalBackground = Color(hex: "#0D1117")
        static let terminalPrompt = Color(hex: "#58A6FF")
        
        static let editorBackground = Color(hex: "#1E1E1E")
        static let lineNumbersBackground = Color(hex: "#252526")
        static let lineNumbers = Color(hex: "#858585")
        static let outputBackground = Color(hex: "#1E1E1E")
    }
    
    enum Fonts {
        static let mono = "JetBrainsMono"
        static let regular = "SF Pro Display"
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
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