import Foundation

func createDate(month: Int, day: Int, year: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

// Test creating dates for different years
let christmas2024 = createDate(month: 12, day: 25, year: 2024)
let christmas2025 = createDate(month: 12, day: 25, year: 2025)

print("Christmas 2024: \(christmas2024)")
print("Christmas 2025: \(christmas2025)")

// Test dateInYear logic
func dateInYear(originalDate: Date, year: Int) -> Date? {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.month, .day], from: originalDate)
    components.year = year
    return calendar.date(from: components)
}

if let christmas2024_recalc = dateInYear(originalDate: christmas2025, year: 2024) {
    print("Christmas 2024 recalculated: \(christmas2024_recalc)")
    print("Equal to original 2024: \(christmas2024 == christmas2024_recalc)")
}

// Test occursOn
func occursOn(holidayDate: Date, checkDate: Date) -> Bool {
    let calendar = Calendar.current
    let holidayComponents = calendar.dateComponents([.month, .day], from: holidayDate)
    let checkComponents = calendar.dateComponents([.month, .day], from: checkDate)
    return holidayComponents.month == checkComponents.month &&
           holidayComponents.day == checkComponents.day
}

let testDate = createDate(month: 12, day: 25, year: 2024)
print("Testing if Christmas 2025 occurs on 2024-12-25: \(occursOn(holidayDate: christmas2025, checkDate: testDate))")

// Test with timezone
print("Current timezone: \(TimeZone.current)")
print("Calendar timezone: \(Calendar.current.timeZone)")

// Test if dates are in same day
let calendar = Calendar.current
print("isDate same day: \(calendar.isDate(christmas2024, inSameDayAs: testDate))")



