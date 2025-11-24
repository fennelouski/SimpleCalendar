//
//  WeatherManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation
import Combine
#if canImport(WeatherKit)
import WeatherKit
#endif

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

    #if canImport(WeatherKit)
    private let weatherService = WeatherService()
    #endif

    private init() {}

    func getWeather(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // Check cache first
        if let cached = weatherCache[location],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            completion(cached.info)
            return
        }

        #if canImport(WeatherKit)
        // Use WeatherKit for accurate weather data
        getWeatherWithWeatherKit(for: location, completion: completion)
        #else
        // Fallback to mock data on older systems
        getMockWeather(for: location, completion: completion)
        #endif
    }

    #if canImport(WeatherKit)
    private func getWeatherWithWeatherKit(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // First geocode the location string to coordinates
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let coordinate = placemark.location?.coordinate else {
                // If geocoding fails, try to use a default location or return nil
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            Task {
                do {
                    let weather = try await self.weatherService.weather(for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))

                    // Convert WeatherKit data to our WeatherInfo format
                    let currentWeather = weather.currentWeather
                    let temperature = currentWeather.temperature.value
                    let condition = self.conditionString(from: currentWeather.condition)
                    let icon = self.iconString(from: currentWeather.condition)
                    let humidity = currentWeather.humidity * 100
                    let windSpeed = currentWeather.wind.speed.value * 2.237 // Convert m/s to mph

                    let weatherInfo = WeatherInfo(
                        temperature: temperature,
                        condition: condition,
                        icon: icon,
                        humidity: humidity,
                        windSpeed: windSpeed,
                        location: location
                    )

                    // Cache the result
                    DispatchQueue.main.async {
                        self.weatherCache[location] = (weatherInfo, Date())
                        completion(weatherInfo)
                    }
                } catch {
                    print("WeatherKit error: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }

    private func conditionString(from condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "Clear"
        case .cloudy:
            return "Cloudy"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .rain:
            return "Rainy"
        case .snow:
            return "Snowy"
        case .windy:
            return "Windy"
        case .foggy:
            return "Foggy"
        default:
            return "Clear"
        }
    }

    private func iconString(from condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max"
        case .cloudy:
            return "cloud"
        case .partlyCloudy:
            return "cloud.sun"
        case .rain:
            return "cloud.rain"
        case .snow:
            return "cloud.snow"
        case .windy:
            return "wind"
        case .foggy:
            return "cloud.fog"
        default:
            return "sun.max"
        }
    }
    #endif

    private func getMockWeather(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // Fallback mock weather data for systems without WeatherKit
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
