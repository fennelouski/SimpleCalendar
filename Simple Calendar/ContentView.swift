//
//  ContentView.swift
//  Calendar Play
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
import MapKit
#if !os(tvOS)
import EventKit
#endif

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
    @State private var showPermissionPrimer = false
    
    
#if os(tvOS)
    // Guard flag to prevent re-entrant focus/selection updates that cause double navigation
    @State private var isUpdatingFocusSelection: Bool = false
#endif
    
    
    private var mainContentView: some View {
        ZStack {
            if calendarViewModel.viewMode == .agenda {
                AgendaView()
                    .overlay(
                        Group {
                            if calendarViewModel.showDayDetail,
                               let selectedDate = calendarViewModel.selectedDate {
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
                            // On iOS single-day view, the main content is already the day detail,
                            // so we do not show the slide-over detail at all.
                            if calendarViewModel.showDayDetail,
                               calendarViewModel.viewMode != .singleDay,
                               let selectedDate = calendarViewModel.selectedDate {
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
        #if !os(tvOS)
        .sheet(isPresented: $calendarViewModel.showEventCreation) {
            EventCreationView()
        }
        #endif
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
//        .sheet(isPresented: $calendarViewModel.showTVEventManagement) {
//            TVEventManagementView(selectedDate: calendarViewModel.selectedDate ?? Date())
//        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showPermissionPrimer) {
            PermissionPrimerView(
                isPresented: $showPermissionPrimer,
                onContinue: {
                    requestCalendarAccess()
                },
                onCancel: {
                    showPermissionPrimer = false
                }
            )
        }
        #endif
        .roundedCorners(.small)
    }
    
    var body: some View {
#if os(tvOS)
        // On tvOS, use full screen layout optimized for TV
        ZStack {
            // Full screen background with gradient
            CalendarGradientBackground(
                baseColor: themeManager.currentPalette.calendarBackground,
                colorScheme: colorScheme,
                intensity: .light
            )
            .ignoresSafeArea()
            
            // Background animations (only in month view) - Edge to edge
            if calendarViewModel.viewMode == .month {
                MonthBackgroundAnimationView(currentDate: calendarViewModel.currentDate)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
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
            // On tvOS, let SwiftUI's focus system handle day-to-day navigation automatically.
            // The onChange(of: focusedDate) handler will sync selectedDate with focusedDate.
            // We only need to handle edge cases here, like navigating to different months.
            
            guard calendarViewModel.viewMode == .month,
                  let currentSelected = calendarViewModel.selectedDate else {
                // For non-month views or when no date is selected, let SwiftUI handle it
                return
            }
            
            let calendar = Calendar(identifier: .gregorian)
            let days = getCachedCalendarDays()
            guard let currentIndex = days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: currentSelected) }) else {
                return
            }
            
            let columns = 7 // daysPerRow for month view
            let row = currentIndex / columns
            let column = currentIndex % columns
            let totalRows = (days.count + columns - 1) / columns // Ceiling division
            let isFirstRow = row == 0
            let isLastRow = row == (totalRows - 1)
            let isFirstColumn = column == 0
            let isLastColumn = column == (columns - 1)
            
            // Check if the current date is in the current month (not a previous/next month filler)
            let currentMonthComponents = calendar.dateComponents([.year, .month], from: calendarViewModel.currentDate)
            let selectedDateComponents = calendar.dateComponents([.year, .month], from: currentSelected)
            let isInCurrentMonth = currentMonthComponents.year == selectedDateComponents.year &&
                                   currentMonthComponents.month == selectedDateComponents.month
            
            switch direction {
            case .left:
                // Only navigate to previous month if we're at left edge AND at the start of the current month
                if isFirstColumn && isInCurrentMonth {
                    // Check if we're at the actual start of the month (not just first column)
                    let startOfMonth = calendar.startOfDay(for: calendar.date(from: currentMonthComponents) ?? currentSelected)
                    if calendar.isDate(currentSelected, inSameDayAs: startOfMonth) {
                        // Navigate to previous month, same day of week (go back 7 days)
                        if let targetDate = calendar.date(byAdding: .day, value: -7, to: currentSelected) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                calendarViewModel.currentDate = targetDate
                                calendarViewModel.selectDate(targetDate)
                            }
                        }
                    }
                }
                // Otherwise, let SwiftUI handle it (will wrap to previous week)
                
            case .right:
                // Only navigate to next month if we're at right edge AND at the end of the current month
                if isLastColumn && isInCurrentMonth {
                    // Check if we're at the actual end of the month
                    guard let monthStart = calendar.date(from: currentMonthComponents),
                          let monthEnd = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart) else {
                        return
                    }
                    if calendar.isDate(currentSelected, inSameDayAs: monthEnd) {
                        // Navigate to next month, same day of week (go forward 7 days)
                        if let targetDate = calendar.date(byAdding: .day, value: 7, to: currentSelected) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                calendarViewModel.currentDate = targetDate
                                calendarViewModel.selectDate(targetDate)
                            }
                        }
                    }
                }
                // Otherwise, let SwiftUI handle it (will wrap to next week)
                
            case .up:
                // Navigate to previous month if we're on the first row
                if isFirstRow && isInCurrentMonth {
                    // Go back 7 days (same day of week in previous month)
                    if let targetDate = calendar.date(byAdding: .day, value: -7, to: currentSelected) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            calendarViewModel.currentDate = targetDate
                            calendarViewModel.selectDate(targetDate)
                        }
                    }
                }
                // Otherwise, let SwiftUI handle it
                
            case .down:
                // Navigate to next month if we're on the last row
                if isLastRow && isInCurrentMonth {
                    // Go forward 7 days (same day of week in next month)
                    if let targetDate = calendar.date(byAdding: .day, value: 7, to: currentSelected) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            calendarViewModel.currentDate = targetDate
                            calendarViewModel.selectDate(targetDate)
                        }
                    }
                }
                // Otherwise, let SwiftUI handle it
                
            @unknown default:
                break
            }
