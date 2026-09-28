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
    var isUserSelected: Bool? = nil

    var isDisposableCache: Bool { unsplashId != nil && isUserSelected == false }

    var isExpired: Bool {
        let expirationDate = cachedAt.addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        return Date() > expirationDate
    }
}

class ImageRepository {
    static let shared = ImageRepository()

    private let lock = NSRecursiveLock()
    private let cacheDirectory: URL
    private let metadataFile: URL
    private var metadataReadable = true
    private var imageMetadata: [String: ImageMetadata] = [:]
    private let memoryCache = NSCache<NSString, PlatformImage>()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB limit for memory cache

    init(directory: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = directory ?? support.appendingPathComponent("CalendarImages", isDirectory: true)
        metadataFile = cacheDirectory.appendingPathComponent("metadata.json")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        if directory == nil {
            // Retain the old cache as a recovery source; selected/imported images now live durably.
            let legacy = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("CalendarImages")
            if let files = try? FileManager.default.contentsOfDirectory(at: legacy, includingPropertiesForKeys: nil) {
                for source in files {
                    let target = cacheDirectory.appendingPathComponent(source.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: target.path) { try? FileManager.default.copyItem(at: source, to: target) }
                }
            }
        }
        memoryCache.totalCostLimit = maxCacheSize
        memoryCache.countLimit = 100
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
        lock.lock(); defer { lock.unlock() }
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
        lock.lock(); defer { lock.unlock() }
        return imageMetadata[id]
    }

    @discardableResult
    func saveImage(_ image: PlatformImage, metadata: ImageMetadata) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard metadataReadable else { return false }
        let imagePath = cacheDirectory.appendingPathComponent("\(metadata.id).jpg")
        let imageData: Data?
        #if os(macOS)
        imageData = image.tiffRepresentation.flatMap { NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) }
        #else
        imageData = image.jpegData(compressionQuality: 0.8)
        #endif
        guard let imageData else { return false }
        var updated = imageMetadata
        updated[metadata.id] = metadata
        let previousBytes = try? Data(contentsOf: imagePath)
        do {
            let index = try JSONEncoder().encode(updated)
            try imageData.write(to: imagePath, options: .atomic)
            do { try index.write(to: metadataFile, options: .atomic) }
            catch {
                if let previousBytes { try? previousBytes.write(to: imagePath, options: .atomic) }
                else { try? FileManager.default.removeItem(at: imagePath) }
                throw error
            }
            imageMetadata = updated
            memoryCache.setObject(image, forKey: metadata.id as NSString)
            return true
        } catch { return false }
    }

    func findSimilarImages(for title: String, location: String? = nil) -> [ImageMetadata] {
        lock.lock(); defer { lock.unlock() }
        var candidates = imageMetadata.values.filter { !$0.isExpired || !$0.isDisposableCache }

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
        lock.lock(); defer { lock.unlock() }
        let validImages = imageMetadata.values.filter { !$0.isExpired || !$0.isDisposableCache }
        return validImages.randomElement()
    }

    func clearExpiredImages() {
        lock.lock(); defer { lock.unlock() }
        let expiredIds = imageMetadata.values.filter { $0.isDisposableCache && $0.isExpired }.map { $0.id }

        for id in expiredIds {
            imageMetadata.removeValue(forKey: id)
            let imagePath = cacheDirectory.appendingPathComponent("\(id).jpg")
            try? FileManager.default.removeItem(at: imagePath)
            memoryCache.removeObject(forKey: id as NSString)
        }

        saveMetadata()
    }

    func limitCacheSize(maxImages: Int = 200) {
        lock.lock(); defer { lock.unlock() }
        let disposable = imageMetadata.values.filter { $0.isDisposableCache }.sorted { $0.cachedAt < $1.cachedAt }
        var totalBytes = disposable.reduce(0) { total, item in
            total + ((try? cacheDirectory.appendingPathComponent("\(item.id).jpg").resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        var count = disposable.count
        for item in disposable where count > maxImages || totalBytes > 200 * 1024 * 1024 {
            let path = cacheDirectory.appendingPathComponent("\(item.id).jpg")
            let size = (try? path.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            do { try FileManager.default.removeItem(at: path) }
            catch { continue }
            imageMetadata.removeValue(forKey: item.id)
            memoryCache.removeObject(forKey: item.id as NSString)
            count -= 1
            totalBytes -= size
        }
        saveMetadata()
    }

    // MARK: - Private Methods

    private func loadMetadata() {
        guard FileManager.default.fileExists(atPath: metadataFile.path) else { return }
        guard let data = try? Data(contentsOf: metadataFile),
              let decoded = try? JSONDecoder().decode([String: ImageMetadata].self, from: data) else {
            metadataReadable = false
            return
        }
        imageMetadata = decoded
    }

    private func saveMetadata() {
        guard metadataReadable else { return }
        guard let data = try? JSONEncoder().encode(imageMetadata) else { return }
        try? data.write(to: metadataFile, options: .atomic)
    }

    private func cleanupExpiredImages() {
        clearExpiredImages()
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
