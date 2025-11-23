//
//  UIConfiguration.swift
//  Simple Calendar
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
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .normal: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.25
        }
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

    private let fontSizeKey = "fontSizeCategory"

    init() {
        let savedFontSize = UserDefaults.standard.integer(forKey: fontSizeKey)
        self.fontSizeCategory = FontSizeCategory(rawValue: savedFontSize) ?? .normal
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
        UserDefaults.standard.synchronize()
    }

    // MARK: - Font Extensions

    func scaledFont(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: baseSize * fontSizeCategory.scaleFactor, weight: weight)
    }

    func scaledFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
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

    var monthTitleFont: Font { scaledFont(32, weight: .bold) }
    var yearTitleFont: Font { scaledFont(.title2) }
    var dayNumberFont: Font { scaledFont(14, weight: .medium) }
    var eventTitleFont: Font { scaledFont(.headline) }
    var eventDetailFont: Font { scaledFont(.subheadline) }
    var buttonFont: Font { scaledFont(17, weight: .medium) }
    var captionFont: Font { scaledFont(.caption) }
    var smallCaptionFont: Font { scaledFont(.caption2) }
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