#endif
        }
        .onExitCommand {
            // Back/Menu button behavior on tvOS:
            // - If day detail slide-out is visible, dismiss it
            // - Otherwise, open settings
            if calendarViewModel.showDayDetail {
                calendarViewModel.showDayDetail = false
            } else {
                calendarViewModel.showSettings = true
            }
        }
        .onPlayPauseCommand {
            // Play/Pause/Select button opens event management view on tvOS when day detail is visible
            if calendarViewModel.showDayDetail, let selectedDate = calendarViewModel.selectedDate {
                calendarViewModel.showDayDetail = false
                calendarViewModel.showTVEventManagement = true
            } else if calendarViewModel.selectedDate != nil {
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
            // Initialize theme color scheme on app launch
            themeManager.currentColorScheme = colorScheme
            
            checkCalendarPermissions()
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            // Defer state modification to avoid "Modifying state during view update" errors
            RunLoop.main.perform {
                themeManager.currentColorScheme = newValue
            }
        }
        .onChange(of: uiConfig.dayNumberFontSize) { oldValue, newValue in
            currentFontSize = newValue
            refreshTrigger = UUID()
        }
        .onChange(of: uiConfig.gridLineOpacity) {
            refreshTrigger = UUID()
        }
        .onChange(of: focusedDate) { oldValue, newFocusedDate in
            // Guard against re-entrant updates that cause double navigation
            guard !isUpdatingFocusSelection else { return }
            guard let date = newFocusedDate else { return }

#if os(tvOS)
            // On tvOS, sync selectedDate with focusedDate when focus changes
            // This ensures that as the user navigates with the remote, the selected date
            // stays in sync with the focused date, providing proper visual feedback
            let normalizedSelected = normalizedDate(calendarViewModel.selectedDate)
            let normalizedFocused = normalizedDate(date)
            
            if normalizedFocused != normalizedSelected {
                // Update immediately on tvOS to keep visual feedback in sync
                // Use Task to avoid "Modifying state during view update" errors while keeping it fast
                Task { @MainActor in
                    isUpdatingFocusSelection = true
                    calendarViewModel.selectDate(date)
                    // Reset guard flag after allowing one run loop iteration
                    try? await Task.sleep(nanoseconds: 1_000_000) // 0.001 seconds - minimal delay
                    isUpdatingFocusSelection = false
                }
            }
#else
            // On other platforms, sync selectedDate with focusedDate
            let normalizedSelected = normalizedDate(calendarViewModel.selectedDate)
            if date != normalizedSelected {
                // Defer state modification to avoid "Modifying state during view update" errors
                RunLoop.main.perform {
                    isUpdatingFocusSelection = true
                    calendarViewModel.selectDate(date)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isUpdatingFocusSelection = false
                    }
                }
            }
#endif
        }
        .onChange(of: calendarViewModel.selectedDate) { oldValue, newSelectedDate in
            // Guard against re-entrant updates that cause double navigation
            guard !isUpdatingFocusSelection else { return }
            guard let normalized = normalizedDate(newSelectedDate) else { return }

            // In month view, if the selected date is in a different month than currentDate,
            // defer focus update until currentDate changes (handled by onChange of currentDate)
            if calendarViewModel.viewMode == .month {
                let calendar = Calendar(identifier: .gregorian)
                let currentComponents = calendar.dateComponents([.year, .month], from: calendarViewModel.currentDate)
                let selectedComponents = calendar.dateComponents([.year, .month], from: normalized)

                // If dates are in different months, skip immediate focus update
                // It will be handled when currentDate changes
                if currentComponents != selectedComponents {
                    return
                }
            }

            if normalized != focusedDate {
                // Defer state modification to avoid "Modifying state during view update" errors
                RunLoop.main.perform {
                    isUpdatingFocusSelection = true
                    focusedDate = normalized
                    // Use a longer delay to ensure SwiftUI's focus system has settled
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isUpdatingFocusSelection = false
                    }
                }
            }
        }
        .onChange(of: calendarViewModel.currentDate) {
            // When currentDate changes (e.g., navigating to different month),
            // update focus after a brief delay to let the grid regenerate
            if calendarViewModel.viewMode == .month,
               let normalized = normalizedDate(calendarViewModel.selectedDate) {
                // Defer state modification to avoid "Modifying state during view update" errors
                RunLoop.main.perform {
                    isUpdatingFocusSelection = true
                    // Delay focus update to ensure grid has regenerated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedDate = normalized
                        // Reset guard after another brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isUpdatingFocusSelection = false
                        }
                    }
                }
            }
        }
        .onChange(of: calendarViewModel.showDayDetail) { oldValue, isShowing in
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
            // Full screen background with gradient that ignores safe areas
            CalendarGradientBackground(
                baseColor: themeManager.currentPalette.calendarBackground,
                colorScheme: colorScheme,
                intensity: .light
            )
            .ignoresSafeArea()
            
            if let backgroundImage = calendarViewModel.currentBackgroundImage {
                Image(platformImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.3)) // Add dimming overlay for readability
            }
            
            // Background animations (only in month view) - Edge to edge
            if calendarViewModel.viewMode == .month {
                MonthBackgroundAnimationView(currentDate: calendarViewModel.currentDate)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
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
            // Initialize theme color scheme on app launch
            themeManager.currentColorScheme = colorScheme
            
            checkCalendarPermissions()
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
                // Initialize theme color scheme on app launch
                themeManager.currentColorScheme = colorScheme
                
                checkCalendarPermissions()
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
            ZStack {
                // Background animations moved to ContentView root for edge-to-edge support
                
                VStack(spacing: 0) {
                    calendarHeader
                    calendarGrid
                }
            }
            .adaptivePadding(for: geometry)
#if os(iOS)
            .ignoresSafeArea(.keyboard) // Only ignore keyboard safe area, keep top/bottom safe areas
#endif
        }
