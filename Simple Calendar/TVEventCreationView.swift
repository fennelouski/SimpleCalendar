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
    let onEventCreated: (CalendarEvent) -> Void

    @State private var pendingEventColor: String?
    @State private var pendingEventEmoji: String?
    @State private var eventUUID: String

    init(selectedDate: Date, editingEvent: CalendarEvent? = nil, onEventCreated: @escaping (CalendarEvent) -> Void) {
        self.selectedDate = selectedDate
        self.editingEvent = editingEvent
        self.onEventCreated = onEventCreated
        self._eventUUID = State(initialValue: UUID().uuidString)
    }

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
    @State private var parseTimer: Timer?

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
                                        handleTextInputChange(newValue)
                                    }
                            }
                        }

                        // Status indicator for automatic parsing
                        if !naturalLanguageInput.isEmpty {
                            HStack(spacing: 8) {
                                if isProcessingText {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Parsing event...".localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                } else if shouldParseText(naturalLanguageInput) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 18))
                                    Text("Event parsed automatically".localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                } else {
                                    Image(systemName: "text.bubble")
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                        .font(.system(size: 18))
                                    Text("Type at least 20 characters with 5 words to auto-parse".localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 8)
                        }
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

                            if !isAllDay {
                                HStack(spacing: 20) {
                                    TVDatePicker(label: "Start".localized, date: $startDate)
                                    TVDatePicker(label: "End".localized, date: $endDate)
                                }
                            } else {
                                Text("Event will last all day".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.7))
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
                }
                .padding(40)
            }
            .background(themeManager.currentPalette.calendarSurface)
            .onAppear {
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
                .disabled(title.isEmpty)
            )
            #endif
        }
        #if os(tvOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func parseNaturalLanguageInput(_ input: String) {
        isProcessingText = true

        // Call the Vercel API to parse the natural language input
        Task {
            do {
                let parsedEvent = try await parseEventDescription(input, selectedDate: selectedDate)
                DispatchQueue.main.async {
                    applyParsedEvent(parsedEvent)
                    isProcessingText = false
                }
            } catch {
                print("Failed to parse event: \(error)")
                DispatchQueue.main.async {
                    isProcessingText = false
                }
            }
        }
    }

    private func parseEventDescription(_ description: String, selectedDate: Date) async throws -> ParsedEventResponse {
        // Deployed Vercel API URL
        let url = URL(string: "https://calendar-play-jzwil01cs-nathan-fennels-projects.vercel.app/api/parse-event")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "description": description,
            "selectedDate": ISO8601DateFormatter().string(from: selectedDate)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ParsedEventResponse.self, from: data)
        return response
    }

    internal func applyParsedEvent(_ parsed: ParsedEventResponse) {
        title = parsed.title ?? title

        if let startDateStr = parsed.startDate {
            startDate = ISO8601DateFormatter().date(from: startDateStr) ?? startDate
        }

        if let endDateStr = parsed.endDate {
            endDate = ISO8601DateFormatter().date(from: endDateStr) ?? endDate
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

            notes += recurrenceText
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

        let eventId = editingEvent?.id ?? "tv_\(UUID().uuidString)"
        let calendarEvent = CalendarEvent(
            id: eventId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            calendarIdentifier: "tv_local",
            isAllDay: isAllDay,
            color: pendingEventColor,
            emoji: pendingEventEmoji
        )

        onEventCreated(calendarEvent)
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - Automatic Parsing Logic

    private func handleTextInputChange(_ newText: String) {
        // Cancel any existing timer
        parseTimer?.invalidate()

        // Start new timer if text meets criteria
        if shouldParseText(newText) {
            parseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
                Task {
                    await parseNaturalLanguageInput(newText)
                }
            }
        }
    }

    private func shouldParseText(_ text: String) -> Bool {
        let characterCount = text.count >= 20
        let wordCount = text.split(separator: " ").count >= 5
        return characterCount && wordCount
    }

    private func parseNaturalLanguageInput(_ input: String) async {
        guard !isProcessingText else { return }

        isProcessingText = true
        defer { isProcessingText = false }

        do {
            // Call the Vercel API
            let apiURL = URL(string: "http://localhost:3002/api/parse-event")!
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: Any] = [
                "text": input,
                "currentDate": ISO8601DateFormatter().string(from: selectedDate)
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("API call failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }

            let parsedEvent = try JSONDecoder().decode(ParsedEventResponse.self, from: data)

            // Update form fields on main thread
            await MainActor.run {
                if let parsedTitle = parsedEvent.title {
                    title = parsedTitle
                }
                if let parsedStartDate = parsedEvent.startDate,
                   let startDateObj = ISO8601DateFormatter().date(from: parsedStartDate) {
                    startDate = startDateObj
                }
                if let parsedEndDate = parsedEvent.endDate,
                   let endDateObj = ISO8601DateFormatter().date(from: parsedEndDate) {
                    endDate = endDateObj
                }
                if let parsedLocation = parsedEvent.location {
                    location = parsedLocation
                }
                if let parsedNotes = parsedEvent.notes {
                    notes = parsedNotes
                }
                if let parsedIsAllDay = parsedEvent.isAllDay {
                    isAllDay = parsedIsAllDay
                }
                pendingEventColor = parsedEvent.color
                pendingEventEmoji = parsedEvent.emoji
            }
        } catch {
            print("Failed to parse event: \(error.localizedDescription)")
            // Silently fail for better UX - user can still manually fill fields
        }
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
        Button(action: onFocus) {
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
        }
        .buttonStyle(.plain)
    }
}

struct TVDatePicker: View {
    let label: String
    @Binding var date: Date

    @EnvironmentObject var themeManager: ThemeManager

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentPalette.textSecondary)

            Button(action: {
                // In a real implementation, you'd show a date picker
                // For now, just show the current value
            }) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.currentPalette.calendarBackground.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager.currentPalette.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct ParsedEventResponse: Codable {
    let title: String?
    let startDate: String?
    let endDate: String?
    let isAllDay: Bool?
    let location: String?
    let notes: String?
    let color: String?
    let emoji: String?
    let recurrence: RecurrenceInfo?

    struct RecurrenceInfo: Codable {
        let frequency: String
        let interval: Int
        let endDate: String?
        let daysOfWeek: [Int]?
    }
}
