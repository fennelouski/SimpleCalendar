//
//  SettingsView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
#if !os(tvOS)
import EventKit
#endif
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var showSettings = false
    
    var body: some View {
        EmptyView()
            .sheet(isPresented: $showSettings) {
                SettingsContentView(showSettings: $showSettings, googleOAuthManager: calendarViewModel.googleOAuthManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("ShowSettings"))) { _ in
                showSettings = true
            }
    }
}

struct SettingsContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var holidayCategoryManager = HolidayCategoryManager.shared
    @Binding var showSettings: Bool
    @FocusState private var focusedTheme: ColorTheme?
    @State private var showAboutView = false
    @State private var preservedFocusedCategory: CalendarHoliday.CalendarHolidayCategory? = nil
    @State private var focusRestoreTrigger: UUID = UUID()
    var googleOAuthManager: GoogleOAuthManager?
    
    var body: some View {
        ZStack {
            themeManager.currentPalette.calendarBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Sticky Header
                VStack(spacing: 0) {
                    HStack {
#if os(tvOS)
                        Spacer()
#endif
                        Text("Settings".localized)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                        Spacer()
#if !os(tvOS)
                        Button("Done".localized) {
                            showSettings = false
                        }
                        .foregroundColor(themeManager.currentPalette.primary)
#endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(themeManager.currentPalette.background.opacity(0.95))
                }
                
                ScrollView {
                    VStack(spacing: 24) {
#if !os(tvOS)
                        // Calendar Integration Section (iOS/macOS only)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calendar Integration".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)
                            
                            // iOS/macOS: Full calendar integration settings
                            VStack(spacing: 0) {
#if !os(tvOS)
                                // System Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("System Calendar".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text("Sync with macOS Calendar".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Could show info popover here
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }
                                    
                                    Toggle("", isOn: Binding(
                                        get: { 
                                            EKEventStore.authorizationStatus(for: .event) == .fullAccess || 
                                            EKEventStore.authorizationStatus(for: .event) == .authorized 
                                        },
                                        set: { newValue in
                                            if newValue {
                                                calendarViewModel.requestCalendarAccess()
                                            } else {
                                                #if os(iOS)
                                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                                    UIApplication.shared.open(url)
                                                }
                                                #elseif os(macOS)
                                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                                                    NSWorkspace.shared.open(url)
                                                }
                                                #endif
                                            }
                                        }
                                    ))
                                        .labelsHidden()
                                        .accessibilityLabel("Sync System Calendar".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
#endif
                                
                                // Google Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Google Calendar".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text(googleOAuthManager?.isAuthenticated ?? false ?
                                             "Signed in as %@".localized(with: googleOAuthManager?.userEmail ?? "Unknown") :
                                                "Connect your Google Calendar".localized)
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                        .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Could show info popover here
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }
                                    
                                    Toggle("", isOn: Binding(
                                        get: { googleOAuthManager?.isAuthenticated ?? false },
                                        set: { newValue in
                                            if newValue {
                                                googleOAuthManager?.signIn()
                                            } else {
                                                googleOAuthManager?.signOut()
                                            }
                                        }
                                    ))
                                        .labelsHidden()
                                        .accessibilityLabel("Sync Google Calendar".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
#endif
                        
                        // Holiday Display Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Holiday Display".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
#if os(tvOS)
                                // tvOS: Toggleable holiday display setting
                                SettingsRowView(
                                    title: "Show Holidays".localized,
                                    description: featureFlags.holidayDisplayEnabled ? "Enabled - Display holidays on the calendar".localized : "Disabled - Hide holidays on the calendar".localized,
                                    icon: featureFlags.holidayDisplayEnabled ? "checkmark.circle.fill" : "xmark.circle.fill",
                                    iconColor: featureFlags.holidayDisplayEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary.opacity(0.5),
                                    themeManager: themeManager
                                ) {
                                    featureFlags.holidayDisplayEnabled.toggle()
                                    NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                }
                                
                                Divider()
                                


                                // tvOS: Background Animations setting
                                SettingsRowView(
                                    title: "Background Animations".localized,
                                    description: featureFlags.backgroundAnimationsEnabled ? "Enabled - Show seasonal animations behind the calendar".localized : "Disabled - No background animations".localized,
                                    icon: featureFlags.backgroundAnimationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill",
                                    iconColor: featureFlags.backgroundAnimationsEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary.opacity(0.5),
                                    themeManager: themeManager
                                ) {
                                    featureFlags.backgroundAnimationsEnabled.toggle()
                                }
#else
                                // iOS/macOS: Separate info button and toggle
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Show Holidays".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text("Display holidays on the calendar with educational information".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Could show info popover here
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }
                                    
                                    Toggle("", isOn: Binding(
                                        get: { featureFlags.holidayDisplayEnabled },
                                        set: { featureFlags.holidayDisplayEnabled = $0 }
                                    ))
                                    .labelsHidden()
                                    .accessibilityLabel("Show Holidays".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                
                                // iOS/macOS: Monthly themes setting
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Monthly Themes".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text("Use different colors for each month to help understand calendar concepts".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { featureFlags.monthlyThemesEnabled },
                                        set: { featureFlags.monthlyThemesEnabled = $0 }
                                    ))
                                    .labelsHidden()
                                    .accessibilityLabel("Monthly Themes".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                // Automatic Unsplash Images
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Automatic Backgrounds".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text("Automatically set a beautiful background image from Unsplash".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { featureFlags.automaticUnsplashImages },
                                        set: { newValue in
                                            featureFlags.automaticUnsplashImages = newValue
                                            if newValue {
                                                NotificationCenter.default.post(name: Notification.Name("FetchUnsplashImage"), object: nil)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .accessibilityLabel("Automatic Backgrounds".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                // Background Animations
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Background Animations".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text("Show seasonal animations behind the calendar in month view".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { featureFlags.backgroundAnimationsEnabled },
                                        set: { featureFlags.backgroundAnimationsEnabled = $0 }
                                    ))
                                    .labelsHidden()
                                    .accessibilityLabel("Background Animations".localized)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                
                                // Holiday Guide Button - Coming Soon
                                Button(action: {
                                    // Holiday guide coming soon
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Holiday Guide".localized)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.6))
                                                .lineLimit(nil)
                                            
                                            Text("Learn about holidays and their meanings (Coming Soon)".localized)
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.5))
                                                .lineLimit(nil)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.3))
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
#endif
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                        
                        // Holiday Categories Section
                        if featureFlags.holidayDisplayEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Holiday Categories".localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 0) {
                                    ForEach(CalendarHoliday.CalendarHolidayCategory.allCases, id: \.self) { category in
                                        HolidayCategoryToggleRow(
                                            category: category,
                                            holidayCategoryManager: holidayCategoryManager,
                                            themeManager: themeManager,
                                            shouldRestoreFocus: preservedFocusedCategory == category,
                                            focusRestoreTrigger: focusRestoreTrigger,
                                            onFocusChange: { newCategory in
                                                preservedFocusedCategory = newCategory
                                            },
                                            onToggle: {
                                                // Trigger focus restoration after toggle
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    focusRestoreTrigger = UUID()
                                                }
                                            }
                                        )
                                        
                                        if category != CalendarHoliday.CalendarHolidayCategory.allCases.last {
                                            Divider()
                                        }
                                    }
                                }
                                .background(themeManager.currentPalette.surface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        
                        // Appearance Section (combined)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // Day Number Font Size
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Day Number Size".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                        
                                        Text("Adjust the size of day numbers in the calendar".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
#if os(tvOS)
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            let currentIndex = Int((uiConfig.dayNumberFontSize - 8) / 12)
                                            let newIndex = max(0, currentIndex - 1)
                                            uiConfig.dayNumberFontSize = 8 + Double(newIndex * 12)
                                            NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22.5)) // 25% smaller than .title (30pt)
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        Text("\(Int(uiConfig.dayNumberFontSize))pt")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .frame(minWidth: 40, alignment: .center)
                                        
                                        Button(action: {
                                            let currentIndex = Int((uiConfig.dayNumberFontSize - 8) / 12)
                                            let newIndex = min(6, currentIndex + 1) // 6 steps: 8,20,32,44,56,68,80
                                            uiConfig.dayNumberFontSize = 8 + Double(newIndex * 12)
                                            NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22.5)) // 25% smaller than .title (30pt)
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
#else
                                    Slider(value: Binding(
                                        get: { uiConfig.dayNumberFontSize },
                                        set: { uiConfig.dayNumberFontSize = $0 }
                                    ), in: 10...24, step: 1)
                                    .tint(themeManager.currentPalette.primary)
                                    .frame(width: 120)
