//
//  ImageManager.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI
import CoreLocation

class ImageManager {
    static let shared = ImageManager()

    private let imageRepository = ImageRepository.shared
    private let unsplashAPI = UnsplashAPI.shared
    private let requestQueueManager = RequestQueueManager.shared

    private init() {}

    func getImageForEvent(_ event: CalendarEvent, completion: @escaping (String?) -> Void) {
        // Check if event already has an image URL (legacy support)
        if let imageUrl = event.imageUrl {
            completion(imageUrl)
            return
        }

        // Check if event has a repository image ID and the image exists
        if let repositoryId = event.imageRepositoryId {
            if imageRepository.getImage(for: repositoryId) != nil {
                completion(repositoryId)
                return
            } else {
                // Image ID exists but image is missing - clear it and find a new one
                event.imageRepositoryId = nil
            }
        }

        // Check if we have a cached image for this exact event (same title and location)
        let title = event.title
        let location = event.location
        let similarImages = imageRepository.findSimilarImages(for: title, location: location)

        let exactMatches = similarImages.filter { metadata in
            metadata.titleQuery?.lowercased() == title.lowercased() &&
            metadata.locationQuery == location &&
            !metadata.isExpired
        }

        if let exactMatch = exactMatches.first {
            // Found exact cached match
            saveImageToEvent(event, imageId: exactMatch.id)
            completion(exactMatch.id)
            return
        }

        // Try to find a suitable cached image
        findOrFetchImage(for: event, completion: completion)
    }

    func findOrFetchImage(for event: CalendarEvent, completion: @escaping (String?) -> Void) {
        let title = event.title
        let location = event.location

        // First, check repository for similar images
        let similarImages = imageRepository.findSimilarImages(for: title, location: location)

        // Look for a very good match (high similarity score)
        if let bestMatch = similarImages.first, similarityScore(for: bestMatch, title: title, location: location) >= 1.5 {
            // Use existing image from repository - very good match
            saveImageToEvent(event, imageId: bestMatch.id)
            completion(bestMatch.id)
            return
        }

        // Check if we have any cached images for this exact event (same title and location)
        let exactMatches = similarImages.filter { metadata in
            metadata.titleQuery?.lowercased() == title.lowercased() &&
            metadata.locationQuery == location
        }

        if let exactMatch = exactMatches.first {
            // Perfect match - use this image
            saveImageToEvent(event, imageId: exactMatch.id)
            completion(exactMatch.id)
            return
        }

        // Check for good enough matches (any similarity score > 0.5)
        if let goodMatch = similarImages.first(where: { similarityScore(for: $0, title: title, location: location) > 0.5 }) {
            // Use existing image - good enough match
            saveImageToEvent(event, imageId: goodMatch.id)
            completion(goodMatch.id)
            return
        }

        // No suitable cached image found, queue a request for a new image
        fetchNewImage(for: event, completion: completion)
    }

    func fetchNewImage(for event: CalendarEvent, completion: @escaping (String?) -> Void) {
        let requestId = "fetch_\(event.id)_\(UUID().uuidString)"

        requestQueueManager.enqueueRequest(id: requestId) {
            let query = self.buildSearchQuery(for: event)

            self.unsplashAPI.getRandomPhoto(query: query) { [weak self] photo in
                guard let self = self, let photo = photo else {
                    completion(nil)
                    return
                }

                // Download the image
                self.unsplashAPI.downloadImage(from: photo.urls.regular) { imageData in
                    guard let imageData = imageData, let image = PlatformImage(data: imageData) else {
                        completion(nil)
                        return
                    }

                    // Track download as per Unsplash guidelines
                    self.unsplashAPI.trackDownload(for: photo.id)

                    // Create metadata
                    let tags = photo.tags?.map { $0.title } ?? []
                    let metadata = ImageMetadata(
                        id: UUID().uuidString,
                        unsplashId: photo.id,
                        url: photo.urls.regular,
                        thumbnailUrl: photo.urls.thumb,
                        author: photo.user.name,
                        authorUrl: photo.user.links.html,
                        downloadUrl: photo.links.download_location,
                        cachedAt: Date(),
                        tags: tags,
                        locationQuery: event.location,
                        titleQuery: event.title
                    )

                    // Save to repository
                    self.imageRepository.saveImage(image, metadata: metadata)

                    // Associate with event
                    self.saveImageToEvent(event, imageId: metadata.id)

                    completion(metadata.id)
                }
            }
        }
    }

