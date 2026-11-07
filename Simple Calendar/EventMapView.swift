//
//  EventMapView.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import MapKit
import CoreLocation
#if os(iOS)
import UIKit
#endif

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

// Shared cache for location geocoding to prevent duplicate requests
class LocationGeocodingCache {
    static let shared = LocationGeocodingCache()
    private var cache: [String: (coordinate: CLLocationCoordinate2D, date: Date)] = [:]
    private var pendingRequests: [String: [(CLLocationCoordinate2D?) -> Void]] = [:]
    private var searches: [String: MKLocalSearch] = [:]
    private var lastRequest: Date?
    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, !CalendarNetworkConsent.allows(CalendarNetworkConsent.weather) else { return }
            self.searches.values.forEach { $0.cancel() }
            self.cache.removeAll()
        }
    }

    func getCoordinate(for location: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard let ticket = CalendarNetworkRequests.shared.ticket(for: CalendarNetworkConsent.weather) else { completion(nil); return }
        cache = cache.filter { Date().timeIntervalSince($0.value.date) < 24 * 60 * 60 }
        if let cached = cache[location] { completion(cached.coordinate); return }
        if pendingRequests[location] != nil { pendingRequests[location]?.append(completion); return }
        guard lastRequest.map({ Date().timeIntervalSince($0) >= 1 }) ?? true else { completion(nil); return }
        pendingRequests[location] = [completion]
        lastRequest = Date()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = location
        let search = MKLocalSearch(request: request)
        searches[location] = search
        search.start { [weak self] response, error in
            guard let self else { return }
            let coordinate = error == nil && CalendarNetworkRequests.shared.isValid(ticket) ? response?.mapItems.first?.location.coordinate : nil
            if let coordinate {
                if self.cache.count >= 200, let oldest = self.cache.min(by: { $0.value.date < $1.value.date })?.key { self.cache.removeValue(forKey: oldest) }
                self.cache[location] = (coordinate, Date())
            }
            let callbacks = self.pendingRequests.removeValue(forKey: location) ?? []
            self.searches.removeValue(forKey: location)
            callbacks.forEach { $0(coordinate) }
        }
    }
}

struct EventMapView: View {
    let location: String
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage(CalendarNetworkConsent.weather) private var allowsMaps = false
    @State private var region: MKCoordinateRegion?
    @State private var isLoading = false
    @State private var showFullMap = false
    @State private var lookupGeneration = UUID()

    var body: some View {
        Group {
            if !allowsMaps {
                Text("Enable Online maps in Settings to look up this location with Apple.").font(.caption)
            } else if let region {
                Map {
                    Marker(location, coordinate: region.center).tint(.red)
                }
                .mapStyle(.standard)
                .cornerRadius(8)
                .contentShape(Rectangle())
                .onTapGesture { showFullMap = true }
            } else if isLoading {
                ProgressView()
            } else {
                Text("Location unavailable").font(.caption)
            }
        }
        .frame(height: 100)
        .onAppear { geocodeLocation() }
        .onChange(of: location) { geocodeLocation() }
        .onChange(of: allowsMaps) {
            if !allowsMaps { region = nil; showFullMap = false }
            geocodeLocation()
        }
        .sheet(isPresented: $showFullMap) {
            if allowsMaps, let region { InteractiveMapView(location: location, region: region) }
        }
    }

    private func geocodeLocation() {
        let generation = UUID()
        lookupGeneration = generation
        region = nil
        guard allowsMaps else { isLoading = false; return }
        isLoading = true
        LocationGeocodingCache.shared.getCoordinate(for: location) { coordinate in
            guard lookupGeneration == generation, allowsMaps else { return }
            region = coordinate.map { MKCoordinateRegion(center: $0, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) }
            isLoading = false
        }
    }
}

struct InteractiveMapView: View {
    let location: String
    let region: MKCoordinateRegion
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var mapHeight: CGFloat = 0
    @State private var isFullScreen = false
    @State private var dragOffset: CGFloat = 0

    #if os(iOS)
    private let halfScreenHeight = UIScreen.main.bounds.height * 0.5
    #else
    private let halfScreenHeight: CGFloat = 400 // Default height for macOS
    #endif
    private let fullScreenThreshold: CGFloat = 100

    var body: some View {
        #if os(iOS)
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Map view
                    ZStack {
                        Map {
                            Marker(location, coordinate: region.center)
                                .tint(.red)
                        }
                        .mapStyle(.standard)
                        .frame(height: mapHeight + dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation.height
                                    if !isFullScreen && translation < 0 {
                                        // Pulling up from half screen
                                        dragOffset = translation
                                    } else if isFullScreen && translation > 0 && value.startLocation.y < 100 {
                                        // Pulling down from top edge in full screen
                                        dragOffset = translation
                                    }
                                }
                                .onEnded { value in
                                    let translation = value.translation.height
                                    _ = value.predictedEndTranslation.height

                                    withAnimation(.spring()) {
                                        if !isFullScreen && dragOffset < -fullScreenThreshold {
                                            // Pulled up enough - go to full screen
                                            isFullScreen = true
                                            mapHeight = geometry.size.height
                                            dragOffset = 0
                                        } else if isFullScreen && dragOffset > fullScreenThreshold {
                                            // Pulled down enough - go back to half screen
                                            isFullScreen = false
                                            mapHeight = halfScreenHeight
                                            dragOffset = 0
                                        } else if isFullScreen && dragOffset > 150 {
                                            // Pulled down far enough - dismiss
                                            dismiss()
                                        } else {
                                            // Return to current state
                                            dragOffset = 0
                                            mapHeight = isFullScreen ? geometry.size.height : halfScreenHeight
                                        }
                                    }
                                }
                        )

                        // Handle indicator
                        VStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 6)
                                .padding(.top, 8)
                            Spacer()
                        }
                    }

                    // Address details
                    VStack(spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        Text(location)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                .onAppear {
                    mapHeight = halfScreenHeight
                }
            }
        }
        #else
        // macOS: Popup window
        VStack(spacing: 0) {
            HStack {
                Text("Location: \(location)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(themeManager.currentPalette.textSecondary)
                }
                .accessibilityLabel("Close")
            }
            .padding()

            Map {
                Marker(location, coordinate: region.center)
                    .tint(.red)
            }
            .mapStyle(.standard)
            .frame(minHeight: 400)
        }
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }
}