#endif
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                
                                // Color Saturation
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Color Saturation".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                        
                                        Text("Adjust color intensity (0% - 200%)".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
#if os(tvOS)
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            themeManager.saturation = max(0.0, themeManager.saturation - 0.1)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22.5))
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        Text("\(Int(round(themeManager.saturation * 100)))%")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .frame(minWidth: 50, alignment: .center)
                                        
                                        Button(action: {
                                            themeManager.saturation = min(2.0, themeManager.saturation + 0.1)
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22.5))
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
#else
                                    Slider(value: Binding(
                                        get: { themeManager.saturation },
                                        set: { themeManager.saturation = $0 }
                                    ), in: 0.0...2.0)
                                    .tint(themeManager.currentPalette.primary)
                                    .frame(width: 120)
#endif
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
#if !os(tvOS)
                                Divider()
                                
                                // Monthly Theme Setting (iOS/macOS)
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Monthly Theme".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)
                                        
                                        Text(featureFlags.useMonthlyThemeMode ? "Theme changes automatically each month".localized : "Use a fixed theme".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { featureFlags.useMonthlyThemeMode },
                                        set: { newValue in
                                            withAnimation {
                                                if newValue {
                                                    // Enabling monthly theme mode - save current theme as manual, then apply monthly theme
                                                    featureFlags.useMonthlyThemeMode = true
                                                    themeManager.saveCurrentThemeAsManual()
                                                    let calendar = Calendar(identifier: .gregorian)
                                                    let month = calendar.component(.month, from: calendarViewModel.currentDate)
                                                    let monthlyTheme = CalendarViewModel.monthlyThemeForMonth(month)
                                                    themeManager.setTheme(monthlyTheme)
                                                } else {
                                                    // Disabling monthly theme mode - restore the last manually selected theme
                                                    featureFlags.useMonthlyThemeMode = false
                                                    themeManager.restoreLastManualTheme()
                                                }
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
#endif
                                
#if os(tvOS)
                                Divider()
                                
                                // Border Contrast Setting
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Border Contrast".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                        
                                        Text("Adjust the contrast of day square borders".localized)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            uiConfig.gridLineOpacity = max(0.1, uiConfig.gridLineOpacity - 0.1)
                                            NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22.5)) // 25% smaller than .title (30pt)
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        Text("\(Int(uiConfig.gridLineOpacity * 100))%")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .frame(minWidth: 40, alignment: .center)
                                        
                                        Button(action: {
                                            uiConfig.gridLineOpacity = min(1.0, uiConfig.gridLineOpacity + 0.1)
                                            NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22.5)) // 25% smaller than .title (30pt)
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                
                                // Weekend Tinting Setting (tvOS only)
                                SettingsRowView(
                                    title: "Weekend Tinting".localized,
                                    description: featureFlags.weekendTintingEnabled ? "Enabled - Weekends are visually distinguished".localized : "Disabled - All days look the same".localized,
                                    icon: featureFlags.weekendTintingEnabled ? "checkmark.circle.fill" : "xmark.circle.fill",
                                    iconColor: featureFlags.weekendTintingEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary.opacity(0.5),
                                    themeManager: themeManager
                                ) {
                                    featureFlags.weekendTintingEnabled.toggle()
                                    NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                                }
                                
                                Divider()
                                
                                // Monthly Theme Setting (tvOS only)
                                SettingsRowView(
                                    title: "Monthly Theme".localized,
                                    description: featureFlags.useMonthlyThemeMode ? "Enabled - Theme changes automatically each month".localized : "Disabled - Use a fixed theme".localized,
                                    icon: featureFlags.useMonthlyThemeMode ? "checkmark.circle.fill" : "circle",
                                    iconColor: featureFlags.useMonthlyThemeMode ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary,
                                    themeManager: themeManager
                                ) {
                                    withAnimation {
                                        if featureFlags.useMonthlyThemeMode {
                                            // Disabling monthly theme mode - restore the last manually selected theme
                                            featureFlags.useMonthlyThemeMode = false
                                            themeManager.restoreLastManualTheme()
                                        } else {
                                            // Enabling monthly theme mode - save current theme as manual, then apply monthly theme
                                            featureFlags.useMonthlyThemeMode = true
                                            themeManager.saveCurrentThemeAsManual()
                                            let calendar = Calendar(identifier: .gregorian)
                                            let month = calendar.component(.month, from: calendarViewModel.currentDate)
                                            let monthlyTheme = CalendarViewModel.monthlyThemeForMonth(month)
                                            themeManager.setTheme(monthlyTheme)
                                        }
                                    }
                                }
#endif
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                        
#if os(tvOS)
                        // Theme Selection Section (tvOS only) - Only show when Monthly Theme is disabled
                        if !featureFlags.useMonthlyThemeMode {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Theme".localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 0) {
                                    // Theme Picker
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Color Theme".localized)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                                
                                                Text("Choose your preferred color scheme".localized)
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.currentPalette.textSecondary)
                                                    .lineLimit(nil)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(themeManager.currentTheme.displayName)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.primary)
                                        }
                                        
                                        // Theme selection for tvOS
                                        VStack(spacing: 16) {
                                            // Theme grid - 3 columns for better fit
                                            LazyVGrid(columns: [
                                                GridItem(.flexible(), spacing: 12),
                                                GridItem(.flexible(), spacing: 12),
                                                GridItem(.flexible(), spacing: 12)
                                            ], spacing: 12) {
                                                ForEach(ColorTheme.allCases, id: \.self) { theme in
                                                    ThemeCard(
                                                        theme: theme,
                                                        isSelected: themeManager.currentTheme == theme,
                                                        isFocused: focusedTheme == theme,
                                                        focusedTheme: $focusedTheme
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .background(themeManager.currentPalette.surface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Go to Today Button (tvOS only)
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(spacing: 0) {
                                SettingsRowView(
                                    title: "Go to Today".localized,
                                    description: "Move the selected date to today".localized,
                                    icon: "calendar",
                                    iconColor: themeManager.currentPalette.primary,
                                    themeManager: themeManager
                                ) {
                                    calendarViewModel.navigateToToday()
                                }
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
#endif
                        
                        // About Section (moved to bottom)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // Version
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Version".localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                        
                                        Text("Calendar Play 1.0.0")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                
                                // About the App
#if os(tvOS)
                                // tvOS: Entire row is clickable
                                AboutAppRowView(themeManager: themeManager) {
                                    showAboutView = true
                                }
#else
                                // iOS/macOS: Button with separate info button
                                Button(action: {
                                    showAboutView = true
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("About the App".localized)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)
                                            
                                            Text("Why I built this calendar".localized)
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showAboutView = true
                                        }) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .font(.system(size: 16))
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
#endif
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
#if os(iOS)
                    .padding(.bottom, 40) // Extra bottom padding to ensure content can scroll above safe area
#endif
                }
            }
        }
        .sheet(isPresented: $showAboutView) {
            AboutView(showAboutView: $showAboutView)
        }
    }
    
}

