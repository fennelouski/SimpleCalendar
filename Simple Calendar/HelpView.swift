//
//  HelpView.swift
//  Simple Calendar
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
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Simple Calendar Help")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
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
                                Text(section.rawValue)
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
            Text("Welcome to Simple Calendar!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Simple Calendar is designed to help you and your kids understand how calendars work. It provides an intuitive interface for viewing and managing events with beautiful images and comprehensive features.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Key Features:")
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "Multiple View Modes", description: "Switch between day, week, month, and agenda views")
                FeatureRow(icon: "photo", title: "Event Images", description: "Add beautiful images to events using Unsplash integration")
                FeatureRow(icon: "map", title: "Location Support", description: "View maps for events with location information")
                FeatureRow(icon: "globe", title: "Google Calendar", description: "Sync with Google Calendar for comprehensive event management")
                FeatureRow(icon: "keyboard", title: "Keyboard Navigation", description: "Navigate efficiently using keyboard shortcuts")
            }
        }
    }

    private var navigationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Navigation")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("View Modes:")
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "Month View", description: "Default view showing the entire month")
                FeatureRow(icon: "calendar.day.timeline.left", title: "Day Views", description: "Press 1-9 for 1-9 day views, 0 for 2-week view")
                FeatureRow(icon: "list.bullet", title: "Agenda View", description: "List view of all upcoming events")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Navigation:")
                    .font(.headline)

                FeatureRow(icon: "arrow.left", title: "Previous Month", description: "Press 'p' or use arrow keys")
                FeatureRow(icon: "arrow.right", title: "Next Month", description: "Press 'n' or use arrow keys")
                FeatureRow(icon: "arrow.up.and.down", title: "Week Navigation", description: "Up/Down arrows move by week")
                FeatureRow(icon: "arrow.left.and.right", title: "Day Navigation", description: "Left/Right arrows move by day")
                FeatureRow(icon: "t.circle", title: "Today", description: "Press 't' to jump to today's date")
            }

            Text("Click on any day to select it. Double-click to open the day detail view.")
                .foregroundColor(themeManager.currentPalette.textSecondary)
        }
    }

    private var creatingEventsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creating Events")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Event Creation:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Click the '+' button in the toolbar or press Command+N")
                    Text("• Enter event title, date, time, and location")
                    Text("• Add notes and set reminders")
                    Text("• Choose a calendar color")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Features:")
                    .font(.headline)

                FeatureRow(icon: "repeat", title: "Recurring Events", description: "Set events to repeat daily, weekly, monthly, or yearly")
                FeatureRow(icon: "bell", title: "Reminders", description: "Set custom reminder times before events")
                FeatureRow(icon: "photo", title: "Event Images", description: "Add images from Unsplash or your repository")
                FeatureRow(icon: "map", title: "Location Maps", description: "View maps for events with addresses")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Event Templates:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Create reusable event templates for common activities:")
                    Text("• Press Command+Shift+T to open templates")
                    Text("• Templates include pre-set duration, location, and notes")
                    Text("• Quick way to create similar events")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var eventImagesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Images")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add beautiful images to your events to make them more engaging and memorable. Simple Calendar integrates with Unsplash to provide high-quality, royalty-free images.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("How to Add Images:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create a new event or edit an existing one")
                    Text("2. In the event creation form, tap 'Event Image'")
                    Text("3. Search for images by keywords (event title and location are suggested)")
                    Text("4. Select an image from the results")
                    Text("5. The image will be cached and associated with your event")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Smart Image Selection:")
                    .font(.headline)

                FeatureRow(icon: "sparkles", title: "Similar Events", description: "The app remembers images used for similar events and suggests them")
                FeatureRow(icon: "location", title: "Location-Based", description: "Images are chosen based on event location when available")
                FeatureRow(icon: "photo.on.rectangle.angled", title: "Unsplash Integration", description: "Access millions of beautiful, free images")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Attribution:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("All Unsplash images include photographer attribution by default.")
                    Text("You can disable attribution in Settings > Images > Show Unsplash Attribution.")
                    Text("Note: Always follow Unsplash's attribution guidelines when sharing images.")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var googleCalendarContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Google Calendar Integration")
                .font(.title2)
                .fontWeight(.bold)

            Text("Sync your events with Google Calendar for comprehensive calendar management across all your devices.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Setup:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Go to Settings (Command+,)")
                    Text("2. Enable 'Google Calendar' toggle")
                    Text("3. Click 'Sign in to Google'")
                    Text("4. Follow the authentication flow")
                    Text("5. Grant calendar access permissions")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Features:")
                    .font(.headline)

                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Two-Way Sync", description: "Events sync between Simple Calendar and Google Calendar")
                FeatureRow(icon: "calendar.badge.plus", title: "Multiple Calendars", description: "Support for multiple Google Calendar accounts")
                FeatureRow(icon: "bell.badge", title: "Notifications", description: "Receive reminders from Google Calendar events")
            }

            Text("Note: Your Google account credentials are never stored locally. Authentication uses secure OAuth 2.0.")
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var keyboardShortcutsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)

            Text("Navigate efficiently using keyboard shortcuts. Press Command+K for a popup reference or Command+Shift+K to show shortcuts in the slide-out panel.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Navigation:")
                    .font(.headline)

                KeyboardShortcutRow(shortcut: "n", description: "Next month")
                KeyboardShortcutRow(shortcut: "p", description: "Previous month")
                KeyboardShortcutRow(shortcut: "t", description: "Go to today")
                KeyboardShortcutRow(shortcut: "↑↓", description: "Move up/down one week")
                KeyboardShortcutRow(shortcut: "←→", description: "Move left/right one day")
                KeyboardShortcutRow(shortcut: "1-9", description: "1-9 day view")
                KeyboardShortcutRow(shortcut: "0", description: "2-week view")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Actions:")
                    .font(.headline)

                KeyboardShortcutRow(shortcut: "⌘N", description: "New event")
                KeyboardShortcutRow(shortcut: "⌘F", description: "Search events")
                KeyboardShortcutRow(shortcut: "⌘D", description: "Show current day details")
                KeyboardShortcutRow(shortcut: "Return", description: "Toggle day detail slide-out")
                KeyboardShortcutRow(shortcut: "⌘K", description: "Show keyboard shortcuts popup")
                KeyboardShortcutRow(shortcut: "⌘⇧K", description: "Show shortcuts in slide-out")
                KeyboardShortcutRow(shortcut: "⌘⇧F", description: "Toggle fullscreen")
                KeyboardShortcutRow(shortcut: "⌘,", description: "Open settings")
                KeyboardShortcutRow(shortcut: "⌘⇧A", description: "Show agenda view")
                KeyboardShortcutRow(shortcut: "⌘⇧T", description: "Show event templates")
                KeyboardShortcutRow(shortcut: "⌘R", description: "Refresh calendar data")
                KeyboardShortcutRow(shortcut: "⌘E", description: "Export selected events")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Double-Click:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Double-click any day to open day detail view")
                    Text("• Double-click the same day again to close the slide-out")
                    Text("• In day detail view, double-click events to edit them")
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            Text("Customize Simple Calendar to work the way you want it to.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("Calendar Integration:")
                    .font(.headline)

                FeatureRow(icon: "calendar", title: "System Calendar", description: "Sync with macOS Calendar app (always enabled)")
                FeatureRow(icon: "globe", title: "Google Calendar", description: "Connect your Google Calendar account")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance:")
                    .font(.headline)

                FeatureRow(icon: "moon.stars", title: "Light/Dark Mode", description: "Follows system appearance settings")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Images:")
                    .font(.headline)

                FeatureRow(icon: "photo", title: "Unsplash Attribution", description: "Show/hide photographer credits on images")
                FeatureRow(icon: "trash", title: "Cache Management", description: "Images are automatically cleaned up after 7 days")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("About:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Version information")
                    Text("• Built for teaching calendar concepts to kids")
                    Text("• Designed for macOS with multiplatform support")
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

