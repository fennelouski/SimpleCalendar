//
//  GoogleCalendarAPI.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

#if !os(tvOS)
import Foundation

class GoogleCalendarAPI {
    private let oauthManager: GoogleOAuthManager

    init(oauthManager: GoogleOAuthManager) {
        self.oauthManager = oauthManager
    }

    func fetchEvents(from startDate: Date, to endDate: Date, completion: @escaping ([CalendarEvent]?) -> Void) {
        oauthManager.getValidAccessToken { [weak self] accessToken in
            guard let self = self, let accessToken = accessToken else {
                completion(nil)
                return
            }

            self.fetchCalendarList(accessToken: accessToken) { calendarList in
                guard let calendarList = calendarList else {
                    completion(nil)
                    return
                }

                self.fetchEventsFromCalendars(calendarList, startDate: startDate, endDate: endDate, accessToken: accessToken, completion: completion)
            }
        }
    }

    private func fetchCalendarList(accessToken: String, completion: @escaping ([[String: Any]]?) -> Void) {
        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!
        components.queryItems = [
            URLQueryItem(name: "minAccessRole", value: "reader")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion(nil)
                return
            }

            completion(items)
        }.resume()
    }

    private func fetchEventsFromCalendars(_ calendars: [[String: Any]], startDate: Date, endDate: Date, accessToken: String, completion: @escaping ([CalendarEvent]?) -> Void) {
        let group = DispatchGroup()
        var allEvents: [CalendarEvent] = []

        for calendar in calendars {
            guard let calendarId = calendar["id"] as? String else { continue }

            group.enter()
            fetchEventsFromCalendar(calendarId: calendarId, startDate: startDate, endDate: endDate, accessToken: accessToken) { events in
                if let events = events {
                    allEvents.append(contentsOf: events)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(allEvents.sorted { $0.startDate < $1.startDate })
        }
    }

    private func fetchEventsFromCalendar(calendarId: String, startDate: Date, endDate: Date, accessToken: String, completion: @escaping ([CalendarEvent]?) -> Void) {
        let dateFormatter = ISO8601DateFormatter()

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "timeMax", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        // URL encode the calendar ID
        let encodedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/\(encodedCalendarId)/events?\(components.query ?? "")"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion(nil)
                return
            }

            let events = items.compactMap { self.parseEvent(from: $0, calendarId: calendarId) }
            completion(events)
        }.resume()
    }

    private func parseEvent(from json: [String: Any], calendarId: String) -> CalendarEvent? {
        guard let id = json["id"] as? String,
              let summary = json["summary"] as? String else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        var startDate: Date?
        var endDate: Date?
        var isAllDay = false

        // Parse start time
        if let start = json["start"] as? [String: Any] {
            if let dateTime = start["dateTime"] as? String {
                startDate = dateFormatter.date(from: dateTime)
            } else if let date = start["date"] as? String {
                // All-day event
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                startDate = dateFormatter.date(from: date)
                isAllDay = true
            }
        }

        // Parse end time
        if let end = json["end"] as? [String: Any] {
            if let dateTime = end["dateTime"] as? String {
                endDate = dateFormatter.date(from: dateTime)
            } else if let date = end["date"] as? String {
                // All-day event
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                endDate = dateFormatter.date(from: date)
            }
        }

        guard let start = startDate, let end = endDate else {
            return nil
        }

        // For all-day events, adjust end date
        let adjustedEndDate = isAllDay ? Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: end) ?? end : end

        let location = json["location"] as? String
        let description = json["description"] as? String

        return CalendarEvent(
            id: "google_\(calendarId)_\(id)",
            title: summary,
            startDate: start,
            endDate: adjustedEndDate,
            location: location,
            notes: description,
            calendarIdentifier: calendarId,
            isAllDay: isAllDay
        )
    }
}
#endif

// Stub implementation for tvOS
#if os(tvOS)
import Foundation

class GoogleCalendarAPI {
    init(oauthManager: GoogleOAuthManager) {
        // tvOS doesn't use Google Calendar API
    }

    func fetchEvents(from startDate: Date, to endDate: Date, completion: @escaping ([CalendarEvent]?) -> Void) {
        // tvOS doesn't fetch Google Calendar events
        completion([])
    }
}
#endif
