//
//  CalendarModels.swift
//  Simple Calendar
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

enum CalendarViewMode {
    case singleDay
    case twoDays
    case threeDays
    case fourDays
    case fiveDays
    case sixDays
    case sevenDays
    case week // Standard week view
    case twoWeeks
    case month // Approximate for month view
    case agenda // List view of upcoming events

    var dayCount: Int {
        switch self {
        case .singleDay: return 1
        case .twoDays: return 2
        case .threeDays: return 3
        case .fourDays: return 4
        case .fiveDays: return 5
        case .sixDays: return 6
        case .sevenDays: return 7
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 31
        case .agenda: return 0 // Not applicable for agenda view
        }
    }

    var displayName: String {
        switch self {
        case .singleDay: return "1 Day"
        case .twoDays: return "2 Days"
        case .threeDays: return "3 Days"
        case .fourDays: return "4 Days"
        case .fiveDays: return "5 Days"
        case .sixDays: return "6 Days"
        case .sevenDays: return "7 Days"
        case .week: return "Week"
        case .twoWeeks: return "2 Weeks"
        case .month: return "Month"
        case .agenda: return "Agenda"
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
