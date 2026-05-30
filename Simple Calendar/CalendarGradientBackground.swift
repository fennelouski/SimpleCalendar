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
