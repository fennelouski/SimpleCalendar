//
//  DaylightManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// Represents different phases of daylight
enum DaylightPhase {
    case astronomicalTwilight
    case nauticalTwilight
    case civilTwilight
    case sunrise
    case goldenHour
    case daylight
    case sunset
    case goldenHourEvening
    case civilTwilightEvening
    case nauticalTwilightEvening
    case astronomicalTwilightEvening
    case night
}

/// Represents a period of daylight with color and time range
struct DaylightPeriod {
    let phase: DaylightPhase
    let startHour: Double // 0-24
    let endHour: Double   // 0-24
    let color: DaylightColor

    var duration: Double {
        endHour - startHour
    }
}

/// Color representation for daylight visualization
struct DaylightColor {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    var swiftUIColor: Color {
        Color(red: red/255.0, green: green/255.0, blue: blue/255.0, opacity: alpha)
    }

    // Predefined colors for daylight phases
    static let night = DaylightColor(red: 0, green: 0, blue: 0, alpha: 1.0) // Black
    static let astronomicalTwilight = DaylightColor(red: 10, green: 0, blue: 20, alpha: 1.0) // Very dark purple
    static let nauticalTwilight = DaylightColor(red: 20, green: 0, blue: 40, alpha: 1.0) // Dark purple
    static let civilTwilight = DaylightColor(red: 40, green: 20, blue: 80, alpha: 1.0) // Medium purple-blue
    static let sunrise = DaylightColor(red: 255, green: 100, blue: 50, alpha: 1.0) // Red-orange
    static let goldenHour = DaylightColor(red: 255, green: 200, blue: 100, alpha: 1.0) // Golden
    static let daylightLight = DaylightColor(red: 135, green: 206, blue: 250, alpha: 1.0) // Light blue
    static let daylightRich = DaylightColor(red: 25, green: 25, blue: 112, alpha: 1.0) // Rich blue
}

/// Manages daylight calculations and visualization
class DaylightManager {
    static let shared = DaylightManager()

    private init() {}

    /// Calculate daylight periods for a given date and location
    func daylightPeriods(for date: Date, latitude: Double = 40.7128, longitude: Double = -74.0060) -> [DaylightPeriod] {
        // For simplicity, we'll use approximate sunrise/sunset times
        // In a real app, you'd use astronomical calculations or an API

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        let dayOfYear = dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)

        // Approximate sunrise/sunset hours (simplified calculation)
        let sunriseHour = calculateSunriseHour(latitude: latitude, solarDeclination: solarDeclination)
        let sunsetHour = 24.0 - sunriseHour

