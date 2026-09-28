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

// Each consent stays on this device and starts disabled, including for existing installs.
nonisolated enum CalendarNetworkConsent {
    static let photos = "CalendarPlay.allowOnlinePhotos"
    static let eventPhotos = "CalendarPlay.allowEventPhotoQueries"
    // The legacy allowNetworkLocation preference is left untouched but no longer enables a provider.
    static let weather = "CalendarPlay.allowOnlineWeather"
    static let history = "feature_onThisDayEnabled"
    static let keys = [photos, eventPhotos, weather, history]

    static func allows(_ key: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key) && (key != eventPhotos || defaults.bool(forKey: photos))
    }
}

/// Central URLSession gate: revocation cancels active work and invalidates queued results.
nonisolated final class CalendarNetworkRequests: @unchecked Sendable {
    static let shared = CalendarNetworkRequests()
    struct Ticket: Sendable { let key: String; let generation: Int }
    private let lock = NSLock()
    private let defaults: UserDefaults
    private let session: URLSession
    private var generations: [String: Int] = [:]
    private var allowed: [String: Bool] = [:]
    private var tasks: [UUID: (Ticket, URLSessionDataTask)] = [:]
    private var observer: NSObjectProtocol?

    init(defaults: UserDefaults = .standard, session: URLSession = URLSession(configuration: .ephemeral)) {
        self.defaults = defaults
        self.session = session
        for key in CalendarNetworkConsent.keys { allowed[key] = CalendarNetworkConsent.allows(key, defaults: defaults) }
        observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [weak self] _ in self?.refreshConsent() }
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    func refreshConsent() {
        lock.lock()
        for key in CalendarNetworkConsent.keys {
            let current = CalendarNetworkConsent.allows(key, defaults: defaults)
            if allowed[key] != current {
                generations[key, default: 0] += 1
                allowed[key] = current
            }
        }
        let canceled = tasks.values.filter { !validWhileLocked($0.0) }.map { $0.1 }
        lock.unlock()
        canceled.forEach { $0.cancel() }
    }

    func ticket(for key: String) -> Ticket? {
        refreshConsent()
        lock.lock(); defer { lock.unlock() }
        guard allowed[key] == true else { return nil }
        return Ticket(key: key, generation: generations[key, default: 0])
    }

    func isValid(_ ticket: Ticket) -> Bool {
        refreshConsent()
        lock.lock(); defer { lock.unlock() }
        return validWhileLocked(ticket)
    }

    private func validWhileLocked(_ ticket: Ticket) -> Bool {
        allowed[ticket.key] == true && generations[ticket.key, default: 0] == ticket.generation
    }

    func data(for request: URLRequest, ticket: Ticket, completion: @escaping (Data?) -> Void) {
        guard isValid(ticket) else { DispatchQueue.main.async { completion(nil) }; return }
        let id = UUID()
        guard var boundedRequest = try? CalendarAPIRequest.prepared(request) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        boundedRequest.timeoutInterval = 20
        let task = session.dataTask(with: boundedRequest) { [weak self] data, response, error in
            guard let self else { return }
            self.lock.lock(); self.tasks.removeValue(forKey: id); self.lock.unlock()
            let successful = error == nil && ((response as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? false)
            DispatchQueue.main.async {
                completion(successful && self.isValid(ticket) ? data : nil)
            }
        }
        lock.lock(); tasks[id] = (ticket, task); lock.unlock()
        if isValid(ticket) { task.resume() } else { task.cancel() }
    }
}

class UnsplashAPI {
    static let shared = UnsplashAPI()
    private let networkRequests: CalendarNetworkRequests
    private var backendBaseURL: String {
        #if DEBUG
        "http://localhost:3001/api/unsplash"
        #else
        "https://calendar-play-seven.vercel.app/api/unsplash"
        #endif
    }
    init(networkRequests: CalendarNetworkRequests = .shared) { self.networkRequests = networkRequests }

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 10, completion: @escaping ([UnsplashPhoto]?) -> Void) {
        fetchPhotos(items: [URLQueryItem(name: "action", value: "search"), URLQueryItem(name: "query", value: String(query.prefix(200))), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "per_page", value: String(perPage))], key: CalendarNetworkConsent.photos, completion: completion)
    }

    func getRandomPhoto(query: String? = nil, requiresEventConsent: Bool = false, completion: @escaping (UnsplashPhoto?) -> Void) {
        var items = [URLQueryItem(name: "action", value: "random")]
        if let query { items.append(URLQueryItem(name: "query", value: String(query.prefix(200)))) }
        fetchPhotos(items: items, key: requiresEventConsent ? CalendarNetworkConsent.eventPhotos : CalendarNetworkConsent.photos) { completion($0?.first) }
    }

    private func fetchPhotos(items: [URLQueryItem], key: String, completion: @escaping ([UnsplashPhoto]?) -> Void) {
        guard let ticket = networkRequests.ticket(for: key), var components = URLComponents(string: backendBaseURL) else { completion(nil); return }
        components.queryItems = items
        guard let url = components.url else { completion(nil); return }
        networkRequests.data(for: URLRequest(url: url), ticket: ticket) { data in
            guard let data else { completion(nil); return }
            completion(try? JSONDecoder().decode([UnsplashPhoto].self, from: data))
        }
    }

    func downloadImage(from urlString: String, requiresEventConsent: Bool = false, completion: @escaping (Data?) -> Void) {
        let key = requiresEventConsent ? CalendarNetworkConsent.eventPhotos : CalendarNetworkConsent.photos
        guard let ticket = networkRequests.ticket(for: key), let url = URL(string: urlString), url.scheme == "https", ["images.unsplash.com", "plus.unsplash.com"].contains(url.host?.lowercased() ?? "") else { completion(nil); return }
        // Use the provider's returned CDN URL directly, retaining its attribution/query parameters.
        networkRequests.data(for: URLRequest(url: url), ticket: ticket, completion: completion)
    }

    func trackDownload(for photoId: String, requiresEventConsent: Bool = false) {
        let key = requiresEventConsent ? CalendarNetworkConsent.eventPhotos : CalendarNetworkConsent.photos
        guard let ticket = networkRequests.ticket(for: key), let url = URL(string: backendBaseURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["action": "track_download", "photoId": photoId])
        networkRequests.data(for: request, ticket: ticket) { _ in }
    }
}

struct UnsplashAttributionView: View {
    let author: String
    let authorURL: String?

    private func creditedURL(_ string: String) -> URL? {
        guard var components = URLComponents(string: string), components.scheme == "https", components.host == "unsplash.com" else { return nil }
        var query = components.queryItems ?? []
        query.removeAll { ["utm_source", "utm_medium"].contains($0.name) }
        query += [URLQueryItem(name: "utm_source", value: "calendar_play"), URLQueryItem(name: "utm_medium", value: "referral")]
        components.queryItems = query
        return components.url
    }

    var body: some View {
        HStack(spacing: 3) {
            Text("Photo by")
            if let authorURL, let url = creditedURL(authorURL) { Link(author, destination: url) }
            else { Text(author) }
            Text("on")
            Link("Unsplash", destination: creditedURL("https://unsplash.com")!)
        }
        .font(.caption2)
        .foregroundStyle(.white)
        .padding(6)
        .background(.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
