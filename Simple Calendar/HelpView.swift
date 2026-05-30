//
//  HelpView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct HelpView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSection: HelpSection = .gettingStarted

    enum HelpSection: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case navigation = "Navigation"
        case creatingEvents = "Creating Events"
        case eventImages = "Event Images"
        case googleCalendar = "Google Calendar"
        case keyboardShortcuts = "Keyboard Shortcuts"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .gettingStarted: return "star.circle"
            case .navigation: return "arrow.left.and.right"
            case .creatingEvents: return "plus.circle"
            case .eventImages: return "photo"
            case .googleCalendar: return "globe"
            case .keyboardShortcuts: return "keyboard"
            case .settings: return "gear"
            }
        }
        
        var localizedName: String {
            return self.rawValue.localized
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Calendar Play Help".localized)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(HelpSection.allCases, id: \.self) { section in
                        Button(action: {
                            selectedSection = section
                        }) {
                            HStack {
                                Image(systemName: section.icon)
                                    .frame(width: 20)
                                Text(section.localizedName)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedSection == section ? Color.blue.opacity(0.1) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 200)
                .background(Color.gray.opacity(0.1))

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        contentForSection(selectedSection)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    @ViewBuilder
    private func contentForSection(_ section: HelpSection) -> some View {
        switch section {
        case .gettingStarted:
            gettingStartedContent
        case .navigation:
            navigationContent
        case .creatingEvents:
            creatingEventsContent
        case .eventImages:
            eventImagesContent
        case .googleCalendar:
            googleCalendarContent
        case .keyboardShortcuts:
            keyboardShortcutsContent
        case .settings:
            settingsContent
        }
    }

    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to Calendar Play!".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Calendar Play is designed to help you and your kids understand how calendars work. It provides an intuitive interface for viewing and managing events with beautiful images and comprehensive features.".localized)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Key Features:".localized)
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "Multiple View Modes".localized, description: "Switch between day, week, month, and agenda views".localized)
                FeatureRow(icon: "photo", title: "Event Images".localized, description: "Add beautiful images to events using Unsplash integration".localized)
                FeatureRow(icon: "map", title: "Location Support".localized, description: "View maps for events with location information".localized)
                FeatureRow(icon: "globe", title: "Google Calendar".localized, description: "Sync with Google Calendar for comprehensive event management".localized)
                FeatureRow(icon: "keyboard", title: "Keyboard Navigation".localized, description: "Navigate efficiently using keyboard shortcuts".localized)
            }
        }
    }

    private var navigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Navigation".localized)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("View Modes:".localized)
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "Month View".localized, description: "Default view showing the entire month".localized)
                FeatureRow(icon: "calendar.day.timeline.left", title: "Day Views".localized, description: "Press 1-9 for 1-9 day views, 0 for 2-week view".localized)
                FeatureRow(icon: "list.bullet", title: "Agenda View".localized, description: "List view of all upcoming events".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Navigation:".localized)
                    .font(.headline)

                FeatureRow(icon: "arrow.left", title: "Previous Month".localized, description: "Press 'p' or use arrow keys".localized)
                FeatureRow(icon: "arrow.right", title: "Next Month".localized, description: "Press 'n' or use arrow keys".localized)
                FeatureRow(icon: "arrow.up.and.down", title: "Week Navigation".localized, description: "Up/Down arrows move by week".localized)
                FeatureRow(icon: "arrow.left.and.right", title: "Day Navigation".localized, description: "Left/Right arrows move by day".localized)
                FeatureRow(icon: "t.circle", title: "Today".localized, description: "Press 't' to jump to today's date".localized)
            }

            Text("Click on any day to select it. Double-click to open the day detail view.".localized)
                .foregroundColor(themeManager.currentPalette.textSecondary)
        }
    }

    private var creatingEventsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creating Events".localized)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Event Creation:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Click the '+' button in the toolbar or press Command+N".localized)
                    Text("• Enter event title, date, time, and location".localized)
                    Text("• Add notes and set reminders".localized)
                    Text("• Choose a calendar color".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Features:".localized)
                    .font(.headline)

                FeatureRow(icon: "repeat", title: "Recurring Events".localized, description: "Set events to repeat daily, weekly, monthly, or yearly".localized)
                FeatureRow(icon: "bell", title: "Reminders".localized, description: "Set custom reminder times before events".localized)
                FeatureRow(icon: "photo", title: "Event Images".localized, description: "Add images from Unsplash or your repository".localized)
                FeatureRow(icon: "map", title: "Location Maps".localized, description: "View maps for events with addresses".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Event Templates:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Create reusable event templates for common activities:".localized)
                    Text("• Press Command+Shift+T to open templates".localized)
                    Text("• Templates include pre-set duration, location, and notes".localized)
                    Text("• Quick way to create similar events".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var eventImagesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Images".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Add beautiful images to your events to make them more engaging and memorable. Calendar Play integrates with Unsplash to provide high-quality, royalty-free images.".localized)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("How to Add Images:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create a new event or edit an existing one".localized)
                    Text("2. In the event creation form, tap 'Event Image'".localized)
                    Text("3. Search for images by keywords (event title and location are suggested)".localized)
                    Text("4. Select an image from the results".localized)
                    Text("5. The image will be cached and associated with your event".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Smart Image Selection:".localized)
                    .font(.headline)

                FeatureRow(icon: "sparkles", title: "Similar Events".localized, description: "The app remembers images used for similar events and suggests them".localized)
                FeatureRow(icon: "location", title: "Location-Based".localized, description: "Images are chosen based on event location when available".localized)
                FeatureRow(icon: "photo.on.rectangle.angled", title: "Unsplash Integration".localized, description: "Access millions of beautiful, free images".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Attribution:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("All Unsplash images include photographer attribution by default.".localized)
                    Text("You can disable attribution in Settings > Images > Show Unsplash Attribution.".localized)
                    Text("Note: Always follow Unsplash's attribution guidelines when sharing images.".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var googleCalendarContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Google Calendar Integration".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Sync your events with Google Calendar for comprehensive calendar management across all your devices.".localized)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Setup:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Go to Settings (Command+,)".localized)
                    Text("2. Enable 'Google Calendar' toggle".localized)
                    Text("3. Click 'Sign in to Google'".localized)
                    Text("4. Follow the authentication flow".localized)
                    Text("5. Grant calendar access permissions".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Features:".localized)
                    .font(.headline)

                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Two-Way Sync".localized, description: "Events sync between Calendar Play and Google Calendar".localized)
                FeatureRow(icon: "calendar.badge.plus", title: "Multiple Calendars".localized, description: "Support for multiple Google Calendar accounts".localized)
                FeatureRow(icon: "bell.badge", title: "Notifications".localized, description: "Receive reminders from Google Calendar events".localized)
            }

            Text("Note: Your Google account credentials are never stored locally. Authentication uses secure OAuth 2.0.".localized)
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var keyboardShortcutsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Navigate efficiently using keyboard shortcuts. Press Command+K for a popup reference or Command+Shift+K to show shortcuts in the slide-out panel.".localized)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Navigation:".localized)
                    .font(.headline)

                KeyboardShortcutRow(shortcut: "n", description: "Next month".localized)
                KeyboardShortcutRow(shortcut: "p", description: "Previous month".localized)
                KeyboardShortcutRow(shortcut: "t", description: "Go to today".localized)
                KeyboardShortcutRow(shortcut: "↑↓", description: "Move up/down one week".localized)
                KeyboardShortcutRow(shortcut: "←→", description: "Move left/right one day".localized)
                KeyboardShortcutRow(shortcut: "1-9", description: "1-9 day view".localized)
                KeyboardShortcutRow(shortcut: "0", description: "2-week view".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Actions:".localized)
                    .font(.headline)

                KeyboardShortcutRow(shortcut: "⌘N", description: "New event".localized)
                KeyboardShortcutRow(shortcut: "⌘F", description: "Search events".localized)
                KeyboardShortcutRow(shortcut: "⌘D", description: "Show current day details".localized)
                KeyboardShortcutRow(shortcut: "Return", description: "Toggle day detail slide-out".localized)
                KeyboardShortcutRow(shortcut: "⌘K", description: "Show keyboard shortcuts popup".localized)
                KeyboardShortcutRow(shortcut: "⌘⇧K", description: "Show shortcuts in slide-out".localized)
                KeyboardShortcutRow(shortcut: "⌘⇧F", description: "Toggle fullscreen".localized)
                KeyboardShortcutRow(shortcut: "⌘,", description: "Open settings".localized)
                KeyboardShortcutRow(shortcut: "⌘⇧A", description: "Show agenda view".localized)
                KeyboardShortcutRow(shortcut: "⌘⇧T", description: "Show event templates".localized)
                KeyboardShortcutRow(shortcut: "⌘R", description: "Refresh calendar data".localized)
                KeyboardShortcutRow(shortcut: "⌘E", description: "Export selected events".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Double-Click:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Double-click any day to open day detail view".localized)
                    Text("• Double-click the same day again to close the slide-out".localized)
                    Text("• In day detail view, double-click events to edit them".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Customize Calendar Play to work the way you want it to.".localized)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Calendar Integration:".localized)
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "System Calendar".localized, description: "Sync with macOS Calendar app (always enabled)".localized)
                FeatureRow(icon: "globe", title: "Google Calendar".localized, description: "Connect your Google Calendar account".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance:".localized)
                    .font(.headline)

                FeatureRow(icon: "moon.stars", title: "Light/Dark Mode".localized, description: "Follows system appearance settings".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Images:".localized)
                    .font(.headline)

                FeatureRow(icon: "photo", title: "Unsplash Attribution".localized, description: "Show/hide photographer credits on images".localized)
                FeatureRow(icon: "trash", title: "Cache Management".localized, description: "Images are automatically cleaned up after 7 days".localized)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("About:".localized)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Version information".localized)
                    Text("• Built for teaching calendar concepts to kids".localized)
                    Text("• Designed for macOS with multiplatform support".localized)
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct KeyboardShortcutRow: View {
    let shortcut: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)

            Text(description)
                .foregroundColor(themeManager.currentPalette.textSecondary)

            Spacer()
        }
    }
}