// MARK: - About View
struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showAboutView: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
#if os(tvOS)
                let spacing0: CGFloat = 2
                let spacing1: CGFloat = 4
                let spacing2: CGFloat = 8
                let spacing3: CGFloat = 12
                let spacing4: CGFloat = 16
                let spacing5: CGFloat = 20
                let spacing6: CGFloat = 24
                let spacing7: CGFloat = 28
                let spacing8: CGFloat = 32
                let spacing9: CGFloat = 36
                let spacing10: CGFloat = 40
#else
                let spacing0: CGFloat = 4
                let spacing1: CGFloat = 8
                let spacing2: CGFloat = 16
                let spacing3: CGFloat = 24
                let spacing4: CGFloat = 32
                let spacing5: CGFloat = 40
                let spacing6: CGFloat = 48
                let spacing7: CGFloat = 56
                let spacing8: CGFloat = 64
                let spacing9: CGFloat = 72
                let spacing10: CGFloat = 80
#endif
                VStack(spacing: spacing3) {
                    // Header
                    VStack(spacing: spacing2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 144))
                            .foregroundColor(themeManager.currentPalette.primary)
                        
                        Spacer()
                        
                        Text("About Calendar Play".localized)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Spacer()
                    }
                    .padding(.top, spacing3)
                    // Description
                    VStack(alignment: .leading, spacing: spacing3) {
                        Text("Calendar Play is designed to help children and learners of all ages understand calendar concepts. The app focuses on accessibility and education, making it easy to visualize time, dates, and calendar relationships.".localized)
                            .font(.body)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                            .lineSpacing(spacing0)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, spacing6)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: spacing1) {
                        Text("Made for learning and accessibility".localized)
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("© 2025 100Apps.Studio")
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                        
                        Text("Version 1.0")
                            .font(.caption2)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    .padding(.top, spacing2)
                    .padding(.bottom, spacing5)
                }
            }
            .background(themeManager.currentPalette.calendarBackground)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        showAboutView = false
                    }
                    .foregroundColor(themeManager.currentPalette.primary)
                }
