//
//  Simple_CalendarTests.swift
//  Simple CalendarTests
//
//  Created by Nathan Fennel on 11/23/25.
//

import Testing
import Foundation
@testable import Simple_Calendar

struct Simple_CalendarTests {

    // MARK: - Navigation Tests

    @Test func testNavigateDateByWeekBackward() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))! // Monday, Dec 8, 2025
        viewModel.currentDate = startDate

        // When
        viewModel.navigateDate(by: .week, direction: .backward)

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))! // Monday, Dec 1, 2025
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "Navigating one week backward should move exactly 7 days")
    }

    @Test func testNavigateDateByWeekForward() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))! // Monday, Dec 1, 2025
        viewModel.currentDate = startDate

        // When
        viewModel.navigateDate(by: .week, direction: .forward)

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))! // Monday, Dec 8, 2025
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "Navigating one week forward should move exactly 7 days")
    }

    @Test func testMoveUpOneWeek() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))! // Monday, Dec 8, 2025
        viewModel.selectedDate = startDate
        viewModel.currentDate = startDate
        viewModel.viewMode = .threeDays // Ensure we're in a day-based view mode

        // When
        viewModel.moveUpOneWeek()

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))! // Monday, Dec 1, 2025
        #expect(viewModel.selectedDate != nil, "selectedDate should not be nil")
        #expect(calendar.isDate(viewModel.selectedDate!, inSameDayAs: expectedDate),
                "moveUpOneWeek should move selectedDate exactly 7 days backward")
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "moveUpOneWeek should also align currentDate with selectedDate")
    }

    @Test func testMoveDownOneWeek() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))! // Monday, Dec 1, 2025
        viewModel.selectedDate = startDate
        viewModel.currentDate = startDate
        viewModel.viewMode = .threeDays // Ensure we're in a day-based view mode

        // When
        viewModel.moveDownOneWeek()

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))! // Monday, Dec 8, 2025
        #expect(viewModel.selectedDate != nil, "selectedDate should not be nil")
        #expect(calendar.isDate(viewModel.selectedDate!, inSameDayAs: expectedDate),
                "moveDownOneWeek should move selectedDate exactly 7 days forward")
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "moveDownOneWeek should also align currentDate with selectedDate")
    }

    @Test func testNavigateDateByDay() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
        viewModel.currentDate = startDate

        // When
        viewModel.navigateDate(by: .day, direction: .backward)

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 7))!
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "Navigating one day backward should move exactly 1 day")
    }

    @Test func testNavigateDateByMonth() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
        viewModel.currentDate = startDate

        // When
        viewModel.navigateDate(by: .month, direction: .backward)

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 11, day: 8))!
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "Navigating one month backward should move to the same day in previous month")
    }

    @Test func testWeekNavigationConsistency() async throws {
        // Given
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))! // Monday

        // Test navigateDate week navigation
        let viewModel1 = CalendarViewModel()
        viewModel1.currentDate = startDate
        viewModel1.navigateDate(by: .week, direction: .backward)
        let navigateResult = viewModel1.currentDate

        // Test moveUpOneWeek navigation
        let viewModel2 = CalendarViewModel()
        viewModel2.selectedDate = startDate
        viewModel2.currentDate = startDate
        viewModel2.moveUpOneWeek()
        let moveResult = viewModel2.selectedDate!

        // Then
        #expect(calendar.isDate(navigateResult, inSameDayAs: moveResult),
                "Week navigation methods should produce consistent results")
    }

    @Test func testNavigationAcrossYearBoundary() async throws {
        // Given - test around year boundary
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 29))! // Monday near year end
        viewModel.currentDate = startDate

        // When
        viewModel.navigateDate(by: .week, direction: .forward)

        // Then
        let expectedDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))! // Monday in new year
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedDate),
                "Week navigation should work correctly across year boundaries")
    }

    @Test func testCurrentDateStabilityInTwoWeeksView() async throws {
        // Given - test that currentDate doesn't change for navigation within visible range
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        viewModel.viewMode = .twoWeeks
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
        viewModel.currentDate = startDate
        viewModel.selectedDate = startDate

        // When - navigate within the visible range (14 days, so within ±7 days)
        viewModel.moveUpOneWeek() // Should move selectedDate but keep currentDate stable

        // Then - currentDate should remain unchanged since we're within visible range
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: startDate),
                "currentDate should remain stable when navigating within visible range in twoWeeks view")
        #expect(viewModel.selectedDate != nil, "selectedDate should be updated")
        let expectedSelected = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        #expect(calendar.isDate(viewModel.selectedDate!, inSameDayAs: expectedSelected),
                "selectedDate should be moved correctly")
    }

    @Test func testCurrentDateUpdatesOutsideVisibleRange() async throws {
        // Given - test that currentDate changes when navigating outside visible range
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = CalendarViewModel()
        viewModel.viewMode = .threeDays  // Visible range ±1 day
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
        viewModel.currentDate = startDate
        viewModel.selectedDate = startDate

        // When - navigate outside visible range (more than 1 day away)
        // Move 7 days back, which is outside ±1 day range
        viewModel.moveUpOneWeek()

        // Then - currentDate should update to match selectedDate
        let expectedSelected = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: expectedSelected),
                "currentDate should update when navigating outside visible range")
        #expect(calendar.isDate(viewModel.selectedDate!, inSameDayAs: expectedSelected),
                "selectedDate should be moved correctly")
    }

}
