import Foundation
import SwiftData

/// Durable app-owned events. External calendar records stay with their provider.
@MainActor
enum LocalCalendarEvents {
    static func isLocal(_ event: CalendarEvent) -> Bool {
        !event.id.hasPrefix("system_") && !event.id.hasPrefix("google_")
    }

    static func copy(_ event: CalendarEvent) -> CalendarEvent {
        CalendarEvent(id: event.id, title: event.title, startDate: event.startDate,
                      endDate: event.endDate, location: event.location, notes: event.notes,
                      calendarIdentifier: event.calendarIdentifier, isAllDay: event.isAllDay,
                      imageUrl: event.imageUrl, imageRepositoryId: event.imageRepositoryId,
                      color: event.color, emoji: event.emoji)
    }

    static func load(from container: ModelContainer) throws -> [CalendarEvent] {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return try context.fetch(FetchDescriptor<CalendarEvent>(sortBy: [SortDescriptor(\.startDate)]))
            .filter(isLocal).map(copy)
    }

    static func save(_ event: CalendarEvent, in container: ModelContainer) throws -> [CalendarEvent] {
        guard isLocal(event), !event.id.isEmpty,
              !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              event.startDate.timeIntervalSinceReferenceDate.isFinite,
              event.endDate.timeIntervalSinceReferenceDate.isFinite,
              event.endDate > event.startDate else {
            throw NSError(domain: "CalendarPlay.LocalEvents", code: 1, userInfo: [NSLocalizedDescriptionKey:
                "Enter a title and an end time after the start time."])
        }
        // A failed SwiftData save can leave inserted/deleted objects visible in
        // its context even after rollback. Isolate writes until they succeed.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let id = event.id
        let matches = try context.fetch(FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.id == id }))
        if let stored = matches.first {
            stored.title = event.title
            stored.startDate = event.startDate
            stored.endDate = event.endDate
            stored.location = event.location
            stored.notes = event.notes
            stored.calendarIdentifier = event.calendarIdentifier
            stored.isAllDay = event.isAllDay
            stored.imageUrl = event.imageUrl
            stored.imageRepositoryId = event.imageRepositoryId
            stored.color = event.color
            stored.emoji = event.emoji
        } else {
            context.insert(copy(event))
        }
        try context.save()
        return try load(from: container)
    }

    static func delete(id: String, from container: ModelContainer) throws -> [CalendarEvent] {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let matches = try context.fetch(FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.id == id }))
        for event in matches where isLocal(event) { context.delete(event) }
        try context.save()
        return try load(from: container)
    }
}
