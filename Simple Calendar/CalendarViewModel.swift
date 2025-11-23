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
    private let googleOAuthManager = GoogleOAuthManager()
    private let googleCalendarAPI: GoogleCalendarAPI
    private let imageManager = ImageManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        googleCalendarAPI = GoogleCalendarAPI(oauthManager: googleOAuthManager)
        requestCalendarAccess()
        setupKeyboardShortcuts()
        loadAllEvents()
    }

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            if granted {
                self?.loadAllEvents()
            }
        }
    }

    func loadAllEvents() {
        loadSystemEvents()
        loadGoogleEvents()
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
        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
        loadAllEvents()
    }

    func navigateToPreviousMonth() {
        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
        loadAllEvents()
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
        viewMode = mode
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
