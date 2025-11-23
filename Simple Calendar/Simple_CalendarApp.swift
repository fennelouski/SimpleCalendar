//
//  Simple_CalendarApp.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import SwiftData

@main
struct Simple_CalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var uiConfig = UIConfiguration()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CalendarEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarViewModel)
                .environmentObject(themeManager)
                .environmentObject(uiConfig)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            #if os(macOS)
            CommandGroup(replacing: .help) {
                Button("Simple Calendar Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
            #endif
        }
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
        helpWindow.title = "Simple Calendar Help"
        helpWindow.contentView = NSHostingView(rootView: HelpView())
        helpWindow.makeKeyAndOrderFront(nil)
    }
    #endif
}
