//
//  EventMapView.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import MapKit

struct EventMapView: View {
    let location: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .cornerRadius(8)
                .onAppear {
                    geocodeLocation()
                }

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .frame(height: 200)
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