#if os(tvOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            // Status bar with date/time display in top left corner
            StatusBarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
            alignment: .topLeading
        )
#elseif os(iOS)
        .ignoresSafeArea(.container, edges: []) // Respect safe areas for calendar content
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    let threshold: CGFloat = 50
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        // Horizontal swipe
                        if calendarViewModel.viewMode == .singleDay {
                            // In single day view, swiping left/right moves one day at a time.
                            if horizontalAmount > threshold {
                                calendarViewModel.moveLeftOneDay()
                            } else if horizontalAmount < -threshold {
                                calendarViewModel.moveRightOneDay()
                            }
                        } else if calendarViewModel.viewMode == .month {
                            // In month view, horizontal swipe navigates by month
                            if horizontalAmount > threshold {
                                // Swipe right - go to previous month
                                calendarViewModel.navigateDate(by: .month, direction: .backward)
                            } else if horizontalAmount < -threshold {
                                // Swipe left - go to next month
                                calendarViewModel.navigateDate(by: .month, direction: .forward)
                            }
                        } else {
                            // Other views: navigate by day
                            if horizontalAmount > threshold {
                                // Swipe right - go to previous day
                                calendarViewModel.navigateDate(by: .day, direction: .backward)
                            } else if horizontalAmount < -threshold {
                                // Swipe left - go to next day
                                calendarViewModel.navigateDate(by: .day, direction: .forward)
                            }
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
                        } else if calendarViewModel.viewMode != .singleDay {
                            // In other multi-day views, vertical swipe navigates by week
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
                .layoutPriority(0)
            
            Spacer()
            
            // Year display
            yearDisplay
                // Allow the year to take as much horizontal space as it needs and never truncate.
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
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
        let year = Calendar(identifier: .gregorian).component(.year, from: calendarViewModel.currentDate)
        let clampedYear = max(-6000, min(9999, year))
        return Text(String(clampedYear))
            .font(uiConfig.yearTitleFont)
            .foregroundColor(themeManager.currentPalette.yearText)
            .lineLimit(1) // Ensure it never wraps to multiple lines
            .minimumScaleFactor(0.8) // Prefer shrinking over truncation
    }
    