    func searchImages(query: String, completion: @escaping ([ImageMetadata]) -> Void) {
        let requestId = "search_\(query.hashValue)_\(UUID().uuidString)"

        requestQueueManager.enqueueRequest(id: requestId) {
            self.unsplashAPI.searchPhotos(query: query) { photos in
                guard let photos = photos else {
                    completion([])
                    return
                }

                var metadataList: [ImageMetadata] = []

                let group = DispatchGroup()

                for photo in photos {
                    group.enter()
                    self.unsplashAPI.downloadImage(from: photo.urls.thumb) { imageData in
                        defer { group.leave() }

                        guard let imageData = imageData, let _ = PlatformImage(data: imageData) else {
                            return
                        }

                        let tags = photo.tags?.map { $0.title } ?? []
                        let metadata = ImageMetadata(
                            id: UUID().uuidString,
                            unsplashId: photo.id,
                            url: photo.urls.regular,
                            thumbnailUrl: photo.urls.thumb,
                            author: photo.user.name,
                            authorUrl: photo.user.links.html,
                            downloadUrl: photo.links.download_location,
                            cachedAt: Date(),
                            tags: tags,
                            locationQuery: nil,
                            titleQuery: query
                        )

                        metadataList.append(metadata)
                    }
                }

                group.notify(queue: .main) {
                    completion(metadataList)
                }
            }
        }
    }

    func getImageMetadata(for imageId: String) -> ImageMetadata? {
        return imageRepository.getImageMetadata(for: imageId)
    }

    func getImage(for imageId: String) -> PlatformImage? {
        return imageRepository.getImage(for: imageId)
    }

    func getQueueStatus() -> String {
        return requestQueueManager.getDebugInfo()
    }

    func cancelImageRequest(for eventId: String) {
        _ = "fetch_\(eventId)_"
        // Note: In a more sophisticated implementation, we'd track request IDs
        // For now, this is a placeholder for future enhancement
    }

    func clearExpiredCache() {
        imageRepository.clearExpiredImages()
    }

    func getCacheStats() -> String {
        // This would require adding stats to ImageRepository
        // For now, return basic queue stats
        return getQueueStatus()
    }

    // MARK: - Private Methods

    private func similarityScore(for metadata: ImageMetadata, title: String, location: String?) -> Double {
        var score = 0.0

        // Title query match
        if let titleQuery = metadata.titleQuery?.lowercased() {
            let titleLower = title.lowercased()
            if titleQuery == titleLower {
                score += 3.0 // Exact match
            } else if titleQuery.contains(titleLower) || titleLower.contains(titleQuery) {
                score += 2.0 // Partial match
            } else {
                // Check individual words
                let titleWords = titleLower.components(separatedBy: .whitespacesAndNewlines)
                let queryWords = titleQuery.components(separatedBy: .whitespacesAndNewlines)
                let matchingWords = titleWords.filter { queryWords.contains($0) }
                score += Double(matchingWords.count) * 0.5
            }
        }

        // Tag matches
        for tag in metadata.tags {
            let tagLower = tag.lowercased()
            let titleWords = title.lowercased().components(separatedBy: .whitespacesAndNewlines)
            for word in titleWords {
                if tagLower.contains(word) || word.contains(tagLower) {
                    score += 0.3
                }
            }
        }

        // Location match bonus
        if let location = location,
           let locationQuery = metadata.locationQuery,
           location.lowercased().contains(locationQuery.lowercased()) ||
           locationQuery.lowercased().contains(location.lowercased()) {
            score += 1.0
        }

        return score
    }

    private func buildSearchQuery(for event: CalendarEvent) -> String {
        var queryParts: [String] = []

        // Add title keywords
        let titleWords = event.title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
            .prefix(3) // Limit to 3 keywords

        queryParts.append(contentsOf: titleWords)

        // Add location if available
        if let location = event.location, !location.isEmpty {
            // Extract city/state/country from location
            let locationParts = location.components(separatedBy: CharacterSet(charactersIn: ", "))
                .filter { !$0.isEmpty }
                .prefix(2)
            queryParts.append(contentsOf: locationParts)
        }

        // Add event type keywords based on common patterns
        if event.title.lowercased().contains("meeting") || event.title.lowercased().contains("conference") {
            queryParts.append("business")
        } else if event.title.lowercased().contains("birthday") || event.title.lowercased().contains("party") {
            queryParts.append("celebration")
        } else if event.title.lowercased().contains("vacation") || event.title.lowercased().contains("travel") {
            queryParts.append("travel")
        } else if event.title.lowercased().contains("workout") || event.title.lowercased().contains("exercise") {
            queryParts.append("fitness")
        }

        return queryParts.joined(separator: " ").lowercased()
    }

    private func saveImageToEvent(_ event: CalendarEvent, imageId: String) {
        event.imageRepositoryId = imageId
        // Note: In a real app, you'd want to save this to persistent storage
        // For now, we're just setting the property
    }
}
