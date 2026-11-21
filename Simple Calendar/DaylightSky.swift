//
//  DaylightSky.swift
//  Simple Calendar
//
//  The sky behind the calendar, following the real sun: night, astronomical,
//  nautical and civil twilight, sunrise, day and sunset blend continuously.
//

import SwiftUI

/// Sky colours keyed to the sun's elevation in degrees; anything between two stops is blended.
nonisolated enum SkyPalette {
    struct Stop {
        let elevation: Double
        let zenith: RGB
        let horizon: RGB
    }

    struct RGB {
        let r: Double, g: Double, b: Double
        init(_ hex: UInt32) {
            r = Double((hex >> 16) & 0xFF) / 255
            g = Double((hex >> 8) & 0xFF) / 255
            b = Double(hex & 0xFF) / 255
        }
        init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
        func mixed(with other: RGB, _ f: Double) -> RGB {
            RGB(r: r + (other.r - r) * f, g: g + (other.g - g) * f, b: b + (other.b - b) * f)
        }
        var color: Color { Color(red: r, green: g, blue: b) }
    }

    static let stops: [Stop] = [
        Stop(elevation: -18, zenith: RGB(0x03050C), horizon: RGB(0x0A0F22)), // night
        Stop(elevation: -12, zenith: RGB(0x070B1F), horizon: RGB(0x18204A)), // astronomical twilight
        Stop(elevation: -8, zenith: RGB(0x0F1638), horizon: RGB(0x2E2F6B)),  // nautical twilight
        Stop(elevation: -4, zenith: RGB(0x1F2A5E), horizon: RGB(0x7A4A7E)),  // civil twilight
        Stop(elevation: -1, zenith: RGB(0x3A4F8C), horizon: RGB(0xE07A5F)),  // sunrise / sunset
        Stop(elevation: 2, zenith: RGB(0x5878B4), horizon: RGB(0xF4A261)),
        Stop(elevation: 6, zenith: RGB(0x6C9BD2), horizon: RGB(0xF2C98A)),   // golden hour
        Stop(elevation: 12, zenith: RGB(0x5D9AE0), horizon: RGB(0xBFDDF2)),
        Stop(elevation: 30, zenith: RGB(0x4A8EDB), horizon: RGB(0xA9D2F2))   // day
    ]

    static func colors(elevation: Double) -> (zenith: RGB, horizon: RGB) {
        guard let first = stops.first, let last = stops.last else { return (RGB(0), RGB(0)) }
        if elevation <= first.elevation { return (first.zenith, first.horizon) }
        if elevation >= last.elevation { return (last.zenith, last.horizon) }
        for (lower, upper) in zip(stops, stops.dropFirst()) where elevation <= upper.elevation {
            let f = (elevation - lower.elevation) / (upper.elevation - lower.elevation)
            return (lower.zenith.mixed(with: upper.zenith, f), lower.horizon.mixed(with: upper.horizon, f))
        }
        return (last.zenith, last.horizon)
    }

    /// 0...1 bell curve: how strongly the sun lights the horizon on its side of the sky.
    static func sunGlow(elevation: Double) -> Double {
        flush(exp(-pow((elevation - 0.5) / 5, 2)))
    }

    /// Bell curves far from their peak produce denormal values (around 1e-40) that the
    /// renderer mishandles (a full-screen layer turned opaque white near solar noon), so
    /// anything below visibility is exactly zero.
    static func flush(_ value: Double) -> Double { value < 0.001 ? 0 : value }

    /// Cloud greys the sky toward slate (darker in a storm), keeping the light level of the hour.
    static func overcast(_ sky: (zenith: RGB, horizon: RGB), elevation: Double, weather: SceneWeather?) -> (zenith: RGB, horizon: RGB) {
        guard let weather else { return sky }
        let cover = Double(weather.cover)
        guard cover > 0.01 else { return sky }
        let light = Double(BG.smoothstep(-8, 6, CGFloat(elevation)))
        let storm = Double(weather.storm) * 0.35
        let grey = RGB(r: 0.05 + light * (0.52 - storm), g: 0.06 + light * (0.55 - storm), b: 0.08 + light * (0.6 - storm))
        return (sky.zenith.mixed(with: grey, 0.8 * cover), sky.horizon.mixed(with: grey.mixed(with: RGB(r: 1, g: 1, b: 1), 0.08 * light), 0.75 * cover))
    }

    /// 0...1 bell curve for the blue-violet of deep twilight.
    static func twilight(elevation: Double) -> Double {
        flush(exp(-pow((elevation + 7) / 4.5, 2)))
    }
}

/// Full-screen sky that replaces the flat backdrop while following the sun.
struct DaylightSkyBackground: View {
    /// True when the calendar shows the current month, which follows the real weather.
    var weatherActive = false
    @ObservedObject private var sunClock = SunClock.shared

    var body: some View {
        let sun = sunClock.sun
        let weather = weatherActive ? SceneWeatherService.shared.conditions(at: SunClock.now()) : nil
        let sky = SkyPalette.overcast(SkyPalette.colors(elevation: sun.elevation), elevation: sun.elevation, weather: weather)
        let glow = SkyPalette.sunGlow(elevation: sun.elevation) * (1 - Double(weather?.cover ?? 0))
        let sunSide: CGFloat = sun.isMorning ? 0.12 : 0.88
        GeometryReader { geometry in
            let span = max(geometry.size.width, geometry.size.height)
            ZStack {
                LinearGradient(colors: [sky.zenith.color, sky.zenith.mixed(with: sky.horizon, 0.45).color, sky.horizon.color],
                               startPoint: .top, endPoint: .bottom)
                if glow > 0 {
                    RadialGradient(colors: [Color(red: 1, green: 0.66, blue: 0.38).opacity(0.6 * glow), .clear],
                                   center: UnitPoint(x: sunSide, y: 1.0), startRadius: 0, endRadius: span * 0.7)
                }
            }
        }
        .animation(.easeInOut(duration: 3), value: sun.elevation)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Light that falls across the month scene: violet in deep twilight and a warm glow
/// from the sun's side at sunrise and sunset. It is clear at full day and full night,
/// where the scene's own day and night artwork already fits.
struct DaylightSkyWash: View {
    var weatherActive = false
    @ObservedObject private var sunClock = SunClock.shared

    var body: some View {
        let sun = sunClock.sun
        let cover = Double(weatherActive ? SceneWeatherService.shared.conditions(at: SunClock.now())?.cover ?? 0 : 0)
        let glow = SkyPalette.sunGlow(elevation: sun.elevation) * (1 - cover)
        let twilight = SkyPalette.twilight(elevation: sun.elevation) * (1 - 0.6 * cover)
        let sunSide: CGFloat = sun.isMorning ? 0.1 : 0.9
        GeometryReader { geometry in
            let span = max(geometry.size.width, geometry.size.height)
            ZStack {
                if twilight > 0 {
                    Color(red: 0.23, green: 0.22, blue: 0.52).opacity(0.22 * twilight)
                }
                if glow > 0 {
                    RadialGradient(colors: [Color(red: 1, green: 0.55, blue: 0.3).opacity(0.32 * glow), .clear],
                                   center: UnitPoint(x: sunSide, y: 1.0), startRadius: 0, endRadius: span * 0.85)
                }
            }
        }
        .animation(.easeInOut(duration: 3), value: sun.elevation)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
