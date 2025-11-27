//
//  SettingsView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

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
    @EnvironmentObject var featureFlags: FeatureFlags
    @Binding var showSettings: Bool
    @FocusState private var focusedTheme: ColorTheme?
    @State private var showAboutView = false
    var googleOAuthManager: GoogleOAuthManager?

    var body: some View {
        ZStack {
            themeManager.currentPalette.calendarBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Settings")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                        Spacer()
                        #if !os(tvOS)
                        Button("Done") {
                            showSettings = false
                        }
                        .foregroundColor(themeManager.currentPalette.primary)
                        #endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(themeManager.currentPalette.calendarSurface.opacity(0.95))
                }

                ScrollView {
                    VStack(spacing: 24) {
                        #if !os(tvOS)
                        // Calendar Integration Section (iOS/macOS only)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calendar Integration")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            // iOS/macOS: Full calendar integration settings
                            VStack(spacing: 0) {
                                // System Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("System Calendar")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text("Sync with macOS Calendar")
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

                                    Toggle("", isOn: .constant(true))
                                        .disabled(true)
                                        .labelsHidden()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                // Google Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Google Calendar")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text(googleOAuthManager?.isAuthenticated ?? false ?
                                            "Signed in as \(googleOAuthManager?.userEmail ?? "Unknown")" :
                                            "Connect your Google Calendar")
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

                                    Toggle("", isOn: .constant(googleOAuthManager?.isAuthenticated ?? false))
                                        .disabled(true)
                                        .labelsHidden()
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
                            Text("Holiday Display")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                #if os(tvOS)
                                // tvOS: Toggleable holiday display setting
                                Button(action: {
                                    featureFlags.holidayDisplayEnabled.toggle()
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Show Holidays")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text(featureFlags.holidayDisplayEnabled ? "Enabled - Display holidays on the calendar" : "Disabled - Hide holidays on the calendar")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }

                                        Spacer()

                                        Image(systemName: featureFlags.holidayDisplayEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(featureFlags.holidayDisplayEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary.opacity(0.5))
                                            .font(.system(size: 24))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .focusable()
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                #else
                                // iOS/macOS: Separate info button and toggle
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Show Holidays")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text("Display holidays on the calendar with educational information")
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
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                #if os(tvOS)
                                // tvOS: Monthly themes setting
                                Button(action: {
                                    featureFlags.monthlyThemesEnabled.toggle()
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Monthly Themes")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text("Use different colors for each month to help understand calendar concepts")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }

                                        Spacer()

                                        Image(systemName: featureFlags.monthlyThemesEnabled ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(featureFlags.monthlyThemesEnabled ? themeManager.currentPalette.primary : themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 20))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                #else
                                // iOS/macOS: Monthly themes setting
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Monthly Themes")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text("Use different colors for each month to help understand calendar concepts")
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
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                #endif

                                Divider()

                                // Holiday Guide Button - Coming Soon
                                Button(action: {
                                    // Holiday guide coming soon
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Holiday Guide")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textSecondary.opacity(0.6))
                                                .lineLimit(nil)

                                            Text("Learn about holidays and their meanings (Coming Soon)")
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


                        // Appearance Section (combined)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Day Number Font Size
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Day Number Size")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)

                                        Text("Adjust the size of day numbers in the calendar")
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

                                #if os(tvOS)
                                Divider()

                                // Border Contrast Setting
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Border Contrast")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)

                                        Text("Adjust the contrast of day square borders")
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
                                #endif
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }

                        #if os(tvOS)
                        // Theme Selection Section (tvOS only)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Theme")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Theme Picker
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Color Theme")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)

                                            Text("Choose your preferred color scheme")
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

                        // Go to Today Button (tvOS only)
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(spacing: 0) {
                                Button(action: {
                                    calendarViewModel.navigateToToday()
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Go to Today")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text("Move the selected date to today")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }

                                        Spacer()

                                        Image(systemName: "calendar")
                                            .foregroundColor(themeManager.currentPalette.primary)
                                            .font(.system(size: 20))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .focusable()
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                        #endif

                        // About Section (moved to bottom)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Version
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Version")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)

                                        Text("Simple Calendar 1.0.0")
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
                                Button(action: {
                                    showAboutView = true
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("About the App")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text("Why I built this calendar")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }

                                        Spacer()

                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 20))

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.borderless)
                                .focusable()
                                #else
                                // iOS/macOS: Button with separate info button
                                Button(action: {
                                    showAboutView = true
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("About the App")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text("Why I built this calendar")
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.currentPalette.primary)

                        Text("About Simple Calendar")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    .padding(.top, 20)

                    // Why I built this app
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why I Built This App")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        Text("""
                        I created Simple Calendar because I believe that understanding time and dates should be accessible to everyone, especially children. Calendars are fundamental to how we organize our lives, yet many people struggle with calendar concepts.

                        This app is designed with education in mind:
                        """)
                        .font(.body)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                        .lineSpacing(4)

                        VStack(alignment: .leading, spacing: 12) {
                            BulletPoint(text: "Visual learning through colors and themes")
                            BulletPoint(text: "Monthly themes to understand different time periods")
                            BulletPoint(text: "Customizable appearance for different needs")
                            BulletPoint(text: "Focus on calendar concepts over complex features")
                            BulletPoint(text: "Accessibility and ease of use for all ages")
                        }

                        Text("""
                        Whether you're teaching a child about days, weeks, and months, or just need a clean, simple calendar interface, Simple Calendar provides the tools to make calendar understanding intuitive and enjoyable.
                        """)
                        .font(.body)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                        .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            FeatureItem(icon: "paintpalette", title: "Multiple Color Themes", description: "Choose from various themes including monthly themes")
                            FeatureItem(icon: "textformat.size", title: "Customizable Text Size", description: "Adjust date number size for better visibility")
                            FeatureItem(icon: "border", title: "Border Controls", description: "Customize day square border contrast")
                            FeatureItem(icon: "moon.stars", title: "Dark/Light Modes", description: "Automatic theme switching based on system preferences")
                            FeatureItem(icon: "hand.point.up", title: "Accessibility Focused", description: "Designed with accessibility and education in mind")
                        }
                    }
                    .padding(.horizontal, 20)

                    // Footer
                    VStack(spacing: 8) {
                        Text("Made with ❤️ for learning and accessibility")
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                            .multilineTextAlignment(.center)

                        Text("© 2025 Nathan Fennel")
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(themeManager.currentPalette.calendarBackground)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentPalette.primary)
                .font(.system(size: 20))
                .frame(width: 24, height: 24)

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

// tvOS Theme Card Component
#if os(tvOS)
struct ThemeCard: View {
    let theme: ColorTheme
    let isSelected: Bool
    let isFocused: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @FocusState.Binding var focusedTheme: ColorTheme?

    private var currentPalette: ColorPalette {
        theme.palette(for: themeManager.currentColorScheme)
    }

    private var expandedContent: some View {
        VStack(spacing: 8) {
            Text(theme.displayName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(currentPalette.textPrimary)

            // Full color palette preview
            HStack(spacing: 6) {
                ForEach(currentPalette.eventColors.prefix(4), id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }

        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }

    private var compactContent: some View {
        VStack(spacing: 6) {
            // Primary color preview
            RoundedRectangle(cornerRadius: 6)
                .fill(currentPalette.primary)
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(currentPalette.border.opacity(0.5), lineWidth: 1)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ?
                  currentPalette.primary.opacity(0.15) :
                  currentPalette.surface.opacity(isFocused ? 0.8 : 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ?
                           currentPalette.primary :
                           (isFocused ? currentPalette.accent.opacity(0.6) : Color.clear),
                           lineWidth: isSelected ? 3 : (isFocused ? 2 : 0))
            )
    }

    var body: some View {
        Button(action: {
            themeManager.setTheme(theme)
        }) {
            VStack(spacing: isFocused ? 12 : 8) {
                if isFocused {
                    expandedContent
                } else {
                    compactContent
                }
            }
            .frame(minHeight: isFocused ? 120 : 80)
            .background(cardBackground)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(.borderless)
        .focused($focusedTheme, equals: theme)
    }
}
#endif

// Extension to add settings notification
extension Notification.Name {
    static let ShowSettings = Notification.Name("ShowSettings")
}

