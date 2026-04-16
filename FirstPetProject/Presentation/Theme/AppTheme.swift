import SwiftUI

enum AppThemeMode: String {
    case dark
    case light

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

@Observable
final class AppSettings {
    var themeMode: AppThemeMode = .dark

    var isDarkMode: Bool {
        get { themeMode == .dark }
        set { themeMode = newValue ? .dark : .light }
    }

    var palette: AppPalette {
        AppPalette(mode: themeMode)
    }
}

struct AppPalette {
    let mode: AppThemeMode

    var background: Color { mode == .dark ? Color(hex: "0F0F13") : Color(hex: "F4F6FB") }
    var surface: Color { mode == .dark ? Color(hex: "14141E") : Color.white }
    var secondarySurface: Color { mode == .dark ? Color(hex: "1C1C28") : Color(hex: "E7EAF4") }
    var border: Color { mode == .dark ? Color(hex: "2A2A3A") : Color(hex: "D5DBE8") }

    var textPrimary: Color { mode == .dark ? Color(hex: "F5F5F0") : Color(hex: "1A1F2E") }
    var textSecondary: Color { mode == .dark ? Color(hex: "8B8B9A") : Color(hex: "5A647B") }
    var textMuted: Color { mode == .dark ? Color(hex: "5A5A70") : Color(hex: "6D7893") }

    var accentStart: Color { mode == .dark ? Color(hex: "7C6AF5") : Color(hex: "5D55E8") }
    var accentEnd: Color { mode == .dark ? Color(hex: "C56AF5") : Color(hex: "8B5DE8") }
    var accentSoft: Color { accentStart.opacity(mode == .dark ? 0.15 : 0.12) }
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
            (a, r, g, b) = (255, 0, 0, 0)
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
