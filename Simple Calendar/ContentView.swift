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

struct ContentView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var showQuickAdd = false

    private var mainContentView: some View {
        ZStack {
            if calendarViewModel.viewMode == .agenda {
                AgendaView()
                    .overlay(dayDetailSlideOut, alignment: .trailing)
                    .overlay(searchOverlay, alignment: .center)
                    .overlay(keyCommandsOverlay, alignment: .center)
            } else {
                mainCalendarView
                    .overlay(dayDetailSlideOut, alignment: .trailing)
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
        .roundedCorners(.small)
    }

    var body: some View {
        #if os(iOS)
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
        }
    }

    private var calendarHeader: some View {
        HStack {
            Spacer()
            monthYearDisplay
            Spacer()
        }
        .padding(.bottom, 20)
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
                calendarViewModel.toggleYearView()
            }
    }

    private var yearDisplay: some View {
        Text(calendarViewModel.currentDate.formatted(.dateTime.year()))
            .font(uiConfig.yearTitleFont)
            .foregroundColor(themeManager.currentPalette.yearText)
    }

    private var calendarGrid: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: daysPerRow)
            let days = generateCalendarDays()

            // Calculate available height for calendar content
            let headerHeight: CGFloat = calendarViewModel.viewMode == .year ? 0 : 32 // Header height + spacing
            let availableHeight = geometry.size.height - headerHeight - 32 // Subtract padding
            let rowsCount = calculateRowsCount(for: days.count, columns: daysPerRow)
            let cellHeight = max(availableHeight / CGFloat(rowsCount), 60) // Minimum height of 60

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
                                .font(uiConfig.dayNameFont)
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
                            MonthMiniView(monthDate: day.date, geometry: geometry)
                                .frame(height: cellHeight)
                                .onTapGesture {
                                    // Switch to month view for the selected month
                                    calendarViewModel.currentDate = day.date
                                    calendarViewModel.setViewMode(.month)
                                }
                        }
                    } else {
                        // Regular views: show day cells
                        ForEach(days) { day in
                            DayView(day: day, geometry: geometry, cellHeight: cellHeight, columnsCount: daysPerRow)
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
                        }
                    }
                }
                .padding(.horizontal)
            }
            .animation(.easeInOut(duration: 0.35), value: calendarViewModel.viewMode)
            .animation(.easeInOut(duration: 0.35), value: calendarViewModel.currentDate)
        }
    }

    private func calculateRowsCount(for itemCount: Int, columns: Int) -> Int {
        return (itemCount + columns - 1) / columns // Ceiling division
    }

    private var dayDetailSlideOut: some View {
        Group {
            if calendarViewModel.showDayDetail, let selectedDate = calendarViewModel.selectedDate {
                DayDetailView(date: selectedDate)
                    .frame(width: 300)
                    .background(themeManager.currentPalette.calendarSurface)
                    .roundedCorners(.medium)
                    .shadow(radius: 10)
                    .transition(.move(edge: .trailing))
            }
        }
    }

    private var searchOverlay: some View {
        Group {
            if calendarViewModel.showSearch {
                SearchView(searchText: $searchText)
                    .frame(width: 400, height: 60)
                    .background(themeManager.currentPalette.calendarSurface)
                    .cornerRadius(8)
                    .shadow(radius: 10)
            }
        }
    }

    private var keyCommandsOverlay: some View {
        Group {
            if calendarViewModel.showKeyCommands {
                KeyCommandsView()
                    .frame(width: 400, height: 500)
                    .background(themeManager.currentPalette.calendarSurface)
                    .cornerRadius(8)
                    .shadow(radius: 10)
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
        let calendar = Calendar.current
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
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared

    private var monthlyPalette: ColorPalette {
        let month = Calendar.current.component(.month, from: day.date)
        let monthlyTheme = monthlyThemeManager.theme(for: month)
        return monthlyTheme.palette(for: themeManager.currentColorScheme)
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

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 1 : 2) {
            Text(day.date.formatted(.dateTime.day()))
                .font(isCompactLayout ? uiConfig.scaledFont(14, weight: .semibold) : uiConfig.dayNumberFont)
                .foregroundColor(dayTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Show event details with compact representation for narrow cells
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
            }

            Spacer()
        }
        .compactPadding()
        .frame(height: cellHeight)
        .background(dayBackgroundColor)
        .roundedCorners(.small)
        .overlay(alignment: .top) {
            // Daylight visualization (only if enabled)
            if featureFlags.daylightVisualizationCalendar {
                DaylightVisualizationView(date: day.date, width: geometry.size.width / CGFloat(columnsCount))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small.value))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(monthlyPalette.gridLine.opacity(uiConfig.gridLineOpacity),
                       lineWidth: gridLineWidth(for: uiConfig.gridLineOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(day.isToday ? monthlyPalette.todayHighlight : Color.clear, lineWidth: 2)
        )
    }

    private var dayTextColor: Color {
        if day.isSelected {
            return monthlyPalette.calendarSurface
        } else if day.isCurrentMonth {
            return monthlyPalette.textPrimary
        } else {
            return monthlyPalette.textSecondary
        }
    }

    private var dayBackgroundColor: Color {
        if day.isSelected {
            return monthlyPalette.selectedDay
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
}

struct DayDetailView: View {
    let date: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var onThisDayService = OnThisDayService.shared
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
                    .frame(width: 20)
            }

            // Main content (right side)
            VStack(alignment: .leading) {
                HStack {
                    Text(date.formatted(.dateTime.month(.wide).day().year()))
                        .font(uiConfig.scaledFont(28, weight: .bold))
                    Spacer()
                    Button(action: { calendarViewModel.toggleDayDetail() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                }
                .standardPadding()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let dayEvents = calendarViewModel.events.filter { event in
                        Calendar.current.isDate(event.startDate, inSameDayAs: date)
                    }

                    let groupedEvents = groupDuplicateEvents(dayEvents)

                    if dayEvents.isEmpty {
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
            } else if let error = error {
                Text("Unable to load historical data")
                    .foregroundColor(.red)
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
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(4)
                    }
                }
            }

            Text(event.title)
                .font(uiConfig.eventTitleFont)

            HStack {
                Image(systemName: "clock")
                if isAllDayEvent {
                    Text("All Day")
                        .font(uiConfig.eventDetailFont)
                        .fontWeight(.medium)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Starts:")
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                        }
                        HStack(spacing: 4) {
                            Text("Ends:")
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.endDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                        }
                    }
                }
            }

            if let location = event.location {
                HStack {
                    Image(systemName: "location")
                    Text(location)
                        .font(uiConfig.eventDetailFont)
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
                            Text(weather.condition)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }

                        HStack(spacing: 16) {
                            Label(weather.humidityString, systemImage: "humidity")
                            Label(weather.windSpeedString, systemImage: "wind")
                        }
                        .font(uiConfig.captionFont)
                        .foregroundColor(themeManager.currentPalette.textSecondary)
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
                    .foregroundColor(.secondary)
                TextField("Search events or dates", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                Button(action: { calendarViewModel.toggleSearch() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            if !searchText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if searchResults.isEmpty {
                            Text("No events found")
                                .foregroundColor(.secondary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Text(event.startDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let location = event.location {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private var monthlyPalette: ColorPalette {
        let month = Calendar.current.component(.month, from: monthDate)
        let monthlyTheme = monthlyThemeManager.theme(for: month)
        return monthlyTheme.palette(for: themeManager.currentColorScheme)
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
                    days.append(CalendarDay(id: date, date: date, isToday: false, isSelected: false, events: [], isCurrentMonth: false))
                }
            }
        }

        // Current month days
        for day in 1...range.count {
            if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                let isToday = calendar.isDateInToday(date)
                days.append(CalendarDay(id: date, date: date, isToday: isToday, isSelected: false, events: [], isCurrentMonth: true))
            }
        }

        // Next month days to fill the grid
        let remainingCells = totalCells - days.count
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        for day in 1...remainingCells {
            if let date = calendar.date(bySetting: .day, value: day, of: nextMonth) {
                days.append(CalendarDay(id: date, date: date, isToday: false, isSelected: false, events: [], isCurrentMonth: false))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { calendarViewModel.toggleKeyCommands() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            ScrollView {
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

    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            Text(description)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - URL Text View
struct URLTextView: View {
    let text: String
    @Environment(\.openURL) var openURL
    @State private var tappedURL: URL? = nil

    private var processedText: String {
        // Find URLs in the text and replace them with domain links
        let urlPattern = #"https?://[^\s]+"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: [])

        if let regex = regex {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if let firstMatch = matches.first {
                let urlString = nsString.substring(with: firstMatch.range)
                if let url = URL(string: urlString) {
                    let domain = extractDomain(from: url)
                    let beforeURL = nsString.substring(to: firstMatch.range.location)
                    let afterURL = nsString.substring(from: firstMatch.range.location + firstMatch.range.length)

                    tappedURL = url
                    return beforeURL + "[\(domain)]" + afterURL
                }
            }
        }

        return text
    }

    var body: some View {
        Text(processedText)
            .foregroundColor(tappedURL != nil ? .blue : .primary)
            .underline(tappedURL != nil)
            .onTapGesture {
                if let url = tappedURL {
                    openURL(url)
                }
            }
    }

    private func extractDomain(from url: URL) -> String {
        return url.host ?? url.absoluteString
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
        "holiday": "🎄",

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

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel())
}
