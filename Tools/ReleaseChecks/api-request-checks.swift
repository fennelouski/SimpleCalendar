import Foundation
import CryptoKit

func require(_ value: Bool, _ message: String) {
    guard value else { fatalError(message) }
    print("PASS: \(message)")
}

// Intercepts the production caller's final URLSession request. The live bridge changes
// only its origin and supplies the existing AWS preview credential, never its digest.
final class APIProtocol: URLProtocol {
    static let lock = NSLock()
    static var origin: String?
    static var observations: [[String: Any]] = []
    private var outgoingTask: URLSessionDataTask?
    private var session: URLSession?
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "calendar-play-seven.vercel.app"
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    static func count() -> Int { lock.lock(); defer { lock.unlock() }; return observations.count }
    override func startLoading() {
        do {
            var outgoing = request
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                stream.open(); defer { stream.close() }
                var bytes = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
                while true {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
                    if count == 0 { break }
                    bytes.append(contentsOf: buffer.prefix(count))
                }
                body = bytes
            }
            let digest = body.map { SHA256.hash(data: $0).map { String(format: "%02x", $0) }.joined() }
            if request.httpMethod == "POST" {
                require(body != nil && body!.count <= 65_536, "actual native POST has a bounded buffered body")
                require(request.value(forHTTPHeaderField: "x-amz-content-sha256") == digest, "actual native outgoing POST supplies exact body digest")
            }
            // URLProtocol may expose httpBody as a stream. Forward the same captured bytes.
            outgoing.httpBody = body
            if let origin = Self.origin {
                var target = URLComponents(string: origin)!
                target.path = request.url!.path
                target.percentEncodedQuery = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.percentEncodedQuery
                outgoing.url = target.url!
                if target.host == "d2ntnk2ucb7yym.cloudfront.net" {
                    guard let password = ProcessInfo.processInfo.environment["CALENDAR_PREVIEW_PASSWORD"], !password.isEmpty else { fatalError("Missing existing preview credential") }
                    outgoing.setValue("Basic " + Data("preview:\(password)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
                }
                let configuration = URLSessionConfiguration.ephemeral
                configuration.protocolClasses = []
                let session = URLSession(configuration: configuration); self.session = session
                outgoingTask = session.dataTask(with: outgoing) { data, response, error in
                    if let error { self.client?.urlProtocol(self, didFailWithError: error); return }
                    self.finish(data ?? Data(), response as! HTTPURLResponse, digest: digest, bytes: body?.count ?? 0)
                    session.finishTasksAndInvalidate()
                }
                outgoingTask!.resume()
            } else {
                let text: String
                if request.url!.path == "/api/parse-event" {
                    text = #"{"title":"Synthetic check","startDate":"2026-09-29T10:00:00Z","endDate":"2026-09-29T11:00:00Z"}"#
                } else { text = #"{"success":true}"# }
                finish(Data(text.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!, digest: digest, bytes: body?.count ?? 0)
            }
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    private func finish(_ data: Data, _ response: HTTPURLResponse, digest: String?, bytes: Int) {
        Self.lock.lock()
        Self.observations.append(["origin": Self.origin ?? "offline", "path": request.url!.path,
                                  "method": request.httpMethod ?? "GET", "status": response.statusCode,
                                  "bodyBytes": bytes, "bodySHA256": digest ?? "", "nativeDigestVerified": request.httpMethod == "POST"])
        Self.lock.unlock()
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { outgoingTask?.cancel(); session?.invalidateAndCancel() }
}

@main struct APIRequestChecks {
    @MainActor static func main() async throws {
        var request = URLRequest(url: URL(string: "https://calendar-play-seven.vercel.app/api/parse-event")!)
        request.httpMethod = "POST"
        request.httpBody = Data("  {\"text\":\"café 🎂\"}\n".utf8)
        request.setValue("Bearer synthetic-only", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prepared = try CalendarAPIRequest.prepared(request)
        require(prepared.httpBody == request.httpBody && prepared.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-only" && prepared.value(forHTTPHeaderField: "Content-Type") == "application/json", "preparation preserves exact Unicode bytes and existing credentials/content type")
        require(prepared.value(forHTTPHeaderField: "x-amz-content-sha256") == SHA256.hash(data: request.httpBody!).map { String(format: "%02x", $0) }.joined(), "digest covers final bytes without reserialization")
        request.httpBody = Data("abc".utf8)
        request.setValue("stale-digest", forHTTPHeaderField: "x-amz-content-sha256")
        require(try CalendarAPIRequest.prepared(request).value(forHTTPHeaderField: "x-amz-content-sha256") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "known SHA-256 vector replaces a stale digest")
        request.httpBody = Data(repeating: 32, count: 65_536)
        require(try CalendarAPIRequest.prepared(request).httpBody?.count == 65_536, "64 KiB boundary is accepted")
        request.httpBody!.append(32)
        do { _ = try CalendarAPIRequest.prepared(request); fatalError("oversized body accepted") } catch {}
        request.httpBody = nil
        do { _ = try CalendarAPIRequest.prepared(request); fatalError("missing POST body accepted") } catch {}
        request.httpBodyStream = InputStream(data: Data("{}".utf8))
        do { _ = try CalendarAPIRequest.prepared(request); fatalError("unbuffered stream accepted") } catch {}
        request.httpBodyStream = nil; request.httpBody = Data("{}".utf8)
        request.url = URL(string: "https://oauth2.googleapis.com/token")!
        require(try CalendarAPIRequest.prepared(request) == request, "third-party request and credentials are untouched")
        request.url = URL(string: "https://calendar-play-seven.vercel.app.attacker.invalid/api/parse-event")!
        require(try CalendarAPIRequest.prepared(request) == request, "lookalike hosts are not treated as owned API")
        request.url = URL(string: "https://d2ntnk2ucb7yym.cloudfront.net/api/parse-event")!
        require(try CalendarAPIRequest.prepared(request).value(forHTTPHeaderField: "x-amz-content-sha256") != nil, "registered AWS origin uses the same bounded preparation")

        let suite = "CalendarAPIChecks-\(UUID())"; let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [APIProtocol.self]
        let session = URLSession(configuration: config); defer { session.invalidateAndCancel() }
        let gate = CalendarNetworkRequests(defaults: defaults, session: session)
        let photos = UnsplashAPI(networkRequests: gate)
        photos.trackDownload(for: "synthetic")
        require(APIProtocol.count() == 0, "production photo tracking remains disabled without consent")
        defaults.set(true, forKey: CalendarNetworkConsent.photos); gate.refreshConsent()
        let ticket = gate.ticket(for: CalendarNetworkConsent.photos)!
        request.url = URL(string: "https://calendar-play-seven.vercel.app/api/unsplash")!
        request.httpBody = Data(repeating: 0, count: 65_537)
        let refused: Data? = await withCheckedContinuation { c in gate.data(for: request, ticket: ticket) { c.resume(returning: $0) } }
        require(refused == nil && APIProtocol.count() == 0, "oversized body cannot reach the actual native transport")
        let oversizedText = "a" + String(repeating: "\u{301}", count: 40_000)
        require(oversizedText.count == 1, "oversized fixture passes the user-facing character count")
        do { _ = try await EventDescriptionParser.parse(oversizedText, selectedDate: Date(), session: session); fatalError("oversized parser request escaped") } catch {}
        require(APIProtocol.count() == 0, "actual event parser rejects oversized encoded Unicode before transport")

        let origins = CommandLine.arguments.contains("--live") ? ["https://d2ntnk2ucb7yym.cloudfront.net", "https://calendar-play-seven.vercel.app", "https://calendar-play-api.vercel.app"] : ["offline"]
        for origin in origins {
            APIProtocol.origin = origin == "offline" ? nil : origin
            let parsed = try await EventDescriptionParser.parse("Synthetic verification meeting September 29 2026 at 10:00 UTC for one hour.", selectedDate: Date(timeIntervalSince1970: 1_790_596_800), session: session)
            require(parsed.title?.isEmpty == false, "actual event parser decodes validated response from \(origin)")
            var photoID = "synthetic"
            if origin != "offline" {
                let result: [UnsplashPhoto]? = await withCheckedContinuation { c in photos.searchPhotos(query: "forest", perPage: 1) { c.resume(returning: $0) } }
                require(result?.count == 1, "actual native photo search decodes provider response from \(origin)")
                photoID = result![0].id
            }
            let previous = APIProtocol.count()
            photos.trackDownload(for: photoID)
            let deadline = Date().addingTimeInterval(25)
            while APIProtocol.count() == previous && Date() < deadline { try await Task.sleep(for: .milliseconds(20)) }
            require(APIProtocol.count() == previous + 1 && APIProtocol.observations.last?["status"] as? Int == 200, "actual photo tracking POST succeeds at \(origin)")
        }
        if let path = ProcessInfo.processInfo.environment["CALENDAR_API_EVIDENCE"] {
            try JSONSerialization.data(withJSONObject: ["checkedAt":ISO8601DateFormatter().string(from: Date()), "requests":APIProtocol.observations], options: [.prettyPrinted,.sortedKeys]).write(to: URL(fileURLWithPath: path))
        }
        print("ALL API REQUEST CHECKS PASSED")
    }
}
