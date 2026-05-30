//
//  ScrollViewWithFade.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - ScrollView with Fade Gradients
struct ScrollViewWithFade<Content: View>: View {
    let content: Content
    let fadeHeight: CGFloat = 8
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top fade area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: fadeHeight)
                    content
                    // Bottom fade area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: fadeHeight)
#if os(iOS)
                    // Add bottom padding to ensure content can scroll above safe area
                    // This accounts for safe area insets on iPhones with home indicators
                    Color.clear.frame(height: 60)
#endif
                }
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fadeHeight)
                    
                    Rectangle().fill(Color.black)
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fadeHeight)
                }
            )
        }
    }
}
