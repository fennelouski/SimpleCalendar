//
//  Color+Extension.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Color Extension for Brightness Adjustment
extension Color {
    /// Adjusts the brightness of the color by a percentage
    /// - Parameter percent: Percentage to adjust (positive = lighter, negative = darker)
    /// - Returns: A new Color with adjusted brightness
    func adjustedBrightness(by percent: Double) -> Color {
        let adjustment = percent / 100.0
        
#if os(macOS)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Try HSB color space first
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if hue >= 0 && saturation >= 0 && brightness >= 0 {
            let newBrightness = max(0, min(1, brightness + CGFloat(adjustment)))
            return Color(NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        }
        
        // Fallback to RGB for grayscale or other color spaces
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha2: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha2)
        // Adjust RGB components by brightness factor
        let factor = 1.0 + CGFloat(adjustment)
        let newRed = max(0, min(1, red * factor))
        let newGreen = max(0, min(1, green * factor))
        let newBlue = max(0, min(1, blue * factor))
        return Color(red: Double(newRed), green: Double(newGreen), blue: Double(newBlue), opacity: Double(alpha2))
#else
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Try HSB color space first
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newBrightness = max(0, min(1, brightness + CGFloat(adjustment)))
            return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        }
        
        // Fallback to RGB for grayscale or other color spaces
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha2: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha2) {
            // Adjust RGB components by brightness factor
            let factor = 1.0 + CGFloat(adjustment)
            let newRed = max(0, min(1, red * factor))
            let newGreen = max(0, min(1, green * factor))
            let newBlue = max(0, min(1, blue * factor))
            return Color(red: Double(newRed), green: Double(newGreen), blue: Double(newBlue), opacity: Double(alpha2))
        }
#endif
        // Fallback to original color if conversion fails
        return self
    }
    
    /// Adjusts the saturation of the color by a factor
    /// - Parameter factor: Factor to adjust (0.0 = grayscale, 1.0 = original, >1.0 = more saturated)
    /// - Returns: A new Color with adjusted saturation
    func adjustedSaturation(by factor: Double) -> Color {
#if os(macOS)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newSaturation = max(0, min(1, saturation * CGFloat(factor)))
        return Color(NSColor(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha))
#else
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newSaturation = max(0, min(1, saturation * CGFloat(factor)))
            return Color(UIColor(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha))
        }
        return self
#endif
    }
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
