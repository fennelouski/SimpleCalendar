//
//  HolidayCalendar.swift
//  Simple Calendar
//
//  A holiday calendar is a set of holidays observed together: either
//  worldwide, or in one region (country). The holidays a user sees are the
//  worldwide calendar plus the calendars of their active regions
//  (`HolidayRegionManager`), further filtered by holiday category
//  (`HolidayCategoryManager`).
//
//  To add a region: write its calendar (see RegionalHolidayCalendars.swift),
//  add it to `HolidayCatalog.calendars`, and give any new holiday with a
//  computed date a rule in `CalendarHoliday.dateInYear`. See
//  docs/regional-calendars.md.
//

import Foundation

struct HolidayCalendar: Identifiable {
    enum Scope: Hashable {
        /// Observed broadly around the world; always included.
        case worldwide
        /// Observed in one region; included when that region is active.
        case region(HolidayRegion)
    }

    let scope: Scope
    /// The holidays in this calendar. A holiday may belong to several calendars
    /// (e.g. Labor Day is in both the United States and Canada calendars).
    let holidays: [CalendarHoliday]

    var id: String {
        switch scope {
        case .worldwide: return "worldwide"
        case .region(let region): return "region.\(region.code)"
        }
    }

    var region: HolidayRegion? {
        if case .region(let region) = scope { return region }
        return nil
    }

    var displayName: String {
        region?.displayName ?? "Worldwide".localized
    }

    /// Holiday names in this calendar. Holidays are identified by name across
    /// the app (date rules, images and de-duplication all key on it).
    var holidayNames: Set<String> {
        Set(holidays.map(\.name))
    }
}

/// Every holiday calendar the app ships, and the master holiday list.
enum HolidayCatalog {
    /// All calendars: worldwide first, then each regional calendar.
    static let calendars: [HolidayCalendar] = [
        .worldwide,
        .unitedStates,
        .canada,
        .mexico,
        .unitedKingdom,
        .ireland,
        .france,
        .germany,
        .sweden,
        .finland,
        .czechia,
        .australia,
        .newZealand
    ]

    static var regionalCalendars: [HolidayCalendar] {
        calendars.filter { $0.region != nil }
    }

    /// Regions that have a calendar, alphabetical in the user's language.
    static var regionsWithCalendars: [HolidayRegion] {
        regionalCalendars.compactMap(\.region).sorted()
    }

    static func calendar(for region: HolidayRegion) -> HolidayCalendar? {
        calendars.first { $0.region == region }
    }

    /// Names of the holidays visible for a set of active regions: the worldwide
    /// calendar plus each active region's calendar. Regions without a calendar
    /// contribute nothing.
    static func visibleHolidayNames(for regions: Set<HolidayRegion>) -> Set<String> {
        var names = Set<String>()
        for calendar in calendars {
            switch calendar.scope {
            case .worldwide:
                names.formUnion(calendar.holidayNames)
            case .region(let region) where regions.contains(region):
                names.formUnion(calendar.holidayNames)
            case .region:
                break
            }
        }
        return names
    }

    /// Every holiday definition the app computes dates for, in display
    /// priority order: when several holidays fall on the same day, earlier
    /// ones are listed first (tvOS shows only the first two per day).
    ///
    /// This is `displayOrder` followed by any holiday that appears only in a
    /// calendar, so a new regional holiday needs to be added to its calendar
    /// only.
    static let definitions: [CalendarHoliday] = {
        var seen = Set(displayOrder.map(\.id))
        var result = displayOrder
        for calendar in calendars {
            for holiday in calendar.holidays where !seen.contains(holiday.id) {
                seen.insert(holiday.id)
                result.append(holiday)
            }
        }
        return result
    }()

