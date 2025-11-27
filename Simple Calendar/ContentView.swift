//
//  ContentView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// Import for daylight visualization
import Foundation
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    private let holidayManager = HolidayManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var showQuickAdd = false
    @State private var currentFontSize: Double = 14.0
    @State private var refreshTrigger: UUID = UUID()
    @FocusState private var focusedDate: Date?


    private var mainContentView: some View {
        ZStack {
            if calendarViewModel.viewMode == .agenda {
                AgendaView()
                    .overlay(
                        Group {
                            if calendarViewModel.showDayDetail, let selectedDate = calendarViewModel.selectedDate {
                                DayDetailSlideOut(date: selectedDate)
                                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calendarViewModel.showDayDetail)
                    )
                    .overlay(searchOverlay, alignment: .center)
                    .overlay(keyCommandsOverlay, alignment: .center)
            } else {
                mainCalendarView
                    .overlay(
                        Group {
                            if calendarViewModel.showDayDetail, let selectedDate = calendarViewModel.selectedDate {
                                DayDetailSlideOut(date: selectedDate)
                                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calendarViewModel.showDayDetail)
                    )
                    .overlay(searchOverlay, alignment: .center)
                    .overlay(keyCommandsOverlay, alignment: .center)
            }
        }
        .overlay(SettingsView())
        .sheet(isPresented: $calendarViewModel.showEventCreation) {
            EventCreationView()
        }
        .sheet(isPresented: $calendarViewModel.showEventTemplates) {
            EventTemplateSelector(selectedDate: calendarViewModel.selectedDate ?? Date())
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView(isPresented: $showQuickAdd)
        }
        .sheet(isPresented: $calendarViewModel.showViewModeSelector) {
            ViewModeSelectorView()
        }
        .sheet(isPresented: $calendarViewModel.showSettings) {
            SettingsContentView(showSettings: $calendarViewModel.showSettings, googleOAuthManager: calendarViewModel.googleOAuthManager ?? GoogleOAuthManager())
        }
        .roundedCorners(.small)
    }

    var body: some View {
        #if os(tvOS)
        // On tvOS, use full screen layout optimized for TV
        ZStack {
            // Full screen background
            themeManager.currentPalette.calendarBackground
                .ignoresSafeArea()

            // Content optimized for TV viewing
            mainContentView
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // Long press opens settings on tvOS
                    calendarViewModel.showSettings = true
                }
        )
        .onMoveCommand { direction in
            #if os(tvOS)
            guard shouldHandleMoveCommand(direction) else { return }
            #endif
            // Handle arrow key navigation on tvOS when focus can't move further
            switch direction {
            case .left:
                calendarViewModel.moveSelectedDate(.left)
            case .right:
                calendarViewModel.moveSelectedDate(.right)
            case .up:
                calendarViewModel.moveSelectedDate(.up)
            case .down:
                calendarViewModel.moveSelectedDate(.down)
            @unknown default:
                break
            }
        }
        .onExitCommand {
            // Back/Menu button opens settings on tvOS
            calendarViewModel.showSettings = true
        }
        .onPlayPauseCommand {
            // Play/Pause/Select button opens day detail view on tvOS
            if calendarViewModel.selectedDate != nil {
                calendarViewModel.toggleDayDetail()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ToggleDaylightVisualization)) { _ in
            FeatureFlags.shared.daylightVisualizationCalendar.toggle()
            FeatureFlags.shared.daylightVisualizationDayView.toggle()
        }
        .onAppear {
            calendarViewModel.navigateToToday()
            currentFontSize = uiConfig.dayNumberFontSize // Initialize with current value
            focusedDate = normalizedDate(calendarViewModel.selectedDate) // Initialize focus to selected date
        }
        .onChange(of: colorScheme) { newColorScheme in
            themeManager.currentColorScheme = newColorScheme
        }
        .onChange(of: uiConfig.dayNumberFontSize) { newFontSize in
            currentFontSize = newFontSize
            refreshTrigger = UUID()
        }
        .onChange(of: uiConfig.gridLineOpacity) { _ in
            refreshTrigger = UUID()
        }
        .onChange(of: focusedDate) { newFocusedDate in
            if let date = newFocusedDate {
                calendarViewModel.selectDate(date)
            }
        }
        .onChange(of: calendarViewModel.selectedDate) { newSelectedDate in
            guard let normalized = normalizedDate(newSelectedDate) else { return }
            if normalized != focusedDate {
                focusedDate = normalized
            }
        }
        .onChange(of: calendarViewModel.showDayDetail) { isShowing in
            if !isShowing, let normalized = normalizedDate(calendarViewModel.selectedDate) {
                DispatchQueue.main.async {
                    focusedDate = normalized
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RefreshCalendar)) { _ in
            calendarViewModel.refresh()
        }
        #elseif os(iOS)
        // On iOS, background extends edge to edge, content respects safe areas
        ZStack {
            // Full screen background that ignores safe areas
            themeManager.currentPalette.calendarBackground
                .ignoresSafeArea()

            // Content that respects safe areas
            mainContentView
        }
        .onReceive(NotificationCenter.default.publisher(for: .ToggleDaylightVisualization)) { _ in
            FeatureFlags.shared.daylightVisualizationCalendar.toggle()
            FeatureFlags.shared.daylightVisualizationDayView.toggle()
        }
        .onAppear {
            calendarViewModel.navigateToToday()
            currentFontSize = uiConfig.dayNumberFontSize // Initialize with current value
            focusedDate = normalizedDate(calendarViewModel.selectedDate) // Initialize focus to selected date
        }
        .onChange(of: colorScheme) { newColorScheme in
            themeManager.currentColorScheme = newColorScheme
        }
        .onChange(of: uiConfig.dayNumberFontSize) { newFontSize in
            currentFontSize = newFontSize
            refreshTrigger = UUID()
        }
        .onChange(of: uiConfig.gridLineOpacity) { _ in
            refreshTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleFullscreen"))) { _ in
            calendarViewModel.toggleFullscreen()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleSearch"))) { _ in
            calendarViewModel.toggleSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleKeyCommands"))) { _ in
            calendarViewModel.toggleKeyCommands()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ShowSettings"))) { _ in
            // Settings view handles this via its own state
        }
        .onReceive(NotificationCenter.default.publisher(for: .RefreshCalendar)) { _ in
            calendarViewModel.refresh()
        }
        #else
        // On macOS, use the original structure
        mainContentView
        .addKeyboardShortcuts()
        .onReceive(NotificationCenter.default.publisher(for: .ToggleDaylightVisualization)) { _ in
            FeatureFlags.shared.daylightVisualizationCalendar.toggle()
            FeatureFlags.shared.daylightVisualizationDayView.toggle()
        }
        .onAppear {
            calendarViewModel.navigateToToday()
            currentFontSize = uiConfig.dayNumberFontSize // Initialize with current value
            focusedDate = normalizedDate(calendarViewModel.selectedDate) // Initialize focus to selected date
        }
        .onChange(of: colorScheme) { newColorScheme in
            themeManager.currentColorScheme = newColorScheme
        }
        .onChange(of: uiConfig.dayNumberFontSize) { newFontSize in
            currentFontSize = newFontSize
            refreshTrigger = UUID()
        }
        .onChange(of: uiConfig.gridLineOpacity) { _ in
            refreshTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleFullscreen"))) { _ in
            calendarViewModel.toggleFullscreen()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleSearch"))) { _ in
            calendarViewModel.toggleSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ToggleKeyCommands"))) { _ in
            calendarViewModel.toggleKeyCommands()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ShowSettings"))) { _ in
            // Settings view handles this via its own state
        }
        .onReceive(NotificationCenter.default.publisher(for: .RefreshCalendar)) { _ in
            calendarViewModel.refresh()
        }
        #endif
    }

    private var mainCalendarView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                calendarHeader
                calendarGrid
            }
            .adaptivePadding(for: geometry)
            .background(themeManager.currentPalette.calendarBackground)
            #if os(iOS)
            .ignoresSafeArea(.keyboard) // Only ignore keyboard safe area, keep top/bottom safe areas
            #endif
        }
        #if os(tvOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #elseif os(iOS)
        .ignoresSafeArea(.container, edges: []) // Respect safe areas for calendar content
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    let threshold: CGFloat = 50

                    if abs(horizontalAmount) > abs(verticalAmount) {
                        // Horizontal swipe - navigate by day
                        if horizontalAmount > threshold {
                            // Swipe right - go to previous day
                            calendarViewModel.navigateDate(by: .day, direction: .backward)
                        } else if horizontalAmount < -threshold {
                            // Swipe left - go to next day
                            calendarViewModel.navigateDate(by: .day, direction: .forward)
                        }
                    } else {
                        // Vertical swipe - navigate by week or month
                        if calendarViewModel.viewMode == .month {
                            // In month view, vertical swipe navigates by month
                            if verticalAmount > threshold {
                                // Swipe down - go to previous month
                                calendarViewModel.navigateDate(by: .month, direction: .backward)
                            } else if verticalAmount < -threshold {
                                // Swipe up - go to next month
                                calendarViewModel.navigateDate(by: .month, direction: .forward)
                            }
                        } else {
                            // In other views, vertical swipe navigates by week
                            if verticalAmount > threshold {
                                // Swipe down - go to previous week
                                calendarViewModel.navigateDate(by: .week, direction: .backward)
                            } else if verticalAmount < -threshold {
                                // Swipe up - go to next week
                                calendarViewModel.navigateDate(by: .week, direction: .forward)
                            }
                        }
                    }
                }
        )
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    private var calendarHeader: some View {
        #if os(tvOS)
        // tvOS layout: centered month/year (settings accessible via long press)
        HStack(spacing: 0) {
            Spacer()

            // Month and year display
            monthYearDisplay

            Spacer()
        }
        .padding(.bottom, 30)
        .focusSection()
        #elseif os(iOS)
        // Custom iOS layout: gear | month | year
        HStack(spacing: 0) {
            // Settings gear button with specific positioning
            Button(action: {
                calendarViewModel.showSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 18, weight: .medium))  // Slightly larger
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
            .frame(width: 44, height: 44)  // Fixed size for consistent centering

            Spacer()

            // Month display with smaller font
            monthDisplaySmall

            Spacer()

            // Year display
            yearDisplay
                .frame(width: 44, alignment: .trailing)  // Match gear button width for symmetric spacing
        }
        .padding(.bottom, 20)
        #else
        // macOS layout: centered month/year display
        HStack {
            Spacer()
            monthYearDisplay
            Spacer()
        }
        .padding(.bottom, 20)
        #endif
    }

    private var monthYearDisplay: some View {
        ZStack {
            if calendarViewModel.viewMode == .year {
                // Year view: Show only the year centered
                HStack {
                    Spacer()
                    yearDisplay
                    Spacer()
                }
            } else {
                // Other views: Show month centered with year on right
                HStack {
                    Spacer()
                    yearDisplay
                }
                monthDisplay
            }
        }
        .frame(height: 60)
        .animation(.easeInOut(duration: 0.35), value: calendarViewModel.viewMode)
    }

    private var monthDisplay: some View {
        let monthName = calendarViewModel.currentDate.formatted(.dateTime.month(.wide))
        let font = monthFont(for: calendarViewModel.currentDate)

        return Text(monthName)
            .font(.custom(font, size: 32 * uiConfig.fontSizeCategory.scaleFactor))
            .fontWeight(.bold)
            .foregroundColor(themeManager.currentPalette.monthText)
            .onTapGesture {
                #if os(iOS)
                calendarViewModel.showViewModeSelector = true
                #else
                calendarViewModel.toggleYearView()
                #endif
            }
    }

    private var monthDisplaySmall: some View {
        let monthName = calendarViewModel.currentDate.formatted(.dateTime.month(.wide))
        let font = monthFont(for: calendarViewModel.currentDate)

        return Text(monthName)
            .font(.custom(font, size: 24 * uiConfig.fontSizeCategory.scaleFactor))  // Smaller font for iOS header
            .fontWeight(.bold)
            .foregroundColor(themeManager.currentPalette.monthText)
            .onTapGesture {
                calendarViewModel.showViewModeSelector = true
            }
    }

    private var yearDisplay: some View {
        let year = Calendar.current.component(.year, from: calendarViewModel.currentDate)
        let clampedYear = max(-6000, min(9999, year))
        return Text(String(clampedYear))
            .font(uiConfig.yearTitleFont)
            .foregroundColor(themeManager.currentPalette.yearText)
            .lineLimit(1) // Ensure it never wraps to multiple lines
    }

    private var calendarGrid: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: daysPerRow)
            let days = generateCalendarDays()

            // Calculate available height for calendar content
            let headerHeight: CGFloat = calendarViewModel.viewMode == .year ? 0 : 32 // Header height + spacing
            #if os(iOS)
            // On iOS, use safe area insets to ensure calendar fits within safe area
            let topSafeArea = geometry.safeAreaInsets.top
            let bottomSafeArea = geometry.safeAreaInsets.bottom
            let availableHeight = geometry.size.height - headerHeight - 32 - topSafeArea - bottomSafeArea
            #else
            let availableHeight = geometry.size.height - headerHeight - 32 // Subtract padding
            #endif
            let rowsCount = calculateRowsCount(for: days.count, columns: daysPerRow)
            #if os(tvOS)
            let cellHeight = availableHeight / CGFloat(rowsCount) // Let rows expand to fill available space on tvOS
            #else
            let cellHeight = max(availableHeight / CGFloat(rowsCount), 60) // Minimum height of 60
            #endif

            VStack(spacing: 8) {
                // Headers (only for non-year views)
                if calendarViewModel.viewMode != .year {
                    let totalSpacing = CGFloat(daysPerRow - 1) * 8 // Spacing between columns
                    let horizontalPadding: CGFloat = 16 // Approximate horizontal padding
                    let availableWidth = geometry.size.width - horizontalPadding * 2 - totalSpacing
                    let widthPerColumn = max(availableWidth / CGFloat(daysPerRow), 30) // Minimum 30pt width

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<daysPerRow, id: \.self) { index in
                            Text(dayName(for: index, availableWidth: widthPerColumn))
                                #if os(tvOS)
                                .font(.system(size: 16, weight: .medium)) // Even smaller font for tvOS
                                .minimumScaleFactor(0.5) // Allow more scaling down to fit
                                .lineLimit(1)
                                #else
                                .font(uiConfig.dayNameFont)
                                #endif
                                .foregroundColor(themeManager.currentPalette.dayNameText)
                                .frame(height: 24)
                        }
                    }
                    .padding(.horizontal)
                }

                // Calendar content
                LazyVGrid(columns: columns, spacing: 8) {
                    if calendarViewModel.viewMode == .year {
                        // Year view: show mini months
                        ForEach(days.indices, id: \.self) { index in
                            let day = days[index]
                            #if os(tvOS)
                            Button(action: {
                                // Switch to month view for the selected month
                                calendarViewModel.currentDate = day.date
                                calendarViewModel.setViewMode(.month)
                            }) {
                                MonthMiniView(monthDate: day.date, geometry: geometry)
                                    .frame(height: cellHeight)
                            }
                            .buttonStyle(.borderless)
                            #else
                            MonthMiniView(monthDate: day.date, geometry: geometry)
                                .frame(height: cellHeight)
                                .onTapGesture {
                                    // Switch to month view for the selected month
                                    calendarViewModel.currentDate = day.date
                                    calendarViewModel.setViewMode(.month)
                                }
                            #endif
                        }
                    } else {
                        // Regular views: show day cells
                        ForEach(days) { day in
                            #if os(tvOS)
                            Button(action: {
                                // Ensure the currently activated tile becomes the selected date before showing detail
                                calendarViewModel.selectDate(day.date)
                                calendarViewModel.toggleDayDetail()
                            }) {
                                DayView(day: day, geometry: geometry, cellHeight: cellHeight, columnsCount: daysPerRow, fontSize: currentFontSize)
                            }
                            .buttonStyle(.borderless)
                            .focused($focusedDate, equals: day.date)
                            #else
                            DayView(day: day, geometry: geometry, cellHeight: cellHeight, columnsCount: daysPerRow, fontSize: currentFontSize)
                                .onTapGesture(count: 2) {
                                    handleDayDoubleClick(day.date)
                                }
                                .onTapGesture(count: 1) {
                                    calendarViewModel.selectDate(day.date)
                                }
                                .simultaneousGesture(
                                    TapGesture(count: 1)
                                        .onEnded {
                                            calendarViewModel.selectDate(day.date)
                                        }
                                )
                                .contextMenu {
                                    Button(action: {
                                        calendarViewModel.selectedDate = day.date
                                        calendarViewModel.showEventCreation = true
                                    }) {
                                        Label("Create Event", systemImage: "plus")
                                    }

                                    Button(action: {
                                        calendarViewModel.selectedDate = day.date
                                        calendarViewModel.showEventTemplates = true
                                    }) {
                                        Label("Quick Create", systemImage: "sparkles")
                                    }

                                    Divider()

                                    if !day.events.isEmpty {
                                        Button(action: {
                                            exportDayEvents(day.events)
                                        }) {
                                            Label("Export Events", systemImage: "square.and.arrow.up")
                                        }
                                    }

                                    Button(action: {
                                        calendarViewModel.selectDate(day.date)
                                        calendarViewModel.setViewMode(.singleDay)
                                    }) {
                                        Label("View Day", systemImage: "calendar")
                                    }
                                }
                            #endif
                        }
                    }
                }
                .padding(.horizontal)
                #if os(iOS)
                .animation(.easeInOut(duration: 0.3), value: calendarViewModel.selectionAnimationId)
                #endif
            }
            .animation(.easeInOut(duration: 0.35), value: calendarViewModel.viewMode)
            .animation(.easeInOut(duration: 0.35), value: calendarViewModel.currentDate)
        }
    }

    private func calculateRowsCount(for itemCount: Int, columns: Int) -> Int {
        return (itemCount + columns - 1) / columns // Ceiling division
    }

    private func normalizedDate(_ date: Date?) -> Date? {
        guard let date else { return nil }
        return Calendar.current.startOfDay(for: date)
    }

    #if os(tvOS)
    private func shouldHandleMoveCommand(_ direction: MoveCommandDirection) -> Bool {
        // If nothing is focused, we must handle navigation manually
        if focusedDate == nil {
            return true
        }

        // Only need manual handling for month view edges; other views rely on default focus movement
        guard calendarViewModel.viewMode == .month,
              let selectedDate = calendarViewModel.selectedDate else {
            return false
        }

        let calendar = Calendar.current
        let days = generateCalendarDays()
        guard let index = days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) else {
            return false
        }

        let columns = daysPerRow
        switch direction {
        case .up:
            return index < columns
        case .down:
            return index >= days.count - columns
        default:
            return false
        }
    }
    #endif

    private var searchOverlay: some View {
        Group {
            if calendarViewModel.showSearch {
                ZStack {
                    // Blurred background
                    Color.black.opacity(0.3)
                        .blur(radius: 10)
                        .ignoresSafeArea()

                    SearchView(searchText: $searchText)
                        .frame(width: 400, height: 60)
                        .background(themeManager.currentPalette.calendarSurface.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var keyCommandsOverlay: some View {
        Group {
            if calendarViewModel.showKeyCommands {
                ZStack {
                    // Blurred background
                    Color.black.opacity(0.3)
                        .blur(radius: 10)
                        .ignoresSafeArea()

                    KeyCommandsView()
                        .frame(width: 400, height: 500)
                        .background(themeManager.currentPalette.calendarSurface.opacity(0.95))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var daysPerRow: Int {
        switch calendarViewModel.viewMode {
        case .month:
            return 7
        case .year:
            return 3 // 3 months per row for year view
        case .twoWeeks:
            return 7
        default:
            return min(calendarViewModel.viewMode.dayCount, 7)
        }
    }

    private func generateCalendarDays() -> [CalendarDay] {
        let currentMonth = calendarViewModel.currentDate

        var days: [CalendarDay] = []

        switch calendarViewModel.viewMode {
        case .month:
            days = generateMonthDays(for: currentMonth)
        case .year:
            days = generateYearDays(for: currentMonth)
        case .sevenDays:
            days = generateWeekDays(for: currentMonth)
        case .twoWeeks:
            days = generateTwoWeekDays(for: currentMonth)
        default:
            days = generateDayRangeDays(for: currentMonth, days: calendarViewModel.viewMode.dayCount)
        }

        return days
    }

    private func generateYearDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        var days: [CalendarDay] = []

        // Create one representative day for each month
        for month in 1...12 {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1

            if let monthDate = calendar.date(from: components) {
                let calendarDay = CalendarDay(
                    id: monthDate,
                    date: monthDate,
                    isToday: false,
                    isSelected: false,
                    events: [], // Year view doesn't show events
                    isCurrentMonth: true
                )
                days.append(calendarDay)
            }
        }

        return days
    }

    private func generateMonthDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)

        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth),
              let firstDayOfMonth = calendar.date(from: components) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Add days from previous month to fill the first week
        var daysFromPreviousMonth = firstWeekday - calendar.firstWeekday
        // Ensure daysFromPreviousMonth is between 0 and 6
        if daysFromPreviousMonth < 0 {
            daysFromPreviousMonth += 7
        }
        daysFromPreviousMonth = min(daysFromPreviousMonth, 6)

        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
              let daysInPreviousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth) else {
            return []
        }

        let daysInPreviousMonth = daysInPreviousMonthRange.count
        var days: [CalendarDay] = []

        // Previous month days (only if we need to fill the week)
        if daysFromPreviousMonth > 0 {
            let startDay = max(1, daysInPreviousMonth - daysFromPreviousMonth + 1)
            for i in startDay...daysInPreviousMonth {
                if let date = calendar.date(bySetting: .day, value: i, of: previousMonth) {
                    days.append(createCalendarDay(for: date, isCurrentMonth: false))
                }
            }
        }

        // Current month days
        for day in 1...range.count {
            if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                days.append(createCalendarDay(for: date, isCurrentMonth: true))
            }
        }

        // Next month days to fill the last week
        let remainingCells = (7 - (days.count % 7)) % 7

        // Only add next month days if we need to fill the week
        if remainingCells > 0 {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                return days
            }

            for day in 1...remainingCells {
                if let date = calendar.date(bySetting: .day, value: day, of: nextMonth) {
                    days.append(createCalendarDay(for: date, isCurrentMonth: false))
                }
            }
        }

        return days
    }

    private func generateTwoWeekDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }

        var days: [CalendarDay] = []
        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else {
                continue
            }
            days.append(createCalendarDay(for: date, isCurrentMonth: true))
        }

        return days
    }

    private func generateWeekDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let referenceDate = calendarViewModel.selectedDate ?? date

        // Find the start of the week containing the reference date
        // Use the localized first weekday (1 = Sunday in US, 2 = Monday in most other locales)
        let weekday = calendar.component(.weekday, from: referenceDate)
        let firstWeekday = calendar.firstWeekday
        let daysToSubtract = (weekday - firstWeekday + 7) % 7

        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: referenceDate) else {
            return []
        }

        var calendarDays: [CalendarDay] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekStart) else {
                continue
            }
            calendarDays.append(createCalendarDay(for: date, isCurrentMonth: true))
        }

        return calendarDays
    }

    private func generateDayRangeDays(for date: Date, days: Int) -> [CalendarDay] {
        let calendar = Calendar.current
        let startDate = calendarViewModel.selectedDate ?? date

        var calendarDays: [CalendarDay] = []
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else {
                continue
            }
            calendarDays.append(createCalendarDay(for: date, isCurrentMonth: true))
        }

        return calendarDays
    }

    private func createCalendarDay(for date: Date, isCurrentMonth: Bool) -> CalendarDay {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: date)

        let events = calendarViewModel.events.filter { event in
            let eventStart = calendar.startOfDay(for: event.startDate)
            return eventStart == dayStart
        }

        return CalendarDay(
            id: date,
            date: date,
            isToday: dayStart == today,
            isSelected: calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == dayStart } ?? false,
            events: events,
            isCurrentMonth: isCurrentMonth
        )
    }

    private func handleDayDoubleClick(_ date: Date) {
        if calendarViewModel.viewMode != .singleDay {
            calendarViewModel.selectDate(date)
            calendarViewModel.toggleDayDetail()
        } else if calendarViewModel.selectedDate == date {
            calendarViewModel.toggleDayDetail()
        }
    }

    private func monthFont(for date: Date) -> String {
        let month = Calendar.current.component(.month, from: date)
        let fonts = [
            "Arial", "Helvetica", "Times New Roman", "Courier", "Georgia",
            "Verdana", "Trebuchet MS", "Impact", "Comic Sans MS", "Lucida Grande",
            "Futura", "Baskerville"
        ]
        return fonts[(month - 1) % fonts.count]
    }

    private func exportDayEvents(_ events: [CalendarEvent]) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: calendarViewModel.selectedDate ?? Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        if let fileURL = EventExporter.exportEventsInDateRange(startDate: startOfDay, endDate: endOfDay, events: events) {
#if os(macOS)
            let sharingService = NSSharingServicePicker(items: [fileURL])
            if let window = NSApplication.shared.windows.first {
                sharingService.show(relativeTo: NSRect.zero, of: window.contentView!, preferredEdge: .minY)
            }
#endif
        }
    }
}

