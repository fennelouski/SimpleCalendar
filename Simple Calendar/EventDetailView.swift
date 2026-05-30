//
//  EventDetailView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    let showOversizedEmoji: Bool
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    @State private var eventImage: PlatformImage?
    @State private var weatherInfo: WeatherInfo?

    init(event: CalendarEvent, showOversizedEmoji: Bool = true) {
        self.event = event
        self.showOversizedEmoji = showOversizedEmoji
    }
    
    private var isAllDayEvent: Bool {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return hours >= 20 || event.isAllDay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event Image
            if let image = eventImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(platformImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                    
                    // Attribution overlay
                    if UserDefaults.standard.bool(forKey: "showUnsplashAttribution"),
                       let metadata = calendarViewModel.getImageMetadataForEvent(event) {
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
            
#if os(tvOS)
            // tvOS: Always show event title at top
            Text(event.title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(event.color != nil ? Color(hex: event.color!) : themeManager.currentPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)

            // tvOS: HUGE emoji/icon BENEATH the title text (only if showOversizedEmoji is true)
            if showOversizedEmoji {
                VStack(spacing: 20) {
                    // Use event's emoji if available, otherwise fallback to EventIconManager
                    if let eventEmoji = event.emoji ?? EventIconManager.emojiForEvent(event.title) {
                        Text(eventEmoji)
                            .font(.system(size: 144)) // Extra large for TV viewing
                    } else {
                        // Fallback: Large clock icon
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 104))
                            .foregroundColor(event.color != nil ? Color(hex: event.color!) : themeManager.currentPalette.accent)
                    }
                
                // Time information beneath the icon
                if isAllDayEvent {
                    Text("All Day".localized)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                } else {
                    HStack(spacing: 40) {
                        VStack(spacing: 6) {
                            Text("Starts".localized)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        
                        // Arrow separator
                        Image(systemName: "arrow.right")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.currentPalette.accent)
                        
                        VStack(spacing: 6) {
                            Text("Ends".localized)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.endDate.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            } // Close the showOversizedEmoji if statement
#else
            Text(event.title)
                .font(uiConfig.eventTitleFont)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentPalette.textPrimary)
#endif
            
#if !os(tvOS)
            // iOS/macOS: Icon inline with text
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                if isAllDayEvent {
                    Text("All Day".localized)
                        .font(uiConfig.eventDetailFont)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Starts:".localized)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.startDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Text("Ends:".localized)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Text(event.endDate.formatted(.dateTime.hour().minute()))
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                    }
                }
            }
#endif
            
            if let location = event.location {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                    Text(location)
                        .font(uiConfig.eventDetailFont)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                }
                
                // Map view for events with location
                EventMapView(location: location)
                    .frame(height: 100)
                    .cornerRadius(8)
                
                // Weather info for events with location
                if let weather = weatherInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weather Forecast".localized)
                            .font(uiConfig.eventDetailFont)
                            .foregroundColor(themeManager.currentPalette.textPrimary)
                        
                        HStack {
                            Image(systemName: weather.icon)
                                .foregroundColor(themeManager.currentPalette.accent)
                            Text(weather.temperatureString)
                                .font(uiConfig.eventDetailFont)
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text(weather.condition)
                                .font(uiConfig.captionFont)
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                        
                        HStack(spacing: 16) {
                            Label(weather.humidityString, systemImage: "humidity")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                            Label(weather.windSpeedString, systemImage: "wind")
                                .foregroundColor(themeManager.currentPalette.textSecondary)
                        }
                        .font(uiConfig.captionFont)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity) // Match map view width
                    .background(themeManager.currentPalette.surface.opacity(0.5))
                    .roundedCorners(.small)
                }
            }
            
            if let notes = event.notes {
                URLTextView(text: notes)
                    .font(uiConfig.scaledFont(.body))
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
        }
        .standardPadding()
        .background(themeManager.currentPalette.calendarSurface)
        .roundedCorners(.normal)
        .padding(.horizontal)
        .onAppear {
            loadEventImage()
            loadWeatherInfo()
        }
    }
    
    private func loadEventImage() {
        if let imageId = event.imageRepositoryId {
            eventImage = ImageManager.shared.getImage(for: imageId)
        } else {
            // Try to fetch an image for this event
            ImageManager.shared.findOrFetchImage(for: event) { imageId in
                if let imageId = imageId {
                    DispatchQueue.main.async {
                        self.eventImage = ImageManager.shared.getImage(for: imageId)
                    }
                }
            }
        }
    }
    
    private func loadWeatherInfo() {
        WeatherManager.shared.getWeatherForEvent(event) { weather in
            DispatchQueue.main.async {
                self.weatherInfo = weather
            }
        }
    }
}
