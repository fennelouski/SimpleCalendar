//
//  TVEventCreationView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/29/25.
//

import SwiftUI

struct TVEventCreationView: View {
    let selectedDate: Date
    let editingEvent: CalendarEvent?
    let onEventCreated: (CalendarEvent) -> Bool

    @State private var pendingEventColor: String?
    @State private var pendingEventEmoji: String?
    @State private var eventUUID: String

    init(selectedDate: Date, editingEvent: CalendarEvent? = nil, onEventCreated: @escaping (CalendarEvent) -> Bool) {
        self.selectedDate = selectedDate
        self.editingEvent = editingEvent
        self.onEventCreated = onEventCreated
        self._eventUUID = State(initialValue: UUID().uuidString)
    }

    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    // Form fields
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isAllDay = false
    @State private var location = ""
    @State private var notes = ""

    // Text input state
    @State private var naturalLanguageInput = ""
    @State private var isProcessingText = false
    @State private var parseTask: Task<Void, Never>?
    @State private var parseRequestID = UUID()
    @State private var parseMessage: String?
    @State private var hasInitialized = false
    @AppStorage("aiEventSharingConsent_v1") private var aiSharingConsent = false

    // Focused field for manual editing
    @State private var focusedField: Field? = nil
    @FocusState private var titleFocused: Bool
    @FocusState private var locationFocused: Bool
    @FocusState private var notesFocused: Bool

    enum Field {
        case title, location, notes
    }

    private var isEditing: Bool {
        editingEvent != nil
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if let error = calendarViewModel.storageError { Text(error).foregroundStyle(.red).padding() }
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isEditing ? "Edit Event".localized : "Create New Event".localized)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        Text("For %@".localized(with: dateFormatter.string(from: selectedDate)))
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }

                    // Natural language input section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Describe Your Event".localized)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Natural Language Description".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.currentPalette.calendarBackground.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeManager.currentPalette.primary.opacity(0.3), lineWidth: 1)
                                    )
                                    .frame(height: 60)

                                TextField("Type or dictate: 'Doctor appointment at 2 PM tomorrow'".localized, text: $naturalLanguageInput)
                                    .font(.system(size: 18))
                                    .padding(12)
                                    .foregroundColor(naturalLanguageInput.isEmpty ? themeManager.currentPalette.textSecondary.opacity(0.6) : themeManager.currentPalette.textPrimary)
                                    .onChange(of: naturalLanguageInput) { oldValue, newValue in
                                        cancelParsing()
                                    }
                            }
                        }

                        Text("Optional AI parsing sends this description, the selected date, and your time zone to Calendar Play's server and OpenAI. Review the returned details before saving. Repeating details are saved as notes; this creates one event.")
                            .font(.system(size: 16))
                        Toggle("Allow sharing this device's event descriptions with OpenAI", isOn: $aiSharingConsent)
                            .onChange(of: aiSharingConsent) { _, allowed in
                                if !allowed { cancelParsing() }
                            }
                        Link("Privacy policy", destination: URL(string: "https://nathanfennel.com/calendar-play/privacy.html")!)
                        Button(isProcessingText ? "Cancel parsing" : "Parse event with AI") {
                            if isProcessingText { cancelParsing() } else { parseNaturalLanguageInput() }
                        }
                        .disabled(!aiSharingConsent || naturalLanguageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || naturalLanguageInput.count > 2000)
                        if naturalLanguageInput.count > 2000 { Text("Use no more than 2,000 characters.").foregroundStyle(.red) }
                        if isProcessingText { ProgressView("Parsing event...") }
                        if let parseMessage { Text(parseMessage).font(.system(size: 16)) }
                    }

                    // Form fields
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Event Details".localized)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)

                            FocusableTextField(
                                text: $title,
                                placeholder: "Enter event title".localized,
                                isFocused: focusedField == .title
                            ) {
                                focusedField = .title
                            }
                            .focused($titleFocused)
                        }

                        // Date and Time
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date & Time".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)

                            Toggle("All Day".localized, isOn: $isAllDay)
                                .font(.system(size: 18))
                                .onChange(of: isAllDay) { _, allDay in
                                    if allDay {
                                        startDate = Calendar.current.startOfDay(for: startDate)
                                        endDate = Calendar.current.startOfDay(for: endDate)
                                        if endDate <= startDate {
                                            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                                        }
                                    }
                                }

                            if !isAllDay {
                                HStack(spacing: 20) {
                                    TVDatePicker(label: "Start".localized, date: $startDate)
                                    TVDatePicker(label: "End".localized, date: $endDate)
                                }
                            } else {
                                HStack(spacing: 20) {
                                    TVDatePicker(label: "First day", date: $startDate, includesTime: false)
                                    TVDatePicker(label: "End date, not included", date: $endDate, includesTime: false)
                                }
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)

                            FocusableTextField(
                                text: $location,
                                placeholder: "Enter location".localized,
                                isFocused: focusedField == .location
                            ) {
                                focusedField = .location
                            }
                            .focused($locationFocused)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)

                            FocusableTextField(
                                text: $notes,
                                placeholder: "Enter notes".localized,
                                isFocused: focusedField == .notes
                            ) {
                                focusedField = .notes
                            }
                            .focused($notesFocused)
                        }
                    }
                    .disabled(isProcessingText)
                }
                .padding(40)
            }
            .background(themeManager.currentPalette.calendarSurface)
            .onDisappear { cancelParsing() }
            .onAppear {
                guard !hasInitialized else { return }
                hasInitialized = true
                if let editingEvent = editingEvent {
                    loadEventForEditing(editingEvent)
                } else {
                    initializeForNewEvent()
                }
            }
            #if os(tvOS)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel".localized)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                },
                trailing: Button(action: saveEvent) {
                    Text(isEditing ? "Update".localized : "Create".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(title.isEmpty ? themeManager.currentPalette.textSecondary.opacity(0.5) : themeManager.currentPalette.primary)
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessingText)
            )
            #endif
        }
        #if os(tvOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func cancelParsing() {
        parseTask?.cancel()
        parseTask = nil
        parseRequestID = UUID()
        isProcessingText = false
        parseMessage = nil
    }

    private func parseNaturalLanguageInput() {
        guard aiSharingConsent, !isProcessingText else { return }
        let input = naturalLanguageInput
        let requestID = UUID()
        parseRequestID = requestID
        isProcessingText = true
        parseMessage = nil
        parseTask = Task { @MainActor in
            do {
                let parsed = try await EventDescriptionParser.parse(input, selectedDate: selectedDate)
                guard !Task.isCancelled, aiSharingConsent, parseRequestID == requestID,
                      naturalLanguageInput == input else { return }
                applyParsedEvent(parsed)
                parseMessage = "Event details filled in. Review them before saving."
            } catch {
                guard !Task.isCancelled, parseRequestID == requestID else { return }
                parseMessage = "The event could not be parsed. Try again or enter the details below."
            }
            guard parseRequestID == requestID else { return }
            isProcessingText = false
            parseTask = nil
        }
    }

    internal func applyParsedEvent(_ parsed: ParsedEventResponse) {
        title = parsed.title ?? title

        if let startDateStr = parsed.startDate {
            startDate = EventDescriptionParser.date(startDateStr) ?? startDate
        }

        if let endDateStr = parsed.endDate {
            endDate = EventDescriptionParser.date(endDateStr) ?? endDate
        }

        isAllDay = parsed.isAllDay ?? isAllDay
        location = parsed.location ?? location
        notes = parsed.notes ?? notes

        // Handle recurrence if present
        // Note: For this implementation, we'll store recurrence info in notes
        if let recurrence = parsed.recurrence {
            var recurrenceText = "\n\nRecurring: ".localized
            switch recurrence.frequency {
            case "daily":
                recurrenceText += "Daily".localized
            case "weekly":
                recurrenceText += "Weekly".localized
            case "monthly":
                recurrenceText += "Monthly".localized
            case "yearly":
                recurrenceText += "Yearly".localized
            default:
                recurrenceText += recurrence.frequency
            }

            if recurrence.interval > 1 {
                recurrenceText += " (every %d)".localized(with: recurrence.interval)
            }

            if let endDate = recurrence.endDate {
                recurrenceText += " until %@".localized(with: endDate)
            }

            notes += recurrenceText + "\nRepeating details only. This is a single event."
        }

        // Store color and emoji for later use in event creation
        if let color = parsed.color {
            pendingEventColor = color
        }
        if let emoji = parsed.emoji {
            pendingEventEmoji = emoji
        }
    }

    private func initializeForNewEvent() {
        let calendar = Calendar(identifier: .gregorian)
        startDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
    }

    private func loadEventForEditing(_ event: CalendarEvent) {
        title = event.title
        startDate = event.startDate
        endDate = event.endDate
        isAllDay = event.isAllDay
        location = event.location ?? ""
        notes = event.notes ?? ""
        pendingEventColor = event.color
        pendingEventEmoji = event.emoji
    }

    internal func saveEvent() {
        guard !title.isEmpty else { return }

        let eventId = editingEvent?.id ?? "tv_\(eventUUID)"
        let calendarEvent = CalendarEvent(
            id: eventId,
            title: title,
            startDate: isAllDay ? Calendar.current.startOfDay(for: startDate) : startDate,
            endDate: isAllDay ? Calendar.current.startOfDay(for: endDate) : endDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            calendarIdentifier: "tv_local",
            isAllDay: isAllDay,
            imageUrl: editingEvent?.imageUrl,
            imageRepositoryId: editingEvent?.imageRepositoryId,
            color: pendingEventColor,
            emoji: pendingEventEmoji
        )

        if onEventCreated(calendarEvent) { presentationMode.wrappedValue.dismiss() }
    }

}

