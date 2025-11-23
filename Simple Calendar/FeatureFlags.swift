//
//  FeatureFlags.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Feature flag system for enabling/disabling experimental features
class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    // MARK: - Feature Flags

    @Published var advancedViews: Bool = true {
        didSet { UserDefaults.standard.set(advancedViews, forKey: "feature_advancedViews") }
    }
    @Published var imageIntegration: Bool = true {
        didSet { UserDefaults.standard.set(imageIntegration, forKey: "feature_imageIntegration") }
    }
    @Published var googleCalendarIntegration: Bool = true {
        didSet { UserDefaults.standard.set(googleCalendarIntegration, forKey: "feature_googleCalendarIntegration") }
    }
    @Published var colorThemes: Bool = true {
        didSet { UserDefaults.standard.set(colorThemes, forKey: "feature_colorThemes") }
    }
    @Published var fontSizeCustomization: Bool = true {
        didSet { UserDefaults.standard.set(fontSizeCustomization, forKey: "feature_fontSizeCustomization") }
    }
    @Published var eventExport: Bool = true {
        didSet { UserDefaults.standard.set(eventExport, forKey: "feature_eventExport") }
    }
    @Published var mapIntegration: Bool = true {
        didSet { UserDefaults.standard.set(mapIntegration, forKey: "feature_mapIntegration") }
    }
    @Published var advancedKeyboardShortcuts: Bool = true {
        didSet { UserDefaults.standard.set(advancedKeyboardShortcuts, forKey: "feature_advancedKeyboardShortcuts") }
    }
    @Published var eventReminders: Bool = true {
        didSet { UserDefaults.standard.set(eventReminders, forKey: "feature_eventReminders") }
    }
    @Published var recurringEvents: Bool = true {
        didSet { UserDefaults.standard.set(recurringEvents, forKey: "feature_recurringEvents") }
    }
    @Published var eventTemplates: Bool = true {
        didSet { UserDefaults.standard.set(eventTemplates, forKey: "feature_eventTemplates") }
    }
    @Published var weatherIntegration: Bool = true {
        didSet { UserDefaults.standard.set(weatherIntegration, forKey: "feature_weatherIntegration") }
    }
    @Published var calendarSharing: Bool = true {
        didSet { UserDefaults.standard.set(calendarSharing, forKey: "feature_calendarSharing") }
    }
    @Published var naturalLanguageEvents: Bool = true {
        didSet { UserDefaults.standard.set(naturalLanguageEvents, forKey: "feature_naturalLanguageEvents") }
    }
    @Published var aiEventSuggestions: Bool = true {
        didSet { UserDefaults.standard.set(aiEventSuggestions, forKey: "feature_aiEventSuggestions") }
    }
    @Published var collaborationFeatures: Bool = true {
        didSet { UserDefaults.standard.set(collaborationFeatures, forKey: "feature_collaborationFeatures") }
    }
    @Published var daylightVisualization: Bool = true {
        didSet { UserDefaults.standard.set(daylightVisualization, forKey: "feature_daylightVisualization") }
    }

    @Published var onThisDayEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(onThisDayEnabled, forKey: "feature_onThisDayEnabled")
            // Also sync to iCloud
            NSUbiquitousKeyValueStore.default.set(onThisDayEnabled, forKey: "feature_onThisDayEnabled")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    private init() {
        // Load initial values from UserDefaults
        advancedViews = UserDefaults.standard.bool(forKey: "feature_advancedViews")
        if advancedViews == false && UserDefaults.standard.object(forKey: "feature_advancedViews") == nil {
            advancedViews = true // Default to true if not set
        }

        imageIntegration = UserDefaults.standard.bool(forKey: "feature_imageIntegration")
        if imageIntegration == false && UserDefaults.standard.object(forKey: "feature_imageIntegration") == nil {
            imageIntegration = true
        }

        googleCalendarIntegration = UserDefaults.standard.bool(forKey: "feature_googleCalendarIntegration")
        if googleCalendarIntegration == false && UserDefaults.standard.object(forKey: "feature_googleCalendarIntegration") == nil {
            googleCalendarIntegration = true
        }

        colorThemes = UserDefaults.standard.bool(forKey: "feature_colorThemes")
        if colorThemes == false && UserDefaults.standard.object(forKey: "feature_colorThemes") == nil {
            colorThemes = true
        }

        fontSizeCustomization = UserDefaults.standard.bool(forKey: "feature_fontSizeCustomization")
        if fontSizeCustomization == false && UserDefaults.standard.object(forKey: "feature_fontSizeCustomization") == nil {
            fontSizeCustomization = true
        }

        eventExport = UserDefaults.standard.bool(forKey: "feature_eventExport")
        if eventExport == false && UserDefaults.standard.object(forKey: "feature_eventExport") == nil {
            eventExport = true
        }

        mapIntegration = UserDefaults.standard.bool(forKey: "feature_mapIntegration")
        if mapIntegration == false && UserDefaults.standard.object(forKey: "feature_mapIntegration") == nil {
            mapIntegration = true
        }

        advancedKeyboardShortcuts = UserDefaults.standard.bool(forKey: "feature_advancedKeyboardShortcuts")
        if advancedKeyboardShortcuts == false && UserDefaults.standard.object(forKey: "feature_advancedKeyboardShortcuts") == nil {
            advancedKeyboardShortcuts = true
        }

        eventReminders = UserDefaults.standard.bool(forKey: "feature_eventReminders")
        if eventReminders == false && UserDefaults.standard.object(forKey: "feature_eventReminders") == nil {
            eventReminders = true
        }

        recurringEvents = UserDefaults.standard.bool(forKey: "feature_recurringEvents")
        if recurringEvents == false && UserDefaults.standard.object(forKey: "feature_recurringEvents") == nil {
            recurringEvents = true
        }

        eventTemplates = UserDefaults.standard.bool(forKey: "feature_eventTemplates")
        if eventTemplates == false && UserDefaults.standard.object(forKey: "feature_eventTemplates") == nil {
            eventTemplates = true
        }

        weatherIntegration = UserDefaults.standard.bool(forKey: "feature_weatherIntegration")
        if weatherIntegration == false && UserDefaults.standard.object(forKey: "feature_weatherIntegration") == nil {
            weatherIntegration = true
        }

        calendarSharing = UserDefaults.standard.bool(forKey: "feature_calendarSharing")
        if calendarSharing == false && UserDefaults.standard.object(forKey: "feature_calendarSharing") == nil {
            calendarSharing = true
        }

        naturalLanguageEvents = UserDefaults.standard.bool(forKey: "feature_naturalLanguageEvents")
        if naturalLanguageEvents == false && UserDefaults.standard.object(forKey: "feature_naturalLanguageEvents") == nil {
            naturalLanguageEvents = true
        }

        aiEventSuggestions = UserDefaults.standard.bool(forKey: "feature_aiEventSuggestions")
        if aiEventSuggestions == false && UserDefaults.standard.object(forKey: "feature_aiEventSuggestions") == nil {
            aiEventSuggestions = true
        }

        collaborationFeatures = UserDefaults.standard.bool(forKey: "feature_collaborationFeatures")
        if collaborationFeatures == false && UserDefaults.standard.object(forKey: "feature_collaborationFeatures") == nil {
            collaborationFeatures = true
        }

        daylightVisualization = UserDefaults.standard.bool(forKey: "feature_daylightVisualization")
        if daylightVisualization == false && UserDefaults.standard.object(forKey: "feature_daylightVisualization") == nil {
            daylightVisualization = true
        }

        onThisDayEnabled = getOnThisDayFlag()
    }

    /// Get On This Day flag with iCloud sync support
    private func getOnThisDayFlag() -> Bool {
        // Try iCloud first, then local defaults
        let iCloudValue = NSUbiquitousKeyValueStore.default.bool(forKey: "feature_onThisDayEnabled")
        if NSUbiquitousKeyValueStore.default.object(forKey: "feature_onThisDayEnabled") != nil {
            return iCloudValue
        }

        // Fall back to local UserDefaults, defaulting to false
        return UserDefaults.standard.bool(forKey: "feature_onThisDayEnabled")
    }

    /// Reset all feature flags to defaults
    func resetToDefaults() {
        advancedViews = true
        imageIntegration = true
        googleCalendarIntegration = true
        colorThemes = true
        fontSizeCustomization = true
        eventExport = true
        mapIntegration = true
        advancedKeyboardShortcuts = true
        eventReminders = true
        recurringEvents = true
        eventTemplates = true
        weatherIntegration = true
        calendarSharing = true
        naturalLanguageEvents = true
        aiEventSuggestions = true
        collaborationFeatures = true
        daylightVisualization = true
        onThisDayEnabled = false  // Default to off

        saveAll()
    }

    private func saveAll() {
        UserDefaults.standard.set(advancedViews, forKey: "feature_advancedViews")
        UserDefaults.standard.set(imageIntegration, forKey: "feature_imageIntegration")
        UserDefaults.standard.set(googleCalendarIntegration, forKey: "feature_googleCalendarIntegration")
        UserDefaults.standard.set(colorThemes, forKey: "feature_colorThemes")
        UserDefaults.standard.set(fontSizeCustomization, forKey: "feature_fontSizeCustomization")
        UserDefaults.standard.set(eventExport, forKey: "feature_eventExport")
        UserDefaults.standard.set(mapIntegration, forKey: "feature_mapIntegration")
        UserDefaults.standard.set(advancedKeyboardShortcuts, forKey: "feature_advancedKeyboardShortcuts")
        UserDefaults.standard.set(eventReminders, forKey: "feature_eventReminders")
        UserDefaults.standard.set(recurringEvents, forKey: "feature_recurringEvents")
        UserDefaults.standard.set(eventTemplates, forKey: "feature_eventTemplates")
        UserDefaults.standard.set(weatherIntegration, forKey: "feature_weatherIntegration")
        UserDefaults.standard.set(calendarSharing, forKey: "feature_calendarSharing")
        UserDefaults.standard.set(naturalLanguageEvents, forKey: "feature_naturalLanguageEvents")
        UserDefaults.standard.set(aiEventSuggestions, forKey: "feature_aiEventSuggestions")
        UserDefaults.standard.set(collaborationFeatures, forKey: "feature_collaborationFeatures")
        UserDefaults.standard.set(daylightVisualization, forKey: "feature_daylightVisualization")
        UserDefaults.standard.set(onThisDayEnabled, forKey: "feature_onThisDayEnabled")
        UserDefaults.standard.synchronize()
    }

    /// Get all available features for settings UI (deprecated - now using direct toggles)
    func allFeatures() -> [(key: String, name: String, description: String, enabled: Bool, isPlanned: Bool)] {
        return []
    }
}
