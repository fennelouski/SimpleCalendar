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
    private var pendingRequests: [String: [(CLLocationCoordinate2D) -> Void]] = [:]
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    private let geocodingMinInterval: TimeInterval = 1.0 // Minimum 1 second between requests
    private var lastGeocodingRequestTime: Date?
    
    private init() {}
    
    func getCoordinate(for location: String, completion: @escaping (CLLocationCoordinate2D) -> Void) {
        // Check cache first
        if let cached = cache[location],
           Date().timeIntervalSince(cached.date) < cacheDuration {
            completion(cached.coordinate)
            return
        }
        
        // Check if there's already a pending request for this location
        if var pendingCompletions = pendingRequests[location] {
            pendingCompletions.append(completion)
            pendingRequests[location] = pendingCompletions
            return
        }
        
        // Rate limiting: check if we've made a request too recently
        let now = Date()
        if let lastRequestTime = lastGeocodingRequestTime,
           now.timeIntervalSince(lastRequestTime) < geocodingMinInterval {
            // Too soon since last request - use cached value if available
            if let cached = cache[location] {
                completion(cached.coordinate)
            } else {
                // Return default coordinate to avoid throttling
                completion(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
            }
            return
        }
        
        // Mark this location as having a pending request
        pendingRequests[location] = [completion]
        lastGeocodingRequestTime = now
        
        // Use CLGeocoder instead of MKLocalSearch to avoid geocoding request throttling
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            let coordinate: CLLocationCoordinate2D
            if let placemark = placemarks?.first,
               let location = placemark.location {
                coordinate = location.coordinate
            } else {
                // Fallback to default
                coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            }
            
            // Cache the result
            self.cache[location] = (coordinate: coordinate, date: Date())
            
            // Call all pending completion handlers for this location
            if let pendingCompletions = self.pendingRequests[location] {
                for completionHandler in pendingCompletions {
                    completionHandler(coordinate)
                }
                // Clear the pending requests
                self.pendingRequests.removeValue(forKey: location)
            }
        }
    }
}

struct EventMapView: View {
    let location: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoading = true
    @State private var showFullMap = false
    @State private var lastGeocodedLocation: String? // Track which location we've geocoded

    var body: some View {
        ZStack {
            Map {
                Marker(location, coordinate: region.center)
                    .tint(.red)
            }
            .mapStyle(.standard)
                .cornerRadius(8)
                .onAppear {
                    if lastGeocodedLocation != location {
                        geocodeLocation()
                    }
                }
                .onChange(of: location) {
                    geocodeLocation()
                }
                #if os(iOS)
                .disabled(true) // Disable user interaction to prevent scrolling
                .contentShape(Rectangle()) // Make the whole area tappable
                .onTapGesture {
                    showFullMap = true
                }
                #else
                .onTapGesture {
                    showFullMap = true
                }
                #endif

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .frame(height: 100) // Match the specified height
        .sheet(isPresented: $showFullMap) {
            InteractiveMapView(location: location, region: region)
        }
    }

    private func geocodeLocation() {
        guard lastGeocodedLocation != location else { return }
        lastGeocodedLocation = location
        
        LocationGeocodingCache.shared.getCoordinate(for: location) { [self] coordinate in
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                self.isLoading = false
            }
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
