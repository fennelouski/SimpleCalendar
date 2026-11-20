//
//  SceneWeather.swift
//  Simple Calendar
//
//  Weather Backgrounds: the real weather where the TV is, for the current month's scene.
//  Apple Weather is fetched on the device about once an hour. When the backend reports
//  that WeatherKit quota is tight ("shared" mode), TVs in the same ~25 km area reuse a
//  recent copy from the backend and only fetch (then share) when there is none.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine
#if canImport(WeatherKit)
import WeatherKit
#endif

/// One hour of weather in the shape the backend shares (mirrors `lib/sky-weather.ts`).
nonisolated struct WeatherHour: Codable, Equatable {
    var t: Double
    var cloud: Double
    var precip: Double
    var kind: String
    var wind: Double
    var gust: Double
    var visibility: Double
    var thunder: Bool
    var temp: Double
}

nonisolated struct WeatherPayload: Codable, Equatable {
    var fetchedAt: Double
    var hours: [WeatherHour]
}

/// The weather at one moment, blended between forecast hours, as the scenes read it.
struct SceneWeather {
    /// 0...1 sky covered by cloud.
    var cloud: Double
    /// Rain-like precipitation rate (rain, sleet, hail), mm/h.
    var rainRate: Double
    /// Snowfall rate, mm/h of water.
    var snowRate: Double
    var sleet: Bool
    /// Wind and gusts, m/s.
    var wind: Double
    var gust: Double
    /// Metres.
    var visibility: Double
    /// 0...1, eases in and out around thundery hours.
    var thunder: Double
    /// °C.
    var temperature: Double

    // MARK: 0...1 strengths the painters use

    var overcast: CGFloat { BG.smoothstep(0.35, 0.95, CGFloat(cloud)) }
    var rain: CGFloat { BG.smoothstep(0.05, 6, CGFloat(rainRate)) }
    var snow: CGFloat { BG.smoothstep(0.02, 2.5, CGFloat(snowRate)) }
    var fog: CGFloat { 1 - BG.smoothstep(800, 9000, CGFloat(visibility)) }
    var windiness: CGFloat { BG.smoothstep(2, 16, CGFloat(max(wind, gust * 0.7))) }
    var storm: CGFloat { CGFloat(thunder) }
    var frost: CGFloat { 1 - BG.smoothstep(-4, 2, CGFloat(temperature)) }
    /// How much the weather hides the sun, moon and stars.
    var cover: CGFloat { min(1, overcast * 0.85 + rain * 0.3 + snow * 0.3 + fog * 0.6) }
    /// Signed horizontal wind push (always from the left for a calm, readable scene).
    var push: CGFloat { CGFloat(min(wind, 30)) }

    static func blend(_ hours: [WeatherHour], at date: Date) -> SceneWeather? {
        guard let first = hours.first else { return nil }
        let now = date.timeIntervalSince1970
        // Only use a forecast that covers now (with an hour of slack either side).
        guard let last = hours.last, now >= first.t - 3600, now <= last.t + 2 * 3600 else { return nil }
        let upper = hours.firstIndex { $0.t > now } ?? hours.count - 1
        let lower = max(upper - 1, 0)
        let a = hours[lower], b = hours[upper]
        let f = b.t > a.t ? min(max((now - a.t) / (b.t - a.t), 0), 1) : 0
        func mix(_ x: Double, _ y: Double) -> Double { x + (y - x) * f }
        func rain(_ h: WeatherHour) -> Double { ["rain", "sleet", "hail"].contains(h.kind) ? h.precip : 0 }
        func snow(_ h: WeatherHour) -> Double { h.kind == "snow" || h.kind == "sleet" ? h.precip * (h.kind == "sleet" ? 0.5 : 1) : 0 }
        return SceneWeather(
            cloud: mix(a.cloud, b.cloud), rainRate: mix(rain(a), rain(b)), snowRate: mix(snow(a), snow(b)),
            sleet: (f < 0.5 ? a : b).kind == "sleet", wind: mix(a.wind, b.wind), gust: mix(a.gust, b.gust),
            visibility: mix(a.visibility, b.visibility), thunder: mix(a.thunder ? 1 : 0, b.thunder ? 1 : 0),
            temperature: mix(a.temp, b.temp)
        )
    }
}

/// Keeps an hourly forecast for the TV's area while Weather Backgrounds is on.
final class SceneWeatherService: ObservableObject {
    static let shared = SceneWeatherService()

    @Published private(set) var payload: WeatherPayload?

    static let refreshInterval: TimeInterval = 60 * 60
    private let defaults: UserDefaults
    private let network: CalendarNetworkRequests
    private let location: ApproximateLocationStore
    private let storeKey = "sceneWeather.payload"
    private var timer: Timer?
    private var consentObserver: NSObjectProtocol?
    private var fetching = false
    private var lastAttempt: Date?
    /// After a failed fetch, wait this long before trying again.
    static let retryInterval: TimeInterval = 20 * 60

    init(defaults: UserDefaults = .standard, network: CalendarNetworkRequests = .shared, location: ApproximateLocationStore = .shared) {
        self.defaults = defaults
        self.network = network
        self.location = location
        if enabled, let data = defaults.data(forKey: storeKey) {
            payload = try? JSONDecoder().decode(WeatherPayload.self, from: data)
        }
    }

    var enabled: Bool { CalendarNetworkConsent.allows(CalendarNetworkConsent.weatherBackgrounds, defaults: defaults) }

