//
//  HolidayRegion.swift
//  Simple Calendar
//
//  A country or region that observes holidays, identified by its ISO 3166-1
//  alpha-2 code (the same codes `Locale.Region` uses).
//

import Foundation

struct HolidayRegion: Hashable, Codable, Identifiable, Comparable {
    /// Uppercased ISO 3166-1 alpha-2 code, e.g. "US", "CA", "GB".
    let code: String

    init(_ code: String) {
        self.code = code.uppercased()
    }

    var id: String { code }

    /// Name in the user's language, e.g. "United States" / "Estados Unidos".
    var displayName: String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    /// Flag emoji built from the region code's regional-indicator symbols.
    var flag: String {
        let base: UInt32 = 0x1F1E6 - 0x41 // regional indicator "A" minus ASCII "A"
        let scalars = code.unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }
        guard scalars.count == 2 else { return "" }
        var flag = ""
        flag.unicodeScalars.append(contentsOf: scalars)
        return flag
    }

    /// The device's region from the user's locale settings, or nil if the locale has none.
    static var device: HolidayRegion? {
        guard let identifier = Locale.current.region?.identifier, identifier.count == 2 else { return nil }
        return HolidayRegion(identifier)
    }

    static func < (lhs: HolidayRegion, rhs: HolidayRegion) -> Bool {
        lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }

    // Regions that currently have a regional calendar.
    static let unitedStates = HolidayRegion("US")
    static let canada = HolidayRegion("CA")
    static let mexico = HolidayRegion("MX")
    static let unitedKingdom = HolidayRegion("GB")
    static let ireland = HolidayRegion("IE")
    static let france = HolidayRegion("FR")
    static let germany = HolidayRegion("DE")
    static let sweden = HolidayRegion("SE")
    static let finland = HolidayRegion("FI")
    static let czechia = HolidayRegion("CZ")
    static let australia = HolidayRegion("AU")
    static let newZealand = HolidayRegion("NZ")
}
