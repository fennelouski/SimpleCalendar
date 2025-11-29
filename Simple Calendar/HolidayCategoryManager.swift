//
//  HolidayCategoryManager.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Manages which holiday categories are enabled/disabled
class HolidayCategoryManager: ObservableObject {
    static let shared = HolidayCategoryManager()
    
    private let userDefaultsKeyPrefix = "holiday_category_enabled_"
    
    /// Default enabled categories: Bank, Unique, Awareness Days, and Seasons
    private static var defaultEnabledCategories: Set<CalendarHoliday.CalendarHolidayCategory> {
        [
            .bankHolidays,
            .uniqueHolidays,
            .awarenessDays,
            .seasons
        ]
    }
    
    @Published var enabledCategories: Set<CalendarHoliday.CalendarHolidayCategory> = HolidayCategoryManager.defaultEnabledCategories
    
    private init() {
        // Load enabled categories from UserDefaults
        // Default: Bank, Unique, Awareness Days, and Seasons enabled
        enabledCategories = loadEnabledCategories()
    }
    
    /// Check if a category is enabled
    func isEnabled(_ category: CalendarHoliday.CalendarHolidayCategory) -> Bool {
        return enabledCategories.contains(category)
    }
    
    /// Enable a category
    func enable(_ category: CalendarHoliday.CalendarHolidayCategory) {
        enabledCategories.insert(category)
        saveEnabledCategories()
        // Also sync to iCloud
        syncToiCloud()
    }
    
    /// Disable a category
    func disable(_ category: CalendarHoliday.CalendarHolidayCategory) {
        enabledCategories.remove(category)
        saveEnabledCategories()
        // Also sync to iCloud
        syncToiCloud()
    }
    
    /// Toggle a category
    func toggle(_ category: CalendarHoliday.CalendarHolidayCategory) {
        if isEnabled(category) {
            disable(category)
        } else {
            enable(category)
        }
    }
    
    /// Enable all categories
    func enableAll() {
        enabledCategories = Set(CalendarHoliday.CalendarHolidayCategory.allCases)
        saveEnabledCategories()
        syncToiCloud()
    }
    
    /// Disable all categories
    func disableAll() {
        enabledCategories.removeAll()
        saveEnabledCategories()
        syncToiCloud()
    }
    
    /// Load enabled categories from UserDefaults
    private func loadEnabledCategories() -> Set<CalendarHoliday.CalendarHolidayCategory> {
        // Try iCloud first
        let iCloudStore = NSUbiquitousKeyValueStore.default
        var enabled: Set<CalendarHoliday.CalendarHolidayCategory> = []
        
        // Check if iCloud has any values
        var hasiCloudValues = false
        for category in CalendarHoliday.CalendarHolidayCategory.allCases {
            let key = userDefaultsKeyPrefix + category.rawValue
            if iCloudStore.object(forKey: key) != nil {
                hasiCloudValues = true
                if iCloudStore.bool(forKey: key) {
                    enabled.insert(category)
                }
            }
        }
        
        // If iCloud has values, use them; otherwise use local UserDefaults
        if hasiCloudValues {
            return enabled.isEmpty ? Self.defaultEnabledCategories : enabled
        }
        
        // Load from local UserDefaults
        var hasAnyPreference = false
        for category in CalendarHoliday.CalendarHolidayCategory.allCases {
            let key = userDefaultsKeyPrefix + category.rawValue
            if UserDefaults.standard.object(forKey: key) != nil {
                hasAnyPreference = true
                if UserDefaults.standard.bool(forKey: key) {
                    enabled.insert(category)
                }
            }
        }
        
        // If no preferences were set, return default enabled categories
        return hasAnyPreference ? enabled : Self.defaultEnabledCategories
    }
    
    /// Save enabled categories to UserDefaults
    private func saveEnabledCategories() {
        for category in CalendarHoliday.CalendarHolidayCategory.allCases {
            let key = userDefaultsKeyPrefix + category.rawValue
            let isEnabled = enabledCategories.contains(category)
            UserDefaults.standard.set(isEnabled, forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
    
    /// Sync enabled categories to iCloud
    private func syncToiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        for category in CalendarHoliday.CalendarHolidayCategory.allCases {
            let key = userDefaultsKeyPrefix + category.rawValue
            let isEnabled = enabledCategories.contains(category)
            iCloudStore.set(isEnabled, forKey: key)
        }
        iCloudStore.synchronize()
    }
}

