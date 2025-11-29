//
//  Holiday.swift
//  Calendar Play
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

    enum CalendarHolidayCategory: String, CaseIterable, Codable {
        case bankHolidays = "Bank Holidays"
        case uniqueHolidays = "Unique Holidays"
        case awarenessDays = "Awareness Days"
        case seasons = "Seasons"
        case christianHolidays = "Christian Holidays"
        case jewishHolidays = "Jewish Holidays"
        case otherHolidays = "Other Holidays"
        
        var displayName: String {
            return self.rawValue
        }
    }

    /// Check if this holiday occurs on the given date
    func occursOn(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
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
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: thanksgiving)
                }
                return nil
            case "Cyber Monday":
                if let thanksgiving = thanksgivingDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 4, to: thanksgiving)
                }
                return nil
            case "Martin Luther King Jr. Day":
                return nthWeekdayOfMonth(year: year, month: 1, weekday: .monday, n: 3)
            case "Presidents' Day", "Washington's Birthday":
                return nthWeekdayOfMonth(year: year, month: 2, weekday: .monday, n: 3)
            case "Indigenous Peoples' Day":
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
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -2, to: easter)
                }
                return nil
            case "Palm Sunday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: easter)
                }
                return nil
            case "Maundy Thursday", "Holy Thursday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -3, to: easter)
                }
                return nil
            case "Holy Saturday", "Easter Saturday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: easter)
                }
                return nil
            case "Easter Monday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: easter)
                }
                return nil
            case "Ascension Day":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 39, to: easter)
                }
                return nil
            case "Pentecost", "Whitsunday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 49, to: easter)
                }
                return nil
            case "Whit Monday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 50, to: easter)
                }
                return nil
            case "Trinity Sunday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 56, to: easter)
                }
                return nil
            case "Corpus Christi":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 60, to: easter)
                }
                return nil
            case "Mardi Gras", "Fat Tuesday", "Shrove Tuesday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -47, to: easter)
                }
                return nil
            case "Ash Wednesday":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -46, to: easter)
                }
                return nil
            case "Lent Begins":
                if let easter = easterDate(for: year) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -46, to: easter)
                }
                return nil
            case "First Sunday of Advent":
                // Sunday closest to November 30
                var components = DateComponents()
                components.year = year
                components.month = 11
                components.day = 30
                if let nov30 = Calendar(identifier: .gregorian).date(from: components) {
                    let weekday = Calendar(identifier: .gregorian).component(.weekday, from: nov30)
                    let daysToSubtract = (weekday - Weekday.sunday.rawValue + 7) % 7
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -daysToSubtract, to: nov30)
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
                    let weekday = Calendar(identifier: .gregorian).component(.weekday, from: laborDay)
                    let daysToSunday = (Weekday.sunday.rawValue - weekday + 7) % 7
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: daysToSunday, to: laborDay)
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
                    if let jan20 = Calendar(identifier: .gregorian).date(from: components) {
                        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: jan20)
                        // If January 20 is a Sunday, move to Monday
                        if weekday == Weekday.sunday.rawValue {
                            return Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: jan20)
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
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: firstMonday)
                }
                return nil
            case "Teacher Appreciation Day":
                // First Tuesday of first full week in May (effectively first Tuesday)
                return nthWeekdayOfMonth(year: year, month: 5, weekday: .tuesday, n: 1)
            case "Mother's Day Weekend":
                // The Saturday before Mother's Day
                if let mothersDay = nthWeekdayOfMonth(year: year, month: 5, weekday: .sunday, n: 2) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: mothersDay)
                }
                return nil
            case "Memorial Day Weekend":
                // The Saturday before Memorial Day (last Monday of May)
                if let memorialDay = lastWeekdayOfMonth(year: year, month: 5, weekday: .monday) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -2, to: memorialDay)
                }
                return nil
            case "Labor Day Weekend":
                // The Saturday before Labor Day (first Monday of September)
                if let laborDay = nthWeekdayOfMonth(year: year, month: 9, weekday: .monday, n: 1) {
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: -2, to: laborDay)
                }
                return nil
            case "Earth Hour":
                // Last Saturday of March
                return lastWeekdayOfMonth(year: year, month: 3, weekday: .saturday)
            case "National Ice Cream for Breakfast Day":
                // First Saturday in February
                return nthWeekdayOfMonth(year: year, month: 2, weekday: .saturday, n: 1)
            case "National Parks Day":
                // Fourth Saturday in April
                return nthWeekdayOfMonth(year: year, month: 4, weekday: .saturday, n: 4)
            case "Batman Day":
                // Third Saturday in September
                return nthWeekdayOfMonth(year: year, month: 9, weekday: .saturday, n: 3)
            case "World Smile Day":
                // First Friday in October
                return nthWeekdayOfMonth(year: year, month: 10, weekday: .friday, n: 1)
            case "National Bring Your Pet to Work Day":
                // Friday after Father's Day (third Sunday in June)
                if let fathersDay = nthWeekdayOfMonth(year: year, month: 6, weekday: .sunday, n: 3) {
                    // Find the following Friday
                    let weekday = Calendar(identifier: .gregorian).component(.weekday, from: fathersDay)
                    let daysToFriday = (Weekday.friday.rawValue - weekday + 7) % 7
                    if daysToFriday == 0 {
                        return Calendar(identifier: .gregorian).date(byAdding: .day, value: 5, to: fathersDay)
                    }
                    return Calendar(identifier: .gregorian).date(byAdding: .day, value: daysToFriday, to: fathersDay)
                }
                return nil
            default:
                // For other recurring holidays, use the stored date but update the year
                let calendar = Calendar(identifier: .gregorian)
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
        return Calendar(identifier: .gregorian).date(from: components)
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
        return Calendar(identifier: .gregorian).date(from: components)
    }

    /// Find the nth weekday of a given month and year
    private func nthWeekdayOfMonth(year: Int, month: Int, weekday: Weekday, n: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)

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
        let calendar = Calendar(identifier: .gregorian)

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
    
    /// Calculate approximate new moon date for a given year
    /// Uses a simplified calculation based on known new moon dates
    private func newMoonDate(for year: Int) -> Date? {
        // Known new moon: January 11, 2024 at 11:57 UTC
        // Lunar cycle is approximately 29.53 days
        let referenceDate = createDateForYear(month: 1, day: 11, year: 2024)
        guard let refDate = referenceDate else { return nil }
        
        let calendar = Calendar(identifier: .gregorian)
        let targetYearStart = createDateForYear(month: 1, day: 1, year: year)
        guard let yearStart = targetYearStart else { return nil }
        
        // Calculate days from reference date to start of target year
        let daysDiff = calendar.dateComponents([.day], from: refDate, to: yearStart).day ?? 0
        
        // Calculate approximate new moon cycles passed
        let lunarCycleDays = 29.53058867
        let cycles = Double(daysDiff) / lunarCycleDays
        let cyclesPassed = Int(cycles)
        let remainingDays = cycles - Double(cyclesPassed)
        
        // Find the first new moon of the year (approximately)
        let approximateDays = Int(remainingDays * lunarCycleDays)
        if let firstNewMoon = calendar.date(byAdding: .day, value: approximateDays, to: yearStart) {
            // Adjust to get closer to actual new moon (this is an approximation)
            return firstNewMoon
        }
        
        // Fallback: approximate new moon dates (roughly every 29.5 days)
        // January new moon approximation
        return createDateForYear(month: 1, day: 11, year: year)
    }
    
    /// Calculate approximate full moon date for a given year
    private func fullMoonDate(for year: Int) -> Date? {
        // Full moon is approximately 14.77 days after new moon
        if let newMoon = newMoonDate(for: year) {
            return Calendar(identifier: .gregorian).date(byAdding: .day, value: 15, to: newMoon)
        }
        // Fallback approximation
        return createDateForYear(month: 1, day: 25, year: year)
    }
    
    /// Calculate blue moon date (when there are two full moons in a month)
    /// This is rare and occurs roughly every 2-3 years
    private func blueMoonDate(for year: Int) -> Date? {
        // Blue moons are rare - this is a simplified check
        // Actual blue moons need proper astronomical calculation
        // Known blue moons: August 31, 2023; May 31, 2026
        
        // Approximate check: blue moons often occur in months with 31 days
        // This is a very simplified approximation
        let knownBlueMoons: [Int: (month: Int, day: Int)] = [
            2024: (8, 19),
            2026: (5, 31),
            2028: (12, 31),
            2031: (9, 30)
        ]
        
        if let blueMoon = knownBlueMoons[year] {
            return createDateForYear(month: blueMoon.month, day: blueMoon.day, year: year)
        }
        
        // Return nil if not a known blue moon year (most years won't have one)
        return nil
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
        category: .bankHolidays
    )

    static let blackFriday = CalendarHoliday(
        name: "Black Friday",
        date: createDate(month: 11, day: 29, year: 2024),
        emoji: "🛍️",
        description: "The day after Thanksgiving, known for major shopping deals and the start of the holiday shopping season.",
        unsplashSearchTerm: "black friday shopping",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let christmasEve = CalendarHoliday(
        name: "Christmas Eve",
        date: createDate(month: 12, day: 24, year: 2024),
        emoji: "🎄",
        description: "The evening before Christmas Day, often celebrated with family gatherings and preparations for Christmas.",
        unsplashSearchTerm: "christmas eve",
        isRecurring: true,
        category: .christianHolidays
    )

    static let christmasDay = CalendarHoliday(
        name: "Christmas Day",
        date: createDate(month: 12, day: 25, year: 2024),
        emoji: "🎅",
        description: "A Christian holiday celebrating the birth of Jesus Christ, celebrated with gift-giving and family time.",
        unsplashSearchTerm: "christmas morning",
        isRecurring: true,
        category: .bankHolidays
    )

    static let boxingDay = CalendarHoliday(
        name: "Boxing Day",
        date: createDate(month: 12, day: 26, year: 2024),
        emoji: "📦",
        description: "Celebrated in many countries, traditionally a day for giving gifts to those who have helped throughout the year.",
        unsplashSearchTerm: "boxing day",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let newYearsEve = CalendarHoliday(
        name: "New Year's Eve",
        date: createDate(month: 12, day: 31, year: 2024),
        emoji: "🎊",
        description: "The last day of the year, celebrated with parties and fireworks as people welcome the new year.",
        unsplashSearchTerm: "new years eve celebration",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let newYearsDay = CalendarHoliday(
        name: "New Year's Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "🎉",
        description: "The first day of the new year, celebrated with resolutions, parades, and family gatherings.",
        unsplashSearchTerm: "new years day",
        isRecurring: true,
        category: .bankHolidays
    )

    static let martinLutherKingJrDay = CalendarHoliday(
        name: "Martin Luther King Jr. Day",
        date: createDate(month: 1, day: 20, year: 2025), // Third Monday of January
        emoji: "✊",
        description: "Honoring Dr. Martin Luther King Jr., celebrating his legacy of civil rights and equality.",
        unsplashSearchTerm: "martin luther king jr memorial",
        isRecurring: true,
        category: .bankHolidays
    )

    static let valentinesDay = CalendarHoliday(
        name: "Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A day celebrating love and affection, often involving cards, flowers, and romantic gestures.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let presidentsDay = CalendarHoliday(
        name: "Presidents' Day",
        date: createDate(month: 2, day: 17, year: 2025), // Third Monday of February
        emoji: "🇺🇸",
        description: "Honoring all U.S. presidents, originally Washington's Birthday, now a federal holiday.",
        unsplashSearchTerm: "presidents day",
        isRecurring: true,
        category: .bankHolidays
    )

    static let indigenousPeoplesDay = CalendarHoliday(
        name: "Indigenous Peoples' Day",
        date: createDate(month: 10, day: 14, year: 2024), // Second Monday of October
        emoji: "🪶",
        description: "Celebrating the history, culture, and resilience of Indigenous peoples of the Americas.",
        unsplashSearchTerm: "indigenous peoples day",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let piDay = CalendarHoliday(
        name: "Pi Day",
        date: createDate(month: 3, day: 14, year: 2025),
        emoji: "🥧",
        description: "Celebrating the mathematical constant π (pi), often with pie-eating and math activities.",
        unsplashSearchTerm: "pi day celebration",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let firstDayOfSpring = CalendarHoliday(
        name: "First Day of Spring",
        date: createDate(month: 3, day: 20, year: 2025), // Vernal equinox
        emoji: "🌸",
        description: "The vernal equinox, marking the beginning of spring and longer days.",
        unsplashSearchTerm: "spring flowers blooming",
        isRecurring: true,
        category: .seasons
    )

    static let firstDayOfSummer = CalendarHoliday(
        name: "First Day of Summer",
        date: createDate(month: 6, day: 21, year: 2025), // Summer solstice
        emoji: "☀️",
        description: "The summer solstice, the longest day of the year and beginning of summer.",
        unsplashSearchTerm: "summer solstice",
        isRecurring: true,
        category: .seasons
    )

    static let fourthOfJuly = CalendarHoliday(
        name: "Independence Day",
        date: createDate(month: 7, day: 4, year: 2025),
        emoji: "🎆",
        description: "Celebrating America's independence with fireworks, parades, and patriotic activities.",
        unsplashSearchTerm: "fourth of july fireworks",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let memorialDay = CalendarHoliday(
        name: "Memorial Day",
        date: createDate(month: 5, day: 26, year: 2025), // Last Monday of May
        emoji: "🇺🇸",
        description: "Honoring those who died serving in the U.S. military, traditionally the start of summer.",
        unsplashSearchTerm: "memorial day parade",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let veteransDay = CalendarHoliday(
        name: "Veterans Day",
        date: createDate(month: 11, day: 11, year: 2025),
        emoji: "🎖️",
        description: "Honoring all veterans who have served in the U.S. military.",
        unsplashSearchTerm: "veterans day memorial",
        isRecurring: true,
        category: .bankHolidays
    )

    static let halloween = CalendarHoliday(
        name: "Halloween",
        date: createDate(month: 10, day: 31, year: 2024),
        emoji: "🎃",
        description: "A fun holiday involving costumes, trick-or-treating, and spooky decorations.",
        unsplashSearchTerm: "halloween pumpkin",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let easter = CalendarHoliday(
        name: "Easter",
        date: createDate(month: 4, day: 20, year: 2025), // Calculated based on lunar calendar
        emoji: "🐣",
        description: "Christian holiday celebrating the resurrection of Jesus Christ, with egg hunts and spring themes.",
        unsplashSearchTerm: "easter eggs",
        isRecurring: true,
        category: .christianHolidays
    )

    static let mothersDay = CalendarHoliday(
        name: "Mother's Day",
        date: createDate(month: 5, day: 11, year: 2025), // Second Sunday of May
        emoji: "👩‍👧‍👦",
        description: "A day to honor mothers and mother figures with cards, flowers, and special activities.",
        unsplashSearchTerm: "mothers day flowers",
        isRecurring: true,
        category: .uniqueHolidays
    )

    static let fathersDay = CalendarHoliday(
        name: "Father's Day",
        date: createDate(month: 6, day: 15, year: 2025), // Third Sunday of June
        emoji: "👨‍👧‍👦",
        description: "A day to honor fathers and father figures with cards, gifts, and special activities.",
        unsplashSearchTerm: "fathers day grill",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Government/Banking Holidays (National)
    
    static let laborDay = CalendarHoliday(
        name: "Labor Day",
        date: createDate(month: 9, day: 1, year: 2025), // First Monday of September
        emoji: "🔨",
        description: "Honoring the contributions of American workers and the labor movement.",
        unsplashSearchTerm: "labor day parade",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let patriotDay = CalendarHoliday(
        name: "Patriot Day",
        date: createDate(month: 9, day: 11, year: 2025),
        emoji: "🇺🇸",
        description: "Remembering the victims of the September 11, 2001 terrorist attacks.",
        unsplashSearchTerm: "patriot day memorial",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let electionDay = CalendarHoliday(
        name: "Election Day",
        date: createDate(month: 11, day: 4, year: 2025), // First Tuesday after first Monday in November
        emoji: "🗳️",
        description: "Election Day for federal offices, held on the first Tuesday after the first Monday in November.",
        unsplashSearchTerm: "election day voting",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let juneteenth = CalendarHoliday(
        name: "Juneteenth",
        date: createDate(month: 6, day: 19, year: 2025),
        emoji: "🎉",
        description: "Commemorating the emancipation of enslaved African Americans in the United States.",
        unsplashSearchTerm: "juneteenth celebration",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let washingtonsBirthday = CalendarHoliday(
        name: "Washington's Birthday",
        date: createDate(month: 2, day: 22, year: 2025),
        emoji: "🇺🇸",
        description: "Honoring the first president of the United States, George Washington.",
        unsplashSearchTerm: "george washington",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let lincolnsBirthday = CalendarHoliday(
        name: "Lincoln's Birthday",
        date: createDate(month: 2, day: 12, year: 2025),
        emoji: "🇺🇸",
        description: "Commemorating the birth of Abraham Lincoln, the 16th president of the United States.",
        unsplashSearchTerm: "abraham lincoln",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let flagDay = CalendarHoliday(
        name: "Flag Day",
        date: createDate(month: 6, day: 14, year: 2025),
        emoji: "🇺🇸",
        description: "Commemorating the adoption of the flag of the United States on June 14, 1777.",
        unsplashSearchTerm: "american flag",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let constitutionDay = CalendarHoliday(
        name: "Constitution Day",
        date: createDate(month: 9, day: 17, year: 2025),
        emoji: "📜",
        description: "Commemorating the signing of the United States Constitution on September 17, 1787.",
        unsplashSearchTerm: "constitution day",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let pearlHarborDay = CalendarHoliday(
        name: "Pearl Harbor Remembrance Day",
        date: createDate(month: 12, day: 7, year: 2025),
        emoji: "⚓",
        description: "Commemorating the attack on Pearl Harbor on December 7, 1941.",
        unsplashSearchTerm: "pearl harbor memorial",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let arborDay = CalendarHoliday(
        name: "Arbor Day",
        date: createDate(month: 4, day: 26, year: 2025), // Last Friday of April
        emoji: "🌳",
        description: "A holiday encouraging tree planting and environmental awareness.",
        unsplashSearchTerm: "tree planting",
        isRecurring: true,
        category: .bankHolidays
    )
    
    // MARK: - Religious Holidays
    
    static let goodFriday = CalendarHoliday(
        name: "Good Friday",
        date: createDate(month: 4, day: 18, year: 2025),
        emoji: "✝️",
        description: "Christian holiday commemorating the crucifixion of Jesus Christ.",
        unsplashSearchTerm: "good friday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let palmSunday = CalendarHoliday(
        name: "Palm Sunday",
        date: createDate(month: 4, day: 13, year: 2025),
        emoji: "🌴",
        description: "Christian holiday marking the beginning of Holy Week, commemorating Jesus's entry into Jerusalem.",
        unsplashSearchTerm: "palm sunday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let maundyThursday = CalendarHoliday(
        name: "Maundy Thursday",
        date: createDate(month: 4, day: 17, year: 2025),
        emoji: "🍞",
        description: "Christian holiday commemorating the Last Supper of Jesus Christ with the Apostles.",
        unsplashSearchTerm: "last supper",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let holySaturday = CalendarHoliday(
        name: "Holy Saturday",
        date: createDate(month: 4, day: 19, year: 2025),
        emoji: "🕊️",
        description: "The day before Easter Sunday, commemorating the day Jesus's body lay in the tomb.",
        unsplashSearchTerm: "holy saturday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let easterMonday = CalendarHoliday(
        name: "Easter Monday",
        date: createDate(month: 4, day: 21, year: 2025),
        emoji: "🐰",
        description: "The day after Easter Sunday, a continuation of the Easter celebration.",
        unsplashSearchTerm: "easter monday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let ascensionDay = CalendarHoliday(
        name: "Ascension Day",
        date: createDate(month: 5, day: 29, year: 2025),
        emoji: "☁️",
        description: "Christian holiday commemorating the ascension of Jesus Christ into heaven.",
        unsplashSearchTerm: "ascension day",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let pentecost = CalendarHoliday(
        name: "Pentecost",
        date: createDate(month: 6, day: 8, year: 2025),
        emoji: "🔥",
        description: "Christian holiday commemorating the descent of the Holy Spirit upon the Apostles.",
        unsplashSearchTerm: "pentecost",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let whitMonday = CalendarHoliday(
        name: "Whit Monday",
        date: createDate(month: 6, day: 9, year: 2025),
        emoji: "🕊️",
        description: "The day after Pentecost, also known as Monday of the Holy Spirit.",
        unsplashSearchTerm: "whit monday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let trinitySunday = CalendarHoliday(
        name: "Trinity Sunday",
        date: createDate(month: 6, day: 15, year: 2025),
        emoji: "☦️",
        description: "Christian feast day honoring the Holy Trinity: the Father, the Son, and the Holy Spirit.",
        unsplashSearchTerm: "trinity sunday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let corpusChristi = CalendarHoliday(
        name: "Corpus Christi",
        date: createDate(month: 6, day: 19, year: 2025),
        emoji: "⛪",
        description: "Christian feast day honoring the Eucharist and the body of Christ.",
        unsplashSearchTerm: "corpus christi",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let mardiGras = CalendarHoliday(
        name: "Mardi Gras",
        date: createDate(month: 3, day: 4, year: 2025),
        emoji: "🎭",
        description: "Fat Tuesday, the last day of Carnival before Lent begins.",
        unsplashSearchTerm: "mardi gras celebration",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let ashWednesday = CalendarHoliday(
        name: "Ash Wednesday",
        date: createDate(month: 3, day: 5, year: 2025),
        emoji: "✝️",
        description: "The first day of Lent in Western Christianity, marked by the placing of ashes.",
        unsplashSearchTerm: "ash wednesday",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let lentBegins = CalendarHoliday(
        name: "Lent Begins",
        date: createDate(month: 3, day: 5, year: 2025),
        emoji: "🙏",
        description: "The beginning of the 40-day period of fasting and prayer before Easter.",
        unsplashSearchTerm: "lent",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let epiphany = CalendarHoliday(
        name: "Epiphany",
        date: createDate(month: 1, day: 6, year: 2025),
        emoji: "⭐",
        description: "Christian feast day commemorating the visit of the Magi to the infant Jesus.",
        unsplashSearchTerm: "epiphany three kings",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let threeKingsDay = CalendarHoliday(
        name: "Three Kings Day",
        date: createDate(month: 1, day: 6, year: 2025),
        emoji: "👑",
        description: "Celebrating the visit of the three wise men to the baby Jesus.",
        unsplashSearchTerm: "three kings day",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let candlemas = CalendarHoliday(
        name: "Candlemas",
        date: createDate(month: 2, day: 2, year: 2025),
        emoji: "🕯️",
        description: "Christian feast day commemorating the presentation of Jesus at the Temple.",
        unsplashSearchTerm: "candlemas",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let allSaintsDay = CalendarHoliday(
        name: "All Saints' Day",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "👼",
        description: "Christian feast day honoring all saints, known and unknown.",
        unsplashSearchTerm: "all saints day",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let allSoulsDay = CalendarHoliday(
        name: "All Souls' Day",
        date: createDate(month: 11, day: 2, year: 2025),
        emoji: "🕯️",
        description: "Christian day of prayer and remembrance for the faithful departed.",
        unsplashSearchTerm: "all souls day",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let immaculateConception = CalendarHoliday(
        name: "Immaculate Conception",
        date: createDate(month: 12, day: 8, year: 2025),
        emoji: "⭐",
        description: "Catholic feast day celebrating the conception of the Virgin Mary without original sin.",
        unsplashSearchTerm: "immaculate conception",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let feastOfTheAssumption = CalendarHoliday(
        name: "Feast of the Assumption",
        date: createDate(month: 8, day: 15, year: 2025),
        emoji: "🙏",
        description: "Catholic feast day celebrating the assumption of Mary into heaven.",
        unsplashSearchTerm: "assumption of mary",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let firstSundayOfAdvent = CalendarHoliday(
        name: "First Sunday of Advent",
        date: createDate(month: 12, day: 1, year: 2024),
        emoji: "🕯️",
        description: "The beginning of the Advent season, a time of preparation for Christmas.",
        unsplashSearchTerm: "advent wreath",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let stNicholasDay = CalendarHoliday(
        name: "St. Nicholas Day",
        date: createDate(month: 12, day: 6, year: 2025),
        emoji: "🎁",
        description: "Christian feast day honoring St. Nicholas, a patron saint of children and gift-giving.",
        unsplashSearchTerm: "saint nicholas",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let stPatricksDay = CalendarHoliday(
        name: "St. Patrick's Day",
        date: createDate(month: 3, day: 17, year: 2025),
        emoji: "☘️",
        description: "Cultural and religious holiday celebrating Irish heritage and St. Patrick.",
        unsplashSearchTerm: "st patricks day parade",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let stValentinesDay = CalendarHoliday(
        name: "St. Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💌",
        description: "Originally a Christian feast day honoring St. Valentine, now celebrated as a day of love.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let roshHashanah = CalendarHoliday(
        name: "Rosh Hashanah",
        date: createDate(month: 9, day: 25, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🍎",
        description: "Jewish New Year, a time of reflection and the beginning of the High Holy Days.",
        unsplashSearchTerm: "rosh hashanah",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let yomKippur = CalendarHoliday(
        name: "Yom Kippur",
        date: createDate(month: 10, day: 4, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🕯️",
        description: "The Day of Atonement, the holiest day in Judaism, marked by fasting and prayer.",
        unsplashSearchTerm: "yom kippur",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let hanukkah = CalendarHoliday(
        name: "Hanukkah",
        date: createDate(month: 12, day: 25, year: 2024), // Approximate start - varies by Hebrew calendar
        emoji: "🕎",
        description: "The Festival of Lights, an eight-day Jewish holiday celebrating the rededication of the Second Temple.",
        unsplashSearchTerm: "hanukkah menorah",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let passover = CalendarHoliday(
        name: "Passover",
        date: createDate(month: 4, day: 22, year: 2025), // Approximate start - varies by Hebrew calendar
        emoji: "🥖",
        description: "Jewish holiday commemorating the liberation of the Israelites from Egyptian slavery.",
        unsplashSearchTerm: "passover seder",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let purim = CalendarHoliday(
        name: "Purim",
        date: createDate(month: 3, day: 24, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🎭",
        description: "Jewish holiday commemorating the saving of the Jewish people from Haman.",
        unsplashSearchTerm: "purim celebration",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let sukkot = CalendarHoliday(
        name: "Sukkot",
        date: createDate(month: 10, day: 16, year: 2025), // Approximate start - varies by Hebrew calendar
        emoji: "🌿",
        description: "Jewish harvest festival commemorating the 40 years Israelites spent in the desert.",
        unsplashSearchTerm: "sukkot sukkah",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let shavuot = CalendarHoliday(
        name: "Shavuot",
        date: createDate(month: 6, day: 12, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🌾",
        description: "Jewish holiday marking the giving of the Torah at Mount Sinai.",
        unsplashSearchTerm: "shavuot",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let diwali = CalendarHoliday(
        name: "Diwali",
        date: createDate(month: 11, day: 1, year: 2024), // Approximate - varies by Hindu calendar
        emoji: "🪔",
        description: "Hindu Festival of Lights, celebrating the victory of light over darkness.",
        unsplashSearchTerm: "diwali lights",
        isRecurring: true,
        category: .otherHolidays
    )
    
    // MARK: - Social/Cultural Holidays
    
    static let groundhogDay = CalendarHoliday(
        name: "Groundhog Day",
        date: createDate(month: 2, day: 2, year: 2025),
        emoji: "🐾",
        description: "A traditional holiday predicting the arrival of spring based on a groundhog's shadow.",
        unsplashSearchTerm: "groundhog day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let superBowlSunday = CalendarHoliday(
        name: "Super Bowl Sunday",
        date: createDate(month: 2, day: 9, year: 2025), // First Sunday in February
        emoji: "🏈",
        description: "The annual championship game of the National Football League.",
        unsplashSearchTerm: "super bowl",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let valentinesDayAlternative = CalendarHoliday(
        name: "Valentine's Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A day celebrating love and affection, often involving cards, flowers, and romantic gestures.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let presidentsDayAlternative = CalendarHoliday(
        name: "Presidents' Day",
        date: createDate(month: 2, day: 17, year: 2025),
        emoji: "🇺🇸",
        description: "Honoring all U.S. presidents, originally Washington's Birthday, now a federal holiday.",
        unsplashSearchTerm: "presidents day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let stPatricksDayCultural = CalendarHoliday(
        name: "St. Patrick's Day",
        date: createDate(month: 3, day: 17, year: 2025),
        emoji: "☘️",
        description: "Celebrating Irish heritage with parades, green attire, and festive celebrations.",
        unsplashSearchTerm: "st patricks day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let aprilFoolsDay = CalendarHoliday(
        name: "April Fool's Day",
        date: createDate(month: 4, day: 1, year: 2025),
        emoji: "😄",
        description: "A day for playing practical jokes and spreading hoaxes.",
        unsplashSearchTerm: "april fools day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let earthDay = CalendarHoliday(
        name: "Earth Day",
        date: createDate(month: 4, day: 22, year: 2025),
        emoji: "🌍",
        description: "A day to demonstrate support for environmental protection and sustainability.",
        unsplashSearchTerm: "earth day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let cincoDeMayo = CalendarHoliday(
        name: "Cinco de Mayo",
        date: createDate(month: 5, day: 5, year: 2025),
        emoji: "🎉",
        description: "Celebrating Mexican heritage and culture, commemorating the Battle of Puebla.",
        unsplashSearchTerm: "cinco de mayo",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let kentuckyDerby = CalendarHoliday(
        name: "Kentucky Derby",
        date: createDate(month: 5, day: 3, year: 2025), // First Saturday in May
        emoji: "🐎",
        description: "The most famous horse race in America, known as 'The Run for the Roses.'",
        unsplashSearchTerm: "kentucky derby",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let memorialDayWeekend = CalendarHoliday(
        name: "Memorial Day Weekend",
        date: createDate(month: 5, day: 24, year: 2025),
        emoji: "🏖️",
        description: "The unofficial start of summer, marked by barbecues and outdoor activities.",
        unsplashSearchTerm: "memorial day weekend",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let fathersDayCultural = CalendarHoliday(
        name: "Father's Day",
        date: createDate(month: 6, day: 15, year: 2025),
        emoji: "👨‍👧‍👦",
        description: "A day to honor fathers and father figures with cards, gifts, and special activities.",
        unsplashSearchTerm: "fathers day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let canadaDay = CalendarHoliday(
        name: "Canada Day",
        date: createDate(month: 7, day: 1, year: 2025),
        emoji: "🇨🇦",
        description: "Celebrating the anniversary of Canadian Confederation.",
        unsplashSearchTerm: "canada day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let independenceDayAlternative = CalendarHoliday(
        name: "Independence Day",
        date: createDate(month: 7, day: 4, year: 2025),
        emoji: "🎆",
        description: "Celebrating America's independence with fireworks, parades, and patriotic activities.",
        unsplashSearchTerm: "fourth of july",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let bastilleDay = CalendarHoliday(
        name: "Bastille Day",
        date: createDate(month: 7, day: 14, year: 2025),
        emoji: "🇫🇷",
        description: "French National Day commemorating the Storming of the Bastille.",
        unsplashSearchTerm: "bastille day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalHamburgerDay = CalendarHoliday(
        name: "National Hamburger Day",
        date: createDate(month: 5, day: 28, year: 2025),
        emoji: "🍔",
        description: "A day to celebrate one of America's favorite foods: the hamburger.",
        unsplashSearchTerm: "hamburger",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalIceCreamDay = CalendarHoliday(
        name: "National Ice Cream Day",
        date: createDate(month: 7, day: 20, year: 2025), // Third Sunday in July
        emoji: ["🍦","🍨"].randomElement() ?? "🍨",
        description: "A day to enjoy and celebrate ice cream.",
        unsplashSearchTerm: "ice cream",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let laborDayWeekend = CalendarHoliday(
        name: "Labor Day Weekend",
        date: createDate(month: 9, day: 1, year: 2025),
        emoji: "🏕️",
        description: "The unofficial end of summer, often celebrated with outdoor activities and barbecues.",
        unsplashSearchTerm: "labor day weekend",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let grandparentsDay = CalendarHoliday(
        name: "Grandparents Day",
        date: createDate(month: 9, day: 7, year: 2025), // First Sunday after Labor Day
        emoji: "👴👵",
        description: "A day to honor grandparents and their contributions to families and society.",
        unsplashSearchTerm: "grandparents day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let roshHashanahCultural = CalendarHoliday(
        name: "Rosh Hashanah",
        date: createDate(month: 9, day: 25, year: 2025),
        emoji: "🍎",
        description: "Jewish New Year, celebrated with special meals and traditions.",
        unsplashSearchTerm: "rosh hashanah",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let halloweenCultural = CalendarHoliday(
        name: "Halloween",
        date: createDate(month: 10, day: 31, year: 2024),
        emoji: "🎃",
        description: "A fun holiday involving costumes, trick-or-treating, and spooky decorations.",
        unsplashSearchTerm: "halloween",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let dayOfTheDead = CalendarHoliday(
        name: "Day of the Dead",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "💀",
        description: "Mexican holiday honoring deceased loved ones with altars and celebrations.",
        unsplashSearchTerm: "day of the dead",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let veteransDayCultural = CalendarHoliday(
        name: "Veterans Day",
        date: createDate(month: 11, day: 11, year: 2025),
        emoji: "🎖️",
        description: "Honoring all veterans who have served in the U.S. military.",
        unsplashSearchTerm: "veterans day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let thanksgivingCultural = CalendarHoliday(
        name: "Thanksgiving",
        date: createDate(month: 11, day: 28, year: 2024),
        emoji: "🦃",
        description: "A holiday celebrating gratitude and harvest, traditionally involving a feast with turkey and family gatherings.",
        unsplashSearchTerm: "thanksgiving",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let blackFridayCultural = CalendarHoliday(
        name: "Black Friday",
        date: createDate(month: 11, day: 29, year: 2024),
        emoji: "🛍️",
        description: "The day after Thanksgiving, known for major shopping deals and the start of the holiday shopping season.",
        unsplashSearchTerm: "black friday",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let cyberMonday = CalendarHoliday(
        name: "Cyber Monday",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "💻",
        description: "The Monday after Thanksgiving, known for online shopping deals.",
        unsplashSearchTerm: "cyber monday shopping",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let hanukkahCultural = CalendarHoliday(
        name: "Hanukkah",
        date: createDate(month: 12, day: 25, year: 2024),
        emoji: "🕎",
        description: "The Festival of Lights, an eight-day Jewish holiday celebrating the rededication of the Second Temple.",
        unsplashSearchTerm: "hanukkah",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let kwanzaa = CalendarHoliday(
        name: "Kwanzaa",
        date: createDate(month: 12, day: 26, year: 2025),
        emoji: "🕯️",
        description: "A week-long celebration honoring African American culture and heritage.",
        unsplashSearchTerm: "kwanzaa celebration",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let newYearsEveCultural = CalendarHoliday(
        name: "New Year's Eve",
        date: createDate(month: 12, day: 31, year: 2024),
        emoji: "🎊",
        description: "The last day of the year, celebrated with parties and fireworks as people welcome the new year.",
        unsplashSearchTerm: "new years eve",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let newYearsDayCultural = CalendarHoliday(
        name: "New Year's Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "🎉",
        description: "The first day of the new year, celebrated with resolutions, parades, and family gatherings.",
        unsplashSearchTerm: "new years day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPizzaDay = CalendarHoliday(
        name: "National Pizza Day",
        date: createDate(month: 2, day: 9, year: 2025),
        emoji: "🍕",
        description: "A day to celebrate one of America's favorite foods: pizza.",
        unsplashSearchTerm: "pizza",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalDonutDay = CalendarHoliday(
        name: "National Donut Day",
        date: createDate(month: 6, day: 7, year: 2025), // First Friday in June
        emoji: "🍩",
        description: "A day to enjoy and celebrate donuts, originally created to honor the Salvation Army.",
        unsplashSearchTerm: "donuts",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCoffeeDay = CalendarHoliday(
        name: "National Coffee Day",
        date: createDate(month: 9, day: 29, year: 2025),
        emoji: "☕",
        description: "A day to celebrate coffee and its cultural significance.",
        unsplashSearchTerm: "coffee",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalTacoDay = CalendarHoliday(
        name: "National Taco Day",
        date: createDate(month: 10, day: 4, year: 2025),
        emoji: "🌮",
        description: "A day to celebrate tacos, one of the most beloved Mexican foods.",
        unsplashSearchTerm: "tacos",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let chineseNewYear = CalendarHoliday(
        name: "Lunar New Year",
        date: createDate(month: 1, day: 29, year: 2025), // Approximate - varies by lunar calendar
        emoji: "🧧",
        description: "The most important Chinese festival, marking the beginning of the lunar new year.",
        unsplashSearchTerm: "lunar new year",
        isRecurring: true,
        category: .seasons
    )
    
    static let valentinesDayWeek = CalendarHoliday(
        name: "Valentine's Day Week",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💝",
        description: "A week-long celebration leading up to Valentine's Day.",
        unsplashSearchTerm: "valentines day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let summerSolstice = CalendarHoliday(
        name: "Summer Solstice",
        date: createDate(month: 6, day: 21, year: 2025),
        emoji: "☀️",
        description: "The longest day of the year and the official start of summer in the Northern Hemisphere.",
        unsplashSearchTerm: "summer solstice",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let winterSolstice = CalendarHoliday(
        name: "Winter Solstice",
        date: createDate(month: 12, day: 21, year: 2025),
        emoji: "❄️",
        description: "The shortest day of the year and the official start of winter in the Northern Hemisphere.",
        unsplashSearchTerm: "winter solstice",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let autumnalEquinox = CalendarHoliday(
        name: "First Day of Fall",
        date: createDate(month: 9, day: 22, year: 2025),
        emoji: "🍂",
        description: "The autumnal equinox, marking the beginning of fall and shorter days.",
        unsplashSearchTerm: "autumn fall",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let vernalEquinox = CalendarHoliday(
        name: "First Day of Spring",
        date: createDate(month: 3, day: 20, year: 2025),
        emoji: "🌸",
        description: "The vernal equinox, marking the beginning of spring and longer days.",
        unsplashSearchTerm: "spring",
        isRecurring: true,
        category: .otherHolidays
    )
    
    // MARK: - Educational Holidays
    
    static let piDayEducational = CalendarHoliday(
        name: "Pi Day",
        date: createDate(month: 3, day: 14, year: 2025),
        emoji: "🥧",
        description: "Celebrating the mathematical constant π (pi), often with pie-eating and math activities.",
        unsplashSearchTerm: "pi day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let teachersDay = CalendarHoliday(
        name: "Teacher Appreciation Day",
        date: createDate(month: 5, day: 6, year: 2025), // First Tuesday of first full week in May
        emoji: "👩‍🏫",
        description: "A day to honor teachers and their contributions to education.",
        unsplashSearchTerm: "teacher appreciation",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let bookLoversDay = CalendarHoliday(
        name: "Book Lovers Day",
        date: createDate(month: 8, day: 9, year: 2025),
        emoji: "📚",
        description: "A day to celebrate books and reading.",
        unsplashSearchTerm: "books reading",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Holidays
    
    static let inaugurationDay = CalendarHoliday(
        name: "Inauguration Day",
        date: createDate(month: 1, day: 20, year: 2025), // Every 4 years
        emoji: "🏛️",
        description: "The day the President of the United States is inaugurated, held every four years.",
        unsplashSearchTerm: "inauguration day",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let leapDay = CalendarHoliday(
        name: "Leap Day",
        date: createDate(month: 2, day: 29, year: 2024),
        emoji: "🐸",
        description: "An extra day added to the calendar every four years to keep it synchronized with the seasons.",
        unsplashSearchTerm: "leap day",
        isRecurring: false,
        category: .uniqueHolidays
    )
    
    static let daylightSavingTimeStarts = CalendarHoliday(
        name: "Daylight Saving Time Begins",
        date: createDate(month: 3, day: 9, year: 2025), // Second Sunday in March
        emoji: "⏰",
        description: "The day clocks spring forward one hour, marking the start of daylight saving time.",
        unsplashSearchTerm: "daylight saving time",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let daylightSavingTimeEnds = CalendarHoliday(
        name: "Daylight Saving Time Ends",
        date: createDate(month: 11, day: 2, year: 2025), // First Sunday in November
        emoji: "⏰",
        description: "The day clocks fall back one hour, marking the end of daylight saving time.",
        unsplashSearchTerm: "daylight saving time",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let taxDay = CalendarHoliday(
        name: "Tax Day",
        date: createDate(month: 4, day: 15, year: 2025),
        emoji: "📋",
        description: "The deadline for filing federal income tax returns in the United States.",
        unsplashSearchTerm: "tax day",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let nationalPetDay = CalendarHoliday(
        name: "National Pet Day",
        date: createDate(month: 4, day: 11, year: 2025),
        emoji: "🐾",
        description: "A day to celebrate pets and the joy they bring to our lives.",
        unsplashSearchTerm: "pet day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let mayDay = CalendarHoliday(
        name: "May Day",
        date: createDate(month: 5, day: 1, year: 2025),
        emoji: "🌺",
        description: "A spring festival and celebration of workers' rights, also known as International Workers' Day.",
        unsplashSearchTerm: "may day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let starWarsDay = CalendarHoliday(
        name: "Star Wars Day",
        date: createDate(month: 5, day: 4, year: 2025),
        emoji: "⭐",
        description: "Celebrating the Star Wars franchise with the catchphrase 'May the Fourth be with you.'",
        unsplashSearchTerm: "star wars",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let mothersDayWeekend = CalendarHoliday(
        name: "Mother's Day Weekend",
        date: createDate(month: 5, day: 10, year: 2025),
        emoji: "💐",
        description: "The weekend celebrating mothers and mother figures.",
        unsplashSearchTerm: "mothers day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let armedForcesDay = CalendarHoliday(
        name: "Armed Forces Day",
        date: createDate(month: 5, day: 17, year: 2025), // Third Saturday in May
        emoji: "🎖️",
        description: "Honoring all branches of the United States Armed Forces.",
        unsplashSearchTerm: "armed forces day",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let emancipationProclamationDay = CalendarHoliday(
        name: "Emancipation Proclamation Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "📜",
        description: "Commemorating the day President Lincoln issued the Emancipation Proclamation in 1863.",
        unsplashSearchTerm: "emancipation proclamation",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let rosaParksDay = CalendarHoliday(
        name: "Rosa Parks Day",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "🚌",
        description: "Honoring Rosa Parks and her role in the Civil Rights Movement.",
        unsplashSearchTerm: "rosa parks",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let billOfRightsDay = CalendarHoliday(
        name: "Bill of Rights Day",
        date: createDate(month: 12, day: 15, year: 2025),
        emoji: "📜",
        description: "Commemorating the ratification of the Bill of Rights, the first ten amendments to the Constitution.",
        unsplashSearchTerm: "bill of rights",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let wrightBrothersDay = CalendarHoliday(
        name: "Wright Brothers Day",
        date: createDate(month: 12, day: 17, year: 2025),
        emoji: "✈️",
        description: "Commemorating the first successful powered flight by the Wright brothers in 1903.",
        unsplashSearchTerm: "wright brothers",
        isRecurring: true,
        category: .bankHolidays
    )
    
    static let nationalFriendshipDay = CalendarHoliday(
        name: "National Friendship Day",
        date: createDate(month: 8, day: 3, year: 2025), // First Sunday in August
        emoji: "🤝",
        description: "A day to celebrate friendships and the bonds between friends.",
        unsplashSearchTerm: "friendship day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalSiblingsDay = CalendarHoliday(
        name: "National Siblings Day",
        date: createDate(month: 4, day: 10, year: 2025),
        emoji: "👨‍👩‍👧‍👦",
        description: "A day to honor and celebrate the bond between siblings.",
        unsplashSearchTerm: "siblings day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalWomensDay = CalendarHoliday(
        name: "National Women's Day",
        date: createDate(month: 3, day: 8, year: 2025),
        emoji: "👩",
        description: "Celebrating the achievements and contributions of women throughout history.",
        unsplashSearchTerm: "womens day",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let stGeorgesDay = CalendarHoliday(
        name: "St. George's Day",
        date: createDate(month: 4, day: 23, year: 2025),
        emoji: "⚔️",
        description: "Christian feast day honoring St. George, the patron saint of England.",
        unsplashSearchTerm: "saint george",
        isRecurring: true,
        category: .christianHolidays
    )
    
    static let walpurgisNight = CalendarHoliday(
        name: "Walpurgis Night",
        date: createDate(month: 4, day: 30, year: 2025),
        emoji: "🔥",
        description: "A European spring festival celebrated on the eve of May Day.",
        unsplashSearchTerm: "walpurgis night",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Unique Holidays
    
    static let talkLikeAPirateDay = CalendarHoliday(
        name: "Talk Like a Pirate Day",
        date: createDate(month: 9, day: 19, year: 2025),
        emoji: "🏴‍☠️",
        description: "A fun holiday where people talk like pirates and celebrate pirate culture.",
        unsplashSearchTerm: "pirate",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalMargaritaDay = CalendarHoliday(
        name: "National Margarita Day",
        date: createDate(month: 2, day: 22, year: 2025),
        emoji: "🍹",
        description: "A day to celebrate the popular tequila-based cocktail.",
        unsplashSearchTerm: "margarita",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCheeseDay = CalendarHoliday(
        name: "National Cheese Day",
        date: createDate(month: 6, day: 4, year: 2025),
        emoji: "🧀",
        description: "A day to celebrate and enjoy all varieties of cheese.",
        unsplashSearchTerm: "cheese",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalChocolateDay = CalendarHoliday(
        name: "National Chocolate Day",
        date: createDate(month: 10, day: 28, year: 2025),
        emoji: "🍫",
        description: "A day to celebrate and enjoy chocolate in all its forms.",
        unsplashSearchTerm: "chocolate",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPancakeDay = CalendarHoliday(
        name: "National Pancake Day",
        date: createDate(month: 9, day: 26, year: 2025),
        emoji: "🥞",
        description: "A day to celebrate pancakes, a beloved breakfast food.",
        unsplashSearchTerm: "pancakes",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalSandwichDay = CalendarHoliday(
        name: "National Sandwich Day",
        date: createDate(month: 11, day: 3, year: 2025),
        emoji: "🥪",
        description: "A day to celebrate the versatile and beloved sandwich.",
        unsplashSearchTerm: "sandwich",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCookieDay = CalendarHoliday(
        name: "National Cookie Day",
        date: createDate(month: 12, day: 4, year: 2025),
        emoji: "🍪",
        description: "A day to celebrate and enjoy cookies of all kinds.",
        unsplashSearchTerm: "cookies",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPretzelDay = CalendarHoliday(
        name: "National Pretzel Day",
        date: createDate(month: 4, day: 26, year: 2025),
        emoji: "🥨",
        description: "A day to celebrate the twisted snack food, pretzels.",
        unsplashSearchTerm: "pretzel",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalBubbleBathDay = CalendarHoliday(
        name: "National Bubble Bath Day",
        date: createDate(month: 1, day: 8, year: 2025),
        emoji: "🛁",
        description: "A day to relax and enjoy a soothing bubble bath.",
        unsplashSearchTerm: "bubble bath",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPajamaDay = CalendarHoliday(
        name: "National Pajama Day",
        date: createDate(month: 4, day: 16, year: 2025),
        emoji: "🛏️",
        description: "A fun day to wear pajamas and celebrate comfort.",
        unsplashSearchTerm: "pajamas",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Awareness Days
    
    static let blackHistoryMonthStart = CalendarHoliday(
        name: "Black History Month Begins",
        date: createDate(month: 2, day: 1, year: 2025),
        emoji: "✊",
        description: "The beginning of Black History Month, celebrating African American history and achievements.",
        unsplashSearchTerm: "black history month",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let autismAwarenessDay = CalendarHoliday(
        name: "World Autism Awareness Day",
        date: createDate(month: 4, day: 2, year: 2025),
        emoji: "🧩",
        description: "A day to raise awareness about autism spectrum disorder and promote acceptance.",
        unsplashSearchTerm: "autism awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let breastCancerAwarenessMonthStart = CalendarHoliday(
        name: "Breast Cancer Awareness Month Begins",
        date: createDate(month: 10, day: 1, year: 2025),
        emoji: "💗",
        description: "The beginning of Breast Cancer Awareness Month, promoting awareness and early detection.",
        unsplashSearchTerm: "breast cancer awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let mentalHealthAwarenessMonthStart = CalendarHoliday(
        name: "Mental Health Awareness Month Begins",
        date: createDate(month: 5, day: 1, year: 2025),
        emoji: "🧠",
        description: "The beginning of Mental Health Awareness Month, promoting mental health awareness and support.",
        unsplashSearchTerm: "mental health",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldAidsDay = CalendarHoliday(
        name: "World AIDS Day",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "🎗️",
        description: "A day to raise awareness about AIDS and support those affected by HIV/AIDS.",
        unsplashSearchTerm: "world aids day",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let heartMonthStart = CalendarHoliday(
        name: "American Heart Month Begins",
        date: createDate(month: 2, day: 1, year: 2025),
        emoji: "❤️",
        description: "The beginning of American Heart Month, promoting heart health awareness.",
        unsplashSearchTerm: "heart health",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let diabetesAwarenessMonthStart = CalendarHoliday(
        name: "Diabetes Awareness Month Begins",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "💙",
        description: "The beginning of Diabetes Awareness Month, promoting awareness and prevention.",
        unsplashSearchTerm: "diabetes awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let alzheimersAwarenessMonthStart = CalendarHoliday(
        name: "Alzheimer's Awareness Month Begins",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "🧬",
        description: "The beginning of Alzheimer's Awareness Month, promoting awareness and support.",
        unsplashSearchTerm: "alzheimers awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldCancerDay = CalendarHoliday(
        name: "World Cancer Day",
        date: createDate(month: 2, day: 4, year: 2025),
        emoji: "🎗️",
        description: "A day to raise awareness about cancer prevention, detection, and treatment.",
        unsplashSearchTerm: "cancer awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldWaterDay = CalendarHoliday(
        name: "World Water Day",
        date: createDate(month: 3, day: 22, year: 2025),
        emoji: "💧",
        description: "A day to raise awareness about the importance of freshwater and sustainable water management.",
        unsplashSearchTerm: "water conservation",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let earthHour = CalendarHoliday(
        name: "Earth Hour",
        date: createDate(month: 3, day: 29, year: 2025), // Last Saturday of March
        emoji: "🌍",
        description: "A global event where people turn off lights for one hour to raise awareness about climate change.",
        unsplashSearchTerm: "earth hour",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldHealthDay = CalendarHoliday(
        name: "World Health Day",
        date: createDate(month: 4, day: 7, year: 2025),
        emoji: "⚕️",
        description: "A global health awareness day sponsored by the World Health Organization.",
        unsplashSearchTerm: "world health day",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let arborDayAwareness = CalendarHoliday(
        name: "Arbor Day",
        date: createDate(month: 4, day: 26, year: 2025), // Last Friday of April
        emoji: "🌳",
        description: "A holiday encouraging tree planting and environmental awareness.",
        unsplashSearchTerm: "tree planting",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalStrokeAwarenessMonthStart = CalendarHoliday(
        name: "National Stroke Awareness Month Begins",
        date: createDate(month: 5, day: 1, year: 2025),
        emoji: "🧠",
        description: "The beginning of Stroke Awareness Month, promoting awareness of stroke prevention and symptoms.",
        unsplashSearchTerm: "stroke awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalSkinCancerAwarenessMonthStart = CalendarHoliday(
        name: "Skin Cancer Awareness Month Begins",
        date: createDate(month: 5, day: 1, year: 2025),
        emoji: "☀️",
        description: "The beginning of Skin Cancer Awareness Month, promoting sun safety and early detection.",
        unsplashSearchTerm: "skin cancer awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldEnvironmentDay = CalendarHoliday(
        name: "World Environment Day",
        date: createDate(month: 6, day: 5, year: 2025),
        emoji: "🌱",
        description: "A day to raise awareness and action for environmental protection.",
        unsplashSearchTerm: "world environment day",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalSuicidePreventionMonthStart = CalendarHoliday(
        name: "Suicide Prevention Month Begins",
        date: createDate(month: 9, day: 1, year: 2025),
        emoji: "💙",
        description: "The beginning of Suicide Prevention Month, promoting awareness and support for mental health.",
        unsplashSearchTerm: "suicide prevention",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldOceansDay = CalendarHoliday(
        name: "World Oceans Day",
        date: createDate(month: 6, day: 8, year: 2025),
        emoji: "🌊",
        description: "A day to celebrate and raise awareness about the importance of oceans.",
        unsplashSearchTerm: "ocean conservation",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalDomesticViolenceAwarenessMonthStart = CalendarHoliday(
        name: "Domestic Violence Awareness Month Begins",
        date: createDate(month: 10, day: 1, year: 2025),
        emoji: "💜",
        description: "The beginning of Domestic Violence Awareness Month, promoting awareness and support.",
        unsplashSearchTerm: "domestic violence awareness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    // MARK: - Additional Other Holidays
    
    static let ramadanStart = CalendarHoliday(
        name: "Ramadan Begins",
        date: createDate(month: 3, day: 1, year: 2025), // Approximate - varies by Islamic calendar
        emoji: "🌙",
        description: "The beginning of Ramadan, a month of fasting, prayer, and reflection for Muslims.",
        unsplashSearchTerm: "ramadan",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let eidAlFitr = CalendarHoliday(
        name: "Eid al-Fitr",
        date: createDate(month: 3, day: 31, year: 2025), // Approximate - varies by Islamic calendar
        emoji: "🕌",
        description: "The festival marking the end of Ramadan, celebrated with feasting and prayer.",
        unsplashSearchTerm: "eid al fitr",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let eidAlAdha = CalendarHoliday(
        name: "Eid al-Adha",
        date: createDate(month: 6, day: 16, year: 2025), // Approximate - varies by Islamic calendar
        emoji: "🕋",
        description: "The Festival of Sacrifice, one of the most important Islamic holidays.",
        unsplashSearchTerm: "eid al adha",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let vesak = CalendarHoliday(
        name: "Vesak",
        date: createDate(month: 5, day: 12, year: 2025), // Approximate - varies by lunar calendar
        emoji: "🪷",
        description: "Buddha's Birthday, celebrating the birth, enlightenment, and death of Buddha.",
        unsplashSearchTerm: "vesak buddha",
        isRecurring: true,
        category: .otherHolidays
    )
    
    static let holi = CalendarHoliday(
        name: "Holi",
        date: createDate(month: 3, day: 14, year: 2025), // Approximate - varies by Hindu calendar
        emoji: "🎨",
        description: "The Festival of Colors, celebrating spring and the triumph of good over evil.",
        unsplashSearchTerm: "holi festival",
        isRecurring: true,
        category: .otherHolidays
    )
    
    
    // MARK: - Additional Jewish Holidays
    
    static let tuBshevat = CalendarHoliday(
        name: "Tu B'Shevat",
        date: createDate(month: 1, day: 17, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🌳",
        description: "The New Year for Trees, celebrating nature and environmental awareness.",
        unsplashSearchTerm: "tu bshevat",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let lagBOmer = CalendarHoliday(
        name: "Lag B'Omer",
        date: createDate(month: 5, day: 26, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🔥",
        description: "A festive day during the counting of the Omer, marked with bonfires and celebrations.",
        unsplashSearchTerm: "lag bomer",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let tishaBAv = CalendarHoliday(
        name: "Tisha B'Av",
        date: createDate(month: 8, day: 13, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🕯️",
        description: "A day of mourning commemorating the destruction of the First and Second Temples.",
        unsplashSearchTerm: "tisha bav",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let simchatTorah = CalendarHoliday(
        name: "Simchat Torah",
        date: createDate(month: 10, day: 17, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "📜",
        description: "The day marking the completion of the annual cycle of reading the Torah.",
        unsplashSearchTerm: "simchat torah",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    static let sheminiAtzeret = CalendarHoliday(
        name: "Shemini Atzeret",
        date: createDate(month: 10, day: 16, year: 2025), // Approximate - varies by Hebrew calendar
        emoji: "🍂",
        description: "The eighth day of assembly, immediately following Sukkot.",
        unsplashSearchTerm: "shemini atzeret",
        isRecurring: true,
        category: .jewishHolidays
    )
    
    // MARK: - Additional Seasonal Holidays (Lunar Phases)
    
    // Note: New Moon and Full Moon dates are approximate and calculated based on a 29.5-day cycle
    // Actual dates vary and should be calculated using astronomical algorithms
    
    static let newMoonJanuary = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 1, day: 11, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonJanuary = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 1, day: 25, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonFebruary = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 2, day: 9, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonFebruary = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 2, day: 24, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonMarch = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 3, day: 10, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonMarch = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 3, day: 25, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonApril = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 4, day: 8, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonApril = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 4, day: 24, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonMay = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 5, day: 8, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonMay = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 5, day: 23, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonJune = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 6, day: 6, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonJune = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 6, day: 22, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonJuly = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 7, day: 5, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonJuly = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 7, day: 21, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonAugust = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 8, day: 4, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonAugust = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 8, day: 19, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonSeptember = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 9, day: 2, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonSeptember = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 9, day: 18, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonOctober = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 10, day: 2, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonOctober = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 10, day: 17, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonNovember = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 11, day: 1, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonNovember = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 11, day: 15, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let newMoonDecember = CalendarHoliday(
        name: "New Moon",
        date: createDate(month: 12, day: 1, year: 2025),
        emoji: "🌑",
        description: "The phase of the moon when it is not visible from Earth, marking the start of a new lunar cycle.",
        unsplashSearchTerm: "new moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let fullMoonDecember = CalendarHoliday(
        name: "Full Moon",
        date: createDate(month: 12, day: 15, year: 2025),
        emoji: "🌕",
        description: "The phase of the moon when it is fully illuminated as seen from Earth.",
        unsplashSearchTerm: "full moon",
        isRecurring: true,
        category: .seasons
    )
    
    static let blueMoon = CalendarHoliday(
        name: "Blue Moon",
        date: createDate(month: 5, day: 31, year: 2026), // Known blue moon date
        emoji: "🔵",
        description: "A rare occurrence when there are two full moons in a single calendar month.",
        unsplashSearchTerm: "blue moon",
        isRecurring: false,
        category: .seasons
    )
    
    // MARK: - Additional Seasonal Holidays
    
    static let firstDayOfWinter = CalendarHoliday(
        name: "First Day of Winter",
        date: createDate(month: 12, day: 21, year: 2025), // Winter solstice
        emoji: "❄️",
        description: "The winter solstice, the shortest day of the year and beginning of winter.",
        unsplashSearchTerm: "winter solstice",
        isRecurring: true,
        category: .seasons
    )
    
    static let firstDayOfFall = CalendarHoliday(
        name: "First Day of Fall",
        date: createDate(month: 9, day: 22, year: 2025), // Autumnal equinox
        emoji: "🍂",
        description: "The autumnal equinox, marking the beginning of fall and shorter days.",
        unsplashSearchTerm: "autumn fall",
        isRecurring: true,
        category: .seasons
    )
    
    // MARK: - Additional Food Holidays
    
    static let nationalGrilledCheeseDay = CalendarHoliday(
        name: "National Grilled Cheese Day",
        date: createDate(month: 4, day: 12, year: 2025),
        emoji: "🥪",
        description: "A day to celebrate the classic comfort food: grilled cheese sandwiches.",
        unsplashSearchTerm: "grilled cheese",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalBaconDay = CalendarHoliday(
        name: "National Bacon Day",
        date: createDate(month: 12, day: 30, year: 2025),
        emoji: "🥓",
        description: "A day to celebrate one of the most beloved breakfast foods: bacon.",
        unsplashSearchTerm: "bacon",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalApplePieDay = CalendarHoliday(
        name: "National Apple Pie Day",
        date: createDate(month: 5, day: 13, year: 2025),
        emoji: "🥧",
        description: "A day to celebrate the classic American dessert: apple pie.",
        unsplashSearchTerm: "apple pie",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalIceCreamForBreakfastDay = CalendarHoliday(
        name: "National Ice Cream for Breakfast Day",
        date: createDate(month: 2, day: 1, year: 2025), // First Saturday in February
        emoji: "🍦",
        description: "A fun day to start your morning with ice cream.",
        unsplashSearchTerm: "ice cream breakfast",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Pet Holidays
    
    static let nationalDogDay = CalendarHoliday(
        name: "National Dog Day",
        date: createDate(month: 8, day: 26, year: 2025),
        emoji: "🐕",
        description: "A day to celebrate dogs and raise awareness about dog adoption.",
        unsplashSearchTerm: "dog",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCatDay = CalendarHoliday(
        name: "National Cat Day",
        date: createDate(month: 10, day: 29, year: 2025),
        emoji: "🐱",
        description: "A day to celebrate cats and raise awareness about cat adoption.",
        unsplashSearchTerm: "cat",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let adoptAShelterPetDay = CalendarHoliday(
        name: "Adopt a Shelter Pet Day",
        date: createDate(month: 4, day: 30, year: 2025),
        emoji: "🏠",
        description: "A day to encourage pet adoption from animal shelters and rescues.",
        unsplashSearchTerm: "shelter pet adoption",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPuppyDay = CalendarHoliday(
        name: "National Puppy Day",
        date: createDate(month: 3, day: 23, year: 2025),
        emoji: "🐶",
        description: "A day to celebrate puppies and raise awareness about puppy mills.",
        unsplashSearchTerm: "puppy",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalAnimalDay = CalendarHoliday(
        name: "National Animal Day",
        date: createDate(month: 10, day: 4, year: 2025),
        emoji: "🐾",
        description: "A day to celebrate all animals and raise awareness about animal welfare.",
        unsplashSearchTerm: "animals",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let worldWildlifeDay = CalendarHoliday(
        name: "World Wildlife Day",
        date: createDate(month: 3, day: 3, year: 2025),
        emoji: "🦁",
        description: "A day to celebrate and raise awareness of the world's wild animals and plants.",
        unsplashSearchTerm: "wildlife",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalParksDay = CalendarHoliday(
        name: "National Parks Day",
        date: createDate(month: 4, day: 27, year: 2025), // Fourth Saturday in April
        emoji: "🏞️",
        description: "A day to celebrate and support America's national parks.",
        unsplashSearchTerm: "national parks",
        isRecurring: true,
        category: .awarenessDays
    )
    
    // MARK: - Additional Fun/Culture Holidays
    
    static let marioDay = CalendarHoliday(
        name: "Mario Day",
        date: createDate(month: 3, day: 10, year: 2025), // Mar 10 = MAR10
        emoji: "🍄",
        description: "A day celebrating Nintendo's iconic Super Mario character (MAR10 = MARIO).",
        unsplashSearchTerm: "super mario",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalVideoGameDay = CalendarHoliday(
        name: "National Video Game Day",
        date: createDate(month: 9, day: 12, year: 2025),
        emoji: "🎮",
        description: "A day to celebrate video games and gaming culture.",
        unsplashSearchTerm: "video games",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalComicBookDay = CalendarHoliday(
        name: "National Comic Book Day",
        date: createDate(month: 9, day: 25, year: 2025),
        emoji: "📚",
        description: "A day to celebrate comic books and graphic novels.",
        unsplashSearchTerm: "comic books",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalMovieDay = CalendarHoliday(
        name: "National Movie Day",
        date: createDate(month: 10, day: 11, year: 2025),
        emoji: "🎬",
        description: "A day to celebrate movies and cinema.",
        unsplashSearchTerm: "movies",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let batmanDay = CalendarHoliday(
        name: "Batman Day",
        date: createDate(month: 9, day: 21, year: 2025), // Third Saturday in September
        emoji: "🦇",
        description: "A day celebrating the iconic DC Comics superhero Batman.",
        unsplashSearchTerm: "batman",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let pokemonDay = CalendarHoliday(
        name: "Pokémon Day",
        date: createDate(month: 2, day: 27, year: 2025),
        emoji: "⚡",
        description: "A day celebrating the Pokémon franchise, commemorating the release of the first games.",
        unsplashSearchTerm: "pokemon",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Kindness/Mental Health Holidays
    
    static let randomActsOfKindnessDay = CalendarHoliday(
        name: "Random Acts of Kindness Day",
        date: createDate(month: 2, day: 17, year: 2025),
        emoji: "💝",
        description: "A day to encourage and celebrate random acts of kindness.",
        unsplashSearchTerm: "kindness",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let worldMentalHealthDay = CalendarHoliday(
        name: "World Mental Health Day",
        date: createDate(month: 10, day: 10, year: 2025),
        emoji: "🧠",
        description: "A day to raise awareness about mental health issues and support mental health care.",
        unsplashSearchTerm: "mental health",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalKindnessDay = CalendarHoliday(
        name: "National Kindness Day",
        date: createDate(month: 11, day: 13, year: 2025),
        emoji: "❤️",
        description: "A day to celebrate and encourage acts of kindness.",
        unsplashSearchTerm: "kindness",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalBestFriendsDay = CalendarHoliday(
        name: "National Best Friends Day",
        date: createDate(month: 6, day: 8, year: 2025),
        emoji: "👯",
        description: "A day to celebrate and appreciate best friends.",
        unsplashSearchTerm: "best friends",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let worldSmileDay = CalendarHoliday(
        name: "World Smile Day",
        date: createDate(month: 10, day: 4, year: 2025), // First Friday in October
        emoji: "😊",
        description: "A day to spread smiles and happiness around the world.",
        unsplashSearchTerm: "smile",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let worldHappinessDay = CalendarHoliday(
        name: "World Happiness Day",
        date: createDate(month: 3, day: 20, year: 2025),
        emoji: "😊",
        description: "A day to recognize the importance of happiness in people's lives.",
        unsplashSearchTerm: "happiness",
        isRecurring: true,
        category: .awarenessDays
    )
    
    static let nationalComplimentDay = CalendarHoliday(
        name: "National Compliment Day",
        date: createDate(month: 1, day: 24, year: 2025),
        emoji: "💬",
        description: "A day to give compliments and spread positivity.",
        unsplashSearchTerm: "compliment",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalRelaxationDay = CalendarHoliday(
        name: "National Relaxation Day",
        date: createDate(month: 8, day: 15, year: 2025),
        emoji: "🧘",
        description: "A day dedicated to taking it easy and relaxing.",
        unsplashSearchTerm: "relaxation",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Educational Holidays
    
    static let nationalSTEMDay = CalendarHoliday(
        name: "National STEM Day",
        date: createDate(month: 11, day: 8, year: 2025),
        emoji: "🔬",
        description: "A day to celebrate science, technology, engineering, and mathematics education.",
        unsplashSearchTerm: "stem education",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalReadingDay = CalendarHoliday(
        name: "National Reading Day",
        date: createDate(month: 1, day: 23, year: 2025),
        emoji: "📖",
        description: "A day to promote and celebrate reading, especially for children.",
        unsplashSearchTerm: "reading",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let worldBookDay = CalendarHoliday(
        name: "World Book Day",
        date: createDate(month: 4, day: 23, year: 2025),
        emoji: "📚",
        description: "A day to celebrate books, reading, and publishing worldwide.",
        unsplashSearchTerm: "books",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalTriviaDay = CalendarHoliday(
        name: "National Trivia Day",
        date: createDate(month: 1, day: 4, year: 2025),
        emoji: "❓",
        description: "A day to celebrate trivia and test your knowledge.",
        unsplashSearchTerm: "trivia",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCartoonistsDay = CalendarHoliday(
        name: "National Cartoonists Day",
        date: createDate(month: 5, day: 5, year: 2025),
        emoji: "✏️",
        description: "A day to celebrate cartoonists and their art.",
        unsplashSearchTerm: "cartoon",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPhotographyDay = CalendarHoliday(
        name: "National Photography Day",
        date: createDate(month: 8, day: 19, year: 2025),
        emoji: "📸",
        description: "A day to celebrate the art and science of photography.",
        unsplashSearchTerm: "photography",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCreativityDay = CalendarHoliday(
        name: "National Creativity Day",
        date: createDate(month: 4, day: 21, year: 2025),
        emoji: "🎨",
        description: "A day to celebrate and encourage creativity in all forms.",
        unsplashSearchTerm: "creativity",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Lifestyle Holidays
    
    static let newYearsResolutionsDay = CalendarHoliday(
        name: "New Year's Resolutions Day",
        date: createDate(month: 1, day: 1, year: 2025),
        emoji: "🎯",
        description: "The day to make and start working on your New Year's resolutions.",
        unsplashSearchTerm: "new year resolutions",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalCleanYourRoomDay = CalendarHoliday(
        name: "National Clean Your Room Day",
        date: createDate(month: 5, day: 10, year: 2025),
        emoji: "🧹",
        description: "A day to encourage cleaning and organizing your personal space.",
        unsplashSearchTerm: "cleaning",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalOrganizeYourHomeDay = CalendarHoliday(
        name: "National Organize Your Home Day",
        date: createDate(month: 1, day: 14, year: 2025),
        emoji: "🏠",
        description: "A day dedicated to organizing and decluttering your home.",
        unsplashSearchTerm: "organize home",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalWorkFromHomeDay = CalendarHoliday(
        name: "National Work From Home Day",
        date: createDate(month: 2, day: 14, year: 2025),
        emoji: "💻",
        description: "A day to celebrate the flexibility and benefits of working from home.",
        unsplashSearchTerm: "work from home",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalTakeAWalkDay = CalendarHoliday(
        name: "National Take a Walk Day",
        date: createDate(month: 3, day: 19, year: 2025),
        emoji: "🚶",
        description: "A day to encourage walking for health and enjoyment.",
        unsplashSearchTerm: "walking",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    // MARK: - Additional Fun Holidays
    
    static let nationalHatDay = CalendarHoliday(
        name: "National Hat Day",
        date: createDate(month: 1, day: 15, year: 2025),
        emoji: "🎩",
        description: "A day to celebrate hats and headwear of all styles.",
        unsplashSearchTerm: "hats",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalLeftHandersDay = CalendarHoliday(
        name: "National Left-Handers Day",
        date: createDate(month: 8, day: 13, year: 2025),
        emoji: "✋",
        description: "A day to celebrate left-handed people and raise awareness about left-handedness.",
        unsplashSearchTerm: "left handed",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalPicnicDay = CalendarHoliday(
        name: "National Picnic Day",
        date: createDate(month: 4, day: 23, year: 2025),
        emoji: "🧺",
        description: "A day to enjoy a picnic outdoors with family and friends.",
        unsplashSearchTerm: "picnic",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalJokeDay = CalendarHoliday(
        name: "National Joke Day",
        date: createDate(month: 7, day: 1, year: 2025),
        emoji: "😄",
        description: "A day to share jokes and laughter with others.",
        unsplashSearchTerm: "jokes",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalThanksATeacherDay = CalendarHoliday(
        name: "National Thank a Teacher Day",
        date: createDate(month: 5, day: 7, year: 2025), // First Tuesday of first full week in May
        emoji: "👩‍🏫",
        description: "A day to thank and appreciate teachers for their hard work and dedication.",
        unsplashSearchTerm: "teacher appreciation",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    static let nationalBringYourPetToWorkDay = CalendarHoliday(
        name: "National Bring Your Pet to Work Day",
        date: createDate(month: 6, day: 21, year: 2025), // Friday after Father's Day
        emoji: "🐾",
        description: "A day to bring your pet to work, promoting pet adoption and workplace wellness.",
        unsplashSearchTerm: "pets at work",
        isRecurring: true,
        category: .uniqueHolidays
    )
    
    private static func createDate(month: Int, day: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
