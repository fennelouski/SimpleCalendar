//
//  DayDetailSlideOut.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - Enhanced Day Detail Slide Out
struct DayDetailSlideOut: View {
    let date: Date
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var uiConfig: UIConfiguration
    
    @State private var slideOffset: CGFloat = 0
    @State private var isFullScreen = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var showOnRight: Bool? = nil // nil means use initial calculation
    @Environment(\.colorScheme) var colorScheme
    
    private var slideWidth: CGFloat {
#if os(tvOS)
        return 300 // Keep fixed width for tvOS for now, will be overridden by geometry
#else
        return 300
#endif
    }
    private let fullScreenThreshold: CGFloat = 150 // How far to pull to go full screen
    private let dismissThreshold: CGFloat = 100 // How far to drag to dismiss
    
    // Hysteresis thresholds - only switch sides when crossing these boundaries
    private let switchToRightThreshold: CGFloat = 0.32 // Switch to right when leading edge < 32%
    private let switchToLeftThreshold: CGFloat = 0.68  // Switch to left when trailing edge > 68%
    
    // Calculate the column index (0-6) for the selected date in the calendar grid
    private var columnIndex: Int {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, 7 = Saturday
        let firstWeekday = calendar.firstWeekday // 1 = Sunday in US, 2 = Monday elsewhere
        return (weekday - firstWeekday + 7) % 7
    }
    
    // Calculate leading edge position (0.0 to 1.0)
    private var leadingEdgePosition: CGFloat {
        return CGFloat(columnIndex) / 7.0
    }
    
    // Calculate trailing edge position (0.0 to 1.0)
    private var trailingEdgePosition: CGFloat {
        return CGFloat(columnIndex + 1) / 7.0
    }
    
    // Determine if the slide out should show on the right side (considering hysteresis)
    private var shouldShowOnRight: Bool {
        if let currentSide = showOnRight {
            // Apply hysteresis - only switch if crossing thresholds
            if currentSide {
                // Currently on right, switch to left if trailing edge > 68%
                return trailingEdgePosition <= switchToLeftThreshold
            } else {
                // Currently on left, switch to right if leading edge < 32%
                return leadingEdgePosition < switchToRightThreshold
            }
        } else {
            // Initial calculation - use center point
            let centerPosition = (leadingEdgePosition + trailingEdgePosition) / 2
            return centerPosition < 0.5
        }
    }
    
    // Public property for parent view to use for overlay alignment
    var currentAlignment: Alignment {
        return shouldShowOnRight ? .trailing : .leading
    }
    
    // For drag gesture direction calculation
    private var isOnRightSide: Bool {
        return shouldShowOnRight
    }
    
    private var dayDetailBackground: Color {
#if os(tvOS)
        return themeManager.currentTheme == .system ?
        Color.gray.opacity(0.95) : // More opaque solid background for system theme on tvOS
        themeManager.currentPalette.calendarSurface.opacity(0.95)
#else
        return themeManager.currentPalette.calendarSurface
#endif
    }
    
