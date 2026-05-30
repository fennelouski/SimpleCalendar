//
//  MonthMiniView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct MonthMiniView: View {
    let monthDate: Date
    let geometry: GeometryProxy
    /// Optional callback when a specific day in this mini-month is tapped.
    /// If nil, taps on days are ignored (used by year view).
    let onDayTap: ((Date) -> Void)?
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared
    
    private var monthlyPalette: ColorPalette {
        if featureFlags.monthlyThemesEnabled {
            let month = Calendar(identifier: .gregorian).component(.month, from: monthDate)
            let monthlyTheme = monthlyThemeManager.theme(for: month)
            return monthlyTheme.palette(for: themeManager.currentColorScheme)
        } else {
            return themeManager.currentPalette
        }
    }
    
    init(monthDate: Date, geometry: GeometryProxy, onDayTap: ((Date) -> Void)? = nil) {
        self.monthDate = monthDate
        self.geometry = geometry
        self.onDayTap = onDayTap
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Month name
            Text(monthDate.formatted(.dateTime.month(.wide)))
                .font(uiConfig.captionFont)
                .fontWeight(.semibold)
                .foregroundColor(monthlyPalette.textPrimary)
            
            // Mini calendar grid
            let monthDays = generateMiniMonthDays(for: monthDate)
            let miniColumns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
            
            LazyVGrid(columns: miniColumns, spacing: 1) {
                ForEach(monthDays) { day in
                    let base = Text(day.date.formatted(.dateTime.day()))
                        .font(.system(size: 8))
                        .foregroundColor(day.isCurrentMonth ?
                                         (day.isToday ? monthlyPalette.accent : monthlyPalette.textPrimary) :
                                            monthlyPalette.textSecondary.opacity(0.5))
                        .frame(width: 12, height: 12)
                        .background(day.isToday ? monthlyPalette.accent.opacity(0.2) : Color.clear)
                        .cornerRadius(2)
                    
                    if let onDayTap = onDayTap {
                        base
                            .frame(minWidth: 20, minHeight: 20) // Larger tap area
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onDayTap(day.date)
                            }
                    } else {
                        base
                    }
                }
            }
        }
        .padding(6)
        .background(monthlyPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small.value))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small.value)
                .stroke(monthlyPalette.gridLine, lineWidth: 0.5)
        )
    }
    
    private func generateMiniMonthDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysFromPreviousMonth = firstWeekday - calendar.firstWeekday
        let totalCells = 42 // 6 weeks * 7 days for consistent mini calendar size
        
        var days: [CalendarDay] = []
        
        // Previous month days
        if daysFromPreviousMonth > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            
            for i in (daysInPreviousMonth - daysFromPreviousMonth + 1)...daysInPreviousMonth {
                if let date = calendar.date(bySetting: .day, value: i, of: previousMonth) {
                    let dayStart = calendar.startOfDay(for: date)
                    let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == dayStart } ?? false
                    days.append(CalendarDay(id: dayStart, date: dayStart, isToday: false, isSelected: isSelected, events: [], isCurrentMonth: false))
                }
            }
        }
        
        // Current month days
        for day in 1...range.count {
            if let date = calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                let dayStart = calendar.startOfDay(for: date)
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == dayStart } ?? false
                days.append(CalendarDay(id: dayStart, date: dayStart, isToday: isToday, isSelected: isSelected, events: [], isCurrentMonth: true))
            }
        }
        
        // Next month days to fill the grid
        let remainingCells = totalCells - days.count
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        for day in 1...remainingCells {
            if let date = calendar.date(bySetting: .day, value: day, of: nextMonth) {
                let dayStart = calendar.startOfDay(for: date)
                let isSelected = calendarViewModel.selectedDate.map { calendar.startOfDay(for: $0) == dayStart } ?? false
                days.append(CalendarDay(id: dayStart, date: dayStart, isToday: false, isSelected: isSelected, events: [], isCurrentMonth: false))
            }
        }
        
        return days
    }
}