#if os(tvOS)
    // Check if locale uses day-first (European) or month-first (American) date format
    private var isEuropeanLocale: Bool {
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
    
    // Date format options for rotation (locale-aware, starting with numeric formats)
    private var dateFormats: [(Date) -> String] {
        var formats: [(Date) -> String] = []
        
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
    
    
#endif
    
    // Cache for calendar days to avoid unnecessary recalculations
    private static var calendarDaysCache: [String: [CalendarDay]] = [:]

    private var calendarGrid: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: daysPerRow)
            let days = getCachedCalendarDays()
            
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
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityLabel(dayName(for: index, availableWidth: 200)) // Use full name for accessibility
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
                        // Regular views: show day cells, except in single-day mode where we show
                        // a full day detail view instead of a grid cell.
                        if calendarViewModel.viewMode == .singleDay,
                           let selectedDate = calendarViewModel.selectedDate ?? days.first?.date {
                            GeometryReader { geometry in
                                DayDetailView(date: selectedDate)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
#if os(iOS)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
#endif
                        } else {
                            ForEach(days) { day in
#if os(tvOS)
                            Button(action: {
                                // Ensure the currently activated tile becomes the selected date before showing detail
                                calendarViewModel.selectDate(day.date)
                                calendarViewModel.toggleDayDetail()
                            }) {
                                DayView(
                                    day: day,
                                    geometry: geometry,
                                    cellHeight: cellHeight,
                                    columnsCount: daysPerRow,
                                    fontSize: currentFontSize,
                                    isExpandedLayout: calendarViewModel.viewMode.dayCount < 14 && calendarViewModel.viewMode != .agenda && calendarViewModel.viewMode != .year && calendarViewModel.viewMode != .month,
                                    focusedDate: focusedDate
                                )
                            }
                            .buttonStyle(.borderless)
                            .focused($focusedDate, equals: day.date)
#else
                            DayView(
                                day: day,
                                geometry: geometry,
                                cellHeight: cellHeight,
                                columnsCount: daysPerRow,
                                fontSize: currentFontSize,
                                isExpandedLayout: calendarViewModel.viewMode.dayCount < 14 && calendarViewModel.viewMode != .agenda && calendarViewModel.viewMode != .year && calendarViewModel.viewMode != .month
                            )
                            .onTapGesture(count: 2) {
                                handleDayDoubleClick(day.date)
                            }
                            // Removed .onTapGesture(count: 1) to avoid delay waiting for double tap failure
                            // Relying on .simultaneousGesture below for immediate highlighting
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
                                    Label("Create Event".localized, systemImage: "plus")
                                }
                                
                                Button(action: {
                                    calendarViewModel.selectedDate = day.date
                                    calendarViewModel.showEventTemplates = true
                                }) {
                                    Label("Quick Create".localized, systemImage: "sparkles")
                                }
                                
                                Divider()
                                
                                if !day.events.isEmpty {
                                    Button(action: {
                                        exportDayEvents(day.events)
                                    }) {
                                        Label("Export Events".localized, systemImage: "square.and.arrow.up")
                                    }
                                }
                                
                                Button(action: {
                                    calendarViewModel.selectDate(day.date)
                                    calendarViewModel.setViewMode(.singleDay)
                                }) {
                                    Label("View Day".localized, systemImage: "calendar")
                                }
                            }
#endif
                            }
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

    private func getCachedCalendarDays() -> [CalendarDay] {
        // Create a cache key based on view mode and the relevant date for that view
        // For month view, both currentDate (month displayed) and selectedDate (for isSelected) matter
        // For other views, both currentDate and selectedDate can affect layout
        var cacheKey: String
        switch calendarViewModel.viewMode {
        case .year:
            // For year view, only the currentDate determines the layout
            cacheKey = "\(calendarViewModel.viewMode.rawValue)_\(calendarViewModel.currentDate.timeIntervalSince1970)"
        case .month:
            // For month view, include selectedDate in cache key because isSelected depends on it
            cacheKey = "\(calendarViewModel.viewMode.rawValue)_\(calendarViewModel.currentDate.timeIntervalSince1970)_\(calendarViewModel.selectedDate?.timeIntervalSince1970 ?? 0)"
        default:
            // For day-based views, both currentDate and selectedDate can affect layout
            cacheKey = "\(calendarViewModel.viewMode.rawValue)_\(calendarViewModel.currentDate.timeIntervalSince1970)_\(calendarViewModel.selectedDate?.timeIntervalSince1970 ?? 0)"
        }

        // Check static cache first
        if let cachedDays = Self.calendarDaysCache[cacheKey] {
            return cachedDays
        }

        // Generate new days and cache them
        let days = generateCalendarDays()
        Self.calendarDaysCache[cacheKey] = days
        return days
    }
    
    private func normalizedDate(_ date: Date?) -> Date? {
        guard let date else { return nil }
        return Calendar(identifier: .gregorian).startOfDay(for: date)
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
        
        let calendar = Calendar(identifier: .gregorian)
        let days = generateCalendarDays()
        guard let index = days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) else {
            return false
        }
        
        let columns = daysPerRow
        switch direction {
        case .up:
            // Need manual handling if on first row
            return index < columns
        case .down:
            // Need manual handling if on last row
            return index >= days.count - columns
        case .left:
            // Need manual handling if at left edge of row (first column)
            // This allows navigation to previous week's last day
            return index % columns == 0
        case .right:
            // Need manual handling if at right edge of row (last column)
            // This allows navigation to next week's first day
            return (index % columns) == (columns - 1)
        @unknown default:
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
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        
        var days: [CalendarDay] = []
        
        // Create one representative day for each month
        for month in 1...12 {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            if let monthDate = calendar.date(from: components) {
                // Normalize to start of day for consistent focus matching
                let normalizedMonthDate = calendar.startOfDay(for: monthDate)
                let calendarDay = CalendarDay(
                    id: normalizedMonthDate,
                    date: normalizedMonthDate,
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
        let calendar = Calendar(identifier: .gregorian)
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
        let calendar = Calendar(identifier: .gregorian)
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
        let calendar = Calendar(identifier: .gregorian)
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
        let calendar = Calendar(identifier: .gregorian)
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
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: date)
        
        let events = calendarViewModel.events.filter { event in
            let eventStart = calendar.startOfDay(for: event.startDate)
            return eventStart == dayStart
        }
        
        // Use normalized date (dayStart) for id and date to ensure focus matching works correctly
        return CalendarDay(
            id: dayStart,
            date: dayStart,
            isToday: dayStart == today,
            isSelected: calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == dayStart } ?? false,
            events: events,
            isCurrentMonth: isCurrentMonth
        )
    }
    
    private func handleDayDoubleClick(_ date: Date) {
        // In single-day view on iOS, the main content *is* the day detail, so we don't
        // want to show a separate slide-over detail at all.
        #if os(iOS)
        if calendarViewModel.viewMode == .singleDay {
            return
        }
        #endif
        
        if calendarViewModel.viewMode != .singleDay {
            calendarViewModel.selectDate(date)
            calendarViewModel.toggleDayDetail()
        } else if calendarViewModel.selectedDate == date {
            calendarViewModel.toggleDayDetail()
        }
    }
    
    private func monthFont(for date: Date) -> String {
        let month = Calendar(identifier: .gregorian).component(.month, from: date)
        let fonts = [
            "Arial", "Helvetica", "Times New Roman", "Courier", "Georgia",
            "Verdana", "Trebuchet MS", "Impact", "Comic Sans MS", "Lucida Grande",
            "Futura", "Baskerville"
        ]
        return fonts[(month - 1) % fonts.count]
    }
    
    private func exportDayEvents(_ events: [CalendarEvent]) {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: calendarViewModel.selectedDate ?? Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        if let fileURL = EventExporter.exportEventsInDateRange(startDate: startOfDay, endDate: endOfDay, events: events) {
#if os(macOS)
            let sharingService = NSSharingServicePicker(items: [fileURL])
            if let window = NSApplication.shared.windows.first {
                sharingService.show(relativeTo: NSRect.zero, of: window.contentView!, preferredEdge: .minY)
            }
#elseif os(iOS)
            // Use the shared export logic which now handles iOS sharing
            EventExporter.shareEvents(fileURL: fileURL)
#endif
        }
    }
    
    private func checkCalendarPermissions() {
#if !os(tvOS)
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            // Delay slightly to ensure view is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showPermissionPrimer = true
            }
        }
#endif
    }
    
    private func requestCalendarAccess() {
#if !os(tvOS)
        let eventStore = EKEventStore()
        if #available(iOS 17.0, macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    showPermissionPrimer = false
                    if granted {
                        calendarViewModel.refresh()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    showPermissionPrimer = false
                    if granted {
                        calendarViewModel.refresh()
                    }
                }
            }
        }
#endif
    }
}

private func dayName(for columnIndex: Int, availableWidth: CGFloat? = nil) -> String {
    let calendar = Calendar(identifier: .gregorian)
    
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

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel())
}

