//
//  MonthlyThemeManager.swift
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

// MARK: - Monthly Theme Manager
class MonthlyThemeManager: ObservableObject {
    static let shared = MonthlyThemeManager()

    @Published var monthlyThemes: [Int: ColorTheme] = [:] {
        didSet { saveMonthlyThemes() }
    }

    @Published var monthlyFonts: [Int: String] = [:] {
        didSet { saveMonthlyFonts() }
    }

    private let monthlyThemesKey = "monthlyThemes"
    private let monthlyFontsKey = "monthlyFonts"

    private init() {
        loadMonthlyThemes()
        loadMonthlyFonts()
    }

    func theme(for month: Int) -> ColorTheme {
        return monthlyThemes[month] ?? .system
    }

    func setTheme(_ theme: ColorTheme, for month: Int) {
        monthlyThemes[month] = theme
    }

    func font(for month: Int) -> String {
        return monthlyFonts[month] ?? "Arial"
    }

    func setFont(_ font: String, for month: Int) {
        monthlyFonts[month] = font
    }

    private func loadMonthlyThemes() {
        if let data = UserDefaults.standard.dictionary(forKey: monthlyThemesKey) as? [String: Int] {
            for (monthStr, themeRaw) in data {
                if let month = Int(monthStr), let theme = ColorTheme(rawValue: themeRaw) {
                    monthlyThemes[month] = theme
                }
            }
        }
    }

    private func loadMonthlyFonts() {
        if let data = UserDefaults.standard.dictionary(forKey: monthlyFontsKey) as? [String: String] {
            for (monthStr, font) in data {
                if let month = Int(monthStr) {
                    monthlyFonts[month] = font
                }
            }
        }
    }

    private func saveMonthlyThemes() {
        var data: [String: Int] = [:]
        for (month, theme) in monthlyThemes {
            data[String(month)] = theme.rawValue
        }
        UserDefaults.standard.set(data, forKey: monthlyThemesKey)
        UserDefaults.standard.synchronize()
    }

    private func saveMonthlyFonts() {
        var data: [String: String] = [:]
        for (month, font) in monthlyFonts {
            data[String(month)] = font
        }
        UserDefaults.standard.set(data, forKey: monthlyFontsKey)
        UserDefaults.standard.synchronize()
    }

    func resetToDefaults() {
        monthlyThemes.removeAll()
        monthlyFonts.removeAll()
        saveMonthlyThemes()
        saveMonthlyFonts()
    }

    /// Get available fonts for monthly selection
    static let availableFonts = [
        "Arial",
        "Helvetica",
        "Times New Roman",
        "Courier",
        "Georgia",
        "Verdana",
        "Trebuchet MS",
        "Impact",
        "Comic Sans MS",
        "Lucida Grande",
        "Futura",
        "Baskerville"
    ]
}
