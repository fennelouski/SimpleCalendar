//
//  StatusBarView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/30/25.
//

import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var themeManager: ThemeManager

    // Current time for display
    @State private var currentTime: Date = Date()
    @State private var timeUpdateTask: Task<Void, Never>?
    @State private var lastMinute: Int = Calendar.current.component(.minute, from: Date())

    #if os(tvOS)
    // Date format rotation for tvOS month view
    @State private var dateFormatIndex: Int = 0

    // Date format options for rotation (locale-aware, starting with numeric formats)
    private var dateFormats: [(Date) -> String] {
        var formats: [(Date) -> String] = []

        let isEuropeanLocale = checkEuropeanLocale()

        if isEuropeanLocale {
            // European formats (day-first)
            formats.append(contentsOf: [
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yyyy"
                    return formatter.string(from: date)
                }, // "15/01/2024" (DD/MM/YYYY)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "d/M/yyyy"
                    return formatter.string(from: date)
                }, // "15/1/2024" (D/M/YYYY no leading zeros)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd-MM-yyyy"
                    return formatter.string(from: date)
                }, // "15-01-2024" (DD-MM-YYYY)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd.MM.yyyy"
                    return formatter.string(from: date)
                }, // "15.01.2024" (DD.MM.YYYY)
            ])
        } else {
            // American formats (month-first)
            formats.append(contentsOf: [
                { date in date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year()) }, // "01/15/2024" (MM/DD/YYYY)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "M/d/yyyy"
                    return formatter.string(from: date)
                }, // "1/15/2024" (M/D/YYYY no leading zeros)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd-yyyy"
                    return formatter.string(from: date)
                }, // "01-15-2024" (MM-DD-YYYY)
                { date in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM.dd.yyyy"
                    return formatter.string(from: date)
                }, // "01.15.2024" (MM.DD.YYYY)
            ])
        }

        // Universal formats (all locales)
        formats.append(contentsOf: [
            { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            }, // "2024-01-15" (YYYY-MM-DD ISO)
            // Text formats
            { date in date.formatted(.dateTime.month(.wide).day().year()) }, // "January 15, 2024"
            { date in date.formatted(.dateTime.month(.abbreviated).day().year()) }, // "Jan 15, 2024"
            { date in date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) }, // "Monday, January 15, 2024"
            { date in date.formatted(.dateTime.month(.wide).day()) }, // "January 15"
            { date in date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()) }, // "Mon, Jan 15, 2024"
        ])

        return formats
    }

    // Check if locale uses day-first (European) or month-first (American) date format
    private func checkEuropeanLocale() -> Bool {
        let locale = Locale.current
        // Check region code for common European countries
        let europeanRegionCodes = ["GB", "IE", "FR", "DE", "IT", "ES", "PT", "NL", "BE", "AT", "CH", "SE", "NO", "DK", "FI", "PL", "CZ", "HU", "GR", "RO", "BG", "HR", "SK", "SI", "EE", "LV", "LT", "MT", "CY", "LU", "IS"]

        if let regionCode = locale.region?.identifier {
            return europeanRegionCodes.contains(regionCode)
        }

        // Fallback: check date format pattern
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .short
        let pattern = formatter.dateFormat ?? ""
        // European formats typically start with "d" (day), American with "M" (month)
        return pattern.hasPrefix("d") || pattern.hasPrefix("dd")
    }

    private func formatDate(_ date: Date) -> String {
        let formatIndex = dateFormatIndex % dateFormats.count
        return dateFormats[formatIndex](date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium // Includes seconds and respects user's locale settings
        return formatter.string(from: date)
    }
    #endif

    var body: some View {
        #if os(tvOS)
        // tvOS: Show selected date display in top left (stacked vertically)
        VStack(alignment: .leading, spacing: 4) {
            // Current date display
            Text(formatDate(Date()))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.monthText)
                .lineLimit(1)

            // Current time display
            Text(formatTime(currentTime))
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(themeManager.currentPalette.monthText.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .onAppear {
            startTimeUpdateTimer()
        }
        .onDisappear {
            stopTimeUpdateTimer()
        }
        #else
        // iOS/macOS: Could add status bar content here if needed
        EmptyView()
        #endif
    }

    #if os(tvOS)
    private func startTimeUpdateTimer() {
        // Stop any existing task
        stopTimeUpdateTimer()

        // Update immediately
        currentTime = Date()
        lastMinute = Calendar.current.component(.minute, from: currentTime)

        // Create a task that updates every second
        timeUpdateTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                guard !Task.isCancelled else { return }

                let now = Date()
                let currentMinute = Calendar.current.component(.minute, from: now)

                // Update time
                currentTime = now

                // Update date format if minute changed
                if currentMinute != lastMinute {
                    dateFormatIndex = (dateFormatIndex + 1) % dateFormats.count
                    lastMinute = currentMinute
                }
            }
        }
    }

    private func stopTimeUpdateTimer() {
        timeUpdateTask?.cancel()
        timeUpdateTask = nil
    }

    #endif
}