struct DayView: View {
    let day: CalendarDay
    let geometry: GeometryProxy
    let cellHeight: CGFloat
    let columnsCount: Int
    let fontSize: Double
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared
    private let holidayManager = HolidayManager.shared

    private var monthlyPalette: ColorPalette {
        if featureFlags.monthlyThemesEnabled {
            let month = Calendar.current.component(.month, from: day.date)
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
        return holidayManager.holidaysOn(day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 1 : 2) {
            Text(day.date.formatted(.dateTime.day()))
                .font(.system(size: fontSize, weight: isCompactLayout ?
                             (day.isToday ? .bold : .medium) :
                             (day.isToday ? .bold : .medium)))
                .foregroundColor(dayTextColor)
                #if !os(tvOS)
                .minimumScaleFactor(0.5) // Allow font to scale down to 50% of original size on iOS/macOS
                #endif
                .lineLimit(1) // Ensure single line
                .frame(maxWidth: .infinity, alignment: .leading)
                #if os(tvOS)
                .frame(minHeight: fontSize * 1.2) // Ensure minimum height for date number on tvOS
                #endif

            // Show event details with compact representation for narrow cells
            #if os(tvOS)
            // tvOS: Show holidays AND events - tvOS doesn't have EventKit so holidays are primary
            let hasContent = !day.events.isEmpty || !holidaysOnThisDay.isEmpty
            
            if hasContent {
                Spacer(minLength: 4) // Push content to middle area
                
                VStack(alignment: .center, spacing: 6) {
                    // Show holiday emojis prominently (these are visible on tvOS!)
                    // Limit to 2 holidays on tvOS for better visibility in detail view
                    if !holidaysOnThisDay.isEmpty {
                        let displayedHolidays = holidaysOnThisDay.prefix(2)
                        HStack(spacing: 8) {
                            ForEach(Array(displayedHolidays)) { holiday in
                                Text(holiday.emoji)
                                    .font(.system(size: 36)) // Large emoji for TV visibility
                            }
                        }
                        
                        // Show holiday name if only one
                        if holidaysOnThisDay.count == 1, let holiday = holidaysOnThisDay.first {
                            Text(holiday.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(monthlyPalette.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.4)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if holidaysOnThisDay.count > 1 {
                            Text("\(holidaysOnThisDay.count) holidays")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(monthlyPalette.accent)
                        }
                    }
                    
                    // Show event indicators if any events exist
                    if !day.events.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(day.events.prefix(4).enumerated()), id: \.offset) { index, event in
                                if let emoji = EventIconManager.emojiForEvent(event.title) {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                } else {
                                    Circle()
                                        .fill(eventIndicatorColor(for: index))
                                        .frame(width: 20, height: 20)
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
                            Text("\(day.events.count) events")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(monthlyPalette.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer(minLength: 4) // Bottom spacer
            #else
            if !isCompactLayout {
                ForEach(day.events.prefix(maxEventsToShow)) { event in
                    Text(event.title)
                        .font(uiConfig.captionFont)
                        .lineLimit(1)
                        .foregroundColor(monthlyPalette.textSecondary)
                }

                if day.events.count > maxEventsToShow {
                    Text("+\(day.events.count - maxEventsToShow) more")
                        .font(uiConfig.smallCaptionFont)
                        .foregroundColor(monthlyPalette.textSecondary)
                }

                // Show holidays if enabled
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
            } else {
                // In compact layout, show compact representations
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

                // Show holidays in compact layout if enabled
                if featureFlags.holidayDisplayEnabled && !holidaysOnThisDay.isEmpty && isCompactLayout {
                    HStack(spacing: 1) {
                        ForEach(holidaysOnThisDay.prefix(2)) { holiday in
                            Text(holiday.emoji)
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            #endif // End iOS/macOS conditional

            #if !os(tvOS)
            Spacer()
            #endif
        }
        .compactPadding()
        .frame(height: cellHeight)
        .background(
            ZStack {
                dayBackgroundColor
                // Daylight visualization at the top (only if enabled)
                if featureFlags.daylightVisualizationCalendar {
                    VStack(spacing: 0) {
                        DaylightVisualizationView(date: day.date, width: geometry.size.width / CGFloat(columnsCount))
                        Spacer()
                    }
                }
            }
        )
        .roundedCorners(.small)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(monthlyPalette.gridLine.opacity(uiConfig.gridLineOpacity),
                       lineWidth: gridLineWidth(for: uiConfig.gridLineOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(day.isToday ? monthlyPalette.accent : Color.clear, lineWidth: day.isToday ? 3 : 0)
        )
        .animation(.easeInOut(duration: 0.2), value: day.isSelected)
    }

    private var dayTextColor: Color {
        if day.isSelected {
            return monthlyPalette.calendarSurface
        } else if day.isToday {
            return monthlyPalette.accent
        } else if day.isCurrentMonth {
            return monthlyPalette.textPrimary
        } else {
            return monthlyPalette.textSecondary
        }
    }

    private var dayBackgroundColor: Color {
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
    }

    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: day.date)
        // weekday 1 = Sunday, 7 = Saturday in Gregorian calendar
        return weekday == 1 || weekday == 7
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

struct DayDetailView: View {
    let date: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var onThisDayService = OnThisDayService.shared
    private let holidayManager = HolidayManager.shared
    @State private var onThisDayData: OnThisDayData?
    @State private var isLoadingOnThisDay = false
    @State private var onThisDayError: Error?

    private func groupDuplicateEvents(_ events: [CalendarEvent]) -> [[CalendarEvent]] {
        var groupedEvents: [[CalendarEvent]] = []
        var processedEvents = Set<String>()

        for event in events {
            let eventKey = "\(event.title)_\(event.startDate.timeIntervalSince1970)_\(event.endDate.timeIntervalSince1970)"

            if !processedEvents.contains(eventKey) {
                let duplicates = events.filter { otherEvent in
                    otherEvent.title == event.title &&
                    otherEvent.startDate == event.startDate &&
                    otherEvent.endDate == event.endDate
                }
                groupedEvents.append(duplicates)
                processedEvents.insert(eventKey)
            }
        }

        return groupedEvents.sorted { $0.first!.startDate < $1.first!.startDate }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Vertical daylight visualization (left side)
            if featureFlags.daylightVisualizationDayView {
                VerticalDaylightVisualizationView(date: date)
                    .frame(width: 30)
                    .frame(maxHeight: .infinity)
            }

            // Main content (right side)
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(uiConfig.scaledFont(16, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                        Text(date.formatted(.dateTime.month(.wide).day().year()))
                            .font(uiConfig.scaledFont(28, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                    }
                    Spacer()
                    #if !os(tvOS)
                    Button(action: { calendarViewModel.toggleDayDetail() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    #endif
                }
                .standardPadding()

            ScrollViewWithFade {
                VStack(alignment: .leading, spacing: 16) {
                    let dayEvents = calendarViewModel.events.filter { event in
                        Calendar.current.isDate(event.startDate, inSameDayAs: date)
                    }

                    let holidaysOnThisDay = featureFlags.holidayDisplayEnabled ? holidayManager.holidaysOn(date) : []

                    let groupedEvents = groupDuplicateEvents(dayEvents)

                    // Show holidays at the top if enabled
                    // Limit to 2 holidays on tvOS for better visibility in detail view
                    if !holidaysOnThisDay.isEmpty {
                        #if os(tvOS)
                        let displayedHolidays = Array(holidaysOnThisDay.prefix(2))
                        #else
                        let displayedHolidays = holidaysOnThisDay
                        #endif
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayedHolidays) { holiday in
                                #if os(tvOS)
                                // tvOS: Holiday name at top, HUGE emoji beneath, then description
                                VStack(spacing: 16) {
                                    // Holiday name at top
                                    Text(holiday.name)
                                        .font(.system(size: 42, weight: .bold))
                                        .foregroundColor(themeManager.currentPalette.accent)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    // HUGE emoji beneath the name
                                    Text(holiday.emoji)
                                        .font(.system(size: 160)) // Massive emoji for TV viewing
                                    
                                    // Description beneath the emoji
                                    Text(holiday.description)
                                        .font(.system(size: 28, weight: .regular))
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .padding(.vertical, 24)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(themeManager.currentPalette.surface.opacity(0.7))
                                .cornerRadius(16)
                                #else
                                // iOS/macOS: Original horizontal layout
                                HStack(spacing: 8) {
                                    Text(holiday.emoji)
                                        .font(.system(size: 16))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(holiday.name)
                                            .font(uiConfig.eventTitleFont)
                                            .foregroundColor(themeManager.currentPalette.accent)
                                        Text(holiday.description)
                                            .font(uiConfig.captionFont)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(themeManager.currentPalette.surface.opacity(0.7))
                                .cornerRadius(8)
                                #endif
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    if dayEvents.isEmpty && holidaysOnThisDay.isEmpty {
                        Text("No events for this day")
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                            .font(uiConfig.eventDetailFont)
                            .standardPadding()
                    } else {
                        ForEach(Array(groupedEvents.enumerated()), id: \.offset) { index, eventGroup in
                            if eventGroup.count > 1 {
                                // Multiple instances of the same event
                                VStack(alignment: .leading, spacing: 4) {
                                    EventDetailView(event: eventGroup.first!)
                                    Text("+\(eventGroup.count - 1) more occurrence\(eventGroup.count > 2 ? "s" : "")")
                                        .font(uiConfig.captionFont)
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                        .padding(.leading, 16)
                                }
                            } else {
                                EventDetailView(event: eventGroup.first!)
                            }
                        }
                    }

                    // Astronomical Information section (tvOS only)
                    #if os(tvOS)
                    AstronomicalInfoSection(date: date, eventCount: dayEvents.count + holidaysOnThisDay.count)
                    #endif

                    // On This Day section
                    if featureFlags.onThisDayEnabled {
                        OnThisDaySection(
                            date: date,
                            data: onThisDayData,
                            isLoading: isLoadingOnThisDay,
                            error: onThisDayError
                        )
                    }
                }
            }
            .task {
                if featureFlags.onThisDayEnabled {
                    await loadOnThisDayData()
                }
            }
            }
        }
    }

    private func loadOnThisDayData() async {
        guard featureFlags.onThisDayEnabled else { return }

        isLoadingOnThisDay = true
        defer { isLoadingOnThisDay = false }

        do {
            onThisDayData = try await onThisDayService.fetchData(for: date)
        } catch {
            onThisDayError = error
            print("Failed to load On This Day data: \(error.localizedDescription)")
        }
    }
}

struct OnThisDaySection: View {
    let date: Date
    let data: OnThisDayData?
    let isLoading: Bool
    let error: Error?

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On This Day")
                    .font(uiConfig.eventTitleFont)
                    .foregroundColor(themeManager.currentPalette.textPrimary)

                Spacer()

                Text("Data from Wikipedia")
                    .font(uiConfig.captionFont)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if error != nil {
                Text("Unable to load historical data")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .font(uiConfig.eventDetailFont)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let data = data, data.hasContent {
                VStack(alignment: .leading, spacing: 16) {
                    if !data.holidays.isEmpty {
                        OnThisDayCategoryView(
                            title: "Holidays & Observances",
                            icon: "calendar",
                            items: data.holidays.map { $0.text },
                            color: .orange
                        )
                    }

                    if !data.events.isEmpty {
                        OnThisDayCategoryView(
                            title: "Historical Events",
                            icon: "clock",
                            items: data.events.map { $0.text },
                            color: .blue
                        )
                    }

                    if !data.births.isEmpty {
                        OnThisDayCategoryView(
                            title: "Notable Births",
                            icon: "person",
                            items: data.births.map { $0.text },
                            color: .green
                        )
                    }

                    if !data.deaths.isEmpty {
                        OnThisDayCategoryView(
                            title: "Notable Deaths",
                            icon: "person.crop.circle.badge.xmark",
                            items: data.deaths.map { $0.text },
                            color: .gray
                        )
                    }
                }
            } else {
                Text("No historical data available for this date")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .font(uiConfig.eventDetailFont)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.currentPalette.surface.opacity(0.5))
        .cornerRadius(CornerRadius.medium.value)
        .padding(.horizontal)
    }
}

struct OnThisDayCategoryView: View {
    let title: String
    let icon: String
    let items: [String]
    let color: Color

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(uiConfig.eventDetailFont)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }

            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(uiConfig.eventDetailFont)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

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
                HStack(spacing: 16) {
                    // Daylight Duration
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text("Daylight")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        Text(data.daylightDuration)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.currentPalette.surface.opacity(0.7))
                    .cornerRadius(12)
                    
                    // Night Duration
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.indigo)
                            Text("Night")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        Text(data.nightDuration)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.currentPalette.surface.opacity(0.7))
                    .cornerRadius(12)
                }
                
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
                                label: "Astronomical Twilight Begins",
                                time: data.astronomicalTwilightStart,
                                color: .purple
                            )
                            
                            TwilightTransitionRow(
                                label: "Nautical Twilight Begins",
                                time: data.nauticalTwilightStart,
                                color: .blue
                            )
                            
                            TwilightTransitionRow(
                                label: "Civil Twilight Begins",
                                time: data.civilTwilightStart,
                                color: .cyan
                            )
                            
                            TwilightTransitionRow(
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
                                label: "Sunset",
                                time: data.sunset,
                                color: .orange
                            )
                            
                            TwilightTransitionRow(
                                label: "Civil Twilight Ends",
                                time: data.civilTwilightEnd,
                                color: .cyan
                            )
                            
                            TwilightTransitionRow(
                                label: "Nautical Twilight Ends",
                                time: data.nauticalTwilightEnd,
                                color: .blue
                            )
                            
                            TwilightTransitionRow(
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
    
    private func calculateAstronomicalData() -> AstronomicalData? {
        let latitude = location.latitude
        let longitude = location.longitude
        
        guard let sunrise = daylightManager.sunriseTime(for: date, latitude: latitude, longitude: longitude),
              let sunset = daylightManager.sunsetTime(for: date, latitude: latitude, longitude: longitude) else {
            return nil
        }
        
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
        let calendar = Calendar.current
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
            nightDuration: nightDuration,
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
    let nightDuration: String
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
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
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

struct EventDetailView: View {
    let event: CalendarEvent
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @State private var eventImage: PlatformImage?
    @State private var weatherInfo: WeatherInfo?

    private var isAllDayEvent: Bool {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return hours >= 20 || event.isAllDay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event Image
            if let image = eventImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(platformImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)

                    // Attribution overlay
                    if UserDefaults.standard.bool(forKey: "showUnsplashAttribution"),
                       let metadata = calendarViewModel.getImageMetadataForEvent(event) {
                        Text("Photo by \(metadata.author)")
                            .font(.caption2)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                            .padding(6)
                            .background(themeManager.currentPalette.surface.opacity(0.9))
                            .cornerRadius(4)
                            .padding(4)
                    }
                }
            }

            #if os(tvOS)
            // tvOS: Always show event title at top
            Text(event.title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            // tvOS: HUGE emoji/icon BENEATH the title text
            VStack(spacing: 20) {
                // Huge emoji (144pt+) positioned beneath title
                if let eventEmoji = EventIconManager.emojiForEvent(event.title) {
                    Text(eventEmoji)
                        .font(.system(size: 160)) // Extra large for TV viewing
                } else {
                    // Fallback: Large clock icon
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 120))
                        .foregroundColor(themeManager.currentPalette.accent)
                }

                // Time information beneath the icon
                if isAllDayEvent {
                    Text("All Day")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                } else {
                    HStack(spacing: 40) {
                        VStack(spacing: 6) {
                            Text("Starts")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        
                        // Arrow separator
                        Image(systemName: "arrow.right")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.currentPalette.accent)
                        
                        VStack(spacing: 6) {
                            Text("Ends")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.endDate.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            #else
            Text(event.title)
                .font(uiConfig.eventTitleFont)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentPalette.textPrimary)
            #endif

            #if !os(tvOS)
            // iOS/macOS: Icon inline with text
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                if isAllDayEvent {
                    Text("All Day")
                        .font(uiConfig.eventDetailFont)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Starts:")
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Text("Ends:")
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.endDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                    }
                }
            }
            #endif

            if let location = event.location {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    Text(location)
                        .font(uiConfig.eventDetailFont)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                }

                // Map view for events with location
                EventMapView(location: location)
                    .frame(height: 100)
                    .cornerRadius(8)

                // Weather info for events with location
                if let weather = weatherInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weather Forecast")
                            .font(uiConfig.eventDetailFont)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        HStack {
                            Image(systemName: weather.icon)
                                .foregroundColor(themeManager.currentPalette.accent)
                            Text(weather.temperatureString)
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text(weather.condition)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }

                        HStack(spacing: 16) {
                            Label(weather.humidityString, systemImage: "humidity")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Label(weather.windSpeedString, systemImage: "wind")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                        .font(uiConfig.captionFont)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity) // Match map view width
                    .background(themeManager.currentPalette.surface.opacity(0.5))
                    .roundedCorners(.small)
                }
            }

            if let notes = event.notes {
                URLTextView(text: notes)
                    .font(uiConfig.scaledFont(.body))
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
        .standardPadding()
        .background(themeManager.currentPalette.calendarSurface)
        .roundedCorners(.normal)
        .padding(.horizontal)
        .onAppear {
            loadEventImage()
            loadWeatherInfo()
        }
    }

    private func loadEventImage() {
        if let imageId = event.imageRepositoryId {
            eventImage = ImageManager.shared.getImage(for: imageId)
        } else {
            // Try to fetch an image for this event
            ImageManager.shared.findOrFetchImage(for: event) { imageId in
                if let imageId = imageId {
                    DispatchQueue.main.async {
                        self.eventImage = ImageManager.shared.getImage(for: imageId)
                    }
                }
            }
        }
    }

    private func loadWeatherInfo() {
        WeatherManager.shared.getWeatherForEvent(event) { weather in
            DispatchQueue.main.async {
                self.weatherInfo = weather
            }
        }
    }
}

struct SearchView: View {
    @Binding var searchText: String
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var searchResults: [CalendarEvent] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedSearch = searchText.lowercased()
        return calendarViewModel.events.filter { event in
            event.title.lowercased().contains(lowercasedSearch) ||
            (event.location?.lowercased().contains(lowercasedSearch) ?? false) ||
            (event.notes?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                TextField("Search events or dates", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .focused($isSearchFocused)
                Button(action: { calendarViewModel.toggleSearch() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
            }
            .padding()

            if !searchText.isEmpty {
                ScrollViewWithFade {
                    VStack(alignment: .leading, spacing: 8) {
                        if searchResults.isEmpty {
                            Text("No events found")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .padding()
                        } else {
                            ForEach(searchResults) { event in
                                SearchResultRow(event: event)
                                    .onTapGesture {
                                        calendarViewModel.selectDate(event.startDate)
                                        calendarViewModel.toggleSearch()
                                        calendarViewModel.toggleDayDetail()
                                    }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    @FocusState private var isSearchFocused: Bool
}

struct SearchResultRow: View {
    let event: CalendarEvent
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .foregroundColor(themeManager.currentPalette.textPrimary)

            HStack {
                Text(event.startDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)

                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            if let location = event.location {
                Text(location)
                    .font(.caption)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .padding(.horizontal)
    }
}

struct MonthMiniView: View {
    let monthDate: Date
    let geometry: GeometryProxy
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared

    private var monthlyPalette: ColorPalette {
        if featureFlags.monthlyThemesEnabled {
            let month = Calendar.current.component(.month, from: monthDate)
            let monthlyTheme = monthlyThemeManager.theme(for: month)
            return monthlyTheme.palette(for: themeManager.currentColorScheme)
        } else {
            return themeManager.currentPalette
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Month name
            Text(monthDate.formatted(.dateTime.month(.wide)))
                .font(uiConfig.captionFont)
                .fontWeight(.semibold)
                .foregroundColor(monthlyPalette.textPrimary)

            // Mini calendar grid
            let monthDays = generateMiniMonthDays(for: monthDate)
            let miniColumns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

            LazyVGrid(columns: miniColumns, spacing: 1) {
                ForEach(monthDays) { day in
                    Text(day.date.formatted(.dateTime.day()))
                        .font(.system(size: 8))
                        .foregroundColor(day.isCurrentMonth ?
                            (day.isToday ? monthlyPalette.accent : monthlyPalette.textPrimary) :
                            monthlyPalette.textSecondary.opacity(0.5))
                        .frame(width: 12, height: 12)
                        .background(day.isToday ? monthlyPalette.accent.opacity(0.2) : Color.clear)
                        .cornerRadius(2)
                }
            }
        }
        .padding(6)
        .background(monthlyPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small.value))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(monthlyPalette.gridLine, lineWidth: 0.5)
        )
    }

    private func generateMiniMonthDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)

        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysFromPreviousMonth = firstWeekday - calendar.firstWeekday
        let totalCells = 42 // 6 weeks * 7 days for consistent mini calendar size

        var days: [CalendarDay] = []

        // Previous month days
        if daysFromPreviousMonth > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count

            for i in (daysInPreviousMonth - daysFromPreviousMonth + 1)...daysInPreviousMonth {
                if let date = calendar.date(bySetting: .day, value: i, of: previousMonth) {
                    let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == calendar.startOfDay(for: date) } ?? false
                    days.append(CalendarDay(id: date, date: date, isToday: false, isSelected: isSelected, events: [], isCurrentMonth: false))
                }
            }
        }

        // Current month days
        for day in 1...range.count {
            if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == calendar.startOfDay(for: date) } ?? false
                days.append(CalendarDay(id: date, date: date, isToday: isToday, isSelected: isSelected, events: [], isCurrentMonth: true))
            }
        }

        // Next month days to fill the grid
        let remainingCells = totalCells - days.count
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        for day in 1...remainingCells {
            if let date = calendar.date(bySetting: .day, value: day, of: nextMonth) {
                let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == calendar.startOfDay(for: date) } ?? false
                days.append(CalendarDay(id: date, date: date, isToday: false, isSelected: isSelected, events: [], isCurrentMonth: false))
            }
        }

        return days
    }
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

    private func dayName(for columnIndex: Int, availableWidth: CGFloat? = nil) -> String {
    let calendar = Calendar.current

    // Calculate which weekday this column represents
    // calendar.firstWeekday is 1-based (1 = Sunday in US locale)
    let firstWeekday = calendar.firstWeekday - 1 // Convert to 0-based
    let weekdayIndex = (columnIndex + firstWeekday) % 7

    // Use DateFormatter to get localized weekday names
    let formatter = DateFormatter()

    // Determine format based on available width
    if let width = availableWidth {
        if width > 80 {
            // Full name for wide columns
            formatter.dateFormat = "EEEE" // Full weekday name (Sunday, Monday, etc.)
        } else if width > 50 {
            // Abbreviated for medium columns
            formatter.dateFormat = "EEE" // Abbreviated weekday name (Sun, Mon, etc.)
        } else {
            // Short for narrow columns
            formatter.dateFormat = "EEEEE" // Very short (S, M, T, etc.)
        }
    } else {
        // Default to abbreviated if no width provided
        formatter.dateFormat = "EEE"
    }

    // Create a date that falls on the desired weekday
    // Use a known Sunday as reference and add days
    let referenceSunday = DateComponents(calendar: calendar, year: 2024, month: 1, day: 7) // Jan 7, 2024 is a Sunday
    let referenceDate = calendar.date(from: referenceSunday)!

    // Add the weekday offset to get the correct day of the week
    let targetDate = calendar.date(byAdding: .day, value: weekdayIndex, to: referenceDate)!

    return formatter.string(from: targetDate)
}

struct KeyCommandsView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { calendarViewModel.toggleKeyCommands() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
            }
            .padding()

            ScrollViewWithFade {
                VStack(alignment: .leading, spacing: 12) {
                    KeyCommandRow(key: "N", description: "Next month")
                    KeyCommandRow(key: "P", description: "Previous month")
                    KeyCommandRow(key: "T", description: "Go to today")
                    KeyCommandRow(key: "1-9", description: "View mode (1-9 days)")
                    KeyCommandRow(key: "0", description: "2-week view")
                    KeyCommandRow(key: "↑↓", description: "Navigate weeks")
                    KeyCommandRow(key: "←→", description: "Navigate days")
                    KeyCommandRow(key: "Cmd + F", description: "Search")
                    KeyCommandRow(key: "Cmd + Shift + F", description: "Toggle fullscreen")
                    KeyCommandRow(key: "Cmd + K", description: "Show shortcuts")
                    KeyCommandRow(key: "Cmd + Shift + K", description: "Show shortcuts in slide-out")
                    KeyCommandRow(key: "Cmd + D", description: "Show day detail")
                    KeyCommandRow(key: "Return", description: "Toggle day detail slide-out")
                    KeyCommandRow(key: "Cmd + ,", description: "Settings")
                    KeyCommandRow(key: "Cmd + A", description: "Switch to agenda view")
                    KeyCommandRow(key: "Cmd + N", description: "Create new event")
                    KeyCommandRow(key: "Cmd + Shift + N", description: "Quick create from templates")
                    KeyCommandRow(key: "Double-click", description: "Show day detail (single day view stays)")
                    KeyCommandRow(key: "Right-click", description: "Context menu with event options")
                }
                .padding(.horizontal)
            }
        }
    }
}

struct KeyCommandRow: View {
    let key: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            Text(description)
                .foregroundColor(themeManager.currentPalette.textSecondary)
            Spacer()
        }
    }
}

// MARK: - URL Text View
struct URLTextView: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showBrowserSelection = false
    @State private var selectedURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(textComponents, id: \.id) { component in
                switch component {
                case .text(let string):
                    Text(string)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                case .url(let url, let displayText):
                    Text(displayText)
                        .foregroundColor(themeManager.currentPalette.accent.opacity(0.8))
                        .bold()
                        .underline()
                        .onTapGesture {
                            selectedURL = url
                            showBrowserSelection = true
                        }
                }
            }
        }
        .sheet(isPresented: $showBrowserSelection) {
            if let url = selectedURL {
                BrowserSelectionView(url: url, isPresented: $showBrowserSelection)
            }
        }
    }

    private var textComponents: [URLTextComponent] {
        var components: [URLTextComponent] = []

        // Find URLs in the text
        let urlPattern = #"https?://[^\s]+"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: [])

        if let regex = regex {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            var lastEnd = 0

            for match in matches {
                // Add text before the URL
                if match.range.location > lastEnd {
                    let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    let beforeText = nsString.substring(with: beforeRange)
                    components.append(.text(beforeText))
                }

                // Add the URL
                let urlString = nsString.substring(with: match.range)
                if let url = URL(string: urlString) {
                    components.append(.url(url, urlString))
                }

                lastEnd = match.range.location + match.range.length
            }

            // Add remaining text after the last URL
            if lastEnd < nsString.length {
                let remainingRange = NSRange(location: lastEnd, length: nsString.length - lastEnd)
                let remainingText = nsString.substring(with: remainingRange)
                components.append(.text(remainingText))
            }
        } else {
            // No URLs found, just return the text
            components.append(.text(text))
        }

        return components
    }

    private func extractDomain(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }

    private enum URLTextComponent: Identifiable {
        case text(String)
        case url(URL, String) // URL and display text

        var id: String {
            switch self {
            case .text(let string):
                return "text_\(string.hash)"
            case .url(let url, _):
                return "url_\(url.absoluteString.hash)"
            }
        }
    }
}

// MARK: - Event Icon Mapping
struct EventIconManager {
    static let wordToEmoji: [String: String] = [
        // Birthdays & Personal
        "birthday": "🎂",
        "birth": "👶",
        "anniversary": "💍",
        "wedding": "💒",
        "party": "🎉",
        "celebration": "🎊",

        // Holidays
        "christmas": "🎄",
        "holiday": "🎁",
        "halloween": "🎃",
        "thanksgiving": "🦃",
        "easter": "🐰",
        "valentine": "💝",
        "new year": "🎆",
        "independence": "🇺🇸",
        "labor": "👷",

        // Work & School
        "meeting": "👥",
        "conference": "🎤",
        "presentation": "📊",
        "interview": "💼",
        "deadline": "⏰",
        "school": "🎓",
        "class": "📚",
        "exam": "📝",
        "homework": "✏️",
        "lecture": "👨‍🏫",
        "seminar": "📖",

        // Health & Medical
        "doctor": "👨‍⚕️",
        "dentist": "🦷",
        "appointment": "📅",
        "checkup": "🏥",
        "therapy": "🧠",
        "gym": "💪",
        "workout": "🏋️‍♂️",
        "yoga": "🧘‍♀️",

        // Travel & Transportation
        "flight": "✈️",
        "train": "🚂",
        "bus": "🚌",
        "car": "🚗",
        "taxi": "🚕",
        "uber": "🚗",
        "vacation": "🏖️",
        "trip": "🗺️",
        "hotel": "🏨",

        // Food & Dining
        "dinner": "🍽️",
        "lunch": "🥗",
        "breakfast": "🥞",
        "coffee": "☕",
        "restaurant": "🍽️",
        "bar": "🍸",
        "date": "💑",

        // Sports & Activities
        "game": "⚽",
        "match": "🏆",
        "practice": "🏃‍♂️",
        "concert": "🎵",
        "movie": "🎬",
        "theater": "🎭",
        "museum": "🏛️",
        "park": "🌳",

        // Family & Social
        "family": "👨‍👩‍👧‍👦",
        "kids": "👶",
        "parent": "👨‍👩‍👧",
        "friend": "👫",
        "call": "📞",
        "video": "📹",

        // Time-based
        "morning": "🌅",
        "afternoon": "☀️",
        "evening": "🌆",
        "night": "🌙",
        "weekend": "🏖️",

        // Generic
        "event": "📅",
        "reminder": "🔔",
        "important": "⚠️",
        "urgent": "🚨"
    ]

    static func emojiForEvent(_ title: String) -> String? {
        let lowercasedTitle = title.lowercased()

        // Check for exact matches first
        for (word, emoji) in wordToEmoji {
            if lowercasedTitle.contains(word) {
                return emoji
            }
        }

        return nil
    }

    static func initialsForEvent(_ title: String) -> String {
        let words = title.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        if words.count == 1 {
            // Single word - take first 2 letters
            return String(words[0].prefix(2)).uppercased()
        } else if words.count <= 8 {
            // Multiple words - take first letter of first 2-3 words
            let initials = words.prefix(3).compactMap { $0.first }.map { String($0) }
            return initials.joined().uppercased()
        } else {
            // Too many words - just show generic event
            return "📅"
        }
    }

    static func compactRepresentation(for title: String, maxLength: Int = 8, cellWidth: CGFloat) -> String {
        #if os(iOS)
        if title.count > maxLength && cellWidth < 40 {
            // Use emoji if available, otherwise use initials
            if let emoji = emojiForEvent(title) {
                return emoji
            } else {
                return initialsForEvent(title)
            }
        }
        #endif

        // Default: return the title (potentially truncated)
        return title.count > maxLength ? String(title.prefix(maxLength)) + "..." : title
    }
}

// MARK: - Browser Selection View
struct BrowserSelectionView: View {
    let url: URL
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Open Link")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentPalette.textPrimary)

                Text("Choose how to open this link:")
                    .foregroundColor(themeManager.currentPalette.textSecondary)

                Text(url.absoluteString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: {
                        openURL(url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Open in Safari")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    #if os(macOS)
                    Button(action: {
                        // On macOS, we can try to open in other browsers
                        openInBrowser("com.google.Chrome", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Chrome")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        openInBrowser("com.microsoft.edgemac", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Edge")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        openInBrowser("org.mozilla.firefox", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Firefox")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    #endif
                }
                .padding(.horizontal)

                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            #if os(iOS)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .navigationViewStyle(.stack)
            #endif
        }
    }

    #if os(macOS)
    private func openInBrowser(_ bundleIdentifier: String, url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = false

        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: "/Applications/\(bundleIdentifier).app"),
                               configuration: configuration) { _, error in
            if let error = error {
                print("Failed to open URL in browser: \(error)")
                // Fallback to default browser
                openURL(url)
            }
        }
    }
    #endif
}

// MARK: - ScrollView with Fade Gradients
struct ScrollViewWithFade<Content: View>: View {
    let content: Content
    let fadeHeight: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top fade area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: fadeHeight)
                    content
                    // Bottom fade area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: fadeHeight)
                }
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fadeHeight)

                    Rectangle().fill(Color.black)

                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fadeHeight)
                }
            )
        }
    }
}

