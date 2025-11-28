import Foundation

// Test the fixed occursOn method
struct CalendarHoliday {
    let name: String
    let date: Date
    let isRecurring: Bool

    func occursOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        // For both recurring and fixed holidays, check if they occur on the same day
        return calendar.isDate(self.date, inSameDayAs: date)
    }
}

func createDate(month: Int, day: Int, year: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

// Create Thanksgiving holidays for different years
let thanksgiving2024 = CalendarHoliday(
    name: "Thanksgiving",
    date: createDate(month: 11, day: 28, year: 2024),
    isRecurring: true
)

let thanksgiving2025 = CalendarHoliday(
    name: "Thanksgiving",
    date: createDate(month: 11, day: 27, year: 2025),
    isRecurring: true
)

let thanksgiving2026 = CalendarHoliday(
    name: "Thanksgiving",
    date: createDate(month: 11, day: 26, year: 2026),
    isRecurring: true
)

let holidays = [thanksgiving2024, thanksgiving2025, thanksgiving2026]

print("Testing occursOn fix:")
print("Thanksgiving 2024 date: \(thanksgiving2024.date)")
print("Thanksgiving 2025 date: \(thanksgiving2025.date)")
print("Thanksgiving 2026 date: \(thanksgiving2026.date)")

// Test each date
let testDates = [
    createDate(month: 11, day: 26, year: 2025), // Should NOT match any
    createDate(month: 11, day: 27, year: 2025), // Should match 2025 Thanksgiving
    createDate(month: 11, day: 28, year: 2025), // Should match 2024 Thanksgiving
    createDate(month: 11, day: 26, year: 2026), // Should match 2026 Thanksgiving
]

for testDate in testDates {
    print("\nTesting date: \(testDate)")
    let matching = holidays.filter { $0.occursOn(testDate) }
    print("Matching holidays: \(matching.count)")
    for holiday in matching {
        print("- \(holiday.name) (\(holiday.date))")
    }
}



