//
//  Holiday.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation

/// Represents a holiday with its details
struct CalendarHoliday: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let date: Date
    let emoji: String
    let description: String
    let unsplashSearchTerm: String
    let isRecurring: Bool
    let category: CalendarHolidayCategory

    enum CalendarHolidayCategory: String, CaseIterable {
        case religious = "Religious"
        case cultural = "Cultural"
        case national = "National"
        case seasonal = "Seasonal"
        case educational = "Educational"
        case other = "Other"
    }

    /// Check if this holiday occurs on the given date
    func occursOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if isRecurring {
            // For recurring holidays, check month and day
            let holidayComponents = calendar.dateComponents([.month, .day], from: self.date)
            let checkComponents = calendar.dateComponents([.month, .day], from: date)
            return holidayComponents.month == checkComponents.month &&
                   holidayComponents.day == checkComponents.day
        } else {
            // For fixed date holidays, check exact date
            return calendar.isDate(self.date, inSameDayAs: date)
        }
    }

    /// Get the date for this holiday in the given year
    func dateInYear(_ year: Int) -> Date? {
        if isRecurring {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.month, .day], from: self.date)
            components.year = year
            return calendar.date(from: components)
        } else {
            return self.date
        }
    }
}

/// Static holiday definitions for common holidays
extension CalendarHoliday {
    static let thanksgiving = CalendarHoliday(
        name: "Thanksgiving",
        date: createDate(month: 11, day: 28, year: 2024), // Will be calculated properly
        emoji: "🦃",
        description: "A holiday celebrating gratitude and harvest, traditionally involving a feast with turkey and family gatherings.",
        unsplashSearchTerm: "thanksgiving dinner",
        isRecurring: true,
        category: .cultural
    )

    static let blackFriday = CalendarHoliday(
        name: "Black Friday",
        date: createDate(month: 11, day: 29, year: 2024),
        emoji: "🛍️",
        description: "The day after Thanksgiving, known for major shopping deals and the start of the holiday shopping season.",
        unsplashSearchTerm: "black friday shopping",
        isRecurring: true,
        category: .cultural
    )

    static let christmasEve = CalendarHoliday(
        name: "Christmas Eve",
        date: createDate(month: 12, day: 24, year: 2024),
        emoji: "🎄",
        description: "The evening before Christmas Day, often celebrated with family gatherings and preparations for Christmas.",
        unsplashSearchTerm: "christmas eve",
        isRecurring: true,
        category: .religious
    )

    static let christmasDay = CalendarHoliday(
        name: "Christmas Day",
        date: createDate(month: 12, day: 25, year: 2024),
        emoji: "🎅",
        description: "A Christian holiday celebrating the birth of Jesus Christ, celebrated with gift-giving and family time.",
        unsplashSearchTerm: "christmas morning",
        isRecurring: true,
        category: .religious
    )

    static let boxingDay = CalendarHoliday(
        name: "Boxing Day",
        date: createDate(month: 12, day: 26, year: 2024),
        emoji: "📦",
        description: "Celebrated in many countries, traditionally a day for giving gifts to those who have helped throughout the year.",
        unsplashSearchTerm: "boxing day",
        isRecurring: true,
        category: .cultural
    )

    static let newYearsEve = CalendarHoliday(
        name: "New Year's Eve",
        date: createDate(month: 12, day: 31, year: 2024),
        emoji: "🎊",
        description: "The last day of the year, celebrated with parties and fireworks as people welcome the new year.",
        unsplashSearchTerm: "new years eve celebration",
        isRecurring: true,
        category: .cultural
    )

    static let newYearsDay = CalendarHoliday(
        name: "New Year's Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "🎉",
        description: "The first day of the new year, celebrated with resolutions, parades, and family gatherings.",
        unsplashSearchTerm: "new years day",
        isRecurring: true,
        category: .cultural
    )

    static let martinLutherKingJrDay = CalendarHoliday(
        name: "Martin Luther King Jr. Day",
        date: createDate(month: 1, day: 20, year: 2025), // Third Monday of January
        emoji: "✊",
        description: "Honoring Dr. Martin Luther King Jr., celebrating his legacy of civil rights and equality.",
        unsplashSearchTerm: "martin luther king jr memorial",
        isRecurring: true,
        category: .national
    )

    static let valentinesDay = CalendarHoliday(
        name: "Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A day celebrating love and affection, often involving cards, flowers, and romantic gestures.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .cultural
    )

