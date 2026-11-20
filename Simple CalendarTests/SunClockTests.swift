//
//  SunClockTests.swift
//  Simple CalendarTests
//
//  Guards the sun math behind the day/night sky and the approximate-location filter.
//

import Testing
import Foundation
import CoreLocation
@testable import Simple_Calendar

struct SunClockTests {

    private func utc(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

    @Test func summerSolsticeNoonHeightAtGreenwich() {
        // Highest sun on 21 June at 51.48° N is 90 - 51.48 + 23.44 ≈ 61.96°.
        let start = utc("2024-06-21T11:30:00Z")
        let highest = (0..<60).map { SolarPosition.sample(at: start.addingTimeInterval(Double($0) * 60), latitude: 51.4769, longitude: 0).elevation }.max()!
        #expect(abs(highest - 61.96) < 0.3)
    }

    @Test func amsterdamSunriseOnTwentiethNovember() {
        // Published sunrise is about 08:17 CET (07:17 UTC); sunrise is the -0.833° crossing.
        let before = SolarPosition.sample(at: utc("2026-11-20T07:10:00Z"), latitude: 52.37, longitude: 4.90)
        let after = SolarPosition.sample(at: utc("2026-11-20T07:25:00Z"), latitude: 52.37, longitude: 4.90)
        #expect(before.elevation < -0.833)
        #expect(after.elevation > -0.833)
        #expect(before.isMorning && after.isMorning)
    }

    @Test func morningAndEveningSides() {
        #expect(SolarPosition.sample(at: utc("2026-03-20T09:00:00Z"), latitude: 0, longitude: 0).isMorning)
        #expect(!SolarPosition.sample(at: utc("2026-03-20T15:00:00Z"), latitude: 0, longitude: 0).isMorning)
        #expect(SolarPosition.sample(at: utc("2026-03-20T00:00:00Z"), latitude: 0, longitude: 0).elevation < -60)
    }

    @Test func averagingAcrossTheAntimeridian() {
        let average = ApproximateLocationStore.average([[10, 179], [10, -179]])!
        #expect(abs(abs(average.longitude) - 180) < 0.01)
        #expect(abs(average.latitude - 10) < 0.05)
    }

    @Test func averagingFiveNearbyReadings() {
        let average = ApproximateLocationStore.average([[52.0, 4.0], [52.2, 4.2], [52.4, 4.4], [52.6, 4.6], [52.8, 4.8]])!
        #expect(abs(average.latitude - 52.4) < 0.01)
        #expect(abs(average.longitude - 4.4) < 0.01)
    }

    @Test func areaAnswerAcceptsMatchingTimeZone() {
        let amsterdam = TimeZone(identifier: "Europe/Amsterdam")!
        let data = Data(#"{"area":{"latitude":52.25,"longitude":5,"cell":"52.25,5.00"},"weatherMode":"shared"}"#.utf8)
        let answer = ApproximateLocationStore.parse(data, deviceTimeZone: amsterdam)
        #expect(answer?.area?.cell == "52.25,5.00")
        #expect(answer?.mode == .shared)
    }

    @Test func areaAnswerDropsVPNInAnotherTimeZone() {
        let amsterdam = TimeZone(identifier: "Europe/Amsterdam")!
        let data = Data(#"{"area":{"latitude":40.75,"longitude":-74,"cell":"40.75,-74.00"},"weatherMode":"direct"}"#.utf8)
        let answer = ApproximateLocationStore.parse(data, deviceTimeZone: amsterdam)
        #expect(answer != nil)
        #expect(answer?.area == nil)
        #expect(answer?.mode == .direct)
    }

    @Test func areaAnswerWithoutAreaKeepsMode() {
        let answer = ApproximateLocationStore.parse(Data(#"{"area":null,"weatherMode":"shared"}"#.utf8))
        #expect(answer?.area == nil)
        #expect(answer?.mode == .shared)
    }

    private func hour(_ t: Double, kind: String = "none", precip: Double = 0, cloud: Double = 0.5, thunder: Bool = false) -> WeatherHour {
        WeatherHour(t: t, cloud: cloud, precip: precip, kind: kind, wind: 4, gust: 6, visibility: 10_000, thunder: thunder, temp: 10)
    }

    @Test func weatherBlendsBetweenHours() {
        let start = 1_800_000_000.0
        let hours = [hour(start, cloud: 0.2), hour(start + 3600, kind: "rain", precip: 4, cloud: 1, thunder: true)]
        let half = SceneWeather.blend(hours, at: Date(timeIntervalSince1970: start + 1800))!
        #expect(abs(half.cloud - 0.6) < 0.001)
        #expect(abs(half.rainRate - 2) < 0.001)
        #expect(half.snowRate == 0)
        #expect(abs(half.thunder - 0.5) < 0.001)
    }

    @Test func snowAndSleetSplitIntoRainAndSnow() {
        let start = 1_800_000_000.0
        let snow = SceneWeather.blend([hour(start, kind: "snow", precip: 2)], at: Date(timeIntervalSince1970: start + 60))!
        #expect(snow.snowRate == 2 && snow.rainRate == 0)
        let sleet = SceneWeather.blend([hour(start, kind: "sleet", precip: 2)], at: Date(timeIntervalSince1970: start + 60))!
        #expect(sleet.snowRate == 1 && sleet.rainRate == 2 && sleet.sleet)
    }

    @Test func staleForecastIsIgnored() {
        let start = 1_800_000_000.0
        #expect(SceneWeather.blend([hour(start)], at: Date(timeIntervalSince1970: start + 4 * 3600)) == nil)
        #expect(SceneWeather.blend([], at: Date()) == nil)
    }

    @Test func skyBrightensThroughSunrise() {
        func brightness(_ elevation: Double) -> Double {
            let c = SkyPalette.colors(elevation: elevation).zenith
            return c.r + c.g + c.b
        }
        let elevations: [Double] = [-20, -12, -6, -2, 0, 4, 10] // the high-sun zenith deepens again, as it should
        for (low, high) in zip(elevations, elevations.dropFirst()) {
            #expect(brightness(low) <= brightness(high))
        }
    }
}
