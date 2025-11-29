//
//  CalendarViewModel.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI
#if !os(tvOS)
import EventKit
#endif
import Combine
#if os(macOS)
import AppKit
#endif

class CalendarViewModel: ObservableObject {
    @Published var currentDate: Date = Date()
    @Published var selectedDate: Date?
    @Published var selectionAnimationId: UUID = UUID()
    @Published var viewMode: CalendarViewMode {
        didSet {
            // Save to UserDefaults when view mode changes
            UserDefaults.standard.set(viewMode.rawValue, forKey: "selectedViewMode")
        }
    }
    @Published var previousViewMode: CalendarViewMode? = nil
    @Published var showViewModeSelector = false // For iOS popup
    @Published var showSettings = false // For iOS settings

    enum NavigationDirection {
        case forward, backward
    }

    enum NavigationUnit {
        case day, week, month
    }

    func navigateDate(by unit: NavigationUnit, direction: NavigationDirection) {
        let calendar = Calendar(identifier: .gregorian)
        let multiplier = direction == .forward ? 1 : -1

        switch unit {
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: multiplier, to: currentDate) {
                currentDate = newDate
            }
        case .week:
            if let newDate = calendar.date(byAdding: .day, value: 7 * multiplier, to: currentDate) {
                currentDate = newDate
            }
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: multiplier, to: currentDate) {
                currentDate = newDate
            }
        }
    }
    @Published var events: [CalendarEvent] = []
    @Published var showDayDetail: Bool = false
    @Published var showSearch: Bool = false
    @Published var showKeyCommands: Bool = false
    @Published var isFullscreen: Bool = false
    @Published var showEventCreation: Bool = false
    @Published var showEventTemplates: Bool = false
    @Published var showImageSelection: Bool = false
    @Published var selectedEventForImage: CalendarEvent?

    #if !os(tvOS)
    private let eventStore = EKEventStore()
    #endif
    #if !os(tvOS)
    let googleOAuthManager = GoogleOAuthManager()
    private let googleCalendarAPI: GoogleCalendarAPI
    #else
    let googleOAuthManager: GoogleOAuthManager? = nil
    private let googleCalendarAPI: GoogleCalendarAPI? = nil
    #endif
    private let imageManager = ImageManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?

    init() {
        #if !os(tvOS)
        googleCalendarAPI = GoogleCalendarAPI(oauthManager: googleOAuthManager)
        #endif

        // Load saved view mode or default to month view on tvOS, threeDays otherwise
        if let savedModeString = UserDefaults.standard.string(forKey: "selectedViewMode"),
           let savedMode = CalendarViewMode(rawValue: savedModeString) {
            self.viewMode = savedMode
        } else {
            #if os(tvOS)
            self.viewMode = .month // Default to month view on tvOS
            #else
            self.viewMode = .threeDays // Default to threeDays on iOS/macOS
            #endif
        }

        #if !os(tvOS)
        // Check calendar authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            print("📅 Calendar access already granted")
            loadSystemEvents()
        case .notDetermined:
            requestCalendarAccess()
        case .denied, .restricted:
            print("📅 Calendar access denied or restricted")
        @unknown default:
            print("📅 Unknown calendar authorization status")
        }
        #endif

        setupKeyboardShortcuts()
        setupSyncTimer()
        loadAllEvents() // This will load Google events

        // Initialize selected date for tvOS
        #if os(tvOS)
        if selectedDate == nil {
            selectDate(Date()) // Select today by default on tvOS
        }
