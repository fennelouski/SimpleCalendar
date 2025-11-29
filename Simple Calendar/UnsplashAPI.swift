//
//  UnsplashAPI.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI

struct UnsplashPhoto: Codable {
    let id: String
    let urls: UnsplashUrls
    let user: UnsplashUser
    let links: UnsplashLinks
    let tags: [UnsplashTag]?

    struct UnsplashUrls: Codable {
        let raw: String
        let full: String
        let regular: String
        let small: String
        let thumb: String
    }

    struct UnsplashUser: Codable {
        let name: String
        let links: UnsplashUserLinks

        struct UnsplashUserLinks: Codable {
            let html: String
        }
    }

    struct UnsplashLinks: Codable {
        let download_location: String
    }

    struct UnsplashTag: Codable {
        let title: String
    }
}

struct UnsplashSearchResponse: Codable {
    let results: [UnsplashPhoto]
    let total: Int
    let total_pages: Int
}

class UnsplashAPI {
    static let shared = UnsplashAPI()

    private let accessKey = "YOUR_UNSPLASH_ACCESS_KEY"
    private let secretKey = "YOUR_UNSPLASH_SECRET_KEY"
    private let baseURL = "https://api.unsplash.com"

    private init() {}

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 10, completion: @escaping ([UnsplashPhoto]?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/search/photos") else {
            completion(nil)
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "client_id", value: accessKey)
        ]

        guard let url = urlComponents.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
                completion(searchResponse.results)
            } catch {
                print("Error decoding Unsplash response: \(error)")
                completion(nil)
            }
        }.resume()
    }

    func getRandomPhoto(query: String? = nil, completion: @escaping (UnsplashPhoto?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/photos/random") else {
            completion(nil)
            return
        }

        var queryItems = [URLQueryItem(name: "client_id", value: accessKey)]
        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let photo = try JSONDecoder().decode(UnsplashPhoto.self, from: data)
                completion(photo)
            } catch {
                print("Error decoding random Unsplash photo: \(error)")
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
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }

    func trackDownload(for photoId: String) {
        // Track the download as per Unsplash API guidelines
        guard let downloadURL = URL(string: "https://api.unsplash.com/photos/\(photoId)/download?client_id=\(accessKey)") else {
            return
        }

        URLSession.shared.dataTask(with: downloadURL).resume()
    }
}
