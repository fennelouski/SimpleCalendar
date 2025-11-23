//
//  WeatherManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation

struct WeatherInfo: Codable, Identifiable {
    let id = UUID()
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Double
    let windSpeed: Double
    let location: String

    var temperatureString: String {
        return String(format: "%.0f°F", temperature)
    }

    var humidityString: String {
        return String(format: "%.0f%%", humidity)
    }

    var windSpeedString: String {
        return String(format: "%.1f mph", windSpeed)
    }
}

class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var weatherCache: [String: (info: WeatherInfo, timestamp: Date)] = [:]

    private let cacheDuration: TimeInterval = 30 * 60 // 30 minutes

    private init() {}

    func getWeather(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // Check cache first
        if let cached = weatherCache[location],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            completion(cached.info)
            return
        }

        // For demo purposes, return mock weather data
        // In a real app, this would call a weather API
        let mockWeather = WeatherInfo(
            temperature: Double.random(in: 50...85),
            condition: ["Sunny", "Partly Cloudy", "Cloudy", "Rainy", "Snowy"].randomElement() ?? "Sunny",
            icon: "sun.max",
            humidity: Double.random(in: 30...80),
            windSpeed: Double.random(in: 0...20),
            location: location
        )

        // Cache the result
        weatherCache[location] = (mockWeather, Date())
        completion(mockWeather)
    }

    func getWeatherForEvent(_ event: CalendarEvent, completion: @escaping (WeatherInfo?) -> Void) {
        guard let location = event.location, !location.isEmpty else {
            completion(nil)
            return
        }

        getWeather(for: location, completion: completion)
    }

    func clearCache() {
        weatherCache.removeAll()
    }
}
