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
        _ = calendar.dateComponents([.month, .day], from: date)
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

    /// Get sunrise time in hours for a date (legacy method for visualization)
    func sunriseTimeInHours(for date: Date, latitude: Double = 40.7128, longitude: Double = -74.0060) -> Double {
        let dayOfYear = dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        return calculateSunriseHour(latitude: latitude, solarDeclination: solarDeclination)
    }

    /// Get sunset time in hours for a date (legacy method for visualization)
    func sunsetTimeInHours(
        for date: Date,
        latitude: Double = 40.7128,
        longitude: Double = -74.0060
    ) -> Double {
        let sunriseHour = sunriseTimeInHours(for: date, latitude: latitude, longitude: longitude)
        return 24.0 - sunriseHour
    }
    
    /// Get sunrise time in hours for a date (convenience method using approximate location)
    func sunriseTime(for date: Date) -> Double {
        let location = LocationApproximator.shared.approximateLocation()
        return sunriseTimeInHours(for: date, latitude: location.latitude, longitude: location.longitude)
    }
    
    /// Get sunset time in hours for a date (convenience method using approximate location)
    func sunsetTime(for date: Date) -> Double {
        let location = LocationApproximator.shared.approximateLocation()
        return sunsetTimeInHours(for: date, latitude: location.latitude, longitude: location.longitude)
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
    
    // MARK: - Astronomical Calculations
    
    /// Calculate solar elevation angle for a given hour angle
    private func solarElevation(latitude: Double, solarDeclination: Double, hourAngle: Double) -> Double {
        let latRad = latitude * Double.pi / 180.0
        let declRad = solarDeclination
        let haRad = hourAngle * Double.pi / 180.0
        
        let elevation = asin(sin(latRad) * sin(declRad) + cos(latRad) * cos(declRad) * cos(haRad))
        return elevation * 180.0 / Double.pi // Convert to degrees
    }
    
    /// Calculate hour angle for a given solar elevation
    private func hourAngleForElevation(latitude: Double, solarDeclination: Double, elevation: Double) -> Double? {
        let latRad = latitude * Double.pi / 180.0
        let declRad = solarDeclination
        let elevRad = elevation * Double.pi / 180.0
        
        let cosHA = (sin(elevRad) - sin(latRad) * sin(declRad)) / (cos(latRad) * cos(declRad))
        
        // Check if the sun reaches this elevation
        guard cosHA >= -1.0 && cosHA <= 1.0 else {
            return nil
        }
        
        return acos(cosHA) * 180.0 / Double.pi // Convert to degrees
    }
    
    /// Calculate time when sun reaches a specific elevation angle
    private func timeForElevation(latitude: Double, solarDeclination: Double, elevation: Double, isRising: Bool) -> Double? {
        guard let hourAngle = hourAngleForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: elevation) else {
            return nil
        }
        
        // Convert hour angle to time (hours from solar noon)
        let timeFromNoon = hourAngle / 15.0 // 15 degrees per hour
        
        if isRising {
            return 12.0 - timeFromNoon
        } else {
            return 12.0 + timeFromNoon
        }
    }
    
    /// Calculate equation of time correction (in minutes)
    private func equationOfTime(dayOfYear: Int) -> Double {
        let B = 2 * Double.pi * Double(dayOfYear - 81) / 365.0
        return 9.87 * sin(2 * B) - 7.53 * cos(B) - 1.5 * sin(B)
    }
    
    /// Get sunrise time for a date and location
    func sunriseTime(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        // Calculate time when sun is at -0.83 degrees (accounting for atmospheric refraction)
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -0.83, isRising: true) else {
            return nil
        }
        
        // Apply equation of time correction
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0 // Convert minutes to hours
        let longitudeCorrection = longitude / 15.0 // 15 degrees per hour
        let correctedHour = hour - eqTime - longitudeCorrection
        
        // Get the date at midnight
        let startOfDay = calendar.startOfDay(for: date)
        
        // Add the calculated hours
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get sunset time for a date and location
    func sunsetTime(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        // Calculate time when sun is at -0.83 degrees (accounting for atmospheric refraction)
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -0.83, isRising: false) else {
            return nil
        }
        
        // Apply equation of time correction
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0 // Convert minutes to hours
        let longitudeCorrection = longitude / 15.0 // 15 degrees per hour
        let correctedHour = hour - eqTime - longitudeCorrection
        
        // Get the date at midnight
        let startOfDay = calendar.startOfDay(for: date)
        
        // Add the calculated hours
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get astronomical twilight start time (sun at -18 degrees)
    func astronomicalTwilightStart(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -18.0, isRising: true) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get astronomical twilight end time (sun at -18 degrees)
    func astronomicalTwilightEnd(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -18.0, isRising: false) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get nautical twilight start time (sun at -12 degrees)
    func nauticalTwilightStart(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -12.0, isRising: true) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get nautical twilight end time (sun at -12 degrees)
    func nauticalTwilightEnd(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -12.0, isRising: false) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get civil twilight start time (sun at -6 degrees)
    func civilTwilightStart(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -6.0, isRising: true) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Get civil twilight end time (sun at -6 degrees)
    func civilTwilightEnd(for date: Date, latitude: Double, longitude: Double) -> Date? {
        let calendar = Calendar.current
        let dayOfYear = self.dayOfYear(from: date)
        let solarDeclination = calculateSolarDeclination(dayOfYear: dayOfYear)
        
        guard let hour = timeForElevation(latitude: latitude, solarDeclination: solarDeclination, elevation: -6.0, isRising: false) else {
            return nil
        }
        
        let eqTime = equationOfTime(dayOfYear: dayOfYear) / 60.0
        let longitudeCorrection = longitude / 15.0
        let correctedHour = hour - eqTime - longitudeCorrection
        
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: Int(correctedHour), to: startOfDay)?
            .addingTimeInterval((correctedHour - Double(Int(correctedHour))) * 3600)
    }
    
    /// Calculate duration between two dates in hours
    func durationInHours(from start: Date, to end: Date) -> Double {
        return end.timeIntervalSince(start) / 3600.0
    }
    
    /// Format duration as hours and minutes
    func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}
