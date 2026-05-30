//
//  DayView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import CoreLocation
import SwiftUI

struct DayView: View {
    let day: CalendarDay
    let geometry: GeometryProxy
    let cellHeight: CGFloat
    let columnsCount: Int
    let fontSize: Double
    /// When true, the layout is showing fewer than two weeks of days, so we can afford multiline text.
    let isExpandedLayout: Bool
    #if os(tvOS)
    var focusedDate: Date?
    #endif
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared
    private let holidayManager = HolidayManager.shared
    private let weatherManager = WeatherManager.shared
    
    #if !os(tvOS)
    @State private var weatherInfo: WeatherInfo?
    @State private var weatherForecast: WeatherForecast?
    @State private var weatherDisplayState: WeatherDisplayState = .icon
    @State private var weatherRotationTask: Task<Void, Never>?
    #endif
    
#if os(tvOS)
    private let maximumNumberOfHolidays = 2
#else
    private let maximumNumberOfHolidays: Int = .max
#endif
    
    private var monthlyPalette: ColorPalette {
        if featureFlags.monthlyThemesEnabled {
            let month = Calendar(identifier: .gregorian).component(.month, from: day.date)
            let monthlyTheme = monthlyThemeManager.theme(for: month)
            return monthlyTheme.palette(for: themeManager.currentColorScheme)
        } else {
            return themeManager.currentPalette
        }
    }
    
    private var isCompactLayout: Bool {
#if os(iOS)
        // Consider compact if cell height is less than 60 or columns > 7
        return cellHeight < 60 || columnsCount > 7
#else
        return false
#endif
    }
    
    private var maxEventsToShow: Int {
        return isCompactLayout ? 1 : 3
    }
    
    private var holidaysOnThisDay: [CalendarHoliday] {
        guard featureFlags.holidayDisplayEnabled else { return [] }
        return holidayManager.holidaysOn(day.date)
    }
    
