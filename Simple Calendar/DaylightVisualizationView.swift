//
//  DaylightVisualizationView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI

struct DaylightVisualizationView: View {
    let date: Date
    let width: CGFloat
    private let height: CGFloat = 3.0

    var body: some View {
        ZStack {
            ForEach(0..<96) { periodIndex in
                Rectangle()
                    .fill(colorForPeriod(periodIndex))
                    .frame(width: width / 96, height: height)
                    .offset(x: CGFloat(periodIndex) * (width / 96) - width/2 + (width / 96)/2)
            }
        }
        .frame(width: width, height: height)
    }

    private func colorForPeriod(_ periodIndex: Int) -> Color {
        // Each period represents 15 minutes (24 hours * 4 periods per hour = 96 periods)
        let hour = Double(periodIndex) * 24.0 / 96.0
        let daylightColor = DaylightManager.shared.colorForHour(hour, date: date)
        return daylightColor.swiftUIColor
    }
}
