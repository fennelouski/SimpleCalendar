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
    @StateObject private var featureFlags = FeatureFlags.shared
    @Binding var showSettings: Bool
    @State private var isGoogleCalendarEnabled = false
    @ObservedObject var googleOAuthManager: GoogleOAuthManager

    @State private var showColorTheme = false
    @State private var showTypography = false
    @State private var showFeatureFlags = false

    var body: some View {
        #if os(iOS)
        NavigationView {
            mainSettingsContent
                .navigationBarHidden(true)
        }
        .sheet(isPresented: $showColorTheme) {
            ColorThemeSettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showTypography) {
            TypographySettingsView()
                .environmentObject(uiConfig)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showFeatureFlags) {
            FeatureFlagsSettingsView()
                .environmentObject(featureFlags)
                .environmentObject(themeManager)
        }
        #else
        // On macOS, use sheets for all sub-views since NavigationView doesn't work well
        mainSettingsContent
        .sheet(isPresented: $showColorTheme) {
            ColorThemeSettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showTypography) {
            TypographySettingsView()
                .environmentObject(uiConfig)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showFeatureFlags) {
            FeatureFlagsSettingsView()
                .environmentObject(featureFlags)
                .environmentObject(themeManager)
        }
        #endif
    }

    private var mainSettingsContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                    Spacer()
                    Button("Done") {
                        showSettings = false
                    }
                    .foregroundColor(themeManager.currentPalette.primary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Settings Sections
                VStack(spacing: 16) {
                    // Calendar Integration
                    SettingsSection(title: "Calendar Integration") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "System Calendar",
                                subtitle: "Sync with macOS Calendar",
                                trailingContent: AnyView(
                                    Toggle("", isOn: .constant(true))
                                        .disabled(true)
                                        .labelsHidden()
                                )
                            )

                            SettingsRow(
                                title: "Google Calendar",
                                subtitle: googleOAuthManager.isAuthenticated ?
                                    "Signed in as \(googleOAuthManager.userEmail ?? "Unknown")" :
                                    "Connect your Google Calendar",
                                trailingContent: AnyView(
                                    Toggle("", isOn: $isGoogleCalendarEnabled)
                                        .labelsHidden()
                                )
                            )

                            if isGoogleCalendarEnabled {
                                if !googleOAuthManager.isAuthenticated {
                                    Button("Sign in to Google") {
                                        googleOAuthManager.signIn()
                                    }
                                    .foregroundColor(themeManager.currentPalette.primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(themeManager.currentPalette.surface.opacity(0.8))
                                    .cornerRadius(8)

                                    if let error = googleOAuthManager.authenticationError {
                                        Text(error)
                                            .foregroundColor(.red)
                                            .font(.caption)
                                            .padding(.vertical, 4)
                                    }
                                } else {
                                    Button("Sign Out") {
                                        googleOAuthManager.signOut()
                                        isGoogleCalendarEnabled = false
                                    }
                                    .foregroundColor(.red)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Appearance
                    SettingsSection(title: "Appearance") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "Light/Dark Mode",
                                subtitle: "Follows system appearance",
                                trailingContent: AnyView(
                                    Toggle("", isOn: .constant(true))
                                        .disabled(true)
                                        .labelsHidden()
                                )
                            )

                            Button(action: {
                                showColorTheme = true
                            }) {
                                SettingsRow(
                                    title: "Color Theme",
                                    subtitle: themeManager.currentPalette.name,
                                    showChevron: true
                                )
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grid Line Contrast")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)

                                HStack {
                                    Slider(value: $uiConfig.gridLineOpacity, in: 0.0...1.0, step: 0.05)
                                        .accentColor(themeManager.currentPalette.primary)

                                    Text("\(Int(uiConfig.gridLineOpacity * 100))%")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentPalette.textSecondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }
                        }
                    }

                    // Typography
                    SettingsSection(title: "Typography") {
                        Button(action: {
                            showTypography = true
                        }) {
                            SettingsRow(
                                title: "Font Size",
                                subtitle: "Adjust text size and style",
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Images
                    SettingsSection(title: "Images") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "Unsplash Attribution",
                                subtitle: "Show photo credits on images",
                                trailingContent: AnyView(
                                    Toggle("", isOn: Binding(
                                        get: { UserDefaults.standard.bool(forKey: "showUnsplashAttribution") },
                                        set: { UserDefaults.standard.set($0, forKey: "showUnsplashAttribution") }
                                    ))
                                    .labelsHidden()
                                )
                            )
                        }
                    }

                    // Experimental Features
                    SettingsSection(title: "Experimental Features") {
                        Button(action: {
                            showFeatureFlags = true
                        }) {
                            SettingsRow(
                                title: "Advanced Options",
                                subtitle: "Enable experimental features",
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // About
                    SettingsSection(title: "About") {
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "Version",
                                subtitle: "Simple Calendar 1.0.0",
                                trailingContent: AnyView(EmptyView())
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
            .background(themeManager.currentPalette.calendarBackground)
        }
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(themeManager.currentPalette.surface.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentPalette.border.opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct SettingsRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let trailingContent: AnyView?

    init(title: String, subtitle: String? = nil, showChevron: Bool = false, trailingContent: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.trailingContent = trailingContent
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)

            if let trailingContent = trailingContent {
                trailingContent
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .font(.body)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Sub-Settings Views

struct ColorThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    private func themePalette(_ theme: ColorTheme) -> ColorPalette {
        theme.palette(for: colorScheme)
    }

    private func currentPalette() -> ColorPalette {
        themeManager.currentPalette
    }

    private func strokeColor(for theme: ColorTheme) -> Color {
        if themeManager.currentTheme == theme {
            return themePalette(theme).primary
        } else {
            return currentPalette().border.opacity(0.3)
        }
    }

    private func strokeWidth(for theme: ColorTheme) -> CGFloat {
        if themeManager.currentTheme == theme {
            return 2
        } else {
            return 0.5
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Color Theme")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentPalette().textPrimary)
                    Spacer()
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
                                Image(systemName: themePalette(theme).icon)
                                    .foregroundColor(themePalette(theme).primary)
                                    .frame(width: 24, height: 24)

                                // Theme Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themePalette(theme).name)
                                        .font(.headline)
                                        .foregroundColor(currentPalette().textPrimary)

                                    // Color Preview
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(themePalette(theme).primary)
                                            .frame(width: 14, height: 14)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(themePalette(theme).secondary)
                                            .frame(width: 14, height: 14)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(themePalette(theme).accent)
                                            .frame(width: 14, height: 14)

                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(themePalette(theme).background)
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(themePalette(theme).border, lineWidth: 0.5)
                                            )
                                    }
                                }

                                Spacer()

                                // Selection Indicator
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themePalette(theme).primary)
                                        .font(.title3)
                                }
                            }
                            .padding(16)
                            .background(currentPalette().surface.opacity(0.6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(strokeColor(for: theme), lineWidth: strokeWidth(for: theme))
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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Typography")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                    Spacer()
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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Experimental Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                    Spacer()
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

