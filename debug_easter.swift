import Foundation

// Easter calculation using Meeus/Jones/Butcher algorithm
func easterDate(for year: Int) -> Date? {
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

print("Easter dates:")
for year in 2024...2026 {
    if let date = easterDate(for: year) {
        print("Easter \(year): \(date)")
    }
}

// Known correct dates:
// Easter 2024: March 31, 2024
// Easter 2025: April 20, 2025
// Easter 2026: April 5, 2026



