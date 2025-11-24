//
//  ColorTheme.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import Combine
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
    case system = 8

    // Monthly themes (9-20)
    case january = 9
    case february = 10
    case march = 11
    case april = 12
    case may = 13
    case june = 14
    case july = 15
    case august = 16
    case september = 17
    case october = 18
    case november = 19
    case december = 20

    var id: Int { rawValue }

    func palette(for colorScheme: ColorScheme) -> ColorPalette {
        switch self {
        case .ocean:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Ocean",
                    primary: Color(hex: "4FC3F7"),      // Light blue (more visible in dark)
                    secondary: Color(hex: "81D4FA"),    // Lighter blue
                    accent: Color(hex: "FFD54F"),      // Sandy yellow (same for contrast)
                    background: Color(hex: "0D47A1"),   // Dark blue background
                    surface: Color(hex: "1E3A5F"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "B3E5FC"), // Light blue text
                    border: Color(hex: "4FC3F7"),      // Blue border
                    highlight: Color(hex: "4FC3F7"),   // Light blue highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "4FC3F7"), // Light blue
                        Color(hex: "81D4FA"), // Lighter blue
                        Color(hex: "B3E5FC"), // Very light blue
                        Color(hex: "E1F5FE")  // Pale blue
                    ],
                    icon: "water.waves"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "0277BD"), // Deep blue
                        Color(hex: "00BCD4"), // Cyan
                        Color(hex: "4DD0E1"), // Light cyan
                        Color(hex: "B2EBF2")  // Very light cyan
                    ],
                    icon: "water.waves"
                )
            }

        case .forest:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Forest",
                    primary: Color(hex: "66BB6A"),      // Light green (more visible in dark)
                    secondary: Color(hex: "81C784"),    // Lighter green
                    accent: Color(hex: "FFD54F"),      // Sunshine yellow (same for contrast)
                    background: Color(hex: "1B5E20"),   // Dark green background
                    surface: Color(hex: "2E4D33"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "C8E6C9"), // Light green text
                    border: Color(hex: "66BB6A"),      // Green border
                    highlight: Color(hex: "66BB6A"),   // Light green highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "66BB6A"), // Light green
                        Color(hex: "81C784"), // Lighter green
                        Color(hex: "A5D6A7"), // Pale green
                        Color(hex: "C8E6C9")  // Very pale green
                    ],
                    icon: "leaf.fill"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "2E7D32"), // Deep green
                        Color(hex: "43A047"), // Medium green
                        Color(hex: "66BB6A"), // Light green
                        Color(hex: "A5D6A7")  // Pale green
                    ],
                    icon: "leaf.fill"
                )
            }

        case .sunset:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Sunset",
                    primary: Color(hex: "FB8C00"),      // Orange (more visible in dark)
                    secondary: Color(hex: "FF9800"),    // Lighter orange
                    accent: Color(hex: "FFD54F"),      // Yellow (same for contrast)
                    background: Color(hex: "BF360C"),   // Dark red background
                    surface: Color(hex: "D84315"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "FFCCBC"), // Light orange text
                    border: Color(hex: "FB8C00"),      // Orange border
                    highlight: Color(hex: "FB8C00"),   // Orange highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "FB8C00"), // Orange
                        Color(hex: "FF9800"), // Lighter orange
                        Color(hex: "FFCCBC"), // Pale orange
                        Color(hex: "FFF3E0")  // Very pale orange
                    ],
                    icon: "sunset.fill"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "D84315"), // Deep orange
                        Color(hex: "E65100"), // Orange
                        Color(hex: "EF6C00"), // Light orange
                        Color(hex: "F57C00")  // Pale orange
                    ],
                    icon: "sunset.fill"
                )
            }

        case .space:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Space",
                    primary: Color(hex: "7C4DFF"),      // Light purple (more visible in dark)
                    secondary: Color(hex: "9575CD"),    // Lighter purple
                    accent: Color(hex: "FFD54F"),      // Star yellow (same for contrast)
                    background: Color(hex: "311B92"),   // Dark purple background
                    surface: Color(hex: "4527A0"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "CE93D8"), // Light purple text
                    border: Color(hex: "7C4DFF"),      // Purple border
                    highlight: Color(hex: "7C4DFF"),   // Light purple highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "7C4DFF"), // Light purple
                        Color(hex: "9575CD"), // Lighter purple
                        Color(hex: "B39DDB"), // Pale purple
                        Color(hex: "E1BEE7")  // Very pale purple
                    ],
                    icon: "moon.stars.fill"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "4527A0"), // Deep purple
                        Color(hex: "673AB7"), // Purple
                        Color(hex: "7C4DFF"), // Light purple
                        Color(hex: "B39DDB")  // Pale purple
                    ],
                    icon: "moon.stars.fill"
                )
            }

        case .candy:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Candy",
                    primary: Color(hex: "FF4081"),      // Light pink (more visible in dark)
                    secondary: Color(hex: "F48FB1"),    // Lighter pink
                    accent: Color(hex: "FFD54F"),      // Yellow (same for contrast)
                    background: Color(hex: "880E4F"),   // Dark pink background
                    surface: Color(hex: "C2185B"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "F8BBD9"), // Light pink text
                    border: Color(hex: "FF4081"),      // Pink border
                    highlight: Color(hex: "FF4081"),   // Light pink highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "FF4081"), // Light pink
                        Color(hex: "F48FB1"), // Lighter pink
                        Color(hex: "F8BBD9"), // Pale pink
                        Color(hex: "FCE4EC")  // Very pale pink
                    ],
                    icon: "heart.fill"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "C2185B"), // Deep pink
                        Color(hex: "E91E63"), // Pink
                        Color(hex: "F06292"), // Light pink
                        Color(hex: "F8BBD9")  // Pale pink
                    ],
                    icon: "heart.fill"
                )
            }

        case .autumn:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Autumn",
                    primary: Color(hex: "EF6C00"),      // Light orange (more visible in dark)
                    secondary: Color(hex: "F57C00"),    // Lighter orange
                    accent: Color(hex: "FFD54F"),      // Yellow (same for contrast)
                    background: Color(hex: "BF360C"),   // Dark orange background
                    surface: Color(hex: "D84315"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "FFCCBC"), // Light orange text
                    border: Color(hex: "EF6C00"),      // Orange border
                    highlight: Color(hex: "EF6C00"),   // Light orange highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "EF6C00"), // Light orange
                        Color(hex: "F57C00"), // Lighter orange
                        Color(hex: "FFCCBC"), // Pale orange
                        Color(hex: "FFF3E0")  // Very pale orange
                    ],
                    icon: "flame.fill"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "D84315"), // Deep orange
                        Color(hex: "E65100"), // Orange
                        Color(hex: "EF6C00"), // Light orange
                        Color(hex: "F57C00")  // Pale orange
                    ],
                    icon: "flame.fill"
                )
            }

        case .winter:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Winter",
                    primary: Color(hex: "42A5F5"),      // Light blue (more visible in dark)
                    secondary: Color(hex: "64B5F6"),    // Lighter blue
                    accent: Color(hex: "E3F2FD"),      // Very light blue (same for contrast)
                    background: Color(hex: "0D47A1"),   // Dark blue background
                    surface: Color(hex: "1976D2"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "B3E5FC"), // Light blue text
                    border: Color(hex: "42A5F5"),      // Blue border
                    highlight: Color(hex: "42A5F5"),   // Light blue highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "42A5F5"), // Light blue
                        Color(hex: "64B5F6"), // Lighter blue
                        Color(hex: "B3E5FC"), // Pale blue
                        Color(hex: "E3F2FD")  // Very pale blue
                    ],
                    icon: "snowflake"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "0D47A1"), // Deep blue
                        Color(hex: "1976D2"), // Blue
                        Color(hex: "42A5F5"), // Light blue
                        Color(hex: "B3E5FC")  // Pale blue
                    ],
                    icon: "snowflake"
                )
            }

        case .rainbow:
            if colorScheme == .dark {
                return ColorPalette(
                    name: "Rainbow",
                    primary: Color(hex: "FF6B9D"),      // Light pink (more visible in dark)
                    secondary: Color(hex: "FFB74D"),    // Light orange
                    accent: Color(hex: "FFD54F"),      // Yellow (same for contrast)
                    background: Color(hex: "F57C00"),   // Dark orange background
                    surface: Color(hex: "E65100"),     // Dark surface
                    textPrimary: Color(hex: "FFFFFF"),  // White text
                    textSecondary: Color(hex: "FFF9C4"), // Light yellow text
                    border: Color(hex: "FF6B9D"),      // Pink border
                    highlight: Color(hex: "FF6B9D"),   // Light pink highlight
                    gridLine: Color.white.opacity(0.9), // Pure white for maximum contrast on dark backgrounds
                    eventColors: [
                        Color(hex: "FF6B9D"), // Light pink
                        Color(hex: "FFB74D"), // Light orange
                        Color(hex: "FFF176"), // Light yellow
                        Color(hex: "81C784")  // Light green
                    ],
                    icon: "rainbow"
                )
            } else {
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
                    gridLine: Color.black.opacity(0.9), // Pure black for maximum contrast on light backgrounds
                    eventColors: [
                        Color(hex: "E91E63"), // Pink
                        Color(hex: "FF9800"), // Orange
                        Color(hex: "FFEB3B"), // Yellow
                        Color(hex: "4CAF50")  // Green
                    ],
                    icon: "rainbow"
                )
            }
        case .system:
            // System theme that uses appropriate colors for the current color scheme
            if colorScheme == .dark {
                #if os(macOS)
                return ColorPalette(
                    name: "System",
                    primary: Color(NSColor.systemBlue),
                    secondary: Color(NSColor.systemGray),
                    accent: Color(NSColor.systemOrange),
                    background: Color(NSColor.windowBackgroundColor),
                    surface: Color(NSColor.controlBackgroundColor),
                    textPrimary: Color(NSColor.labelColor),
                    textSecondary: Color(NSColor.secondaryLabelColor),
                    border: Color(NSColor.separatorColor),
                    highlight: Color(NSColor.systemBlue),
                    gridLine: Color(NSColor.separatorColor).opacity(0.6),
                    eventColors: [
                        Color(NSColor.systemBlue),
                        Color(NSColor.systemGreen),
                        Color(NSColor.systemOrange),
                        Color(NSColor.systemPurple)
                    ],
                    icon: "circle.grid.3x3"
                )
                #else
                return ColorPalette(
                    name: "System",
                    primary: Color(UIColor.systemBlue),
                    secondary: Color(UIColor.systemGray),
                    accent: Color(UIColor.systemOrange),
                    background: Color(UIColor.systemBackground),
                    surface: Color(UIColor.secondarySystemBackground),
                    textPrimary: Color(UIColor.label),
                    textSecondary: Color(UIColor.secondaryLabel),
                    border: Color(UIColor.separator),
                    highlight: Color(UIColor.systemBlue),
                    gridLine: Color(UIColor.separator).opacity(0.6),
                    eventColors: [
                        Color(UIColor.systemBlue),
                        Color(UIColor.systemGreen),
                        Color(UIColor.systemOrange),
                        Color(UIColor.systemPurple)
                    ],
                    icon: "circle.grid.3x3"
                )
                #endif
            } else {
                #if os(macOS)
                return ColorPalette(
                    name: "System",
                    primary: Color(NSColor.systemBlue),
                    secondary: Color(NSColor.systemGray),
                    accent: Color(NSColor.systemOrange),
                    background: Color(NSColor.windowBackgroundColor),
                    surface: Color(NSColor.controlBackgroundColor),
                    textPrimary: Color(NSColor.labelColor),
                    textSecondary: Color(NSColor.secondaryLabelColor),
                    border: Color(NSColor.separatorColor),
                    highlight: Color(NSColor.systemBlue),
                    gridLine: Color(NSColor.separatorColor).opacity(0.5),
                    eventColors: [
                        Color(NSColor.systemBlue),
                        Color(NSColor.systemGreen),
                        Color(NSColor.systemOrange),
                        Color(NSColor.systemPurple)
                    ],
                    icon: "circle.grid.3x3"
                )
                #else
                return ColorPalette(
                    name: "System",
                    primary: Color(UIColor.systemBlue),
                    secondary: Color(UIColor.systemGray),
                    accent: Color(UIColor.systemOrange),
                    background: Color(UIColor.systemBackground),
                    surface: Color(UIColor.secondarySystemBackground),
                    textPrimary: Color(UIColor.label),
                    textSecondary: Color(UIColor.secondaryLabel),
                    border: Color(UIColor.separator),
                    highlight: Color(UIColor.systemBlue),
                    gridLine: Color(UIColor.separator).opacity(0.5),
                    eventColors: [
                        Color(UIColor.systemBlue),
                        Color(UIColor.systemGreen),
                        Color(UIColor.systemOrange),
                        Color(UIColor.systemPurple)
                    ],
                    icon: "circle.grid.3x3"
                )
                #endif
            }

        case .january:
            // Winter theme - cool blues and whites
            if colorScheme == .dark {
                return ColorPalette(
                    name: "January",
                    primary: Color(hex: "42A5F5"),      // Light blue
                    secondary: Color(hex: "64B5F6"),    // Lighter blue
                    accent: Color(hex: "E3F2FD"),      // Very light blue
                    background: Color(hex: "0D47A1"),   // Dark blue
                    surface: Color(hex: "1976D2"),     // Medium blue
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "B3E5FC"), // Light blue
                    border: Color(hex: "42A5F5"),      // Blue border
                    highlight: Color(hex: "42A5F5"),   // Light blue
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "42A5F5"), // Light blue
                        Color(hex: "64B5F6"), // Lighter blue
                        Color(hex: "B3E5FC"), // Pale blue
                        Color(hex: "E3F2FD")  // Very pale blue
                    ],
                    icon: "snowflake"
                )
            } else {
                return ColorPalette(
                    name: "January",
                    primary: Color(hex: "1976D2"),      // Blue
                    secondary: Color(hex: "42A5F5"),    // Light blue
                    accent: Color(hex: "E3F2FD"),      // Very light blue
                    background: Color(hex: "E3F2FD"),   // Light blue background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "0D47A1"),  // Dark blue
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "B3E5FC"),      // Light blue border
                    highlight: Color(hex: "1976D2"),   // Blue
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "0D47A1"), // Deep blue
                        Color(hex: "1976D2"), // Blue
                        Color(hex: "42A5F5"), // Light blue
                        Color(hex: "B3E5FC")  // Pale blue
                    ],
                    icon: "snowflake"
                )
            }

        case .february:
            // Valentine's theme - reds and pinks
            if colorScheme == .dark {
                return ColorPalette(
                    name: "February",
                    primary: Color(hex: "E91E63"),      // Pink
                    secondary: Color(hex: "F48FB1"),    // Light pink
                    accent: Color(hex: "FCE4EC"),      // Very light pink
                    background: Color(hex: "880E4F"),   // Dark pink
                    surface: Color(hex: "C2185B"),     // Medium pink
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "F8BBD9"), // Light pink
                    border: Color(hex: "E91E63"),      // Pink border
                    highlight: Color(hex: "E91E63"),   // Pink
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "E91E63"), // Pink
                        Color(hex: "F48FB1"), // Light pink
                        Color(hex: "F8BBD9"), // Pale pink
                        Color(hex: "FCE4EC")  // Very pale pink
                    ],
                    icon: "heart.fill"
                )
            } else {
                return ColorPalette(
                    name: "February",
                    primary: Color(hex: "C2185B"),      // Deep pink
                    secondary: Color(hex: "E91E63"),    // Pink
                    accent: Color(hex: "FCE4EC"),      // Very light pink
                    background: Color(hex: "FCE4EC"),   // Light pink background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "880E4F"),  // Dark pink
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "F8BBD9"),      // Light pink border
                    highlight: Color(hex: "C2185B"),   // Deep pink
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "880E4F"), // Deep pink
                        Color(hex: "C2185B"), // Pink
                        Color(hex: "E91E63"), // Light pink
                        Color(hex: "F8BBD9")  // Pale pink
                    ],
                    icon: "heart.fill"
                )
            }

        case .march:
            // Spring theme - greens and yellows
            if colorScheme == .dark {
                return ColorPalette(
                    name: "March",
                    primary: Color(hex: "66BB6A"),      // Light green
                    secondary: Color(hex: "81C784"),    // Lighter green
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "1B5E20"),   // Dark green
                    surface: Color(hex: "2E4D33"),     // Medium green
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "C8E6C9"), // Light green
                    border: Color(hex: "66BB6A"),      // Green border
                    highlight: Color(hex: "66BB6A"),   // Light green
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "66BB6A"), // Light green
                        Color(hex: "81C784"), // Lighter green
                        Color(hex: "C8E6C9"), // Pale green
                        Color(hex: "E8F5E8")  // Very pale green
                    ],
                    icon: "leaf.fill"
                )
            } else {
                return ColorPalette(
                    name: "March",
                    primary: Color(hex: "388E3C"),      // Green
                    secondary: Color(hex: "66BB6A"),    // Light green
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "E8F5E8"),   // Light green background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "1B5E20"),  // Dark green
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "C8E6C9"),      // Light green border
                    highlight: Color(hex: "388E3C"),   // Green
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "2E7D32"), // Deep green
                        Color(hex: "388E3C"), // Green
                        Color(hex: "66BB6A"), // Light green
                        Color(hex: "C8E6C9")  // Pale green
                    ],
                    icon: "leaf.fill"
                )
            }

        case .april:
            // April showers theme - blues and purples
            if colorScheme == .dark {
                return ColorPalette(
                    name: "April",
                    primary: Color(hex: "7C4DFF"),      // Purple
                    secondary: Color(hex: "9575CD"),    // Light purple
                    accent: Color(hex: "E1BEE7"),      // Pale purple
                    background: Color(hex: "311B92"),   // Dark purple
                    surface: Color(hex: "4527A0"),     // Medium purple
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "CE93D8"), // Light purple
                    border: Color(hex: "7C4DFF"),      // Purple border
                    highlight: Color(hex: "7C4DFF"),   // Purple
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "7C4DFF"), // Purple
                        Color(hex: "9575CD"), // Light purple
                        Color(hex: "CE93D8"), // Pale purple
                        Color(hex: "F3E5F5")  // Very pale purple
                    ],
                    icon: "cloud.rain.fill"
                )
            } else {
                return ColorPalette(
                    name: "April",
                    primary: Color(hex: "5E35B1"),      // Deep purple
                    secondary: Color(hex: "7C4DFF"),    // Purple
                    accent: Color(hex: "E1BEE7"),      // Pale purple
                    background: Color(hex: "F3E5F5"),   // Light purple background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "311B92"),  // Dark purple
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "CE93D8"),      // Light purple border
                    highlight: Color(hex: "5E35B1"),   // Deep purple
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "4527A0"), // Deep purple
                        Color(hex: "5E35B1"), // Purple
                        Color(hex: "7C4DFF"), // Light purple
                        Color(hex: "CE93D8")  // Pale purple
                    ],
                    icon: "cloud.rain.fill"
                )
            }

        case .may:
            // May flowers theme - bright greens and yellows
            if colorScheme == .dark {
                return ColorPalette(
                    name: "May",
                    primary: Color(hex: "4CAF50"),      // Green
                    secondary: Color(hex: "66BB6A"),    // Light green
                    accent: Color(hex: "FFF176"),      // Yellow
                    background: Color(hex: "1B5E20"),   // Dark green
                    surface: Color(hex: "2E4D33"),     // Medium green
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "C8E6C9"), // Light green
                    border: Color(hex: "4CAF50"),      // Green border
                    highlight: Color(hex: "4CAF50"),   // Green
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "4CAF50"), // Green
                        Color(hex: "66BB6A"), // Light green
                        Color(hex: "C8E6C9"), // Pale green
                        Color(hex: "E8F5E8")  // Very pale green
                    ],
                    icon: "camera.macro"
                )
            } else {
                return ColorPalette(
                    name: "May",
                    primary: Color(hex: "2E7D32"),      // Deep green
                    secondary: Color(hex: "4CAF50"),    // Green
                    accent: Color(hex: "FFF176"),      // Yellow
                    background: Color(hex: "E8F5E8"),   // Light green background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "1B5E20"),  // Dark green
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "C8E6C9"),      // Light green border
                    highlight: Color(hex: "2E7D32"),   // Deep green
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "1B5E20"), // Deep green
                        Color(hex: "2E7D32"), // Green
                        Color(hex: "4CAF50"), // Light green
                        Color(hex: "C8E6C9")  // Pale green
                    ],
                    icon: "camera.macro"
                )
            }

        case .june:
            // Summer theme - bright blues and yellows
            if colorScheme == .dark {
                return ColorPalette(
                    name: "June",
                    primary: Color(hex: "2196F3"),      // Blue
                    secondary: Color(hex: "42A5F5"),    // Light blue
                    accent: Color(hex: "FFF176"),      // Yellow
                    background: Color(hex: "0D47A1"),   // Dark blue
                    surface: Color(hex: "1976D2"),     // Medium blue
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "B3E5FC"), // Light blue
                    border: Color(hex: "2196F3"),      // Blue border
                    highlight: Color(hex: "2196F3"),   // Blue
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "2196F3"), // Blue
                        Color(hex: "42A5F5"), // Light blue
                        Color(hex: "B3E5FC"), // Pale blue
                        Color(hex: "E3F2FD")  // Very pale blue
                    ],
                    icon: "sun.max.fill"
                )
            } else {
                return ColorPalette(
                    name: "June",
                    primary: Color(hex: "1565C0"),      // Deep blue
                    secondary: Color(hex: "2196F3"),    // Blue
                    accent: Color(hex: "FFF176"),      // Yellow
                    background: Color(hex: "E3F2FD"),   // Light blue background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "0D47A1"),  // Dark blue
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "B3E5FC"),      // Light blue border
                    highlight: Color(hex: "1565C0"),   // Deep blue
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "0D47A1"), // Deep blue
                        Color(hex: "1565C0"), // Blue
                        Color(hex: "2196F3"), // Light blue
                        Color(hex: "B3E5FC")  // Pale blue
                    ],
                    icon: "sun.max.fill"
                )
            }

        case .july:
            // Independence theme - reds, whites, blues
            if colorScheme == .dark {
                return ColorPalette(
                    name: "July",
                    primary: Color(hex: "F44336"),      // Red
                    secondary: Color(hex: "42A5F5"),    // Blue
                    accent: Color(hex: "FFFFFF"),      // White
                    background: Color(hex: "B71C1C"),   // Dark red
                    surface: Color(hex: "D32F2F"),     // Medium red
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "FFCDD2"), // Light red
                    border: Color(hex: "F44336"),      // Red border
                    highlight: Color(hex: "F44336"),   // Red
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "F44336"), // Red
                        Color(hex: "42A5F5"), // Blue
                        Color(hex: "FFFFFF"), // White
                        Color(hex: "FFCDD2")  // Light red
                    ],
                    icon: "star.fill"
                )
            } else {
                return ColorPalette(
                    name: "July",
                    primary: Color(hex: "D32F2F"),      // Deep red
                    secondary: Color(hex: "1976D2"),    // Blue
                    accent: Color(hex: "FFFFFF"),      // White
                    background: Color(hex: "FFEBEE"),   // Light red background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "B71C1C"),  // Dark red
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "FFCDD2"),      // Light red border
                    highlight: Color(hex: "D32F2F"),   // Deep red
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "B71C1C"), // Deep red
                        Color(hex: "D32F2F"), // Red
                        Color(hex: "1976D2"), // Blue
                        Color(hex: "FFFFFF")  // White
                    ],
                    icon: "star.fill"
                )
            }

        case .august:
            // Beach theme - sandy yellows and ocean blues
            if colorScheme == .dark {
                return ColorPalette(
                    name: "August",
                    primary: Color(hex: "FFB74D"),      // Orange
                    secondary: Color(hex: "4FC3F7"),    // Light blue
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "E65100"),   // Dark orange
                    surface: Color(hex: "EF6C00"),     // Medium orange
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "FFE0B2"), // Light orange
                    border: Color(hex: "FFB74D"),      // Orange border
                    highlight: Color(hex: "FFB74D"),   // Orange
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "FFB74D"), // Orange
                        Color(hex: "4FC3F7"), // Light blue
                        Color(hex: "FFF9C4"), // Light yellow
                        Color(hex: "FFE0B2")  // Light orange
                    ],
                    icon: "beach.umbrella.fill"
                )
            } else {
                return ColorPalette(
                    name: "August",
                    primary: Color(hex: "EF6C00"),      // Deep orange
                    secondary: Color(hex: "FF9800"),    // Orange
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "FFF3E0"),   // Light orange background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "E65100"),  // Dark orange
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "FFE0B2"),      // Light orange border
                    highlight: Color(hex: "EF6C00"),   // Deep orange
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "E65100"), // Deep orange
                        Color(hex: "EF6C00"), // Orange
                        Color(hex: "FF9800"), // Light orange
                        Color(hex: "FFE0B2")  // Pale orange
                    ],
                    icon: "beach.umbrella.fill"
                )
            }

        case .september:
            // Back to school theme - academic colors
            if colorScheme == .dark {
                return ColorPalette(
                    name: "September",
                    primary: Color(hex: "3F51B5"),      // Indigo
                    secondary: Color(hex: "7986CB"),    // Light indigo
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "1A237E"),   // Dark indigo
                    surface: Color(hex: "283593"),     // Medium indigo
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "C5CAE9"), // Light indigo
                    border: Color(hex: "3F51B5"),      // Indigo border
                    highlight: Color(hex: "3F51B5"),   // Indigo
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "3F51B5"), // Indigo
                        Color(hex: "7986CB"), // Light indigo
                        Color(hex: "C5CAE9"), // Pale indigo
                        Color(hex: "E8EAF6")  // Very pale indigo
                    ],
                    icon: "book.fill"
                )
            } else {
                return ColorPalette(
                    name: "September",
                    primary: Color(hex: "283593"),      // Deep indigo
                    secondary: Color(hex: "3F51B5"),    // Indigo
                    accent: Color(hex: "FFF9C4"),      // Light yellow
                    background: Color(hex: "E8EAF6"),   // Light indigo background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "1A237E"),  // Dark indigo
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "C5CAE9"),      // Light indigo border
                    highlight: Color(hex: "283593"),   // Deep indigo
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "1A237E"), // Deep indigo
                        Color(hex: "283593"), // Indigo
                        Color(hex: "3F51B5"), // Light indigo
                        Color(hex: "C5CAE9")  // Pale indigo
                    ],
                    icon: "book.fill"
                )
            }

        case .october:
            // Halloween theme - oranges and purples
            if colorScheme == .dark {
                return ColorPalette(
                    name: "October",
                    primary: Color(hex: "FF5722"),      // Deep orange
                    secondary: Color(hex: "9C27B0"),    // Purple
                    accent: Color(hex: "FFEB3B"),      // Yellow
                    background: Color(hex: "BF360C"),   // Dark orange
                    surface: Color(hex: "D84315"),     // Medium orange
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "FFCCBC"), // Light orange
                    border: Color(hex: "FF5722"),      // Deep orange border
                    highlight: Color(hex: "FF5722"),   // Deep orange
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "FF5722"), // Deep orange
                        Color(hex: "9C27B0"), // Purple
                        Color(hex: "FFEB3B"), // Yellow
                        Color(hex: "FFCCBC")  // Light orange
                    ],
                    icon: "moon.stars.fill"
                )
            } else {
                return ColorPalette(
                    name: "October",
                    primary: Color(hex: "D84315"),      // Orange
                    secondary: Color(hex: "7B1FA2"),    // Deep purple
                    accent: Color(hex: "FFEB3B"),      // Yellow
                    background: Color(hex: "FFF3E0"),   // Light orange background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "BF360C"),  // Dark orange
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "FFCCBC"),      // Light orange border
                    highlight: Color(hex: "D84315"),   // Orange
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "BF360C"), // Deep orange
                        Color(hex: "D84315"), // Orange
                        Color(hex: "7B1FA2"), // Deep purple
                        Color(hex: "FFCCBC")  // Light orange
                    ],
                    icon: "moon.stars.fill"
                )
            }

        case .november:
            // Thanksgiving theme - warm browns and oranges
            if colorScheme == .dark {
                return ColorPalette(
                    name: "November",
                    primary: Color(hex: "8D6E63"),      // Brown
                    secondary: Color(hex: "A1887F"),    // Light brown
                    accent: Color(hex: "FF8A65"),      // Orange
                    background: Color(hex: "3E2723"),   // Dark brown
                    surface: Color(hex: "4E342E"),     // Medium brown
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "D7CCC8"), // Light brown
                    border: Color(hex: "8D6E63"),      // Brown border
                    highlight: Color(hex: "8D6E63"),   // Brown
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "8D6E63"), // Brown
                        Color(hex: "A1887F"), // Light brown
                        Color(hex: "FF8A65"), // Orange
                        Color(hex: "D7CCC8")  // Light brown
                    ],
                    icon: "leaf.fill"
                )
            } else {
                return ColorPalette(
                    name: "November",
                    primary: Color(hex: "5D4037"),      // Deep brown
                    secondary: Color(hex: "8D6E63"),    // Brown
                    accent: Color(hex: "FF8A65"),      // Orange
                    background: Color(hex: "EFEBE9"),   // Light brown background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "3E2723"),  // Dark brown
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "D7CCC8"),      // Light brown border
                    highlight: Color(hex: "5D4037"),   // Deep brown
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "3E2723"), // Deep brown
                        Color(hex: "5D4037"), // Brown
                        Color(hex: "8D6E63"), // Light brown
                        Color(hex: "D7CCC8")  // Pale brown
                    ],
                    icon: "leaf.fill"
                )
            }

        case .december:
            // Holiday theme - reds and greens
            if colorScheme == .dark {
                return ColorPalette(
                    name: "December",
                    primary: Color(hex: "E53935"),      // Red
                    secondary: Color(hex: "43A047"),    // Green
                    accent: Color(hex: "FFD54F"),      // Gold
                    background: Color(hex: "B71C1C"),   // Dark red
                    surface: Color(hex: "C62828"),     // Medium red
                    textPrimary: Color(hex: "FFFFFF"),  // White
                    textSecondary: Color(hex: "EF9A9A"), // Light red
                    border: Color(hex: "E53935"),      // Red border
                    highlight: Color(hex: "E53935"),   // Red
                    gridLine: Color.white.opacity(0.9),
                    eventColors: [
                        Color(hex: "E53935"), // Red
                        Color(hex: "43A047"), // Green
                        Color(hex: "FFD54F"), // Gold
                        Color(hex: "EF9A9A")  // Light red
                    ],
                    icon: "star.fill"
                )
            } else {
                return ColorPalette(
                    name: "December",
                    primary: Color(hex: "C62828"),      // Deep red
                    secondary: Color(hex: "2E7D32"),    // Green
                    accent: Color(hex: "FFD54F"),      // Gold
                    background: Color(hex: "FFEBEE"),   // Light red background
                    surface: Color(hex: "FFFFFF"),     // White
                    textPrimary: Color(hex: "B71C1C"),  // Dark red
                    textSecondary: Color(hex: "546E7A"), // Grey
                    border: Color(hex: "EF9A9A"),      // Light red border
                    highlight: Color(hex: "C62828"),   // Deep red
                    gridLine: Color.black.opacity(0.9),
                    eventColors: [
                        Color(hex: "B71C1C"), // Deep red
                        Color(hex: "C62828"), // Red
                        Color(hex: "2E7D32"), // Green
                        Color(hex: "EF9A9A")  // Light red
                    ],
                    icon: "star.fill"
                )
            }
        }
    }

    static var `default`: ColorTheme { .ocean }
}

