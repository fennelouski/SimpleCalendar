//
//  RequestQueueManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation

class RequestQueueManager {
    static let shared = RequestQueueManager()

    // Rate limiting constraints
    private let minIntervalBetweenRequests: TimeInterval = 5.0 // 5 seconds minimum between requests
    private let maxRequestsPerMinute = 3
    private let minuteWindow: TimeInterval = 60.0 // 1 minute

    // Queue management
    private var requestQueue: [(id: String, operation: () -> Void)] = []
    private var isProcessing = false
    private var requestTimestamps: [Date] = []
    private var lastRequestTime: Date?

    private let queue = DispatchQueue(label: "com.simplecalendar.requestqueue", qos: .background)
    private let semaphore = DispatchSemaphore(value: 1)

    private init() {}

    // MARK: - Public Methods

    func enqueueRequest(id: String, operation: @escaping () -> Void) {
        queue.async {
            self.semaphore.wait()

            // Check if we already have this request queued
            if self.requestQueue.contains(where: { $0.id == id }) {
                print("⚠️ Request already queued: \(id)")
                self.semaphore.signal()
                return
            }

            // Add to queue
            self.requestQueue.append((id: id, operation: operation))
            print("📋 Queued request: \(id) (queue length: \(self.requestQueue.count))")

            // Start processing if not already processing
            if !self.isProcessing {
                self.processQueue()
            }

            self.semaphore.signal()
        }
    }

    func cancelRequest(id: String) {
        queue.async {
            self.semaphore.wait()
            self.requestQueue.removeAll { $0.id == id }
            self.semaphore.signal()
        }
    }

    func getQueueLength() -> Int {
        return requestQueue.count
    }

    // MARK: - Private Methods

    private func processQueue() {
        guard !isProcessing else { return }

        isProcessing = true

        queue.async {
            while true {
                self.semaphore.wait()

                // Check if queue is empty
                if self.requestQueue.isEmpty {
                    self.isProcessing = false
                    self.semaphore.signal()
                    break
                }

                // Check if we can make a request
                guard self.canMakeRequest() else {
                    print("⏱️ Rate limiting active, waiting...")
                    self.semaphore.signal()
                    // Wait before checking again
                    Thread.sleep(forTimeInterval: 1.0)
                    continue
                }

                // Get next request
                let request = self.requestQueue.removeFirst()
                self.recordRequest()

                self.semaphore.signal()

                // Execute the request
                print("🚀 Executing request: \(request.id)")
                request.operation()

                // Wait minimum interval before processing next request
                print("⏳ Waiting \(self.minIntervalBetweenRequests)s before next request")
                Thread.sleep(forTimeInterval: self.minIntervalBetweenRequests)
            }
        }
    }

    private func canMakeRequest() -> Bool {
        let now = Date()

        // Check minimum interval between requests
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = now.timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minIntervalBetweenRequests {
                return false
            }
        }

        // Check requests per minute limit
        let recentRequests = requestTimestamps.filter { now.timeIntervalSince($0) < minuteWindow }
        return recentRequests.count < maxRequestsPerMinute
    }

    private func recordRequest() {
        let now = Date()
        lastRequestTime = now
        requestTimestamps.append(now)

        // Clean up old timestamps (older than 1 minute)
        let cutoffDate = now.addingTimeInterval(-minuteWindow)
        requestTimestamps = requestTimestamps.filter { $0 > cutoffDate }
    }

    // MARK: - Debug Info

    func getDebugInfo() -> String {
        let now = Date()
        let recentRequests = requestTimestamps.filter { now.timeIntervalSince($0) < minuteWindow }

        var info = """
        Queue Status:
        - Queue length: \(requestQueue.count)
        - Processing: \(isProcessing)
        - Recent requests (last minute): \(recentRequests.count)/\(maxRequestsPerMinute)
        - Last request: \(lastRequestTime?.description ?? "None")
        """

        if let lastRequest = lastRequestTime {
            let timeSinceLast = now.timeIntervalSince(lastRequest)
            info += "\n- Time since last request: \(String(format: "%.1f", timeSinceLast))s"
            if timeSinceLast < minIntervalBetweenRequests {
                info += " (waiting \(String(format: "%.1f", minIntervalBetweenRequests - timeSinceLast))s)"
            }
        }

        return info
    }
}