// MARK: - View Mode Selector (iOS)
struct ViewModeSelectorView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration

    var body: some View {
        #if os(iOS)
        NavigationView {
            List {
                ForEach(CalendarViewMode.userSelectableCases, id: \.self) { mode in
                    Button(action: {
                        calendarViewModel.setViewMode(mode)
                        calendarViewModel.showViewModeSelector = false
                    }) {
                        HStack {
                            Text(mode.displayName)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Spacer()
                            if calendarViewModel.viewMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.currentPalette.primary)
                            }
                        }
                    }
                    .listRowBackground(themeManager.currentPalette.surface.opacity(0.5))
                }
            }
            .navigationTitle("Select View")
            .navigationBarItems(trailing: Button("Done") {
                calendarViewModel.showViewModeSelector = false
            })
            .listStyle(.insetGrouped)
            .background(themeManager.currentPalette.calendarBackground)
            .navigationViewStyle(.stack)
        }
        #else
        // macOS version - use a simple sheet with blur background
        ZStack {
            // Blurred background
            Color.black.opacity(0.3)
                .blur(radius: 20)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Select View")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentPalette.textPrimary)

                VStack(spacing: 0) {
                    ForEach(CalendarViewMode.userSelectableCases, id: \.self) { mode in
                        Button(action: {
                            calendarViewModel.setViewMode(mode)
                            calendarViewModel.showViewModeSelector = false
                        }) {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                Spacer()
                                if calendarViewModel.viewMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentPalette.primary)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                        .background(themeManager.currentPalette.surface.opacity(0.5))

                        if mode != CalendarViewMode.userSelectableCases.last {
                            Divider()
                        }
                    }
                }
                .background(themeManager.currentPalette.surface.opacity(0.95))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                Button("Cancel") {
                    calendarViewModel.showViewModeSelector = false
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
            .padding(40)
        }
        .frame(minWidth: 300, minHeight: 400)
        #endif
    }
}

