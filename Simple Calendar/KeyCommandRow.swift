//
//  KeyCommandRow.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/28/25.
//

import SwiftUI

struct KeyCommandRow: View {
    let key: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(themeManager.currentPalette.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            Text(description)
                .foregroundColor(themeManager.currentPalette.textSecondary)
            Spacer()
        }
    }
}
