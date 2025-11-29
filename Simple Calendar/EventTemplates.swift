//
//  EventTemplates.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation

struct EventTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let title: String
    let duration: TimeInterval // in seconds
    let location: String?
    let notes: String?
    let isAllDay: Bool
    let category: EventCategory

    enum EventCategory: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
        case health = "Health & Fitness"
        case social = "Social"
        case education = "Education"
        case travel = "Travel"
        case other = "Other"
    }

    static let templates: [EventTemplate] = [
        // Work templates
        EventTemplate(
            name: "Meeting",
            title: "Meeting",
            duration: 3600, // 1 hour
            location: "Conference Room",
            notes: "Agenda:\n- Topic 1\n- Topic 2\n- Action items",
            isAllDay: false,
            category: .work
        ),

        EventTemplate(
            name: "Project Review",
            title: "Project Review",
            duration: 5400, // 1.5 hours
            location: nil,
            notes: "Review project progress and next steps",
            isAllDay: false,
            category: .work
        ),

        EventTemplate(
            name: "One-on-One",
            title: "1:1 Meeting",
            duration: 1800, // 30 minutes
            location: nil,
            notes: "Discuss goals, feedback, and development",
            isAllDay: false,
            category: .work
        ),

        // Personal templates
        EventTemplate(
            name: "Doctor Appointment",
            title: "Doctor Appointment",
            duration: 1800, // 30 minutes
            location: "Medical Center",
            notes: "Bring insurance card and any relevant medical records",
            isAllDay: false,
            category: .health
        ),

        EventTemplate(
            name: "Dentist",
            title: "Dentist Appointment",
            duration: 3600, // 1 hour
            location: "Dental Office",
            notes: nil,
            isAllDay: false,
            category: .health
        ),

        EventTemplate(
            name: "Gym Workout",
            title: "Gym Workout",
            duration: 5400, // 1.5 hours
            location: "Gym",
            notes: "Focus on:\n- Cardio\n- Strength training\n- Stretching",
            isAllDay: false,
            category: .health
        ),

        EventTemplate(
            name: "Dinner with Friends",
            title: "Dinner",
            duration: 7200, // 2 hours
            location: "Restaurant",
            notes: nil,
            isAllDay: false,
            category: .social
        ),

        EventTemplate(
            name: "Birthday Party",
            title: "Birthday Party",
            duration: 14400, // 4 hours
            location: "Home",
            notes: "Don't forget:\n- Cake\n- Presents\n- Decorations",
            isAllDay: false,
            category: .social
        ),

        EventTemplate(
            name: "Coffee Meetup",
            title: "Coffee",
            duration: 3600, // 1 hour
            location: "Coffee Shop",
            notes: nil,
            isAllDay: false,
            category: .social
        ),

        // Education templates
        EventTemplate(
            name: "Class",
            title: "Class",
            duration: 5400, // 1.5 hours
            location: "Classroom",
            notes: "Topics to cover:\n- Chapter readings\n- Assignments",
            isAllDay: false,
            category: .education
        ),

        EventTemplate(
            name: "Study Session",
            title: "Study Session",
            duration: 7200, // 2 hours
            location: "Library",
            notes: "Study materials:\n- Textbook\n- Notes\n- Practice problems",
            isAllDay: false,
            category: .education
        ),

        // Travel templates
        EventTemplate(
            name: "Flight",
            title: "Flight",
            duration: 14400, // 4 hours (approximate)
            location: "Airport",
            notes: "Flight details:\n- Airline: \n- Flight number: \n- Gate: \n\nPacking checklist:\n- Passport/ID\n- Boarding pass\n- Carry-on items",
            isAllDay: false,
            category: .travel
        ),

        EventTemplate(
            name: "Hotel Stay",
            title: "Hotel Check-in",
            duration: 604800, // 1 week
            location: "Hotel",
            notes: "Hotel details:\n- Name: \n- Address: \n- Room number: \n- Check-in time: \n- Check-out time:",
            isAllDay: true,
            category: .travel
        ),

        // Other templates
        EventTemplate(
            name: "Appointment",
            title: "Appointment",
            duration: 3600, // 1 hour
            location: nil,
            notes: nil,
            isAllDay: false,
            category: .other
        ),

        EventTemplate(
            name: "Reminder",
            title: "Reminder",
            duration: 1800, // 30 minutes
            location: nil,
            notes: "What to remember:",
            isAllDay: false,
            category: .other
        ),

        EventTemplate(
            name: "All Day Event",
            title: "All Day Event",
            duration: 86400, // 24 hours
            location: nil,
            notes: nil,
            isAllDay: true,
            category: .other
        )
    ]

    static func templates(for category: EventCategory) -> [EventTemplate] {
        return templates.filter { $0.category == category }
    }

    func createEvent(startingAt startDate: Date) -> CalendarEvent {
        return CalendarEvent(
            id: UUID().uuidString,
            title: title,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            location: location,
            notes: notes,
            calendarIdentifier: "template",
            isAllDay: isAllDay
        )
    }
}
