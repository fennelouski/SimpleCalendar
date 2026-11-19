//
//  MonthBackgroundAnimationView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

/// Main view that selects and displays the appropriate month animation
struct MonthBackgroundAnimationView: View {
    /// Determines which month's scene is shown.
    let currentDate: Date
    /// The day the user has selected/focused. Scenes react to this day (weather, moon
    /// phase, daylight, special days); falls back to `currentDate`.
    var selectedDate: Date? = nil
    /// True while the background is fully hidden (e.g. behind a full-screen sheet); scenes stop rendering.
    var isPaused: Bool = false
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
                            JanuarySnowAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 2:
                            FebruaryHeartCloudsAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 3:
                            MarchShamrocksAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 4:
                            AprilRainAnimation(alpha: animationAlpha)
                        case 5:
                            MayFlowersAnimation(alpha: animationAlpha)
                        case 6:
                            JuneButterfliesAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 7:
                            JulyFireworksAnimation(alpha: animationAlpha)
                        case 8:
                            AugustSunCloudsAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 9:
                            SeptemberLeavesAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 10:
                            OctoberMoonBatsAnimation(alpha: animationAlpha, moonDate: selectedDate ?? currentDate)
                        case 11:
                            NovemberLeavesAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        case 12:
                            DecemberChristmasLightsAnimation(alpha: animationAlpha, date: selectedDate ?? currentDate)
                        default:
                            EmptyView()
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allow touches to pass through
                .environment(\.backgroundScenePaused, isPaused)
            }
        }
    }
}

