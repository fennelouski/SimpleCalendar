//
//  SunClock.swift
//  Simple Calendar
//
//  Tracks where the sun is for the household's approximate location so the
//  calendar background can move through night, twilight, sunrise, day and sunset.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Solar position

/// NOAA solar-position approximation; accurate to a fraction of a degree, which is
/// far tighter than the location estimate feeding it.
nonisolated enum SolarPosition {
    struct Sample: Equatable {
        /// Degrees above (+) or below (-) the horizon.
        let elevation: Double
        /// True before solar noon, so the sky glows on the eastern side.
        let isMorning: Bool
        /// Degrees from solar noon: negative in the morning, positive in the afternoon.
        var hourAngle: Double = 0
        /// The highest the sun climbs on this day at this latitude.
        var noonElevation: Double = 45
    }

    static func sample(at date: Date, latitude: Double, longitude: Double) -> Sample {
        let rad = Double.pi / 180
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let t = (julianDay - 2_451_545) / 36_525

        let meanLongitude = (280.46646 + t * (36_000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let meanAnomaly = 357.52911 + t * (35_999.05029 - 0.0001537 * t)
        let eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let center = sin(meanAnomaly * rad) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * meanAnomaly * rad) * (0.019993 - 0.000101 * t)
            + sin(3 * meanAnomaly * rad) * 0.000289
        let omega = 125.04 - 1_934.136 * t
        let apparentLongitude = meanLongitude + center - 0.00569 - 0.00478 * sin(omega * rad)
        let meanObliquity = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let obliquity = meanObliquity + 0.00256 * cos(omega * rad)
        let declination = asin(sin(obliquity * rad) * sin(apparentLongitude * rad))

        let y = pow(tan(obliquity * rad / 2), 2)
        let equationOfTime = 4 / rad * (
            y * sin(2 * meanLongitude * rad)
            - 2 * eccentricity * sin(meanAnomaly * rad)
            + 4 * eccentricity * y * sin(meanAnomaly * rad) * cos(2 * meanLongitude * rad)
            - 0.5 * y * y * sin(4 * meanLongitude * rad)
            - 1.25 * eccentricity * eccentricity * sin(2 * meanAnomaly * rad)
        ) // minutes

        // Cheap enough to run every animation frame: no Calendar, just seconds since UTC midnight.
        var utcSeconds = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400)
        if utcSeconds < 0 { utcSeconds += 86_400 }
        let utcMinutes = utcSeconds / 60
        var trueSolarMinutes = (utcMinutes + equationOfTime + 4 * longitude).truncatingRemainder(dividingBy: 1_440)
        if trueSolarMinutes < 0 { trueSolarMinutes += 1_440 }
        let hourAngle = trueSolarMinutes / 4 - 180 // degrees; negative before solar noon

        let cosZenith = sin(latitude * rad) * sin(declination) + cos(latitude * rad) * cos(declination) * cos(hourAngle * rad)
        let zenith = acos(min(max(cosZenith, -1), 1)) / rad
        let noonElevation = 90 - abs(latitude - declination / rad)
        return Sample(elevation: 90 - zenith, isMorning: hourAngle < 0, hourAngle: hourAngle, noonElevation: noonElevation)
    }
}

// MARK: - Approximate location

/// The Calendar Play backend (local server in debug builds). Every app request goes
/// through this one origin; the older vercel.app address keeps serving installed versions.
nonisolated enum CalendarBackend {
    static let host = "calendarplay.nathanfennel.com"
    static var baseURL: String {
        #if DEBUG
        "http://localhost:3001"
        #else
        "https://\(host)"
        #endif
    }
}

/// Where the Apple TV probably is. An Apple TV rarely moves, so this favours stability.
/// By default it is the time zone's region and nothing leaves the device. While Weather
/// Backgrounds is on, the backend's coarse area for the TV's connection is checked at most
/// once an hour and the last five answers are averaged.
final class ApproximateLocationStore: ObservableObject {
    static let shared = ApproximateLocationStore()

    enum Source: Equatable {
        case timeZone
        case network(samples: Int)
    }

    enum WeatherMode: String { case direct, shared }

    @Published private(set) var coordinate: CLLocationCoordinate2D
    @Published private(set) var source: Source = .timeZone
    /// The backend's ~25 km sharing cell for this TV, when known.
    private(set) var cell: String?
    /// Whether the backend wants weather fetched directly or shared through its cache.
    private(set) var weatherMode: WeatherMode = .direct

