//
//  ImageRepository.swift
//  Simple Calendar
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

    private init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("CalendarImages")
        metadataFile = cacheDirectory.appendingPathComponent("metadata.json")

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        loadMetadata()
        cleanupExpiredImages()
    }

    // MARK: - Public Methods

    func getImage(for id: String) -> PlatformImage? {
        guard let metadata = imageMetadata[id] else { return nil }

        let imagePath = cacheDirectory.appendingPathComponent("\(id).jpg")
        return PlatformImage(contentsOfFile: imagePath.path)
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
        }

        saveMetadata()
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
