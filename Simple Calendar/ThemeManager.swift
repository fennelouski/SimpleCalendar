//
//  ThemeManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI
import Combine
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ColorTheme {
        didSet {
            saveTheme()
        }
    }
    
    @Published var saturation: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(saturation, forKey: "themeSaturation")
            objectWillChange.send()
        }
    }
    
    // Get palette for a specific color scheme
    func palette(for colorScheme: ColorScheme) -> ColorPalette {
        currentTheme.palette(for: colorScheme)
    }
    
    // Convenience property for current system color scheme (set by views)
    private var _currentColorScheme: ColorScheme = .light
    var currentColorScheme: ColorScheme {
        get { _currentColorScheme }
        set {
            if _currentColorScheme != newValue {
                _currentColorScheme = newValue
                // Trigger UI updates when color scheme changes
                objectWillChange.send()
            }
        }
    }
    
    // Computed property that returns the appropriate palette based on current color scheme
    var currentPalette: ColorPalette {
        currentTheme.palette(for: currentColorScheme).withSaturation(saturation)
    }

    private let themeKey = "selectedColorTheme"
    private let lastManualThemeKey = "lastManualColorTheme"
    
    // Store the last manually selected theme (before monthly theme mode was enabled)
    var lastManualTheme: ColorTheme? {
        get {
            let savedThemeRaw = UserDefaults.standard.integer(forKey: lastManualThemeKey)
            if savedThemeRaw == 0 && UserDefaults.standard.object(forKey: lastManualThemeKey) == nil {
                return nil
            }
            return ColorTheme(rawValue: savedThemeRaw)
        }
        set {
            if let theme = newValue {
                UserDefaults.standard.set(theme.rawValue, forKey: lastManualThemeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastManualThemeKey)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        let savedThemeRaw = UserDefaults.standard.integer(forKey: themeKey)
#if os(tvOS)
        self.currentTheme = ColorTheme(rawValue: savedThemeRaw) ?? .system
#else
        self.currentTheme = ColorTheme(rawValue: savedThemeRaw) ?? .default
#endif
        
        // Default to light mode initially - will be updated by ContentView when it appears
        // System color scheme detection is now handled by ContentView's onChange modifier
        self.currentColorScheme = .light
        // Default to light mode initially - will be updated by ContentView when it appears
        // System color scheme detection is now handled by ContentView's onChange modifier
        self.currentColorScheme = .light
        
        // Load saturation
        if UserDefaults.standard.object(forKey: "themeSaturation") != nil {
            self.saturation = UserDefaults.standard.double(forKey: "themeSaturation")
        } else {
            self.saturation = 1.0
        }
    }
    
    func setTheme(_ theme: ColorTheme) {
        // Ensure we're on the main thread for UI updates
        if Thread.isMainThread {
            currentTheme = theme
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.currentTheme = theme
            }
        }
    }
    
    /// Save the current theme as the last manually selected theme
    func saveCurrentThemeAsManual() {
        // Only save if the current theme is not a monthly theme (january through december)
        if currentTheme.rawValue < 9 || currentTheme.rawValue > 20 {
            lastManualTheme = currentTheme
        }
    }
    
    /// Save a specific theme as the last manually selected theme
    func saveThemeAsManual(_ theme: ColorTheme) {
        // Only save if the theme is not a monthly theme (january through december)
        if theme.rawValue < 9 || theme.rawValue > 20 {
            lastManualTheme = theme
        }
    }
    
    /// Restore the last manually selected theme
    func restoreLastManualTheme() {
        if let manualTheme = lastManualTheme {
            setTheme(manualTheme)
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.synchronize()
    }
}
