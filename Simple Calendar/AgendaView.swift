//
//  AgendaView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct AgendaView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Date picker for jumping to specific dates
            HStack {
                Button(action: { moveToPreviousWeek() }) {
                    Image(systemName: "chevron.left")
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
                    .onChange(of: selectedDate) { newDate in
                        scrollToDate()
                    }

                Button(action: { moveToNextWeek() }) {
                    Image(systemName: "chevron.right")
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])

                Spacer()

                Button(action: { selectedDate = Date() }) {
                    Text("Today")
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
            .padding()
            .background(Color.white)

            Divider()

            // Agenda list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        let agendaItems = generateAgendaItems()

                        ForEach(agendaItems) { item in
                            AgendaItemView(item: item)
                                .id(item.id)
                                .onTapGesture {
                                    calendarViewModel.selectDate(item.date)
                                    calendarViewModel.setViewMode(.singleDay)
                                    calendarViewModel.toggleDayDetail()
                                }
                        }
                    }
                }
                .onAppear {
                    scrollToDate(scrollView)
                }
                .onChange(of: selectedDate) { newDate in
                    scrollToDate(scrollView)
                }
            }
        }
    }

    private func generateAgendaItems() -> [AgendaItem] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: selectedDate)
        let endDate = calendar.date(byAdding: .month, value: 2, to: startDate)!

        var items: [AgendaItem] = []

        // Get events in the date range
        let eventsInRange = calendarViewModel.events.filter { event in
            event.startDate >= startDate && event.startDate < endDate
        }

        // Group events by date
        let groupedEvents = Dictionary(grouping: eventsInRange) { event in
            calendar.startOfDay(for: event.startDate)
        }

        // Create date range for the next 60 days
        for dayOffset in 0..<60 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let dayEvents = groupedEvents[calendar.startOfDay(for: currentDate)] ?? []

            if dayEvents.isEmpty && !calendar.isDate(currentDate, inSameDayAs: Date()) {
                // Only show empty days for today
                continue
            }

            let isToday = calendar.isDate(currentDate, inSameDayAs: Date())
            let isSelected = calendar.isDate(currentDate, inSameDayAs: selectedDate)

            items.append(AgendaItem(
                id: currentDate,
                date: currentDate,
                events: dayEvents,
                isToday: isToday,
                isSelected: isSelected
            ))
        }

        return items
    }

    private func moveToPreviousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
    }

    private func moveToNextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
    }

    private func scrollToDate() {
        // This will trigger the scroll view reader
    }

    private func scrollToDate(_ scrollView: ScrollViewProxy) {
        scrollView.scrollTo(selectedDate, anchor: .top)
    }
}

struct AgendaItem: Identifiable {
    let id: Date
    let date: Date
    let events: [CalendarEvent]
    let isToday: Bool
    let isSelected: Bool
}

struct AgendaItemView: View {
    let item: AgendaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            HStack {
                Text(dateString(for: item.date))
                    .font(.headline)
                    .foregroundColor(item.isToday ? .blue : .primary)

                if item.isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                if !item.events.isEmpty {
                    Text("\(item.events.count) event\(item.events.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Events
            if item.events.isEmpty {
                Text("No events")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.events) { event in
                        EventRowView(event: event)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()
        }
        .background(item.isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"

        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: Date()) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: Date())!) {
            return "Tomorrow"
        } else {
            return formatter.string(from: date)
        }
    }
}

struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time indicator
            VStack {
                Circle()
                    .fill(eventColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                if !event.isAllDay {
                    Rectangle()
                        .fill(eventColor.opacity(0.3))
                        .frame(width: 2, height: 40)
                        .padding(.top, 2)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)

                if !event.isAllDay {
                    Text(timeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if let location = event.location {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(location)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Calendar source indicator
            HStack(spacing: 2) {
                Circle()
                    .fill(calendarColor)
                    .frame(width: 6, height: 6)
                Text(calendarSource)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var timeString: String {
        if event.isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }

    private var eventColor: Color {
        if event.id.hasPrefix("google_") {
            return .green
        } else {
            return .blue
        }
    }

    private var calendarColor: Color {
        if event.id.hasPrefix("google_") {
            return .green
        } else {
            return .blue
        }
    }

    private var calendarSource: String {
        if event.id.hasPrefix("google_") {
            return "Google"
        } else {
            return "Local"
        }
    }
}