    var body: some View {
        mainContent
            .compactPadding()
            .frame(height: cellHeight)
            .background(backgroundView)
            .roundedCorners(.small)
            .overlay(gridOverlay)
            .overlay(todayOverlay)
            .overlay(weatherOverlay)
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: day.date) { _, _ in
                handleDateChange(day.date)
            }
            .animation(.easeInOut(duration: 0.2), value: day.isSelected)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint("Double tap to view details".localized)
            .accessibilityAddTraits(accessibilityTraits)
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 1 : 2) {
            dateText
            contentSection
            #if os(tvOS)
            // Push content to top when there's no events/holidays
            if day.events.isEmpty && holidaysOnThisDay.isEmpty {
                Spacer()
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var dateText: some View {
        Text(day.date.formatted(.dateTime.day()))
            .font(dayFont)
            .foregroundColor(dayTextColor)
#if !os(tvOS)
            .minimumScaleFactor(0.5)
#endif
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
#if os(tvOS)
            .frame(minHeight: fontSize * 1.2)
#endif
    }
    
    @ViewBuilder
    private var contentSection: some View {
#if os(tvOS)
        tvOSContent
#else
        nonTVOSContent
#endif
    }
    
    @ViewBuilder
    private var tvOSContent: some View {
        let hasContent = !day.events.isEmpty || !holidaysOnThisDay.isEmpty
        
        if hasContent {
            Spacer(minLength: 4)
            tvOSContentStack
            Spacer(minLength: 4)
        }
    }
    
    private var tvOSContentStack: some View {
        VStack(alignment: .center, spacing: 6) {
            if !holidaysOnThisDay.isEmpty {
                tvOSHolidayView
            }
            if !day.events.isEmpty {
                tvOSEventView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var tvOSHolidayView: some View {
        let displayedHolidays = holidaysOnThisDay.prefix(2)
        HStack(spacing: 8) {
            ForEach(Array(displayedHolidays)) { holiday in
                Text(holiday.emoji)
                    .font(.system(size: 36))
            }
        }
        
        if holidaysOnThisDay.count == 1, let holiday = holidaysOnThisDay.first {
            Text(holiday.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(monthlyPalette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if holidaysOnThisDay.count > 1 {
            Text("%d holidays".localized(with: min(holidaysOnThisDay.count, maximumNumberOfHolidays)))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(monthlyPalette.accent)
        }
    }
    
    @ViewBuilder
    private var tvOSEventView: some View {
        HStack(spacing: 8) {
            ForEach(Array(day.events.prefix(4).enumerated()), id: \.offset) { index, event in
                if let emoji = EventIconManager.emojiForEvent(event.title) {
                    Text(emoji)
                        .font(.system(size: 28))
                } else {
                    #if os(tvOS)
                    Circle()
                        .fill(eventIndicatorColor(for: index))
                        .frame(width: 20, height: 20)
                    #else
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    #endif
                }
            }
        }
        
        if day.events.count == 1, let firstEvent = day.events.first {
            Text(firstEvent.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(monthlyPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Text("%d events".localized(with: day.events.count))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(monthlyPalette.textSecondary)
        }
    }
    
    @ViewBuilder
    private var nonTVOSContent: some View {
        if !isCompactLayout {
            expandedContent
        } else {
            compactContent
        }
#if !os(tvOS)
        Spacer()
#endif
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        ForEach(day.events.prefix(maxEventsToShow)) { event in
            Text(event.title)
                .font(uiConfig.captionFont)
                .lineLimit(isExpandedLayout ? nil : 1)
                .foregroundColor(monthlyPalette.textSecondary)
        }
        
        if day.events.count > maxEventsToShow {
            Text("+%d more".localized(with: day.events.count - maxEventsToShow))
                .font(uiConfig.smallCaptionFont)
                .foregroundColor(monthlyPalette.textSecondary)
        }
        
        if featureFlags.holidayDisplayEnabled && !holidaysOnThisDay.isEmpty {
            ForEach(holidaysOnThisDay.prefix(2)) { holiday in
                HStack(spacing: 2) {
                    Text(holiday.emoji)
                        .font(.system(size: 8))
                    Text(holiday.name)
                        .font(uiConfig.captionFont)
                        .lineLimit(1)
                        .foregroundColor(monthlyPalette.accent)
                }
            }
        }
    }
    
    @ViewBuilder
    private var compactContent: some View {
        HStack(spacing: 2) {
            ForEach(day.events.prefix(min(3, day.events.count))) { event in
                Text(EventIconManager.compactRepresentation(for: event.title, cellWidth: geometry.size.width / CGFloat(columnsCount)))
                    .font(.system(size: 10))
                    .foregroundColor(monthlyPalette.textSecondary)
            }
            
            if day.events.count > 3 {
                Text("…")
                    .font(.system(size: 10))
                    .foregroundColor(monthlyPalette.textSecondary)
            }
        }
        
        if featureFlags.holidayDisplayEnabled && !holidaysOnThisDay.isEmpty && isCompactLayout {
            HStack(spacing: 1) {
                ForEach(holidaysOnThisDay.prefix(2)) { holiday in
                    Text(holiday.emoji)
                        .font(.system(size: 8))
                }
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            dayBackgroundColor
            if featureFlags.daylightVisualizationCalendar {
                VStack(spacing: 0) {
                    DaylightVisualizationView(date: day.date, width: geometry.size.width / CGFloat(columnsCount))
                    Spacer()
                }
            }
        }
    }
    
    private var gridOverlay: some View {
        RoundedRectangle(cornerRadius: CornerRadius.small.value)
            .stroke(monthlyPalette.gridLine.opacity(uiConfig.gridLineOpacity),
                    lineWidth: gridLineWidth(for: uiConfig.gridLineOpacity))
    }
    
    private var todayOverlay: some View {
        RoundedRectangle(cornerRadius: CornerRadius.small.value)
            .stroke(day.isToday ? monthlyPalette.accent : Color.clear, lineWidth: day.isToday ? 3 : 0)
    }
    
    @ViewBuilder
    private var weatherOverlay: some View {
        #if !os(tvOS)
        if weatherInfo != nil || weatherForecast != nil {
            SmallWeatherIndicator(
                weatherInfo: weatherInfo,
                weatherForecast: weatherForecast,
                date: day.date,
                displayState: weatherDisplayState
            )
            .padding(.top, 2)
            .padding(.trailing, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        #endif
    }
    
    private func handleAppear() {
        #if !os(tvOS)
        if featureFlags.weatherIntegration {
            loadWeatherForDay()
            startWeatherRotation()
        }
        #endif
    }
    
    private func handleDisappear() {
        #if !os(tvOS)
        stopWeatherRotation()
        #endif
    }
    
    private func handleDateChange(_ newDate: Date) {
        #if !os(tvOS)
        if featureFlags.weatherIntegration {
            loadWeatherForDay()
        }
        #endif
    }
    
    private var accessibilityLabel: String {
        let dateString = day.date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        var label = dateString
        if day.isToday {
            label = "Today, ".localized + label
        }
        return label
    }
    
    private var accessibilityValue: String {
        var values: [String] = []
        
        if !holidaysOnThisDay.isEmpty {
            let holidayCount = holidaysOnThisDay.count
            if holidayCount == 1 {
                values.append("1 holiday".localized)
            } else {
                values.append("%d holidays".localized(with: holidayCount))
            }
            for holiday in holidaysOnThisDay {
                values.append(holiday.name)
            }
        }
        
        if !day.events.isEmpty {
            let eventCount = day.events.count
            if eventCount == 1 {
                values.append("1 event".localized)
            } else {
                values.append("%d events".localized(with: eventCount))
            }
            for event in day.events {
                values.append(event.title)
            }
        }
        
        if values.isEmpty {
            return "No events".localized
        }
        
        return values.joined(separator: ", ")
    }
    
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]
        if day.isSelected {
            traits = traits.union([.isSelected])
        }
        return traits
    }
    
    #if !os(tvOS)
    private func loadWeatherForDay() {
        let location = LocationApproximator.shared.approximateLocation()
        weatherManager.getWeatherForCoordinates(latitude: location.latitude, longitude: location.longitude, date: day.date) { weather in
            DispatchQueue.main.async {
                weatherInfo = weather
                // Restart rotation when weather data loads
                if weather != nil {
                    startWeatherRotation()
                }
            }
            
            // Try to get forecast for high/low temps (using coordinates directly, avoids geocoding)
            weatherManager.getWeatherForecastForCoordinates(latitude: location.latitude, longitude: location.longitude) { forecast in
                DispatchQueue.main.async {
                    weatherForecast = forecast
                    // Restart rotation when forecast loads
                    if forecast != nil {
                        startWeatherRotation()
                    }
                }
            }
        }
    }
    
    private func startWeatherRotation() {
        stopWeatherRotation()
        weatherRotationTask = Task { @MainActor in
            while !Task.isCancelled {
                // Rotate through states: icon -> high temp -> feels like (if available)
                weatherDisplayState = .icon
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                
                if Task.isCancelled { break }
                weatherDisplayState = .highTemp
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                
                if Task.isCancelled { break }
                // Only show feels like if we have that data (for now, skip it as we don't have it)
                // weatherDisplayState = .feelsLike
                // try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            }
        }
    }
    
    private func stopWeatherRotation() {
        weatherRotationTask?.cancel()
        weatherRotationTask = nil
    }
    #endif
    
    private var dayTextColor: Color {
        #if os(tvOS)
        // On tvOS, change text color if focused OR selected
        // Ensure proper date normalization to prevent false positives
        let calendar = Calendar(identifier: .gregorian)
        let normalizedFocusedDate = focusedDate.map { calendar.startOfDay(for: $0) }
        let normalizedDayDate = calendar.startOfDay(for: day.date)
        let isFocused = normalizedFocusedDate != nil && normalizedFocusedDate == normalizedDayDate
        if day.isSelected || isFocused {
            return monthlyPalette.calendarSurface
        } else if day.isToday {
            return monthlyPalette.accent
        } else if day.isCurrentMonth {
            return monthlyPalette.textPrimary
        } else {
            return monthlyPalette.textSecondary
        }
        #else
        if day.isSelected {
            return monthlyPalette.calendarSurface
        } else if day.isToday {
            return monthlyPalette.accent
        } else if day.isCurrentMonth {
            return monthlyPalette.textPrimary
        } else {
            return monthlyPalette.textSecondary
        }
        #endif
    }
    
    private var dayBackgroundColor: Color {
        #if os(tvOS)
        // On tvOS, show selection highlight, and subtle focus highlight when focused but not selected
        let calendar = Calendar(identifier: .gregorian)
        let normalizedFocusedDate = focusedDate.map { calendar.startOfDay(for: $0) }
        let normalizedDayDate = calendar.startOfDay(for: day.date)
        let isFocused = normalizedFocusedDate != nil && normalizedFocusedDate == normalizedDayDate
        
        if day.isSelected {
            // Selected date gets full highlight
            return monthlyPalette.selectedDay
        } else if isFocused && !day.isSelected {
            // Focused but not selected gets subtle highlight (distinct from selection)
            return monthlyPalette.surface.opacity(0.2)
        } else if day.isToday {
            return monthlyPalette.accent.opacity(0.15)
        } else if featureFlags.weekendTintingEnabled && isWeekend {
            // Apply subtle weekend tinting
            return monthlyPalette.surface.opacity(0.3)
        } else {
            return .clear
        }
        #else
        if day.isSelected {
            return monthlyPalette.selectedDay
        } else if day.isToday {
            return monthlyPalette.accent.opacity(0.15)
        } else if featureFlags.weekendTintingEnabled && isWeekend {
            // Apply subtle weekend tinting
            return monthlyPalette.surface.opacity(0.3)
        } else {
            return .clear
        }
        #endif
    }
    
    private var isWeekend: Bool {
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: day.date)
        // weekday 1 = Sunday, 7 = Saturday in Gregorian calendar
        return weekday == 1 || weekday == 7
    }
    
    private var dayFont: Font {
        let weight: Font.Weight = day.isToday ? .bold : .medium
        return .system(size: fontSize, weight: weight)
    }
    
#if os(tvOS)
    /// Returns a distinct color for event indicator based on index
    private func eventIndicatorColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue,
            .green,
            .orange,
            .purple,
            .red,
            .cyan,
            .pink,
            .yellow
        ]
        return colors[index % colors.count]
    }
#endif
}

private func gridLineWidth(for opacity: Double) -> CGFloat {
    // Scale from 1pt at 0% opacity to 5pt at 100% opacity, but cap at 3pt on iOS
    let maxWidth: CGFloat = {
#if os(iOS)
        return 3.0
#else
        return 5.0
#endif
    }()
    return min(1.0 + (opacity * 4.0), maxWidth)
}
