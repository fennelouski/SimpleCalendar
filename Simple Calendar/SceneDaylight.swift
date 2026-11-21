//
//  SceneDaylight.swift
//  Simple Calendar
//
//  The time of day as the month scenes see it. Computed from the real sun every
//  animation frame, so everything that depends on it drifts continuously: there are
//  no steps, and nothing switches between "day art" and "night art".
//

import SwiftUI

struct SceneDaylight {
    /// Sun degrees above (+) or below (-) the horizon.
    var elevation: Double
    /// Degrees from solar noon (negative in the morning).
    var hourAngle: Double
    /// How high the sun climbs today; lets the arc fill the sky in every season.
    var noonElevation: Double
    /// 0 new moon, 0.5 full, 1 new again.
    var moonPhase: Double
    /// Local clock hour with fraction (19.5 = 7:30 pm), for human routines like lit windows.
    var localHour: Double
    /// Real weather, only for the current month while Weather Backgrounds is on; nil otherwise,
    /// when scenes keep their own invented weather.
    var weather: SceneWeather? = nil

    // MARK: Light levels (0...1)

    /// Overall light: 0 from deep twilight through the night, 1 once the sun is up properly.
    var light: CGFloat { BG.smoothstep(-8, 6, CGFloat(elevation)) }
    /// Darkness: full from astronomical twilight, gone by mid civil twilight.
    var night: CGFloat { 1 - BG.smoothstep(-15, -4, CGFloat(elevation)) }
    /// How visible the stars are.
    var stars: CGFloat { 1 - BG.smoothstep(-13, -5, CGFloat(elevation)) }
    /// Low warm sun: strongest a few degrees either side of the horizon.
    var golden: CGFloat { CGFloat(SkyPalette.flush(exp(-pow((elevation - 2) / 5, 2)))) }
    /// Morning twilight and sunrise (0 otherwise).
    var dawn: CGFloat { hourAngle < 0 ? CGFloat(SkyPalette.flush(exp(-pow((elevation + 3) / 6, 2)))) : 0 }
    /// Evening twilight and sunset (0 otherwise).
    var dusk: CGFloat { hourAngle >= 0 ? CGFloat(SkyPalette.flush(exp(-pow((elevation + 3) / 6, 2)))) : 0 }
    /// 1 while the sun is clear of the horizon; fades through sunrise and sunset.
    var sunUp: CGFloat { BG.smoothstep(-1.5, 1.5, CGFloat(elevation)) }
    var isMorning: Bool { hourAngle < 0 }

    /// Compatibility for scene parts that still pick between two looks.
    var isDark: Bool { elevation <= SunClock.lightElevation }

    // MARK: Positions

    /// Where the horizon sits for the sun and moon (behind most scenes' land).
    static let horizonFraction: CGFloat = 0.6

    /// The sun's place on screen: it rises at the left, crosses the top at noon and sets
    /// at the right. Below the horizon it keeps going down, so glows set naturally.
    func sunPoint(in size: CGSize) -> CGPoint {
        point(hourAngle: hourAngle, elevation: elevation, in: size)
    }

    /// The moon trails the sun by its phase (new moon rides with the sun, full moon is
    /// opposite), which puts a full moon up all night and a crescent near the sunset.
    var moonHourAngle: Double { moonHourAngle(phase: moonPhase) }
    var moonElevation: Double { moonElevation(phase: moonPhase) }

    func moonPoint(in size: CGSize) -> CGPoint { moonPoint(in: size, phase: moonPhase) }

    /// Where a moon of `phase` would be now (scenes that show a chosen day's phase).
    func moonHourAngle(phase: Double) -> Double {
        let angle = hourAngle - phase * 360
        return (angle + 540).truncatingRemainder(dividingBy: 360) - 180
    }

    func moonElevation(phase: Double) -> Double {
        let peak = max(noonElevation, 20) + 8
        return peak * cos(moonHourAngle(phase: phase) * .pi / 180) - 8
    }

