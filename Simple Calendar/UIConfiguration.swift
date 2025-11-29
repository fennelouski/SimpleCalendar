//
//  UIConfiguration.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import Combine

/// Font size categories for consistent typography
enum FontSizeCategory: Int, CaseIterable, Identifiable {
    case extraSmall = -2
    case small = -1
    case normal = 0
    case large = 1
    case extraLarge = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .normal: return "Normal"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var scaleFactor: CGFloat {
        #if os(tvOS)
        // tvOS needs larger scaling for viewing from distance
        switch self {
        case .extraSmall: return 1.0
        case .small: return 1.1
        case .normal: return 1.3
        case .large: return 1.5
        case .extraLarge: return 1.8
        }
        #else
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .normal: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.25
        }
        #endif
    }
}

/// Responsive padding system
enum PaddingLevel {
    case compact   // 4pt
    case normal    // 8pt
    case spacious  // 12pt
    case generous  // 16pt

    var value: CGFloat {
        switch self {
        case .compact: return 4
        case .normal: return 8
        case .spacious: return 12
        case .generous: return 16
        }
    }

    /// Adaptive padding based on available width
    static func adaptive(for width: CGFloat) -> PaddingLevel {
        if width < 400 {
            return .compact
        } else if width < 600 {
            return .normal
        } else if width < 800 {
            return .spacious
        } else {
            return .generous
        }
    }
}

/// Rounded corner radius system
enum CornerRadius {
    case none      // 0pt
    case small     // 4pt
    case medium    // 6pt
    case normal    // 8pt
    case large     // 12pt
    case extraLarge // 16pt

    var value: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 4
        case .medium: return 6
        case .normal: return 8
        case .large: return 12
        case .extraLarge: return 16
        }
    }
}

/// UI Configuration Manager
class UIConfiguration: ObservableObject {
    static let shared = UIConfiguration()

    @Published var fontSizeCategory: FontSizeCategory {
        didSet {
            saveSettings()
        }
    }

    @Published var gridLineOpacity: Double {
        didSet {
            saveSettings()
        }
    }

    @Published var dayNumberFontSize: Double {
        didSet {
            saveSettings()
        }
    }


    private let fontSizeKey = "fontSizeCategory"
    private let gridLineOpacityKey = "gridLineOpacity"
    private let dayNumberFontSizeKey = "dayNumberFontSize"

    init() {
        let savedFontSize = UserDefaults.standard.integer(forKey: fontSizeKey)
        self.fontSizeCategory = FontSizeCategory(rawValue: savedFontSize) ?? .normal

        // Load grid line opacity, default to 0.8 (80%)
        let loadedGridLineOpacity = UserDefaults.standard.double(forKey: gridLineOpacityKey)
        if loadedGridLineOpacity == 0.0 && !UserDefaults.standard.bool(forKey: "gridLineOpacitySet") {
            // First time setup, use default value
            self.gridLineOpacity = 0.8
            UserDefaults.standard.set(true, forKey: "gridLineOpacitySet")
        } else {
            self.gridLineOpacity = loadedGridLineOpacity
        }

        // Load day number font size, default to larger size on tvOS
        if !UserDefaults.standard.bool(forKey: "dayNumberFontSizeSet") {
            // First time setup, use default value
            #if os(tvOS)
            self.dayNumberFontSize = 68.0 // Large default for tvOS (8 + 6*12 = 68)
            #else
            self.dayNumberFontSize = 14.0 // Standard size for iOS/macOS
            #endif
            UserDefaults.standard.set(true, forKey: "dayNumberFontSizeSet")
            UserDefaults.standard.set(self.dayNumberFontSize, forKey: dayNumberFontSizeKey)
        } else {
            // Load stored value, snap to valid step size (8, 20, 32, 44, 56, 68, 80)
            let loadedValue = UserDefaults.standard.double(forKey: dayNumberFontSizeKey)
            let clampedValue = max(8, min(80, loadedValue)) // Clamp to valid range
            let step = 12.0
            let index = round((clampedValue - 8) / step)
            self.dayNumberFontSize = 8 + index * step // Snap to nearest valid step
        }
    }

    func increaseFontSize() {
        if let currentIndex = FontSizeCategory.allCases.firstIndex(of: fontSizeCategory),
           currentIndex < FontSizeCategory.allCases.count - 1 {
            fontSizeCategory = FontSizeCategory.allCases[currentIndex + 1]
        }
    }

