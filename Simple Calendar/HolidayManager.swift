//
//  HolidayManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Manages holiday data and provides holidays for display
class HolidayManager: ObservableObject {
    static let shared = HolidayManager()

    @Published var holidays: [CalendarHoliday] = []

    private let allHolidays: [CalendarHoliday] = [
        .thanksgiving,
        .blackFriday,
        .christmasEve,
        .christmasDay,
        .boxingDay,
        .newYearsEve,
        .newYearsDay,
        .martinLutherKingJrDay,
        .valentinesDay,
        .presidentsDay,
        .indigenousPeoplesDay,
        .piDay,
        .firstDayOfSpring,
        .firstDayOfSummer,
        .fourthOfJuly,
        .memorialDay,
        .veteransDay,
        .halloween,
        .easter,
        .mothersDay,
        .fathersDay
    ]

    private init() {
        loadHolidaysForCurrentYear()
    }

    /// Load holidays for the current year and next year
    private func loadHolidaysForCurrentYear() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let nextYear = currentYear + 1

        var yearHolidays: [CalendarHoliday] = []

        for holiday in allHolidays {
            // Add holiday for current year
            if let currentYearDate = holiday.dateInYear(currentYear) {
                let holidayForCurrentYear = CalendarHoliday(
                    name: holiday.name,
                    date: currentYearDate,
                    emoji: holiday.emoji,
                    description: holiday.description,
                    unsplashSearchTerm: holiday.unsplashSearchTerm,
                    isRecurring: holiday.isRecurring,
                    category: holiday.category
                )
                yearHolidays.append(holidayForCurrentYear)
            }

            // Add holiday for next year (for planning)
            if let nextYearDate = holiday.dateInYear(nextYear) {
                let holidayForNextYear = CalendarHoliday(
                    name: holiday.name,
                    date: nextYearDate,
                    emoji: holiday.emoji,
                    description: holiday.description,
                    unsplashSearchTerm: holiday.unsplashSearchTerm,
                    isRecurring: holiday.isRecurring,
                    category: holiday.category
                )
                yearHolidays.append(holidayForNextYear)
            }
        }

        self.holidays = yearHolidays.sorted(by: { $0.date < $1.date })
    }

    /// Get holidays that occur on a specific date
    func holidaysOn(_ date: Date) -> [CalendarHoliday] {
        holidays.filter { $0.occursOn(date) }
    }

    /// Get all holidays in a specific month and year
    func holidaysInMonth(_ month: Int, year: Int) -> [CalendarHoliday] {
        holidays.filter { holiday in
            let components = Calendar.current.dateComponents([.month, .year], from: holiday.date)
            return components.month == month && components.year == year
        }
    }

    /// Get holidays grouped by category
    func holidaysByCategory() -> [CalendarHoliday.CalendarHolidayCategory: [CalendarHoliday]] {
        Dictionary(grouping: holidays) { $0.category }
    }

    /// Get upcoming holidays (next 12 months from today)
    func upcomingHolidays(limit: Int = 10) -> [CalendarHoliday] {
        let today = Date()
        let futureHolidays = holidays.filter { $0.date >= today }
            .sorted { $0.date < $1.date }

        return Array(futureHolidays.prefix(limit))
    }

    /// Get holidays for a specific year
    func holidaysForYear(_ year: Int) -> [CalendarHoliday] {
        holidays.filter { holiday in
            Calendar.current.component(.year, from: holiday.date) == year
        }
    }

    /// Refresh holidays for new years as needed
    func refreshHolidaysIfNeeded() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let hasCurrentYear = holidays.contains { holiday in
            Calendar.current.component(.year, from: holiday.date) == currentYear
        }

        if !hasCurrentYear {
            loadHolidaysForCurrentYear()
        }
    }
}
