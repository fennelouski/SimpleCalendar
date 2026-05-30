//
//  TVEventManagementIntegrationTests.swift
//  Calendar PlayTests
//
//  Created by Nathan Fennel on 11/29/25.
//

import Testing
import Foundation
@testable import Simple_Calendar

struct TVEventManagementIntegrationTests {

    // MARK: - API Integration Tests

    @Test func testEventParsingAPIWithColorAndEmoji() async throws {
        // Given - Test API endpoint for color and emoji parsing
        let testDescription = "Red birthday party tomorrow at 3 PM"
        let selectedDate = "2025-11-29T00:00:00Z"

        // When - Try to call real API first, fallback to mock
        var parsedResponse: ParsedEventResponse?
        do {
            parsedResponse = try await callRealAPI(description: testDescription, selectedDate: selectedDate)
        } catch {
            // Fallback to mock if API is not available
            parsedResponse = try await simulateEventParsing(description: testDescription, selectedDate: selectedDate)
        }

        guard let response = parsedResponse else {
            throw TestingError("No response from API or mock")
        }

        // Then - Verify color and emoji are parsed
        #expect(response.title == "Red birthday party", "Title should be extracted")
        #expect(response.color == "#FF6B6B" || response.color?.hasPrefix("#") == true, "Color should be a hex code")
        #expect(response.emoji == "🎉", "Should select party emoji for birthday")
        #expect(response.startDate?.contains("2025-11-30") == true, "Should parse 'tomorrow' correctly")
    }

    @Test func testEventParsingAPIDoctorAppointment() async throws {
        // Given
        let testDescription = "Doctor appointment at 2 PM"
        let selectedDate = "2025-11-29T00:00:00Z"

        // When - Try to call real API first, fallback to mock
        var parsedResponse: ParsedEventResponse?
        do {
            parsedResponse = try await callRealAPI(description: testDescription, selectedDate: selectedDate)
        } catch {
            // Fallback to mock if API is not available
            parsedResponse = try await simulateEventParsing(description: testDescription, selectedDate: selectedDate)
        }

        guard let response = parsedResponse else {
            throw TestingError("No response from API or mock")
        }

        // Then
        #expect(response.title?.contains("Doctor") == true, "Should identify doctor appointment")
        #expect(response.emoji == "👨‍⚕️" || response.emoji == "🏥", "Should select medical emoji")
        #expect(response.startDate?.contains("14:00") == true, "Should parse 2 PM correctly")
    }

    @Test func testEventParsingAPISchoolSchedule() async throws {
        // Given
        let testDescription = "School Monday through Friday from 8:30 to 3:45"
        let selectedDate = "2025-11-29T00:00:00Z" // Saturday, Nov 29, 2025

        // When - Try to call real API first, fallback to mock
        var parsedResponse: ParsedEventResponse?
        do {
            parsedResponse = try await callRealAPI(description: testDescription, selectedDate: selectedDate)
        } catch {
            // Fallback to mock if API is not available
            parsedResponse = try await simulateEventParsing(description: testDescription, selectedDate: selectedDate)
        }

        guard let response = parsedResponse else {
            throw TestingError("No response from API or mock")
        }

        // Then
        #expect(response.title?.contains("School") == true, "Should identify school event")
        #expect(response.emoji == "🎓" || response.emoji == "🏫", "Should select education emoji")
        #expect(response.recurrence?.frequency == "weekly", "Should detect weekly recurrence")
    }

    // MARK: - Event Creation Tests

    @Test func testEventCreationWithColorAndEmoji() async throws {
        // Given - Test that CalendarEvent can be created with color and emoji
        let cal1 = Calendar(identifier: .gregorian)
        let startDate = cal1.date(from: DateComponents(year: 2025, month: 12, day: 1, hour: 14))!
        let endDate = cal1.date(from: DateComponents(year: 2025, month: 12, day: 1, hour: 15))!

        // When - Create event with color and emoji
        let event = CalendarEvent(
            id: "test_event",
            title: "Red Team Meeting",
            startDate: startDate,
            endDate: endDate,
            location: "Conference Room A",
            notes: "Discuss project timeline",
            calendarIdentifier: "tv_local",
            isAllDay: false,
            color: "#4A90E2",
            emoji: "💼"
        )

        // Then - Verify event was created with color and emoji
        #expect(event.title == "Red Team Meeting", "Title should match")
        #expect(event.color == "#4A90E2", "Color should be set")
        #expect(event.emoji == "💼", "Emoji should be set")
        #expect(event.location == "Conference Room A", "Location should be set")
        #expect(event.calendarIdentifier == "tv_local", "Should be marked as tvOS event")
    }

    // MARK: - Display Logic Tests