    func start() {
        guard timer == nil else { return }
        location.start()
        refreshIfDue()
        timer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshIfDue() }
        }
        consentObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: defaults, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.consentMayHaveChanged() }
        }
    }

    /// The weather now, or nil when weather backgrounds are off or there is no fresh forecast.
    func conditions(at date: Date) -> SceneWeather? {
        guard enabled, let payload else { return nil }
        return SceneWeather.blend(payload.hours, at: date)
    }

    private func consentMayHaveChanged() {
        if enabled {
            refreshIfDue()
        } else if payload != nil || defaults.object(forKey: storeKey) != nil {
            payload = nil
            defaults.removeObject(forKey: storeKey)
        }
    }

    private func refreshIfDue() {
        guard enabled, !fetching else { return }
        if let payload, Date().timeIntervalSince1970 - payload.fetchedAt < Self.refreshInterval { return }
        if let lastAttempt, Date().timeIntervalSince(lastAttempt) < Self.retryInterval { return }
        lastAttempt = Date()
        fetching = true
        location.refreshIfDue { [weak self] in self?.fetch() }
    }

    private func fetch() {
        guard enabled else { fetching = false; return }
        if location.weatherMode == .shared, let cell = location.cell {
            fetchShared(cell: cell) { [weak self] shared in
                guard let self else { return }
                if let shared { self.store(shared); self.fetching = false }
                else { self.fetchFromApple(shareAs: cell) }
            }
        } else {
            fetchFromApple(shareAs: nil)
        }
    }

    private func fetchShared(cell: String, completion: @escaping (WeatherPayload?) -> Void) {
        guard let ticket = network.ticket(for: CalendarNetworkConsent.weatherBackgrounds),
              var components = URLComponents(string: CalendarBackend.baseURL + "/api/sky/weather") else { completion(nil); return }
        components.queryItems = [URLQueryItem(name: "cell", value: cell)]
        guard let url = components.url else { completion(nil); return }
        network.data(for: URLRequest(url: url), ticket: ticket) { data in
            completion(data.flatMap { try? JSONDecoder().decode(WeatherPayload.self, from: $0) })
        }
    }

    private func share(_ payload: WeatherPayload, cell: String) {
        guard let ticket = network.ticket(for: CalendarNetworkConsent.weatherBackgrounds),
              let url = URL(string: CalendarBackend.baseURL + "/api/sky/weather"),
              let body = try? JSONEncoder().encode(["cell": AnyEncodable(cell), "payload": AnyEncodable(payload)]) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        network.data(for: request, ticket: ticket) { _ in }
    }

    private func store(_ payload: WeatherPayload) {
        guard enabled else { return }
        self.payload = payload
        if let data = try? JSONEncoder().encode(payload) { defaults.set(data, forKey: storeKey) }
    }

    private func fetchFromApple(shareAs cell: String?) {
        #if canImport(WeatherKit)
        let coordinate = location.coordinate
        Task { [weak self] in
            let result = try? await WeatherService.shared.weather(
                for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                including: .hourly(startDate: Date().addingTimeInterval(-3600), endDate: Date().addingTimeInterval(25 * 3600))
            )
            guard let self else { return }
            self.fetching = false
            guard self.enabled, let result else { return }
            let payload = WeatherPayload(fetchedAt: Date().timeIntervalSince1970.rounded(), hours: result.forecast.map(Self.hour))
            guard !payload.hours.isEmpty else { return }
            self.store(payload)
            if let cell { self.share(payload, cell: cell) }
        }
        #else
        fetching = false
        #endif
    }

    #if canImport(WeatherKit)
    private static func hour(_ weather: HourWeather) -> WeatherHour {
        let kind: String
        switch weather.precipitation {
        case .rain: kind = "rain"
        case .snow: kind = "snow"
        case .sleet, .mixed: kind = "sleet"
        case .hail: kind = "hail"
        default: kind = "none"
        }
        let thunder: Bool
        switch weather.condition {
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .tropicalStorm, .hurricane: thunder = true
        default: thunder = false
        }
        func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double { min(max(x.isFinite ? x : lo, lo), hi) }
        return WeatherHour(
            t: weather.date.timeIntervalSince1970.rounded(),
            cloud: clamp(weather.cloudCover, 0, 1),
            precip: kind == "none" ? 0 : clamp(weather.precipitationAmount.converted(to: .millimeters).value, 0, 300),
            kind: kind,
            wind: clamp(weather.wind.speed.converted(to: .metersPerSecond).value, 0, 120),
            gust: clamp(weather.wind.gust?.converted(to: .metersPerSecond).value ?? 0, 0, 150),
            visibility: clamp(weather.visibility.converted(to: .meters).value, 0, 200_000),
            thunder: thunder,
            temp: clamp(weather.temperature.converted(to: .celsius).value, -90, 65)
        )
    }
    #endif
}

/// Lets the share body mix a string and a payload without a dedicated struct per call.
nonisolated private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { encodeValue = value.encode }
    func encode(to encoder: Encoder) throws { try encodeValue(encoder) }
}

// MARK: - Attribution

/// The Apple Weather mark and legal link Apple requires wherever its weather data is used.
struct AppleWeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var mark: URL?
    @State private var legal: URL?

    var body: some View {
        HStack(spacing: 12) {
            if let mark {
                AsyncImage(url: mark) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Text(" Weather").font(.caption.weight(.semibold))
                }
                .frame(height: 22)
            } else {
                Text(" Weather").font(.caption.weight(.semibold))
            }
            if let legal {
                // Apple TV has no browser, so the legal page is shown as its address.
                Text(legal.absoluteString).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Apple Weather. Other data sources are listed at \(legal?.absoluteString ?? "weatherkit.apple.com/legal-attribution.html").")
        .task(id: colorScheme) {
            #if canImport(WeatherKit)
            if let attribution = try? await WeatherService.shared.attribution {
                mark = colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
                legal = attribution.legalPageURL
            }
            #endif
        }
    }
}
