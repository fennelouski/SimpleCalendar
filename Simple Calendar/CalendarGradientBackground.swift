//
//  CalendarGradientBackground.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - Gradient Background View
struct CalendarGradientBackground: View {
    enum Intensity {
        case light
        case heavy
        var topLeft: Double {
            switch self {
            case .light: return 10
            case .heavy: return 20
            }
        }
        var bottomRight: Double {
            switch self {
            case .light: return -10
            case .heavy: return -30
            }
        }
    }
    let baseColor: Color
    let colorScheme: ColorScheme
    let intensity: Intensity
    
    var body: some View {
        ZStack {
            baseGradient
            lighting
        }
    }

    /// Soft studio lighting over the flat base: a key light from the top-leading
    /// corner, falloff into the bottom-trailing corner, and an edge vignette.
    /// Gives the backdrop depth on a large TV screen without competing with content.
    private var lighting: some View {
        let isDark = colorScheme == .dark
        let strength = intensity == .heavy ? 1.4 : 1.0
        return GeometryReader { geometry in
            let span = max(geometry.size.width, geometry.size.height)
            ZStack {
                RadialGradient(
                    colors: [Color.white.opacity((isDark ? 0.09 : 0.22) * strength), Color.white.opacity(0)],
                    center: UnitPoint(x: 0.15, y: 0.05),
                    startRadius: 0,
                    endRadius: span * 0.75
                )
                RadialGradient(
                    colors: [Color.black.opacity((isDark ? 0.22 : 0.08) * strength), Color.black.opacity(0)],
                    center: UnitPoint(x: 0.95, y: 1.05),
                    startRadius: 0,
                    endRadius: span * 0.65
                )
                RadialGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity((isDark ? 0.28 : 0.1) * strength)],
                    center: .center,
                    startRadius: span * 0.35,
                    endRadius: span * 0.8
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var baseGradient: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: gradient from top-left (same) to bottom-right (10% darker)
                LinearGradient(
                    gradient: Gradient(colors: [
                        baseColor.adjustedBrightness(by: intensity.topLeft),
                        baseColor,
                        baseColor,
                        baseColor.adjustedBrightness(by: intensity.bottomRight)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Light mode: gradient from bottom-right (same) to top-left (10% lighter)
                LinearGradient(
                    gradient: Gradient(colors: [
                        baseColor.adjustedBrightness(by: intensity.topLeft),
                        baseColor,
                        baseColor,
                        baseColor.adjustedBrightness(by: intensity.bottomRight)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
