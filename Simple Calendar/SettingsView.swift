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
                SettingsContentView(showSettings: $showSettings)
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("ShowSettings"))) { _ in
                showSettings = true
            }
    }
}

struct SettingsContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var featureFlags = FeatureFlags.shared
    @Binding var showSettings: Bool
    @State private var isGoogleCalendarEnabled = false
    @State private var googleAccountEmail = ""
    @State private var showColorTheme = false
    @State private var showTypography = false
    @State private var showFeatureFlags = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                        showSettings = false
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Settings Sections
                VStack(spacing: 0) {
                    // Calendar Integration
                    SettingsSection(title: "Calendar Integration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("System Calendar", isOn: .constant(true))
                                .disabled(true)

                            Toggle("Google Calendar", isOn: $isGoogleCalendarEnabled)

                            if isGoogleCalendarEnabled {
                                if googleAccountEmail.isEmpty {
                                    Button("Sign in to Google") {
                                        // Google OAuth would go here
                                        print("Google sign in tapped")
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 4)
                                } else {
                                    HStack {
                                        Text("Signed in as:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(googleAccountEmail)
                                            .foregroundColor(.secondary)
                                    }

                                    Button("Sign Out") {
                                        googleAccountEmail = ""
                                        isGoogleCalendarEnabled = false
                                    }
                                    .foregroundColor(.red)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    // Appearance
                    SettingsSection(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Light/Dark Mode", isOn: .constant(true))
                                .disabled(true)
                        }
                    }

                    // Color Theme - Button to show sheet
                    SettingsSection(title: "Color Theme") {
                        Button(action: {
                            showColorTheme = true
                        }) {
                            SettingsRow(title: "Theme", subtitle: themeManager.currentTheme.palette.name, showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    // Typography - Button to show sheet
                    SettingsSection(title: "Typography") {
                        Button(action: {
                            showTypography = true
                        }) {
                            SettingsRow(title: "Font Size", subtitle: "Adjust text size and style", showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    // Images
                    SettingsSection(title: "Images") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Show Unsplash Attribution", isOn: Binding(
                                get: { UserDefaults.standard.bool(forKey: "showUnsplashAttribution") },
                                set: { UserDefaults.standard.set($0, forKey: "showUnsplashAttribution") }
                            ))
                            Text("Display photo credits on images from Unsplash")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Feature Flags - Button to show sheet
                    SettingsSection(title: "Experimental Features") {
                        Button(action: {
                            showFeatureFlags = true
                        }) {
                            SettingsRow(title: "Advanced Options", subtitle: "Enable experimental features", showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    // About
                    SettingsSection(title: "About") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showColorTheme) {
            ColorThemeSettingsView(showSettings: $showColorTheme)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showTypography) {
            TypographySettingsView(showSettings: $showTypography)
                .environmentObject(uiConfig)
        }
        .sheet(isPresented: $showFeatureFlags) {
            FeatureFlagsSettingsView(showSettings: $showFeatureFlags)
                .environmentObject(featureFlags)
        }
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let showChevron: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Sub-Settings Views

struct ColorThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Color Theme")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                        showSettings = false
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Theme Selection
                VStack(spacing: 16) {
                    ForEach(ColorTheme.allCases) { theme in
                        Button(action: {
                            themeManager.currentTheme = theme
                        }) {
                            HStack(spacing: 16) {
                                // Theme Icon
                                Image(systemName: theme.palette.icon)
                                    .foregroundColor(theme.palette.primary)
                                    .frame(width: 24, height: 24)

                                // Theme Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.palette.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    // Color Preview
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.palette.primary)
                                            .frame(width: 16, height: 16)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.palette.secondary)
                                            .frame(width: 16, height: 16)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.palette.accent)
                                            .frame(width: 16, height: 16)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.palette.background)
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(theme.palette.border, lineWidth: 1)
                                            )
                                    }
                                }

                                Spacer()

                                // Selection Indicator
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.palette.primary)
                                        .font(.title3)
                                }
                            }
                            .padding(16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.currentTheme == theme ? theme.palette.primary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }
}

struct TypographySettingsView: View {
    @EnvironmentObject var uiConfig: UIConfiguration
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Typography")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                        showSettings = false
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Font Size Controls
                VStack(spacing: 16) {
                    SettingsSection(title: "Font Size") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Size")
                                Spacer()
                                Button(action: {
                                    uiConfig.decreaseFontSize()
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(uiConfig.fontSizeCategory == .extraSmall ? .gray : .blue)
                                }
                                .disabled(uiConfig.fontSizeCategory == .extraSmall)

                                Text(uiConfig.fontSizeCategory.displayName)
                                    .frame(minWidth: 80)
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    uiConfig.increaseFontSize()
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(uiConfig.fontSizeCategory == .extraLarge ? .gray : .blue)
                                }
                                .disabled(uiConfig.fontSizeCategory == .extraLarge)
                            }
                            .padding(.vertical, 4)

                            // Font size preview
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Month Name")
                                        .font(uiConfig.monthTitleFont)
                                    Text("January 2025")
                                        .font(uiConfig.yearTitleFont)
                                    Text("Day numbers and event details")
                                        .font(uiConfig.eventDetailFont)
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }
}

struct FeatureFlagsSettingsView: View {
    @EnvironmentObject var featureFlags: FeatureFlags
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Experimental Features")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") {
                        showSettings = false
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Feature Toggles
                VStack(spacing: 16) {
                    // Available Features
                    SettingsSection(title: "Available Features") {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Advanced Views", isOn: $featureFlags.advancedViews)
                                .help("Agenda view, event templates, and advanced calendar layouts")

                            Toggle("Image Integration", isOn: $featureFlags.imageIntegration)
                                .help("Beautiful images from Unsplash for events")

                            Toggle("Google Calendar", isOn: $featureFlags.googleCalendarIntegration)
                                .help("Sync with your Google Calendar account")

                            Toggle("Color Themes", isOn: $featureFlags.colorThemes)
                                .help("Choose from multiple beautiful color palettes")

                            Toggle("Font Customization", isOn: $featureFlags.fontSizeCustomization)
                                .help("Adjust font sizes for better readability")

                            Toggle("Event Export", isOn: $featureFlags.eventExport)
                                .help("Export events to other calendar applications")

                            Toggle("Map Integration", isOn: $featureFlags.mapIntegration)
                                .help("View event locations on interactive maps")

                            Toggle("Keyboard Shortcuts", isOn: $featureFlags.advancedKeyboardShortcuts)
                                .help("Full keyboard navigation and shortcuts")

                            Toggle("Event Reminders", isOn: $featureFlags.eventReminders)
                                .help("Get notified about upcoming events")

                            Toggle("Recurring Events", isOn: $featureFlags.recurringEvents)
                                .help("Create events that repeat daily, weekly, or monthly")

                            Toggle("Event Templates", isOn: $featureFlags.eventTemplates)
                                .help("Quick event creation with predefined templates")

                            Toggle("Daylight Visualization", isOn: $featureFlags.daylightVisualization)
                                .help("Show daylight cycles on calendar days")
                        }
                    }

                    // Planned Features
                    SettingsSection(title: "Planned Features") {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Weather Integration", isOn: $featureFlags.weatherIntegration)
                                .help("Weather forecasts for outdoor events")

                            Toggle("Calendar Sharing", isOn: $featureFlags.calendarSharing)
                                .help("Share calendars with family and friends")

                            Toggle("Natural Language", isOn: $featureFlags.naturalLanguageEvents)
                                .help("Create events using plain English")

                            Toggle("AI Suggestions", isOn: $featureFlags.aiEventSuggestions)
                                .help("Smart event suggestions based on your habits")

                            Toggle("Collaboration", isOn: $featureFlags.collaborationFeatures)
                                .help("Collaborate on events with others")
                        }
                    }

                    // Reset Button
                    VStack(spacing: 16) {
                        Divider()

                        Button(action: {
                            featureFlags.resetToDefaults()
                        }) {
                            Text("Reset to Defaults")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }
}
// Extension to add settings notification
extension Notification.Name {
    static let ShowSettings = Notification.Name("ShowSettings")
}
