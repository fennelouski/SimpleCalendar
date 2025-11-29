//
//  CalendarModels.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var calendarIdentifier: String
    var isAllDay: Bool
    var imageUrl: String?
    var imageRepositoryId: String?

    init(id: String, title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, calendarIdentifier: String, isAllDay: Bool = false, imageUrl: String? = nil, imageRepositoryId: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.calendarIdentifier = calendarIdentifier
        self.isAllDay = isAllDay
        self.imageUrl = imageUrl
        self.imageRepositoryId = imageRepositoryId
    }
}

enum CalendarViewMode: String {
    case singleDay = "singleDay"
    case threeDays = "threeDays" // Default
    case fiveDays = "fiveDays"
    case sevenDays = "sevenDays"
    case twoWeeks = "twoWeeks"
    case month = "month"
    case year = "year" // Keep for existing functionality
    case agenda = "agenda" // Keep for existing functionality

    // Only expose the 6 view modes requested by user in iOS popup
    static var userSelectableCases: [CalendarViewMode] {
        [.singleDay, .threeDays, .fiveDays, .sevenDays, .twoWeeks, .month]
    }

    var dayCount: Int {
        switch self {
        case .singleDay: return 1
        case .threeDays: return 3
        case .fiveDays: return 5
        case .sevenDays: return 7
        case .twoWeeks: return 14
        case .month: return 31
        case .year: return 365
        case .agenda: return 0
        }
    }

    var displayName: String {
        switch self {
        case .singleDay: return "One Day View"
        case .threeDays: return "Three Day View"
        case .fiveDays: return "Five Day View"
        case .sevenDays: return "7 Day View"
        case .twoWeeks: return "2 Week View"
        case .month: return "Month View"
        case .year: return "Year View"
        case .agenda: return "Agenda View"
        }
    }
}

struct CalendarDay: Identifiable {
    let id: Date
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let events: [CalendarEvent]
    let isCurrentMonth: Bool
}
