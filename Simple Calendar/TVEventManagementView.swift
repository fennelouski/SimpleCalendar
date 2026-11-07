//
//  TVEventManagementView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/29/25.
//

import SwiftUI
import SwiftData

struct TVEventManagementView: View {
    let selectedDate: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var eventsForDate: [CalendarEvent] = []
    @State private var showCreateEvent = false
    @State private var eventToDelete: CalendarEvent?
    @State private var editingEvent: CalendarEvent? = nil
    @State private var selectedEvent: CalendarEvent? = nil

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Events for".localized)
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                    }
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.currentPalette.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                .padding(.bottom, 20)

                if let error = calendarViewModel.storageError {
                    Text(error).foregroundStyle(.red).padding()
                }
                // Content
                if eventsForDate.isEmpty {
                    // No events view
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.5))
                        Text("No events for this date".localized)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                        Text("Tap 'Create Event' to add your first event".localized)
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Events list
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(eventsForDate.sorted(by: { $0.startDate < $1.startDate })) { event in
                                TVEventRow(event: event) {
                                    selectedEvent = event
                                } editAction: {
                                    editingEvent = event
                                } deleteAction: {
                                    eventToDelete = event
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    }
                }

                // Bottom buttons
                HStack(spacing: 40) {
                    Button(action: {
                        showCreateEvent = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            Text("Create Event".localized)
                                .font(.system(size: 24, weight: .semibold))
                        }
                        .foregroundColor(themeManager.currentPalette.primary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.currentPalette.primary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)

                    if !eventsForDate.isEmpty {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done".localized)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .background(themeManager.currentPalette.calendarSurface)
            .onAppear {
                loadEventsForDate()
            }
            .confirmationDialog("Delete this event?", isPresented: Binding(
                get: { eventToDelete != nil }, set: { if !$0 { eventToDelete = nil } }
            ), titleVisibility: .visible) {
                if let eventToDelete {
                    Button("Delete event", role: .destructive) { deleteEvent(eventToDelete) }
                }
                Button("Cancel", role: .cancel) { eventToDelete = nil }
            }
            .sheet(isPresented: $showCreateEvent) {
                TVEventCreationView(selectedDate: selectedDate, onEventCreated: { newEvent in
                    addEvent(newEvent)
                })
            }
            .sheet(item: $editingEvent) { event in
                TVEventCreationView(selectedDate: selectedDate, editingEvent: event, onEventCreated: { updatedEvent in
                    updateEvent(updatedEvent)
                })
            }
            .sheet(item: $selectedEvent) { event in
                TVEventDetailView(event: event)
            }
        }
        #if os(tvOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func loadEventsForDate() {
        eventsForDate = calendarViewModel.events.filter { $0.occurs(on: selectedDate) }
    }

    private func addEvent(_ event: CalendarEvent) -> Bool {
        guard calendarViewModel.addEvent(event) else { return false }
        loadEventsForDate()
        return true
    }

    private func updateEvent(_ event: CalendarEvent) -> Bool {
        addEvent(event)
    }

    private func deleteEvent(_ event: CalendarEvent) {
        eventToDelete = nil
        if calendarViewModel.deleteLocalEvent(event) { loadEventsForDate() }
    }

}

struct TVEventRow: View {
    let event: CalendarEvent
    let viewAction: () -> Void
    let editAction: () -> Void
    let deleteAction: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        Button(action: viewAction) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    if !event.isAllDay {
                        Text(timeFormatter.string(from: event.startDate))
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                }

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentPalette.primary)
                        Text(location)
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                            .lineLimit(1)
                    }
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentPalette.calendarBackground.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentPalette.primary.opacity(isFocused ? 0.5 : 0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .contextMenu {
            Button(action: editAction) {
                Label("Edit Event".localized, systemImage: "pencil")
            }
            Button(action: deleteAction) {
                Label("Delete Event".localized, systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct TVEventDetailView: View {
    let event: CalendarEvent
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

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
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(event.title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(themeManager.currentPalette.textPrimary)

                    // Date and time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time".localized)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        if event.isAllDay {
                            Text(dateFormatter.string(from: event.startDate))
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text("All day".localized)
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.8))
                        } else {
                            Text(dateFormatter.string(from: event.startDate))
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            HStack {
                                Text(timeFormatter.string(from: event.startDate))
                                Text("to".localized)
                                Text(timeFormatter.string(from: event.endDate))
                            }
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.8))
                        }
                    }

                    // Location
                    if let location = event.location, !location.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location".localized)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)

                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.currentPalette.primary)
                                Text(location)
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.currentPalette.textSecondary)
                            }
                        }
                    }

                    // Notes
                    if let notes = event.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes".localized)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)

                            Text(notes)
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(40)
            }
            .background(themeManager.currentPalette.calendarSurface)
            .navigationTitle("Event Details".localized)
            #if os(tvOS)
            .navigationBarItems(trailing:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentPalette.primary)
                }
            )
            #endif
        }
        #if os(tvOS)
        .navigationViewStyle(.stack)
        #endif
    }
}