// MARK: - Monthly Theme Manager
class MonthlyThemeManager: ObservableObject {
    static let shared = MonthlyThemeManager()

    @Published var monthlyThemes: [Int: ColorTheme] = [:] {
        didSet { saveMonthlyThemes() }
    }

    @Published var monthlyFonts: [Int: String] = [:] {
        didSet { saveMonthlyFonts() }
    }

    private let monthlyThemesKey = "monthlyThemes"
    private let monthlyFontsKey = "monthlyFonts"

    private init() {
        loadMonthlyThemes()
        loadMonthlyFonts()
    }

    func theme(for month: Int) -> ColorTheme {
        return monthlyThemes[month] ?? .ocean
    }

    func setTheme(_ theme: ColorTheme, for month: Int) {
        monthlyThemes[month] = theme
    }

    func font(for month: Int) -> String {
        return monthlyFonts[month] ?? "Arial"
    }

    func setFont(_ font: String, for month: Int) {
        monthlyFonts[month] = font
    }

    private func loadMonthlyThemes() {
        if let data = UserDefaults.standard.dictionary(forKey: monthlyThemesKey) as? [String: Int] {
            for (monthStr, themeRaw) in data {
                if let month = Int(monthStr), let theme = ColorTheme(rawValue: themeRaw) {
                    monthlyThemes[month] = theme
                }
            }
        }
    }

