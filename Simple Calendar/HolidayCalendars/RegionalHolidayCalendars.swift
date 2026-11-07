//
//  RegionalHolidayCalendars.swift
//  Simple Calendar
//
//  Calendars for regions other than the United States. Most are small for
//  now. They grow as regional holidays are added; a region can also move into
//  its own file once its calendar gets large (like UnitedStatesHolidayCalendar).
//

import Foundation

extension HolidayCalendar {
    /// Canada (Labour Day and daylight saving time share US dates)
    static let canada = HolidayCalendar(scope: .region(.canada), holidays: [
        .laborDay,
        .groundhogDay,
        .canadaDay,
        .boxingDay,
        .daylightSavingTimeStarts,
        .daylightSavingTimeEnds,
        .blackHistoryMonthStart
    ])

    /// Mexico
    static let mexico = HolidayCalendar(scope: .region(.mexico), holidays: [
        .cincoDeMayo,
        .dayOfTheDead
    ])

    /// United Kingdom
    static let unitedKingdom = HolidayCalendar(scope: .region(.unitedKingdom), holidays: [
        .boxingDay
    ])

    /// Ireland (Boxing Day is St. Stephen's Day)
    static let ireland = HolidayCalendar(scope: .region(.ireland), holidays: [
        .boxingDay
    ])

    /// France
    static let france = HolidayCalendar(scope: .region(.france), holidays: [
        .bastilleDay
    ])

    /// Germany
    static let germany = HolidayCalendar(scope: .region(.germany), holidays: [
        .walpurgisNight
    ])

    /// Sweden (Valborg)
    static let sweden = HolidayCalendar(scope: .region(.sweden), holidays: [
        .walpurgisNight
    ])

    /// Finland (Vappu eve)
    static let finland = HolidayCalendar(scope: .region(.finland), holidays: [
        .walpurgisNight
    ])

    /// Czechia (Pálení čarodějnic)
    static let czechia = HolidayCalendar(scope: .region(.czechia), holidays: [
        .walpurgisNight
    ])

    /// Australia
    static let australia = HolidayCalendar(scope: .region(.australia), holidays: [
        .boxingDay
    ])

    /// New Zealand
    static let newZealand = HolidayCalendar(scope: .region(.newZealand), holidays: [
        .boxingDay
    ])
}
