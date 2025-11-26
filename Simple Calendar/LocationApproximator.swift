//
//  LocationApproximator.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation

/// Approximates user location based on timezone and locale information
/// This is useful for tvOS where direct location access isn't available
class LocationApproximator {
    static let shared = LocationApproximator()
    
    private init() {}
    
    /// Approximate location based on timezone and locale
    /// Returns a coordinate that represents a reasonable estimate for the user's location
    func approximateLocation() -> CLLocationCoordinate2D {
        // First, try to get location from timezone
        if let timezoneLocation = locationFromTimezone() {
            return timezoneLocation
        }
        
        // Fallback to locale-based approximation
        if let localeLocation = locationFromLocale() {
            return localeLocation
        }
        
        // Ultimate fallback: center of the US (most common timezone)
        return CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
    }
    
    /// Get approximate location from timezone identifier
    private func locationFromTimezone() -> CLLocationCoordinate2D? {
        let timezone = TimeZone.current
        let identifier = timezone.identifier
        
        // Map common timezone identifiers to approximate coordinates
        // These are typically the largest city or geographic center of the timezone
        let timezoneLocations: [String: CLLocationCoordinate2D] = [
            // US Timezones
            "America/New_York": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York
            "America/Chicago": CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298), // Chicago
            "America/Denver": CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903), // Denver
            "America/Los_Angeles": CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
            "America/Phoenix": CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740), // Phoenix
            "America/Anchorage": CLLocationCoordinate2D(latitude: 61.2181, longitude: -149.9003), // Anchorage
            "Pacific/Honolulu": CLLocationCoordinate2D(latitude: 21.3099, longitude: -157.8581), // Honolulu
            
            // European Timezones
            "Europe/London": CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            "Europe/Paris": CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), // Paris
            "Europe/Berlin": CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Berlin
            "Europe/Rome": CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), // Rome
            "Europe/Madrid": CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038), // Madrid
            "Europe/Amsterdam": CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), // Amsterdam
            "Europe/Stockholm": CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686), // Stockholm
            "Europe/Moscow": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173), // Moscow
            
            // Asian Timezones
            "Asia/Tokyo": CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo
            "Asia/Shanghai": CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), // Shanghai
            "Asia/Hong_Kong": CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694), // Hong Kong
            "Asia/Singapore": CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198), // Singapore
            "Asia/Dubai": CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708), // Dubai
            "Asia/Mumbai": CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777), // Mumbai
            "Asia/Seoul": CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // Seoul
            
            // Australian Timezones
            "Australia/Sydney": CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney
            "Australia/Melbourne": CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631), // Melbourne
            "Australia/Brisbane": CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251), // Brisbane
            "Australia/Perth": CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605), // Perth
            
            // Canadian Timezones
            "America/Toronto": CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), // Toronto
            "America/Vancouver": CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Vancouver
            
            // South American Timezones
            "America/Sao_Paulo": CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333), // São Paulo
            "America/Buenos_Aires": CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Buenos Aires
            "America/Mexico_City": CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332), // Mexico City
        ]
        
        // Check exact match first
        if let location = timezoneLocations[identifier] {
            return location
        }
        
        // Check for partial matches (e.g., "America/New_York" matches "America/")
        for (tzId, location) in timezoneLocations {
            if identifier.contains(tzId) || tzId.contains(identifier) {
                return location
            }
        }
        
        // Try to extract region from timezone identifier
        let components = identifier.split(separator: "/")
        if components.count >= 2 {
            let region = String(components[0])
            let city = String(components[1])
            
            // Try to find a match based on region
            for (tzId, location) in timezoneLocations {
                if tzId.contains(region) {
                    return location
                }
            }
        }
        
        return nil
    }
    
    /// Get approximate location from locale identifier
    private func locationFromLocale() -> CLLocationCoordinate2D? {
        let locale = Locale.current
        let identifier = locale.identifier
        
        // Map locale identifiers to approximate coordinates
        // These represent the geographic center of countries
        let localeLocations: [String: CLLocationCoordinate2D] = [
            "en_US": CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // USA center
            "en_GB": CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            "en_CA": CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468), // Canada center
            "en_AU": CLLocationCoordinate2D(latitude: -25.2744, longitude: 133.7751), // Australia center
            "fr_FR": CLLocationCoordinate2D(latitude: 46.6034, longitude: 1.8883), // France center
            "de_DE": CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515), // Germany center
            "es_ES": CLLocationCoordinate2D(latitude: 40.4637, longitude: -3.7492), // Spain center
            "it_IT": CLLocationCoordinate2D(latitude: 41.8719, longitude: 12.5674), // Italy center
            "ja_JP": CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529), // Japan center
            "zh_CN": CLLocationCoordinate2D(latitude: 35.8617, longitude: 104.1954), // China center
            "ko_KR": CLLocationCoordinate2D(latitude: 35.9078, longitude: 127.7669), // South Korea center
            "pt_BR": CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253), // Brazil center
            "ru_RU": CLLocationCoordinate2D(latitude: 61.5240, longitude: 105.3188), // Russia center
            "es_MX": CLLocationCoordinate2D(latitude: 23.6345, longitude: -102.5528), // Mexico center
        ]
        
        // Check exact match
        if let location = localeLocations[identifier] {
            return location
        }
        
        // Check for language code match (e.g., "en" in "en_US")
        let languageCode = locale.languageCode ?? ""
        for (localeId, location) in localeLocations {
            if localeId.hasPrefix(languageCode + "_") {
                return location
            }
        }
        
        return nil
    }
}

