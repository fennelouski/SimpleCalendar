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
    @State private var searchText = ""
    @State private var showQuickAdd = false

    var body: some View {
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
        .background(themeManager.currentTheme.palette.calendarBackground)
        #if os(macOS)
        .addKeyboardShortcuts()
        #endif
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
        .onReceive(NotificationCenter.default.publisher(for: .ToggleDaylightVisualization)) { _ in
            FeatureFlags.shared.daylightVisualization.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ShowQuickAdd"))) { _ in
            showQuickAdd = true
        }
    }

    private var mainCalendarView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                calendarHeader
                calendarGrid
            }
            .adaptivePadding(for: geometry)
            .background(themeManager.currentTheme.palette.calendarBackground)
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
            HStack {
                Spacer()
                yearDisplay
            }
            monthDisplay
        }
        .frame(height: 60)
    }

    private var monthDisplay: some View {
        let monthName = calendarViewModel.currentDate.formatted(.dateTime.month(.wide))
        let font = monthFont(for: calendarViewModel.currentDate)

        return Text(monthName)
            .font(.custom(font, size: 32 * uiConfig.fontSizeCategory.scaleFactor))
            .fontWeight(.bold)
            .foregroundColor(themeManager.currentTheme.palette.monthText)
    }

    private var yearDisplay: some View {
        Text(calendarViewModel.currentDate.formatted(.dateTime.year()))
            .font(uiConfig.yearTitleFont)
            .foregroundColor(themeManager.currentTheme.palette.yearText)
    }

    private var calendarGrid: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: daysPerRow)
            let days = generateCalendarDays()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(days) { day in
                        DayView(day: day, geometry: geometry)
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
                .padding(.horizontal)
            }
        }
    }

    private var dayDetailSlideOut: some View {
        Group {
            if calendarViewModel.showDayDetail, let selectedDate = calendarViewModel.selectedDate {
                DayDetailView(date: selectedDate)
                    .frame(width: 300)
                    .background(themeManager.currentTheme.palette.calendarSurface)
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
                    .background(themeManager.currentTheme.palette.calendarSurface)
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
                    .background(themeManager.currentTheme.palette.calendarSurface)
                    .cornerRadius(8)
                    .shadow(radius: 10)
            }
        }
    }

    private var daysPerRow: Int {
        switch calendarViewModel.viewMode {
        case .month:
            return 7
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
        case .twoWeeks:
            days = generateTwoWeekDays(for: currentMonth)
        default:
            days = generateDayRangeDays(for: currentMonth, days: calendarViewModel.viewMode.dayCount)
        }

        return days
    }

    private func generateMonthDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: components)!

        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstDayOfMonth = calendar.date(from: components)!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Add days from previous month to fill the first week
        let daysFromPreviousMonth = firstWeekday - calendar.firstWeekday
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count

        var days: [CalendarDay] = []

        // Previous month days
        for i in (daysInPreviousMonth - daysFromPreviousMonth + 1)...daysInPreviousMonth {
            let date = calendar.date(bySetting: .day, value: i, of: previousMonth)!
            days.append(createCalendarDay(for: date, isCurrentMonth: false))
        }

        // Current month days
        for day in 1...range.count {
            let date = calendar.date(bySetting: .day, value: day, of: startOfMonth)!
            days.append(createCalendarDay(for: date, isCurrentMonth: true))
        }

        // Next month days to fill the last week
        let remainingCells = (7 - (days.count % 7)) % 7
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        for day in 1...remainingCells {
            let date = calendar.date(bySetting: .day, value: day, of: nextMonth)!
            days.append(createCalendarDay(for: date, isCurrentMonth: false))
        }

        return days
    }

    private func generateTwoWeekDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!

        var days: [CalendarDay] = []
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            days.append(createCalendarDay(for: date, isCurrentMonth: true))
        }

        return days
    }

    private func generateDayRangeDays(for date: Date, days: Int) -> [CalendarDay] {
        let calendar = Calendar.current
        let startDate = calendarViewModel.selectedDate ?? date

        var calendarDays: [CalendarDay] = []
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
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
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day.date.formatted(.dateTime.day()))
                .font(uiConfig.dayNumberFont)
                .foregroundColor(dayTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(day.events.prefix(3)) { event in
                Text(event.title)
                    .font(uiConfig.captionFont)
                    .lineLimit(1)
                    .foregroundColor(themeManager.currentTheme.palette.textSecondary)
            }

            if day.events.count > 3 {
                Text("+\(day.events.count - 3) more")
                    .font(uiConfig.smallCaptionFont)
                    .foregroundColor(themeManager.currentTheme.palette.textSecondary)
            }

            Spacer()
        }
        .compactPadding()
        .frame(height: geometry.size.width / 7 - 16)
        .background(dayBackgroundColor)
        .roundedCorners(.small)
        .overlay(alignment: .top) {
            // Daylight visualization (only if enabled)
            if featureFlags.daylightVisualization {
                DaylightVisualizationView(date: day.date, width: geometry.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small.value))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(themeManager.currentTheme.palette.gridLine, lineWidth: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(day.isToday ? themeManager.currentTheme.palette.todayHighlight : Color.clear, lineWidth: 2)
        )
    }

    private var dayTextColor: Color {
        if day.isSelected {
            return themeManager.currentTheme.palette.calendarSurface
        } else if day.isCurrentMonth {
            return themeManager.currentTheme.palette.textPrimary
        } else {
            return themeManager.currentTheme.palette.textSecondary
        }
    }

    private var dayBackgroundColor: Color {
        if day.isSelected {
            return themeManager.currentTheme.palette.selectedDay
        } else {
            return .clear
        }
    }
}

struct DayDetailView: View {
    let date: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(date.formatted(.dateTime.month(.wide).day().year()))
                    .font(uiConfig.scaledFont(28, weight: .bold))
                Spacer()
                Button(action: { calendarViewModel.toggleDayDetail() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentTheme.palette.textSecondary)
                }
            }
            .standardPadding()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let dayEvents = calendarViewModel.events.filter { event in
                        Calendar.current.isDate(event.startDate, inSameDayAs: date)
                    }

                    if dayEvents.isEmpty {
                        Text("No events for this day")
                            .foregroundColor(themeManager.currentTheme.palette.textSecondary)
                            .font(uiConfig.eventDetailFont)
                            .standardPadding()
                    } else {
                        ForEach(dayEvents) { event in
                            EventDetailView(event: event)
                        }
                    }
                }
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
                Text("\(event.startDate.formatted(.dateTime.hour().minute())) - \(event.endDate.formatted(.dateTime.hour().minute()))")
                    .font(uiConfig.eventDetailFont)
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
                            .foregroundColor(themeManager.currentTheme.palette.textPrimary)

                        HStack {
                            Image(systemName: weather.icon)
                                .foregroundColor(themeManager.currentTheme.palette.accent)
                            Text(weather.temperatureString)
                                .font(uiConfig.eventDetailFont)
                            Text(weather.condition)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentTheme.palette.textSecondary)
                        }

                        HStack(spacing: 16) {
                            Label(weather.humidityString, systemImage: "humidity")
                            Label(weather.windSpeedString, systemImage: "wind")
                        }
                        .font(uiConfig.captionFont)
                        .foregroundColor(themeManager.currentTheme.palette.textSecondary)
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .roundedCorners(.small)
                }
            }

            if let notes = event.notes {
                Text(notes)
                    .font(uiConfig.scaledFont(.body))
                    .foregroundColor(themeManager.currentTheme.palette.textSecondary)
            }
        }
        .standardPadding()
        .background(themeManager.currentTheme.palette.calendarSurface)
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

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel())
}
