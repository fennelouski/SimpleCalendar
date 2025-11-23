//
//  EventTemplateSelector.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import EventKit

struct EventTemplateSelector: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedCategory: EventTemplate.EventCategory = .work
    @State private var selectedDate: Date
    @State private var showEventCreation = false
    @State private var selectedTemplate: EventTemplate?

    init(selectedDate: Date = Date()) {
        self._selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and cancel button
            HStack {
                Text("Quick Create Event")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()

            Divider()

            VStack {
                // Date picker
                DatePicker("Event Date & Time", selection: $selectedDate)
                    .datePickerStyle(.graphical)
                    .padding()

                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(EventTemplate.EventCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Templates list
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(EventTemplate.templates(for: selectedCategory)) { template in
                            TemplateCard(template: template)
                                .onTapGesture {
                                    selectedTemplate = template
                                    showEventCreation = true
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showEventCreation) {
            if let template = selectedTemplate {
                EventCreationFromTemplateView(template: template, selectedDate: selectedDate)
            }
        }
    }
}

struct TemplateCard: View {
    let template: EventTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: template.category))
                    .foregroundColor(.blue)
                    .font(.title2)

                Spacer()

                Text(template.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }

            Text(template.name)
                .font(.headline)
                .foregroundColor(.primary)

            if let location = template.location {
                HStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(durationString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var durationString: String {
        let hours = Int(template.duration / 3600)
        let minutes = Int((template.duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if template.isAllDay {
            return "All day"
        } else if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }

    private func iconName(for category: EventTemplate.EventCategory) -> String {
        switch category {
        case .work:
            return "briefcase.fill"
        case .personal:
            return "person.fill"
        case .health:
            return "heart.fill"
        case .social:
            return "person.2.fill"
        case .education:
            return "book.fill"
        case .travel:
            return "airplane"
        case .other:
            return "square.fill"
        }
    }
}

struct EventCreationFromTemplateView: View {
    let template: EventTemplate
    let selectedDate: Date

    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var event: CalendarEvent
    @State private var showRecurrencePicker = false
    @State private var recurrenceRule: EKRecurrenceRule?
    @State private var showReminderPicker = false
    @State private var reminderMinutes = 15

    private let eventStore = EKEventStore()

    init(template: EventTemplate, selectedDate: Date) {
        self.template = template
        self.selectedDate = selectedDate

        // Create initial event from template
        let startDate = selectedDate
        let event = template.createEvent(startingAt: startDate)
        self._event = State(initialValue: event)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $event.title)
                        .font(.headline)

                    Toggle("All Day", isOn: $event.isAllDay)

                    if !event.isAllDay {
                        DatePicker("Start Time", selection: $event.startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $event.endDate, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        DatePicker("Date", selection: $event.startDate, displayedComponents: [.date])
                    }
                }

                Section(header: Text("Additional Information")) {
                    TextField("Location", text: Binding(
                        get: { event.location ?? "" },
                        set: { event.location = $0.isEmpty ? nil : $0 }
                    ))

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding(
                            get: { event.notes ?? "" },
                            set: { event.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 80)

                        if event.notes?.isEmpty ?? true {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
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
            .navigationTitle("Create \(template.name)")
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Save") {
                    saveEvent()
                }
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
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else { return }

            DispatchQueue.main.async {
                let ekEvent = EKEvent(eventStore: self.eventStore)
                ekEvent.title = self.event.title
                ekEvent.startDate = self.event.startDate
                ekEvent.endDate = self.event.isAllDay ? Calendar.current.date(byAdding: .day, value: 1, to: self.event.startDate) ?? self.event.endDate : self.event.endDate
                ekEvent.location = self.event.location
                ekEvent.notes = self.event.notes
                ekEvent.isAllDay = self.event.isAllDay
                ekEvent.calendar = self.eventStore.calendars(for: .event).first

                if let recurrenceRule = self.recurrenceRule {
                    ekEvent.addRecurrenceRule(recurrenceRule)
                }

                if self.reminderMinutes > 0 {
                    let alarm = EKAlarm(relativeOffset: -TimeInterval(self.reminderMinutes * 60))
                    ekEvent.addAlarm(alarm)
                }

                do {
                    try self.eventStore.save(ekEvent, span: .thisEvent)
                    self.calendarViewModel.loadAllEvents()
                    self.presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to save event: \(error.localizedDescription)")
                }
            }
        }
    }
}