    static let presidentsDay = CalendarHoliday(
        name: "Presidents' Day",
        date: createDate(month: 2, day: 17, year: 2025), // Third Monday of February
        emoji: "🇺🇸",
        description: "Honoring all U.S. presidents, originally Washington's Birthday, now a federal holiday.",
        unsplashSearchTerm: "presidents day",
        isRecurring: true,
        category: .national
    )

    static let indigenousPeoplesDay = CalendarHoliday(
        name: "Indigenous Peoples' Day",
        date: createDate(month: 10, day: 14, year: 2024), // Second Monday of October
        emoji: "🪶",
        description: "Celebrating the history, culture, and resilience of Indigenous peoples of the Americas.",
        unsplashSearchTerm: "indigenous peoples day",
        isRecurring: true,
        category: .cultural
    )

    static let piDay = CalendarHoliday(
        name: "Pi Day",
        date: createDate(month: 3, day: 14, year: 2025),
        emoji: "🥧",
        description: "Celebrating the mathematical constant π (pi), often with pie-eating and math activities.",
        unsplashSearchTerm: "pi day celebration",
        isRecurring: true,
        category: .educational
    )

    static let firstDayOfSpring = CalendarHoliday(
        name: "First Day of Spring",
        date: createDate(month: 3, day: 20, year: 2025), // Vernal equinox
        emoji: "🌸",
        description: "The vernal equinox, marking the beginning of spring and longer days.",
        unsplashSearchTerm: "spring flowers blooming",
        isRecurring: true,
        category: .seasonal
    )

    static let firstDayOfSummer = CalendarHoliday(
        name: "First Day of Summer",
        date: createDate(month: 6, day: 21, year: 2025), // Summer solstice
        emoji: "☀️",
        description: "The summer solstice, the longest day of the year and beginning of summer.",
        unsplashSearchTerm: "summer solstice",
        isRecurring: true,
        category: .seasonal
    )

    static let fourthOfJuly = CalendarHoliday(
        name: "Independence Day",
        date: createDate(month: 7, day: 4, year: 2025),
        emoji: "🎆",
        description: "Celebrating America's independence with fireworks, parades, and patriotic activities.",
        unsplashSearchTerm: "fourth of july fireworks",
        isRecurring: true,
        category: .national
    )

    static let memorialDay = CalendarHoliday(
        name: "Memorial Day",
        date: createDate(month: 5, day: 26, year: 2025), // Last Monday of May
        emoji: "🇺🇸",
        description: "Honoring those who died serving in the U.S. military, traditionally the start of summer.",
        unsplashSearchTerm: "memorial day parade",
        isRecurring: true,
        category: .national
    )

    static let veteransDay = CalendarHoliday(
        name: "Veterans Day",
        date: createDate(month: 11, day: 11, year: 2025),
        emoji: "🎖️",
        description: "Honoring all veterans who have served in the U.S. military.",
        unsplashSearchTerm: "veterans day memorial",
        isRecurring: true,
        category: .national
    )

    static let halloween = CalendarHoliday(
        name: "Halloween",
        date: createDate(month: 10, day: 31, year: 2024),
        emoji: "🎃",
        description: "A fun holiday involving costumes, trick-or-treating, and spooky decorations.",
        unsplashSearchTerm: "halloween pumpkin",
        isRecurring: true,
        category: .cultural
    )

    static let easter = CalendarHoliday(
        name: "Easter",
        date: createDate(month: 4, day: 20, year: 2025), // Calculated based on lunar calendar
        emoji: "🐣",
        description: "Christian holiday celebrating the resurrection of Jesus Christ, with egg hunts and spring themes.",
        unsplashSearchTerm: "easter eggs",
        isRecurring: true,
        category: .religious
    )

    static let mothersDay = CalendarHoliday(
        name: "Mother's Day",
        date: createDate(month: 5, day: 11, year: 2025), // Second Sunday of May
        emoji: "👩‍👧‍👦",
        description: "A day to honor mothers and mother figures with cards, flowers, and special activities.",
        unsplashSearchTerm: "mothers day flowers",
        isRecurring: true,
        category: .cultural
    )

    static let fathersDay = CalendarHoliday(
        name: "Father's Day",
        date: createDate(month: 6, day: 15, year: 2025), // Third Sunday of June
        emoji: "👨‍👧‍👦",
        description: "A day to honor fathers and father figures with cards, gifts, and special activities.",
        unsplashSearchTerm: "fathers day grill",
        isRecurring: true,
        category: .cultural
    )

    private static func createDate(month: Int, day: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

/// Helper function to create dates
private func createDate(month: Int, day: Int, year: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}
}
