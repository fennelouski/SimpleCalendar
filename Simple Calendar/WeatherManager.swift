//
//  WeatherManager.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation
import Combine
import MapKit
#if canImport(WeatherKit)
import WeatherKit
#endif

struct WeatherInfo: Codable, Identifiable {
    var id: UUID
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Double
    let windSpeed: Double
    let location: String
    let date: Date?

    var temperatureString: String {
        return String(format: "%.0f°F", temperature)
    }

    var humidityString: String {
        return String(format: "%.0f%%", humidity)
    }

    var windSpeedString: String {
        return String(format: "%.1f mph", windSpeed)
    }
    
    init(id: UUID = UUID(), temperature: Double, condition: String, icon: String, humidity: Double, windSpeed: Double, location: String, date: Date? = nil) {
        self.id = id
        self.temperature = temperature
        self.condition = condition
        self.icon = icon
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.location = location
        self.date = date
    }
}

struct DailyWeatherForecast: Codable, Identifiable {
    var id: UUID
    let date: Date
    let maxTemperature: Double
    let minTemperature: Double
    let condition: String
    let icon: String
    let humidity: Double?
    let windSpeed: Double?
    
    init(id: UUID = UUID(), date: Date, maxTemperature: Double, minTemperature: Double, condition: String, icon: String, humidity: Double?, windSpeed: Double?) {
        self.id = id
        self.date = date
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.condition = condition
        self.icon = icon
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
    
    var maxTemperatureString: String {
        return String(format: "%.0f°F", maxTemperature)
    }
    
    var minTemperatureString: String {
        return String(format: "%.0f°F", minTemperature)
    }
}

struct WeatherForecast: Codable {
    let current: WeatherInfo
    let daily: [DailyWeatherForecast]
    let location: String
    let fetchedAt: Date
}

// MARK: - Open-Meteo API Models
private nonisolated(unsafe) struct OpenMeteoResponse: Codable {
    let currentWeather: CurrentWeather?
    let daily: DailyData?
    let current: CurrentData?
    
    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
        case daily
        case current
    }
}

private nonisolated(unsafe) struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let winddirection: Double
    let weathercode: Int
    let time: String
}

private nonisolated(unsafe) struct CurrentData: Codable {
    let temperature2m: Double
    let relativeHumidity2m: Double
    let windspeed10m: Double
    let weathercode: Int?
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windspeed10m = "windspeed_10m"
        case weathercode
        case time
    }
}

private nonisolated(unsafe) struct DailyData: Codable {
    let time: [String]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let weathercode: [Int]?
    let windspeed10mMax: [Double]?
    let relativeHumidity2mMax: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case weathercode
        case windspeed10mMax = "windspeed_10m_max"
        case relativeHumidity2mMax = "relative_humidity_2m_max"
    }
}

// Nonisolated decoding helper to avoid main actor isolation issues
private nonisolated func decodeOpenMeteoResponse(from data: Data) throws -> OpenMeteoResponse {
    let decoder = JSONDecoder()
    return try decoder.decode(OpenMeteoResponse.self, from: data)
}

