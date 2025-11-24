//
//  EventMapView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import MapKit

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
            FullMapView(location: location, region: region)
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

struct FullMapView: View {
    let location: String
    let region: MKCoordinateRegion
    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if os(iOS)
        // iOS: Full screen modal with map at top and address at bottom
        VStack(spacing: 0) {
            ZStack {
                Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: region.center, title: location)]) { location in
                    MapPin(coordinate: location.coordinate, tint: .red)
                }
                .frame(height: UIScreen.main.bounds.height * 0.7)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }

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
        .edgesIgnoringSafeArea(.top)
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
