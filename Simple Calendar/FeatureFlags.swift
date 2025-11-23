//
//  FeatureFlags.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation

/// Feature flag system for enabling/disabling experimental features
class FeatureFlags {
    static let shared = FeatureFlags()

    // MARK: - Feature Flags

    /// Enable advanced calendar views (agenda, templates, etc.)
    var advancedViews: Bool {
        get { getFlag("advancedViews", defaultValue: true) }
        set { setFlag("advancedViews", value: newValue) }
    }

    /// Enable image integration with Unsplash
    var imageIntegration: Bool {
        get { getFlag("imageIntegration", defaultValue: true) }
        set { setFlag("imageIntegration", value: newValue) }
    }

    /// Enable Google Calendar integration
    var googleCalendarIntegration: Bool {
        get { getFlag("googleCalendarIntegration", defaultValue: true) }
        set { setFlag("googleCalendarIntegration", value: newValue) }
    }

    /// Enable color themes
    var colorThemes: Bool {
        get { getFlag("colorThemes", defaultValue: true) }
        set { setFlag("colorThemes", value: newValue) }
    }

    /// Enable font size customization
    var fontSizeCustomization: Bool {
        get { getFlag("fontSizeCustomization", defaultValue: true) }
        set { setFlag("fontSizeCustomization", value: newValue) }
    }

    /// Enable event export functionality
    var eventExport: Bool {
        get { getFlag("eventExport", defaultValue: true) }
        set { setFlag("eventExport", value: newValue) }
    }

    /// Enable map integration for events with locations
    var mapIntegration: Bool {
        get { getFlag("mapIntegration", defaultValue: true) }
        set { setFlag("mapIntegration", value: newValue) }
    }

    /// Enable advanced keyboard shortcuts
    var advancedKeyboardShortcuts: Bool {
        get { getFlag("advancedKeyboardShortcuts", defaultValue: true) }
        set { setFlag("advancedKeyboardShortcuts", value: newValue) }
    }

    /// Enable event reminders and notifications
    var eventReminders: Bool {
        get { getFlag("eventReminders", defaultValue: true) }
        set { setFlag("eventReminders", value: newValue) }
    }

    /// Enable recurring events
    var recurringEvents: Bool {
        get { getFlag("recurringEvents", defaultValue: true) }
        set { setFlag("recurringEvents", value: newValue) }
    }

    /// Enable event templates for quick creation
    var eventTemplates: Bool {
        get { getFlag("eventTemplates", defaultValue: true) }
        set { setFlag("eventTemplates", value: newValue) }
    }

    /// Enable weather integration (planned feature)
    var weatherIntegration: Bool {
        get { getFlag("weatherIntegration", defaultValue: false) }
        set { setFlag("weatherIntegration", value: newValue) }
    }

    /// Enable calendar sharing (planned feature)
    var calendarSharing: Bool {
        get { getFlag("calendarSharing", defaultValue: false) }
        set { setFlag("calendarSharing", value: newValue) }
    }

    /// Enable natural language event creation (planned feature)
    var naturalLanguageEvents: Bool {
        get { getFlag("naturalLanguageEvents", defaultValue: false) }
        set { setFlag("naturalLanguageEvents", value: newValue) }
    }

    /// Enable AI-powered event suggestions (planned feature)
    var aiEventSuggestions: Bool {
        get { getFlag("aiEventSuggestions", defaultValue: false) }
        set { setFlag("aiEventSuggestions", value: newValue) }
    }

    /// Enable collaborative features (planned feature)
    var collaborationFeatures: Bool {
        get { getFlag("collaborationFeatures", defaultValue: false) }
        set { setFlag("collaborationFeatures", value: newValue) }
    }

    // MARK: - Private Methods

    private func getFlag(_ key: String, defaultValue: Bool) -> Bool {
        return UserDefaults.standard.bool(forKey: "feature_\(key)")
    }

    private func setFlag(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: "feature_\(key)")
        UserDefaults.standard.synchronize()
    }

    /// Reset all feature flags to defaults
    func resetToDefaults() {
        let defaults = [
            "feature_advancedViews": true,
            "feature_imageIntegration": true,
            "feature_googleCalendarIntegration": true,
            "feature_colorThemes": true,
            "feature_fontSizeCustomization": true,
            "feature_eventExport": true,
            "feature_mapIntegration": true,
            "feature_advancedKeyboardShortcuts": true,
            "feature_eventReminders": true,
            "feature_recurringEvents": true,
            "feature_eventTemplates": true,
            "feature_weatherIntegration": false,
            "feature_calendarSharing": false,
            "feature_naturalLanguageEvents": false,
            "feature_aiEventSuggestions": false,
            "feature_collaborationFeatures": false
        ]

        for (key, value) in defaults {
            UserDefaults.standard.set(value, forKey: key)
        }
        UserDefaults.standard.synchronize()
    }

    /// Get all available features for settings UI
    func allFeatures() -> [(key: String, name: String, description: String, enabled: Bool, isPlanned: Bool)] {
        return [
            ("advancedViews", "Advanced Views", "Agenda view, event templates, and advanced calendar layouts", advancedViews, false),
            ("imageIntegration", "Image Integration", "Beautiful images from Unsplash for events", imageIntegration, false),
            ("googleCalendarIntegration", "Google Calendar", "Sync with your Google Calendar account", googleCalendarIntegration, false),
            ("colorThemes", "Color Themes", "Choose from multiple beautiful color palettes", colorThemes, false),
            ("fontSizeCustomization", "Font Customization", "Adjust font sizes for better readability", fontSizeCustomization, false),
            ("eventExport", "Event Export", "Export events to other calendar applications", eventExport, false),
            ("mapIntegration", "Map Integration", "View event locations on interactive maps", mapIntegration, false),
            ("advancedKeyboardShortcuts", "Keyboard Shortcuts", "Full keyboard navigation and shortcuts", advancedKeyboardShortcuts, false),
            ("eventReminders", "Event Reminders", "Get notified about upcoming events", eventReminders, false),
            ("recurringEvents", "Recurring Events", "Create events that repeat daily, weekly, or monthly", recurringEvents, false),
            ("eventTemplates", "Event Templates", "Quick event creation with predefined templates", eventTemplates, false),
            ("weatherIntegration", "Weather Integration", "Weather forecasts for outdoor events", weatherIntegration, true),
            ("calendarSharing", "Calendar Sharing", "Share calendars with family and friends", calendarSharing, true),
            ("naturalLanguageEvents", "Natural Language", "Create events using plain English", naturalLanguageEvents, true),
            ("aiEventSuggestions", "AI Suggestions", "Smart event suggestions based on your habits", aiEventSuggestions, true),
            ("collaborationFeatures", "Collaboration", "Collaborate on events with others", collaborationFeatures, true)
        ]
    }
}