#endif
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(themeManager.currentPalette.primary)
                .font(.body)
            Text(text)
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .font(.body)
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentPalette.primary)
                .font(.system(size: 14))
                .frame(width:16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }
}

// MARK: - tvOS Settings Row Components
#if os(tvOS)
struct AboutAppRowView: View {
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("About the App".localized)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(nil)
                
                Text("Why I built this calendar".localized)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .font(.system(size: 16))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? themeManager.currentPalette.primary.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? themeManager.currentPalette.primary : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            action()
        }
    }
}

struct SettingsRowView: View {
    let title: String
    let description: String
    let icon: String?
    let iconColor: Color?
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        description: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        themeManager: ThemeManager,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.iconColor = iconColor
        self.themeManager = themeManager
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(nil)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor ?? themeManager.currentPalette.textSecondary)
                    .font(.system(size: 24))
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? themeManager.currentPalette.primary.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? themeManager.currentPalette.primary : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            action()
        }
    }
}
#endif

// MARK: - Holiday Category Toggle Row
struct HolidayCategoryToggleRow: View {
    let category: CalendarHoliday.CalendarHolidayCategory
    @ObservedObject var holidayCategoryManager: HolidayCategoryManager
    @ObservedObject var themeManager: ThemeManager
    var shouldRestoreFocus: Bool
    var focusRestoreTrigger: UUID
    var onFocusChange: ((CalendarHoliday.CalendarHolidayCategory?) -> Void)?
    var onToggle: (() -> Void)?
    
