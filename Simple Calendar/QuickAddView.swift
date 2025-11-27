//
//  QuickAddView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // 1 hour later
    @State private var location = ""
    @State private var isAllDay = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Add Event")
                    .font(uiConfig.scaledFont(.headline, weight: .bold))
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
            }
            .padding()
            .background(themeManager.currentPalette.calendarSurface)

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Title
                TextField("Event title", text: $title)
                    .font(uiConfig.scaledFont(.body))
                    #if !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .padding(.horizontal)

                // Date and Time
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("All Day", isOn: $isAllDay)
                        .font(uiConfig.scaledFont(.body))

                    #if os(tvOS)
                    // tvOS simplified date/time selection - uses current date/time
                    Text("Event will be created for today")
                        .font(uiConfig.scaledFont(.body))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    #else
                    if isAllDay {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .font(uiConfig.scaledFont(.body))
                    } else {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .font(uiConfig.scaledFont(.body))

                        HStack {
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                .font(uiConfig.scaledFont(.body))
                            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                                .font(uiConfig.scaledFont(.body))
                        }
                    }
                    #endif
                }
                .padding(.horizontal)

                // Location
                TextField("Location (optional)", text: $location)
                    .font(uiConfig.scaledFont(.body))
                    #if !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .padding(.horizontal)

                // Action Buttons
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(uiConfig.scaledFont(.body))
                    .foregroundColor(themeManager.currentPalette.textSecondary)

                    Spacer()

                    Button("Add Event") {
                        addEvent()
                    }
                    .font(uiConfig.scaledFont(.body, weight: .medium))
                    .foregroundColor(themeManager.currentPalette.buttonPrimary)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .frame(width: 400)
        .background(themeManager.currentPalette.calendarSurface)
        .roundedCorners(.normal)
        .shadow(radius: 10)
    }

    private func addEvent() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let event = CalendarEvent(
            id: UUID().uuidString,
            title: title,
            startDate: isAllDay ? Calendar.current.startOfDay(for: selectedDate) : combineDateAndTime(selectedDate, time: startTime),
            endDate: isAllDay ? Calendar.current.startOfDay(for: selectedDate.addingTimeInterval(24 * 60 * 60)) : combineDateAndTime(selectedDate, time: endTime),
            location: location.isEmpty ? nil : location,
            notes: nil,
            calendarIdentifier: "quick_add",
            isAllDay: isAllDay
        )

        // Add to calendar
        calendarViewModel.addEvent(event)
        isPresented = false
    }

    private func combineDateAndTime(_ date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? date
    }
}

// Extension to add quick add to CalendarViewModel
extension CalendarViewModel {
    func addEvent(_ event: CalendarEvent) {
        // For now, just add to local events
        // In a real implementation, this would save to the system calendar
        events.append(event)
        events.sort { $0.startDate < $1.startDate }
    }
}
