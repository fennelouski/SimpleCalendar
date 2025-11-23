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
    @State private var showFeatureFlags = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    showSettings = false
                }
            }
            .padding()

            ScrollView {
                Form {
                Section(header: Text("Calendar Integration")) {
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
                        } else {
                            HStack {
                                Text("Signed in as:")
                                Spacer()
                                Text(googleAccountEmail)
                                    .foregroundColor(.secondary)
                            }

                            Button("Sign Out") {
                                googleAccountEmail = ""
                                isGoogleCalendarEnabled = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                }

                Section(header: Text("Appearance")) {
                    Toggle("Light/Dark Mode", isOn: .constant(true))
                        .disabled(true)
                }

                Section(header: Text("Color Theme")) {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        ForEach(ColorTheme.allCases) { theme in
                            HStack {
                                Image(systemName: theme.palette.icon)
                                    .foregroundColor(theme.palette.primary)
                                Text(theme.palette.name)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    // Theme preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.palette.primary)
                                .frame(width: 20, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.palette.secondary)
                                .frame(width: 20, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.palette.accent)
                                .frame(width: 20, height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.palette.background)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(themeManager.currentTheme.palette.border, lineWidth: 1)
                                )
                        }
                    }
                        .padding(.vertical, 4)
                }

                Section(header: Text("Typography")) {
                    HStack {
                        Text("Font Size")
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
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium.value))
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Images")) {
                    Toggle("Show Unsplash Attribution", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "showUnsplashAttribution") },
                        set: { UserDefaults.standard.set($0, forKey: "showUnsplashAttribution") }
                    ))
                    Text("Display photo credits on images from Unsplash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Experimental Features")) {
                    DisclosureGroup("Feature Flags", isExpanded: $showFeatureFlags) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(featureFlags.allFeatures(), id: \.key) { feature in
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle(isOn: Binding(
                                        get: { feature.enabled },
                                        set: { _ in
                                            // Toggle the feature flag
                                            switch feature.key {
                                            case "advancedViews": featureFlags.advancedViews.toggle()
                                            case "imageIntegration": featureFlags.imageIntegration.toggle()
                                            case "googleCalendarIntegration": featureFlags.googleCalendarIntegration.toggle()
                                            case "colorThemes": featureFlags.colorThemes.toggle()
                                            case "fontSizeCustomization": featureFlags.fontSizeCustomization.toggle()
                                            case "eventExport": featureFlags.eventExport.toggle()
                                            case "mapIntegration": featureFlags.mapIntegration.toggle()
                                            case "advancedKeyboardShortcuts": featureFlags.advancedKeyboardShortcuts.toggle()
                                            case "eventReminders": featureFlags.eventReminders.toggle()
                                            case "recurringEvents": featureFlags.recurringEvents.toggle()
                                            case "eventTemplates": featureFlags.eventTemplates.toggle()
                                            case "weatherIntegration": featureFlags.weatherIntegration.toggle()
                                            case "calendarSharing": featureFlags.calendarSharing.toggle()
                                            case "naturalLanguageEvents": featureFlags.naturalLanguageEvents.toggle()
                                        case "aiEventSuggestions": featureFlags.aiEventSuggestions.toggle()
                                        case "collaborationFeatures": featureFlags.collaborationFeatures.toggle()
                                        case "daylightVisualization": featureFlags.daylightVisualization.toggle()
                                            default: break
                                            }
                                        }
                                    )) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(feature.name)
                                                    .font(.body)
                                                Text(feature.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if feature.isPlanned {
                                                Text("Planned")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            Button(action: {
                                featureFlags.resetToDefaults()
                            }) {
                                Text("Reset to Defaults")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 16)
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

// Extension to add settings notification
extension Notification.Name {
    static let ShowSettings = Notification.Name("ShowSettings")
}
