//
//  KeyboardShortcuts.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import Combine

extension Notification.Name {
    static let ToggleFullscreen = Notification.Name("ToggleFullscreen")
    static let ToggleSearch = Notification.Name("ToggleSearch")
    static let ToggleKeyCommands = Notification.Name("ToggleKeyCommands")
    static let RefreshCalendar = Notification.Name("RefreshCalendar")
}

#if os(macOS)
struct KeyEventHandler: NSViewRepresentable {
    let calendarViewModel: CalendarViewModel

    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlingView(calendarViewModel: calendarViewModel)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}

class KeyHandlingView: NSView {
    let calendarViewModel: CalendarViewModel

    init(calendarViewModel: CalendarViewModel) {
        self.calendarViewModel = calendarViewModel
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        switch event.keyCode {
        case 45: // n - check for command modifier first
            if event.modifierFlags.contains(.command) {
                if event.modifierFlags.contains(.shift) {
                    calendarViewModel.showEventTemplates = true
                } else {
                    calendarViewModel.showEventCreation = true
                }
            } else {
                calendarViewModel.navigateToNextMonth()
            }
        case 35: // p
            calendarViewModel.navigateToPreviousMonth()
        case 17: // t
            calendarViewModel.navigateToToday()
        case 18: // 1
            calendarViewModel.setViewMode(.singleDay)
        case 19: // 2
            calendarViewModel.setViewMode(.twoDays)
        case 20: // 3
            calendarViewModel.setViewMode(.threeDays)
        case 21: // 4
            calendarViewModel.setViewMode(.fourDays)
        case 23: // 5
            calendarViewModel.setViewMode(.fiveDays)
        case 22: // 6
            calendarViewModel.setViewMode(.sixDays)
        case 26: // 7
            calendarViewModel.setViewMode(.sevenDays)
        case 29: // 0
            calendarViewModel.setViewMode(.twoWeeks)
        case 126: // up arrow
            calendarViewModel.moveUpOneWeek()
        case 125: // down arrow
            calendarViewModel.moveDownOneWeek()
        case 123: // left arrow
            calendarViewModel.moveLeftOneDay()
        case 124: // right arrow
            calendarViewModel.moveRightOneDay()
        case 53: // escape
            calendarViewModel.showDayDetail = false
            calendarViewModel.showSearch = false
            calendarViewModel.showKeyCommands = false
        case 0: // a (with command modifier)
            if event.modifierFlags.contains(.command) {
                calendarViewModel.setViewMode(.agenda)
            }
        case 15: // r (with command modifier)
            if event.modifierFlags.contains(.command) {
                calendarViewModel.refresh()
            }
        default:
            break
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

struct KeyboardShortcutsViewModifier: ViewModifier {
    @EnvironmentObject var calendarViewModel: CalendarViewModel

    func body(content: Content) -> some View {
        content
            .background(KeyEventHandler(calendarViewModel: calendarViewModel))
    }
}
#endif

#if os(macOS)
extension View {
    func addKeyboardShortcuts() -> some View {
        modifier(KeyboardShortcutsViewModifier())
    }
}
#endif