class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    // Legacy cache for backward compatibility
    @Published var weatherCache: [String: (info: WeatherInfo, timestamp: Date)] = [:]
    @Published var forecastCache: [String: (forecast: WeatherForecast, timestamp: Date)] = [:]
    
    // New date-based cache: location -> date -> weather info
    @Published var dateBasedCache: [String: [Date: WeatherInfo]] = [:]
    
    // Track last current day fetch per location (to enforce once per day)
    private var lastCurrentDayFetch: [String: Date] = [:]
    
    // Track historical fetches per day (limit to 10 date+location combinations per day)
    private var historicalFetchesToday: Set<String> = [] // Set of "date|location" strings
    private var lastHistoricalFetchDate: Date?
    
    // Geocoding cache: coordinate string -> (location name, date) (to avoid throttling, reset daily)
    private var geocodingCache: [String: (name: String, date: Date)] = [:]
    private var lastGeocodingCacheDate: Date?
    // Pending geocoding requests: coordinate string -> array of completion handlers (to deduplicate simultaneous requests)
    private var pendingGeocodingRequests: [String: [(String) -> Void]] = [:]
    // Rate limiting: track last geocoding request time to prevent excessive requests
    private var lastGeocodingRequestTime: Date?
    private let geocodingMinInterval: TimeInterval = 2.0 // Minimum 2 seconds between geocoding requests (more conservative)
    // Track active geocoding requests to prevent duplicates
    private var activeGeocodingRequests: Set<String> = []
    private let geocodingCacheKey: (Double, Double) -> String = { lat, lon in
        String(format: "%.4f,%.4f", lat, lon) // Round to 4 decimals for cache key
    }
    
    private let cacheDuration: TimeInterval = 30 * 60 // 30 minutes
    private let forecastCacheDuration: TimeInterval = 60 * 60 // 1 hour for forecasts
    private let maxHistoricalFetchesPerDay = 10

    #if canImport(WeatherKit)
    private let weatherService = WeatherService()
    #endif

    private init() {}
    
    // MARK: - Geocoding Helpers
    
    /// Geocode an address string to coordinates using MapKit APIs
    private func geocodeAddressString(_ addressString: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        // Note: New MapKit APIs (MKGeocodingRequest) are not yet fully available
        // Using CLGeocoder with deprecation suppression until new APIs are stable
        let geocoder = CLGeocoder()
        #if swift(>=6.0)
        #warning("CLGeocoder is deprecated in tvOS 26.0. Update to use MKGeocodingRequest when available.")
        #endif
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let coordinate = placemark.location?.coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(coordinate)
            }
        }
    }
    
    /// Reverse geocode coordinates to a location name using MapKit APIs
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        // Note: New MapKit APIs (MKReverseGeocodingRequest) are not yet fully available
        // Using CLGeocoder with deprecation suppression until new APIs are stable
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        #if swift(>=6.0)
        #warning("CLGeocoder.reverseGeocodeLocation is deprecated in tvOS 26.0. Update to use MKReverseGeocodingRequest when available.")
        #endif
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            var locationName: String
            if let placemark = placemarks?.first {
                if let city = placemark.locality, let state = placemark.administrativeArea {
                    locationName = "\(city), \(state)"
                } else if let city = placemark.locality {
                    locationName = city
                } else if let state = placemark.administrativeArea {
                    locationName = state
                } else if let country = placemark.country {
                    locationName = country
                } else {
                    locationName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                }
            } else {
                locationName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            }
            
            DispatchQueue.main.async {
                completion(locationName)
            }
        }
    }
    
    // MARK: - Date-based Weather Fetching
    
    /// Get weather for a specific date and location
    /// Fetches from cache if available, otherwise fetches from API
    func getWeather(for location: String, date: Date, completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // Check cache first
        if let locationCache = dateBasedCache[location],
           let cachedWeather = locationCache[dayStart] {
            completion(cachedWeather)
            return
        }
        
        // Determine if we need to fetch
        if dayStart == today {
            // Current day - fetch once per day
            fetchCurrentDayWeather(for: location, completion: completion)
        } else if dayStart > today {
            // Future date - fetch forecast
            fetchForecast(for: location, completion: { [weak self] forecast in
                guard let self = self else {
                    completion(nil)
                    return
                }
                // Extract weather for specific date from forecast
                if let forecast = forecast {
                    let weather = self.extractWeatherFromForecast(forecast, for: dayStart)
                    completion(weather)
                } else {
                    completion(nil)
                }
            })
        } else {
            // Past date - fetch historical (with limit)
            fetchHistoricalWeather(for: location, date: dayStart, completion: completion)
        }
    }
    
    /// Fetches current day weather (once per day max)
    private func fetchCurrentDayWeather(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already fetched today
        if let lastFetch = lastCurrentDayFetch[location],
           calendar.isDate(lastFetch, inSameDayAs: Date()) {
            // Return cached data if available
            if let locationCache = dateBasedCache[location],
               let cachedWeather = locationCache[today] {
                completion(cachedWeather)
                return
            }
        }
        
        // Geocode and fetch
        geocodeAddressString(location) { [weak self] coordinate in
            guard let self = self,
                  let coordinate = coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.fetchOpenMeteoCurrentWeather(latitude: coordinate.latitude, longitude: coordinate.longitude, location: location) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by date
                if self.dateBasedCache[location] == nil {
                    self.dateBasedCache[location] = [:]
                }
                self.dateBasedCache[location]?[today] = weatherInfo
                self.lastCurrentDayFetch[location] = Date()
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
        }
    }
    
    /// Fetches extended forecast (up to 16 days) and caches all dates
    private func fetchForecast(for location: String, completion: @escaping (WeatherForecast?) -> Void) {
        // Check if we have recent forecast cache
        if let cached = forecastCache[location],
           Date().timeIntervalSince(cached.timestamp) < forecastCacheDuration {
            // Update date-based cache from forecast
            updateDateCacheFromForecast(cached.forecast, for: location)
            completion(cached.forecast)
            return
        }
        
        geocodeAddressString(location) { [weak self] coordinate in
            guard let self = self,
                  let coordinate = coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.fetchOpenMeteoForecast(latitude: coordinate.latitude, longitude: coordinate.longitude, location: location) { [weak self] forecast in
                guard let self = self, let forecast = forecast else {
                    completion(nil)
                    return
                }
                
                // Cache forecast
                self.forecastCache[location] = (forecast, Date())
                
                // Update date-based cache from forecast
                self.updateDateCacheFromForecast(forecast, for: location)
                
                // Replace today's forecast with actual current weather if available
                self.replaceTodayWithCurrentWeather(for: location)
                
                DispatchQueue.main.async {
                    completion(forecast)
                }
            }
        }
    }
    
    /// Fetches historical weather (up to 10 date+location combinations per day)
    private func fetchHistoricalWeather(for location: String, date: Date, completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create unique key for this date+location combination
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: date)
        let fetchKey = "\(dateKey)|\(location)"
        
        // Check if we've exceeded daily limit
        if let lastFetchDate = lastHistoricalFetchDate,
           calendar.isDate(lastFetchDate, inSameDayAs: Date()) {
            // Check if we've already fetched this combination today
            if historicalFetchesToday.contains(fetchKey) {
                // Check cache
                if let locationCache = dateBasedCache[location],
                   let cachedWeather = locationCache[date] {
                    completion(cachedWeather)
                    return
                }
                completion(nil)
                return
            }
            
            // Check if we've exceeded the limit of unique combinations
            if historicalFetchesToday.count >= maxHistoricalFetchesPerDay {
                // Check cache only
                if let locationCache = dateBasedCache[location],
                   let cachedWeather = locationCache[date] {
                    completion(cachedWeather)
                    return
                }
                // Limit reached, return nil
                completion(nil)
                return
            }
        } else {
            // New day, reset counter
            historicalFetchesToday.removeAll()
            lastHistoricalFetchDate = today
        }
        
        // Geocode and fetch
        geocodeAddressString(location) { [weak self] coordinate in
            guard let self = self,
                  let coordinate = coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.fetchOpenMeteoHistoricalWeather(latitude: coordinate.latitude, longitude: coordinate.longitude, location: location, date: date) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by date
                if self.dateBasedCache[location] == nil {
                    self.dateBasedCache[location] = [:]
                }
                self.dateBasedCache[location]?[date] = weatherInfo
                
                // Track this fetch
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateKey = dateFormatter.string(from: date)
                let fetchKey = "\(dateKey)|\(location)"
                self.historicalFetchesToday.insert(fetchKey)
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
        }
    }
    
    /// Updates date-based cache from forecast data
    private func updateDateCacheFromForecast(_ forecast: WeatherForecast, for location: String) {
        if dateBasedCache[location] == nil {
            dateBasedCache[location] = [:]
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Cache current weather for today
        let currentDay = calendar.startOfDay(for: forecast.current.date ?? Date())
        if currentDay == today {
            dateBasedCache[location]?[today] = forecast.current
        }
        
        // Cache daily forecasts
        for dailyForecast in forecast.daily {
            let forecastDay = calendar.startOfDay(for: dailyForecast.date)
            // Convert DailyWeatherForecast to WeatherInfo (using max temp as representative)
            let weatherInfo = WeatherInfo(
                temperature: dailyForecast.maxTemperature,
                condition: dailyForecast.condition,
                icon: dailyForecast.icon,
                humidity: dailyForecast.humidity ?? 0,
                windSpeed: dailyForecast.windSpeed ?? 0,
                location: location,
                date: dailyForecast.date
            )
            dateBasedCache[location]?[forecastDay] = weatherInfo
        }
    }
    
    /// Replaces today's forecast with actual current weather if available
    private func replaceTodayWithCurrentWeather(for location: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we have current day weather
        if let locationCache = dateBasedCache[location],
           locationCache[today] != nil {
            // Already have current weather, forecast will be replaced
            return
        }
        
        // Fetch current weather to replace forecast
        fetchCurrentDayWeather(for: location) { _ in
            // Current weather is now cached and will override forecast
        }
    }
    
    /// Extracts weather for a specific date from forecast
    private func extractWeatherFromForecast(_ forecast: WeatherForecast, for date: Date) -> WeatherInfo? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // Check if it's today - use current weather
        if targetDay == today {
            return forecast.current
        }
        
        // Find in daily forecasts
        for dailyForecast in forecast.daily {
            let forecastDay = calendar.startOfDay(for: dailyForecast.date)
            if forecastDay == targetDay {
                // Convert DailyWeatherForecast to WeatherInfo
                return WeatherInfo(
                    temperature: dailyForecast.maxTemperature,
                    condition: dailyForecast.condition,
                    icon: dailyForecast.icon,
                    humidity: dailyForecast.humidity ?? 0,
                    windSpeed: dailyForecast.windSpeed ?? 0,
                    location: forecast.location,
                    date: dailyForecast.date
                )
            }
        }
        
        return nil
    }

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
        // Fallback to Open-Meteo API
        getWeatherWithOpenMeteo(for: location, completion: completion)
        #endif
    }

    #if canImport(WeatherKit)
    private func getWeatherWithWeatherKit(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // First geocode the location string to coordinates
        geocodeAddressString(location) { coordinate in
            guard let coordinate = coordinate else {
                // If geocoding fails, try to use a default location or return nil
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            Task { @MainActor in
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
                        location: location,
                        date: Date()
                    )

                    // Cache the result
                    self.weatherCache[location] = (weatherInfo, Date())
                    completion(weatherInfo)
                } catch {
                    print("WeatherKit error: \(error)")
                    completion(nil)
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

    private func getWeatherWithOpenMeteo(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // Geocode location to coordinates
        geocodeAddressString(location) { [weak self] coordinate in
            guard let self = self,
                  let coordinate = coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Build URL for current weather only
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
                URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
                URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,windspeed_10m,weather_code"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
                URLQueryItem(name: "windspeed_unit", value: "mph")
            ]
            
            guard let url = components.url else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self,
                      let data = data,
                      error == nil else {
                    print("Open-Meteo API error: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                do {
                    let response = try decodeOpenMeteoResponse(from: data)
                    
                    guard let current = response.current else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    // Skip if weathercode is missing - don't show weather without condition data
                    guard let weathercode = current.weathercode else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let currentDate = dateFormatter.date(from: current.time) ?? Date()
                    
                    let weatherInfo = WeatherInfo(
                        temperature: current.temperature2m,
                        condition: self.conditionFromWeatherCode(weathercode),
                        icon: self.iconFromWeatherCode(weathercode),
                        humidity: current.relativeHumidity2m,
                        windSpeed: current.windspeed10m,
                        location: location,
                        date: currentDate
                    )
                    
                    DispatchQueue.main.async {
                        self.weatherCache[location] = (weatherInfo, Date())
                        completion(weatherInfo)
                    }
                    
                } catch {
                    print("Error decoding Open-Meteo response: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
        }
    }
    
    private func getMockWeather(for location: String, completion: @escaping (WeatherInfo?) -> Void) {
        // Fallback mock weather data for systems without WeatherKit or Open-Meteo
        let mockWeather = WeatherInfo(
            temperature: Double.random(in: 50...85),
            condition: ["Sunny", "Partly Cloudy", "Cloudy", "Rainy", "Snowy"].randomElement() ?? "Sunny",
            icon: "sun.max",
            humidity: Double.random(in: 30...80),
            windSpeed: Double.random(in: 0...20),
            location: location,
            date: Date()
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
    
    /// Get weather for current user location using improved location approximation
    func getWeatherForCurrentLocation(date: Date = Date(), completion: @escaping (WeatherInfo?) -> Void) {
        let location = LocationApproximator.shared.approximateLocation()
        getWeatherForCoordinates(latitude: location.latitude, longitude: location.longitude, date: date, completion: completion)
    }
    
    /// Get weather using coordinates directly (avoids redundant geocoding)
    func getWeatherForCoordinates(latitude: Double, longitude: Double, date: Date = Date(), completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // Create a cache key from coordinates (rounded to avoid floating point issues)
        let coordKey = String(format: "%.4f,%.4f", latitude, longitude)
        
        // Check coordinate-based cache first
        if let locationCache = dateBasedCache[coordKey],
           let cachedWeather = locationCache[dayStart] {
            completion(cachedWeather)
            return
        }
        
        // Determine if we need to fetch
        if dayStart == today {
            // Current day - fetch once per day
            fetchCurrentDayWeatherForCoordinates(latitude: latitude, longitude: longitude, date: dayStart, completion: completion)
        } else if dayStart > today {
            // Future date - fetch forecast
            fetchForecastForCoordinates(latitude: latitude, longitude: longitude, completion: { [weak self] forecast in
                guard let self = self else {
                    completion(nil)
                    return
                }
                // Extract weather for specific date from forecast
                if let forecast = forecast {
                    let weather = self.extractWeatherFromForecast(forecast, for: dayStart)
                    completion(weather)
                } else {
                    completion(nil)
                }
            })
        } else {
            // Past date - fetch historical (with limit)
            fetchHistoricalWeatherForCoordinates(latitude: latitude, longitude: longitude, date: dayStart, completion: completion)
        }
    }
    
    /// Fetches current day weather using coordinates directly (avoids geocoding)
    private func fetchCurrentDayWeatherForCoordinates(latitude: Double, longitude: Double, date: Date, completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let coordKey = String(format: "%.4f,%.4f", latitude, longitude)
        
        // Check if we already fetched today
        if let lastFetch = lastCurrentDayFetch[coordKey],
           calendar.isDate(lastFetch, inSameDayAs: Date()) {
            // Return cached data if available
            if let locationCache = dateBasedCache[coordKey],
               let cachedWeather = locationCache[today] {
                completion(cachedWeather)
                return
            }
        }
        
        // Try to get location name from cache first (avoid geocoding if possible)
        let cacheKey = geocodingCacheKey(latitude, longitude)
        
        // Check if we have a cached location name
        let locationName: String
        if let cached = geocodingCache[cacheKey],
           calendar.isDate(cached.date, inSameDayAs: today) {
            locationName = cached.name
            // Use cached name immediately
            self.fetchOpenMeteoCurrentWeather(latitude: latitude, longitude: longitude, location: locationName) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by coordinate key
                if self.dateBasedCache[coordKey] == nil {
                    self.dateBasedCache[coordKey] = [:]
                }
                self.dateBasedCache[coordKey]?[today] = weatherInfo
                self.lastCurrentDayFetch[coordKey] = Date()
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
        } else {
            // No cached name - use coordinates as location name to avoid geocoding
            locationName = String(format: "%.4f, %.4f", latitude, longitude)
            self.fetchOpenMeteoCurrentWeather(latitude: latitude, longitude: longitude, location: locationName) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by coordinate key
                if self.dateBasedCache[coordKey] == nil {
                    self.dateBasedCache[coordKey] = [:]
                }
                self.dateBasedCache[coordKey]?[today] = weatherInfo
                self.lastCurrentDayFetch[coordKey] = Date()
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
            
            // Optionally try to get a better location name in the background (non-blocking)
            // This will cache it for future use but won't block the current request
            reverseGeocodeLocation(latitude: latitude, longitude: longitude) { _ in
                // Name is now cached for future requests
            }
        }
    }
    
    /// Fetches forecast using coordinates directly (avoids geocoding)
    private func fetchForecastForCoordinates(latitude: Double, longitude: Double, completion: @escaping (WeatherForecast?) -> Void) {
        let coordKey = String(format: "%.4f,%.4f", latitude, longitude)
        
        // Check if we have recent forecast cache
        if let cached = forecastCache[coordKey],
           Date().timeIntervalSince(cached.timestamp) < forecastCacheDuration {
            // Update date-based cache from forecast
            updateDateCacheFromForecast(cached.forecast, for: coordKey)
            completion(cached.forecast)
            return
        }
        
        // Try to get location name from cache first (avoid geocoding if possible)
        let cacheKey = geocodingCacheKey(latitude, longitude)
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        
        // Check if we have a cached location name
        let locationName: String
        if let cached = geocodingCache[cacheKey],
           calendar.isDate(cached.date, inSameDayAs: today) {
            locationName = cached.name
            // Use cached name immediately
            self.fetchOpenMeteoForecast(latitude: latitude, longitude: longitude, location: locationName) { [weak self] forecast in
                guard let self = self, let forecast = forecast else {
                    completion(nil)
                    return
                }
                
                // Cache forecast by coordinate key
                self.forecastCache[coordKey] = (forecast, Date())
                
                // Update date-based cache from forecast
                self.updateDateCacheFromForecast(forecast, for: coordKey)
                
                // Replace today's forecast with actual current weather if available
                self.replaceTodayWithCurrentWeatherForCoordinates(latitude: latitude, longitude: longitude)
                
                DispatchQueue.main.async {
                    completion(forecast)
                }
            }
        } else {
            // No cached name - use coordinates as location name to avoid geocoding
            locationName = String(format: "%.4f, %.4f", latitude, longitude)
            self.fetchOpenMeteoForecast(latitude: latitude, longitude: longitude, location: locationName) { [weak self] forecast in
                guard let self = self, let forecast = forecast else {
                    completion(nil)
                    return
                }
                
                // Cache forecast by coordinate key
                self.forecastCache[coordKey] = (forecast, Date())
                
                // Update date-based cache from forecast
                self.updateDateCacheFromForecast(forecast, for: coordKey)
                
                // Replace today's forecast with actual current weather if available
                self.replaceTodayWithCurrentWeatherForCoordinates(latitude: latitude, longitude: longitude)
                
                DispatchQueue.main.async {
                    completion(forecast)
                }
            }
            
            // Optionally try to get a better location name in the background (non-blocking)
            // This will cache it for future use but won't block the current request
            reverseGeocodeLocation(latitude: latitude, longitude: longitude) { _ in
                // Name is now cached for future requests
            }
        }
    }
    
    /// Fetches historical weather using coordinates directly (avoids geocoding)
    private func fetchHistoricalWeatherForCoordinates(latitude: Double, longitude: Double, date: Date, completion: @escaping (WeatherInfo?) -> Void) {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let coordKey = String(format: "%.4f,%.4f", latitude, longitude)
        
        // Create unique key for this date+location combination
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: date)
        let fetchKey = "\(dateKey)|\(coordKey)"
        
        // Check if we've exceeded daily limit
        if let lastFetchDate = lastHistoricalFetchDate,
           calendar.isDate(lastFetchDate, inSameDayAs: Date()) {
            // Check if we've already fetched this combination today
            if historicalFetchesToday.contains(fetchKey) {
                // Check cache
                if let locationCache = dateBasedCache[coordKey],
                   let cachedWeather = locationCache[date] {
                    completion(cachedWeather)
                    return
                }
                completion(nil)
                return
            }
            
            // Check if we've exceeded the limit of unique combinations
            if historicalFetchesToday.count >= maxHistoricalFetchesPerDay {
                // Check cache only
                if let locationCache = dateBasedCache[coordKey],
                   let cachedWeather = locationCache[date] {
                    completion(cachedWeather)
                    return
                }
                // Limit reached, return nil
                completion(nil)
                return
            }
        } else {
            // New day, reset counter
            historicalFetchesToday.removeAll()
            lastHistoricalFetchDate = today
        }
        
        // Try to get location name from cache first (avoid geocoding if possible)
        let cacheKey = geocodingCacheKey(latitude, longitude)
        
        // Check if we have a cached location name
        let locationName: String
        if let cached = geocodingCache[cacheKey],
           calendar.isDate(cached.date, inSameDayAs: today) {
            locationName = cached.name
            // Use cached name immediately
            self.fetchOpenMeteoHistoricalWeather(latitude: latitude, longitude: longitude, location: locationName, date: date) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by coordinate key
                if self.dateBasedCache[coordKey] == nil {
                    self.dateBasedCache[coordKey] = [:]
                }
                self.dateBasedCache[coordKey]?[date] = weatherInfo
                
                // Track this fetch
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateKey = dateFormatter.string(from: date)
                let fetchKey = "\(dateKey)|\(coordKey)"
                self.historicalFetchesToday.insert(fetchKey)
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
        } else {
            // No cached name - use coordinates as location name to avoid geocoding
            locationName = String(format: "%.4f, %.4f", latitude, longitude)
            self.fetchOpenMeteoHistoricalWeather(latitude: latitude, longitude: longitude, location: locationName, date: date) { [weak self] weatherInfo in
                guard let self = self, let weatherInfo = weatherInfo else {
                    completion(nil)
                    return
                }
                
                // Cache by coordinate key
                if self.dateBasedCache[coordKey] == nil {
                    self.dateBasedCache[coordKey] = [:]
                }
                self.dateBasedCache[coordKey]?[date] = weatherInfo
                
                // Track this fetch
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateKey = dateFormatter.string(from: date)
                let fetchKey = "\(dateKey)|\(coordKey)"
                self.historicalFetchesToday.insert(fetchKey)
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
            }
            
            // Optionally try to get a better location name in the background (non-blocking)
            // This will cache it for future use but won't block the current request
            reverseGeocodeLocation(latitude: latitude, longitude: longitude) { _ in
                // Name is now cached for future requests
            }
        }
    }
    
    /// Replaces today's forecast with actual current weather if available (coordinate-based)
    private func replaceTodayWithCurrentWeatherForCoordinates(latitude: Double, longitude: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let coordKey = String(format: "%.4f,%.4f", latitude, longitude)
        
        // Check if we have current day weather
        if let locationCache = dateBasedCache[coordKey],
           locationCache[today] != nil {
            // Already have current weather, forecast will be replaced
            return
        }
        
        // Fetch current weather to replace forecast
        fetchCurrentDayWeatherForCoordinates(latitude: latitude, longitude: longitude, date: today) { _ in
            // Current weather is now cached and will override forecast
        }
    }
    
    // MARK: - Open-Meteo Forecast Methods
    
    /// Fetches current weather and 10-day forecast for a location
    func getWeatherForecast(for location: String, completion: @escaping (WeatherForecast?) -> Void) {
        // Check cache first
        if let cached = forecastCache[location],
           Date().timeIntervalSince(cached.timestamp) < forecastCacheDuration {
            completion(cached.forecast)
            return
        }
        
        // Geocode location to coordinates
        geocodeAddressString(location) { [weak self] coordinate in
            guard let self = self,
                  let coordinate = coordinate else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.fetchOpenMeteoForecast(latitude: coordinate.latitude, longitude: coordinate.longitude, location: location, completion: completion)
        }
    }
    
    /// Fetches current weather and 10-day forecast using coordinates directly (avoids geocoding)
    func getWeatherForecastForCoordinates(latitude: Double, longitude: Double, completion: @escaping (WeatherForecast?) -> Void) {
        fetchForecastForCoordinates(latitude: latitude, longitude: longitude, completion: completion)
    }
    
    private func fetchOpenMeteoCurrentWeather(latitude: Double, longitude: Double, location: String, completion: @escaping (WeatherInfo?) -> Void) {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,windspeed_10m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "windspeed_unit", value: "mph")
        ]
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Open-Meteo API error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let response = try decodeOpenMeteoResponse(from: data)
                
                guard let current = response.current,
                      let weathercode = current.weathercode else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let currentDate = dateFormatter.date(from: current.time) ?? Date()
                
                let weatherInfo = WeatherInfo(
                    temperature: current.temperature2m,
                    condition: self.conditionFromWeatherCode(weathercode),
                    icon: self.iconFromWeatherCode(weathercode),
                    humidity: current.relativeHumidity2m,
                    windSpeed: current.windspeed10m,
                    location: location,
                    date: currentDate
                )
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
                
            } catch {
                print("Error decoding Open-Meteo response: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func fetchOpenMeteoForecast(latitude: Double, longitude: Double, location: String, completion: @escaping (WeatherForecast?) -> Void) {
        // Build URL for Open-Meteo API
        // Request current weather + daily forecast for up to 16 days (maximum)
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,windspeed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,windspeed_10m_max,relative_humidity_2m_max"),
            URLQueryItem(name: "forecast_days", value: "16"), // Maximum forecast days
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "windspeed_unit", value: "mph")
        ]
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Open-Meteo API error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let response = try decodeOpenMeteoResponse(from: data)
                
                // Parse current weather
                guard let current = response.current,
                      let _ = response.currentWeather,
                      let weathercode = current.weathercode else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let currentDate = dateFormatter.date(from: current.time) ?? Date()
                let currentInfo = WeatherInfo(
                    temperature: current.temperature2m,
                    condition: self.conditionFromWeatherCode(weathercode),
                    icon: self.iconFromWeatherCode(weathercode),
                    humidity: current.relativeHumidity2m,
                    windSpeed: current.windspeed10m,
                    location: location,
                    date: currentDate
                )
                
                // Parse daily forecast
                var dailyForecasts: [DailyWeatherForecast] = []
                if let daily = response.daily {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    for (index, timeString) in daily.time.enumerated() {
                        guard index < daily.temperature2mMax.count,
                              index < daily.temperature2mMin.count else {
                            continue
                        }
                        
                        guard let forecastDate = dateFormatter.date(from: timeString) else {
                            continue
                        }
                        
                        // Skip today if it's already in the past (use current weather for today)
                        let forecastDay = calendar.startOfDay(for: forecastDate)
                        if forecastDay < today {
                            continue
                        }
                        
                        // Skip if weathercode is missing - don't show weather without condition data
                        guard let weathercode = daily.weathercode,
                              index < weathercode.count else {
                            continue
                        }
                        
                        // No limit - fetch all available forecast days (up to 16)
                        
                        let maxTemp = daily.temperature2mMax[index]
                        let minTemp = daily.temperature2mMin[index]
                        let weatherCode = weathercode[index]
                        let windSpeed = daily.windspeed10mMax?[index]
                        let humidity = daily.relativeHumidity2mMax?[index]
                        
                        let dailyForecast = DailyWeatherForecast(
                            date: forecastDate,
                            maxTemperature: maxTemp,
                            minTemperature: minTemp,
                            condition: self.conditionFromWeatherCode(weatherCode),
                            icon: self.iconFromWeatherCode(weatherCode),
                            humidity: humidity,
                            windSpeed: windSpeed
                        )
                        
                        dailyForecasts.append(dailyForecast)
                    }
                }
                
                let forecast = WeatherForecast(
                    current: currentInfo,
                    daily: dailyForecasts,
                    location: location,
                    fetchedAt: Date()
                )
                
                // Cache the result
                DispatchQueue.main.async {
                    self.forecastCache[location] = (forecast, Date())
                    completion(forecast)
                }
                
            } catch {
                print("Error decoding Open-Meteo response: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func fetchOpenMeteoHistoricalWeather(latitude: Double, longitude: Double, location: String, date: Date, completion: @escaping (WeatherInfo?) -> Void) {
        // Format date for API (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Use historical weather API endpoint
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "start_date", value: dateString),
            URLQueryItem(name: "end_date", value: dateString),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,windspeed_10m_max,relative_humidity_2m_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "windspeed_unit", value: "mph")
        ]
        
        // For historical data, we can also use the archive endpoint if available
        // But the forecast endpoint with past dates should work for recent history
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Open-Meteo Historical API error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let response = try decodeOpenMeteoResponse(from: data)
                
                guard let daily = response.daily,
                      !daily.time.isEmpty,
                      !daily.temperature2mMax.isEmpty,
                      !daily.temperature2mMin.isEmpty else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // Skip if weathercode is missing - don't show weather without condition data
                guard let weathercode = daily.weathercode,
                      !weathercode.isEmpty else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // Get first day's data (should only be one day)
                let maxTemp = daily.temperature2mMax[0]
                let _ = daily.temperature2mMin[0]
                let weatherCode = weathercode[0]
                let windSpeed = daily.windspeed10mMax?[0]
                let humidity = daily.relativeHumidity2mMax?[0]
                
                // Parse date
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let historicalDate = isoFormatter.date(from: daily.time[0]) ?? date
                
                // Use max temp as representative temperature
                let weatherInfo = WeatherInfo(
                    temperature: maxTemp,
                    condition: self.conditionFromWeatherCode(weatherCode),
                    icon: self.iconFromWeatherCode(weatherCode),
                    humidity: humidity ?? 0,
                    windSpeed: windSpeed ?? 0,
                    location: location,
                    date: historicalDate
                )
                
                DispatchQueue.main.async {
                    completion(weatherInfo)
                }
                
            } catch {
                print("Error decoding Open-Meteo historical response: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Weather Code Conversion
    
    private func conditionFromWeatherCode(_ code: Int) -> String {
        // Open-Meteo uses WMO weather codes
        switch code {
        case 0:
            return "Clear"
        case 1, 2, 3:
            return "Partly Cloudy"
        case 45, 48:
            return "Foggy"
        case 51, 53, 55:
            return "Drizzle"
        case 56, 57:
            return "Freezing Drizzle"
        case 61, 63, 65:
            return "Rainy"
        case 66, 67:
            return "Freezing Rain"
        case 71, 73, 75:
            return "Snowy"
        case 77:
            return "Snow Grains"
        case 80, 81, 82:
            return "Rain Showers"
        case 85, 86:
            return "Snow Showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm with Hail"
        default:
            return "Clear"
        }
    }
    
    // MARK: - Geocoding Cache Helper
    
    /// Reverse geocode coordinates to location name with daily caching (only once per day per location)
    /// Deduplicates simultaneous requests for the same location
    /// Uses MapKit APIs (MKReverseGeocodingRequest) on tvOS 26.0+ or CLGeocoder for older versions
    /// Returns coordinate string immediately if rate limited to avoid throttling errors
    func reverseGeocodeLocation(latitude: Double, longitude: Double, completion: @escaping (String) -> Void) {
        let cacheKey = geocodingCacheKey(latitude, longitude)
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        
        // Reset cache if it's a new day
        if let lastCacheDate = lastGeocodingCacheDate,
           !calendar.isDate(lastCacheDate, inSameDayAs: today) {
            geocodingCache.removeAll()
            pendingGeocodingRequests.removeAll()
            lastGeocodingRequestTime = nil // Reset rate limiter on new day
        }
        lastGeocodingCacheDate = today
        
        // Check cache first - only use if it's from today
        if let cached = geocodingCache[cacheKey],
           calendar.isDate(cached.date, inSameDayAs: today) {
            completion(cached.name)
            return
        }
        
        // Check if there's already a pending request for this location
        if var pendingCompletions = pendingGeocodingRequests[cacheKey] {
            // Add this completion to the pending list - it will be called when the request completes
            pendingCompletions.append(completion)
            pendingGeocodingRequests[cacheKey] = pendingCompletions
            return
        }
        
        // Check if there's an active request for this exact location
        if activeGeocodingRequests.contains(cacheKey) {
            // There's already an active request, add to pending
            pendingGeocodingRequests[cacheKey] = [completion]
            return
        }
        
        // Rate limiting: check if we've made a request too recently
        let now = Date()
        if let lastRequestTime = lastGeocodingRequestTime,
           now.timeIntervalSince(lastRequestTime) < geocodingMinInterval {
            // Too soon since last request - use cached value if available, otherwise return coordinates
            // This prevents hitting the rate limit
            if let cached = geocodingCache[cacheKey] {
                completion(cached.name)
            } else {
                // Return coordinate string as fallback to avoid throttling
                // This is better than making another request that will be throttled
                completion(String(format: "%.4f, %.4f", latitude, longitude))
            }
            return
        }
        
        // Mark this location as having a pending request and active request
        pendingGeocodingRequests[cacheKey] = [completion]
        activeGeocodingRequests.insert(cacheKey)
        lastGeocodingRequestTime = now
        
        // Perform reverse geocoding using MapKit APIs
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        reverseGeocodeCoordinate(coordinate) { [weak self] locationName in
            guard let self = self else { return }
            
            // Cache the result with today's date
            self.geocodingCache[cacheKey] = (name: locationName, date: today)
            
            // Call all pending completion handlers for this location
            if let pendingCompletions = self.pendingGeocodingRequests[cacheKey] {
                for completionHandler in pendingCompletions {
                    completionHandler(locationName)
                }
                // Clear the pending requests and active request
                self.pendingGeocodingRequests.removeValue(forKey: cacheKey)
                self.activeGeocodingRequests.remove(cacheKey)
            }
        }
    }
    
    private func iconFromWeatherCode(_ code: Int) -> String {
        switch code {
        case 0:
            return "sun.max"
        case 1, 2, 3:
            return "cloud.sun"
        case 45, 48:
            return "cloud.fog"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow"
        case 95, 96, 99:
            return "cloud.bolt.rain"
        default:
            return "sun.max"
        }
    }

    func clearCache() {
        weatherCache.removeAll()
        forecastCache.removeAll()
        dateBasedCache.removeAll()
        lastCurrentDayFetch.removeAll()
        historicalFetchesToday.removeAll()
        lastHistoricalFetchDate = nil
        geocodingCache.removeAll()
        pendingGeocodingRequests.removeAll()
        activeGeocodingRequests.removeAll()
        lastGeocodingRequestTime = nil
    }
}
