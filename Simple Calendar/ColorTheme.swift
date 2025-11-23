//
//  ColorTheme.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import Combine

struct ColorPalette {
    let name: String
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let border: Color
    let highlight: Color
    let gridLine: Color
    let eventColors: [Color] // Colors for different event types
    let icon: String

    // Computed properties for different UI elements
    var calendarBackground: Color { background }
    var calendarSurface: Color { surface }
    var selectedDay: Color { primary.opacity(0.2) }
    var todayHighlight: Color { accent.opacity(0.3) }
    var monthText: Color { primary }
    var yearText: Color { textSecondary }
    var dayNameText: Color { textSecondary }
    var buttonPrimary: Color { primary }
    var buttonSecondary: Color { secondary }

    // Event color variations
    var workEvent: Color { eventColors.count > 0 ? eventColors[0] : primary }
    var personalEvent: Color { eventColors.count > 1 ? eventColors[1] : secondary }
    var familyEvent: Color { eventColors.count > 2 ? eventColors[2] : accent }
    var otherEvent: Color { eventColors.count > 3 ? eventColors[3] : primary.opacity(0.7) }
}

enum ColorTheme: Int, CaseIterable, Identifiable {
    case ocean = 0
    case forest = 1
    case sunset = 2
    case space = 3
    case candy = 4
    case autumn = 5
    case winter = 6
    case rainbow = 7

    var id: Int { rawValue }

    var palette: ColorPalette {
        switch self {
        case .ocean:
            return ColorPalette(
                name: "Ocean",
                primary: Color(hex: "1E88E5"),      // Ocean blue
                secondary: Color(hex: "4FC3F7"),    // Light blue
                accent: Color(hex: "FFD54F"),      // Sandy yellow
                background: Color(hex: "E3F2FD"),   // Light blue background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "0D47A1"),  // Dark blue
                textSecondary: Color(hex: "546E7A"), // Blue grey
                border: Color(hex: "B3E5FC"),      // Light border
                highlight: Color(hex: "1E88E5"),   // Ocean blue highlight
                gridLine: Color(hex: "B3E5FC").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "0277BD"), // Deep blue
                    Color(hex: "00BCD4"), // Cyan
                    Color(hex: "4DD0E1"), // Light cyan
                    Color(hex: "B2EBF2")  // Very light cyan
                ],
                icon: "water.waves"
            )

