//
//  AstronomicalInfoSectionTV.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/27/25.
//

import CoreLocation
import SwiftUI

// MARK: - Astronomical Information Section (tvOS)
#if os(tvOS)
struct AstronomicalInfoSection: View {
    let date: Date
    let eventCount: Int
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    private let daylightManager = DaylightManager.shared
    private let locationApproximator = LocationApproximator.shared
    
    private var location: CLLocationCoordinate2D {
        locationApproximator.approximateLocation()
    }
    
    private var astronomicalData: AstronomicalData? {
        calculateAstronomicalData()
    }
    
    var body: some View {
        Group {
            // Don't show if 2+ events
            if eventCount >= 2 {
                EmptyView()
            } else if let data = astronomicalData {
                // If 1 event, only show sunrise/sunset
                if eventCount == 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        // Sunrise and Sunset (side by side)
                        HStack(spacing: 16) {
                            AstronomicalInfoRow(
                                icon: "sunrise.fill",
                                title: "Sunrise",
                                time: data.sunrise,
                                color: .orange
                            )
                            
                            AstronomicalInfoRow(
                                icon: "sunset.fill",
                                title: "Sunset",
                                time: data.sunset,
                                color: .orange
                            )
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(themeManager.currentPalette.surface.opacity(0.7))
                        .cornerRadius(12)
                        
                        // Daylight and Night Duration (side by side)
                        daylightNightRow(astronomicalData: data)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                } else if eventCount == 0 {
                    // If 0 events, show full information including Daily Progression
                    VStack(alignment: .leading, spacing: 16) {
                        // Sunrise and Sunset (side by side)
                        HStack(spacing: 16) {
                            AstronomicalInfoRow(
                                icon: "sunrise.fill",
                                title: "Sunrise",
                                time: data.sunrise,
                                color: .orange
                            )
                            
                            AstronomicalInfoRow(
                                icon: "sunset.fill",
                                title: "Sunset",
                                time: data.sunset,
                                color: .orange
                            )
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(themeManager.currentPalette.surface.opacity(0.7))
                        .cornerRadius(12)
                        
                        // Daylight and Night Duration (side by side)
                        daylightNightRow(astronomicalData: data)
                        
                        // Daily Progression - Only shown when eventCount == 0 (we're already in that block)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Progression")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 4)
                            
                            // Morning progression: Astronomical -> Nautical -> Civil -> Sunrise
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Morning")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(themeManager.currentPalette.textSecondary)
                                    .padding(.bottom, 2)
                                
                                TwilightTransitionRow(
                                    icon: "moon.stars",
                                    label: "Astronomical Twilight Begins",
                                    time: data.astronomicalTwilightStart,
                                    color: .purple
                                )
                                
                                TwilightTransitionRow(
                                    icon: "moon.haze",
                                    label: "Nautical Twilight Begins",
                                    time: data.nauticalTwilightStart,
                                    color: .blue
                                )
                                
                                TwilightTransitionRow(
                                    icon: "moon.haze.circle",
                                    label: "Civil Twilight Begins",
                                    time: data.civilTwilightStart,
                                    color: .cyan
                                )
                                
                                TwilightTransitionRow(
                                    icon: "sunrise",
                                    label: "Sunrise",
                                    time: data.sunrise,
                                    color: .orange
                                )
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Evening progression: Sunset -> Civil -> Nautical -> Astronomical
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Evening")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(themeManager.currentPalette.textSecondary)
                                    .padding(.bottom, 2)
                                
                                TwilightTransitionRow(
                                    icon: "sunset.fill",
                                    label: "Sunset",
                                    time: data.sunset,
                                    color: .orange
                                )
                                
                                TwilightTransitionRow(
                                    icon: "moon.haze.circle.fill",
                                    label: "Civil Twilight Ends",
                                    time: data.civilTwilightEnd,
                                    color: .cyan
                                )
                                
                                TwilightTransitionRow(
                                    icon: "moon.haze.fill",
                                    label: "Nautical Twilight Ends",
                                    time: data.nauticalTwilightEnd,
                                    color: .blue
                                )
                                
                                TwilightTransitionRow(
                                    icon: "moon.stars.fill",
                                    label: "Astronomical Twilight Ends",
                                    time: data.astronomicalTwilightEnd,
                                    color: .purple
                                )
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(themeManager.currentPalette.surface.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func daylightNightRow(astronomicalData data: AstronomicalData) -> some View {
        HStack(spacing: 16) {
            // Daylight Duration
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: sunIconForDaylightHours(data.daylightHours))
                    .font(.system(size: 44))
                    .foregroundColor(.yellow)
                    .frame(height: 60)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daylight")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                    Text(data.daylightDuration)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.currentPalette.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(themeManager.currentPalette.surface.opacity(0.7))
            .cornerRadius(12)
            
            // Night Duration
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: data.moonPhaseIcon)
                    .font(.system(size: 44))
                    .foregroundColor(.indigo)
                    .frame(height: 60)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Night")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                    Text(data.nightDuration)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.currentPalette.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(themeManager.currentPalette.surface.opacity(0.7))
            .cornerRadius(12)
        }

    }
    
    private func sunIconForDaylightHours(_ hours: Double) -> String {
        if hours < 6 {
            return "sun.horizon"
        } else if hours < 7 {
            return "sun.horizon.fill"
        } else if hours < 9 {
            return "sun.min"
        } else if hours < 11 {
            return "sun.min.fill"
        } else if hours < 13 {
            return "sun.max"
        } else {
            return "sun.max.fill"
        }
    }
    
    private func moonPhaseIconForDate(_ date: Date, atSunset sunset: Date) -> String {
        // Calculate moon phase based on the lunar cycle (29.530588 days)
        // Using a reference date for new moon (January 6, 2000 was a new moon)
        let referenceNewMoon = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2000, month: 1, day: 6, hour: 18, minute: 14).date!
        let lunarCycle: Double = 29.530588 // days
        
        let daysSinceReference = date.timeIntervalSince(referenceNewMoon) / (24 * 3600)
        let phasePosition = daysSinceReference.truncatingRemainder(dividingBy: lunarCycle)
        let phasePercentage = phasePosition / lunarCycle
        
        // Map phase to SF Symbol moon phase icons (16 phases for higher precision)
        // Each phase represents 1/16 of the lunar cycle (0.0625 = 6.25%)
        let phaseIcons: [String] = [
            "moonphase.new.moon",
            "moonphase.waxing.crescent",
            "moonphase.first.quarter",
            "moonphase.waxing.gibbous",
            "moonphase.full.moon",
            "moonphase.waxing.crescent.inverse",
            "moonphase.first.quarter.inverse",
            "moonphase.waxing.gibbous.inverse",
            "moonphase.full.moon.inverse",
        ]
        
        let phaseIndex = Int(phasePercentage * Double(phaseIcons.count) - ((1/Double(phaseIcons.count)) / 2)) % Int(phaseIcons.count)
        return phaseIcons[phaseIndex]
    }
    
    private func calculateAstronomicalData() -> AstronomicalData? {
        let latitude = location.latitude
        let longitude = location.longitude
        
        guard let sunrise = daylightManager.sunriseTime(for: date, latitude: latitude, longitude: longitude),
              let sunset = daylightManager.sunsetTime(for: date, latitude: latitude, longitude: longitude) else {
            return nil
        }
        
        let moonPhaseIcon = moonPhaseIconForDate(date, atSunset: sunset)
        
        let astronomicalStart = daylightManager.astronomicalTwilightStart(for: date, latitude: latitude, longitude: longitude)
        let astronomicalEnd = daylightManager.astronomicalTwilightEnd(for: date, latitude: latitude, longitude: longitude)
        let nauticalStart = daylightManager.nauticalTwilightStart(for: date, latitude: latitude, longitude: longitude)
        let nauticalEnd = daylightManager.nauticalTwilightEnd(for: date, latitude: latitude, longitude: longitude)
        let civilStart = daylightManager.civilTwilightStart(for: date, latitude: latitude, longitude: longitude)
        let civilEnd = daylightManager.civilTwilightEnd(for: date, latitude: latitude, longitude: longitude)
        
        // Calculate daylight duration
        let daylightHours = daylightManager.durationInHours(from: sunrise, to: sunset)
        let daylightDuration = daylightManager.formatDuration(daylightHours)
        
        // Calculate night duration (from sunset to sunrise next day)
        let calendar = Calendar(identifier: .gregorian)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
        let nextDaySunrise = daylightManager.sunriseTime(for: nextDay, latitude: latitude, longitude: longitude) ?? sunset
        let nightHours = daylightManager.durationInHours(from: sunset, to: nextDaySunrise)
        let nightDuration = daylightManager.formatDuration(nightHours)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        
        return AstronomicalData(
            sunrise: formatter.string(from: sunrise),
            sunset: formatter.string(from: sunset),
            daylightDuration: daylightDuration,
            daylightHours: daylightHours,
            nightDuration: nightDuration,
            moonPhaseIcon: moonPhaseIcon,
            astronomicalTwilightStart: astronomicalStart.map { formatter.string(from: $0) } ?? "N/A",
            astronomicalTwilightEnd: astronomicalEnd.map { formatter.string(from: $0) } ?? "N/A",
            nauticalTwilightStart: nauticalStart.map { formatter.string(from: $0) } ?? "N/A",
            nauticalTwilightEnd: nauticalEnd.map { formatter.string(from: $0) } ?? "N/A",
            civilTwilightStart: civilStart.map { formatter.string(from: $0) } ?? "N/A",
            civilTwilightEnd: civilEnd.map { formatter.string(from: $0) } ?? "N/A"
        )
    }
}

struct AstronomicalData {
    let sunrise: String
    let sunset: String
    let daylightDuration: String
    let daylightHours: Double
    let nightDuration: String
    let moonPhaseIcon: String
    let astronomicalTwilightStart: String
    let astronomicalTwilightEnd: String
    let nauticalTwilightStart: String
    let nauticalTwilightEnd: String
    let civilTwilightStart: String
    let civilTwilightEnd: String
}

struct AstronomicalInfoRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                Text(time)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentPalette.textPrimary)
            }
            
            Spacer()
        }
    }
}

struct TwilightTransitionRow: View {
    let icon: String
    let label: String
    let time: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(time)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(themeManager.currentPalette.surface.opacity(0.4))
        .cornerRadius(8)
    }
}
#endif
