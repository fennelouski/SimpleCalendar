import Foundation

class MockCalendarViewModel {
    var currentDate: Date = Date()
    var selectedDate: Date?
    
    enum NavigationDirection {
        case forward, backward
    }
    
    enum NavigationUnit {
        case day, week, month
    }
    
    func navigateDate(by unit: NavigationUnit, direction: NavigationDirection) {
        let calendar = Calendar.current
        let multiplier = direction == .forward ? 1 : -1

        switch unit {
        case .day:
            if let newDate = calendar.date(byAdding: .day, value: multiplier, to: currentDate) {
                currentDate = newDate
            }
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: multiplier, to: currentDate) {
                currentDate = newDate
            }
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: multiplier, to: currentDate) {
                currentDate = newDate
            }
        }
    }
    
    func moveUpOneWeek() {
        if let selectedDate = selectedDate,
           let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) {
            self.selectedDate = newDate
            ensureSelectedDateIsVisible()
        }
    }
    
    private func ensureSelectedDateIsVisible() {
        guard let selectedDate = selectedDate else { return }
        alignCurrentDateWithSelectionIfNeeded(selectedDate)
    }
    
    private func alignCurrentDateWithSelectionIfNeeded(_ date: Date) {
        let calendar = Calendar.current
        // For day-based views (default case)
        if !calendar.isDate(currentDate, inSameDayAs: date) {
            currentDate = date
        }
    }
}

let calendar = Calendar.current
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd EEEE"

// Test the navigation
let viewModel = MockCalendarViewModel()
viewModel.currentDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
viewModel.selectedDate = viewModel.currentDate

print("Initial state:")
print("currentDate: \(formatter.string(from: viewModel.currentDate))")
print("selectedDate: \(formatter.string(from: viewModel.selectedDate!))")

// Test moveUpOneWeek
print("\nCalling moveUpOneWeek():")
viewModel.moveUpOneWeek()
print("After moveUpOneWeek:")
print("currentDate: \(formatter.string(from: viewModel.currentDate))")
print("selectedDate: \(formatter.string(from: viewModel.selectedDate!))")

// Test navigateDate with week
print("\nCalling navigateDate(by: .week, direction: .backward):")
viewModel.navigateDate(by: .week, direction: .backward)
print("After navigateDate week backward:")
print("currentDate: \(formatter.string(from: viewModel.currentDate))")
print("selectedDate: \(formatter.string(from: viewModel.selectedDate!))")
