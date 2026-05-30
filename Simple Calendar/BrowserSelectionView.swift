//
//  BrowserSelectionView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - Browser Selection View
struct BrowserSelectionView: View {
    let url: URL
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Open Link")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                
                Text("Choose how to open this link:")
                    .foregroundColor(themeManager.currentPalette.textSecondary)
                
                Text(url.absoluteString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeManager.currentPalette.textPrimary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    Button(action: {
                        openURL(url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Open in Safari")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
#if os(macOS)
                    Button(action: {
                        // On macOS, we can try to open in other browsers
                        openInBrowser("com.google.Chrome", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Chrome")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        openInBrowser("com.microsoft.edgemac", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Edge")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        openInBrowser("org.mozilla.firefox", url: url)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                            Text("Open in Firefox")
                                .foregroundColor(themeManager.currentPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
#endif
                }
                .padding(.horizontal)
                
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(themeManager.currentPalette.textSecondary)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
#if os(iOS)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .navigationViewStyle(.stack)
#endif
        }
    }
    
#if os(macOS)
    private func openInBrowser(_ bundleIdentifier: String, url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = false
        
        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: "/Applications/\(bundleIdentifier).app"),
                                configuration: configuration) { _, error in
            if let error = error {
                print("Failed to open URL in browser: \(error)")
                // Fallback to default browser
                openURL(url)
            }
        }
    }
#endif
}
