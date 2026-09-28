import Foundation
import SwiftData

@main
struct CalendarReleaseChecks {
    @MainActor static func main() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("events.store")
        let schema = Schema([CalendarEvent.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let now = Date()
        let event = CalendarEvent(id: "tv_saved", title: "A saved event", startDate: now, endDate: now.addingTimeInterval(3600), location: "Library", notes: "Keep these notes", calendarIdentifier: "tv_local", imageRepositoryId: "saved-image", color: "#123456", emoji: "📅")
        _ = try LocalCalendarEvents.save(event, in: container)
        let reopened = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let reopenedEvents = try LocalCalendarEvents.load(from: reopened)
        assert(reopenedEvents.first?.title == event.title)
        let edit = LocalCalendarEvents.copy(event)
        edit.title = "Edited event"
        _ = try LocalCalendarEvents.save(edit, in: container)
        let saved = try LocalCalendarEvents.load(from: reopened)
        assert(saved.count == 1 && saved[0].id == event.id && saved[0].title == edit.title)
        assert(saved[0].notes == event.notes && saved[0].imageRepositoryId == event.imageRepositoryId)
        print("PASS: add, reopen and idempotent edit preserve all event metadata")

        let readOnly = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, allowsSave: false, cloudKitDatabase: .none)])
        let unsaved = LocalCalendarEvents.copy(edit)
        unsaved.title = "Draft that must stay open"
        do { _ = try LocalCalendarEvents.save(unsaved, in: readOnly); assertionFailure("Read-only edit unexpectedly saved") } catch {}
        do { _ = try LocalCalendarEvents.delete(id: event.id, from: readOnly); assertionFailure("Read-only delete unexpectedly saved") } catch {}
        let failedAdd = LocalCalendarEvents.copy(event)
        failedAdd.id = "new-unsaved"
        do { _ = try LocalCalendarEvents.save(failedAdd, in: readOnly); assertionFailure("Read-only add unexpectedly saved") } catch {}
        let afterFailures = try LocalCalendarEvents.load(from: container)
        assert(afterFailures.count == 1 && afterFailures[0].title == edit.title)
        assert(unsaved.title == "Draft that must stay open")
        print("PASS: failed add/edit/delete leave committed events and input drafts intact")

        let invalid = LocalCalendarEvents.copy(event)
        invalid.title = "  "
        do { _ = try LocalCalendarEvents.save(invalid, in: container); assertionFailure("Empty title accepted") } catch {}
        invalid.title = "Bad time"
        invalid.endDate = invalid.startDate
        do { _ = try LocalCalendarEvents.save(invalid, in: container); assertionFailure("Invalid interval accepted") } catch {}
        let external = LocalCalendarEvents.copy(event)
        external.id = "google_external"
        do { _ = try LocalCalendarEvents.save(external, in: container); assertionFailure("External event copied into local store") } catch {}
        print("PASS: invalid intervals, blank titles and external-provider writes rejected")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29))!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        assert(nextDay.timeIntervalSince(day) == 23 * 3600)
        let overnight = LocalCalendarEvents.copy(event)
        overnight.startDate = day.addingTimeInterval(-1800)
        overnight.endDate = day.addingTimeInterval(1800)
        assert(overnight.occurs(on: day, calendar: calendar))
        assert(overnight.occurs(on: day.addingTimeInterval(-3600), calendar: calendar))
        overnight.startDate = day
        overnight.endDate = nextDay
        assert(overnight.occurs(on: day, calendar: calendar))
        assert(!overnight.occurs(on: nextDay, calendar: calendar))
        print("PASS: overnight events, DST day length and exclusive midnight boundary")

        let response: [String: Any] = ["title": "Lunch", "startDate": "2026-03-29T11:00:00.000Z", "endDate": "2026-03-29T12:00:00Z", "emoji": "🍽️", "color": "#123456"]
        let parsed = try EventDescriptionParser.validatedResponse(JSONSerialization.data(withJSONObject: response))
        assert(parsed.title == "Lunch")
        for invalidField in [["title": " "], ["endDate": "2026-03-29T10:00:00Z"], ["color": "garbage"], ["emoji": "🍺"], ["startDate": "not-a-date"]] {
            var invalidResponse = response
            invalidField.forEach { invalidResponse[$0.key] = $0.value }
            do { _ = try EventDescriptionParser.validatedResponse(JSONSerialization.data(withJSONObject: invalidResponse)); assertionFailure("Malformed AI response accepted") } catch {}
        }
        print("PASS: AI response dates, intervals, title, color and curated emoji validation")

        let oldZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "Europe/Amsterdam")!
        defer { NSTimeZone.default = oldZone }
        let allDay = LocalCalendarEvents.copy(overnight)
        allDay.isAllDay = true
        allDay.title = "A/../../path\r\n" + String(repeating: "📅é", count: 60)
        allDay.notes = "First\rline; with, punctuation\\and newline\nEND:VEVENT"
        let ics = EventExporter.generateICSContent(for: [allDay])
        assert(ics.contains("DTSTART;VALUE=DATE:20260329\r\n"))
        assert(ics.contains("DTEND;VALUE=DATE:20260330\r\n"))
        assert(!ics.replacingOccurrences(of: "\r\n", with: "").contains("\n"))
        assert(ics.components(separatedBy: "\r\n").allSatisfy { $0.utf8.count <= 75 })
        let unfolded = ics.replacingOccurrences(of: "\r\n ", with: "")
        assert(unfolded.contains("SUMMARY:A/../../path\\n"))
        assert(unfolded.components(separatedBy: "\r\nEND:VEVENT\r\n").count == 2)
        let exportURL = EventExporter.exportSingleEvent(allDay)!
        assert(exportURL.deletingLastPathComponent().standardizedFileURL == FileManager.default.temporaryDirectory.standardizedFileURL)
        try FileManager.default.removeItem(at: exportURL)
        print("PASS: all-day export dates, Unicode line folding, injection escaping and safe filenames")

        _ = try LocalCalendarEvents.delete(id: event.id, from: container)
        let remaining = try LocalCalendarEvents.load(from: reopened)
        assert(remaining.isEmpty)
        print("PASS: deletion persists after reopening")
    }
}
