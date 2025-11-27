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
        // For both recurring and fixed holidays, check if they occur on the same day
        // Each holiday instance already has the correct date set for its specific year
        return calendar.isDate(self.date, inSameDayAs: date)
    }

    /// Get the date for this holiday in the given year
    func dateInYear(_ year: Int) -> Date? {
        if isRecurring {
            // Handle special cases for holidays that don't have fixed dates
            switch name {
            case "Thanksgiving":
                return thanksgivingDate(for: year)
            case "Black Friday":
                if let thanksgiving = thanksgivingDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 1, to: thanksgiving)
                }
                return nil
            case "Cyber Monday":
                if let thanksgiving = thanksgivingDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 4, to: thanksgiving)
                }
                return nil
            case "Martin Luther King Jr. Day":
                return nthWeekdayOfMonth(year: year, month: 1, weekday: .monday, n: 3)
            case "Presidents' Day", "Washington's Birthday":
                return nthWeekdayOfMonth(year: year, month: 2, weekday: .monday, n: 3)
            case "Indigenous Peoples' Day", "Columbus Day":
                return nthWeekdayOfMonth(year: year, month: 10, weekday: .monday, n: 2)
            case "Memorial Day":
                return lastWeekdayOfMonth(year: year, month: 5, weekday: .monday)
            case "Mother's Day":
                return nthWeekdayOfMonth(year: year, month: 5, weekday: .sunday, n: 2)
            case "Father's Day":
                return nthWeekdayOfMonth(year: year, month: 6, weekday: .sunday, n: 3)
            case "Labor Day":
                return nthWeekdayOfMonth(year: year, month: 9, weekday: .monday, n: 1)
            case "Patriot Day":
                // Fixed date but marked as recurring
                return createDateForYear(month: 9, day: 11, year: year)
            case "Election Day":
                return nthWeekdayOfMonth(year: year, month: 11, weekday: .tuesday, n: 1)
            case "Easter":
                return easterDate(for: year)
            case "Good Friday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -2, to: easter)
                }
                return nil
            case "Palm Sunday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -7, to: easter)
                }
                return nil
            case "Maundy Thursday", "Holy Thursday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -3, to: easter)
                }
                return nil
            case "Holy Saturday", "Easter Saturday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -1, to: easter)
                }
                return nil
            case "Easter Monday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 1, to: easter)
                }
                return nil
            case "Ascension Day":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 39, to: easter)
                }
                return nil
            case "Pentecost", "Whitsunday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 49, to: easter)
                }
                return nil
            case "Whit Monday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 50, to: easter)
                }
                return nil
            case "Trinity Sunday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 56, to: easter)
                }
                return nil
            case "Corpus Christi":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: 60, to: easter)
                }
                return nil
            case "Mardi Gras", "Fat Tuesday", "Shrove Tuesday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -47, to: easter)
                }
                return nil
            case "Ash Wednesday":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -46, to: easter)
                }
                return nil
            case "Lent Begins":
                if let easter = easterDate(for: year) {
                    return Calendar.current.date(byAdding: .day, value: -46, to: easter)
                }
                return nil
            case "First Sunday of Advent":
                // Sunday closest to November 30
                var components = DateComponents()
                components.year = year
                components.month = 11
                components.day = 30
                if let nov30 = Calendar.current.date(from: components) {
                    let weekday = Calendar.current.component(.weekday, from: nov30)
                    let daysToSubtract = (weekday - Weekday.sunday.rawValue + 7) % 7
                    return Calendar.current.date(byAdding: .day, value: -daysToSubtract, to: nov30)
                }
                return nil
            case "Groundhog Day":
                return createDateForYear(month: 2, day: 2, year: year)
            case "Daylight Saving Time Begins":
                return nthWeekdayOfMonth(year: year, month: 3, weekday: .sunday, n: 2)
            case "Daylight Saving Time Ends":
                return nthWeekdayOfMonth(year: year, month: 11, weekday: .sunday, n: 1)
            case "Armed Forces Day":
                return nthWeekdayOfMonth(year: year, month: 5, weekday: .saturday, n: 3)
            case "National Friendship Day":
                return nthWeekdayOfMonth(year: year, month: 8, weekday: .sunday, n: 1)
            case "Super Bowl Sunday":
                // First Sunday in February
                return nthWeekdayOfMonth(year: year, month: 2, weekday: .sunday, n: 1)
            case "Kentucky Derby":
                // First Saturday in May
                return nthWeekdayOfMonth(year: year, month: 5, weekday: .saturday, n: 1)
            case "Grandparents Day":
                // First Sunday after Labor Day (first Monday of September)
                if let laborDay = nthWeekdayOfMonth(year: year, month: 9, weekday: .monday, n: 1) {
                    // Find the following Sunday
                    let weekday = Calendar.current.component(.weekday, from: laborDay)
                    let daysToSunday = (Weekday.sunday.rawValue - weekday + 7) % 7
                    return Calendar.current.date(byAdding: .day, value: daysToSunday, to: laborDay)
                }
                return nil
            case "National Ice Cream Day":
                // Third Sunday in July
                return nthWeekdayOfMonth(year: year, month: 7, weekday: .sunday, n: 3)
            case "Arbor Day":
                // Last Friday of April
                return lastWeekdayOfMonth(year: year, month: 4, weekday: .friday)
            case "National Donut Day":
                // First Friday in June
                return nthWeekdayOfMonth(year: year, month: 6, weekday: .friday, n: 1)
            case "Inauguration Day":
                // Every 4 years starting from years divisible by 4 (2020, 2024, 2028, etc.)
                // Only return a date if it's an inauguration year
                if year % 4 == 0 {
                    // January 20th, or 21st if the 20th is a Sunday
                    var components = DateComponents()
                    components.year = year
                    components.month = 1
                    components.day = 20
                    if let jan20 = Calendar.current.date(from: components) {
                        let weekday = Calendar.current.component(.weekday, from: jan20)
                        // If January 20 is a Sunday, move to Monday
                        if weekday == Weekday.sunday.rawValue {
                            return Calendar.current.date(byAdding: .day, value: 1, to: jan20)
                        }
                        return jan20
                    }
                }
                return nil // Not an inauguration year
            case "Leap Day":
                // Only in leap years (divisible by 4, except century years not divisible by 400)
                if isLeapYear(year) {
                    return createDateForYear(month: 2, day: 29, year: year)
                }
                return nil // Not a leap year
            case "Election Day":
                // First Tuesday after the first Monday in November
                if let firstMonday = nthWeekdayOfMonth(year: year, month: 11, weekday: .monday, n: 1) {
                    return Calendar.current.date(byAdding: .day, value: 1, to: firstMonday)
                }
                return nil
            case "Teacher Appreciation Day":
                // First Tuesday of first full week in May (effectively first Tuesday)
                return nthWeekdayOfMonth(year: year, month: 5, weekday: .tuesday, n: 1)
            case "Mother's Day Weekend":
                // The Saturday before Mother's Day
                if let mothersDay = nthWeekdayOfMonth(year: year, month: 5, weekday: .sunday, n: 2) {
                    return Calendar.current.date(byAdding: .day, value: -1, to: mothersDay)
                }
                return nil
            case "Memorial Day Weekend":
                // The Saturday before Memorial Day (last Monday of May)
                if let memorialDay = lastWeekdayOfMonth(year: year, month: 5, weekday: .monday) {
                    return Calendar.current.date(byAdding: .day, value: -2, to: memorialDay)
                }
                return nil
            case "Labor Day Weekend":
                // The Saturday before Labor Day (first Monday of September)
                if let laborDay = nthWeekdayOfMonth(year: year, month: 9, weekday: .monday, n: 1) {
                    return Calendar.current.date(byAdding: .day, value: -2, to: laborDay)
                }
                return nil
            default:
                // For other recurring holidays, use the stored date but update the year
                let calendar = Calendar.current
                var components = calendar.dateComponents([.month, .day], from: self.date)
                components.year = year
                return calendar.date(from: components)
            }
        } else {
            return self.date
        }
    }
    
    /// Check if a year is a leap year
    private func isLeapYear(_ year: Int) -> Bool {
        // Leap year if divisible by 4, except century years must be divisible by 400
        if year % 4 != 0 {
            return false
        }
        if year % 100 == 0 {
            return year % 400 == 0
        }
        return true
    }
    
    /// Helper to create date for a specific year
    private func createDateForYear(month: Int, day: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    /// Calculate Thanksgiving date (fourth Thursday of November)
    private func thanksgivingDate(for year: Int) -> Date? {
        nthWeekdayOfMonth(year: year, month: 11, weekday: .thursday, n: 4)
    }

    /// Calculate Easter date using the algorithm
    private func easterDate(for year: Int) -> Date? {
        // Easter calculation using Meeus/Jones/Butcher algorithm
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    /// Find the nth weekday of a given month and year
    private func nthWeekdayOfMonth(year: Int, month: Int, weekday: Weekday, n: Int) -> Date? {
        let calendar = Calendar.current

        // Start of the month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startOfMonth = calendar.date(from: components) else { return nil }

        // Find the first occurrence of the weekday in the month
        let weekdayOffset = (weekday.rawValue - calendar.component(.weekday, from: startOfMonth) + 7) % 7
        let firstWeekday = calendar.date(byAdding: .day, value: weekdayOffset, to: startOfMonth)

        // Calculate the nth occurrence
        guard let firstOccurrence = firstWeekday else { return nil }
        let nthOccurrence = calendar.date(byAdding: .day, value: (n - 1) * 7, to: firstOccurrence)

        return nthOccurrence
    }

    /// Find the last weekday of a given month and year
    private func lastWeekdayOfMonth(year: Int, month: Int, weekday: Weekday) -> Date? {
        let calendar = Calendar.current

        // Start of next month
        var nextMonthComponents = DateComponents()
        nextMonthComponents.year = month == 12 ? year + 1 : year
        nextMonthComponents.month = month == 12 ? 1 : month + 1
        nextMonthComponents.day = 1

        guard let startOfNextMonth = calendar.date(from: nextMonthComponents) else { return nil }

        // Go back one day to get end of current month
        guard let endOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth) else { return nil }

        // Find the last occurrence of the weekday
        let endWeekday = calendar.component(.weekday, from: endOfMonth)
        let weekdayOffset = (endWeekday - weekday.rawValue + 7) % 7
        let lastWeekday = calendar.date(byAdding: .day, value: -weekdayOffset, to: endOfMonth)

        return lastWeekday
    }

    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
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
    
    // MARK: - Government/Banking Holidays (National)
    
    static let laborDay = CalendarHoliday(
        name: "Labor Day",
        date: createDate(month: 9, day: 1, year: 2025), // First Monday of September
        emoji: "🔨",
        description: "Honoring the contributions of American workers and the labor movement.",
        unsplashSearchTerm: "labor day parade",
        isRecurring: true,
        category: .national
    )
    
    static let columbusDay = CalendarHoliday(
        name: "Columbus Day",
        date: createDate(month: 10, day: 14, year: 2024), // Second Monday of October
        emoji: "🚢",
        description: "Commemorating Christopher Columbus's arrival in the Americas in 1492.",
        unsplashSearchTerm: "columbus day",
        isRecurring: true,
        category: .national
    )
    
    static let patriotDay = CalendarHoliday(
        name: "Patriot Day",
        date: createDate(month: 9, day: 11, year: 2025),
        emoji: "🇺🇸",
        description: "Remembering the victims of the September 11, 2001 terrorist attacks.",
        unsplashSearchTerm: "patriot day memorial",
        isRecurring: true,
        category: .national
    )
    
    static let electionDay = CalendarHoliday(
        name: "Election Day",
        date: createDate(month: 11, day: 4, year: 2025), // First Tuesday after first Monday in November
        emoji: "🗳️",
        description: "Election Day for federal offices, held on the first Tuesday after the first Monday in November.",
        unsplashSearchTerm: "election day voting",
        isRecurring: true,
        category: .national
    )
    
    static let juneteenth = CalendarHoliday(
        name: "Juneteenth",
        date: createDate(month: 6, day: 19, year: 2025),
        emoji: "🆓",
        description: "Commemorating the emancipation of enslaved African Americans in the United States.",
        unsplashSearchTerm: "juneteenth celebration",
        isRecurring: true,
        category: .national
    )
    
    static let washingtonsBirthday = CalendarHoliday(
        name: "Washington's Birthday",
        date: createDate(month: 2, day: 22, year: 2025),
        emoji: "🇺🇸",
        description: "Honoring the first president of the United States, George Washington.",
        unsplashSearchTerm: "george washington",
        isRecurring: true,
        category: .national
    )
    
    static let lincolnsBirthday = CalendarHoliday(
        name: "Lincoln's Birthday",
        date: createDate(month: 2, day: 12, year: 2025),
        emoji: "🇺🇸",
        description: "Commemorating the birth of Abraham Lincoln, the 16th president of the United States.",
        unsplashSearchTerm: "abraham lincoln",
        isRecurring: true,
        category: .national
    )
    
    static let flagDay = CalendarHoliday(
        name: "Flag Day",
        date: createDate(month: 6, day: 14, year: 2025),
        emoji: "🇺🇸",
        description: "Commemorating the adoption of the flag of the United States on June 14, 1777.",
        unsplashSearchTerm: "american flag",
        isRecurring: true,
        category: .national
    )
    
    static let constitutionDay = CalendarHoliday(
        name: "Constitution Day",
        date: createDate(month: 9, day: 17, year: 2025),
        emoji: "📜",
        description: "Commemorating the signing of the United States Constitution on September 17, 1787.",
        unsplashSearchTerm: "constitution day",
        isRecurring: true,
        category: .national
    )
    
    static let pearlHarborDay = CalendarHoliday(
        name: "Pearl Harbor Remembrance Day",
        date: createDate(month: 12, day: 7, year: 2025),
        emoji: "⚓",
        description: "Commemorating the attack on Pearl Harbor on December 7, 1941.",
        unsplashSearchTerm: "pearl harbor memorial",
        isRecurring: true,
        category: .national
    )
    
    static let arborDay = CalendarHoliday(
        name: "Arbor Day",
        date: createDate(month: 4, day: 26, year: 2025), // Last Friday of April
        emoji: "🌳",
        description: "A holiday encouraging tree planting and environmental awareness.",
        unsplashSearchTerm: "tree planting",
        isRecurring: true,
        category: .national
    )
    
    // MARK: - Religious Holidays
    
    static let goodFriday = CalendarHoliday(
        name: "Good Friday",
        date: createDate(month: 4, day: 18, year: 2025),
        emoji: "✝️",
        description: "Christian holiday commemorating the crucifixion of Jesus Christ.",
        unsplashSearchTerm: "good friday",
        isRecurring: true,
        category: .religious
    )
    
    static let palmSunday = CalendarHoliday(
        name: "Palm Sunday",
        date: createDate(month: 4, day: 13, year: 2025),
        emoji: "🌴",
        description: "Christian holiday marking the beginning of Holy Week, commemorating Jesus's entry into Jerusalem.",
        unsplashSearchTerm: "palm sunday",
        isRecurring: true,
        category: .religious
    )
    
    static let maundyThursday = CalendarHoliday(
        name: "Maundy Thursday",
        date: createDate(month: 4, day: 17, year: 2025),
        emoji: "🍞",
        description: "Christian holiday commemorating the Last Supper of Jesus Christ with the Apostles.",
        unsplashSearchTerm: "last supper",
        isRecurring: true,
        category: .religious
    )
    
    static let holySaturday = CalendarHoliday(
        name: "Holy Saturday",
        date: createDate(month: 4, day: 19, year: 2025),
        emoji: "🕊️",
        description: "The day before Easter Sunday, commemorating the day Jesus's body lay in the tomb.",
        unsplashSearchTerm: "holy saturday",
        isRecurring: true,
        category: .religious
    )
    
    static let easterMonday = CalendarHoliday(
        name: "Easter Monday",
        date: createDate(month: 4, day: 21, year: 2025),
        emoji: "🐰",
        description: "The day after Easter Sunday, a continuation of the Easter celebration.",
        unsplashSearchTerm: "easter monday",
        isRecurring: true,
        category: .religious
    )
    
    static let ascensionDay = CalendarHoliday(
        name: "Ascension Day",
        date: createDate(month: 5, day: 29, year: 2025),
        emoji: "☁️",
        description: "Christian holiday commemorating the ascension of Jesus Christ into heaven.",
        unsplashSearchTerm: "ascension day",
        isRecurring: true,
        category: .religious
    )
    
    static let pentecost = CalendarHoliday(
        name: "Pentecost",
        date: createDate(month: 6, day: 8, year: 2025),
        emoji: "🔥",
        description: "Christian holiday commemorating the descent of the Holy Spirit upon the Apostles.",
        unsplashSearchTerm: "pentecost",
        isRecurring: true,
        category: .religious
    )
    
    static let whitMonday = CalendarHoliday(
        name: "Whit Monday",
        date: createDate(month: 6, day: 9, year: 2025),
        emoji: "🕊️",
        description: "The day after Pentecost, also known as Monday of the Holy Spirit.",
        unsplashSearchTerm: "whit monday",
        isRecurring: true,
        category: .religious
    )
    
    static let trinitySunday = CalendarHoliday(
        name: "Trinity Sunday",
        date: createDate(month: 6, day: 15, year: 2025),
        emoji: "☦️",
        description: "Christian feast day honoring the Holy Trinity: the Father, the Son, and the Holy Spirit.",
        unsplashSearchTerm: "trinity sunday",
        isRecurring: true,
        category: .religious
    )
    
    static let corpusChristi = CalendarHoliday(
        name: "Corpus Christi",
        date: createDate(month: 6, day: 19, year: 2025),
        emoji: "⛪",
        description: "Christian feast day honoring the Eucharist and the body of Christ.",
        unsplashSearchTerm: "corpus christi",
        isRecurring: true,
        category: .religious
    )
    
    static let mardiGras = CalendarHoliday(
        name: "Mardi Gras",
        date: createDate(month: 3, day: 4, year: 2025),
        emoji: "🎭",
        description: "Fat Tuesday, the last day of Carnival before Lent begins.",
        unsplashSearchTerm: "mardi gras celebration",
        isRecurring: true,
        category: .religious
    )
    
    static let ashWednesday = CalendarHoliday(
        name: "Ash Wednesday",
        date: createDate(month: 3, day: 5, year: 2025),
        emoji: "✝️",
        description: "The first day of Lent in Western Christianity, marked by the placing of ashes.",
        unsplashSearchTerm: "ash wednesday",
        isRecurring: true,
        category: .religious
    )
    
    static let lentBegins = CalendarHoliday(
        name: "Lent Begins",
        date: createDate(month: 3, day: 5, year: 2025),
        emoji: "🙏",
        description: "The beginning of the 40-day period of fasting and prayer before Easter.",
        unsplashSearchTerm: "lent",
        isRecurring: true,
        category: .religious
    )
    
    static let epiphany = CalendarHoliday(
        name: "Epiphany",
        date: createDate(month: 1, day: 6, year: 2025),
        emoji: "⭐",
        description: "Christian feast day commemorating the visit of the Magi to the infant Jesus.",
        unsplashSearchTerm: "epiphany three kings",
        isRecurring: true,
        category: .religious
    )
    
    static let threeKingsDay = CalendarHoliday(
        name: "Three Kings Day",
        date: createDate(month: 1, day: 6, year: 2025),
        emoji: "👑",
        description: "Celebrating the visit of the three wise men to the baby Jesus.",
        unsplashSearchTerm: "three kings day",
        isRecurring: true,
        category: .religious
    )
    
    static let candlemas = CalendarHoliday(
        name: "Candlemas",
        date: createDate(month: 2, day: 2, year: 2025),
        emoji: "🕯️",
        description: "Christian feast day commemorating the presentation of Jesus at the Temple.",
        unsplashSearchTerm: "candlemas",
        isRecurring: true,
        category: .religious
    )
    
    static let allSaintsDay = CalendarHoliday(
        name: "All Saints' Day",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "👼",
        description: "Christian feast day honoring all saints, known and unknown.",
        unsplashSearchTerm: "all saints day",
        isRecurring: true,
        category: .religious
    )
    
    static let allSoulsDay = CalendarHoliday(
        name: "All Souls' Day",
        date: createDate(month: 11, day: 2, year: 2025),
        emoji: "🕯️",
        description: "Christian day of prayer and remembrance for the faithful departed.",
        unsplashSearchTerm: "all souls day",
        isRecurring: true,
        category: .religious
    )
    
    static let immaculateConception = CalendarHoliday(
        name: "Immaculate Conception",
        date: createDate(month: 12, day: 8, year: 2025),
        emoji: "⭐",
        description: "Catholic feast day celebrating the conception of the Virgin Mary without original sin.",
        unsplashSearchTerm: "immaculate conception",
        isRecurring: true,
        category: .religious
    )
    
    static let feastOfTheAssumption = CalendarHoliday(
        name: "Feast of the Assumption",
        date: createDate(month: 8, day: 15, year: 2025),
        emoji: "🙏",
        description: "Catholic feast day celebrating the assumption of Mary into heaven.",
        unsplashSearchTerm: "assumption of mary",
        isRecurring: true,
        category: .religious
    )
    
    static let firstSundayOfAdvent = CalendarHoliday(
        name: "First Sunday of Advent",
        date: createDate(month: 12, day: 1, year: 2024),
        emoji: "🕯️",
        description: "The beginning of the Advent season, a time of preparation for Christmas.",
        unsplashSearchTerm: "advent wreath",
        isRecurring: true,
        category: .religious
    )
    
    static let stNicholasDay = CalendarHoliday(
        name: "St. Nicholas Day",
        date: createDate(month: 12, day: 6, year: 2025),
        emoji: "🎁",
        description: "Christian feast day honoring St. Nicholas, a patron saint of children and gift-giving.",
        unsplashSearchTerm: "saint nicholas",
        isRecurring: true,
        category: .religious
    )
    
    static let stPatricksDay = CalendarHoliday(
        name: "St. Patrick's Day",
        date: createDate(month: 3, day: 17, year: 2025),
        emoji: "☘️",
        description: "Cultural and religious holiday celebrating Irish heritage and St. Patrick.",
        unsplashSearchTerm: "st patricks day parade",
        isRecurring: true,
        category: .religious
    )
    
    static let stValentinesDay = CalendarHoliday(
        name: "St. Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💌",
        description: "Originally a Christian feast day honoring St. Valentine, now celebrated as a day of love.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .religious
    )
    
    static let roshHashanah = CalendarHoliday(
        name: "Rosh Hashanah",
        date: createDate(month: 9, day: 25, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🍎",
        description: "Jewish New Year, a time of reflection and the beginning of the High Holy Days.",
        unsplashSearchTerm: "rosh hashanah",
        isRecurring: true,
        category: .religious
    )
    
    static let yomKippur = CalendarHoliday(
        name: "Yom Kippur",
        date: createDate(month: 10, day: 4, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🕯️",
        description: "The Day of Atonement, the holiest day in Judaism, marked by fasting and prayer.",
        unsplashSearchTerm: "yom kippur",
        isRecurring: true,
        category: .religious
    )
    
    static let hanukkah = CalendarHoliday(
        name: "Hanukkah",
        date: createDate(month: 12, day: 25, year: 2024), // Approximate start - varies by Hebrew calendar
        emoji: "🕎",
        description: "The Festival of Lights, an eight-day Jewish holiday celebrating the rededication of the Second Temple.",
        unsplashSearchTerm: "hanukkah menorah",
        isRecurring: true,
        category: .religious
    )
    
    static let passover = CalendarHoliday(
        name: "Passover",
        date: createDate(month: 4, day: 22, year: 2025), // Approximate start - varies by Hebrew calendar
        emoji: "🥖",
        description: "Jewish holiday commemorating the liberation of the Israelites from Egyptian slavery.",
        unsplashSearchTerm: "passover seder",
        isRecurring: true,
        category: .religious
    )
    
    static let purim = CalendarHoliday(
        name: "Purim",
        date: createDate(month: 3, day: 24, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🎭",
        description: "Jewish holiday commemorating the saving of the Jewish people from Haman.",
        unsplashSearchTerm: "purim celebration",
        isRecurring: true,
        category: .religious
    )
    
    static let sukkot = CalendarHoliday(
        name: "Sukkot",
        date: createDate(month: 10, day: 16, year: 2025), // Approximate start - varies by Hebrew calendar
        emoji: "🏕️",
        description: "Jewish harvest festival commemorating the 40 years Israelites spent in the desert.",
        unsplashSearchTerm: "sukkot sukkah",
        isRecurring: true,
        category: .religious
    )
    
    static let shavuot = CalendarHoliday(
        name: "Shavuot",
        date: createDate(month: 6, day: 12, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🌾",
        description: "Jewish holiday marking the giving of the Torah at Mount Sinai.",
        unsplashSearchTerm: "shavuot",
        isRecurring: true,
        category: .religious
    )
    
    static let diwali = CalendarHoliday(
        name: "Diwali",
        date: createDate(month: 11, day: 1, year: 2024), // Approximate - varies by Hindu calendar
        emoji: "🪔",
        description: "Hindu Festival of Lights, celebrating the victory of light over darkness.",
        unsplashSearchTerm: "diwali lights",
        isRecurring: true,
        category: .religious
    )
    
    // MARK: - Social/Cultural Holidays
    
    static let groundhogDay = CalendarHoliday(
        name: "Groundhog Day",
        date: createDate(month: 2, day: 2, year: 2025),
        emoji: "🐾",
        description: "A traditional holiday predicting the arrival of spring based on a groundhog's shadow.",
        unsplashSearchTerm: "groundhog day",
        isRecurring: true,
        category: .cultural
    )
    
    static let superBowlSunday = CalendarHoliday(
        name: "Super Bowl Sunday",
        date: createDate(month: 2, day: 9, year: 2025), // First Sunday in February
        emoji: "🏈",
        description: "The annual championship game of the National Football League.",
        unsplashSearchTerm: "super bowl",
        isRecurring: true,
        category: .cultural
    )
    
    static let valentinesDayAlternative = CalendarHoliday(
        name: "Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A day celebrating love and affection, often involving cards, flowers, and romantic gestures.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .cultural
    )
    
    static let presidentsDayAlternative = CalendarHoliday(
        name: "Presidents' Day",
        date: createDate(month: 2, day: 17, year: 2025),
        emoji: "🇺🇸",
        description: "Honoring all U.S. presidents, originally Washington's Birthday, now a federal holiday.",
        unsplashSearchTerm: "presidents day",
        isRecurring: true,
        category: .cultural
    )
    
    static let stPatricksDayCultural = CalendarHoliday(
        name: "St. Patrick's Day",
        date: createDate(month: 3, day: 17, year: 2025),
        emoji: "☘️",
        description: "Celebrating Irish heritage with parades, green attire, and festive celebrations.",
        unsplashSearchTerm: "st patricks day",
        isRecurring: true,
        category: .cultural
    )
    
    static let aprilFoolsDay = CalendarHoliday(
        name: "April Fool's Day",
        date: createDate(month: 4, day: 1, year: 2025),
        emoji: "😄",
        description: "A day for playing practical jokes and spreading hoaxes.",
        unsplashSearchTerm: "april fools day",
        isRecurring: true,
        category: .cultural
    )
    
    static let earthDay = CalendarHoliday(
        name: "Earth Day",
        date: createDate(month: 4, day: 22, year: 2025),
        emoji: "🌍",
        description: "A day to demonstrate support for environmental protection and sustainability.",
        unsplashSearchTerm: "earth day",
        isRecurring: true,
        category: .cultural
    )
    
    static let cincoDeMayo = CalendarHoliday(
        name: "Cinco de Mayo",
        date: createDate(month: 5, day: 5, year: 2025),
        emoji: "🎉",
        description: "Celebrating Mexican heritage and culture, commemorating the Battle of Puebla.",
        unsplashSearchTerm: "cinco de mayo",
        isRecurring: true,
        category: .cultural
    )
    
    static let kentuckyDerby = CalendarHoliday(
        name: "Kentucky Derby",
        date: createDate(month: 5, day: 3, year: 2025), // First Saturday in May
        emoji: "🐎",
        description: "The most famous horse race in America, known as 'The Run for the Roses.'",
        unsplashSearchTerm: "kentucky derby",
        isRecurring: true,
        category: .cultural
    )
    
    static let memorialDayWeekend = CalendarHoliday(
        name: "Memorial Day Weekend",
        date: createDate(month: 5, day: 24, year: 2025),
        emoji: "🏖️",
        description: "The unofficial start of summer, marked by barbecues and outdoor activities.",
        unsplashSearchTerm: "memorial day weekend",
        isRecurring: true,
        category: .cultural
    )
    
    static let fathersDayCultural = CalendarHoliday(
        name: "Father's Day",
        date: createDate(month: 6, day: 15, year: 2025),
        emoji: "👨‍👧‍👦",
        description: "A day to honor fathers and father figures with cards, gifts, and special activities.",
        unsplashSearchTerm: "fathers day",
        isRecurring: true,
        category: .cultural
    )
    
    static let canadaDay = CalendarHoliday(
        name: "Canada Day",
        date: createDate(month: 7, day: 1, year: 2025),
        emoji: "🍁",
        description: "Celebrating the anniversary of Canadian Confederation.",
        unsplashSearchTerm: "canada day",
        isRecurring: true,
        category: .cultural
    )
    
    static let independenceDayAlternative = CalendarHoliday(
        name: "Independence Day",
        date: createDate(month: 7, day: 4, year: 2025),
        emoji: "🎆",
        description: "Celebrating America's independence with fireworks, parades, and patriotic activities.",
        unsplashSearchTerm: "fourth of july",
        isRecurring: true,
        category: .cultural
    )
    
    static let bastilleDay = CalendarHoliday(
        name: "Bastille Day",
        date: createDate(month: 7, day: 14, year: 2025),
        emoji: "🇫🇷",
        description: "French National Day commemorating the Storming of the Bastille.",
        unsplashSearchTerm: "bastille day",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalHamburgerDay = CalendarHoliday(
        name: "National Hamburger Day",
        date: createDate(month: 5, day: 28, year: 2025),
        emoji: "🍔",
        description: "A day to celebrate one of America's favorite foods: the hamburger.",
        unsplashSearchTerm: "hamburger",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalIceCreamDay = CalendarHoliday(
        name: "National Ice Cream Day",
        date: createDate(month: 7, day: 20, year: 2025), // Third Sunday in July
        emoji: "🍦",
        description: "A day to enjoy and celebrate ice cream.",
        unsplashSearchTerm: "ice cream",
        isRecurring: true,
        category: .cultural
    )
    
    static let laborDayWeekend = CalendarHoliday(
        name: "Labor Day Weekend",
        date: createDate(month: 9, day: 1, year: 2025),
        emoji: "🏕️",
        description: "The unofficial end of summer, often celebrated with outdoor activities and barbecues.",
        unsplashSearchTerm: "labor day weekend",
        isRecurring: true,
        category: .cultural
    )
    
    static let grandparentsDay = CalendarHoliday(
        name: "Grandparents Day",
        date: createDate(month: 9, day: 7, year: 2025), // First Sunday after Labor Day
        emoji: "👴👵",
        description: "A day to honor grandparents and their contributions to families and society.",
        unsplashSearchTerm: "grandparents day",
        isRecurring: true,
        category: .cultural
    )
    
    static let roshHashanahCultural = CalendarHoliday(
        name: "Rosh Hashanah",
        date: createDate(month: 9, day: 25, year: 2025),
        emoji: "🍎",
        description: "Jewish New Year, celebrated with special meals and traditions.",
        unsplashSearchTerm: "rosh hashanah",
        isRecurring: true,
        category: .cultural
    )
    
    static let columbusDayCultural = CalendarHoliday(
        name: "Columbus Day",
        date: createDate(month: 10, day: 14, year: 2024),
        emoji: "🚢",
        description: "Observed in many states, commemorating Christopher Columbus's arrival in the Americas.",
        unsplashSearchTerm: "columbus day",
        isRecurring: true,
        category: .cultural
    )
    
    static let halloweenCultural = CalendarHoliday(
        name: "Halloween",
        date: createDate(month: 10, day: 31, year: 2024),
        emoji: "🎃",
        description: "A fun holiday involving costumes, trick-or-treating, and spooky decorations.",
        unsplashSearchTerm: "halloween",
        isRecurring: true,
        category: .cultural
    )
    
    static let dayOfTheDead = CalendarHoliday(
        name: "Day of the Dead",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "💀",
        description: "Mexican holiday honoring deceased loved ones with altars and celebrations.",
        unsplashSearchTerm: "day of the dead",
        isRecurring: true,
        category: .cultural
    )
    
    static let veteransDayCultural = CalendarHoliday(
        name: "Veterans Day",
        date: createDate(month: 11, day: 11, year: 2025),
        emoji: "🎖️",
        description: "Honoring all veterans who have served in the U.S. military.",
        unsplashSearchTerm: "veterans day",
        isRecurring: true,
        category: .cultural
    )
    
    static let thanksgivingCultural = CalendarHoliday(
        name: "Thanksgiving",
        date: createDate(month: 11, day: 28, year: 2024),
        emoji: "🦃",
        description: "A holiday celebrating gratitude and harvest, traditionally involving a feast with turkey and family gatherings.",
        unsplashSearchTerm: "thanksgiving",
        isRecurring: true,
        category: .cultural
    )
    
    static let blackFridayCultural = CalendarHoliday(
        name: "Black Friday",
        date: createDate(month: 11, day: 29, year: 2024),
        emoji: "🛍️",
        description: "The day after Thanksgiving, known for major shopping deals and the start of the holiday shopping season.",
        unsplashSearchTerm: "black friday",
        isRecurring: true,
        category: .cultural
    )
    
    static let cyberMonday = CalendarHoliday(
        name: "Cyber Monday",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "💻",
        description: "The Monday after Thanksgiving, known for online shopping deals.",
        unsplashSearchTerm: "cyber monday shopping",
        isRecurring: true,
        category: .cultural
    )
    
    static let hanukkahCultural = CalendarHoliday(
        name: "Hanukkah",
        date: createDate(month: 12, day: 25, year: 2024),
        emoji: "🕎",
        description: "The Festival of Lights, an eight-day Jewish holiday celebrating the rededication of the Second Temple.",
        unsplashSearchTerm: "hanukkah",
        isRecurring: true,
        category: .cultural
    )
    
    static let kwanzaa = CalendarHoliday(
        name: "Kwanzaa",
        date: createDate(month: 12, day: 26, year: 2025),
        emoji: "🕯️",
        description: "A week-long celebration honoring African American culture and heritage.",
        unsplashSearchTerm: "kwanzaa celebration",
        isRecurring: true,
        category: .cultural
    )
    
    static let newYearsEveCultural = CalendarHoliday(
        name: "New Year's Eve",
        date: createDate(month: 12, day: 31, year: 2024),
        emoji: "🎊",
        description: "The last day of the year, celebrated with parties and fireworks as people welcome the new year.",
        unsplashSearchTerm: "new years eve",
        isRecurring: true,
        category: .cultural
    )
    
    static let newYearsDayCultural = CalendarHoliday(
        name: "New Year's Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "🎉",
        description: "The first day of the new year, celebrated with resolutions, parades, and family gatherings.",
        unsplashSearchTerm: "new years day",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalPizzaDay = CalendarHoliday(
        name: "National Pizza Day",
        date: createDate(month: 2, day: 9, year: 2025),
        emoji: "🍕",
        description: "A day to celebrate one of America's favorite foods: pizza.",
        unsplashSearchTerm: "pizza",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalDonutDay = CalendarHoliday(
        name: "National Donut Day",
        date: createDate(month: 6, day: 7, year: 2025), // First Friday in June
        emoji: "🍩",
        description: "A day to enjoy and celebrate donuts, originally created to honor the Salvation Army.",
        unsplashSearchTerm: "donuts",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalCoffeeDay = CalendarHoliday(
        name: "National Coffee Day",
        date: createDate(month: 9, day: 29, year: 2025),
        emoji: "☕",
        description: "A day to celebrate coffee and its cultural significance.",
        unsplashSearchTerm: "coffee",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalTacoDay = CalendarHoliday(
        name: "National Taco Day",
        date: createDate(month: 10, day: 4, year: 2025),
        emoji: "🌮",
        description: "A day to celebrate tacos, one of the most beloved Mexican foods.",
        unsplashSearchTerm: "tacos",
        isRecurring: true,
        category: .cultural
    )
    
    static let chineseNewYear = CalendarHoliday(
        name: "Chinese New Year",
        date: createDate(month: 1, day: 29, year: 2025), // Approximate - varies by lunar calendar
        emoji: "🧧",
        description: "The most important Chinese festival, marking the beginning of the lunar new year.",
        unsplashSearchTerm: "chinese new year",
        isRecurring: true,
        category: .cultural
    )
    
    static let valentinesDayWeek = CalendarHoliday(
        name: "Valentine's Day Week",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A week-long celebration leading up to Valentine's Day.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .cultural
    )
    
    static let summerSolstice = CalendarHoliday(
        name: "Summer Solstice",
        date: createDate(month: 6, day: 21, year: 2025),
        emoji: "☀️",
        description: "The longest day of the year and the official start of summer in the Northern Hemisphere.",
        unsplashSearchTerm: "summer solstice",
        isRecurring: true,
        category: .seasonal
    )
    
    static let winterSolstice = CalendarHoliday(
        name: "Winter Solstice",
        date: createDate(month: 12, day: 21, year: 2025),
        emoji: "❄️",
        description: "The shortest day of the year and the official start of winter in the Northern Hemisphere.",
        unsplashSearchTerm: "winter solstice",
        isRecurring: true,
        category: .seasonal
    )
    
    static let autumnalEquinox = CalendarHoliday(
        name: "First Day of Fall",
        date: createDate(month: 9, day: 22, year: 2025),
        emoji: "🍂",
        description: "The autumnal equinox, marking the beginning of fall and shorter days.",
        unsplashSearchTerm: "autumn fall",
        isRecurring: true,
        category: .seasonal
    )
    
    static let vernalEquinox = CalendarHoliday(
        name: "First Day of Spring",
        date: createDate(month: 3, day: 20, year: 2025),
        emoji: "🌸",
        description: "The vernal equinox, marking the beginning of spring and longer days.",
        unsplashSearchTerm: "spring",
        isRecurring: true,
        category: .seasonal
    )
    
    // MARK: - Educational Holidays
    
    static let piDayEducational = CalendarHoliday(
        name: "Pi Day",
        date: createDate(month: 3, day: 14, year: 2025),
        emoji: "🥧",
        description: "Celebrating the mathematical constant π (pi), often with pie-eating and math activities.",
        unsplashSearchTerm: "pi day",
        isRecurring: true,
        category: .educational
    )
    
    static let teachersDay = CalendarHoliday(
        name: "Teacher Appreciation Day",
        date: createDate(month: 5, day: 6, year: 2025), // First Tuesday of first full week in May
        emoji: "👩‍🏫",
        description: "A day to honor teachers and their contributions to education.",
        unsplashSearchTerm: "teacher appreciation",
        isRecurring: true,
        category: .educational
    )
    
    static let bookLoversDay = CalendarHoliday(
        name: "Book Lovers Day",
        date: createDate(month: 8, day: 9, year: 2025),
        emoji: "📚",
        description: "A day to celebrate books and reading.",
        unsplashSearchTerm: "books reading",
        isRecurring: true,
        category: .educational
    )
    
    // MARK: - Additional Holidays
    
    static let inaugurationDay = CalendarHoliday(
        name: "Inauguration Day",
        date: createDate(month: 1, day: 20, year: 2025), // Every 4 years
        emoji: "🏛️",
        description: "The day the President of the United States is inaugurated, held every four years.",
        unsplashSearchTerm: "inauguration day",
        isRecurring: true,
        category: .national
    )
    
    static let leapDay = CalendarHoliday(
        name: "Leap Day",
        date: createDate(month: 2, day: 29, year: 2024),
        emoji: "🐸",
        description: "An extra day added to the calendar every four years to keep it synchronized with the seasons.",
        unsplashSearchTerm: "leap day",
        isRecurring: false,
        category: .cultural
    )
    
    static let daylightSavingTimeStarts = CalendarHoliday(
        name: "Daylight Saving Time Begins",
        date: createDate(month: 3, day: 9, year: 2025), // Second Sunday in March
        emoji: "⏰",
        description: "The day clocks spring forward one hour, marking the start of daylight saving time.",
        unsplashSearchTerm: "daylight saving time",
        isRecurring: true,
        category: .national
    )
    
    static let daylightSavingTimeEnds = CalendarHoliday(
        name: "Daylight Saving Time Ends",
        date: createDate(month: 11, day: 2, year: 2025), // First Sunday in November
        emoji: "⏰",
        description: "The day clocks fall back one hour, marking the end of daylight saving time.",
        unsplashSearchTerm: "daylight saving time",
        isRecurring: true,
        category: .national
    )
    
    static let taxDay = CalendarHoliday(
        name: "Tax Day",
        date: createDate(month: 4, day: 15, year: 2025),
        emoji: "📋",
        description: "The deadline for filing federal income tax returns in the United States.",
        unsplashSearchTerm: "tax day",
        isRecurring: true,
        category: .national
    )
    
    static let nationalPetDay = CalendarHoliday(
        name: "National Pet Day",
        date: createDate(month: 4, day: 11, year: 2025),
        emoji: "🐾",
        description: "A day to celebrate pets and the joy they bring to our lives.",
        unsplashSearchTerm: "pet day",
        isRecurring: true,
        category: .cultural
    )
    
    static let mayDay = CalendarHoliday(
        name: "May Day",
        date: createDate(month: 5, day: 1, year: 2025),
        emoji: "🌺",
        description: "A spring festival and celebration of workers' rights, also known as International Workers' Day.",
        unsplashSearchTerm: "may day",
        isRecurring: true,
        category: .cultural
    )
    
    static let starWarsDay = CalendarHoliday(
        name: "Star Wars Day",
        date: createDate(month: 5, day: 4, year: 2025),
        emoji: "⭐",
        description: "Celebrating the Star Wars franchise with the catchphrase 'May the Fourth be with you.'",
        unsplashSearchTerm: "star wars",
        isRecurring: true,
        category: .cultural
    )
    
    static let mothersDayWeekend = CalendarHoliday(
        name: "Mother's Day Weekend",
        date: createDate(month: 5, day: 10, year: 2025),
        emoji: "💐",
        description: "The weekend celebrating mothers and mother figures.",
        unsplashSearchTerm: "mothers day",
        isRecurring: true,
        category: .cultural
    )
    
    static let armedForcesDay = CalendarHoliday(
        name: "Armed Forces Day",
        date: createDate(month: 5, day: 17, year: 2025), // Third Saturday in May
        emoji: "🎖️",
        description: "Honoring all branches of the United States Armed Forces.",
        unsplashSearchTerm: "armed forces day",
        isRecurring: true,
        category: .national
    )
    
    static let emancipationProclamationDay = CalendarHoliday(
        name: "Emancipation Proclamation Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "📜",
        description: "Commemorating the day President Lincoln issued the Emancipation Proclamation in 1863.",
        unsplashSearchTerm: "emancipation proclamation",
        isRecurring: true,
        category: .national
    )
    
    static let rosaParksDay = CalendarHoliday(
        name: "Rosa Parks Day",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "🚌",
        description: "Honoring Rosa Parks and her role in the Civil Rights Movement.",
        unsplashSearchTerm: "rosa parks",
        isRecurring: true,
        category: .national
    )
    
    static let billOfRightsDay = CalendarHoliday(
        name: "Bill of Rights Day",
        date: createDate(month: 12, day: 15, year: 2025),
        emoji: "📜",
        description: "Commemorating the ratification of the Bill of Rights, the first ten amendments to the Constitution.",
        unsplashSearchTerm: "bill of rights",
        isRecurring: true,
        category: .national
    )
    
    static let wrightBrothersDay = CalendarHoliday(
        name: "Wright Brothers Day",
        date: createDate(month: 12, day: 17, year: 2025),
        emoji: "✈️",
        description: "Commemorating the first successful powered flight by the Wright brothers in 1903.",
        unsplashSearchTerm: "wright brothers",
        isRecurring: true,
        category: .national
    )
    
    static let nationalFriendshipDay = CalendarHoliday(
        name: "National Friendship Day",
        date: createDate(month: 8, day: 3, year: 2025), // First Sunday in August
        emoji: "🤝",
        description: "A day to celebrate friendships and the bonds between friends.",
        unsplashSearchTerm: "friendship day",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalSiblingsDay = CalendarHoliday(
        name: "National Siblings Day",
        date: createDate(month: 4, day: 10, year: 2025),
        emoji: "👨‍👩‍👧‍👦",
        description: "A day to honor and celebrate the bond between siblings.",
        unsplashSearchTerm: "siblings day",
        isRecurring: true,
        category: .cultural
    )
    
    static let nationalWomensDay = CalendarHoliday(
        name: "National Women's Day",
        date: createDate(month: 3, day: 8, year: 2025),
        emoji: "👩",
        description: "Celebrating the achievements and contributions of women throughout history.",
        unsplashSearchTerm: "womens day",
        isRecurring: true,
        category: .cultural
    )
    
    static let stGeorgesDay = CalendarHoliday(
        name: "St. George's Day",
        date: createDate(month: 4, day: 23, year: 2025),
        emoji: "⚔️",
        description: "Christian feast day honoring St. George, the patron saint of England.",
        unsplashSearchTerm: "saint george",
        isRecurring: true,
        category: .religious
    )
    
    static let walpurgisNight = CalendarHoliday(
        name: "Walpurgis Night",
        date: createDate(month: 4, day: 30, year: 2025),
        emoji: "🔥",
        description: "A European spring festival celebrated on the eve of May Day.",
        unsplashSearchTerm: "walpurgis night",
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
}
