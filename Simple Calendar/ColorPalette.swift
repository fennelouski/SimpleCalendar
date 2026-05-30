//
//  ColorPalette.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
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
    
    /// Returns a new palette with adjusted saturation
    func withSaturation(_ saturation: Double) -> ColorPalette {
        if saturation == 1.0 { return self }
        
        return ColorPalette(
            name: name,
            primary: primary.adjustedSaturation(by: saturation),
            secondary: secondary.adjustedSaturation(by: saturation),
            accent: accent.adjustedSaturation(by: saturation),
            background: background.adjustedSaturation(by: saturation),
            surface: surface.adjustedSaturation(by: saturation),
            textPrimary: textPrimary.adjustedSaturation(by: saturation),
            textSecondary: textSecondary.adjustedSaturation(by: saturation),
            border: border.adjustedSaturation(by: saturation),
            highlight: highlight.adjustedSaturation(by: saturation),
            gridLine: gridLine.adjustedSaturation(by: saturation),
            eventColors: eventColors.map { $0.adjustedSaturation(by: saturation) },
            icon: icon
        )
    }
}
