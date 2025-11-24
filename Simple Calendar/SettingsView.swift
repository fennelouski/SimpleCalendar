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
    @Binding var showSettings: Bool
    @ObservedObject var googleOAuthManager: GoogleOAuthManager

    var body: some View {
        ZStack {
            themeManager.currentPalette.calendarBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Header
                VStack(spacing: 0) {
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
                    .background(themeManager.currentPalette.calendarSurface.opacity(0.95))
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Calendar Integration Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calendar Integration")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // System Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("System Calendar")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text("Sync with macOS Calendar")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }

                                    Spacer()

                                    // Info button
                                    Button(action: {
                                        // Could show info popover here
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }

                                    Toggle("", isOn: .constant(true))
                                        .disabled(true)
                                        .labelsHidden()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                // Google Calendar
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Google Calendar")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)
                                            .lineLimit(nil)

                                        Text(googleOAuthManager.isAuthenticated ?
                                            "Signed in as \(googleOAuthManager.userEmail ?? "Unknown")" :
                                            "Connect your Google Calendar")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .lineLimit(nil)
                                    }

                                    Spacer()

                                    // Info button
                                    Button(action: {
                                        // Could show info popover here
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                            .font(.system(size: 16))
                                    }

                                    Toggle("", isOn: .constant(false))
                                        .disabled(true)
                                        .labelsHidden()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }

                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Version
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Version")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.currentPalette.textPrimary)

                                        Text("Simple Calendar 1.0.0")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                Divider()

                                // About the App
                                Button(action: {
                                    // Could navigate to about page here
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("About the App")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.currentPalette.textPrimary)
                                                .lineLimit(nil)

                                            Text("Why I built this calendar")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .lineLimit(nil)
                                        }

                                        Spacer()

                                        // Info button
                                        Button(action: {
                                            // Could show info popover here
                                        }) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                                .font(.system(size: 16))
                                        }

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeManager.currentPalette.textSecondary)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(themeManager.currentPalette.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }

}

// Extension to add settings notification
extension Notification.Name {
    static let ShowSettings = Notification.Name("ShowSettings")
}