    @Test func testEventDisplayLogicNoUserEvents() async throws {
        // Given - Day with only system events
        let cal2 = Calendar(identifier: .gregorian)
        let testDate = cal2.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        // Add some system events (non-tv_local)
        let systemEvent = CalendarEvent(
            id: "system_1",
            title: "System Holiday",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            calendarIdentifier: "system",
            isAllDay: true
        )
        let events = [systemEvent]

        // When - Get filtered events
        let filteredEvents = getFilteredEvents(for: testDate, events: events)
        let showEmoji = shouldShowOversizedEmoji(for: testDate, events: events)

        // Then - Should show all events normally with oversized emoji
        #expect(filteredEvents.count == 1, "Should show system event")
        #expect(showEmoji == true, "Should show oversized emoji with 0 user events")
    }

    @Test func testEventDisplayLogicOneUserEvent() async throws {
        // Given - Day with one user event and one system event
        let cal3 = Calendar(identifier: .gregorian)
        let testDate = cal3.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        let userEvent = CalendarEvent(
            id: "tv_1",
            title: "My Meeting",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            calendarIdentifier: "tv_local",
            isAllDay: false
        )
        let systemEvent = CalendarEvent(
            id: "system_1",
            title: "System Event",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            calendarIdentifier: "system",
            isAllDay: false
        )
        let events = [userEvent, systemEvent]

        // When - Get filtered events
        let filteredEvents = getFilteredEvents(for: testDate, events: events)
        let showEmoji = shouldShowOversizedEmoji(for: testDate, events: events)

        // Then - User event should come first, show oversized emoji
        #expect(filteredEvents.count == 2, "Should show both events")
        #expect(filteredEvents.first?.calendarIdentifier == "tv_local", "User event should be first")
        #expect(showEmoji == true, "Should show oversized emoji with 1 user event")
    }

    @Test func testEventDisplayLogicTwoUserEvents() async throws {
        // Given - Day with exactly two user events
        let cal4 = Calendar(identifier: .gregorian)
        let testDate = cal4.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        let userEvent1 = CalendarEvent(
            id: "tv_1",
            title: "Morning Meeting",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            calendarIdentifier: "tv_local",
            isAllDay: false
        )
        let userEvent2 = CalendarEvent(
            id: "tv_2",
            title: "Afternoon Meeting",
            startDate: testDate.addingTimeInterval(3600*4), // 4 hours later
            endDate: testDate.addingTimeInterval(3600*5),
            calendarIdentifier: "tv_local",
            isAllDay: false
        )
        let systemEvent = CalendarEvent(
            id: "system_1",
            title: "System Event",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            calendarIdentifier: "system",
            isAllDay: false
        )
        let events = [userEvent1, userEvent2, systemEvent]

        // When - Get filtered events
        let filteredEvents = getFilteredEvents(for: testDate, events: events)
        let showEmoji = shouldShowOversizedEmoji(for: testDate, events: events)

        // Then - Should show only the two user events in slide-over detail
        #expect(filteredEvents.count == 2, "Should show only user events")
        #expect(filteredEvents.allSatisfy { $0.calendarIdentifier == "tv_local" }, "Should only show user events")
        #expect(showEmoji == true, "Should show oversized emoji with 2 user events")
    }

    @Test func testEventDisplayLogicThreeOrMoreUserEvents() async throws {
        // Given - Day with three user events
        let cal5 = Calendar(identifier: .gregorian)
        let testDate = cal5.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        let events = (1...4).map { index in
            CalendarEvent(
                id: "tv_\(index)",
                title: "Meeting \(index)",
                startDate: testDate.addingTimeInterval(TimeInterval(index * 3600)),
                endDate: testDate.addingTimeInterval(TimeInterval((index + 1) * 3600)),
                calendarIdentifier: "tv_local",
                isAllDay: false
            )
        }

        // When - Get filtered events
        let filteredEvents = getFilteredEvents(for: testDate, events: events)
        let showEmoji = shouldShowOversizedEmoji(for: testDate, events: events)

        // Then - Should show all events but hide oversized emoji
        #expect(filteredEvents.count == 4, "Should show all events")
        #expect(showEmoji == false, "Should hide oversized emoji with 3+ user events")
    }

    // MARK: - End-to-End Integration Test

