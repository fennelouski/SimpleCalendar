//
//  OnThisDaySection.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct OnThisDaySection: View {
    let date: Date
    let data: OnThisDayData?
    let isLoading: Bool
    let error: Error?
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On This Day".localized)
                    .font(uiConfig.eventTitleFont)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                
                Spacer()
                
                Text("Data from Wikipedia".localized)
                    .font(uiConfig.captionFont)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
            }
            
            Link("Wikipedia contributors · CC BY-SA 4.0", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
                .font(uiConfig.captionFont)
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if error != nil {
                Text("Unable to load historical data".localized)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .font(uiConfig.eventDetailFont)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let data = data, data.hasContent {
                VStack(alignment: .leading, spacing: 16) {
                    if !data.holidays.isEmpty {
                        OnThisDayCategoryView(
                            title: "Holidays & Observances".localized,
                            icon: "calendar",
                            items: data.holidays.map { $0.text },
                            sourcePages: data.holidays.map { $0.pages ?? [] },
                            color: .orange
                        )
                    }
                    
                    if !data.events.isEmpty {
                        OnThisDayCategoryView(
                            title: "Historical Events".localized,
                            icon: "clock",
                            items: data.events.map { $0.text },
                            sourcePages: data.events.map { $0.pages ?? [] },
                            color: .blue
                        )
                    }
                    
                    if !data.births.isEmpty {
                        OnThisDayCategoryView(
                            title: "Notable Births".localized,
                            icon: "person",
                            items: data.births.map { $0.text },
                            sourcePages: data.births.map { $0.pages ?? [] },
                            color: .green
                        )
                    }
                    
                    if !data.deaths.isEmpty {
                        OnThisDayCategoryView(
                            title: "Notable Deaths".localized,
                            icon: "person.crop.circle.badge.xmark",
                            items: data.deaths.map { $0.text },
                            sourcePages: data.deaths.map { $0.pages ?? [] },
                            color: .gray
                        )
                    }
                }
            } else {
                Text("No historical data available for this date".localized)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .font(uiConfig.eventDetailFont)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.currentPalette.surface.opacity(0.5))
        .cornerRadius(CornerRadius.medium.value)
        .padding(.horizontal)
    }
}
