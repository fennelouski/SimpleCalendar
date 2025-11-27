import Foundation

// Recreate the holiday loading logic to debug
struct CalendarHoliday {
    let name: String
    let date: Date
    let isRecurring: Bool

    func occursOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if isRecurring {
            let holidayComponents = calendar.dateComponents([.month, .day], from: self.date)
            let checkComponents = calendar.dateComponents([.month, .day], from: date)
            return holidayComponents.month == checkComponents.month &&
                   holidayComponents.day == checkComponents.day
        } else {
            return calendar.isDate(self.date, inSameDayAs: date)
        }
    }

    func dateInYear(_ year: Int) -> Date? {
        if isRecurring {
            switch name {
            case "Thanksgiving":
                return thanksgivingDate(for: year)
            default:
                let calendar = Calendar.current
                var components = calendar.dateComponents([.month, .day], from: self.date)
                components.year = year
                return calendar.date(from: components)
            }
        } else {
            return self.date
        }
    }

    private func thanksgivingDate(for year: Int) -> Date? {
        let calendar = Calendar.current

        // Start of November
        var components = DateComponents()
        components.year = year
        components.month = 11
        components.day = 1

        guard let startOfNovember = calendar.date(from: components) else { return nil }

        // Find the first Thursday of November
        let weekdayOfFirst = calendar.component(.weekday, from: startOfNovember)
        let daysToThursday = (5 - weekdayOfFirst + 7) % 7 // Thursday is 5 in Gregorian calendar
        let firstThursday = calendar.date(byAdding: .day, value: daysToThursday, to: startOfNovember)!

        // Fourth Thursday is 3 weeks after first Thursday
        let fourthThursday = calendar.date(byAdding: .day, value: 21, to: firstThursday)!

        return fourthThursday
    }
}

func createDate(month: Int, day: Int, year: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

// Create a sample Thanksgiving holiday
let thanksgiving = CalendarHoliday(
    name: "Thanksgiving",
    date: createDate(month: 11, day: 28, year: 2024), // This date will be recalculated
    isRecurring: true
)

print("Original thanksgiving date: \(thanksgiving.date)")

// Simulate loading holidays for 3 years
let calendar = Calendar.current
let currentYear = calendar.component(.year, from: Date())
let previousYear = currentYear - 1
let nextYear = currentYear + 1

print("Current year: \(currentYear)")
print("Previous year: \(previousYear)")
print("Next year: \(nextYear)")

var yearHolidays: [CalendarHoliday] = []

// Add holiday for previous year
if let previousYearDate = thanksgiving.dateInYear(previousYear) {
    let holidayForPreviousYear = CalendarHoliday(
        name: thanksgiving.name,
        date: previousYearDate,
        isRecurring: thanksgiving.isRecurring
    )
    yearHolidays.append(holidayForPreviousYear)
    print("Thanksgiving \(previousYear): \(previousYearDate)")
}

// Add holiday for current year
if let currentYearDate = thanksgiving.dateInYear(currentYear) {
    let holidayForCurrentYear = CalendarHoliday(
        name: thanksgiving.name,
        date: currentYearDate,
        isRecurring: thanksgiving.isRecurring
    )
    yearHolidays.append(holidayForCurrentYear)
    print("Thanksgiving \(currentYear): \(currentYearDate)")
}

// Add holiday for next year
if let nextYearDate = thanksgiving.dateInYear(nextYear) {
    let holidayForNextYear = CalendarHoliday(
        name: thanksgiving.name,
        date: nextYearDate,
        isRecurring: thanksgiving.isRecurring
    )
    yearHolidays.append(holidayForNextYear)
    print("Thanksgiving \(nextYear): \(nextYearDate)")
}

// Test holidaysOn for a specific date - let's use today's date components
let today = Date()
let todayComponents = calendar.dateComponents([.month, .day], from: today)
print("\nToday's components: month=\(todayComponents.month!), day=\(todayComponents.day!)")

// Create a test date for Thanksgiving in current year
let testDate = createDate(month: 11, day: 27, year: currentYear) // Thanksgiving 2024 is Nov 28, so let's test Nov 27
print("Testing date: \(testDate)")

func holidaysOn(_ date: Date, from holidays: [CalendarHoliday]) -> [CalendarHoliday] {
    let matchingHolidays = holidays.filter { $0.occursOn(date) }
    print("Matching holidays before deduplication: \(matchingHolidays.count)")
    for holiday in matchingHolidays {
        print("- \(holiday.name): \(holiday.date)")
    }

    // Remove duplicates by name to avoid showing the same holiday twice
    var seenNames = Set<String>()
    let deduplicated = matchingHolidays.filter { holiday in
        if seenNames.contains(holiday.name) {
            return false
        } else {
            seenNames.insert(holiday.name)
            return true
        }
    }

    print("After deduplication: \(deduplicated.count)")
    return deduplicated
}

let holidaysOnDate = holidaysOn(testDate, from: yearHolidays)
print("Final result: \(holidaysOnDate.count) holidays")


