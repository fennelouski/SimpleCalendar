//
//  SearchView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var searchResults: [CalendarEvent] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedSearch = searchText.lowercased()
        return calendarViewModel.events.filter { event in
            event.title.lowercased().contains(lowercasedSearch) ||
            (event.location?.lowercased().contains(lowercasedSearch) ?? false) ||
            (event.notes?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                TextField("Search events or dates".localized, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .focused($isSearchFocused)
                Button(action: { calendarViewModel.toggleSearch() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
            }
            .padding()
            
            if !searchText.isEmpty {
                ScrollViewWithFade {
                    VStack(alignment: .leading, spacing: 8) {
                        if searchResults.isEmpty {
                            Text("No events found".localized)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                                .padding()
                        } else {
                            ForEach(searchResults) { event in
                                SearchResultRow(event: event)
                                    .onTapGesture {
                                        calendarViewModel.selectDate(event.startDate)
                                        calendarViewModel.toggleSearch()
                                        calendarViewModel.toggleDayDetail()
                                    }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    @FocusState private var isSearchFocused: Bool
}