    static let maximumSamples = 5
    static let checkInterval: TimeInterval = 60 * 60

    private let defaults: UserDefaults
    private let network: CalendarNetworkRequests
    private let samplesKey = "approximateLocation.samples"
    private let cellKey = "approximateLocation.cell"
    private let modeKey = "approximateLocation.weatherMode"
    private let timeZoneKey = "approximateLocation.timeZone"
    private let lastCheckKey = "approximateLocation.lastCheck"
    private var timer: Timer?
    private var consentObserver: NSObjectProtocol?
    private var lookupInFlight = false
    private var waiting: [() -> Void] = []

    init(defaults: UserDefaults = .standard, network: CalendarNetworkRequests = .shared) {
        self.defaults = defaults
        self.network = network
        self.coordinate = LocationApproximator.shared.approximateLocation()
        resetIfTimeZoneChanged()
        publish()
    }

    func start() {
        guard timer == nil else { return }
        checkIfDue()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkIfDue() }
        }
        consentObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: defaults, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.consentMayHaveChanged() }
        }
    }

    private var enabled: Bool { CalendarNetworkConsent.allows(CalendarNetworkConsent.weatherBackgrounds, defaults: defaults) }

    private func consentMayHaveChanged() {
        if enabled {
            checkIfDue()
        } else if defaults.object(forKey: samplesKey) != nil {
            // Turning weather off forgets the network-derived area, not just future lookups.
            for key in [samplesKey, cellKey, modeKey, lastCheckKey] { defaults.removeObject(forKey: key) }
            publish()
        }
    }

    /// Runs `then` once the hourly area check (if one is due) has finished.
    func refreshIfDue(then: @escaping () -> Void) {
        waiting.append(then)
        checkIfDue()
        if !lookupInFlight { flushWaiting() }
    }

    private func flushWaiting() {
        let callbacks = waiting
        waiting.removeAll()
        callbacks.forEach { $0() }
    }

    private func checkIfDue(now: Date = Date()) {
        resetIfTimeZoneChanged()
        guard enabled, !lookupInFlight else { return }
        if let last = defaults.object(forKey: lastCheckKey) as? Date, now.timeIntervalSince(last) < Self.checkInterval, last <= now { return }
        guard let ticket = network.ticket(for: CalendarNetworkConsent.weatherBackgrounds),
              let url = URL(string: CalendarBackend.baseURL + "/api/sky") else { return }
        lookupInFlight = true
        defaults.set(now, forKey: lastCheckKey) // count failures too, so a bad network never causes rapid retries
        network.data(for: URLRequest(url: url), ticket: ticket) { [weak self] data in
            guard let self else { return }
            self.lookupInFlight = false
            if let data, let answer = Self.parse(data) {
                self.defaults.set(answer.mode.rawValue, forKey: self.modeKey)
                if let area = answer.area {
                    var samples = self.storedSamples()
                    samples.append([area.latitude, area.longitude])
                    self.defaults.set(Array(samples.suffix(Self.maximumSamples)), forKey: self.samplesKey)
                    self.defaults.set(area.cell, forKey: self.cellKey)
                }
                self.publish()
            }
            self.flushWaiting()
        }
    }

    struct Answer { let area: (latitude: Double, longitude: Double, cell: String)?; let mode: WeatherMode }

    /// Reads the backend's answer. An area whose longitude disagrees with the device's
    /// time zone by more than a few hours (a VPN exit, a mis-located carrier) is dropped.
    nonisolated static func parse(_ data: Data, deviceTimeZone: TimeZone = .current, now: Date = Date()) -> Answer? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let mode = WeatherMode(rawValue: json["weatherMode"] as? String ?? "") ?? .direct
        guard let area = json["area"] as? [String: Any],
              let latitude = area["latitude"] as? Double, let longitude = area["longitude"] as? Double,
              let cell = area["cell"] as? String,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            return Answer(area: nil, mode: mode)
        }
        let offsetHours = Double(deviceTimeZone.secondsFromGMT(for: now)) / 3600
        var gap = abs(longitude / 15 - offsetHours)
        gap = min(gap, 24 - gap)
        guard gap <= 3.5 else { return Answer(area: nil, mode: mode) }
        return Answer(area: (latitude, longitude, cell), mode: mode)
    }

    private func storedSamples() -> [[Double]] {
        (defaults.array(forKey: samplesKey) as? [[Double]])?.filter { $0.count == 2 } ?? []
    }

    /// A new time zone means the TV moved; old samples no longer describe it.
    private func resetIfTimeZoneChanged() {
        let current = TimeZone.current.identifier
        if let stored = defaults.string(forKey: timeZoneKey), stored != current {
            for key in [samplesKey, cellKey, lastCheckKey] { defaults.removeObject(forKey: key) }
        }
        if defaults.string(forKey: timeZoneKey) != current { defaults.set(current, forKey: timeZoneKey) }
    }

    private func publish() {
        let samples = enabled ? storedSamples() : []
        cell = enabled ? defaults.string(forKey: cellKey) : nil
        weatherMode = WeatherMode(rawValue: defaults.string(forKey: modeKey) ?? "") ?? .direct
        let next: CLLocationCoordinate2D
        if let average = Self.average(samples) {
            next = average
            if source != .network(samples: samples.count) { source = .network(samples: samples.count) }
        } else {
            next = LocationApproximator.shared.approximateLocation()
            if source != .timeZone { source = .timeZone }
        }
        if next.latitude != coordinate.latitude || next.longitude != coordinate.longitude { coordinate = next }
    }

    /// Mean of the samples on the sphere, so readings either side of the antimeridian average correctly.
    nonisolated static func average(_ samples: [[Double]]) -> CLLocationCoordinate2D? {
        guard !samples.isEmpty else { return nil }
        let rad = Double.pi / 180
        var x = 0.0, y = 0.0, z = 0.0
        for sample in samples {
            let lat = sample[0] * rad, lon = sample[1] * rad
            x += cos(lat) * cos(lon); y += cos(lat) * sin(lon); z += sin(lat)
        }
        let n = Double(samples.count)
        x /= n; y /= n; z /= n
        return CLLocationCoordinate2D(latitude: atan2(z, sqrt(x * x + y * y)) / rad, longitude: atan2(y, x) / rad)
    }
}

