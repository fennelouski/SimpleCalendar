//
//  WeatherRotationClock.swift
//  Simple Calendar
//
//  One app-wide clock that alternates the day cells' weather indicator between
//  the icon and the high temperature.
//

import SwiftUI

/// Shared clock for `SmallWeatherIndicator` in the month grid.
///
/// Each day cell used to run its own 10-second loop, restarted whenever that
/// cell's weather loaded, so ~42 cells flipped at scattered moments and the grid
/// kept re-rendering piecemeal. Now a single task flips one value, every cell
/// shows the same state, and only cells that display weather (those that read
/// `state`) re-render, all in the same update.
@Observable
final class WeatherRotationClock {
    static let shared = WeatherRotationClock()

    /// How long each state stays on screen.
    static let interval: Duration = .seconds(10)

    private(set) var state: WeatherDisplayState = .icon

    @ObservationIgnored private var task: Task<Void, Never>?

    private init() {}

    /// Starts the clock if it isn't running yet. Safe to call from every cell.
    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: WeatherRotationClock.interval)
                guard let self, !Task.isCancelled else { return }
                // Feels-like is not shown yet (no data), so alternate icon and high temp.
                self.state = self.state == .icon ? .highTemp : .icon
            }
        }
    }
}
