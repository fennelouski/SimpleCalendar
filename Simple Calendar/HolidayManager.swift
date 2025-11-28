//
//  HolidayManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import Combine

/// Manages holiday data and provides holidays for display
class HolidayManager: ObservableObject {
    static let shared = HolidayManager()
    
    /// Supported year range for holiday calculations
    static let minYear = 1900
    static let maxYear = 2100
    
    /// Number of years to load around the current year initially
    private static let initialYearRange = 5 // 2 years back, current year, 2 years forward

    @Published var holidays: [CalendarHoliday] = []
    
    // Caching and async processing
    private var cachedHolidays: [Int: [CalendarHoliday]] = [:] // Year -> Holidays cache
    private var loadingYears: Set<Int> = [] // Years currently being loaded
    private var loadingQueue = DispatchQueue(label: "com.simplecalendar.holidayloading", qos: .utility)
    private let calculationQueue = DispatchQueue(label: "com.simplecalendar.holidaycalculation", qos: .userInitiated)
    private let semaphore = DispatchSemaphore(value: 4) // Limit to 4 concurrent calculations
    
    // Cache for date calculations to avoid recalculation
    private var dateCache: [String: Date?] = [:] // "holidayName-year" -> Date

    private let allHolidays: [CalendarHoliday] = [
        // MARK: - Government/Banking Holidays (National)
        .newYearsDay,
        .martinLutherKingJrDay,
        .presidentsDay,
        .washingtonsBirthday,
        .lincolnsBirthday,
        .patriotDay,
        .memorialDay,
        .juneteenth,
        .flagDay,
        .fourthOfJuly,
        .constitutionDay,
        .laborDay,
        .columbusDay,
        .indigenousPeoplesDay,
        .electionDay,
        .veteransDay,
        .pearlHarborDay,
        .arborDay,
        
        // MARK: - Religious Holidays
        .epiphany,
        .threeKingsDay,
        .candlemas,
        .stValentinesDay,
        .stPatricksDay,
        .ashWednesday,
        .lentBegins,
        .mardiGras,
        .palmSunday,
        .maundyThursday,
        .goodFriday,
        .holySaturday,
        .easter,
        .easterMonday,
        .ascensionDay,
        .pentecost,
        .whitMonday,
        .trinitySunday,
        .corpusChristi,
        .feastOfTheAssumption,
        .allSaintsDay,
        .allSoulsDay,
        .firstSundayOfAdvent,
        .stNicholasDay,
        .immaculateConception,
        .christmasEve,
        .christmasDay,
        .roshHashanah,
        .yomKippur,
        .hanukkah,
        .passover,
        .purim,
        .sukkot,
        .shavuot,
        .diwali,
        
        // MARK: - Social/Cultural Holidays
        .newYearsEve,
        .chineseNewYear,
        .groundhogDay,
        .superBowlSunday,
        .valentinesDay,
        .nationalPizzaDay,
        .aprilFoolsDay,
        .earthDay,
        .cincoDeMayo,
        .kentuckyDerby,
        .nationalHamburgerDay,
        .mothersDay,
        .nationalDonutDay,
        .fathersDay,
        .nationalIceCreamDay,
        .bastilleDay,
        .canadaDay,
        .grandparentsDay,
        .nationalCoffeeDay,
        .nationalTacoDay,
        .halloween,
        .dayOfTheDead,
        .thanksgiving,
        .blackFriday,
        .cyberMonday,
        .kwanzaa,
        .boxingDay,
        
        // MARK: - Seasonal Holidays
        .vernalEquinox,
        .firstDayOfSpring,
        .summerSolstice,
        .firstDayOfSummer,
        .autumnalEquinox,
        .winterSolstice,
        
        // MARK: - Educational Holidays
        .piDay,
        .teachersDay,
        .bookLoversDay,
        
        // MARK: - Additional Holidays
        .inaugurationDay,
        .leapDay,
        .daylightSavingTimeStarts,
        .daylightSavingTimeEnds,
        .taxDay,
        .nationalPetDay,
        .mayDay,
        .starWarsDay,
        .mothersDayWeekend,
        .armedForcesDay,
        .emancipationProclamationDay,
        .rosaParksDay,
        .billOfRightsDay,
        .wrightBrothersDay,
        .nationalFriendshipDay,
        .nationalSiblingsDay,
        .nationalWomensDay,
        .stGeorgesDay,
        .walpurgisNight
    ]

