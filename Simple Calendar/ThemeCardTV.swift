//
//  ThemeCardTV.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/27/25.
//

import SwiftUI

// tvOS Theme Card Component
#if os(tvOS)
struct ThemeCard: View {
    let theme: ColorTheme
    let isSelected: Bool
    let isFocused: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @FocusState.Binding var focusedTheme: ColorTheme?
    @StateObject private var featureFlags = FeatureFlags.shared

    private var currentPalette: ColorPalette {
        theme.palette(for: themeManager.currentColorScheme)
    }

    private var expandedContent: some View {
        VStack(spacing: 8) {
            Text(theme.displayName)
                .font(.body)
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
            Text(theme.displayName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(currentPalette.textPrimary)

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
            // Save as manual theme if monthly theme mode is disabled
            if !featureFlags.useMonthlyThemeMode {
                themeManager.saveThemeAsManual(theme)
            }
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

