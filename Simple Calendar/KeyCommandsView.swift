//
//  KeyCommandsView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct KeyCommandsView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts".localized)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { calendarViewModel.toggleKeyCommands() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
            }
            .padding()
            
            ScrollViewWithFade {
                VStack(alignment: .leading, spacing: 12) {
                    KeyCommandRow(key: "N", description: "Next month".localized)
                    KeyCommandRow(key: "P", description: "Previous month".localized)
                    KeyCommandRow(key: "T", description: "Go to today".localized)
                    KeyCommandRow(key: "1-9", description: "View mode (1-9 days)".localized)
                    KeyCommandRow(key: "0", description: "2-week view".localized)
                    KeyCommandRow(key: "↑↓", description: "Navigate weeks".localized)
                    KeyCommandRow(key: "←→", description: "Navigate days".localized)
                    KeyCommandRow(key: "Cmd + F", description: "Search".localized)
                    KeyCommandRow(key: "Cmd + Shift + F", description: "Toggle fullscreen".localized)
                    KeyCommandRow(key: "Cmd + K", description: "Show shortcuts".localized)
                    KeyCommandRow(key: "Cmd + Shift + K", description: "Show shortcuts in slide-out".localized)
                    KeyCommandRow(key: "Cmd + D", description: "Show day detail".localized)
                    KeyCommandRow(key: "Return", description: "Toggle day detail slide-out".localized)
                    KeyCommandRow(key: "Cmd + ,", description: "Settings".localized)
                    KeyCommandRow(key: "Cmd + A", description: "Switch to agenda view".localized)
                    KeyCommandRow(key: "Cmd + N", description: "Create new event".localized)
                    KeyCommandRow(key: "Cmd + Shift + N", description: "Quick create from templates".localized)
                    KeyCommandRow(key: "Double-click", description: "Show day detail (single day view stays)".localized)
                    KeyCommandRow(key: "Right-click", description: "Context menu with event options".localized)
                }
                .padding(.horizontal)
            }
        }
    }
}