    private init() {
        // Load holidays for a small window around current year asynchronously
        // This prevents blocking the UI on app launch
        loadHolidaysForInitialRangeAsync()
    }

    /// Load holidays for initial range around current year asynchronously
    private func loadHolidaysForInitialRangeAsync() {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: Date())
        let startYear = max(Self.minYear, currentYear - 2)
        let endYear = min(Self.maxYear, currentYear + 2)
        
        // Load initial years asynchronously
        loadingQueue.async { [weak self] in
            self?.loadHolidaysForYears(Array(startYear...endYear), priority: .userInitiated)
        }
    }
    
    /// Load holidays for multiple years asynchronously with priority
    private func loadHolidaysForYears(_ years: [Int], priority: DispatchQoS = .utility) {
        let validYears = years.filter { $0 >= Self.minYear && $0 <= Self.maxYear }
        
        for year in validYears {
            // Skip if already loaded or currently loading
            if cachedHolidays[year] != nil || loadingYears.contains(year) {
                continue
            }
            
            loadingYears.insert(year)
            
            // Use semaphore to limit concurrent calculations
            semaphore.wait()
            calculationQueue.async(qos: priority) { [weak self] in
                defer { self?.semaphore.signal() }
                
                guard let self = self else { return }
                
                var yearHolidays: [CalendarHoliday] = []
                
                // Calculate holidays for this year
                for holiday in self.allHolidays {
                    if let holidayDate = self.cachedDateForHoliday(holiday: holiday, year: year) {
                        let holidayForYear = CalendarHoliday(
                            name: holiday.name,
                            date: holidayDate,
                            emoji: holiday.emoji,
                            description: holiday.description,
                            unsplashSearchTerm: holiday.unsplashSearchTerm,
                            isRecurring: holiday.isRecurring,
                            category: holiday.category
                        )
                        yearHolidays.append(holidayForYear)
                    }
                }
                
                // Cache the results
                self.loadingQueue.async {
                    self.cachedHolidays[year] = yearHolidays
                    self.loadingYears.remove(year)
                    
                    // Update published holidays on main thread
                    DispatchQueue.main.async {
                        self.updatePublishedHolidays()
                    }
                }
            }
        }
    }
    
    /// Get cached date or calculate and cache it
    private func cachedDateForHoliday(holiday: CalendarHoliday, year: Int) -> Date? {
        let cacheKey = "\(holiday.name)-\(year)"
        
        if let cachedDate = dateCache[cacheKey] {
            return cachedDate
        }
        
        let calculatedDate = holiday.dateInYear(year)
        dateCache[cacheKey] = calculatedDate
        
        return calculatedDate
    }
    
    /// Update the published holidays array from cache
    private func updatePublishedHolidays() {
        var allHolidays: [CalendarHoliday] = []
        for (_, yearHolidays) in cachedHolidays {
            allHolidays.append(contentsOf: yearHolidays)
        }
        self.holidays = allHolidays.sorted(by: { $0.date < $1.date })
    }
    
    /// Load holidays for a specific year if not already loaded and within supported range
    /// This ensures holidays are available even when viewing years outside the initial range
    /// Uses async loading to avoid blocking the main thread
    private func ensureHolidaysForYear(_ year: Int) {
        // Only load holidays for years within the supported range
        guard year >= Self.minYear && year <= Self.maxYear else {
            return
        }
        
        // Check if already cached or loading
        if cachedHolidays[year] != nil || loadingYears.contains(year) {
            return
        }
        
        // Load year asynchronously
        loadingQueue.async { [weak self] in
            self?.loadHolidaysForYears([year], priority: .userInitiated)
        }
        
        // Also preload adjacent years for smoother scrolling
        let adjacentYears = [year - 1, year + 1].filter { $0 >= Self.minYear && $0 <= Self.maxYear }
        loadingQueue.async { [weak self] in
            self?.loadHolidaysForYears(adjacentYears, priority: .utility)
        }
    }
    
    /// Preload holidays for a range of years (useful when user navigates to new year)
    func preloadHolidaysForYearRange(centerYear: Int, range: Int = 2) {
        let startYear = max(Self.minYear, centerYear - range)
        let endYear = min(Self.maxYear, centerYear + range)
        let yearsToPreload = Array(startYear...endYear).filter { cachedHolidays[$0] == nil && !loadingYears.contains($0) }
        
        if !yearsToPreload.isEmpty {
            loadingQueue.async { [weak self] in
                self?.loadHolidaysForYears(yearsToPreload, priority: .utility)
            }
        }
    }

    /// Get holidays that occur on a specific date
    func holidaysOn(_ date: Date) -> [CalendarHoliday] {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        
        // Ensure we have holidays loaded for this year (async, won't block)
        ensureHolidaysForYear(year)
        
        // Return cached holidays for this year if available, otherwise return empty
        // The holidays will appear once async loading completes
        if let yearHolidays = cachedHolidays[year] {
            let matchingHolidays = yearHolidays.filter { $0.occursOn(date) }
            // Remove duplicates by name to avoid showing the same holiday twice
            var seenNames = Set<String>()
            return matchingHolidays.filter { holiday in
                if seenNames.contains(holiday.name) {
                    return false
                } else {
                    seenNames.insert(holiday.name)
                    return true
                }
            }
        }
        
        // Return empty if not loaded yet - will be updated when async loading completes
        return []
    }

    /// Get all holidays in a specific month and year
    func holidaysInMonth(_ month: Int, year: Int) -> [CalendarHoliday] {
        // Ensure we have holidays loaded for this year (async)
        ensureHolidaysForYear(year)
        
        // Return cached holidays for this year if available
        if let yearHolidays = cachedHolidays[year] {
            return yearHolidays.filter { holiday in
                let components = Calendar(identifier: .gregorian).dateComponents([.month, .year], from: holiday.date)
                return components.month == month && components.year == year
            }
        }
        
        // Return empty if not loaded yet
        return []
    }

    /// Get holidays grouped by category
    func holidaysByCategory() -> [CalendarHoliday.CalendarHolidayCategory: [CalendarHoliday]] {
        Dictionary(grouping: holidays) { $0.category }
    }

    /// Get upcoming holidays (next 12 months from today)
    func upcomingHolidays(limit: Int = 10) -> [CalendarHoliday] {
        let today = Date()
        let futureHolidays = holidays.filter { $0.date >= today }
            .sorted { $0.date < $1.date }

        return Array(futureHolidays.prefix(limit))
    }

    /// Get holidays for a specific year
    func holidaysForYear(_ year: Int) -> [CalendarHoliday] {
        // Ensure we have holidays loaded for this year (async)
        ensureHolidaysForYear(year)
        
        // Return cached holidays directly
        return cachedHolidays[year] ?? []
    }

    /// Refresh holidays for new years as needed
    func refreshHolidaysIfNeeded() {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: Date())
        
        // Ensure we have holidays for current year and adjacent years
        let yearsNeeded = [currentYear - 1, currentYear, currentYear + 1]
            .filter { $0 >= Self.minYear && $0 <= Self.maxYear }
            .filter { cachedHolidays[$0] == nil }
        
        if !yearsNeeded.isEmpty {
            loadingQueue.async { [weak self] in
                self?.loadHolidaysForYears(yearsNeeded, priority: .userInitiated)
            }
        }
    }
    
    /// Clear cache if needed (for memory management)
    func clearCache(keepingYears: Set<Int>) {
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let yearsToKeep = keepingYears.filter { $0 >= Self.minYear && $0 <= Self.maxYear }
            let yearsToRemove = Set(self.cachedHolidays.keys).subtracting(yearsToKeep)
            
            for year in yearsToRemove {
                self.cachedHolidays.removeValue(forKey: year)
                
                // Also clear date cache for this year
                for (key, _) in self.dateCache {
                    if key.hasSuffix("-\(year)") {
                        self.dateCache.removeValue(forKey: key)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.updatePublishedHolidays()
            }
        }
    }
}
