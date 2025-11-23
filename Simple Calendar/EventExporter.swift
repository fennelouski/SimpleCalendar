//
//  EventExporter.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
#if os(macOS)
import AppKit
#endif
import EventKit

class EventExporter {
    static func exportEvents(_ events: [CalendarEvent], to url: URL) throws {
        let icsContent = generateICSContent(for: events)
        try icsContent.write(to: url, atomically: true, encoding: .utf8)
    }

    static func generateICSContent(for events: [CalendarEvent]) -> String {
        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Simple Calendar//EN
        CALSCALE:GREGORIAN

        """

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        for event in events {
            icsContent += "BEGIN:VEVENT\n"
            icsContent += "UID:\(event.id)\n"
            icsContent += "DTSTAMP:\(dateFormatter.string(from: Date()))\n"
            icsContent += "DTSTART:\(formatDate(event.startDate, isAllDay: event.isAllDay))\n"
            icsContent += "DTEND:\(formatDate(event.endDate, isAllDay: event.isAllDay))\n"
            icsContent += "SUMMARY:\(escapeString(event.title))\n"

            if let location = event.location {
                icsContent += "LOCATION:\(escapeString(location))\n"
            }

            if let notes = event.notes {
                icsContent += "DESCRIPTION:\(escapeString(notes))\n"
            }

            if event.isAllDay {
                icsContent += "X-MICROSOFT-CDO-ALLDAYEVENT:TRUE\n"
            }

            icsContent += "END:VEVENT\n"
        }

        icsContent += "END:VCALENDAR\n"

        return icsContent
    }

    private static func formatDate(_ date: Date, isAllDay: Bool) -> String {
        if isAllDay {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter.string(from: date)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter.string(from: date)
        }
    }

    private static func escapeString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    static func exportSingleEvent(_ event: CalendarEvent) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "event_\(event.title.replacingOccurrences(of: " ", with: "_")).ics"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try exportEvents([event], to: fileURL)
            return fileURL
        } catch {
            print("Failed to export event: \(error)")
            return nil
        }
    }

    static func exportEventsInDateRange(startDate: Date, endDate: Date, events: [CalendarEvent]) -> URL? {
        let eventsInRange = events.filter { event in
            event.startDate >= startDate && event.startDate <= endDate
        }

        guard !eventsInRange.isEmpty else { return nil }

        let tempDirectory = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateRange = "\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate))"
        let fileName = "calendar_events_\(dateRange).ics"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try exportEvents(eventsInRange, to: fileURL)
            return fileURL
        } catch {
            print("Failed to export events: \(error)")
            return nil
        }
    }

    static func shareEvent(_ event: CalendarEvent) {
        guard let fileURL = exportSingleEvent(event) else { return }

        #if os(macOS)
        let sharingService = NSSharingServicePicker(items: [fileURL])
        if let window = NSApplication.shared.windows.first {
            sharingService.show(relativeTo: NSRect.zero, of: window.contentView!, preferredEdge: .minY)
        }
        #endif
    }
}
