import Foundation
import CryptoKit

/// Hash exactly the buffered bytes sent to our API for CloudFront origin access control.
nonisolated enum CalendarAPIRequest {
    static let maximumBodyBytes = 65_536
    private static let hosts = ["calendar-play-seven.vercel.app", "calendar-play-api.vercel.app", "d2ntnk2ucb7yym.cloudfront.net"]

    static func prepared(_ request: URLRequest) throws -> URLRequest {
        guard let url = request.url, hosts.contains(url.host?.lowercased() ?? ""), url.path.hasPrefix("/api/") else { return request }
        guard url.scheme == "https", request.httpBodyStream == nil else { throw URLError(.requestBodyStreamExhausted) }
        let needsBody = ["POST", "PUT", "PATCH"].contains(request.httpMethod?.uppercased() ?? "GET")
        guard let body = request.httpBody else {
            if needsBody { throw URLError(.requestBodyStreamExhausted) }
            return request
        }
        guard body.count <= maximumBodyBytes else { throw URLError(.dataLengthExceedsMaximum) }
        var prepared = request
        prepared.setValue(SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined(), forHTTPHeaderField: "x-amz-content-sha256")
        return prepared
    }
}
