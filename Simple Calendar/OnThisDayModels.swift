//
//  OnThisDayModels.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation

/// Main response structure from Wikimedia On This Day API
struct OnThisDayResponse: Codable {
    let events: [HistoricalEvent]?
    let births: [Person]?
    let deaths: [Person]?
    let holidays: [Holiday]?
    let selected: [HistoricalEvent]?

    enum CodingKeys: String, CodingKey {
        case events
        case births
        case deaths
        case holidays
        case selected
    }
}

/// Represents a historical event
struct HistoricalEvent: Codable, Identifiable {
    let id = UUID()
    let text: String
    let pages: [Page]?
    let year: Int?

    enum CodingKeys: String, CodingKey {
        case text
        case pages
        case year
    }
}

/// Represents a notable person (birth/death)
struct Person: Codable, Identifiable {
    let id = UUID()
    let text: String
    let pages: [Page]?
    let year: Int?

    enum CodingKeys: String, CodingKey {
        case text
        case pages
        case year
    }
}

/// Represents a holiday or observance
struct Holiday: Codable, Identifiable {
    let id = UUID()
    let text: String
    let pages: [Page]?

    enum CodingKeys: String, CodingKey {
        case text
        case pages
    }
}

/// Page information from Wikipedia
struct Page: Codable {
    let title: String
    let description: String?
    let thumbnail: Thumbnail?
    let content_urls: ContentURLs?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case thumbnail
        case content_urls
    }
}

/// Thumbnail image information
struct Thumbnail: Codable {
    let source: String?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case source
        case width
        case height
    }
}

/// Content URLs for different formats
struct ContentURLs: Codable {
    let desktop: PageURL?
    let mobile: PageURL?

    enum CodingKeys: String, CodingKey {
        case desktop
        case mobile
    }
}

/// Page URL information
struct PageURL: Codable {
    let page: String

    enum CodingKeys: String, CodingKey {
        case page
    }
}

/// Processed data for UI display
struct OnThisDayData: Codable {
    let events: [HistoricalEvent]
    let births: [Person]
    let deaths: [Person]
    let holidays: [Holiday]

    var hasContent: Bool {
        return !events.isEmpty || !births.isEmpty || !deaths.isEmpty || !holidays.isEmpty
    }

    var totalItems: Int {
        return events.count + births.count + deaths.count + holidays.count
    }
}

/// Cache entry for On This Day data
class OnThisDayCacheEntry: Codable {
    let date: Date
    let data: OnThisDayData
    let timestamp: Date

    init(date: Date, data: OnThisDayData, timestamp: Date = Date()) {
        self.date = date
        self.data = data
        self.timestamp = timestamp
    }

    var isExpired: Bool {
        // Cache for 24 hours
        return Date().timeIntervalSince(timestamp) > 24 * 60 * 60
    }
}
