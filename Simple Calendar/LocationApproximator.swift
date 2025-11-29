//
//  LocationApproximator.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import CoreLocation

/// Approximates user location based on timezone and locale information
/// This is useful for tvOS where direct location access isn't available
class LocationApproximator {
    static let shared = LocationApproximator()
    
    // Cache for IP-based location
    private var cachedIPLocation: (coordinate: CLLocationCoordinate2D, timezone: String?, timestamp: Date)?
    private let ipLocationCacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    private var isFetchingIPLocation = false
    
    private init() {}
    
    /// Approximate location based on timezone and locale, refined with IP geolocation
    /// Returns a coordinate that represents a reasonable estimate for the user's location
    func approximateLocation() -> CLLocationCoordinate2D {
        // Get timezone-based location first
        let timezoneLocation = locationFromTimezone() ?? locationFromLocale() ?? CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        
        // Try to refine with IP geolocation if available
        if let cached = getCachedIPLocation() {
            // Validate timezone matches (still important for accuracy)
            if isTimezoneValid(cached.timezone) {
                let distance = calculateDistance(cached.coordinate, to: timezoneLocation)
                let maxDistance: Double = 1_000_000 // 1000 km in meters
                
                if distance <= maxDistance {
                    // IP location is close enough, use it directly
                    return cached.coordinate
                } else {
                    // IP location is too far, use midpoint between timezone and IP location
                    return calculateMidpoint(between: timezoneLocation, and: cached.coordinate)
                }
            }
        }
        
        // If IP location is not available or invalid, fetch it asynchronously for next time
        fetchIPLocationIfNeeded()
        
        return timezoneLocation
    }
    
    /// Get cached IP location if available and not expired
    private func getCachedIPLocation() -> (coordinate: CLLocationCoordinate2D, timezone: String?)? {
        guard let cached = cachedIPLocation,
              Date().timeIntervalSince(cached.timestamp) < ipLocationCacheDuration else {
            return nil
        }
        return (cached.coordinate, cached.timezone)
    }
    
