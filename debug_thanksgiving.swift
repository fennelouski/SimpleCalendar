import Foundation

// Test Thanksgiving calculation
func thanksgivingDate(for year: Int) -> Date? {
    let calendar = Calendar.current

    // Start of November
    var components = DateComponents()
    components.year = year
    components.month = 11
    components.day = 1

    guard let startOfNovember = calendar.date(from: components) else { return nil }

    // Find the first Thursday of November
    let weekdayOfFirst = calendar.component(.weekday, from: startOfNovember)
    let daysToThursday = (5 - weekdayOfFirst + 7) % 7 // Thursday is 5 in Calendar
    let firstThursday = calendar.date(byAdding: .day, value: daysToThursday, to: startOfNovember)!

    // Fourth Thursday is 3 weeks after first Thursday
    let fourthThursday = calendar.date(byAdding: .day, value: 21, to: firstThursday)!

    return fourthThursday
}

func nthWeekdayOfMonth(year: Int, month: Int, weekday: Int, n: Int) -> Date? {
    let calendar = Calendar.current

    // Start of the month
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = 1

    guard let startOfMonth = calendar.date(from: components) else { return nil }

    // Find the first occurrence of the weekday in the month
    let weekdayOffset = (weekday - calendar.component(.weekday, from: startOfMonth) + 7) % 7
    let firstWeekday = calendar.date(byAdding: .day, value: weekdayOffset, to: startOfMonth)

    // Calculate the nth occurrence
    guard let firstOccurrence = firstWeekday else { return nil }
    let nthOccurrence = calendar.date(byAdding: .day, value: (n - 1) * 7, to: firstOccurrence)

    return nthOccurrence
}

print("Testing Thanksgiving calculation:")
for year in 2024...2026 {
    if let date = thanksgivingDate(for: year) {
        print("Thanksgiving \(year): \(date)")
    }

    // Also test the nthWeekdayOfMonth function
    if let date2 = nthWeekdayOfMonth(year: year, month: 11, weekday: 5, n: 4) { // Thursday = 5
        print("nthWeekdayOfMonth \(year): \(date2)")
        if let date = thanksgivingDate(for: year) {
            print("Match: \(date == date2)")
        }
    }
}
