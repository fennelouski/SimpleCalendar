//
//  EventCreationView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
#if !os(tvOS)
import EventKit
#endif
import MapKit

struct EventCreationView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var location = ""
    @State private var notes = ""
    @State private var invitees = ""
    @State private var isAllDay = false
    #if !os(tvOS)
    @State private var selectedCalendar: EKCalendar?
    #endif

    @State private var showRecurrencePicker = false
    #if !os(tvOS)
    @State private var recurrenceRule: EKRecurrenceRule?
    #endif

    @State private var showReminderPicker = false
    @State private var reminderMinutes = 15
    @State private var showImageSelection = false
    @State private var selectedImageId: String?

    #if !os(tvOS)
    private let eventStore = EKEventStore()
    #endif

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details".localized)) {
                    TextField("Title".localized, text: $title)
                        .font(.headline)

                    Toggle("All Day".localized, isOn: $isAllDay)

                    #if os(tvOS)
                    // tvOS - date selection not available, uses current date
                    Text("Event will use current date and time".localized)
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    #else
                    if !isAllDay {
                        DatePicker("Start Time".localized, selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time".localized, selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        DatePicker("Date".localized, selection: $startDate, displayedComponents: [.date])
                    }
                    #endif
                }

                Section(header: Text("Additional Information".localized)) {
                    TextField("Location".localized, text: $location)
                    #if os(tvOS)
                    TextField("Notes", text: $notes)
                    #else
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                        if notes.isEmpty {
                            Text("Notes".localized)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    #endif
                }

                Section(header: Text("Invitees".localized)) {
                    TextField("Email addresses (comma separated)".localized, text: $invitees)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                }

                #if !os(tvOS)
                Section(header: Text("Calendar".localized)) {
                    Picker("Calendar".localized, selection: $selectedCalendar) {
                        ForEach(eventStore.calendars(for: .event), id: \.calendarIdentifier) { calendar in
                            Text(calendar.title)
                                .tag(calendar as EKCalendar?)
                        }
                    }
                }
                #endif

                Section(header: Text("Image".localized)) {
                    Button(action: { showImageSelection = true }) {
                        HStack {
                            Text("Event Image".localized)
                            Spacer()
                            if let imageId = selectedImageId,
                               let image = ImageManager.shared.getImage(for: imageId) {
                                Image(platformImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else if selectedImageId != nil {
                                Image(systemName: "photo")
                                    .foregroundColor(themeManager.currentPalette.primary)
                            } else {
                                Text("None".localized)
                                    .foregroundColor(themeManager.currentPalette.textSecondary)
                            }
                        }
                    }
                    .accessibilityLabel("Event Image".localized)
                    .accessibilityValue(selectedImageId != nil ? "Image selected".localized : "None".localized)
                    .accessibilityHint("Double tap to choose an image".localized)
                }

                #if !os(tvOS)
                if !location.isEmpty {
                    Section(header: Text("Location Map".localized)) {
                        EventMapView(location: location)
                    }
                }
                #endif

                #if !os(tvOS)
                Section {
                    Button(action: { showRecurrencePicker = true }) {
                        HStack {
                            Text("Repeat".localized)
                            Spacer()
                            Text(recurrenceRule?.description ?? "Never".localized)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                    }
                    .accessibilityLabel("Repeat".localized)
                    .accessibilityValue(recurrenceRule?.description ?? "Never".localized)
                    .accessibilityHint("Double tap to set recurrence".localized)
                }
                #endif

                Section {
                    Button(action: { showReminderPicker = true }) {
                        HStack {
                            Text("Reminder".localized)
                            Spacer()
                            Text(reminderText)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                    }
                    .accessibilityLabel("Reminder".localized)
                    .accessibilityValue(reminderText)
                    .accessibilityHint("Double tap to set reminder".localized)
                }
            }
            .navigationTitle("New Event".localized)
            HStack {
                Button("Cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Save".localized) {
                    saveEvent()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        #if !os(tvOS)
        .sheet(isPresented: $showRecurrencePicker) {
            RecurrencePickerView(recurrenceRule: $recurrenceRule)
        }
        #endif
        #if !os(tvOS)
        .sheet(isPresented: $showReminderPicker) {
            ReminderPickerView(reminderMinutes: $reminderMinutes)
        }
        #endif
        .sheet(isPresented: $showImageSelection) {
            ImageSelectionView(event: CalendarEvent(
                id: UUID().uuidString,
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                calendarIdentifier: "local",
                isAllDay: isAllDay
            )) { selectedImageId in
                self.selectedImageId = selectedImageId
            }
        }
    }

    private var reminderText: String {
        if reminderMinutes == 0 {
            return "At time of event".localized
        } else if reminderMinutes < 60 {
            return "%d minutes before".localized(with: reminderMinutes)
        } else {
            let hours = reminderMinutes / 60
            if hours == 1 {
                return "1 hour before".localized
            } else {
                return "%d hours before".localized(with: hours)
            }
        }
    }

    private func saveEvent() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        #if os(tvOS)
        // On tvOS, create a CalendarEvent and add it directly to the viewModel
        let calendarEvent = CalendarEvent(
            id: "local_\(UUID().uuidString)",
            title: title,
            startDate: startDate,
            endDate: isAllDay ? Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: startDate) ?? endDate : endDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            calendarIdentifier: "local",
            isAllDay: isAllDay
        )

        // Add to viewModel events
        calendarViewModel.events.append(calendarEvent)
        calendarViewModel.events.sort { $0.startDate < $1.startDate }
        presentationMode.wrappedValue.dismiss()
        #else
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else { return }

            DispatchQueue.main.async {
                let event = EKEvent(eventStore: self.eventStore)
                event.title = self.title
                event.startDate = self.startDate
                event.endDate = self.isAllDay ? Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: self.startDate) ?? self.endDate : self.endDate
                event.location = self.location.isEmpty ? nil : self.location
                event.location = self.location.isEmpty ? nil : self.location
                
                var finalNotes = self.notes
                if !self.invitees.isEmpty {
                    if !finalNotes.isEmpty {
                        finalNotes += "\n\n"
                    }
                    finalNotes += "Invited: %@".localized(with: self.invitees)
                }
                event.notes = finalNotes.isEmpty ? nil : finalNotes
                
                event.isAllDay = self.isAllDay
                event.calendar = self.selectedCalendar ?? self.eventStore.calendars(for: .event).first

                if let recurrenceRule = self.recurrenceRule {
                    event.addRecurrenceRule(recurrenceRule)
                }

                if self.reminderMinutes > 0 {
                    let alarm = EKAlarm(relativeOffset: -TimeInterval(self.reminderMinutes * 60))
                    event.addAlarm(alarm)
                }

                do {
                    try self.eventStore.save(event, span: .thisEvent)
                    self.calendarViewModel.loadAllEvents()
                    self.presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to save event: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }
}

#if !os(tvOS)
struct RecurrencePickerView: View {
    @Binding var recurrenceRule: EKRecurrenceRule?
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var frequency: EKRecurrenceFrequency = .daily
    @State private var interval = 1
    @State private var endDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Repeat Event".localized)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Done".localized) {
                        saveRecurrenceRule()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            Form {
                Section(header: Text("Repeat Every".localized)) {
                    Picker("Frequency".localized, selection: $frequency) {
                        Text("Day".localized).tag(EKRecurrenceFrequency.daily)
                        Text("Week".localized).tag(EKRecurrenceFrequency.weekly)
                        Text("Month".localized).tag(EKRecurrenceFrequency.monthly)
                        Text("Year".localized).tag(EKRecurrenceFrequency.yearly)
                    }

                    Stepper("Every %d %@".localized(with: interval, frequency.description), value: $interval, in: 1...30)
                }

                Section(header: Text("End Repeat".localized)) {
                    Button(action: { endDate = nil }) {
                        HStack {
                            Text("Never".localized)
                            Spacer()
                            if endDate == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.currentPalette.primary)
                            }
                        }
                    }

                    Button(action: { endDate = Date().addingTimeInterval(86400 * 30) }) {
                        HStack {
                            Text("After 30 occurrences".localized)
                            Spacer()
                            if endDate != nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.currentPalette.primary)
                            }
                        }
                    }

                    if endDate != nil {
                        DatePicker("End Date".localized, selection: Binding($endDate)!)
                    }
                }
            }
        }
    }

    private func saveRecurrenceRule() {
        recurrenceRule = EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            end: endDate != nil ? EKRecurrenceEnd(end: endDate!) : nil
        )
        presentationMode.wrappedValue.dismiss()
    }
}

struct ReminderPickerView: View {
    @Binding var reminderMinutes: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    let reminderOptions = [
        (0, "At time of event".localized),
        (5, "%d minutes before".localized(with: 5)),
        (15, "%d minutes before".localized(with: 15)),
        (30, "%d minutes before".localized(with: 30)),
        (60, "1 hour before".localized),
        (120, "%d hours before".localized(with: 2)),
        (1440, "1 day before".localized)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Set Reminder".localized)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()

            Divider()

            List(reminderOptions, id: \.0) { option in
                Button(action: {
                    reminderMinutes = option.0
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(option.1)
                        Spacer()
                        if reminderMinutes == option.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.currentPalette.primary)
                        }
                    }
                }
            }
        }
    }
}
#endif

#if !os(tvOS)
extension EKRecurrenceFrequency {
    var description: String {
        switch self {
        case .daily: return "Day".localized
        case .weekly: return "Week".localized
        case .monthly: return "Month".localized
        case .yearly: return "Year".localized
        @unknown default: return "period"
        }
    }
}
#endif
