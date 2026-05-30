//
//  AnimationAlphaSettings.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Manages alpha/opacity settings for background animations
class AnimationAlphaSettings: ObservableObject {
    static let shared = AnimationAlphaSettings()
    
    // Global alpha multiplier (applies to all animations)
    @Published var globalAlpha: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(globalAlpha, forKey: "animation_globalAlpha")
            NSUbiquitousKeyValueStore.default.set(globalAlpha, forKey: "animation_globalAlpha")
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    // Individual month animation alphas (1-12 for January-December)
    @Published var monthAlphas: [Double] = Array(repeating: 1.0, count: 12) {
        didSet {
            saveMonthAlphas()
        }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load global alpha
        if let iCloudValue = NSUbiquitousKeyValueStore.default.object(forKey: "animation_globalAlpha") as? Double {
            globalAlpha = iCloudValue
        } else {
            globalAlpha = UserDefaults.standard.double(forKey: "animation_globalAlpha")
            if globalAlpha == 0.0 && UserDefaults.standard.object(forKey: "animation_globalAlpha") == nil {
                globalAlpha = 1.0 // Default to 1.0
            }
        }
        
        // Load month alphas
        var loadedAlphas: [Double] = []
        for month in 1...12 {
            let key = "animation_monthAlpha_\(month)"
            if let iCloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Double {
                loadedAlphas.append(iCloudValue)
            } else {
                let value = UserDefaults.standard.double(forKey: key)
                loadedAlphas.append(value == 0.0 && UserDefaults.standard.object(forKey: key) == nil ? 1.0 : value)
            }
        }
        monthAlphas = loadedAlphas
    }
    
    private func saveMonthAlphas() {
        for (index, alpha) in monthAlphas.enumerated() {
            let month = index + 1
            let key = "animation_monthAlpha_\(month)"
            UserDefaults.standard.set(alpha, forKey: key)
            NSUbiquitousKeyValueStore.default.set(alpha, forKey: key)
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    /// Get the combined alpha for a specific month (globalAlpha * monthAlpha)
    func combinedAlpha(for month: Int) -> Double {
        guard month >= 1 && month <= 12 else { return globalAlpha }
        return globalAlpha * monthAlphas[month - 1]
    }
    
    /// Set alpha for a specific month (1-12)
    func setAlpha(_ alpha: Double, for month: Int) {
        guard month >= 1 && month <= 12 else { return }
        monthAlphas[month - 1] = alpha
    }
    
    /// Get alpha for a specific month
    func alpha(for month: Int) -> Double {
        guard month >= 1 && month <= 12 else { return 1.0 }
        return monthAlphas[month - 1]
    }
    
    /// Month names for UI
    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
}


