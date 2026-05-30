//
//  URLTextView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

// MARK: - URL Text View
struct URLTextView: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showBrowserSelection = false
    @State private var selectedURL: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(textComponents, id: \.id) { component in
                switch component {
                case .text(let string):
                    Text(string)
                        .foregroundColor(themeManager.currentPalette.textPrimary)
                case .url(let url, let displayText):
                    Text(displayText)
                        .foregroundColor(themeManager.currentPalette.accent.opacity(0.8))
                        .bold()
                        .underline()
                        .onTapGesture {
                            selectedURL = url
                            showBrowserSelection = true
                        }
                }
            }
        }
        .sheet(isPresented: $showBrowserSelection) {
            if let url = selectedURL {
                BrowserSelectionView(url: url, isPresented: $showBrowserSelection)
            }
        }
    }
    
    private var textComponents: [URLTextComponent] {
        var components: [URLTextComponent] = []
        
        // Find URLs in the text
        let urlPattern = #"https?://[^\s]+"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: [])
        
        if let regex = regex {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var lastEnd = 0
            
            for match in matches {
                // Add text before the URL
                if match.range.location > lastEnd {
                    let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    let beforeText = nsString.substring(with: beforeRange)
                    components.append(.text(beforeText))
                }
                
                // Add the URL
                let urlString = nsString.substring(with: match.range)
                if let url = URL(string: urlString) {
                    components.append(.url(url, urlString))
                }
                
                lastEnd = match.range.location + match.range.length
            }
            
            // Add remaining text after the last URL
            if lastEnd < nsString.length {
                let remainingRange = NSRange(location: lastEnd, length: nsString.length - lastEnd)
                let remainingText = nsString.substring(with: remainingRange)
                components.append(.text(remainingText))
            }
        } else {
            // No URLs found, just return the text
            components.append(.text(text))
        }
        
        return components
    }
    
    private func extractDomain(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }
    
    private enum URLTextComponent: Identifiable {
        case text(String)
        case url(URL, String) // URL and display text
        
        var id: String {
            switch self {
            case .text(let string):
                return "text_\(string.hash)"
            case .url(let url, _):
                return "url_\(url.absoluteString.hash)"
            }
        }
    }
}
