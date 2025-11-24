//
//  DaylightVisualizationView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

/// Horizontal daylight visualization for calendar day cells
struct DaylightVisualizationView: View {
    let date: Date
    let width: CGFloat
    private let height: CGFloat = 3.0

    var body: some View {
        ZStack {
            ForEach(0..<96) { periodIndex in
                Rectangle()
                    .fill(colorForPeriod(periodIndex))
                    .frame(width: width / 96, height: height)
                    .offset(x: CGFloat(periodIndex) * (width / 96) - width/2 + (width / 96)/2)
            }
        }
        .frame(width: width, height: height)
    }

    private func colorForPeriod(_ periodIndex: Int) -> Color {
        // Each period represents 15 minutes (24 hours * 4 periods per hour = 96 periods)
        let hour = Double(periodIndex) * 24.0 / 96.0
        let daylightColor = DaylightManager.shared.colorForHour(hour, date: date)
        return daylightColor.swiftUIColor
    }
}

/// Vertical daylight visualization for day detail view
struct VerticalDaylightVisualizationView: View {
    let date: Date
    private let width: CGFloat = 30.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Show periods from previous day, current day, and next day for overflow
                // Total of 288 periods (3 days * 96 periods per day)
                ForEach(0..<288) { periodIndex in
                    Rectangle()
                        .fill(colorForExtendedPeriod(periodIndex))
                        .frame(width: width, height: geometry.size.height / 288)
                        .offset(y: CGFloat(periodIndex) * (geometry.size.height / 288))
                }

                // Time markers overlay
                timeMarkers(geometry: geometry)
            }
            .frame(width: width, height: geometry.size.height)
        }
        .frame(width: width)
    }

    private func colorForExtendedPeriod(_ periodIndex: Int) -> Color {
        // Map 288 periods (3 days) to the appropriate date and hour
        _ = 288
        let periodsPerDay = 96

        // Calculate which day and period within that day
        let dayOffset = periodIndex / periodsPerDay  // 0 = previous day, 1 = current day, 2 = next day
        let periodWithinDay = periodIndex % periodsPerDay

        // Get the appropriate date
        let targetDate: Date
        switch dayOffset {
        case 0:
            targetDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        case 1:
            targetDate = date
        case 2:
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        default:
            targetDate = date
        }

        // Each period represents 15 minutes
        let hour = Double(periodWithinDay) * 24.0 / Double(periodsPerDay)
        let daylightColor = DaylightManager.shared.colorForHour(hour, date: targetDate)
        return daylightColor.swiftUIColor
    }

    private func timeMarkers(geometry: GeometryProxy) -> some View {
        ZStack {
            let sunrise = DaylightManager.shared.sunriseTime(for: date)
            let sunset = DaylightManager.shared.sunsetTime(for: date)

            // Check if sunrise/sunset are within 2 hours of each other
            let isNearTwilight = abs(sunrise - sunset) < 2.0

            // Key time markers
            let keyTimes = getKeyTimes(for: date, isNearTwilight: isNearTwilight)

            ForEach(keyTimes, id: \.hour) { timeMarker in
                let yPosition = hourToYPosition(timeMarker.hour, geometry: geometry)

                // Time label
                Text(timeMarker.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                            .frame(height: 16)
                    )
                    .frame(width: width - 4, height: 16)
                    .position(x: width/2, y: yPosition)
            }
        }
    }

    private func getKeyTimes(for date: Date, isNearTwilight: Bool) -> [(hour: Double, label: String)] {
        var times: [(Double, String)] = []

        let sunrise = DaylightManager.shared.sunriseTime(for: date)
        let sunset = DaylightManager.shared.sunsetTime(for: date)

        // Always show sunrise and sunset
        times.append((sunrise, "☀️"))
        times.append((sunset, "🌙"))

        // If not within 2 hours of sunrise/sunset, add standard time markers
        if !isNearTwilight {
            let standardTimes = [
                0.0: "12A",   // Midnight
                3.0: "3A",
                6.0: "6A",
                9.0: "9A",
                12.0: "12P",  // Noon
                15.0: "3P",
                18.0: "6P",
                21.0: "9P"
            ]

            for (hour, label) in standardTimes {
                // Only add if not too close to sunrise/sunset (within 2 hours)
                if abs(hour - sunrise) >= 2.0 && abs(hour - sunset) >= 2.0 {
                    times.append((hour, label))
                }
            }
        }

        return times.sorted { $0.0 < $1.0 }
    }

    private func hourToYPosition(_ hour: Double, geometry: GeometryProxy) -> CGFloat {
        // Map hour (0-24) to Y position in the 3-day visualization
        // Hours 0-24 should map to the middle third (current day)
        let totalHeight = geometry.size.height
        let dayHeight = totalHeight / 3.0
        let currentDayStartY = dayHeight

        let yInCurrentDay = (hour / 24.0) * dayHeight
        return currentDayStartY + yInCurrentDay
    }
}
