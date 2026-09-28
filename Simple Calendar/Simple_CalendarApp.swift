//
//  Simple_CalendarApp.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import SwiftData

@main
struct Simple_CalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var uiConfig = UIConfiguration()
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var monthlyThemeManager = MonthlyThemeManager.shared
    private let holidayManager = HolidayManager.shared

    @State private var sharedModelContainer: ModelContainer?
    @State private var startupError: String?

    private func openStore() {
        do {
            let schema = Schema([CalendarEvent.self])
            // App-owned events use the existing local store. System and Google
            // calendar synchronization are handled by their own services.
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
            startupError = nil
        } catch { startupError = error.localizedDescription }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let sharedModelContainer {
                    ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear { calendarViewModel.attachLocalStore(sharedModelContainer) }
                .environmentObject(calendarViewModel)
                .environmentObject(themeManager)
                .environmentObject(uiConfig)
                .environmentObject(featureFlags)
                .environmentObject(monthlyThemeManager)
                .environmentObject(holidayManager)
                } else if let startupError {
                    ContentUnavailableView {
                        Label("Saved events could not be opened", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(startupError)
                        Text("Your existing event files have been preserved.")
                    } actions: {
                        Button("Retry") { openStore() }
                    }
                } else {
                    ProgressView("Opening saved events")
                }
            }
            .task { if sharedModelContainer == nil { openStore() } }
        }
        #if !os(tvOS)
        .commands {
            #if os(macOS)
            CommandGroup(replacing: .appInfo) {
                Button("About Calendar Play") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: Notification.Name("ShowSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("New Event") {
                    NotificationCenter.default.post(name: Notification.Name("NewEvent"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(replacing: .help) {
                Button("Calendar Play Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
            #endif
        }
        #endif
    }

    #if os(macOS)
    private func showHelp() {
        // Create a new window for help
        let helpWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        helpWindow.center()
        helpWindow.title = "Calendar Play Help"
        helpWindow.contentView = NSHostingView(rootView: HelpView())
        helpWindow.makeKeyAndOrderFront(nil)
    }
    #endif
}
