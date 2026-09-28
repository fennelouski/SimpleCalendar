import Foundation

/// Explicitly requested parsing only. The editor owns device-local consent.
enum EventDescriptionParser {
    static let allowedEmoji = ["📅", "👨‍⚕️", "🎓", "🍽️", "🎉", "💼", "🏃‍♂️", "🎨", "📖", "✈️"]

    static func parse(_ text: String, selectedDate: Date, session: URLSession? = nil) async throws -> ParsedEventResponse {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 2000 else { throw URLError(.badURL) }
        var request = URLRequest(url: URL(string: "https://calendar-play-seven.vercel.app/api/parse-event")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "text": text,
            "currentDate": ISO8601DateFormatter().string(from: selectedDate),
            "timeZone": TimeZone.current.identifier
        ])
        request = try CalendarAPIRequest.prepared(request)
        let requestSession = session ?? URLSession(configuration: .ephemeral)
        defer { if session == nil { requestSession.invalidateAndCancel() } }
        let (data, response) = try await requestSession.data(for: request)
        try Task.checkCancellation()
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 64_000 else { throw URLError(.badServerResponse) }
        return try validatedResponse(data)
    }

    static func date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }

    static func validatedResponse(_ data: Data) throws -> ParsedEventResponse {
        let parsed = try JSONDecoder().decode(ParsedEventResponse.self, from: data)
        guard let title = parsed.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              title.count <= 300,
              let start = parsed.startDate.flatMap(date), let end = parsed.endDate.flatMap(date), end > start,
              (parsed.location?.count ?? 0) <= 1000, (parsed.notes?.count ?? 0) <= 4000,
              parsed.color == nil || parsed.color!.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil,
              parsed.emoji == nil || allowedEmoji.contains(parsed.emoji!) else { throw URLError(.cannotParseResponse) }
        if let recurrence = parsed.recurrence {
            guard ["daily", "weekly", "monthly", "yearly"].contains(recurrence.frequency),
                  (1...365).contains(recurrence.interval),
                  recurrence.endDate == nil || date(recurrence.endDate!) != nil,
                  recurrence.daysOfWeek?.allSatisfy({ (0...6).contains($0) }) ?? true else { throw URLError(.cannotParseResponse) }
        }
        return parsed
    }
}

struct ParsedEventResponse: Codable {
    let title: String?
    let startDate: String?
    let endDate: String?
    let isAllDay: Bool?
    let location: String?
    let notes: String?
    let color: String?
    let emoji: String?
    let recurrence: RecurrenceInfo?

    struct RecurrenceInfo: Codable {
        let frequency: String
        let interval: Int
        let endDate: String?
        let daysOfWeek: [Int]?
    }
}
