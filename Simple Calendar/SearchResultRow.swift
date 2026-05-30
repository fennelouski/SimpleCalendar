//
//  SearchResultRow.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct SearchResultRow: View {
    let event: CalendarEvent
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .foregroundColor(themeManager.currentPalette.textPrimary)
            
            HStack {
                Text(event.startDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                
                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
            
            if let location = event.location {
                Text(location)
                    .font(.caption)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .padding(.horizontal)
    }
}