    private func loadMonthlyFonts() {
        if let data = UserDefaults.standard.dictionary(forKey: monthlyFontsKey) as? [String: String] {
            for (monthStr, font) in data {
                if let month = Int(monthStr) {
                    monthlyFonts[month] = font
                }
            }
        }
    }

    private func saveMonthlyThemes() {
        var data: [String: Int] = [:]
        for (month, theme) in monthlyThemes {
            data[String(month)] = theme.rawValue
        }
        UserDefaults.standard.set(data, forKey: monthlyThemesKey)
        UserDefaults.standard.synchronize()
    }

    private func saveMonthlyFonts() {
        var data: [String: String] = [:]
        for (month, font) in monthlyFonts {
            data[String(month)] = font
        }
        UserDefaults.standard.set(data, forKey: monthlyFontsKey)
        UserDefaults.standard.synchronize()
    }

    func resetToDefaults() {
        monthlyThemes.removeAll()
        monthlyFonts.removeAll()
        saveMonthlyThemes()
        saveMonthlyFonts()
    }

    /// Get available fonts for monthly selection
    static let availableFonts = [
        "Arial",
        "Helvetica",
        "Times New Roman",
        "Courier",
        "Georgia",
        "Verdana",
        "Trebuchet MS",
        "Impact",
        "Comic Sans MS",
        "Lucida Grande",
        "Futura",
        "Baskerville"
    ]
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

    // Get palette for a specific color scheme
    func palette(for colorScheme: ColorScheme) -> ColorPalette {
        currentTheme.palette(for: colorScheme)
    }

    // Convenience property for current system color scheme (set by views)
    private var _currentColorScheme: ColorScheme = .light
    var currentColorScheme: ColorScheme {
        get { _currentColorScheme }
        set {
            if _currentColorScheme != newValue {
                _currentColorScheme = newValue
                // Trigger UI updates when color scheme changes
                objectWillChange.send()
            }
        }
    }

    // Computed property that returns the appropriate palette based on current color scheme
    var currentPalette: ColorPalette {
        currentTheme.palette(for: currentColorScheme)
    }

    private let themeKey = "selectedColorTheme"

    init() {
        let savedThemeRaw = UserDefaults.standard.integer(forKey: themeKey)
        self.currentTheme = ColorTheme(rawValue: savedThemeRaw) ?? .default

        // Default to light mode - users can restart app to see correct theme
        // TODO: Implement proper system color scheme detection
        self.currentColorScheme = .light
    }

    func setTheme(_ theme: ColorTheme) {
        currentTheme = theme
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.synchronize()
    }
}
