//
//  PermissionPrimerView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/30/25.
//

import SwiftUI
#if !os(tvOS)
import EventKit
#endif

struct PermissionPrimerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    var onContinue: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        ZStack {
            themeManager.currentPalette.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Iconography
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(themeManager.currentPalette.primary)
                    .accessibilityHidden(true) // Decorative icon
                
                // Title
                Text("Calendar Access".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                    .accessibilityAddTraits(.isHeader)
                
                // Description
                Text("Calendar Play needs access to your calendar to display your schedule and help you manage events directly from the app.".localized)
                    .font(.body)
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Accessibility Note
                Text("We respect your privacy and only use this access to show and edit your calendar events.".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 8)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: onContinue) {
                        Text("Allow Access".localized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentPalette.primary) // Reverted to original theme color
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .accessibilityLabel("Allow Calendar Access".localized)
                    .accessibilityHint("Prompts the system dialog to grant calendar permissions.".localized)
                    
                    Button(action: onCancel) {
                        Text("Not Now".localized)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .accessibilityLabel("Not Now".localized) // Added missing localization
                    .accessibilityHint("Dismisses this screen without granting permission.".localized)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}
