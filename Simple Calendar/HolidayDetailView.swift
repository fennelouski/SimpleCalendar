//
//  HolidayDetailView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/30/25.
//

import SwiftUI

struct HolidayDetailView: View {
    let holiday: CalendarHoliday
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @State private var holidayImage: PlatformImage?
    @State private var isLoadingImage = false
    @Environment(\.dismiss) var dismiss

    private let holidayImageManager = HolidayImageManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Holiday Image
                if let image = holidayImage {
                    ZStack(alignment: .bottomTrailing) {
                        Image(platformImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)

                        // Attribution overlay
                        if UserDefaults.standard.bool(forKey: "showUnsplashAttribution") {
                            if let metadata = holidayImageManager.imageManager.getImageMetadata(for: holidayImageManager.getCachedImageIdForHoliday(holiday) ?? "") {
                                Text("Photo by %@".localized(with: metadata.author))
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentPalette.textPrimary)
                                    .padding(6)
                                    .background(themeManager.currentPalette.surface.opacity(0.9))
                                    .cornerRadius(4)
                                    .padding(4)
                            }
                        }
                    }
                } else if isLoadingImage {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentPalette.surface.opacity(0.5))
                            .frame(height: 200)

                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }

                // Holiday Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(holiday.emoji)
                            .font(.system(size: 32))
                        Text(holiday.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                        Spacer()
                    }

                    // Date
                    let dateFormatter = DateFormatter()
                    let _ = dateFormatter.dateStyle = .full
                    Text(dateFormatter.string(from: holiday.date))
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }

                // Description
                if !holiday.description.isEmpty {
                    Text(holiday.description)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                        .lineSpacing(4)
                }

                // Category
                HStack {
                    Text("Category:".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    Text(holiday.category.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentPalette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.currentPalette.surface.opacity(0.5))
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(holiday.name)
#if !os(tvOS) && !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            loadHolidayImage()
        }
    }

    private func loadHolidayImage() {
        isLoadingImage = true

        holidayImageManager.getImageForHoliday(holiday) { imageId in
            if let imageId = imageId,
               let image = self.holidayImageManager.imageManager.getImage(for: imageId) {
                self.holidayImage = image
            }

            self.isLoadingImage = false
        }
    }
}

#Preview {
    // Create a sample holiday for preview
    let calendar = Calendar(identifier: .gregorian)
    let date = calendar.date(from: DateComponents(year: 2024, month: 12, day: 25))!

    let sampleHoliday = CalendarHoliday(
        name: "Christmas Day",
        date: date,
        emoji: "🎄",
        description: "Christmas Day is celebrated on December 25 and is both a sacred religious holiday and a worldwide cultural and commercial phenomenon.",
        unsplashSearchTerm: "christmas morning",
        isRecurring: true,
        category: .christianHolidays
    )

    NavigationView {
        HolidayDetailView(holiday: sampleHoliday)
    }
}

