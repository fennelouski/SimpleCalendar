//
//  EventMapView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import MapKit
#if os(iOS)
import UIKit
#endif

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct EventMapView: View {
    let location: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoading = true
    @State private var showFullMap = false

    var body: some View {
        ZStack {
            Map(coordinateRegion: .constant(region), showsUserLocation: false, annotationItems: [MapLocation(coordinate: region.center, title: location)]) { location in
                MapPin(coordinate: location.coordinate, tint: .red)
            }
                .cornerRadius(8)
                .onAppear {
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
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
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
                        Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: region.center, title: location)]) { location in
                            MapPin(coordinate: location.coordinate, tint: .red)
                        }
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
                        .foregroundColor(.gray)
                }
            }
            .padding()

            Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: region.center, title: location)]) { location in
                MapPin(coordinate: location.coordinate, tint: .red)
            }
            .frame(minHeight: 400)
        }
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }
}