    private var isEnabled: Bool {
        holidayCategoryManager.enabledCategories.contains(category)
    }
    
    private var categoryBinding: Binding<Bool> {
        Binding(
            get: {
                holidayCategoryManager.enabledCategories.contains(category)
            },
            set: { newValue in
                if newValue {
                    holidayCategoryManager.enable(category)
                } else {
                    holidayCategoryManager.disable(category)
                }
                onToggle?()
                NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
                HolidayManager.shared.refreshHolidaysIfNeeded()
            }
        )
    }
    
#if os(tvOS)
    @FocusState private var isFocused: Bool
    @State private var lastRestoreTrigger: UUID?
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(nil)
                
                Text(categoryDescription(for: category))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary)
                .font(.system(size: 24))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? themeManager.currentPalette.primary.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? themeManager.currentPalette.primary : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue {
                onFocusChange?(category)
            }
        }
        .onChange(of: focusRestoreTrigger) { oldValue, trigger in
            if shouldRestoreFocus && trigger != lastRestoreTrigger && !isFocused {
                lastRestoreTrigger = trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
        .onTapGesture {
            categoryBinding.wrappedValue.toggle()
        }
    }
#else
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(nil)
                
                Text(categoryDescription(for: category))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            Toggle("", isOn: categoryBinding)
                .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
#endif
    
    private func categoryDescription(for category: CalendarHoliday.CalendarHolidayCategory) -> String {
        switch category {
        case .bankHolidays:
            return "New Year's Day, Labor Day, Thanksgiving, etc.".localized
        case .uniqueHolidays:
            return "National Donut Day, Talk Like a Pirate Day, etc.".localized
        case .awarenessDays:
            return "Awareness days and months".localized
        case .seasons:
            return "First day of spring, summer, etc.".localized
        case .christianHolidays:
            return "Christmas, Easter, Good Friday, etc.".localized
        case .jewishHolidays:
            return "Hanukkah, Rosh Hashanah, Passover, etc.".localized
        case .otherHolidays:
            return "Other holidays like Diwali and Kwanzaa".localized
        }
    }
}

// Extension to add settings notification
extension Notification.Name {
    static let ShowSettings = Notification.Name("ShowSettings")
}