        case .forest:
            return ColorPalette(
                name: "Forest",
                primary: Color(hex: "388E3C"),      // Forest green
                secondary: Color(hex: "66BB6A"),    // Light green
                accent: Color(hex: "FFD54F"),      // Sunshine yellow
                background: Color(hex: "E8F5E8"),   // Light green background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "1B5E20"),  // Dark green
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "C8E6C9"),      // Light green border
                highlight: Color(hex: "388E3C"),   // Forest green highlight
                gridLine: Color(hex: "C8E6C9").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "2E7D32"), // Deep green
                    Color(hex: "43A047"), // Medium green
                    Color(hex: "66BB6A"), // Light green
                    Color(hex: "A5D6A7")  // Pale green
                ],
                icon: "leaf.fill"
            )

        case .sunset:
            return ColorPalette(
                name: "Sunset",
                primary: Color(hex: "F4511E"),      // Orange red
                secondary: Color(hex: "FB8C00"),    // Orange
                accent: Color(hex: "FFD54F"),      // Yellow
                background: Color(hex: "FFF3E0"),   // Light orange background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "BF360C"),  // Dark red
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "FFCCBC"),      // Light orange border
                highlight: Color(hex: "F4511E"),   // Orange red highlight
                gridLine: Color(hex: "FFCCBC").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "D84315"), // Deep orange
                    Color(hex: "E65100"), // Orange
                    Color(hex: "EF6C00"), // Light orange
                    Color(hex: "F57C00")  // Pale orange
                ],
                icon: "sunset.fill"
            )

        case .space:
            return ColorPalette(
                name: "Space",
                primary: Color(hex: "5E35B1"),      // Deep purple
                secondary: Color(hex: "7C4DFF"),    // Purple
                accent: Color(hex: "FFD54F"),      // Star yellow
                background: Color(hex: "F3E5F5"),   // Light purple background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "311B92"),  // Dark purple
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "CE93D8"),      // Light purple border
                highlight: Color(hex: "5E35B1"),   // Deep purple highlight
                gridLine: Color(hex: "CE93D8").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "4527A0"), // Deep purple
                    Color(hex: "673AB7"), // Purple
                    Color(hex: "7C4DFF"), // Light purple
                    Color(hex: "B39DDB")  // Pale purple
                ],
                icon: "moon.stars.fill"
            )

        case .candy:
            return ColorPalette(
                name: "Candy",
                primary: Color(hex: "E91E63"),      // Pink
                secondary: Color(hex: "FF4081"),    // Light pink
                accent: Color(hex: "FFD54F"),      // Yellow
                background: Color(hex: "FCE4EC"),   // Light pink background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "880E4F"),  // Dark pink
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "F8BBD9"),      // Light pink border
                highlight: Color(hex: "E91E63"),   // Pink highlight
                gridLine: Color(hex: "F8BBD9").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "C2185B"), // Deep pink
                    Color(hex: "E91E63"), // Pink
                    Color(hex: "F06292"), // Light pink
                    Color(hex: "F8BBD9")  // Pale pink
                ],
                icon: "heart.fill"
            )

        case .autumn:
            return ColorPalette(
                name: "Autumn",
                primary: Color(hex: "E65100"),      // Orange
                secondary: Color(hex: "EF6C00"),     // Light orange
                accent: Color(hex: "FFD54F"),      // Yellow
                background: Color(hex: "FFF3E0"),   // Light orange background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "BF360C"),  // Dark orange
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "FFCCBC"),      // Light orange border
                highlight: Color(hex: "E65100"),   // Orange highlight
                gridLine: Color(hex: "FFCCBC").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "D84315"), // Deep orange
                    Color(hex: "E65100"), // Orange
                    Color(hex: "EF6C00"), // Light orange
                    Color(hex: "F57C00")  // Pale orange
                ],
                icon: "flame.fill"
            )

        case .winter:
            return ColorPalette(
                name: "Winter",
                primary: Color(hex: "1976D2"),      // Blue
                secondary: Color(hex: "42A5F5"),    // Light blue
                accent: Color(hex: "E3F2FD"),      // Very light blue
                background: Color(hex: "E3F2FD"),   // Light blue background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "0D47A1"),  // Dark blue
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "B3E5FC"),      // Light blue border
                highlight: Color(hex: "1976D2"),   // Blue highlight
                gridLine: Color(hex: "B3E5FC").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "0D47A1"), // Deep blue
                    Color(hex: "1976D2"), // Blue
                    Color(hex: "42A5F5"), // Light blue
                    Color(hex: "B3E5FC")  // Pale blue
                ],
                icon: "snowflake"
            )

        case .rainbow:
            return ColorPalette(
                name: "Rainbow",
                primary: Color(hex: "FF4081"),      // Pink
                secondary: Color(hex: "FF9800"),    // Orange
                accent: Color(hex: "FFD54F"),      // Yellow
                background: Color(hex: "FFFDE7"),   // Light yellow background
                surface: Color(hex: "FFFFFF"),     // White
                textPrimary: Color(hex: "F57C00"),  // Dark orange
                textSecondary: Color(hex: "546E7A"), // Grey
                border: Color(hex: "FFF9C4"),      // Light yellow border
                highlight: Color(hex: "FF4081"),   // Pink highlight
                gridLine: Color(hex: "FFF9C4").opacity(0.8), // Visible grid line
                eventColors: [
                    Color(hex: "E91E63"), // Pink
                    Color(hex: "FF9800"), // Orange
                    Color(hex: "FFEB3B"), // Yellow
                    Color(hex: "4CAF50")  // Green
                ],
                icon: "rainbow"
            )
        }
    }

    static var `default`: ColorTheme { .ocean }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: ColorTheme {
        didSet {
            saveTheme()
        }
    }

    private let themeKey = "selectedColorTheme"

    init() {
        let savedThemeRaw = UserDefaults.standard.integer(forKey: themeKey)
        self.currentTheme = ColorTheme(rawValue: savedThemeRaw) ?? .default
    }

    func setTheme(_ theme: ColorTheme) {
        currentTheme = theme
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.synchronize()
    }
}
