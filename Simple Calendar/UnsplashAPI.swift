//
//  UnsplashAPI.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI

nonisolated struct UnsplashPhoto: Codable {
    let id: String
    let urls: UnsplashUrls
    let user: UnsplashUser
    let links: UnsplashLinks
    let tags: [UnsplashTag]?

    nonisolated struct UnsplashUrls: Codable {
        let raw: String
        let full: String
        let regular: String
        let small: String
        let thumb: String
    }

    nonisolated struct UnsplashUser: Codable {
        let name: String
        let links: UnsplashUserLinks

        nonisolated struct UnsplashUserLinks: Codable {
            let html: String
        }
    }

    nonisolated struct UnsplashLinks: Codable {
        let download_location: String
    }

    nonisolated struct UnsplashTag: Codable {
        let title: String
    }
}

nonisolated struct UnsplashSearchResponse: Codable {
    let results: [UnsplashPhoto]
    let total: Int
    let total_pages: Int
}

class UnsplashAPI {
    static let shared = UnsplashAPI()

    // Backend endpoint - configure this for your deployment
    private var backendBaseURL: String {
        #if DEBUG
        return "http://localhost:3001/api/unsplash"
        #else
        return "https://calendar-play-seven.vercel.app/api/unsplash"
        #endif
    }

    private init() {}

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 10, completion: @escaping ([UnsplashPhoto]?) -> Void) {
        guard var urlComponents = URLComponents(string: backendBaseURL) else {
            completion(nil)
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "search"),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for network errors
            if let error = error {
                print("❌ Network error fetching photos: \(error.localizedDescription)")
                print("   URL: \(url.absoluteString)")
                completion(nil)
                return
            }
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP error fetching photos: Status \(httpResponse.statusCode)")
                    print("   URL: \(url.absoluteString)")
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("   Response: \(errorMessage)")
                    }
                    completion(nil)
                    return
                }
            }
            
            // Check for data
            guard let data = data else {
                print("❌ No data received from backend")
                print("   URL: \(url.absoluteString)")
                completion(nil)
                return
            }

            do {
                let photos = try JSONDecoder().decode([UnsplashPhoto].self, from: data)
                completion(photos)
            } catch {
                print("❌ Error decoding backend response: \(error)")
                print("   URL: \(url.absoluteString)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response data: \(responseString.prefix(200))")
                }
                completion(nil)
            }
        }.resume()
    }

    func getRandomPhoto(query: String? = nil, completion: @escaping (UnsplashPhoto?) -> Void) {
        guard var urlComponents = URLComponents(string: backendBaseURL) else {
            completion(nil)
            return
        }

        var queryItems = [URLQueryItem(name: "action", value: "random")]
        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for network errors
            if let error = error {
                print("❌ Network error fetching random photo: \(error.localizedDescription)")
                print("   URL: \(url.absoluteString)")
                completion(nil)
                return
            }
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP error fetching random photo: Status \(httpResponse.statusCode)")
                    print("   URL: \(url.absoluteString)")
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("   Response: \(errorMessage)")
                    }
                    completion(nil)
                    return
                }
            }
            
            // Check for data
            guard let data = data else {
                print("❌ No data received from backend")
                print("   URL: \(url.absoluteString)")
                completion(nil)
                return
            }

            do {
                let photos = try JSONDecoder().decode([UnsplashPhoto].self, from: data)
                completion(photos.first)
            } catch {
                print("❌ Error decoding random photo from backend: \(error)")
                print("   URL: \(url.absoluteString)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response data: \(responseString.prefix(200))")
                }
                completion(nil)
            }
        }.resume()
    }

    func downloadImage(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for network errors
            if let error = error {
                print("❌ Network error downloading image: \(error.localizedDescription)")
                print("   URL: \(urlString)")
                completion(nil)
                return
            }
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ HTTP error downloading image: Status \(httpResponse.statusCode)")
                    print("   URL: \(urlString)")
                    completion(nil)
                    return
                }
            }
            
            // Return data if available
            guard let data = data else {
                print("❌ No image data received")
                print("   URL: \(urlString)")
                completion(nil)
                return
            }
            
            completion(data)
        }.resume()
    }

    func trackDownload(for photoId: String) {
        // Track the download through our backend
        guard let url = URL(string: backendBaseURL) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["action": "track_download", "photoId": photoId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error creating track download request: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("⚠️ Failed to track download: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("⚠️ Failed to track download: HTTP \(httpResponse.statusCode)")
                    return
                }
            }
        }.resume()
    }
}
