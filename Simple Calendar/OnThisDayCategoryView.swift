//
//  OnThisDayCategoryView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct OnThisDayCategoryView: View {
    let title: String
    let icon: String
    let items: [String]
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(uiConfig.eventDetailFont)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
            
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(uiConfig.eventDetailFont)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
