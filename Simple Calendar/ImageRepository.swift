//
//  ImageRepository.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI

struct ImageMetadata: Codable {
    let id: String
    let unsplashId: String?
    let url: String
    let thumbnailUrl: String
    let author: String
    let authorUrl: String?
    let downloadUrl: String
    let cachedAt: Date
    let tags: [String]
    let locationQuery: String?
    let titleQuery: String?

    var isExpired: Bool {
        let expirationDate = cachedAt.addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        return Date() > expirationDate
    }
}

class ImageRepository {
    static let shared = ImageRepository()

    private let cacheDirectory: URL
    private let metadataFile: URL
    private var imageMetadata: [String: ImageMetadata] = [:]
    private let memoryCache = NSCache<NSString, PlatformImage>()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB limit for memory cache

    private init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("CalendarImages")
        metadataFile = cacheDirectory.appendingPathComponent("metadata.json")

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Set memory cache limits
        memoryCache.totalCostLimit = maxCacheSize
        memoryCache.countLimit = 100 // Max 100 images in memory

        loadMetadata()
        cleanupExpiredImages()
        setupMemoryPressureHandler()
    }

    private func setupMemoryPressureHandler() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    @objc private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Public Methods

    func getImage(for id: String) -> PlatformImage? {
        guard imageMetadata[id] != nil else { return nil }

        // Check memory cache first
        let cacheKey = id as NSString
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Load from disk and cache in memory
        let imagePath = cacheDirectory.appendingPathComponent("\(id).jpg")
        guard let image = PlatformImage(contentsOfFile: imagePath.path) else { return nil }

        // Calculate approximate memory cost (rough estimate: width * height * 4 bytes per pixel)
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)

        return image
    }

    func getImageMetadata(for id: String) -> ImageMetadata? {
        return imageMetadata[id]
    }

    func saveImage(_ image: PlatformImage, metadata: ImageMetadata) {
        let imagePath = cacheDirectory.appendingPathComponent("\(metadata.id).jpg")

        // Save image
        #if os(macOS)
        if let tiffData = image.tiffRepresentation,
           let bitmapImageRep = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
            try? jpegData.write(to: imagePath)
        }
        #else
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: imagePath)
        }
        #endif

        // Save metadata
        imageMetadata[metadata.id] = metadata
        saveMetadata()

        // Periodically limit cache size
        DispatchQueue.global(qos: .background).async {
            self.limitCacheSize()
        }
    }

    func findSimilarImages(for title: String, location: String? = nil) -> [ImageMetadata] {
        var candidates = imageMetadata.values.filter { !$0.isExpired }

        // Prioritize images with similar titles
        if !title.isEmpty {
            let titleWords = title.lowercased().components(separatedBy: .whitespacesAndNewlines)
            candidates.sort { metadata1, metadata2 in
                let score1 = similarityScore(for: metadata1, with: titleWords, location: location)
                let score2 = similarityScore(for: metadata2, with: titleWords, location: location)
                return score1 > score2
            }
        }

        return Array(candidates.prefix(10))
    }

    func getRandomImage() -> ImageMetadata? {
        let validImages = imageMetadata.values.filter { !$0.isExpired }
        return validImages.randomElement()
    }

    func clearExpiredImages() {
        let expiredIds = imageMetadata.values.filter { $0.isExpired }.map { $0.id }

        for id in expiredIds {
            imageMetadata.removeValue(forKey: id)
            let imagePath = cacheDirectory.appendingPathComponent("\(id).jpg")
            try? FileManager.default.removeItem(at: imagePath)
            memoryCache.removeObject(forKey: id as NSString)
        }

        saveMetadata()
    }

    func limitCacheSize(maxImages: Int = 200) {
        // If we have too many images, remove oldest ones
        if imageMetadata.count > maxImages {
            let sortedByAge = imageMetadata.values.sorted { $0.cachedAt < $1.cachedAt }
            let imagesToRemove = sortedByAge.prefix(imageMetadata.count - maxImages)

            for metadata in imagesToRemove {
                imageMetadata.removeValue(forKey: metadata.id)
                let imagePath = cacheDirectory.appendingPathComponent("\(metadata.id).jpg")
                try? FileManager.default.removeItem(at: imagePath)
                memoryCache.removeObject(forKey: metadata.id as NSString)
            }

            saveMetadata()
        }

        // Also limit disk space (rough estimate: 1MB per image on average)
        let maxDiskSize = 200 * 1024 * 1024 // 200MB
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = contents.reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + size
            }

            if totalSize > maxDiskSize {
                // Remove oldest files until we're under the limit
                let sortedContents = contents.sorted {
                    let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 < date2
                }

                var currentSize = totalSize
                for url in sortedContents {
                    if currentSize <= maxDiskSize { break }
                    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    try? FileManager.default.removeItem(at: url)
                    currentSize -= size

                    // Also remove from metadata if it's tracked
                    let filename = url.deletingPathExtension().lastPathComponent
                    imageMetadata.removeValue(forKey: filename)
                    memoryCache.removeObject(forKey: filename as NSString)
                }
                saveMetadata()
            }
        } catch {
            print("Error managing cache size: \(error)")
        }
    }

    // MARK: - Private Methods

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataFile),
              let decoded = try? JSONDecoder().decode([String: ImageMetadata].self, from: data) else {
            return
        }
        imageMetadata = decoded
    }

    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(imageMetadata) else { return }
        try? data.write(to: metadataFile)
    }

    private func cleanupExpiredImages() {
        DispatchQueue.global(qos: .background).async {
            self.clearExpiredImages()
        }
    }

    private func similarityScore(for metadata: ImageMetadata, with words: [String], location: String?) -> Double {
        var score = 0.0

        // Title query match
        if let titleQuery = metadata.titleQuery?.lowercased() {
            for word in words {
                if titleQuery.contains(word) {
                    score += 1.0
                }
            }
        }

        // Tag matches
        for tag in metadata.tags {
            let tagLower = tag.lowercased()
            for word in words {
                if tagLower.contains(word) || word.contains(tagLower) {
                    score += 0.5
                }
            }
        }

        // Location match bonus
        if let location = location,
           let locationQuery = metadata.locationQuery,
           location.lowercased().contains(locationQuery.lowercased()) ||
           locationQuery.lowercased().contains(location.lowercased()) {
            score += 2.0
        }

        return score
    }
}