    func moonPoint(in size: CGSize, phase: Double) -> CGPoint {
        point(hourAngle: moonHourAngle(phase: phase), elevation: moonElevation(phase: phase), in: size)
    }

    private func point(hourAngle: Double, elevation: Double, in size: CGSize) -> CGPoint {
        let across = CGFloat(min(max(hourAngle / 115, -1.2), 1.2))
        let horizon = size.height * SceneDaylight.horizonFraction
        let top = size.height * 0.07
        let height = CGFloat(elevation / max(noonElevation, 12))
        return CGPoint(x: size.width * (0.5 + 0.42 * across), y: horizon - (horizon - top) * height)
    }

    // MARK: Sources

    static func at(_ date: Date) -> SceneDaylight {
        let sun = SunClock.shared.sample(at: date)
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = Double(parts.hour ?? 12) + Double(parts.minute ?? 0) / 60 + Double(parts.second ?? 0) / 3600
        return SceneDaylight(elevation: sun.elevation, hourAngle: sun.hourAngle, noonElevation: sun.noonElevation,
                             moonPhase: MoonPhase.fraction(at: date), localHour: hour)
    }

    /// A fixed midday or midnight, for when the sky does not follow the sun.
    static func fixed(dark: Bool, date: Date = Date()) -> SceneDaylight {
        SceneDaylight(elevation: dark ? -30 : 40, hourAngle: dark ? 170 : 15, noonElevation: 45,
                      moonPhase: MoonPhase.fraction(at: date), localHour: dark ? 22 : 13)
    }
}

// MARK: - Shared time-of-day features

enum DaylightPainter {
    /// Multiplies the scene's colors toward a moonlit blue as the light goes: one call
    /// at the end of a scene darkens everything drawn so far, keeping its alpha.
    static func nightGrade(in ctx: inout GraphicsContext, size: CGSize, daylight: SceneDaylight, strength: CGFloat = 1) {
        let amount = Double(daylight.night * strength)
        guard amount > 0.01 else { return }
        var grade = ctx
        grade.blendMode = .sourceAtop
        grade.fill(Path(CGRect(origin: .zero, size: size)), with: .color(BG.rgb(0.04, 0.06, 0.16, 0.72 * amount)))
    }