// MARK: - Sun clock

/// Publishes the sun's position once a minute for the approximate location.
final class SunClock: ObservableObject {
    static let shared = SunClock()

    /// The look switches between dark and light while the sun is just below the horizon,
    /// when the real sky turns from deep twilight to bright dawn (and back at dusk).
    static let lightElevation = -2.0

    @Published private(set) var sun: SolarPosition.Sample
    @Published private(set) var colorScheme: ColorScheme

    private let location: ApproximateLocationStore
    private var timer: Timer?
    private var locationSubscription: AnyCancellable?

    init(location: ApproximateLocationStore = .shared) {
        self.location = location
        let sample = SolarPosition.sample(at: SunClock.now(), latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        sun = sample
        colorScheme = sample.elevation > SunClock.lightElevation ? .light : .dark
    }

    func start() {
        guard timer == nil else { return }
        location.start()
        locationSubscription = location.$coordinate.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.update() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        update()
    }

    private func update() {
        let coordinate = location.coordinate
        let next = SolarPosition.sample(at: SunClock.now(), latitude: coordinate.latitude, longitude: coordinate.longitude)
        if next != sun { sun = next }
        let scheme: ColorScheme = next.elevation > SunClock.lightElevation ? .light : .dark
        if scheme != colorScheme { colorScheme = scheme }
    }

    /// The current time; cheap enough to call every animation frame.
    static func now() -> Date { Date() }

    /// The sun for any moment at the approximate location (used per frame by the scenes).
    func sample(at date: Date) -> SolarPosition.Sample {
        let coordinate = location.coordinate
        return SolarPosition.sample(at: date, latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

// MARK: - Appearance

private struct FollowSunAppearance: ViewModifier {
    @ObservedObject private var featureFlags = FeatureFlags.shared
    @State private var scheme: ColorScheme = SunClock.shared.colorScheme

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(featureFlags.followSunAppearance ? scheme : nil)
            // Only the scheme is observed here, so the minute-by-minute sun updates
            // never invalidate the whole view tree.
            .onReceive(SunClock.shared.$colorScheme.removeDuplicates()) { scheme = $0 }
            .onAppear {
                SunClock.shared.start()
                SceneWeatherService.shared.start()
            }
    }
}

extension View {
    /// Light by day and dark by night, following the sun at the approximate location.
    func followsSunAppearance() -> some View { modifier(FollowSunAppearance()) }
}
