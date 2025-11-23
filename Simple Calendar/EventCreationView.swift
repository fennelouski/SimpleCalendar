//
//  EventCreationView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import EventKit
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
    @State private var isAllDay = false
    @State private var selectedCalendar: EKCalendar?

    @State private var showRecurrencePicker = false
    @State private var recurrenceRule: EKRecurrenceRule?

    @State private var showReminderPicker = false
    @State private var reminderMinutes = 15
    @State private var showImageSelection = false
    @State private var selectedImageId: String?

    private let eventStore = EKEventStore()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                        .font(.headline)

                    Toggle("All Day", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                    }
                }

                Section(header: Text("Additional Information")) {
                    TextField("Location", text: $location)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                        if notes.isEmpty {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Section(header: Text("Calendar")) {
                    Picker("Calendar", selection: $selectedCalendar) {
                        ForEach(eventStore.calendars(for: .event), id: \.calendarIdentifier) { calendar in
                            Text(calendar.title)
                                .tag(calendar as EKCalendar?)
                        }
                    }
                }

                Section(header: Text("Image")) {
                    Button(action: { showImageSelection = true }) {
                        HStack {
                            Text("Event Image")
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
                                    .foregroundColor(.blue)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !location.isEmpty {
                    Section(header: Text("Location Map")) {
                        EventMapView(location: location)
                    }
                }

                Section {
                    Button(action: { showRecurrencePicker = true }) {
                        HStack {
                            Text("Repeat")
                            Spacer()
                            Text(recurrenceRule?.description ?? "Never")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { showReminderPicker = true }) {
                        HStack {
                            Text("Reminder")
                            Spacer()
                            Text(reminderText)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Event")
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Save") {
                    saveEvent()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(isPresented: $showRecurrencePicker) {
            RecurrencePickerView(recurrenceRule: $recurrenceRule)
        }
        .sheet(isPresented: $showReminderPicker) {
            ReminderPickerView(reminderMinutes: $reminderMinutes)
        }
        .sheet(isPresented: $showImageSelection) {
            ImageSelectionView(event: CalendarEvent(
                id: UUID().uuidString,
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                calendarIdentifier: selectedCalendar?.calendarIdentifier ?? "",
                isAllDay: isAllDay
            )) { selectedImageId in
                self.selectedImageId = selectedImageId
            }
        }
    }

    private var reminderText: String {
        if reminderMinutes == 0 {
            return "At time of event"
        } else if reminderMinutes < 60 {
            return "\(reminderMinutes) minutes before"
        } else {
            let hours = reminderMinutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        }
    }

    private func saveEvent() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else { return }

            DispatchQueue.main.async {
                let event = EKEvent(eventStore: self.eventStore)
                event.title = self.title
                event.startDate = self.startDate
                event.endDate = self.isAllDay ? Calendar.current.date(byAdding: .day, value: 1, to: self.startDate) ?? self.endDate : self.endDate
                event.location = self.location.isEmpty ? nil : self.location
                event.notes = self.notes.isEmpty ? nil : self.notes
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
    }
}

struct RecurrencePickerView: View {
    @Binding var recurrenceRule: EKRecurrenceRule?
    @Environment(\.presentationMode) var presentationMode

    @State private var frequency: EKRecurrenceFrequency = .daily
    @State private var interval = 1
    @State private var endDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Repeat Event")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 16) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Done") {
                        saveRecurrenceRule()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            Form {
                Section(header: Text("Repeat Every")) {
                    Picker("Frequency", selection: $frequency) {
                        Text("Day").tag(EKRecurrenceFrequency.daily)
                        Text("Week").tag(EKRecurrenceFrequency.weekly)
                        Text("Month").tag(EKRecurrenceFrequency.monthly)
                        Text("Year").tag(EKRecurrenceFrequency.yearly)
                    }

                    Stepper("Every \(interval) \(frequency.description)", value: $interval, in: 1...30)
                }

                Section(header: Text("End Repeat")) {
                    Button(action: { endDate = nil }) {
                        HStack {
                            Text("Never")
                            Spacer()
                            if endDate == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Button(action: { endDate = Date().addingTimeInterval(86400 * 30) }) {
                        HStack {
                            Text("After 30 occurrences")
                            Spacer()
                            if endDate != nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    if endDate != nil {
                        DatePicker("End Date", selection: Binding($endDate)!)
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
    @Environment(\.presentationMode) var presentationMode

    let reminderOptions = [
        (0, "At time of event"),
        (5, "5 minutes before"),
        (15, "15 minutes before"),
        (30, "30 minutes before"),
        (60, "1 hour before"),
        (120, "2 hours before"),
        (1440, "1 day before")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Set Reminder")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
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
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

extension EKRecurrenceFrequency {
    var description: String {
        switch self {
        case .daily: return "day"
        case .weekly: return "week"
        case .monthly: return "month"
        case .yearly: return "year"
        @unknown default: return "period"
        }
    }
}
