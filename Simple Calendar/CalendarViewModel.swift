//
//  CalendarViewModel.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI
import EventKit
import Combine
#if os(macOS)
import AppKit
#endif

class CalendarViewModel: ObservableObject {
    @Published var currentDate: Date = Date()
    @Published var selectedDate: Date?
    @Published var viewMode: CalendarViewMode = .month
    @Published var previousViewMode: CalendarViewMode? = nil
    @Published var events: [CalendarEvent] = []
    @Published var showDayDetail: Bool = false
    @Published var showSearch: Bool = false
    @Published var showKeyCommands: Bool = false
    @Published var isFullscreen: Bool = false
    @Published var showEventCreation: Bool = false
    @Published var showEventTemplates: Bool = false
    @Published var showImageSelection: Bool = false
    @Published var selectedEventForImage: CalendarEvent?

    private let eventStore = EKEventStore()
    let googleOAuthManager = GoogleOAuthManager()
    private let googleCalendarAPI: GoogleCalendarAPI
    private let imageManager = ImageManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        googleCalendarAPI = GoogleCalendarAPI(oauthManager: googleOAuthManager)

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

        setupKeyboardShortcuts()
        loadAllEvents() // This will load Google events
    }

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
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

    func loadAllEvents() {
        loadGoogleEvents()
        // System events are loaded separately when calendar access is granted
    }

    /// Refresh all calendar data from both system and Google calendars
    func refresh() {
        print("🔄 Refreshing calendar data...")
        loadAllEvents()
    }

    private func loadSystemEvents() {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        let endDate = Calendar.current.date(byAdding: .month, value: 2, to: currentDate)!

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

    private func loadGoogleEvents() {
        guard googleOAuthManager.isAuthenticated else { return }

        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        let endDate = Calendar.current.date(byAdding: .month, value: 2, to: currentDate)!

        googleCalendarAPI.fetchEvents(from: startDate, to: endDate) { [weak self] googleEvents in
            guard let self = self, let googleEvents = googleEvents else { return }

            DispatchQueue.main.async {
                // Combine with existing events (keeping system events)
                let systemEvents = self.events.filter { $0.id.hasPrefix("system_") }
                self.events = (systemEvents + googleEvents).sorted { $0.startDate < $1.startDate }
            }
        }
    }

    func setupKeyboardShortcuts() {
        // Keyboard shortcuts will be handled in the view
    }

    func navigateToNextMonth() {
        if viewMode == .year {
            navigateToNextYear()
        } else {
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = newDate
                loadAllEvents()
            }
        }
    }

    func navigateToPreviousMonth() {
        if viewMode == .year {
            navigateToPreviousYear()
        } else {
            if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                currentDate = newDate
                loadAllEvents()
            }
        }
    }

    func navigateToNextYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) {
            currentDate = newDate
            loadAllEvents()
        }
    }

    func navigateToPreviousYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) {
            currentDate = newDate
            loadAllEvents()
        }
    }

    func navigateToToday() {
        currentDate = Date()
        selectedDate = Date()
        loadAllEvents()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
    }

    func toggleDayDetail() {
        showDayDetail.toggle()
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
        if let selectedDate = selectedDate {
            self.selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate)
        }
    }

    func moveDownOneWeek() {
        if let selectedDate = selectedDate {
            self.selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate)
        }
    }

    func moveLeftOneDay() {
        if let selectedDate = selectedDate {
            self.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)
        }
    }

    func moveRightOneDay() {
        if let selectedDate = selectedDate {
            self.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)
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
}
