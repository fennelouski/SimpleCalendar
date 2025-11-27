import Foundation

// Simulate the full holiday manager to see what's happening
class HolidayManager {
    static let shared = HolidayManager()

    var holidays: [CalendarHoliday] = []

    private let allHolidays: [CalendarHoliday] = [
        CalendarHoliday(name: "Thanksgiving", date: Date(), emoji: "🦃", description: "", unsplashSearchTerm: "", isRecurring: true, category: .cultural)
    ]

    private init() {
        print("HolidayManager initialized")
        loadHolidaysForCurrentYear()
    }

    private func loadHolidaysForCurrentYear() {
        print("Loading holidays for current year")
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let previousYear = currentYear - 1
        let nextYear = currentYear + 1

        print("Years: prev=\(previousYear), current=\(currentYear), next=\(nextYear)")

        var yearHolidays: [CalendarHoliday] = []

        for holiday in allHolidays {
            // Add holiday for previous year
            if let previousYearDate = holiday.dateInYear(previousYear) {
                let holidayForPreviousYear = CalendarHoliday(
                    name: holiday.name,
                    date: previousYearDate,
                    emoji: holiday.emoji,
                    description: holiday.description,
                    unsplashSearchTerm: holiday.unsplashSearchTerm,
                    isRecurring: holiday.isRecurring,
                    category: holiday.category
                )
                yearHolidays.append(holidayForPreviousYear)
                print("Added \(holiday.name) for \(previousYear): \(previousYearDate)")
            }

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
                print("Added \(holiday.name) for \(currentYear): \(currentYearDate)")
            }

            // Add holiday for next year
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
                print("Added \(holiday.name) for \(nextYear): \(nextYearDate)")
            }
        }

        self.holidays = yearHolidays.sorted(by: { $0.date < $1.date })
        print("Total holidays loaded: \(self.holidays.count)")
    }

    func holidaysOn(_ date: Date) -> [CalendarHoliday] {
        let matchingHolidays = holidays.filter { $0.occursOn(date) }
        print("holidaysOn called for date: \(date)")
        print("Total holidays in manager: \(holidays.count)")
        print("Matching holidays: \(matchingHolidays.count)")

        for holiday in matchingHolidays {
            print("- \(holiday.name): \(holiday.date)")
        }

        // Remove duplicates by name
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
}

struct CalendarHoliday {
    let name: String
    let date: Date
    let emoji: String
    let description: String
    let unsplashSearchTerm: String
    let isRecurring: Bool
    let category: CalendarHolidayCategory

    enum CalendarHolidayCategory: String {
        case cultural
    }

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

        var components = DateComponents()
        components.year = year
        components.month = 11
        components.day = 1

        guard let startOfNovember = calendar.date(from: components) else { return nil }

        let weekdayOfFirst = calendar.component(.weekday, from: startOfNovember)
        let daysToThursday = (5 - weekdayOfFirst + 7) % 7
        let firstThursday = calendar.date(byAdding: .day, value: daysToThursday, to: startOfNovember)!

        let fourthThursday = calendar.date(byAdding: .day, value: 21, to: firstThursday)!

        return fourthThursday
    }
}

// Test the HolidayManager
print("=== Testing HolidayManager ===")
let manager = HolidayManager.shared
print("Manager holidays count: \(manager.holidays.count)")

// Test for Thanksgiving 2025
let calendar = Calendar.current
var testComponents = DateComponents()
testComponents.year = 2025
testComponents.month = 11
testComponents.day = 27 // Thanksgiving 2025
let testDate = calendar.date(from: testComponents)!

print("\n=== Testing holidaysOn for Thanksgiving 2025 ===")
let result = manager.holidaysOn(testDate)
print("Result count: \(result.count)")

// Test for multiple dates around Thanksgiving
print("\n=== Testing multiple dates around Thanksgiving ===")
for day in 25...29 {
    testComponents.day = day
    let date = calendar.date(from: testComponents)!
    let holidays = manager.holidaysOn(date)
    print("November \(day), 2025: \(holidays.count) holidays")
    for holiday in holidays {
        print("  - \(holiday.name)")
    }
}


