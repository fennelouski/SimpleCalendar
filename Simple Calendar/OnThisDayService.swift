//
//  OnThisDayService.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Service for fetching and caching "On This Day" data from Wikipedia
@MainActor
class OnThisDayService: ObservableObject {
    static let shared = OnThisDayService()

    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?

    private let cache = NSCache<NSString, OnThisDayCacheEntry>()
    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "onThisDay_"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private init() {
        loadPersistentCache()
    }

    /// Fetch On This Day data for a specific date
    func fetchData(for date: Date) async throws -> OnThisDayData {
        let cacheKey = cacheKey(for: date)

        // Check memory cache first
        if let cachedEntry = cache.object(forKey: cacheKey as NSString),
           !cachedEntry.isExpired {
            return cachedEntry.data
        }

        // Check persistent cache
        if let persistentData = loadFromPersistentCache(for: date) {
            // Store in memory cache
            let entry = OnThisDayCacheEntry(date: date, data: persistentData, timestamp: Date())
            cache.setObject(entry, forKey: cacheKey as NSString)
            return persistentData
        }

        // Fetch from API
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await fetchFromAPI(for: date)

            // Cache the result
            let entry = OnThisDayCacheEntry(date: date, data: data, timestamp: Date())
            cache.setObject(entry, forKey: cacheKey as NSString)
            saveToPersistentCache(data, for: date)

            return data
        } catch {
            lastError = error
            throw error
        }
    }

    /// Clear all cached data
    func clearCache() {
        cache.removeAllObjects()

        // Clear persistent cache
        let keysToRemove = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cacheKeyPrefix) }
        keysToRemove.forEach { userDefaults.removeObject(forKey: $0) }
    }

    // MARK: - Private Methods

    private func fetchFromAPI(for date: Date) async throws -> OnThisDayData {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            throw OnThisDayError.invalidDate
        }

        // Wikimedia API: https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/MM/DD
        let urlString = "https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/\(String(format: "%02d", month))/\(String(format: "%02d", day))"
        guard let url = URL(string: urlString) else {
            throw OnThisDayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("SimpleCalendar/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OnThisDayError.networkError
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(OnThisDayResponse.self, from: data)

        // Convert to our data model
        let events = apiResponse.events ?? []
        let births = apiResponse.births ?? []
        let deaths = apiResponse.deaths ?? []
        let holidays = apiResponse.holidays ?? []

        return OnThisDayData(
            events: events,
            births: births,
            deaths: deaths,
            holidays: holidays
        )
    }

    private func cacheKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        return "\(cacheKeyPrefix)\(components.month ?? 0)_\(components.day ?? 0)"
    }

    private func loadFromPersistentCache(for date: Date) -> OnThisDayData? {
        let key = cacheKey(for: date)

        guard let data = userDefaults.data(forKey: key),
              let cacheEntry = try? JSONDecoder().decode(OnThisDayCacheEntry.self, from: data),
              !cacheEntry.isExpired else {
            return nil
        }

        return cacheEntry.data
    }

    private func saveToPersistentCache(_ data: OnThisDayData, for date: Date) {
        let key = cacheKey(for: date)
        let cacheEntry = OnThisDayCacheEntry(date: date, data: data, timestamp: Date())

        if let encodedData = try? JSONEncoder().encode(cacheEntry) {
            userDefaults.set(encodedData, forKey: key)
        }
    }

    private func loadPersistentCache() {
        // Load recently accessed cache entries into memory
        let cacheKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cacheKeyPrefix) }

        for key in cacheKeys {
            if let data = userDefaults.data(forKey: key),
               let cacheEntry = try? JSONDecoder().decode(OnThisDayCacheEntry.self, from: data),
               !cacheEntry.isExpired {
                cache.setObject(cacheEntry, forKey: key as NSString)
            } else {
                // Remove expired entries
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Errors

enum OnThisDayError: LocalizedError {
    case invalidDate
    case invalidURL
    case networkError
    case parsingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Invalid date provided"
        case .invalidURL:
            return "Unable to create API URL"
        case .networkError:
            return "Network request failed"
        case .parsingError:
            return "Unable to parse API response"
        case .noData:
            return "No data available for this date"
        }
    }
}
