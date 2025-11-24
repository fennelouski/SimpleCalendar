//
//  HolidayDetailView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct HolidayDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @StateObject private var holidayManager = HolidayManager.shared

    var body: some View {
        NavigationView {
            ScrollViewWithFade {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Holiday Guide")
                            .font(uiConfig.eventTitleFont)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                        Text("Learn about holidays and their meanings")
                            .font(uiConfig.eventDetailFont)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

    // Holiday categories
    let holidaysByCategory = holidayManager.holidaysByCategory()

    ForEach(Array(CalendarHoliday.CalendarHolidayCategory.allCases), id: \.self) { category in
                        if let categoryHolidays = holidaysByCategory[category], !categoryHolidays.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                // Category header
                                Text(category.rawValue)
                                    .font(uiConfig.sectionTitleFont)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                    .padding(.horizontal)

                                // Holiday cards
                                VStack(spacing: 12) {
                                    ForEach(categoryHolidays.sorted { $0.date < $1.date }) { holiday in
                                        HolidayCard(holiday: holiday)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(themeManager.currentPalette.calendarBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Holiday Guide")
                        .font(uiConfig.titleFont)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                }
            }
        }
    }
}

struct HolidayCard: View {
    let holiday: CalendarHoliday

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @State private var holidayImage: PlatformImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with emoji and name
            HStack(spacing: 12) {
                Text(holiday.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                        Text(holiday.name)
                            .font(.title2)
                            .foregroundColor(themeManager.currentPalette.textPrimary)

                    Text(holiday.date.formatted(.dateTime.month(.wide).day()))
                        .font(uiConfig.captionFont)
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }

                Spacer()
            }

            // Description
            Text(holiday.description)
                .font(.body)
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .lineSpacing(4)

            // Holiday image (if available)
            if let image = holidayImage {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium.value))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium.value)
                            .stroke(themeManager.currentPalette.gridLine, lineWidth: 1)
                    )
            } else {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: CornerRadius.medium.value)
                    .fill(themeManager.currentPalette.surface.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Text("Loading image...")
                            .font(uiConfig.captionFont)
                            .foregroundColor(themeManager.currentPalette.textSecondary)
                    )
            }
        }
        .padding(16)
        .background(themeManager.currentPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium.value))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .onAppear {
            loadHolidayImage()
        }
    }

    private func loadHolidayImage() {
        Task {
            do {
                if let image = try await ImageManager.shared.getImage(for: holiday.unsplashSearchTerm) {
                    holidayImage = image
                }
            } catch {
                print("Failed to load holiday image: \(error)")
            }
        }
    }
}

struct         HolidayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HolidayDetailView()
            .environmentObject(ThemeManager())
            .environmentObject(UIConfiguration())
    }
}
