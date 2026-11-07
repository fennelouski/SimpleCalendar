//
//  HolidayRegionManager.swift
//  Simple Calendar
//
//  Decides which regional holiday calendars are active.
//
//  Active regions = the device's region (while "Match device region" is on)
//  plus any regions the user added in Settings. The worldwide calendar is
//  always included. Category filtering (HolidayCategoryManager) is applied on
//  top of this, unchanged.
//

import Foundation
import Combine

final class HolidayRegionManager: ObservableObject {
    static let shared = HolidayRegionManager()

    /// Region used when the device's locale has no region at all. The holiday
    /// data has always been US-centric, so this matches prior behavior.
    static let fallbackRegion = HolidayRegion.unitedStates

    private enum Keys {
        static let followsDeviceRegion = "holiday_regions_follow_device"
        static let additionalRegions = "holiday_regions_additional"
    }

    /// When true, the device's region is active automatically (the default).
    @Published private(set) var followsDeviceRegion: Bool

    /// Regions the user turned on in addition to (or instead of) the device region.
    @Published private(set) var additionalRegions: Set<HolidayRegion>

    /// The device's region right now (updates if the user changes it in system settings).
    @Published private(set) var deviceRegion: HolidayRegion

    /// The regions whose calendars are currently shown.
    @Published private(set) var activeRegions: Set<HolidayRegion> = []

    /// Names of holidays allowed by the active regions (worldwide + active
    /// regional calendars). Recomputed only when the active regions change.
    private(set) var visibleHolidayNames: Set<String> = []

    private var localeObserver: NSObjectProtocol?

    private init() {
        deviceRegion = HolidayRegion.device ?? Self.fallbackRegion
        let stored = Self.loadPreferences()
        followsDeviceRegion = stored.followsDevice
        additionalRegions = stored.additional
        recomputeActiveRegions(notify: false)

        localeObserver = NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.deviceRegionMayHaveChanged()
            }
        }
    }

    // MARK: - Queries

    /// Whether a holiday belongs to the worldwide calendar or an active region's calendar.
    func isVisible(_ holiday: CalendarHoliday) -> Bool {
        visibleHolidayNames.contains(holiday.name)
    }

    func isActive(_ region: HolidayRegion) -> Bool {
        activeRegions.contains(region)
    }

    /// True when the region is active only because it is the device region
    /// (so its toggle can't be turned off without turning off "Match device region").
    func isActiveAutomatically(_ region: HolidayRegion) -> Bool {
        followsDeviceRegion && region == deviceRegion
    }

    /// Regions to offer in Settings: every region with a calendar, plus the
    /// device region, with the device region first.
    var selectableRegions: [HolidayRegion] {
        var regions = Set(HolidayCatalog.regionsWithCalendars)
        regions.insert(deviceRegion)
        let others = regions.subtracting([deviceRegion]).sorted()
        return [deviceRegion] + others
    }

    /// Whether the app has a regional calendar for this region.
    func hasCalendar(_ region: HolidayRegion) -> Bool {
        HolidayCatalog.calendar(for: region) != nil
    }

    // MARK: - Changes

    func setFollowsDeviceRegion(_ follows: Bool) {
        guard follows != followsDeviceRegion else { return }
        followsDeviceRegion = follows
        if !follows {
            // Keep what the user was seeing: the device region becomes a manual choice.
            additionalRegions.insert(deviceRegion)
        }
        savePreferences()
        recomputeActiveRegions(notify: true)
    }

    func setRegion(_ region: HolidayRegion, enabled: Bool) {
        if isActiveAutomatically(region) { return }
        if enabled {
            additionalRegions.insert(region)
        } else {
            additionalRegions.remove(region)
        }
        savePreferences()
        recomputeActiveRegions(notify: true)
    }

    func toggle(_ region: HolidayRegion) {
        setRegion(region, enabled: !isActive(region))
    }

    private func deviceRegionMayHaveChanged() {
        let current = HolidayRegion.device ?? Self.fallbackRegion
        guard current != deviceRegion else { return }
        deviceRegion = current
        recomputeActiveRegions(notify: true)
    }

    private func recomputeActiveRegions(notify: Bool) {
        var regions = additionalRegions
        if followsDeviceRegion {
            regions.insert(deviceRegion)
        }
        let names = HolidayCatalog.visibleHolidayNames(for: regions)
        let changed = regions != activeRegions || names != visibleHolidayNames
        activeRegions = regions
        visibleHolidayNames = names
        guard notify, changed else { return }
        // Same refresh path as a holiday category change.
        HolidayManager.shared.holidayFiltersDidChange()
        NotificationCenter.default.post(name: Notification.Name("RefreshCalendar"), object: nil)
    }

    // MARK: - Persistence (local, mirrored to iCloud like holiday categories)

    private static func loadPreferences() -> (followsDevice: Bool, additional: Set<HolidayRegion>) {
        let iCloud = NSUbiquitousKeyValueStore.default
        let local = UserDefaults.standard

        let follows: Bool
        if iCloud.object(forKey: Keys.followsDeviceRegion) != nil {
            follows = iCloud.bool(forKey: Keys.followsDeviceRegion)
        } else if local.object(forKey: Keys.followsDeviceRegion) != nil {
            follows = local.bool(forKey: Keys.followsDeviceRegion)
        } else {
            follows = true
        }

        let codes = (iCloud.array(forKey: Keys.additionalRegions) as? [String])
            ?? local.stringArray(forKey: Keys.additionalRegions)
            ?? []
        return (follows, Set(codes.map(HolidayRegion.init)))
    }

    private func savePreferences() {
        let codes = additionalRegions.map(\.code).sorted()
        let local = UserDefaults.standard
        local.set(followsDeviceRegion, forKey: Keys.followsDeviceRegion)
        local.set(codes, forKey: Keys.additionalRegions)

        let iCloud = NSUbiquitousKeyValueStore.default
        iCloud.set(followsDeviceRegion, forKey: Keys.followsDeviceRegion)
        iCloud.set(codes, forKey: Keys.additionalRegions)
        iCloud.synchronize()
    }
}
