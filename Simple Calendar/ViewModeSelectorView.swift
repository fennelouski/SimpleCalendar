//
//  ViewModeSelectorView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - View Mode Selector (iOS)
struct ViewModeSelectorView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    /// iOS-specific selectable cases (excludes 7 day and 2 week views on iPhone)
    private var iosSelectableCases: [CalendarViewMode] {
        CalendarViewMode.userSelectableCases.filter { mode in
            mode != .sevenDays && mode != .twoWeeks
        }
    }
    
    var body: some View {
#if os(iOS)
        NavigationView {
            VStack(spacing: 0) {
                // View mode options list
                List {
                    // View mode options (excluding 7 day and 2 week views on iPhone)
                    ForEach(iosSelectableCases, id: \.self) { mode in
                        Button(action: {
                            calendarViewModel.setViewMode(mode)
                            calendarViewModel.showViewModeSelector = false
                        }) {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                Spacer()
                                if calendarViewModel.viewMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentPalette.primary)
                                }
                            }
                        }
                        .listRowBackground(themeManager.currentPalette.surface.opacity(0.5))
                    }
                }
                .listStyle(.insetGrouped)
                
                // Compact year calendar view that extends to the bottom
                CompactYearCalendarView()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxHeight: .infinity) // Fill remaining space
            }
            .navigationTitle("Select View".localized)
            .navigationBarItems(trailing: Button("Done".localized) {
                calendarViewModel.showViewModeSelector = false
            })
            .background(themeManager.currentPalette.calendarBackground)
            .navigationViewStyle(.stack)
        }
#else
        // macOS version - use a simple sheet with blur background
        ZStack {
            // Blurred background
            Color.black.opacity(0.3)
                .blur(radius: 20)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select View".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                
                VStack(spacing: 0) {
                    ForEach(CalendarViewMode.userSelectableCases, id: \.self) { mode in
                        Button(action: {
                            calendarViewModel.setViewMode(mode)
                            calendarViewModel.showViewModeSelector = false
                        }) {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                Spacer()
                                if calendarViewModel.viewMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentPalette.primary)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                        .background(themeManager.currentPalette.surface.opacity(0.5))
                        
                        if mode != CalendarViewMode.userSelectableCases.last {
                            Divider()
                        }
                    }
                }
                .background(themeManager.currentPalette.surface.opacity(0.95))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                Button("Cancel".localized) {
                    calendarViewModel.showViewModeSelector = false
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
            .padding(40)
        }
        .frame(minWidth: 300, minHeight: 400)
#endif
    }
}

#if os(iOS)
/// Compact year calendar shown under the View Mode selector on iOS.
/// - Tapping a date updates the selected date in the main calendar.
/// - Swiping left/right moves the compact view forward/backward by one year.
struct CompactYearCalendarView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    @State private var displayedYear: Int = Calendar(identifier: .gregorian).component(.year, from: Date())
    
    private var displayedYearDate: Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: displayedYear, month: 1, day: 1)) ?? Date()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            let calendar = Calendar(identifier: .gregorian)
            let months: [Date] = (1...12).compactMap { month in
                calendar.date(from: DateComponents(year: displayedYear, month: month, day: 1))
            }
            
            ZStack {
                themeManager.currentPalette.surface
                    .opacity(0.8)
                    .cornerRadius(12)
                
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { changeYear(by: -1) }) {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                        
                        Spacer()
                        
                        Text(formatYear(displayedYear))
                            .font(uiConfig.yearTitleFont)
                            .foregroundColor(themeManager.currentPalette.yearText)
                        
                        Spacer()
                        
                        Button(action: { changeYear(by: 1) }) {
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(months, id: \.self) { monthDate in
                                MonthMiniView(
                                    monthDate: monthDate,
                                    geometry: geometry
                                ) { tappedDate in
                                    // Select the tapped date and close the view mode selector
                                    calendarViewModel.selectDate(tappedDate)
                                    calendarViewModel.showViewModeSelector = false
                                }
                            }
                        }
                        .padding(8)
#if os(iOS)
                        // Add bottom padding to ensure content can scroll above safe area
                        .padding(.bottom, 20)
#endif
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let threshold: CGFloat = 40
                        if value.translation.width < -threshold {
                            // Swipe left -> next year
                            changeYear(by: 1)
                        } else if value.translation.width > threshold {
                            // Swipe right -> previous year
                            changeYear(by: -1)
                        }
                    }
            )
        }
    }
    
    private func changeYear(by delta: Int) {
        displayedYear += delta
    }
    
    /// Format year as a plain string without any grouping separators (commas)
    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? String(year)
    }
}
#endif