    func decreaseFontSize() {
        if let currentIndex = FontSizeCategory.allCases.firstIndex(of: fontSizeCategory),
           currentIndex > 0 {
            fontSizeCategory = FontSizeCategory.allCases[currentIndex - 1]
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(fontSizeCategory.rawValue, forKey: fontSizeKey)
        UserDefaults.standard.set(gridLineOpacity, forKey: gridLineOpacityKey)
        UserDefaults.standard.set(dayNumberFontSize, forKey: dayNumberFontSizeKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Font Extensions

    func scaledFont(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Ensure reactivity by accessing the published property
        _ = fontSizeCategory
        return .system(size: baseSize * fontSizeCategory.scaleFactor, weight: weight)
    }

    func scaledFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        // Ensure reactivity by accessing the published property
        _ = fontSizeCategory
        let baseSize: CGFloat
        switch style {
        case .largeTitle: baseSize = 34
        case .title: baseSize = 28
        case .title2: baseSize = 22
        case .title3: baseSize = 20
        case .headline: baseSize = 17
        case .body: baseSize = 17
        case .callout: baseSize = 16
        case .subheadline: baseSize = 15
        case .footnote: baseSize = 13
        case .caption: baseSize = 12
        case .caption2: baseSize = 11
        @unknown default: baseSize = 17
        }
        return .system(size: baseSize * fontSizeCategory.scaleFactor, weight: weight)
    }

    // MARK: - Predefined Font Sizes

    var monthTitleFont: Font {
        // Ensure reactivity
        _ = fontSizeCategory
        #if os(tvOS)
        return scaledFont(56, weight: .bold) // Even larger for tvOS: 32 + 24 = 56pt minimum
        #else
        return scaledFont(32, weight: .bold)
        #endif
    }

    var yearTitleFont: Font {
        #if os(tvOS)
        scaledFont(46, weight: .semibold) // 22 + 24 = 46pt minimum
        #else
        scaledFont(.title2)
        #endif
    }

    var dayNumberFont: Font {
        #if os(tvOS)
        scaledFont(38, weight: .medium) // 14 + 24 = 38pt minimum
        #else
        scaledFont(14, weight: .medium)
        #endif
    }

    var customDayNumberFont: Font {
        #if os(tvOS)
        .system(size: dayNumberFontSize, weight: .medium)
        #else
        .system(size: dayNumberFontSize, weight: .medium)
        #endif
    }

    var dayNameFont: Font {
        #if os(tvOS)
        scaledFont(36, weight: .semibold) // 12 + 24 = 36pt minimum
        #else
        scaledFont(12, weight: .semibold)
        #endif
    }

    var eventTitleFont: Font {
        #if os(tvOS)
        scaledFont(41, weight: .semibold) // 17 + 24 = 41pt minimum
        #else
        scaledFont(.headline)
        #endif
    }
    var eventDetailFont: Font {
        #if os(tvOS)
        scaledFont(39, weight: .medium) // 15 + 24 = 39pt minimum
        #else
        scaledFont(.subheadline)
        #endif
    }

    var buttonFont: Font {
        #if os(tvOS)
        scaledFont(41, weight: .medium) // 17 + 24 = 41pt minimum
        #else
        scaledFont(17, weight: .medium)
        #endif
    }

    var captionFont: Font {
        #if os(tvOS)
        scaledFont(36, weight: .regular) // 12 + 24 = 36pt minimum
        #else
        scaledFont(.caption)
        #endif
    }

    var smallCaptionFont: Font {
        #if os(tvOS)
        scaledFont(35, weight: .regular) // 11 + 24 = 35pt minimum
        #else
        scaledFont(.caption2)
        #endif
    }
}

// MARK: - View Extensions for Responsive Padding

extension View {
    func adaptivePadding(for geometry: GeometryProxy, level: PaddingLevel = .normal) -> some View {
        let adaptiveLevel = PaddingLevel.adaptive(for: geometry.size.width)
        return self.padding(adaptiveLevel.value)
    }

    func standardPadding() -> some View {
        self.padding(PaddingLevel.normal.value)
    }

    func compactPadding() -> some View {
        self.padding(PaddingLevel.compact.value)
    }

    func roundedCorners(_ radius: CornerRadius = .normal) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius.value))
    }
}

// MARK: - Color Extensions for Rounded Corners

extension Color {
    static func backgroundRounded(opacity: Double = 1.0) -> some View {
        RoundedRectangle(cornerRadius: CornerRadius.normal.value)
            .fill(Color.white.opacity(opacity))
    }

    static func surfaceRounded() -> some View {
        RoundedRectangle(cornerRadius: CornerRadius.medium.value)
            .fill(Color.gray.opacity(0.2))
    }
}
