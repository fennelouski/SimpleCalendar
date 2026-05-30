//
//  HolidayImageManager.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/30/25.
//

import Foundation
import SwiftUI

/// Manages images specifically for holidays, ensuring one image per holiday name
/// regardless of year or location, and only fetching when needed for display
class HolidayImageManager {
    static let shared = HolidayImageManager()

    let imageManager = ImageManager.shared
    private let imageRepository = ImageRepository.shared

    // Cache mapping holiday names to image IDs
    private var holidayImageCache: [String: String] = [:] // holidayName -> imageId
    private var pendingRequests: Set<String> = [] // holiday names currently being fetched

    private init() {
        loadHolidayImageCache()
    }

    /// Get or fetch image for a holiday. Uses holiday name as the key for consistency.
    func getImageForHoliday(_ holiday: CalendarHoliday, completion: @escaping (String?) -> Void) {
        let cacheKey = holiday.name

        // Check if we already have an image for this holiday name
        if let cachedImageId = holidayImageCache[cacheKey],
           imageRepository.getImage(for: cachedImageId) != nil {
            completion(cachedImageId)
            return
        }

        // Check if we already have a pending request for this holiday
        if pendingRequests.contains(cacheKey) {
            // Wait a moment and try again (simple polling for now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.getImageForHoliday(holiday, completion: completion)
            }
            return
        }

        // Create a temporary CalendarEvent-like object for image fetching
        let tempEvent = createEventFromHoliday(holiday)

        // Mark as pending and fetch
        pendingRequests.insert(cacheKey)

        imageManager.findOrFetchImage(for: tempEvent) { [weak self] imageId in
            guard let self = self else { return }

            if let imageId = imageId {
                // Cache the association
                self.holidayImageCache[cacheKey] = imageId
                self.saveHolidayImageCache()
            }

            // Remove from pending
            self.pendingRequests.remove(cacheKey)

            completion(imageId)
        }
    }

    /// Get cached image ID for a holiday without fetching
    func getCachedImageIdForHoliday(_ holiday: CalendarHoliday) -> String? {
        let cacheKey = holiday.name
        let imageId = holidayImageCache[cacheKey]

        // Verify the image still exists
        if let imageId = imageId, imageRepository.getImage(for: imageId) != nil {
            return imageId
        } else if imageId != nil {
            // Image is missing, remove from cache
            holidayImageCache.removeValue(forKey: cacheKey)
            saveHolidayImageCache()
        }

        return nil
    }

    /// Pre-fetch images only for holidays that are currently visible on the calendar
    func prefetchImagesForVisibleHolidays(_ holidays: [CalendarHoliday]) {
        let uniqueHolidayNames = Set(holidays.map { $0.name })

        for holidayName in uniqueHolidayNames {
            // Only fetch if we don't already have an image
            if holidayImageCache[holidayName] == nil && !pendingRequests.contains(holidayName) {
                // Find a representative holiday object for this name
                if let holiday = holidays.first(where: { $0.name == holidayName }) {
                    getImageForHoliday(holiday) { _ in
                        // We don't need to do anything with the result here
                        // The image will be cached for future use
                    }
                }
            }
        }
    }

    /// Clear all holiday image associations (useful for debugging or reset)
    func clearHolidayImageCache() {
        holidayImageCache.removeAll()
        saveHolidayImageCache()
    }

    // MARK: - Private Methods

    private func createEventFromHoliday(_ holiday: CalendarHoliday) -> CalendarEvent {
        // Create a minimal CalendarEvent for image fetching purposes
        // Use holiday name as title and unsplashSearchTerm as the basis for image search
        return CalendarEvent(
            id: "holiday_\(holiday.name.hashValue)",
            title: holiday.unsplashSearchTerm.isEmpty ? holiday.name : holiday.unsplashSearchTerm,
            startDate: holiday.date,
            endDate: holiday.date,
            location: nil, // Holidays don't have specific locations
            notes: holiday.description,
            calendarIdentifier: "holidays",
            isAllDay: true
        )
    }

    private func loadHolidayImageCache() {
        if let data = UserDefaults.standard.data(forKey: "holidayImageCache"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            holidayImageCache = decoded
        }
    }

    private func saveHolidayImageCache() {
        if let data = try? JSONEncoder().encode(holidayImageCache) {
            UserDefaults.standard.set(data, forKey: "holidayImageCache")
        }
    }
}
