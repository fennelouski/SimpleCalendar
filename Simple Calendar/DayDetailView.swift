//
//  DayDetailView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

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
    @State private var showHolidayDetail = false
    @State private var selectedHoliday: CalendarHoliday?
    
#if os(tvOS)
    private let maximumNumberOfHolidays = 2
#else
    private let maximumNumberOfHolidays: Int = .max
#endif
    
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
    
    // Computed properties for event filtering logic
    private var filteredEvents: [CalendarEvent] {
        let allDayEvents = calendarViewModel.events.filter { event in
            Calendar(identifier: .gregorian).isDate(event.startDate, inSameDayAs: date)
        }

        // Separate user events (tvOS-created) from other events
        let userEvents = allDayEvents.filter { $0.calendarIdentifier == "tv_local" }
        let otherEvents = allDayEvents.filter { $0.calendarIdentifier != "tv_local" }

        // Determine what events to display based on user event count
        switch userEvents.count {
        case 0:
            // No user events - show all events normally
            return allDayEvents
        case 1:
            // One user event - show it first, then other events
            return userEvents + otherEvents
        case 2:
            // Exactly 2 user events - show only these in slide over detail
            return userEvents
        default:
            // More than 2 user events - show all user events and other events
            return userEvents + otherEvents
        }
    }

    private var shouldShowOversizedEmoji: Bool {
        let allDayEvents = calendarViewModel.events.filter { event in
            Calendar(identifier: .gregorian).isDate(event.startDate, inSameDayAs: date)
        }
        let userEventsCount = allDayEvents.filter { $0.calendarIdentifier == "tv_local" }.count

        // Hide oversized emoji only when there are more than 2 user events
        return userEventsCount <= 2
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
            VStack(alignment: .leading, spacing: 0) {
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
                    // Only show close button when NOT in single day view mode
                    // In single day view, the main content IS the detail view, so there's nothing to close
                    if calendarViewModel.viewMode != .singleDay {
                        Button(action: { calendarViewModel.toggleDayDetail() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                    }
#endif
                }
                .standardPadding()

                ScrollViewWithFade {
                    VStack(alignment: .leading, spacing: 16) {
                        let displayEvents = filteredEvents
                        let showOversizedEmoji = shouldShowOversizedEmoji

                        let holidaysOnThisDay = featureFlags.holidayDisplayEnabled ? holidayManager.holidaysOn(date) : []

                        let groupedEvents = groupDuplicateEvents(displayEvents)
                        
                        // Show holidays at the top if enabled
                        // Limit to 2 holidays on tvOS for better visibility in detail view

                        if !holidaysOnThisDay.isEmpty {
#if os(tvOS)
                            let displayedHolidays = Array(holidaysOnThisDay.prefix(maximumNumberOfHolidays))
#else
                            let displayedHolidays = holidaysOnThisDay
#endif

                            // Pre-fetch images for visible holidays only
                            let holidayImageManager = HolidayImageManager.shared
                            let _ = DispatchQueue.main.async {
                                holidayImageManager.prefetchImagesForVisibleHolidays(displayedHolidays)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(displayedHolidays) { holiday in
#if os(tvOS)
                                    // tvOS: Holiday name at top, HUGE emoji beneath, then description
                                    VStack(spacing: 16) {
                                        // Holiday name at top
                                        Text(holiday.name)
                                            .font(.system(size: 42, weight: .bold))
                                            .foregroundColor(themeManager.currentPalette.accent)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.3)
                                            .frame(maxWidth: .infinity, alignment: .center)

                                        // HUGE emoji beneath the name
                                        Text(holiday.emoji)
                                            .font(.system(size: 144)) // Massive emoji for TV viewing

                                        // Description beneath the emoji
                                        Text(holiday.description)
                                            .font(.system(size: 28, weight: .regular))
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(themeManager.currentPalette.surface.opacity(0.7))
                                    .cornerRadius(16)
                                    .padding(16)
                                    .focusable()
                                    .onTapGesture {
                                        // tvOS navigation to holiday detail
                                        // Note: This would need to be integrated with tvOS navigation system
                                    }
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Navigate to holiday detail view
                                        showHolidayDetail = true
                                        selectedHoliday = holiday
                                    }
#endif
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        
                        if displayEvents.isEmpty && holidaysOnThisDay.isEmpty {
                            Text("No events for this day".localized)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .standardPadding()
                        } else {
                            ForEach(Array(groupedEvents.enumerated()), id: \.offset) { index, eventGroup in
                                if eventGroup.count > 1 {
                                    // Multiple instances of the same event
                                    VStack(alignment: .leading, spacing: 4) {
                                        EventDetailView(event: eventGroup.first!, showOversizedEmoji: showOversizedEmoji)
                                        Text(eventGroup.count - 1 == 1 ? "+1 more occurrence".localized : "+%d more occurrences".localized(with: eventGroup.count - 1))
                                            .font(uiConfig.captionFont)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .padding(.leading, 16)
                                    }
                                } else {
                                    EventDetailView(event: eventGroup.first!, showOversizedEmoji: showOversizedEmoji)
                                }
                            }
                        }
                        
                        // Astronomical Information section (tvOS only)
#if os(tvOS)
                        AstronomicalInfoSection(date: date, eventCount: displayEvents.count + holidaysOnThisDay.count)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ScrollView can expand
                .task {
                    if featureFlags.onThisDayEnabled {
                        await loadOnThisDayData()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack fills available space
        }
        .sheet(isPresented: $showHolidayDetail) {
            if let holiday = selectedHoliday {
                NavigationView {
                    HolidayDetailView(holiday: holiday)
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
