import Foundation

// Simulate the holiday creation logic
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
            let calendar = Calendar.current
            var components = calendar.dateComponents([.month, .day], from: self.date)
            components.year = year
            return calendar.date(from: components)
        } else {
            return self.date
        }
    }
}

func createDate(month: Int, day: Int, year: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

// Create a sample holiday
let veteransDay = CalendarHoliday(
    name: "Veterans Day",
    date: createDate(month: 11, day: 11, year: 2025),
    isRecurring: true
)

print("Original holiday date: \(veteransDay.date)")

// Simulate creating for different years
let calendar = Calendar.current
let currentYear = calendar.component(.year, from: Date())
let nextYear = currentYear + 1

var yearHolidays: [CalendarHoliday] = []

if let currentYearDate = veteransDay.dateInYear(currentYear) {
    let holidayForCurrentYear = CalendarHoliday(
        name: veteransDay.name,
        date: currentYearDate,
        isRecurring: veteransDay.isRecurring
    )
    yearHolidays.append(holidayForCurrentYear)
    print("Created holiday for \(currentYear): \(currentYearDate)")
}

if let nextYearDate = veteransDay.dateInYear(nextYear) {
    let holidayForNextYear = CalendarHoliday(
        name: veteransDay.name,
        date: nextYearDate,
        isRecurring: veteransDay.isRecurring
    )
    yearHolidays.append(holidayForNextYear)
    print("Created holiday for \(nextYear): \(nextYearDate)")
}

// Test holidaysOn for a specific date
func holidaysOn(_ date: Date, from holidays: [CalendarHoliday]) -> [CalendarHoliday] {
    let matchingHolidays = holidays.filter { $0.occursOn(date) }
    var seenNames = Set<String>()
    return matchingHolidays.filter { holiday in
        if seenNames.contains(holiday.name) {
            return false
        } else {
            seenNames.insert(holiday.name)
            return true
        }
    }
}

let testDate = createDate(month: 11, day: 11, year: currentYear)
print("\nTesting date: \(testDate)")
let holidaysOnDate = holidaysOn(testDate, from: yearHolidays)
print("Holidays found: \(holidaysOnDate.count)")
for holiday in holidaysOnDate {
    print("- \(holiday.name): \(holiday.date)")
}



