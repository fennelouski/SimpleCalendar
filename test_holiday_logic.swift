import Foundation

let calendar = Calendar.current
let veteransDay2025 = DateComponents(year: 2025, month: 11, day: 11)
let date2025 = calendar.date(from: veteransDay2025)!

print("Veterans Day 2025: \(date2025)")

// Extract components
let components = calendar.dateComponents([.month, .day], from: date2025)
print("Components: month=\(components.month!), day=\(components.day!)")

// Create for 2024
var components2024 = components
components2024.year = 2024
let date2024 = calendar.date(from: components2024)!
print("Veterans Day 2024: \(date2024)")

// Test occursOn
func occursOn(holidayDate: Date, checkDate: Date) -> Bool {
    let holidayComponents = calendar.dateComponents([.month, .day], from: holidayDate)
    let checkComponents = calendar.dateComponents([.month, .day], from: checkDate)
    return holidayComponents.month == checkComponents.month &&
           holidayComponents.day == checkComponents.day
}

let testDate = calendar.date(from: DateComponents(year: 2024, month: 11, day: 11))!
print("Testing if 2025 holiday occurs on 2024-11-11: \(occursOn(holidayDate: date2025, checkDate: testDate))")

let testDate2 = calendar.date(from: DateComponents(year: 2025, month: 11, day: 11))!
print("Testing if 2025 holiday occurs on 2025-11-11: \(occursOn(holidayDate: date2025, checkDate: testDate2))")

// Test with different times
let dateWithTime = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: testDate)!
print("Testing if 2025 holiday occurs on 2024-11-11 12:30: \(occursOn(holidayDate: date2025, checkDate: dateWithTime))")