    private var fullScreenBackground: Color {
#if os(tvOS)
        return themeManager.currentTheme == .system ?
        Color.black.opacity(0.8) : // More opaque for system theme on tvOS
        Color.black.opacity(0.3)
#else
        return Color.black.opacity(0.3)
#endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay for full screen mode
                if isFullScreen {
                    fullScreenBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                calendarViewModel.showDayDetail = false
                            }
                        }
                }
                
                // Use HStack with Spacer to position on left or right
                HStack(spacing: 0) {
                    if isOnRightSide {
                        Spacer(minLength: 0)
                    }
                    
                    // Slide-out content
                    DayDetailView(date: date)
                        .frame(
                            width: {
                                if isFullScreen {
                                    return geometry.size.width
                                } else {
                                    #if os(iOS)
                                    // On iOS, the slide-over should be at least 400pt wide,
                                    // but never closer than 16pt to the screen edge.
                                    let maxWidth = geometry.size.width - 16
                                    return min(400, maxWidth)
                                    #else
                                    return (geometry.size.width / 3) - 16 // Account for 8pt inset on each side
                                    #endif
                                }
                            }()
                        )
                        .frame(maxHeight: isFullScreen ? .infinity : geometry.size.height)
                        .background(
                            CalendarGradientBackground(
                                baseColor: dayDetailBackground,
                                colorScheme: colorScheme,
                                intensity: .heavy
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 10)) // Increased from 6pt to 10pt
                        .shadow(radius: isFullScreen ? 0 : 10)
                        .padding(isFullScreen ? 0 : 16) // 16pt inset on all sides
#if os(iOS)
                        .safeAreaInset(edge: .top, spacing: 0) {
                            // Prevent view from getting stuck in safe area at top
                            Color.clear.frame(height: 0)
                        }
#endif
                        .offset(x: isOnRightSide ? slideOffset : -slideOffset)
#if !os(tvOS)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation.width
                                    let slideWidth = isFullScreen ? geometry.size.width : min(400, geometry.size.width - 16)
                                    
                                    if isFullScreen {
                                        // In full screen mode, only allow edge pan from appropriate edge
                                        if isOnRightSide {
                                            // Right side panel - allow pan from right edge
                                            if value.startLocation.x > geometry.size.width - 50 {
                                                // Clamp to prevent going beyond bounds
                                                slideOffset = max(-slideWidth, min(0, translation))
                                            }
                                        } else {
                                            // Left side panel - allow pan from left edge
                                            if value.startLocation.x < 50 {
                                                // Clamp to prevent going beyond bounds
                                                slideOffset = min(slideWidth, max(0, translation))
                                            }
                                        }
                                    } else {
                                        // In normal mode, allow pulling to full screen or dragging to close
                                        if isOnRightSide {
                                            // Right-side sliding: pulling left goes to full screen, right closes
                                            if translation < 0 {
                                                // Pulling to the left (towards full screen)
                                                // Allow up to slideWidth to the left, but not beyond
                                                slideOffset = max(-slideWidth * 0.5, translation)
                                            } else {
                                                // Dragging to the right (towards close)
                                                // Allow dragging all the way off screen to the right
                                                slideOffset = translation
                                            }
                                        } else {
                                            // Left-side sliding: pulling right goes to full screen, left closes
                                            // Note: offset uses -slideOffset, so positive slideOffset moves left, negative moves right
                                            if translation > 0 {
                                                // Pulling to the right (towards full screen)
                                                // slideOffset negative moves right (because -negative = positive offset)
                                                slideOffset = max(-slideWidth * 0.5, -translation)
                                            } else {
                                                // Dragging to the left (towards close)
                                                // slideOffset positive moves left (because -positive = negative offset)
                                                slideOffset = -translation
                                            }
                                        }
                                    }
                                }
                                .onEnded { value in
                                    let translation = value.translation.width
                                    let velocity = value.predictedEndTranslation.width
                                    
                                    withAnimation(.spring()) {
                                        if isFullScreen {
                                            // Full screen mode: edge pan to dismiss
                                            if isOnRightSide {
                                                // Right side - dismiss on drag right
                                                if slideOffset > dismissThreshold || velocity > 300 {
                                                    calendarViewModel.showDayDetail = false
                                                }
                                            } else {
                                                // Left side - dismiss on drag left
                                                if -slideOffset > dismissThreshold || velocity < -300 {
                                                    calendarViewModel.showDayDetail = false
                                                }
                                            }
                                            slideOffset = 0
                                        } else {
                                            // Normal mode
                                            if isOnRightSide {
                                                // Right-side sliding
                                                if translation < -fullScreenThreshold || velocity < -300 {
                                                    // Pulled far enough left - go full screen
                                                    isFullScreen = true
                                                    slideOffset = 0
                                                } else if translation > dismissThreshold || velocity > 300 {
                                                    // Dragged far enough right - close
                                                    calendarViewModel.showDayDetail = false
                                                } else {
                                                    // Return to original position
                                                    slideOffset = 0
                                                }
                                            } else {
                                                // Left-side sliding
                                                if translation > fullScreenThreshold || velocity > 300 {
                                                    // Pulled far enough right - go full screen
                                                    isFullScreen = true
                                                    slideOffset = 0
                                                } else if translation < -dismissThreshold || velocity < -300 {
                                                    // Dragged far enough left - close
                                                    calendarViewModel.showDayDetail = false
                                                } else {
                                                    // Return to original position
                                                    slideOffset = 0
                                                }
                                            }
                                        }
                                    }
                                }
                        )
#endif
                        .transition(.move(edge: isOnRightSide ? .trailing : .leading).combined(with: .opacity))
                    
                    if !isOnRightSide {
                        Spacer(minLength: 0)
                    }
                }
            }
#if os(iOS)
            .ignoresSafeArea(isFullScreen ? .all : [], edges: .bottom) // Only ignore bottom safe area when not fullscreen
#else
            .ignoresSafeArea(isFullScreen ? .all : [])
#endif
        }
        .animation(.easeInOut(duration: 0.3), value: date)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShowOnRight)
        .onChange(of: calendarViewModel.showDayDetail) { oldValue, newValue in
            if !newValue {
                withAnimation(.spring()) {
                    isFullScreen = false
                    slideOffset = 0
                }
            }
        }
        .onChange(of: date) {
            // Update the hysteresis state when date changes
            let newShouldShowOnRight = shouldShowOnRight
            if showOnRight != newShouldShowOnRight {
                showOnRight = newShouldShowOnRight
            }
        }
        .onAppear {
            // Initialize the side based on current position
            showOnRight = shouldShowOnRight
        }
    }
}