// MARK: - Enhanced Day Detail Slide Out
struct DayDetailSlideOut: View {
    let date: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration

    @State private var slideOffset: CGFloat = 0
    @State private var isFullScreen = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var showOnRight: Bool? = nil // nil means use initial calculation

    private var slideWidth: CGFloat {
        #if os(tvOS)
        return 300 // Keep fixed width for tvOS for now, will be overridden by geometry
        #else
        return 300
        #endif
    }
    private let fullScreenThreshold: CGFloat = 150 // How far to pull to go full screen
    private let dismissThreshold: CGFloat = 100 // How far to drag to dismiss

    // Hysteresis thresholds - only switch sides when crossing these boundaries
    private let switchToRightThreshold: CGFloat = 0.32 // Switch to right when leading edge < 32%
    private let switchToLeftThreshold: CGFloat = 0.68  // Switch to left when trailing edge > 68%

    // Calculate the column index (0-6) for the selected date in the calendar grid
    private var columnIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, 7 = Saturday
        let firstWeekday = calendar.firstWeekday // 1 = Sunday in US, 2 = Monday elsewhere
        return (weekday - firstWeekday + 7) % 7
    }
    
    // Calculate leading edge position (0.0 to 1.0)
    private var leadingEdgePosition: CGFloat {
        return CGFloat(columnIndex) / 7.0
    }
    
    // Calculate trailing edge position (0.0 to 1.0)
    private var trailingEdgePosition: CGFloat {
        return CGFloat(columnIndex + 1) / 7.0
    }
    
    // Determine if the slide out should show on the right side (considering hysteresis)
    private var shouldShowOnRight: Bool {
        if let currentSide = showOnRight {
            // Apply hysteresis - only switch if crossing thresholds
            if currentSide {
                // Currently on right, switch to left if trailing edge > 68%
                return trailingEdgePosition <= switchToLeftThreshold
            } else {
                // Currently on left, switch to right if leading edge < 32%
                return leadingEdgePosition < switchToRightThreshold
            }
        } else {
            // Initial calculation - use center point
            let centerPosition = (leadingEdgePosition + trailingEdgePosition) / 2
            return centerPosition < 0.5
        }
    }
    
    // Public property for parent view to use for overlay alignment
    var currentAlignment: Alignment {
        return shouldShowOnRight ? .trailing : .leading
    }
    
    // For drag gesture direction calculation
    private var isOnRightSide: Bool {
        return shouldShowOnRight
    }

    private var dayDetailBackground: Color {
        #if os(tvOS)
        return themeManager.currentTheme == .system ?
            Color.gray.opacity(0.95) : // More opaque solid background for system theme on tvOS
            themeManager.currentPalette.calendarSurface.opacity(0.95)
        #else
        return themeManager.currentPalette.calendarSurface
        #endif
    }

    private var fullScreenBackground: Color {
        #if os(tvOS)
        return themeManager.currentTheme == .system ?
            Color.black.opacity(0.8) : // More opaque for system theme on tvOS
            Color.black.opacity(0.3)
        #else
        return Color.black.opacity(0.3)
        #endif
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay for full screen mode
                if isFullScreen {
                    fullScreenBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                calendarViewModel.showDayDetail = false
                            }
                        }
                }

                // Use HStack with Spacer to position on left or right
                HStack(spacing: 0) {
                    if isOnRightSide {
                        Spacer(minLength: 0)
                    }
                    
                    // Slide-out content
                    DayDetailView(date: date)
                        .frame(width: isFullScreen ? geometry.size.width : (geometry.size.width / 3) - 16) // Account for 8pt inset on each side
                        .frame(maxHeight: isFullScreen ? .infinity : .infinity)
                        .background(dayDetailBackground)
                        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 10)) // Increased from 6pt to 10pt
                        .shadow(radius: isFullScreen ? 0 : 10)
                        .padding(isFullScreen ? 0 : 8) // 8pt inset on all sides
                        .offset(x: isOnRightSide ? slideOffset : -slideOffset)
                    #if !os(tvOS)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.width

                                if isFullScreen {
                                    // In full screen mode, only allow edge pan from appropriate edge
                                    if isOnRightSide {
                                        // Right side panel - allow pan from right edge
                                        if value.startLocation.x > geometry.size.width - 50 {
                                            slideOffset = min(0, translation)
                                        }
                                    } else {
                                        // Left side panel - allow pan from left edge
                                        if value.startLocation.x < 50 {
                                            slideOffset = max(0, translation)
                                        }
                                    }
                                } else {
                                    // In normal mode, allow pulling to full screen or dragging to close
                                    if isOnRightSide {
                                        // Right-side sliding: pulling left goes to full screen, right closes
                                        if translation < 0 {
                                            // Pulling to the left (towards full screen)
                                            slideOffset = min(0, translation)
                                        } else {
                                            // Dragging to the right (towards close)
                                            slideOffset = max(0, translation)
                                        }
                                    } else {
                                        // Left-side sliding: pulling right goes to full screen, left closes
                                        if translation > 0 {
                                            // Pulling to the right (towards full screen)
                                            slideOffset = max(0, translation)
                                        } else {
                                            // Dragging to the left (towards close)
                                            slideOffset = min(0, translation)
                                        }
                                    }
                                }
                            }
                            .onEnded { value in
                                let translation = value.translation.width
                                let velocity = value.predictedEndTranslation.width

                                withAnimation(.spring()) {
                                    if isFullScreen {
                                        // Full screen mode: edge pan to dismiss
                                        if isOnRightSide {
                                            // Right side - dismiss on drag right
                                            if slideOffset > dismissThreshold || velocity > 300 {
                                                calendarViewModel.showDayDetail = false
                                            }
                                        } else {
                                            // Left side - dismiss on drag left
                                            if -slideOffset > dismissThreshold || velocity < -300 {
                                                calendarViewModel.showDayDetail = false
                                            }
                                        }
                                        slideOffset = 0
                                    } else {
                                        // Normal mode
                                        if isOnRightSide {
                                            // Right-side sliding
                                            if translation < -fullScreenThreshold || velocity < -300 {
                                                // Pulled far enough left - go full screen
                                                isFullScreen = true
                                                slideOffset = 0
                                            } else if translation > dismissThreshold || velocity > 300 {
                                                // Dragged far enough right - close
                                                calendarViewModel.showDayDetail = false
                                            } else {
                                                // Return to original position
                                                slideOffset = 0
                                            }
                                        } else {
                                            // Left-side sliding
                                            if translation > fullScreenThreshold || velocity > 300 {
                                                // Pulled far enough right - go full screen
                                                isFullScreen = true
                                                slideOffset = 0
                                            } else if translation < -dismissThreshold || velocity < -300 {
                                                // Dragged far enough left - close
                                                calendarViewModel.showDayDetail = false
                                            } else {
                                                // Return to original position
                                                slideOffset = 0
                                            }
                                        }
                                    }
                                }
                            }
                    )
                    #endif
                        .transition(.move(edge: isOnRightSide ? .trailing : .leading).combined(with: .opacity))
                    
                    if !isOnRightSide {
                        Spacer(minLength: 0)
                    }
                }
            }
            .ignoresSafeArea(isFullScreen ? .all : [])
        }
        .animation(.easeInOut(duration: 0.3), value: date)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShowOnRight)
        .onChange(of: calendarViewModel.showDayDetail) { newValue in
            if !newValue {
                withAnimation(.spring()) {
                    isFullScreen = false
                    slideOffset = 0
                }
            }
        }
        .onChange(of: date) { _ in
            // Update the hysteresis state when date changes
            let newShouldShowOnRight = shouldShowOnRight
            if showOnRight != newShouldShowOnRight {
                showOnRight = newShouldShowOnRight
            }
        }
        .onAppear {
            // Initialize the side based on current position
            showOnRight = shouldShowOnRight
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel())
}