        // Define daylight phases with approximate durations
        return [
            DaylightPeriod(phase: .night, startHour: 0, endHour: sunriseHour - 2.5, color: .night),
            DaylightPeriod(phase: .astronomicalTwilight, startHour: sunriseHour - 2.5, endHour: sunriseHour - 2.0, color: .astronomicalTwilight),
            DaylightPeriod(phase: .nauticalTwilight, startHour: sunriseHour - 2.0, endHour: sunriseHour - 1.5, color: .nauticalTwilight),
            DaylightPeriod(phase: .civilTwilight, startHour: sunriseHour - 1.5, endHour: sunriseHour - 0.5, color: .civilTwilight),
            DaylightPeriod(phase: .sunrise, startHour: sunriseHour - 0.5, endHour: sunriseHour + 0.5, color: .sunrise),
            DaylightPeriod(phase: .goldenHour, startHour: sunriseHour + 0.5, endHour: sunriseHour + 1.5, color: .goldenHour),
            DaylightPeriod(phase: .daylight, startHour: sunriseHour + 1.5, endHour: sunsetHour - 1.5, color: .daylightRich),
            DaylightPeriod(phase: .goldenHourEvening, startHour: sunsetHour - 1.5, endHour: sunsetHour - 0.5, color: .goldenHour),
            DaylightPeriod(phase: .sunset, startHour: sunsetHour - 0.5, endHour: sunsetHour + 0.5, color: .sunrise),
            DaylightPeriod(phase: .civilTwilightEvening, startHour: sunsetHour + 0.5, endHour: sunsetHour + 1.5, color: .civilTwilight),
            DaylightPeriod(phase: .nauticalTwilightEvening, startHour: sunsetHour + 1.5, endHour: sunsetHour + 2.0, color: .nauticalTwilight),
            DaylightPeriod(phase: .astronomicalTwilightEvening, startHour: sunsetHour + 2.0, endHour: sunsetHour + 2.5, color: .astronomicalTwilight),
            DaylightPeriod(phase: .night, startHour: sunsetHour + 2.5, endHour: 24.0, color: .night)
        ]
    }

    /// Get color for a specific hour of the day with smooth interpolation between phases
    func colorForHour(_ hour: Double, date: Date) -> DaylightColor {
        let periods = daylightPeriods(for: date)

        // Find the current period and interpolate with the next period for smooth transitions
        for (index, period) in periods.enumerated() {
            if hour >= period.startHour && hour < period.endHour {
                // Special handling for daylight period - use lighter blue in the middle
                if period.phase == .daylight {
                    let progress = (hour - period.startHour) / period.duration
                    // Create a smoother daylight gradient with lighter blue in the middle
                    let midPoint = 0.5
                    var factor: Double

                    if progress < midPoint {
                        // First half: transition to lighter blue
                        factor = progress / midPoint
                        let lighterBlue = DaylightColor(red: 100, green: 180, blue: 255, alpha: 1.0) // Lighter blue
                        return interpolateColor(from: DaylightColor.daylightRich, to: lighterBlue, factor: factor)
                    } else {
                        // Second half: transition back to rich blue
                        factor = (progress - midPoint) / midPoint
                        let lighterBlue = DaylightColor(red: 100, green: 180, blue: 255, alpha: 1.0) // Lighter blue
                        return interpolateColor(from: lighterBlue, to: DaylightColor.daylightRich, factor: factor)
                    }
                }

                // For other periods, interpolate with adjacent periods for smooth transitions
                let progress = (hour - period.startHour) / period.duration

                // If we're in the first 20% of the period, blend with the previous period
                if progress < 0.2 && index > 0 {
                    let prevPeriod = periods[index - 1]
                    let blendFactor = progress / 0.2
                    return interpolateColor(from: prevPeriod.color, to: period.color, factor: blendFactor)
                }
                // If we're in the last 20% of the period, blend with the next period
                else if progress > 0.8 && index < periods.count - 1 {
                    let nextPeriod = periods[index + 1]
                    let blendFactor = (progress - 0.8) / 0.2
                    return interpolateColor(from: period.color, to: nextPeriod.color, factor: blendFactor)
                }
                // Otherwise, use the period color directly
                else {
                    return period.color
                }
            }
        }

        return .night
    }

    /// Interpolate between two DaylightColor values
    private func interpolateColor(from startColor: DaylightColor, to endColor: DaylightColor, factor: Double) -> DaylightColor {
        let clampedFactor = max(0, min(1, factor))
        let red = startColor.red + (endColor.red - startColor.red) * clampedFactor
        let green = startColor.green + (endColor.green - startColor.green) * clampedFactor
        let blue = startColor.blue + (endColor.blue - startColor.blue) * clampedFactor
        let alpha = startColor.alpha + (endColor.alpha - startColor.alpha) * clampedFactor
        return DaylightColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Calculate day of year (1-365)
    private func dayOfYear(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    /// Calculate solar declination
    private func calculateSolarDeclination(dayOfYear: Int) -> Double {
        let dayAngle = 2 * Double.pi * Double(dayOfYear - 81) / 365.0
        return 23.45 * sin(dayAngle) * Double.pi / 180.0 // Convert to radians
    }

    /// Get sunrise time in hours for a date
    func sunriseTime(for date: Date, latitude: Double = 40.7128, longitude: Double = -74.0060) -> Double {
        let dayOfYear = dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        return calculateSunriseHour(latitude: latitude, solarDeclination: solarDeclination)
    }

    /// Get sunset time in hours for a date
    func sunsetTime(for date: Date, latitude: Double = 40.7128, longitude: Double = -74.0060) -> Double {
        let sunriseHour = sunriseTime(for: date, latitude: latitude, longitude: longitude)
        return 24.0 - sunriseHour
    }

    /// Approximate sunrise hour calculation
    private func calculateSunriseHour(latitude: Double, solarDeclination: Double) -> Double {
        let latitudeRad = latitude * Double.pi / 180.0

        // Simplified sunrise calculation (cos^-1(-tan(lat) * tan(dec)))
        let hourAngle = acos(-tan(latitudeRad) * tan(solarDeclination))

        // Convert from radians to hours (15 degrees = 1 hour)
        let sunriseHour = 12.0 - (hourAngle * 180.0 / Double.pi) / 15.0

        // Clamp to reasonable values
        return max(5.0, min(9.0, sunriseHour))
    }
}