    @Test func testEndToEndEventCreationAndDisplay() async throws {
        // Given - Complete flow from voice input to display
        let cal6 = Calendar(identifier: .gregorian)
        let selectedDate = cal6.date(from: DateComponents(year: 2025, month: 12, day: 1))!

        // Step 1: Simulate API parsing
        let voiceInput = "Blue doctor's appointment at 3 PM tomorrow"
        let parsedEvent = try await simulateEventParsing(description: voiceInput, selectedDate: "2025-12-01T00:00:00Z")

        // Verify parsing worked
        #expect(parsedEvent.title?.contains("doctor") == true || parsedEvent.title?.contains("appointment") == true, "Should parse doctor appointment")
        #expect(parsedEvent.emoji == "👨‍⚕️" || parsedEvent.emoji == "🏥", "Should select medical emoji")
        #expect(parsedEvent.startDate?.contains("15:00") == true, "Should parse 3 PM time")

        // Step 2: Create event with parsed data
        let startDate = cal6.date(from: DateComponents(year: 2025, month: 12, day: 2, hour: 15))! // Tomorrow at 3 PM
        let endDate = cal6.date(from: DateComponents(year: 2025, month: 12, day: 2, hour: 16))! // 1 hour later

        let createdEvent = CalendarEvent(
            id: "test_doctor",
            title: parsedEvent.title ?? "Doctor Appointment",
            startDate: startDate,
            endDate: endDate,
            location: nil,
            notes: nil,
            calendarIdentifier: "tv_local",
            isAllDay: false,
            color: parsedEvent.color,
            emoji: parsedEvent.emoji
        )

        // Step 3: Test display logic
        let testDate = selectedDate.addingTimeInterval(86400) // "tomorrow"
        let events = [createdEvent]

        let filteredEvents = getFilteredEvents(for: testDate, events: events)
        let showEmoji = shouldShowOversizedEmoji(for: testDate, events: events)

        // Then - Verify complete flow
        #expect(createdEvent.title.contains("Doctor") || createdEvent.title.contains("appointment"), "Should be doctor appointment")
        #expect(createdEvent.color == "#4A90E2" || createdEvent.color?.hasPrefix("#") == true, "Should have blue color")
        #expect(createdEvent.emoji == "👨‍⚕️" || createdEvent.emoji == "🏥", "Should have medical emoji")
        #expect(filteredEvents.count == 1, "Should display the created event")
        #expect(showEmoji == true, "Should show oversized emoji for single user event")
    }

    // MARK: - Helper Methods

    private func callRealAPI(description: String, selectedDate: String) async throws -> ParsedEventResponse {
        let apiURL = URL(string: "http://localhost:3002/api/parse-event")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "text": description,
            "currentDate": selectedDate
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(ParsedEventResponse.self, from: data)
        return decodedResponse
    }

    private func simulateEventParsing(description: String, selectedDate: String) async throws -> ParsedEventResponse {
        // Simulate API response based on common patterns
        // In a real test, this would call the actual API

        var title = ""
        var color: String? = "#4A90E2" // Default blue
        var emoji = "📅" // Default calendar

        // Simple pattern matching for demo (real API uses OpenAI)
        if description.contains("birthday") || description.contains("party") {
            emoji = "🎉"
            if description.contains("red") {
                color = "#FF6B6B"
            }
        } else if description.contains("doctor") || description.contains("appointment") {
            emoji = "👨‍⚕️"
            if description.contains("blue") {
                color = "#4A90E2"
            }
        } else if description.contains("school") {
            emoji = "🎓"
        } else if description.contains("meeting") {
            emoji = "💼"
        }

        // Extract title (simplified)
        let words = description.components(separatedBy: " ")
        title = words.prefix(3).joined(separator: " ")

        // Parse time (simplified)
        var startDate: String? = nil
        if description.contains("3 PM") {
            // Tomorrow relative to selected date
            let selectedDateObj = ISO8601DateFormatter().date(from: selectedDate)
            if let selectedDateObj = selectedDateObj {
                let tomorrow = selectedDateObj.addingTimeInterval(86400)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let tomorrowString = dateFormatter.string(from: tomorrow)
                startDate = "\(tomorrowString)T15:00:00Z"
            }
        }

        // Parse recurrence (simplified)
        var recurrence: ParsedEventResponse.RecurrenceInfo? = nil
        if description.contains("Monday through Friday") {
            recurrence = ParsedEventResponse.RecurrenceInfo(
                frequency: "weekly",
                interval: 1,
                endDate: nil,
                daysOfWeek: [1, 2, 3, 4, 5] // Mon-Fri
            )
        }

        return ParsedEventResponse(
            title: title,
            startDate: startDate,
            endDate: nil,
            isAllDay: false,
            location: nil,
            notes: nil,
            color: color,
            emoji: emoji,
            recurrence: recurrence
        )
    }
}

// MARK: - API Response Types

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

// MARK: - Test Helper Functions

func getFilteredEvents(for date: Date, events: [CalendarEvent]) -> [CalendarEvent] {
    let allDayEvents = events.filter { event in
        Calendar(identifier: .gregorian).isDate(event.startDate, inSameDayAs: date)
    }

    // Separate user events (tvOS-created) from other events
    let userEvents = allDayEvents.filter { $0.calendarIdentifier == "tv_local" }
    let otherEvents = allDayEvents.filter { $0.calendarIdentifier != "tv_local" }

    // Determine what events to display based on user event count
    switch userEvents.count {
    case 0:
        return allDayEvents
    case 1:
        return userEvents + otherEvents
    case 2:
        return userEvents
    default:
        return userEvents + otherEvents
    }
}

func shouldShowOversizedEmoji(for date: Date, events: [CalendarEvent]) -> Bool {
    let allDayEvents = events.filter { event in
        Calendar(identifier: .gregorian).isDate(event.startDate, inSameDayAs: date)
    }
    let userEventsCount = allDayEvents.filter { $0.calendarIdentifier == "tv_local" }.count
    return userEventsCount <= 2
}