#endif
        // Apply monthly theme if enabled
        applyMonthlyThemeIfEnabled()
    }

    #if !os(tvOS)
    func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("📅 Calendar access granted")
                    self?.loadSystemEvents()
                } else {
                    print("📅 Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    #endif

    func loadAllEvents() {
        #if !os(tvOS)
        loadGoogleEvents()
        #endif
        // System events are loaded separately when calendar access is granted
    }

    /// Refresh all calendar data from both system and Google calendars
    func refresh() {
        print("🔄 Refreshing calendar data...")
        loadAllEvents()
    }

    #if !os(tvOS)
    private func loadSystemEvents() {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: currentDate)!
        let endDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: 2, to: currentDate)!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let ekEvents = self.eventStore.events(matching: predicate)
            let systemEvents = ekEvents.map { ekEvent in
                CalendarEvent(
                    id: "system_\(ekEvent.eventIdentifier ?? "unknown")",
                    title: ekEvent.title,
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    location: ekEvent.location,
                    notes: ekEvent.notes,
                    calendarIdentifier: ekEvent.calendar.calendarIdentifier,
                    isAllDay: ekEvent.isAllDay
                )
            }

            // Combine with existing events (keeping Google events)
            let googleEvents = self.events.filter { $0.id.hasPrefix("google_") }
            self.events = (systemEvents + googleEvents).sorted { $0.startDate < $1.startDate }
        }
    }
    #endif

    #if !os(tvOS)
    private func loadGoogleEvents() {
        guard googleOAuthManager.isAuthenticated else { return }

        let startDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: currentDate)!
        let endDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: 2, to: currentDate)!

        googleCalendarAPI.fetchEvents(from: startDate, to: endDate) { [weak self] googleEvents in
            guard let self = self, let googleEvents = googleEvents else { return }

            DispatchQueue.main.async {
                // Combine with existing events (keeping system events)
                let systemEvents = self.events.filter { $0.id.hasPrefix("system_") }
                self.events = (systemEvents + googleEvents).sorted { $0.startDate < $1.startDate }
            }
        }
    }
    #endif

    func setupKeyboardShortcuts() {
        // Keyboard shortcuts will be handled in the view
    }

    func navigateToNextMonth() {
        if viewMode == .year {
            navigateToNextYear()
        } else {
            if let newDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = newDate
                loadAllEvents()
                preloadHolidaysForDate(newDate)
            }
        }
        
        // Apply monthly theme if enabled (tvOS only)
        applyMonthlyThemeIfEnabled()
    }

    func navigateToPreviousMonth() {
        if viewMode == .year {
            navigateToPreviousYear()
        } else {
            if let newDate = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: currentDate) {
                currentDate = newDate
                loadAllEvents()
                preloadHolidaysForDate(newDate)
            }
        }
        
        // Apply monthly theme if enabled (tvOS only)
        applyMonthlyThemeIfEnabled()
    }

    func navigateToNextYear() {
        if let newDate = Calendar(identifier: .gregorian).date(byAdding: .year, value: 1, to: currentDate) {
            currentDate = newDate
            loadAllEvents()
            preloadHolidaysForDate(newDate)
        }
        
        // Apply monthly theme if enabled (tvOS only)
        applyMonthlyThemeIfEnabled()
    }

    func navigateToPreviousYear() {
        if let newDate = Calendar(identifier: .gregorian).date(byAdding: .year, value: -1, to: currentDate) {
            currentDate = newDate
            loadAllEvents()
            preloadHolidaysForDate(newDate)
        }
        
        // Apply monthly theme if enabled (tvOS only)
        applyMonthlyThemeIfEnabled()
    }

    func navigateToToday() {
        let today = Date()
        // Update selection animation ID to trigger animations
        selectionAnimationId = UUID()
        // Set selected date first, which will trigger proper alignment
        selectedDate = today
        // Align currentDate with the selection (this handles month/year view alignment)
        alignCurrentDateWithSelectionIfNeeded(today)
        // Load events for the new date range
        loadAllEvents()
        // Preload holidays for smooth navigation
        preloadHolidaysForDate(today)
        // Post notification to refresh calendar view
        NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
        
        // Apply monthly theme if enabled (tvOS only)
        applyMonthlyThemeIfEnabled()
    }
    
    /// Preload holidays for a given date to ensure smooth navigation
    private func preloadHolidaysForDate(_ date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        HolidayManager.shared.preloadHolidaysForYearRange(centerYear: year, range: 2)
    }

    func selectDate(_ date: Date) {
        // Normalize to start of day for consistent focus/selection matching
        let calendar = Calendar(identifier: .gregorian)
        let normalizedDate = calendar.startOfDay(for: date)
        selectedDate = normalizedDate
        // Change animation ID to cancel any previous animations and start fresh
        selectionAnimationId = UUID()
        alignCurrentDateWithSelectionIfNeeded(normalizedDate)
        applyMonthlyThemeIfEnabled()
    }

    func toggleDayDetail() {
        showDayDetail.toggle()
    }

    enum CursorDirection {
        case left, right, up, down
    }

    func moveSelectedDate(_ direction: CursorDirection) {
        guard let currentSelectedDate = selectedDate else {
            // If no date is selected, select today
            selectDate(Date())
            return
        }

        let calendar = Calendar(identifier: .gregorian)
        var newDate: Date

        switch direction {
        case .left:
            newDate = calendar.date(byAdding: .day, value: -1, to: currentSelectedDate) ?? currentSelectedDate
        case .right:
            newDate = calendar.date(byAdding: .day, value: 1, to: currentSelectedDate) ?? currentSelectedDate
        case .up:
            newDate = calendar.date(byAdding: .day, value: -7, to: currentSelectedDate) ?? currentSelectedDate
        case .down:
            newDate = calendar.date(byAdding: .day, value: 7, to: currentSelectedDate) ?? currentSelectedDate
        }

        // Normalize to start of day for consistent focus/selection matching
        self.selectedDate = calendar.startOfDay(for: newDate)
        ensureSelectedDateIsVisible()
    }

    func setViewMode(_ mode: CalendarViewMode) {
        // Save previous view mode for toggling back
        if mode != .year {
            previousViewMode = viewMode
        }
        viewMode = mode
    }

    func toggleYearView() {
        if viewMode == .year {
            // Return to previous view or month view
            viewMode = previousViewMode ?? .month
            previousViewMode = nil
        } else {
            // Save current view and switch to year view
            previousViewMode = viewMode
            viewMode = .year
        }
    }

    func moveUpOneWeek() {
        let calendar = Calendar(identifier: .gregorian)
        if let selectedDate = selectedDate,
           let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            // Normalize to start of day for consistent focus/selection matching
            self.selectedDate = calendar.startOfDay(for: newDate)
            ensureSelectedDateIsVisible()
        }
    }

    func moveDownOneWeek() {
        let calendar = Calendar(identifier: .gregorian)
        if let selectedDate = selectedDate,
           let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
            // Normalize to start of day for consistent focus/selection matching
            self.selectedDate = calendar.startOfDay(for: newDate)
            ensureSelectedDateIsVisible()
        }
    }

    func moveLeftOneDay() {
        let calendar = Calendar(identifier: .gregorian)
        if let selectedDate = selectedDate,
           let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            // Normalize to start of day for consistent focus/selection matching
            self.selectedDate = calendar.startOfDay(for: newDate)
            ensureSelectedDateIsVisible()
        }
    }

    func moveRightOneDay() {
        let calendar = Calendar(identifier: .gregorian)
        if let selectedDate = selectedDate,
           let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            // Normalize to start of day for consistent focus/selection matching
            self.selectedDate = calendar.startOfDay(for: newDate)
            ensureSelectedDateIsVisible()
        }
    }

    /// Ensures the selected date is visible in the current view by updating currentDate if necessary
    private func ensureSelectedDateIsVisible() {
        guard let selectedDate = selectedDate else { return }
        alignCurrentDateWithSelectionIfNeeded(selectedDate)
        applyMonthlyThemeIfEnabled()
    }

    private func alignCurrentDateWithSelectionIfNeeded(_ date: Date) {
        let calendar = Calendar(identifier: .gregorian)

        switch viewMode {
        case .month:
            let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
            let selectedComponents = calendar.dateComponents([.year, .month], from: date)

            if currentComponents != selectedComponents,
               let newCurrentDate = calendar.date(from: selectedComponents) {
                currentDate = newCurrentDate
                loadAllEvents()
            }

        case .year:
            let currentYear = calendar.component(.year, from: currentDate)
            let selectedYear = calendar.component(.year, from: date)

            if currentYear != selectedYear {
                if let newCurrentDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) {
                    currentDate = newCurrentDate
                    loadAllEvents()
                }
            }

        default:
            // For day-based views, only change currentDate if selection is outside visible range
            let dayCount = viewMode.dayCount
            if dayCount == 1 || dayCount == 0 {
                // For single day or agenda view, always match currentDate to selection
                if !calendar.isDate(currentDate, inSameDayAs: date) {
                    currentDate = date
                    loadAllEvents()
                }
            } else {
                // For multi-day views, check if selection is within visible range
                let rangeDays = dayCount / 2  // e.g., for 14 days, range = 7
                let rangeStart = calendar.date(byAdding: .day, value: -rangeDays, to: currentDate)!
                let rangeEnd = calendar.date(byAdding: .day, value: rangeDays, to: currentDate)!

                // Change currentDate only if selection is outside the visible range
                if date < rangeStart || date > rangeEnd {
                    currentDate = date
                    loadAllEvents()
                }
            }
        }
    }

    func toggleFullscreen() {
        isFullscreen.toggle()
        #if os(macOS)
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.toggleFullScreen(nil)
            }
        }
        #endif
    }

    func toggleSearch() {
        showSearch.toggle()
    }

    func toggleKeyCommands() {
        showKeyCommands.toggle()
    }

    // MARK: - Image Management

    func selectImageForEvent(_ event: CalendarEvent) {
        selectedEventForImage = event
        showImageSelection = true
    }

    func assignImageToEvent(_ event: CalendarEvent, imageId: String) {
        event.imageRepositoryId = imageId
        objectWillChange.send()
    }

    func getImageForEvent(_ event: CalendarEvent) -> PlatformImage? {
        guard let imageId = event.imageRepositoryId else { return nil }
        return imageManager.getImage(for: imageId)
    }

    func getImageMetadataForEvent(_ event: CalendarEvent) -> ImageMetadata? {
        guard let imageId = event.imageRepositoryId else { return nil }
        return imageManager.getImageMetadata(for: imageId)
    }

    func fetchImageForEvent(_ event: CalendarEvent, completion: @escaping (String?) -> Void) {
        imageManager.findOrFetchImage(for: event, completion: completion)
    }

    private func setupSyncTimer() {
        // Set up a timer to sync every 15 minutes (900 seconds)
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            print("⏰ Auto-syncing calendar data (15-minute interval)")
            self?.syncCalendars()
        }
        // Make sure the timer doesn't prevent the app from sleeping
        syncTimer?.tolerance = 60 // Allow 1 minute tolerance
    }

    private func syncCalendars() {
        // Force a reload of all calendar data
        loadAllEvents()
    }

    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Monthly Theme Support (tvOS only)
    
    /// Get the ColorTheme for a given month (1-12)
    static func monthlyThemeForMonth(_ month: Int) -> ColorTheme {
        switch month {
        case 1: return .january
        case 2: return .february
        case 3: return .march
        case 4: return .april
        case 5: return .may
        case 6: return .june
        case 7: return .july
        case 8: return .august
        case 9: return .september
        case 10: return .october
        case 11: return .november
        case 12: return .december
        default: return .january
        }
    }
    
    /// Apply the monthly theme if monthly theme mode is enabled
    private func applyMonthlyThemeIfEnabled() {
        let featureFlags = FeatureFlags.shared
        guard featureFlags.useMonthlyThemeMode else { return }
        
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: currentDate)
        let monthlyTheme = CalendarViewModel.monthlyThemeForMonth(month)
        
        ThemeManager.shared.setTheme(monthlyTheme)
    }
}