    /// Fetch IP location asynchronously if needed
    private func fetchIPLocationIfNeeded() {
        // Don't fetch if already cached or currently fetching
        if cachedIPLocation != nil || isFetchingIPLocation {
            return
        }
        
        isFetchingIPLocation = true
        
        // Use ipapi.co - free, no API key required, good rate limits
        guard let url = URL(string: "https://ipapi.co/json/") else {
            isFetchingIPLocation = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                self?.isFetchingIPLocation = false
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let ipResponse = try decoder.decode(IPLocationResponse.self, from: data)
                
                // Only cache if we got valid coordinates
                if let latitude = ipResponse.latitude,
                   let longitude = ipResponse.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    DispatchQueue.main.async {
                        self.cachedIPLocation = (coordinate, ipResponse.timezone, Date())
                        self.isFetchingIPLocation = false
                    }
                } else {
                    self.isFetchingIPLocation = false
                }
            } catch {
                print("Error decoding IP location response: \(error)")
                self.isFetchingIPLocation = false
            }
        }.resume()
    }
    
    /// Validate that IP timezone matches device timezone
    /// This ensures we don't use an IP location from a completely different timezone
    private func isTimezoneValid(_ ipTimezone: String?) -> Bool {
        guard let ipTimezone = ipTimezone else {
            // If no timezone info, we'll still use it but with midpoint logic
            return true
        }
        
        let deviceTimezone = TimeZone.current.identifier
        // Check if timezones match (exact or similar)
        return timezonesMatch(ipTimezone, deviceTimezone)
    }
    
    /// Calculate the midpoint between two coordinates
    private func calculateMidpoint(between coord1: CLLocationCoordinate2D, and coord2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = coord1.latitude * .pi / 180.0
        let lon1 = coord1.longitude * .pi / 180.0
        let lat2 = coord2.latitude * .pi / 180.0
        let lon2 = coord2.longitude * .pi / 180.0
        
        // Convert to Cartesian coordinates
        let x1 = cos(lat1) * cos(lon1)
        let y1 = cos(lat1) * sin(lon1)
        let z1 = sin(lat1)
        
        let x2 = cos(lat2) * cos(lon2)
        let y2 = cos(lat2) * sin(lon2)
        let z2 = sin(lat2)
        
        // Calculate midpoint in Cartesian space
        let xMid = (x1 + x2) / 2.0
        let yMid = (y1 + y2) / 2.0
        let zMid = (z1 + z2) / 2.0
        
        // Convert back to spherical coordinates
        let lonMid = atan2(yMid, xMid)
        let hyp = sqrt(xMid * xMid + yMid * yMid)
        let latMid = atan2(zMid, hyp)
        
        return CLLocationCoordinate2D(
            latitude: latMid * 180.0 / .pi,
            longitude: lonMid * 180.0 / .pi
        )
    }
    
    /// Check if two timezone identifiers match (handles variations)
    private func timezonesMatch(_ tz1: String, _ tz2: String) -> Bool {
        // Exact match
        if tz1 == tz2 {
            return true
        }
        
        // Check if they're in the same region (e.g., both America/New_York variants)
        let tz1Components = tz1.split(separator: "/")
        let tz2Components = tz2.split(separator: "/")
        
        if tz1Components.count >= 2 && tz2Components.count >= 2 {
            // Same region (e.g., both "America")
            if tz1Components[0] == tz2Components[0] {
                // For US timezones, check if they're in the same timezone group
                let tz1City = String(tz1Components[1])
                let tz2City = String(tz2Components[1])
                
                // US Eastern Time variants
                if (tz1City.contains("New_York") || tz1City.contains("Detroit") || tz1City.contains("Indiana") || tz1City.contains("Kentucky")) &&
                   (tz2City.contains("New_York") || tz2City.contains("Detroit") || tz2City.contains("Indiana") || tz2City.contains("Kentucky")) {
                    return true
                }
                
                // US Central Time variants
                if (tz1City.contains("Chicago") || tz1City.contains("Menominee") || tz1City.contains("North_Dakota")) &&
                   (tz2City.contains("Chicago") || tz2City.contains("Menominee") || tz2City.contains("North_Dakota")) {
                    return true
                }
                
                // US Mountain Time variants
                if (tz1City.contains("Denver") || tz1City.contains("Boise") || tz1City.contains("Shiprock")) &&
                   (tz2City.contains("Denver") || tz2City.contains("Boise") || tz2City.contains("Shiprock")) {
                    return true
                }
                
                // US Pacific Time variants
                if (tz1City.contains("Los_Angeles") || tz1City.contains("Juneau") || tz1City.contains("Metlakatla") || tz1City.contains("Nome") || tz1City.contains("Sitka") || tz1City.contains("Yakutat")) &&
                   (tz2City.contains("Los_Angeles") || tz2City.contains("Juneau") || tz2City.contains("Metlakatla") || tz2City.contains("Nome") || tz2City.contains("Sitka") || tz2City.contains("Yakutat")) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Calculate distance between two coordinates in meters (Haversine formula)
    private func calculateDistance(_ from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Get approximate location from timezone identifier
    private func locationFromTimezone() -> CLLocationCoordinate2D? {
        let timezone = TimeZone.current
        let identifier = timezone.identifier
        
        // Map timezone identifiers to regional centers (calculated from major cities in each timezone)
        // These represent geographic centers of timezone regions for better accuracy
        let timezoneLocations: [String: CLLocationCoordinate2D] = [
            // US Eastern Time (EST/EDT) - Regional center of major cities
            "America/New_York": CLLocationCoordinate2D(latitude: 39.8283, longitude: -80.5795), // Regional center (NYC, Boston, Miami, Atlanta, DC)
            "America/Detroit": CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458), // Detroit
            "America/Indiana/Indianapolis": CLLocationCoordinate2D(latitude: 39.7684, longitude: -86.1581), // Indianapolis
            "America/Indiana/Vevay": CLLocationCoordinate2D(latitude: 38.7470, longitude: -85.0672), // Vevay, IN
            "America/Indiana/Vincennes": CLLocationCoordinate2D(latitude: 38.6773, longitude: -87.5286), // Vincennes, IN
            "America/Indiana/Winamac": CLLocationCoordinate2D(latitude: 41.0514, longitude: -86.6031), // Winamac, IN
            "America/Kentucky/Louisville": CLLocationCoordinate2D(latitude: 38.2527, longitude: -85.7585), // Louisville
            "America/Kentucky/Monticello": CLLocationCoordinate2D(latitude: 36.8297, longitude: -84.8491), // Monticello, KY
            
            // US Central Time (CST/CDT) - Regional center
            "America/Chicago": CLLocationCoordinate2D(latitude: 36.1627, longitude: -95.9903), // Regional center (Chicago, Dallas, Houston, Minneapolis, St. Louis)
            "America/Indiana/Knox": CLLocationCoordinate2D(latitude: 41.2959, longitude: -86.6250), // Knox, IN
            "America/Indiana/Marengo": CLLocationCoordinate2D(latitude: 38.3695, longitude: -86.3444), // Marengo, IN
            "America/Indiana/Petersburg": CLLocationCoordinate2D(latitude: 38.4919, longitude: -87.2786), // Petersburg, IN
            "America/Indiana/Tell_City": CLLocationCoordinate2D(latitude: 37.9531, longitude: -86.7678), // Tell City, IN
            "America/Menominee": CLLocationCoordinate2D(latitude: 45.1078, longitude: -87.6143), // Menominee, MI
            "America/North_Dakota/Center": CLLocationCoordinate2D(latitude: 47.1164, longitude: -101.2997), // Center, ND
            "America/North_Dakota/New_Salem": CLLocationCoordinate2D(latitude: 46.8442, longitude: -101.4118), // New Salem, ND
            "America/North_Dakota/Beulah": CLLocationCoordinate2D(latitude: 47.2633, longitude: -101.7779), // Beulah, ND
            
            // US Mountain Time (MST/MDT) - Regional center
            "America/Denver": CLLocationCoordinate2D(latitude: 38.9979, longitude: -105.5506), // Regional center (Denver, Salt Lake City, Albuquerque)
            "America/Boise": CLLocationCoordinate2D(latitude: 43.6150, longitude: -116.2023), // Boise
            "America/Shiprock": CLLocationCoordinate2D(latitude: 36.7856, longitude: -108.6870), // Shiprock, NM
            
            // US Pacific Time (PST/PDT) - Regional center
            "America/Los_Angeles": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Regional center (LA, SF, Seattle, Portland)
            "America/Juneau": CLLocationCoordinate2D(latitude: 58.3019, longitude: -134.4197), // Juneau, AK
            "America/Metlakatla": CLLocationCoordinate2D(latitude: 55.1292, longitude: -131.5761), // Metlakatla, AK
            "America/Nome": CLLocationCoordinate2D(latitude: 64.5011, longitude: -165.4064), // Nome, AK
            "America/Sitka": CLLocationCoordinate2D(latitude: 57.0531, longitude: -135.3300), // Sitka, AK
            "America/Yakutat": CLLocationCoordinate2D(latitude: 59.5469, longitude: -139.7272), // Yakutat, AK
            
            // US Arizona (MST, no DST)
            "America/Phoenix": CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740), // Phoenix
            
            // US Alaska Time
            "America/Anchorage": CLLocationCoordinate2D(latitude: 61.2181, longitude: -149.9003), // Anchorage
            
            // US Hawaii
            "Pacific/Honolulu": CLLocationCoordinate2D(latitude: 21.3099, longitude: -157.8581), // Honolulu
            
            // Canadian Timezones - Regional centers
            "America/Toronto": CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), // Regional center (Toronto, Montreal, Ottawa)
            "America/Vancouver": CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Vancouver
            "America/Winnipeg": CLLocationCoordinate2D(latitude: 49.8951, longitude: -97.1384), // Winnipeg
            "America/Edmonton": CLLocationCoordinate2D(latitude: 53.5461, longitude: -113.4938), // Edmonton
            "America/Regina": CLLocationCoordinate2D(latitude: 50.4452, longitude: -104.6189), // Regina
            "America/Halifax": CLLocationCoordinate2D(latitude: 44.6488, longitude: -63.5752), // Halifax
            "America/St_Johns": CLLocationCoordinate2D(latitude: 47.5615, longitude: -52.7126), // St. John's
            "America/Whitehorse": CLLocationCoordinate2D(latitude: 60.7212, longitude: -135.0568), // Whitehorse
            "America/Yellowknife": CLLocationCoordinate2D(latitude: 62.4540, longitude: -114.3718), // Yellowknife
            "America/Dawson": CLLocationCoordinate2D(latitude: 64.0601, longitude: -139.4330), // Dawson
            "America/Inuvik": CLLocationCoordinate2D(latitude: 68.3617, longitude: -133.7307), // Inuvik
            "America/Moncton": CLLocationCoordinate2D(latitude: 46.0878, longitude: -64.7782), // Moncton
            "America/Glace_Bay": CLLocationCoordinate2D(latitude: 46.1969, longitude: -59.9570), // Glace Bay
            "America/Goose_Bay": CLLocationCoordinate2D(latitude: 53.3192, longitude: -60.4258), // Goose Bay
            "America/Blanc-Sablon": CLLocationCoordinate2D(latitude: 51.4264, longitude: -57.1314), // Blanc-Sablon
            "America/Montreal": CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), // Montreal
            "America/Cambridge_Bay": CLLocationCoordinate2D(latitude: 69.1170, longitude: -105.0598), // Cambridge Bay
            "America/Rankin_Inlet": CLLocationCoordinate2D(latitude: 62.8084, longitude: -92.0853), // Rankin Inlet
            "America/Resolute": CLLocationCoordinate2D(latitude: 74.6969, longitude: -94.8294), // Resolute
            
            // European Timezones - Regional centers
            "Europe/London": CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            "Europe/Dublin": CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603), // Dublin
            "Europe/Paris": CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), // Paris
            "Europe/Berlin": CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515), // Regional center (Berlin, Munich, Hamburg)
            "Europe/Rome": CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), // Rome
            "Europe/Madrid": CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038), // Madrid
            "Europe/Amsterdam": CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), // Amsterdam
            "Europe/Brussels": CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517), // Brussels
            "Europe/Vienna": CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738), // Vienna
            "Europe/Zurich": CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417), // Zurich
            "Europe/Stockholm": CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686), // Stockholm
            "Europe/Oslo": CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522), // Oslo
            "Europe/Copenhagen": CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683), // Copenhagen
            "Europe/Helsinki": CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384), // Helsinki
            "Europe/Warsaw": CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122), // Warsaw
            "Europe/Prague": CLLocationCoordinate2D(latitude: 50.0755, longitude: 14.4378), // Prague
            "Europe/Budapest": CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402), // Budapest
            "Europe/Bucharest": CLLocationCoordinate2D(latitude: 44.4268, longitude: 26.1025), // Bucharest
            "Europe/Athens": CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275), // Athens
            "Europe/Lisbon": CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393), // Lisbon
            "Europe/Moscow": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173), // Moscow
            "Europe/Kiev": CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234), // Kiev
            "Europe/Istanbul": CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // Istanbul
            
            // Asian Timezones - Regional centers
            "Asia/Tokyo": CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo
            "Asia/Shanghai": CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), // Shanghai
            "Asia/Beijing": CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // Beijing
            "Asia/Hong_Kong": CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694), // Hong Kong
            "Asia/Singapore": CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198), // Singapore
            "Asia/Dubai": CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708), // Dubai
            "Asia/Mumbai": CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777), // Mumbai
            "Asia/Delhi": CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), // Delhi
            "Asia/Kolkata": CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639), // Kolkata
            "Asia/Bangalore": CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946), // Bangalore
            "Asia/Seoul": CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // Seoul
            "Asia/Bangkok": CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018), // Bangkok
            "Asia/Jakarta": CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456), // Jakarta
            "Asia/Manila": CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842), // Manila
            "Asia/Kuala_Lumpur": CLLocationCoordinate2D(latitude: 3.1390, longitude: 101.6869), // Kuala Lumpur
            "Asia/Taipei": CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // Taipei
            "Asia/Jerusalem": CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137), // Jerusalem
            "Asia/Riyadh": CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753), // Riyadh
            "Asia/Tehran": CLLocationCoordinate2D(latitude: 35.6892, longitude: 51.3890), // Tehran
            
            // Australian Timezones
            "Australia/Sydney": CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney
            "Australia/Melbourne": CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631), // Melbourne
            "Australia/Brisbane": CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251), // Brisbane
            "Australia/Perth": CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605), // Perth
            "Australia/Adelaide": CLLocationCoordinate2D(latitude: -34.9285, longitude: 138.6007), // Adelaide
            "Australia/Darwin": CLLocationCoordinate2D(latitude: -12.4634, longitude: 130.8456), // Darwin
            "Australia/Hobart": CLLocationCoordinate2D(latitude: -42.8821, longitude: 147.3272), // Hobart
            
            // South American Timezones
            "America/Sao_Paulo": CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333), // São Paulo
            "America/Buenos_Aires": CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816), // Buenos Aires
            "America/Mexico_City": CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332), // Mexico City
            "America/Lima": CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428), // Lima
            "America/Bogota": CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721), // Bogota
            "America/Santiago": CLLocationCoordinate2D(latitude: -33.4489, longitude: -70.6693), // Santiago
            "America/Caracas": CLLocationCoordinate2D(latitude: 10.4806, longitude: -66.9036), // Caracas
            
            // African Timezones
            "Africa/Cairo": CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357), // Cairo
            "Africa/Johannesburg": CLLocationCoordinate2D(latitude: -26.2041, longitude: 28.0473), // Johannesburg
            "Africa/Lagos": CLLocationCoordinate2D(latitude: 6.5244, longitude: 3.3792), // Lagos
            "Africa/Nairobi": CLLocationCoordinate2D(latitude: -1.2921, longitude: 36.8219), // Nairobi
            "Africa/Casablanca": CLLocationCoordinate2D(latitude: 33.5731, longitude: -7.5898), // Casablanca
            
            // New Zealand
            "Pacific/Auckland": CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633), // Auckland
            "Pacific/Chatham": CLLocationCoordinate2D(latitude: -43.9544, longitude: -176.9147), // Chatham Islands
        ]
        
        // Check exact match first
        if let location = timezoneLocations[identifier] {
            return location
        }
        
        // Check for timezone aliases and common variations
        let normalizedIdentifier = identifier.lowercased()
        for (tzId, location) in timezoneLocations {
            let normalizedTzId = tzId.lowercased()
            if normalizedIdentifier == normalizedTzId {
                return location
            }
        }
        
        // Try to match by region prefix (e.g., "America/New_York" -> check for "America/" matches)
        let components = identifier.split(separator: "/")
        if components.count >= 2 {
            let region = String(components[0])
            let city = String(components[1])
            
            // For US timezones, try to match by region and find regional center
            if region == "America" {
                // Try to match by city name in identifier
                for (tzId, location) in timezoneLocations {
                    if tzId.contains(city) || city.contains(tzId.split(separator: "/").last ?? "") {
                        return location
                    }
                }
                
                // If no city match, try to determine timezone offset and use regional center
                // This is a fallback for unknown US timezones
                let offset = timezone.secondsFromGMT()
                let hoursOffset = offset / 3600
                switch hoursOffset {
                case -5, -4: // Eastern Time (EST/EDT)
                    return timezoneLocations["America/New_York"]
                case -6, -5: // Central Time (CST/CDT)
                    return timezoneLocations["America/Chicago"]
                case -7, -6: // Mountain Time (MST/MDT)
                    return timezoneLocations["America/Denver"]
                case -8, -7: // Pacific Time (PST/PDT)
                    return timezoneLocations["America/Los_Angeles"]
                case -9, -8: // Alaska Time (AKST/AKDT)
                    return timezoneLocations["America/Anchorage"]
                case -10: // Hawaii Time (HST)
                    return timezoneLocations["Pacific/Honolulu"]
                default:
                    break
                }
            }
            
            // For other regions, try to find any match in that region
            for (tzId, location) in timezoneLocations {
                if tzId.hasPrefix(region + "/") {
                    return location
                }
            }
        }
        
        // Final fallback: try partial string matching
        for (tzId, location) in timezoneLocations {
            if identifier.contains(tzId.split(separator: "/").last ?? "") ||
               tzId.contains(identifier.split(separator: "/").last ?? "") {
                return location
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

// MARK: - IP Geolocation Response Model
private struct IPLocationResponse: Codable {
    let latitude: Double?
    let longitude: Double?
    let city: String?
    let region: String?
    let country: String?
    let timezone: String?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case city
        case region
        case country
        case timezone
    }
}


