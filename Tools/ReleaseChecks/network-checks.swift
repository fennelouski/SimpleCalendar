import Foundation
import AppKit

final class StubProtocol: URLProtocol {
    static let lock = NSLock()
    static var loads = 0
    static var stops = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); Self.loads += 1; Self.lock.unlock()
        if request.url!.path == "/held" { return }
        let response = HTTPURLResponse(url: request.url!, statusCode: request.url!.path == "/failure" ? 500 : 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("fixture".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { Self.lock.lock(); Self.stops += 1; Self.lock.unlock() }
}

func require(_ value: Bool, _ message: String) {
    guard value else { fatalError(message) }
    print("PASS: \(message)")
}

@main struct Checks {
    @MainActor static func main() async throws {
        let suite = "CalendarPrivacyChecks-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let gate = CalendarNetworkRequests(defaults: defaults, session: URLSession(configuration: configuration))
        require(CalendarNetworkConsent.keys.allSatisfy { gate.ticket(for: $0) == nil }, "fresh settings deny every provider request")
        let legacyLocationKey = "CalendarPlay.allowNetworkLocation"
        defaults.set(true, forKey: legacyLocationKey)
        require(gate.ticket(for: legacyLocationKey) == nil, "legacy location grant cannot create a network ticket")
        require(defaults.bool(forKey: legacyLocationKey), "retired location choice remains stored without changing other preferences")
        let estimator = LocationApproximator.shared
        let london = estimator.approximateLocation(timeZone: TimeZone(identifier: "Europe/London")!, locale: Locale(identifier: "de_DE"))
        require(london.latitude == 51.5074 && london.longitude == -0.1278, "existing time-zone estimate takes precedence over region")
        let germany = estimator.approximateLocation(timeZone: TimeZone(secondsFromGMT: 0)!, locale: Locale(identifier: "de_DE"))
        require(germany.latitude == 51.1657 && germany.longitude == 10.4515, "unmapped time zone preserves local region fallback")
        let fallback = estimator.approximateLocation(timeZone: TimeZone(secondsFromGMT: 0)!, locale: Locale(identifier: "zz_ZZ"))
        require(fallback.latitude == 39.8283 && fallback.longitude == -98.5795, "unknown device settings retain existing final fallback")
        require(StubProtocol.loads == 0, "local estimate checks start no provider requests")
        defaults.set(true, forKey: CalendarNetworkConsent.eventPhotos)
        gate.refreshConsent()
        require(gate.ticket(for: CalendarNetworkConsent.eventPhotos) == nil, "event matching also needs online photo consent")
        defaults.set(true, forKey: CalendarNetworkConsent.photos); gate.refreshConsent()
        let ticket = gate.ticket(for: CalendarNetworkConsent.photos)!
        require(gate.ticket(for: CalendarNetworkConsent.eventPhotos) != nil, "both grants enable event matching")
        func fetch(_ path: String, _ ticket: CalendarNetworkRequests.Ticket) async -> Data? {
            await withCheckedContinuation { continuation in gate.data(for: URLRequest(url: URL(string: "https://fixture.invalid\(path)")!), ticket: ticket) { continuation.resume(returning: $0) } }
        }
        require(await fetch("/success", ticket) == Data("fixture".utf8), "allowed transport returns successful fixture")
        require(await fetch("/failure", ticket) == nil, "HTTP failure body never treated as data")
        let pending = Task { await fetch("/held", ticket) }
        while StubProtocol.loads < 3 { try await Task.sleep(for: .milliseconds(5)) }
        defaults.set(false, forKey: CalendarNetworkConsent.photos); gate.refreshConsent()
        require(await pending.value == nil, "revocation cancels active request and discards its result")
        require(StubProtocol.stops > 0, "URLSession cancellation reaches the transport")
        defaults.set(true, forKey: CalendarNetworkConsent.photos); gate.refreshConsent()
        let previousLoads = StubProtocol.loads
        require(await fetch("/success", ticket) == nil, "re-enabling does not revive an old request ticket")
        require(StubProtocol.loads == previousLoads, "stale queued request never reaches transport")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("CalendarImagesChecks-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = ImageRepository(directory: directory)
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let image = NSImage(size: NSSize(width: 2, height: 2)); image.addRepresentation(bitmap)
        func metadata(_ id: String, selected: Bool?, unsplash: String? = "photo") -> ImageMetadata {
            ImageMetadata(id: id, unsplashId: unsplash, url: "https://images.unsplash.com/fixture", thumbnailUrl: "", author: "Fixture", authorUrl: nil, downloadUrl: "", cachedAt: Date(timeIntervalSince1970: 0), tags: [], locationQuery: nil, titleQuery: nil, isUserSelected: selected)
        }
        require(repository.saveImage(image, metadata: metadata("selected", selected: true)), "selected image and index save durably")
        require(repository.saveImage(image, metadata: metadata("legacy", selected: nil)), "legacy unknown selection retained")
        require(repository.saveImage(image, metadata: metadata("imported", selected: false, unsplash: nil)), "local imported image saved")
        require(repository.saveImage(image, metadata: metadata("automatic", selected: false)), "disposable automatic image saved")
        repository.clearExpiredImages(); repository.limitCacheSize(maxImages: 0)
        require(repository.getImage(for: "selected") != nil && repository.getImage(for: "legacy") != nil && repository.getImage(for: "imported") != nil, "expiry and size cleanup preserve selected, legacy and local images")
        require(repository.getImage(for: "automatic") == nil, "cleanup can remove expired disposable image")
        let reopened = ImageRepository(directory: directory)
        require(reopened.getImage(for: "selected") != nil && reopened.getImageMetadata(for: "selected")?.isUserSelected == true, "durable image and metadata reopen together")
        let index = directory.appendingPathComponent("metadata.json")
        let originalBytes = try Data(contentsOf: directory.appendingPathComponent("selected.jpg"))
        try FileManager.default.removeItem(at: index)
        try FileManager.default.createDirectory(at: index, withIntermediateDirectories: false)
        require(!repository.saveImage(image, metadata: metadata("failed", selected: true)), "real metadata write failure reports failure")
        require(repository.getImage(for: "failed") == nil && !FileManager.default.fileExists(atPath: directory.appendingPathComponent("failed.jpg").path), "failed image does not create a broken identifier or cache entry")
        require(!repository.saveImage(image, metadata: metadata("selected", selected: false)), "failed replacement reports failure")
        require(try Data(contentsOf: directory.appendingPathComponent("selected.jpg")) == originalBytes && repository.getImageMetadata(for: "selected")?.isUserSelected == true, "failed replacement preserves old bytes and metadata")
        try FileManager.default.removeItem(at: index)
        try Data("corrupt-index".utf8).write(to: index)
        let damaged = ImageRepository(directory: directory)
        require(!damaged.saveImage(image, metadata: metadata("new", selected: true)), "unreadable index cannot be overwritten with an empty store")
        require(try Data(contentsOf: index) == Data("corrupt-index".utf8), "corrupt original is preserved for recovery")
        print("ALL NETWORK AND IMAGE CHECKS PASSED")
    }
}