    /// The display priority order of the existing holidays. Unchanged from the
    /// list `HolidayManager` used before regional calendars, so same-day
    /// ordering is identical.
    static let displayOrder: [CalendarHoliday] = [
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
        .tuBshevat,
        .lagBOmer,
        .tishaBAv,
        .simchatTorah,
        .sheminiAtzeret,
        .diwali,
        .ramadanStart,
        .eidAlFitr,
        .eidAlAdha,
        .vesak,
        .holi,

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
        .walpurgisNight,

        // MARK: - Additional Unique Holidays
        .talkLikeAPirateDay,
        .nationalMargaritaDay,
        .nationalCheeseDay,
        .nationalChocolateDay,
        .nationalPancakeDay,
        .nationalSandwichDay,
        .nationalCookieDay,
        .nationalPretzelDay,
        .nationalBubbleBathDay,
        .nationalPajamaDay,

        // MARK: - Awareness Days
        .blackHistoryMonthStart,
        .autismAwarenessDay,
        .breastCancerAwarenessMonthStart,
        .mentalHealthAwarenessMonthStart,
        .worldAidsDay,
        .heartMonthStart,
        .diabetesAwarenessMonthStart,
        .alzheimersAwarenessMonthStart,
        .worldCancerDay,
        .worldWaterDay,
        .earthHour,
        .worldHealthDay,
        .arborDayAwareness,
        .nationalStrokeAwarenessMonthStart,
        .nationalSkinCancerAwarenessMonthStart,
        .worldEnvironmentDay,
        .nationalSuicidePreventionMonthStart,
        .worldOceansDay,
        .nationalDomesticViolenceAwarenessMonthStart,

        // MARK: - Additional Seasonal Holidays
        .firstDayOfWinter,
        .firstDayOfFall,

        // MARK: - Additional Food Holidays
        .nationalGrilledCheeseDay,
        .nationalBaconDay,
        .nationalApplePieDay,
        .nationalIceCreamForBreakfastDay,

        // MARK: - Additional Pet Holidays
        .nationalDogDay,
        .nationalCatDay,
        .adoptAShelterPetDay,
        .nationalPuppyDay,
        .nationalAnimalDay,
        .worldWildlifeDay,
        .nationalParksDay,

        // MARK: - Additional Fun/Culture Holidays
        .marioDay,
        .nationalVideoGameDay,
        .nationalComicBookDay,
        .nationalMovieDay,
        .batmanDay,
        .pokemonDay,

        // MARK: - Additional Kindness/Mental Health Holidays
        .randomActsOfKindnessDay,
        .worldMentalHealthDay,
        .nationalKindnessDay,
        .nationalBestFriendsDay,
        .worldSmileDay,
        .worldHappinessDay,
        .nationalComplimentDay,
        .nationalRelaxationDay,

        // MARK: - Additional Educational Holidays
        .nationalSTEMDay,
        .nationalReadingDay,
        .worldBookDay,
        .nationalTriviaDay,
        .nationalCartoonistsDay,
        .nationalPhotographyDay,
        .nationalCreativityDay,

        // MARK: - Additional Lifestyle Holidays
        .newYearsResolutionsDay,
        .nationalCleanYourRoomDay,
        .nationalOrganizeYourHomeDay,
        .nationalWorkFromHomeDay,
        .nationalTakeAWalkDay,

        // MARK: - Additional Fun Holidays
        .nationalHatDay,
        .nationalLeftHandersDay,
        .nationalPicnicDay,
        .nationalJokeDay,
        .nationalThanksATeacherDay,
        .nationalBringYourPetToWorkDay,

        // MARK: - Lunar Phases
        .newMoonJanuary,
        .fullMoonJanuary,
        .newMoonFebruary,
        .fullMoonFebruary,
        .newMoonMarch,
        .fullMoonMarch,
        .newMoonApril,
        .fullMoonApril,
        .newMoonMay,
        .fullMoonMay,
        .newMoonJune,
        .fullMoonJune,
        .newMoonJuly,
        .fullMoonJuly,
        .newMoonAugust,
        .fullMoonAugust,
        .newMoonSeptember,
        .fullMoonSeptember,
        .newMoonOctober,
        .fullMoonOctober,
        .newMoonNovember,
        .fullMoonNovember,
        .newMoonDecember,
        .fullMoonDecember,
        .blueMoon
    ]
}
