//
//  HolidayCatalogTests.swift
//  Simple CalendarTests
//
//  Guards the regional-calendar restructure: the master holiday list is
//  unchanged, every holiday belongs to a calendar, and each region sees the
//  expected set.
//

import Testing
import Foundation
@testable import Simple_Calendar

@MainActor
struct HolidayCatalogTests {

    /// The four holidays the US no longer shows by default: they belong to other regions.
    private let nonUSRegionalNames: Set<String> = ["Canada Day", "Bastille Day", "Boxing Day", "Walpurgis Night"]

    private var allNames: Set<String> {
        Set(HolidayCatalog.definitions.map(\.name))
    }

    // MARK: - Master list

    @Test func definitionsKeepThePreviousListAndOrder() {
        let definitions = HolidayCatalog.definitions
        #expect(definitions.count == 216, "Regional calendars must not add or drop holidays yet")
        #expect(definitions.first?.name == "New Year's Day")
        #expect(definitions.last?.name == "Blue Moon")
        #expect(definitions.map(\.id) == HolidayCatalog.displayOrder.map(\.id),
                "Display priority order must be unchanged (tvOS shows the first two per day)")
    }

    @Test func definitionsHaveNoDuplicateEntries() {
        let ids = HolidayCatalog.definitions.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Calendars

    @Test func everyHolidayBelongsToACalendar() {
        let inCalendars = HolidayCatalog.calendars.reduce(into: Set<String>()) { $0.formUnion($1.holidayNames) }
        let orphans = allNames.subtracting(inCalendars)
        #expect(orphans.isEmpty, "Holidays in no calendar would never be shown: \(orphans.sorted())")
    }

    @Test func calendarsAreUniqueWithOneWorldwide() {
        let ids = HolidayCatalog.calendars.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(HolidayCatalog.calendars.filter { $0.region == nil }.count == 1)
        let regions = HolidayCatalog.regionalCalendars.compactMap(\.region)
        #expect(Set(regions).count == regions.count, "One calendar per region")
    }

    @Test func worldwideAndRegionalCalendarsDoNotOverlap() {
        let worldwide = HolidayCalendar.worldwide.holidayNames
        for calendar in HolidayCatalog.regionalCalendars {
            let overlap = worldwide.intersection(calendar.holidayNames)
            #expect(overlap.isEmpty, "\(calendar.id) repeats worldwide holidays: \(overlap.sorted())")
        }
    }

    // MARK: - Visibility per region

    @Test func unitedStatesSeesEverythingExceptOtherRegionsHolidays() {
        let visible = HolidayCatalog.visibleHolidayNames(for: [.unitedStates])
        #expect(visible == allNames.subtracting(nonUSRegionalNames))
        #expect(visible.contains("Thanksgiving"))
        #expect(visible.contains("Independence Day"))
        #expect(visible.contains("Christmas Day"))
    }

    @Test func allRegionsTogetherSeeEveryHoliday() {
        let everyRegion = Set(HolidayCatalog.regionsWithCalendars)
        #expect(HolidayCatalog.visibleHolidayNames(for: everyRegion) == allNames)
    }

    @Test func regionWithoutACalendarSeesWorldwideOnly() {
        let visible = HolidayCatalog.visibleHolidayNames(for: [HolidayRegion("JP")])
        #expect(visible == HolidayCalendar.worldwide.holidayNames)
        #expect(!visible.contains("Thanksgiving"))
        #expect(visible.contains("New Year's Day"))
    }

    @Test func sharedHolidaysAppearInEachRegion() {
        let canada = HolidayCatalog.visibleHolidayNames(for: [.canada])
        #expect(canada.contains("Labor Day"))
        #expect(canada.contains("Canada Day"))
        #expect(!canada.contains("Thanksgiving"), "US Thanksgiving is not Canada's")

        let unitedKingdom = HolidayCatalog.visibleHolidayNames(for: [.unitedKingdom])
        #expect(unitedKingdom.contains("Boxing Day"))
        #expect(!unitedKingdom.contains("Memorial Day"))
    }

    // MARK: - Region model

    @Test func regionCodesAreNormalizedAndHaveFlags() {
        #expect(HolidayRegion("us") == .unitedStates)
        #expect(HolidayRegion.unitedStates.flag == "🇺🇸")
        #expect(HolidayRegion("GB").flag == "🇬🇧")
    }
}