    /// Warm light washing over the scene from the sun's side at sunrise and sunset.
    static func lowSunGrade(in ctx: inout GraphicsContext, size: CGSize, daylight: SceneDaylight, strength: CGFloat = 1) {
        let amount = Double(max(daylight.dawn, daylight.dusk) * strength)
        guard amount > 0.01 else { return }
        var grade = ctx
        grade.blendMode = .sourceAtop
        let sun = daylight.sunPoint(in: size)
        grade.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [BG.rgb(1, 0.55, 0.3, 0.35 * amount), BG.rgb(0.95, 0.45, 0.45, 0.12 * amount)]),
                center: sun, startRadius: 0, endRadius: max(size.width, size.height)
            )
        )
    }

    /// Stars that come out through twilight; `cover` (0...1) hides them behind cloud.
    static func stars(in ctx: inout GraphicsContext, size: CGSize, time: Double, daylight: SceneDaylight, count: Int = 90, cover: CGFloat = 0) {
        let cover = max(cover, daylight.weather?.cover ?? 0)
        let intensity = Double(daylight.stars * (1 - cover))
        guard intensity > 0.01 else { return }
        AtmospherePainter.stars(in: &ctx, size: size, time: time, count: count, skyFraction: 0.6, intensity: intensity)
    }

    /// The moon at its place in the sky with its real phase; `cover` dims it behind cloud.
    static func moon(in ctx: inout GraphicsContext, size: CGSize, daylight: SceneDaylight, radius: CGFloat = 34, cover: CGFloat = 0) {
        let cover = max(cover, daylight.weather?.cover ?? 0)
        let up = BG.smoothstep(-2, 4, CGFloat(daylight.moonElevation))
        let visible = Double(up * (1 - 0.65 * daylight.light) * (1 - min(cover, 1)))
        guard visible > 0.02 else { return }
        let c = daylight.moonPoint(in: size)
        let illumination = MoonPhase.illumination(daylight.moonPhase)
        ctx.glow(at: c, radius: radius * 7, color: BG.rgb(0.75, 0.82, 1), intensity: 0.35 * visible * illumination)
        var disc = ctx
        disc.opacity = visible
        MoonPainter.draw(in: &disc, center: c, radius: radius, phase: daylight.moonPhase)
    }

    /// Fireflies over the grass from dusk until about midnight on warm, dry evenings.
    /// `season` scales how many are out (0 none ... 1 high summer).
    static func fireflies(in ctx: inout GraphicsContext, size: CGSize, time: Double, daylight: SceneDaylight, season: CGFloat, top: CGFloat = 0.55) {
        let evening = daylight.localHour >= 12 && daylight.localHour < 24.5 ? 1 - BG.smoothstep(23, 24.5, CGFloat(daylight.localHour)) : 0
        var amount = season * BG.smoothstep(0.55, 0.15, daylight.light) * evening
        if let weather = daylight.weather {
            amount *= (1 - weather.rain) * (1 - weather.windiness * 0.8) * BG.smoothstep(10, 16, CGFloat(weather.temperature))
        }
        guard amount > 0.02 else { return }
        let t = CGFloat(time)
        let count = Int(8 + 30 * amount)
        for i in 0..<count {
            // Each wanders slowly and flashes on its own rhythm: a slow rise, a short glow.
            let x = BG.wrap(BG.hash(i, 961) * size.width + sin(t * BG.hash(i, 962, 0.05, 0.15) + CGFloat(i)) * 60, length: size.width, margin: 20)
            let y = size.height * BG.hash(i, 963, top, 0.95) + sin(t * BG.hash(i, 964, 0.1, 0.3) + CGFloat(i) * 2) * 24
            let period = BG.hash(i, 965, 2.5, 5.5)
            let phase = BG.fract(t / period + BG.hash(i, 966))
            let flash = BG.smoothstep(0, 0.12, phase) * (1 - BG.smoothstep(0.12, 0.35, phase))
            guard flash > 0.02 else { continue }
            let alpha = Double(flash * amount)
            let p = CGPoint(x: x, y: y)
            ctx.glow(at: p, radius: 22, color: BG.rgb(0.85, 1, 0.45), intensity: 0.55 * alpha, additive: true)
            ctx.fill(BG.circle(p, 2.2), with: .color(BG.rgb(0.95, 1, 0.7, alpha)))
        }
    }

    /// 0...1 for a lit window: on at dusk, most off by bedtime, a few back on before dawn.
    /// Each window keeps its own habits so they come and go one by one.
    static func windowLit(_ index: Int, salt: Int, daylight: SceneDaylight) -> CGFloat {
        let dark = BG.smoothstep(0.25, 0.7, daylight.night + (1 - daylight.light) * 0.4)
        guard dark > 0 else { return 0 }
        let h = daylight.localHour
        let bedtime = 21.5 + Double(BG.hash(index, salt)) * 3      // 21:30 ... 00:30
        let wake = 5.5 + Double(BG.hash(index, salt + 1)) * 2       // 05:30 ... 07:30
        let evening = h >= 12 ? (h < bedtime ? 1.0 : 0.0) : (bedtime > 24 && h < bedtime - 24 ? 1 : 0)
        let morning = h < 12 && h >= wake ? 1.0 : 0.0
        let threshold = BG.hash(index, salt + 2) * 0.6                // some windows light earlier than others
        return CGFloat(max(evening, morning)) * BG.smoothstep(threshold, threshold + 0.25, dark)
    }
}
