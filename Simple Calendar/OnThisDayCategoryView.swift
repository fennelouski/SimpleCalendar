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
    let sourcePages: [[Page]]
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
            
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 3) {
                Text("• \(item)")
                    .font(uiConfig.eventDetailFont)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if sourcePages.indices.contains(index) {
                    ForEach(Array(sourcePages[index].enumerated()), id: \.offset) { _, page in
                        if let string = page.content_urls?.desktop?.page, let url = URL(string: string), url.scheme == "https", url.host == "en.wikipedia.org" {
                            Link(page.title.replacingOccurrences(of: "_", with: " "), destination: url)
                                .font(uiConfig.captionFont)
                        }
                    }
                }
                }
            }
        }
    }
}