// Supporting views and structs
struct FocusableTextField: View {
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let onFocus: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TextField(placeholder, text: $text)
                .font(.system(size: 18))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.currentPalette.calendarBackground.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isFocused ? themeManager.currentPalette.primary : themeManager.currentPalette.primary.opacity(0.3), lineWidth: 2)
                        )
                )
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .onTapGesture(perform: onFocus)
    }
}

struct TVDatePicker: View {
    let label: String
    @Binding var date: Date
    var includesTime = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label).font(.headline)
            Text(date.formatted(date: .abbreviated, time: includesTime ? .shortened : .omitted))
                .accessibilityLabel("\(label): \(date.formatted(date: .complete, time: .shortened))")
            adjustment("Year", component: .year)
            adjustment("Month", component: .month)
            adjustment("Day", component: .day)
            if includesTime {
                adjustment("Hour", component: .hour)
                adjustment("Minute", component: .minute)
            }
        }
    }

    private func adjustment(_ name: String, component: Calendar.Component) -> some View {
        HStack {
            Button { shift(component, by: -1) } label: { Image(systemName: "minus") }
                .accessibilityLabel("\(label): previous \(name.lowercased())")
            Text(name).frame(maxWidth: .infinity)
            Button { shift(component, by: 1) } label: { Image(systemName: "plus") }
                .accessibilityLabel("\(label): next \(name.lowercased())")
        }
    }

    private func shift(_ component: Calendar.Component, by value: Int) {
        if let updated = Calendar.current.date(byAdding: component, value: value, to: date) { date = updated }
    }
}
