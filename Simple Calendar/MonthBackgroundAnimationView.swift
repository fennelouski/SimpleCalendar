//
//  MonthBackgroundAnimationView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

/// Main view that selects and displays the appropriate month animation
struct MonthBackgroundAnimationView: View {
    let currentDate: Date
    @StateObject private var featureFlags = FeatureFlags.shared
    
    // Hardcoded alpha at 60% (0.6) for all animations
    private let animationAlpha: Double = 0.6
    
    var body: some View {
        Group {
            if featureFlags.backgroundAnimationsEnabled {
                ZStack {
                    // Select animation based on current month
                    let calendar = Calendar(identifier: .gregorian)
                    let month = calendar.component(.month, from: currentDate)
                    
                    Group {
                        switch month {
                        case 1:
                            JanuarySnowAnimation(alpha: animationAlpha)
                        case 2:
                            FebruaryHeartCloudsAnimation(alpha: animationAlpha)
                        case 3:
                            MarchShamrocksAnimation(alpha: animationAlpha)
                        case 4:
                            AprilRainAnimation(alpha: animationAlpha)
                        case 5:
                            MayFlowersAnimation(alpha: animationAlpha)
                        case 6:
                            JuneButterfliesAnimation(alpha: animationAlpha)
                        case 7:
                            JulyFireworksAnimation(alpha: animationAlpha)
                        case 8:
                            AugustSunCloudsAnimation(alpha: animationAlpha)
                        case 9:
                            SeptemberLeavesAnimation(alpha: animationAlpha)
                        case 10:
                            OctoberMoonBatsAnimation(alpha: animationAlpha)
                        case 11:
                            NovemberLeavesAnimation(alpha: animationAlpha)
                        case 12:
                            DecemberChristmasLightsAnimation(alpha: animationAlpha)
                        default:
                            EmptyView()
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allow touches to pass through
            }
        }
    }
}

