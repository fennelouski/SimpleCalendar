//
//  AugustScene.swift
//  Simple Calendar
//
//  August: high summer over open farmland.
//
//  The sun is the engine of the scene. It arcs across the top over twenty minutes and
//  everything answers to it: clouds are lit toward it and dim it when they pass in
//  front (rays, flare and the fields below all darken together), their shadows sweep
//  across the fields, and the ground it heats drives one thermal signal. Thermals make
//  the air shimmer, keep the hawks circling, swell the cumulus and, now and then, spin
//  a dust devil up off the fields.
//
//  The scene also follows the selected day:
//    * daylight       - long early-August days ride the sun higher and whiter; shorter
//                       late-month days lower and warm it, and the shimmer eases
//    * day character  - on hot days (hash of the date) a thunderhead slowly towers up
//                       at the edge of the sky
//    * Perseids       - Aug 12-13: the sky dims to dusk, stars come out and meteors fall
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct AugustSunCloudsAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = AugustModel()

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = AugustModel.Target(date: date)
        let state = model
        AnimatedScene(daylight: { ctx, size, time, daylight in
            var look = state.look(target: target.with(daylight.weather), time: time)
            // The scene's own dusk now follows the real sky.
            look.night = daylight.night
            AugustScene.draw(in: &ctx, size: size, time: time, look: look, daylight: daylight, meteorPeak: CGFloat(target.meteorNight))
        })
        .opacity(alpha)
    }
}

// MARK: - State

final class AugustModel {
    struct Target {
        /// 0 on a long early-August day ... 1 on a short late-August day.
        let shortDay: Double
        /// 1 on thunderhead days.
        var hot: Double
        /// 1 on the Perseid peak.
        let meteorNight: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            shortDay = 1 - min(max((day.daylightHours - 12.8) / 1.3, 0), 1)
            hot = day.roll(311) < 0.4 ? 1 : 0
            meteorNight = day.month == 8 && (day.day == 12 || day.day == 13) ? 1 : 0
        }

        /// A real hot, unsettled afternoon or a thunderstorm raises the thunderhead.
        func with(_ weather: SceneWeather?) -> Target {
            guard let weather else { return self }
            var target = self
            let hotAndBuilding = weather.temperature > 26 && weather.cloud > 0.25
            target.hot = max(Double(weather.storm), hotAndBuilding ? 1 : 0)
            return target
        }
    }

    struct Look {
        var shortDay: CGFloat
        var hot: CGFloat
        var night: CGFloat
        /// Breeze displacement accumulated since the scene appeared.
        var drift: CGFloat

        var warmth: CGFloat { BG.lerp(0.08, 0.2, shortDay) }
        var shimmer: CGFloat { BG.lerp(1, 0.6, shortDay) }
    }

    private let shortTransition = SceneTransition()
    private let hotTransition = SceneTransition()
    private let nightTransition = SceneTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let short = shortTransition.value(target: target.shortDay, time: time)
        let hot = hotTransition.value(target: target.hot, time: time)
        let night = nightTransition.value(target: target.meteorNight, time: time)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * AugustAir.breeze(CGFloat(time))
        }
        lastTime = time
        return Look(shortDay: CGFloat(short), hot: CGFloat(hot), night: CGFloat(night), drift: drift)
    }
}

// MARK: - Air

private enum AugustAir {
    /// Gentle breeze in points per second (never reverses).
    static func breeze(_ t: CGFloat) -> CGFloat {
        10 + 3.5 * sin(t * 0.13) + 2 * sin(t * 0.31 + 1.3)
    }

    /// 0...1 strength of the thermals coming off the sunlit ground (before shading).
    /// Incommensurate periods of roughly 25 to 70 s, so the swells never loop visibly.
    static func thermal(_ t: CGFloat) -> CGFloat {
        let s = 0.45 * sin(t * 0.09) + 0.35 * sin(t * 0.23 + 2.1) + 0.2 * sin(t * 0.37 + 0.7)
        return BG.smoothstep(-0.6, 0.8, s)
    }
}

// MARK: - Cloud state

/// One cumulus in this frame, computed up front so the sun can be occluded by it and
/// its shadow can be cast on the fields.
private struct AugustCloud {
    var center: CGPoint
    var width: CGFloat
    var opacity: Double
    var seed: Int
    var depth: CGFloat
    var grow: CGFloat
}

private struct AugustFrame {
    var sun: CGPoint
    var sunFade: CGFloat
    /// 0 (sun fully behind a cloud) ... 1 (clear).
    var sunlight: CGFloat
    /// Thermal strength after cloud shading.
    var heat: CGFloat
    var clouds: [AugustCloud]
}

// MARK: - Scene

private enum AugustScene {
    static let sunRadius: CGFloat = 62

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: AugustModel.Look, daylight: SceneDaylight, meteorPeak: CGFloat) {
        let t = CGFloat(time)
        let dark = daylight.isDark
        let frame = makeFrame(size: size, t: t, look: look, daylight: daylight)
        let day = 1 - look.night
        let cover = daylight.weather?.cover ?? 0
        // Perseids are active all month: a few meteors on any clear night, a shower at the peak.
        let meteors = daylight.stars * (1 - cover) * BG.lerp(0.35, 1, meteorPeak)

        drawSky(in: &ctx, size: size, t: t, look: look, dark: dark)
        if day > 0.01 {
            var sunCtx = ctx
            sunCtx.opacity = Double(day * frame.sunFade * (0.45 + 0.55 * frame.sunlight))
            SunPainter.draw(in: &sunCtx, center: frame.sun, radius: sunRadius, time: time, warmth: look.warmth, canvas: size, flare: false)
        }
        DaylightPainter.moon(in: &ctx, size: size, daylight: daylight)
        drawMeteors(in: &ctx, size: size, t: t, night: meteors)
        WeatherPainter.cloudDeck(in: &ctx, size: size, time: time, daylight: daylight, seed: 8)
        drawBalloon(in: &ctx, size: size, t: t, frame: frame, day: day)
        drawThunderhead(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark)
        for cloud in frame.clouds {
            drawCloud(cloud, in: &ctx, t: t, frame: frame, look: look, dark: dark)
        }
        drawSwallows(in: &ctx, size: size, t: t, night: look.night)
        drawHawks(in: &ctx, size: size, t: t, look: look, frame: frame)

        ctx.drawLayer { land in
            drawFarHills(in: &land, size: size, t: t, look: look, frame: frame)
            WeatherPainter.rainbow(in: &land, size: size, daylight: daylight, strength: WeatherPainter.rainbowChance(daylight))
            drawFields(in: &land, size: size, look: look, frame: frame)
            drawDustDevil(in: &land, size: size, t: t, look: look, frame: frame)
            drawShimmer(in: &land, size: size, t: t, look: look, frame: frame)
            WeatherPainter.dullLight(in: &land, size: size, daylight: daylight)
            DaylightPainter.lowSunGrade(in: &land, size: size, daylight: daylight)
            // The fields already darken with the scene's night; this only adds the moonlit blue.
            DaylightPainter.nightGrade(in: &land, size: size, daylight: daylight, strength: 0.4)
        }
        DaylightPainter.fireflies(in: &ctx, size: size, time: time, daylight: daylight, season: 0.45, top: 0.75)
        if dark {
            drawFlare(in: &ctx, size: size, frame: frame, day: day)
        }
        WeatherPainter.foreground(in: &ctx, size: size, time: time, daylight: daylight)
    }

    static func makeFrame(size: CGSize, t: CGFloat, look: AugustModel.Look, daylight: SceneDaylight) -> AugustFrame {
        // The real sun: rising at the left, highest at noon, setting at the right.
        let sun = daylight.sunPoint(in: size)
        let sunFade = daylight.sunUp * (1 - 0.8 * (daylight.weather?.cover ?? 0))

        var clouds: [AugustCloud] = []
        clouds.reserveCapacity(6)
        var cover: CGFloat = 0
        for k in 0..<6 {
            let depth = CGFloat(k) / 5
            // Each cloud billows up, lives a couple of minutes and dissipates; it only
            // moves to a new spot while it is invisible.
            let period = BG.hash(k, 401, 120, 180)
            let position = t / period + BG.hash(k, 402)
            let cycle = Int(floor(position))
            let life = BG.fract(position)
            let seed = k * 1000 + cycle
            let width = BG.lerp(220, 420, depth) * BG.hash(seed, 403, 0.85, 1.15)
            let fade = BG.smoothstep(0, 0.2, life) * (1 - BG.smoothstep(0.75, 1, life))
            let x = BG.wrap(
                BG.hash(seed, 404) * size.width + look.drift * BG.lerp(0.35, 0.9, depth),
                length: size.width,
                margin: width * 0.7
            )
            let y = size.height * BG.hash(seed, 405, 0.07, 0.25)
            let opacity = Double(BG.lerp(0.55, 0.9, depth) * fade)
            let cloud = AugustCloud(
                center: CGPoint(x: x, y: y),
                width: width,
                opacity: opacity,
                seed: seed,
                depth: depth,
                grow: BG.smoothstep(0, 0.45, life)
            )
            clouds.append(cloud)

            // How much of the sun this cloud hides (elliptical footprint of the body).
            let dx = (sun.x - x) / (width * 0.42)
            let dy = (sun.y - y) / (width * 0.2)
            let d = sqrt(dx * dx + dy * dy)
            cover = max(cover, CGFloat(opacity) * (1 - BG.smoothstep(0.45, 1.05, d)))
        }
        let sunlight = 1 - 0.85 * cover
        let heat = AugustAir.thermal(t) * (0.35 + 0.65 * sunlight) * (1 - look.night)
        return AugustFrame(sun: sun, sunFade: sunFade, sunlight: sunlight, heat: heat, clouds: clouds)
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, dark: Bool) {
        let night = Double(look.night)
        let warm = Double(look.shortDay)
        let sky = Gradient(stops: [
            .init(color: BG.rgb(0.3, 0.55, 0.92, 0.2 * (1 - night)), location: 0),
            .init(color: BG.rgb(0.55, 0.75, 0.98, 0.08 * (1 - night)), location: 0.4),
            .init(color: BG.rgb(1, 0.88 - 0.06 * warm, 0.68, 0.16), location: 0.86),
            .init(color: BG.rgb(1, 0.8, 0.55, 0.2), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.93, 0.72), intensity: 0.16 * (1 - night), depth: 0.45)

        guard night > 0.01 else { return }
        // Perseid dusk.
        let dusk = (dark ? 0.3 : 0.15) * night
        let gradient = Gradient(stops: [
            .init(color: BG.rgb(0.18, 0.22, 0.4, dusk), location: 0),
            .init(color: BG.rgb(0.25, 0.25, 0.45, dusk * 0.7), location: 0.6),
            .init(color: BG.rgb(0.75, 0.45, 0.35, dusk * 0.5), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        AtmospherePainter.stars(in: &ctx, size: size, time: Double(t), count: 60, skyFraction: 0.55, intensity: 0.75 * night)
    }

    /// Perseids: meteors falling away from a radiant just past the top-right corner.
    static func drawMeteors(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, night: CGFloat) {
        guard night > 0.02 else { return }
        let radiant = CGPoint(x: size.width * 0.93, y: -size.height * 0.06)
        let period: CGFloat = 1.6
        for s in 0..<2 {
            let position = t / period + BG.hash(s, 461)
            let cycle = Int(floor(position))
            let seed = cycle * 2 + s
            guard BG.hash(seed, 462) < 0.55 else { continue }
            let life = BG.hash(seed, 463, 0.6, 1.0)
            let age = BG.fract(position) * period
            guard age < life else { continue }
            let u = age / life
            let angle = BG.hash(seed, 464, 1.95, 2.85)
            let dir = CGVector(dx: cos(angle), dy: sin(angle))
            let length = BG.hash(seed, 466, 120, 260)
            let speed = length * 1.8
            let headDistance = BG.hash(seed, 465, 0.12, 0.5) * size.width + speed * age
            let head = CGPoint(x: radiant.x + dir.dx * headDistance, y: radiant.y + dir.dy * headDistance)
            let trail = min(length, speed * age)
            let tail = CGPoint(x: head.x - dir.dx * trail, y: head.y - dir.dy * trail)
            let alpha = Double(sin(u * .pi) * night)
            var streak = Path()
            streak.move(to: tail)
            streak.addLine(to: head)
            ctx.stroke(
                streak,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.8, 1, 0.9, 0), BG.rgb(0.9, 1, 0.95, 0.8 * alpha)]),
                    startPoint: tail,
                    endPoint: head
                ),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
            )
            ctx.glow(at: head, radius: 9, color: BG.rgb(0.75, 1, 0.85), intensity: 0.8 * alpha, additive: true)
        }
    }

    // MARK: Clouds

    static func drawCloud(_ cloud: AugustCloud, in ctx: inout GraphicsContext, t: CGFloat, frame: AugustFrame, look: AugustModel.Look, dark: Bool) {
        guard cloud.opacity > 0.01 else { return }
        let w = cloud.width
        // Billowing: puffs swell up as the cloud forms and breathe while it lives.
        let base = CloudPainter.cumulusPuffs(seed: cloud.seed % 997 + 100, width: w)
        var puffs: [CloudPainter.Puff] = []
        puffs.reserveCapacity(base.count + 2)
        for (i, puff) in base.enumerated() {
            let swell = 1 + (0.03 + 0.05 * frame.heat) * sin(t * 0.17 + CGFloat(i) * 1.7 + CGFloat(cloud.seed % 7))
            puffs.append(CloudPainter.Puff(
                offset: CGPoint(x: puff.offset.x, y: puff.offset.y * (0.6 + 0.4 * cloud.grow)),
                radius: puff.radius * (0.55 + 0.45 * cloud.grow) * swell
            ))
        }
        if cloud.depth > 0.7 {
            // Towering tops on the nearest clouds.
            let rise = w * 0.24 * cloud.grow
            puffs.append(CloudPainter.Puff(offset: CGPoint(x: w * 0.04, y: -rise), radius: w * 0.15 * cloud.grow))
            puffs.append(CloudPainter.Puff(offset: CGPoint(x: -w * 0.08, y: -rise * 0.6), radius: w * 0.13 * cloud.grow))
        }

        // Far clouds are hazier (atmospheric perspective).
        let haze = Double(1 - cloud.depth) * 0.3
        let palette = CloudPalette(
            light: BG.rgb(1, 1, 1),
            body: BG.rgb(0.95 - 0.02 * haze, 0.96, 0.99),
            shade: dark ? BG.rgb(0.72 + 0.15 * haze, 0.77 + 0.12 * haze, 0.88 + 0.06 * haze) : BG.rgb(0.6, 0.66, 0.78)
        )
        let night = Double(look.night)
        CloudPainter.draw(
            in: &ctx,
            puffs: puffs,
            center: cloud.center,
            width: w,
            palette: palette,
            opacity: cloud.opacity * (1 - 0.45 * night),
            lightDirection: CGVector(dx: frame.sun.x - cloud.center.x, dy: frame.sun.y - cloud.center.y),
            softness: BG.lerp(0.05, 0.025, cloud.depth)
        )

        // Silver lining on the edge facing the sun when it passes close.
        let dx = frame.sun.x - cloud.center.x
        let dy = frame.sun.y - cloud.center.y
        let distance = max(1, sqrt(dx * dx + dy * dy))
        let near = 1 - BG.smoothstep(w * 0.3, w * 0.95, distance)
        let lining = Double(near * frame.sunFade) * cloud.opacity * (1 - night)
        if lining > 0.01 {
            let edge = CGPoint(x: cloud.center.x + dx / distance * w * 0.36, y: cloud.center.y + dy / distance * w * 0.16)
            ctx.glow(at: edge, radius: w * 0.32, color: BG.rgb(1, 0.97, 0.85), intensity: 0.55 * lining, additive: true)
        }
    }

    /// On hot days a cumulus at the edge of the sky towers into an anvil-topped
    /// thunderhead over about ten minutes, then slowly melts away.
    static func drawThunderhead(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, frame: AugustFrame, dark: Bool) {
        guard look.hot > 0.01 else { return }
        let period: CGFloat = 900
        let position = t / period + 0.15
        let cycle = Int(floor(position))
        let life = BG.fract(position)
        let build = BG.smoothstep(0.02, 0.68, life)
        let fade = BG.smoothstep(0, 0.06, life) * (1 - BG.smoothstep(0.8, 1, life))
        let opacity = Double(fade * look.hot * (1 - look.night)) * 0.85
        guard opacity > 0.01 else { return }

        let leftSide = BG.hash(cycle, 410) < 0.5
        let w: CGFloat = min(size.width * 0.26, 340)
        let base = CGPoint(x: leftSide ? size.width * 0.1 : size.width * 0.9, y: size.height * 0.31)
        let height = size.height * 0.27 * build

        var puffs: [CloudPainter.Puff] = []
        puffs.reserveCapacity(20)
        // Broad flat base.
        for i in 0..<5 {
            let u = CGFloat(i) / 4 - 0.5
            puffs.append(CloudPainter.Puff(offset: CGPoint(x: u * w * 0.8, y: 0), radius: w * BG.hash(i, 411, 0.15, 0.2)))
        }
        // The tower: stacked puffs narrowing slightly with height.
        for i in 0..<8 {
            let u = CGFloat(i) / 7
            let wobble = sin(t * 0.05 + CGFloat(i) * 1.9) * w * 0.02
            puffs.append(CloudPainter.Puff(
                offset: CGPoint(x: BG.hash(i, 412, -0.12, 0.12) * w + wobble, y: -u * height),
                radius: w * BG.lerp(0.22, 0.16, u) * BG.hash(i, 413, 0.9, 1.1)
            ))
        }
        // Anvil spreading out along the top once the tower is tall.
        let anvil = BG.smoothstep(0.55, 1, build)
        if anvil > 0.01 {
            for i in 0..<6 {
                let u = CGFloat(i) / 5 - 0.5
                let reach = u * w * (0.5 + 1.1 * anvil)
                puffs.append(CloudPainter.Puff(offset: CGPoint(x: reach, y: -height - w * 0.05), radius: w * 0.11 * (0.6 + 0.4 * anvil)))
            }
        }
        let palette = CloudPalette(
            light: BG.rgb(1, 0.99, 0.96),
            body: BG.rgb(0.9, 0.91, 0.95),
            shade: dark ? BG.rgb(0.5, 0.55, 0.68) : BG.rgb(0.45, 0.5, 0.62)
        )
        CloudPainter.draw(
            in: &ctx,
            puffs: puffs,
            center: base,
            width: w,
            palette: palette,
            opacity: opacity,
            lightDirection: CGVector(dx: frame.sun.x - base.x, dy: frame.sun.y - base.y + height * 0.5),
            softness: 0.035
        )
    }

    // MARK: Sky life

    /// A hot-air balloon drifting high across the sky every few minutes.
    static func drawBalloon(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, frame: AugustFrame, day: CGFloat) {
        let period: CGFloat = 330
        let position = t / period + 0.62
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.6
        guard local < span, day > 0.01 else { return }
        let u = local / span
        let leftToRight = BG.hash(cycle, 420) < 0.5
        let travel = u * (size.width + 160)
        let p = CGPoint(
            x: leftToRight ? -80 + travel : size.width + 80 - travel,
            y: size.height * BG.hash(cycle, 421, 0.1, 0.2) + sin(u * 7) * 6
        )
        let s = BG.hash(cycle, 422, 26, 36)
        let fade = Double(BG.smoothstep(0, 0.04, u) * (1 - BG.smoothstep(0.96, 1, u)) * day)
        let stripes: [Color] = BG.hash(cycle, 423) < 0.5
            ? [BG.rgb(0.95, 0.3, 0.25), BG.rgb(1, 0.85, 0.3)]
            : [BG.rgb(0.25, 0.5, 0.95), BG.rgb(0.98, 0.95, 0.9)]

        var balloon = ctx
        balloon.opacity = fade * 0.9
        balloon.translateBy(x: p.x, y: p.y)
        balloon.rotate(by: .radians(Double(sin(t * 0.4 + CGFloat(cycle)) * 0.04)))
        balloon.scaleBy(x: s, y: s)

        // Envelope: striped with hard stops, then shaded toward the sun.
        var stops: [Gradient.Stop] = []
        for i in 0..<8 {
            let color = stripes[i % 2]
            stops.append(.init(color: color, location: CGFloat(i) / 8))
            stops.append(.init(color: color, location: CGFloat(i + 1) / 8 - 0.001))
        }
        balloon.fill(AugustArt.envelope, with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: -0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 0)))
        let toSun = CGVector(dx: frame.sun.x - p.x, dy: frame.sun.y - p.y)
        let length = max(1, sqrt(toSun.dx * toSun.dx + toSun.dy * toSun.dy))
        let hot = CGPoint(x: toSun.dx / length * 0.22, y: -0.2 + toSun.dy / length * 0.1)
        balloon.fill(
            AugustArt.envelope,
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0), Color.black.opacity(0.3)]),
                center: hot, startRadius: 0, endRadius: 0.75
            )
        )
        var ropes = Path()
        ropes.move(to: CGPoint(x: -0.17, y: 0.36))
        ropes.addLine(to: CGPoint(x: -0.08, y: 0.6))
        ropes.move(to: CGPoint(x: 0.17, y: 0.36))
        ropes.addLine(to: CGPoint(x: 0.08, y: 0.6))
        balloon.stroke(ropes, with: .color(BG.rgb(0.3, 0.22, 0.15, 0.8)), lineWidth: 0.025)
        balloon.fill(Path(CGRect(x: -0.09, y: 0.6, width: 0.18, height: 0.14)), with: .color(BG.rgb(0.45, 0.3, 0.16)))
        // The burner fires now and then.
        let burn = pow(max(0, sin(t * 0.5 + CGFloat(cycle))), 16)
        if burn > 0.02 {
            balloon.glow(at: CGPoint(x: 0, y: 0.48), radius: 0.18, color: BG.rgb(1, 0.7, 0.3), intensity: Double(burn) * 0.9, additive: true)
        }
    }

    /// A loose flock of swallows crossing far away, flapping with short glides.
    static func drawSwallows(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, night: CGFloat) {
        let alpha = Double(1 - night) * 0.55
        guard alpha > 0.01 else { return }
        var flock = Path()
        for i in 0..<6 {
            let duration = BG.hash(i, 141, 40, 70)
            let progress = BG.fract(BG.hash(i, 142) + t / duration)
            let rightward = i % 3 != 0
            let x = rightward ? -40 + progress * (size.width + 80) : size.width + 40 - progress * (size.width + 80)
            let y = size.height * BG.hash(i, 143, 0.18, 0.4) + sin(t * 0.4 + CGFloat(i)) * 14
            let span = BG.hash(i, 144, 8, 14)
            let gliding = BG.smoothstep(0.2, 0.6, sin(t * 0.35 + CGFloat(i) * 2.3))
            let beat = sin(t * BG.hash(i, 145, 4, 6) * 1.6 + CGFloat(i)) * (1 - gliding)
            let wingY = beat * span * 0.4 + gliding * span * 0.1
            flock.move(to: CGPoint(x: x - span, y: y + wingY))
            flock.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - span * 0.5, y: y - span * 0.35 + wingY * 0.3))
            flock.addQuadCurve(to: CGPoint(x: x + span, y: y + wingY), control: CGPoint(x: x + span * 0.5, y: y - span * 0.35 + wingY * 0.3))
        }
        ctx.stroke(flock, with: .color(BG.rgb(0.2, 0.22, 0.3, alpha)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    }

    /// Hawks riding the thermals near the edges: wide circles that tighten and lift
    /// when the thermal is strong.
    static func drawHawks(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, frame: AugustFrame) {
        let alpha = Double(1 - look.night) * 0.7
        guard alpha > 0.01 else { return }
        let columns: [(x: CGFloat, y: CGFloat)] = [(0.12, 0.34), (0.12, 0.3), (0.86, 0.36)]
        for k in 0..<3 {
            let column = columns[k]
            let dir: CGFloat = k == 2 ? -1 : 1
            let angle = dir * t * BG.hash(k, 430, 0.22, 0.3) + BG.hash(k, 431) * 6.28
            let radius = BG.hash(k, 432, 45, 70) * (1 - 0.25 * frame.heat)
            let lift = frame.heat * 24
            let center = CGPoint(
                x: size.width * column.x + sin(t * 0.03 + CGFloat(k)) * 20,
                y: size.height * column.y - lift - sin(t * 0.05 + CGFloat(k) * 2) * 10
            )
            let p = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius * 0.32)
            let velocityX = -sin(angle) * dir
            let span = BG.hash(k, 433, 26, 34)
            // Mostly soaring, with a few quick flaps now and then.
            let flapping = pow(max(0, sin(t * 0.21 + CGFloat(k) * 2.4)), 10)
            let flap = sin(t * 9 + CGFloat(k)) * flapping

            var hawk = ctx
            hawk.opacity = alpha
            hawk.translateBy(x: p.x, y: p.y)
            hawk.rotate(by: .radians(Double(cos(angle) * 0.22 * dir)))
            hawk.scaleBy(x: span * (0.7 + 0.3 * abs(velocityX)) * (velocityX >= 0 ? 1 : -1), y: span * (1 + 0.9 * flap))
            hawk.fill(AugustArt.hawk, with: .color(BG.rgb(0.2, 0.15, 0.13)))
        }
    }

    // MARK: Land

    static func hillY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.915 + 0.012 * sin(u * 5.3 + 0.8) + 0.007 * sin(u * 13 + 2.1))
    }

    static func fieldY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.948 + 0.01 * sin(u * 3.7 + 2.4) + 0.005 * sin(u * 9.1))
    }

    static func landPath(size: CGSize, top: (CGFloat) -> CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            path.addLine(to: CGPoint(x: x, y: top(x)))
            x += 20
        }
        path.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        path.closeSubpath()
        return path
    }

    /// Hazy distant hills with a few round trees near the edges, and a heat mirage
    /// wavering along their crest.
    static func drawFarHills(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, frame: AugustFrame) {
        let hills = landPath(size: size) { hillY($0, size: size) }
        let top = size.height * 0.89
        ctx.fill(
            hills,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.45, 0.6, 0.55, 0.32), BG.rgb(0.4, 0.55, 0.35, 0.42)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        var trees = Path()
        for i in 0..<9 {
            let u = BG.hash(i, 440)
            let x = (u < 0.5 ? u * 0.5 : 0.75 + (u - 0.5) * 0.5) * size.width
            let r = BG.hash(i, 441, 7, 13)
            let y = hillY(x, size: size)
            trees.addPath(BG.ellipse(CGPoint(x: x, y: y - r * 0.7), r, r * 0.85))
            trees.addPath(Path(CGRect(x: x - 1.2, y: y - r * 0.2, width: 2.4, height: r * 0.5)))
        }
        ctx.fill(trees, with: .color(BG.rgb(0.22, 0.35, 0.22, 0.5)))

        // Mirage: a pale wavering band hugging the horizon, strongest in strong heat.
        let mirage = Double(frame.heat * look.shimmer) * 0.16
        if mirage > 0.005 {
            let y = size.height * 0.905 + sin(t * 1.3) * 1.5
            let band = CGRect(x: 0, y: y - 6, width: size.width, height: 12)
            ctx.fill(
                Path(band),
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.95, 0.97, 1, 0), BG.rgb(0.95, 0.97, 1, mirage), BG.rgb(0.95, 0.97, 1, 0)]),
                    startPoint: CGPoint(x: 0, y: band.minY),
                    endPoint: CGPoint(x: 0, y: band.maxY)
                )
            )
        }
    }

    /// Golden fields along the bottom, with cloud shadows sweeping across them and the
    /// light dimming whenever the sun goes in.
    static func drawFields(in ctx: inout GraphicsContext, size: CGSize, look: AugustModel.Look, frame: AugustFrame) {
        let field = landPath(size: size) { fieldY($0, size: size) }
        let top = size.height * 0.935
        ctx.fill(
            field,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.95, 0.8, 0.42, 0.55), BG.rgb(0.72, 0.55, 0.22, 0.7)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Hay bales at the edges.
        for i in 0..<4 {
            let x = size.width * (i < 2 ? 0.04 + CGFloat(i) * 0.07 : 0.86 + CGFloat(i - 2) * 0.08)
            let r = BG.hash(i, 445, 8, 11)
            let c = CGPoint(x: x, y: fieldY(x, size: size) + r * 0.9)
            ctx.fill(BG.ellipse(CGPoint(x: c.x + 3, y: c.y + r * 0.85), r * 1.1, r * 0.25), with: .color(BG.rgb(0.35, 0.25, 0.1, 0.35)))
            ctx.fill(
                BG.circle(c, r),
                with: .radialGradient(
                    Gradient(colors: [BG.rgb(1, 0.88, 0.55), BG.rgb(0.78, 0.6, 0.28)]),
                    center: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.35), startRadius: 0, endRadius: r * 1.3
                )
            )
            ctx.stroke(BG.circle(c, r * 0.55), with: .color(BG.rgb(0.6, 0.45, 0.2, 0.5)), lineWidth: 1)
        }

        // Cloud shadows, cast away from the sun and clipped to the land.
        let night = look.night
        var land = ctx
        land.clip(to: landPath(size: size) { hillY($0, size: size) })
        land.blurredLayer(radius: 18) { shade in
            for cloud in frame.clouds where cloud.opacity > 0.02 {
                let x = cloud.center.x - (frame.sun.x - cloud.center.x) * 0.15
                let c = CGPoint(x: x, y: size.height * 0.95)
                let alpha = cloud.opacity * 0.32 * Double(frame.sunFade * (1 - night))
                shade.fill(BG.ellipse(c, cloud.width * 0.42, size.height * 0.035), with: .color(BG.rgb(0.2, 0.22, 0.3, alpha)))
            }
            // The whole landscape dims a little while the sun is behind a cloud.
            let dim = Double(1 - frame.sunlight) * 0.18 + Double(night) * 0.3
            if dim > 0.005 {
                shade.fill(Path(CGRect(x: 0, y: size.height * 0.85, width: size.width, height: size.height * 0.15)), with: .color(BG.rgb(0.15, 0.17, 0.25, dim)))
            }
        }
    }

    /// Now and then a strong thermal spins up a dust devil over the fields near an edge.
    static func drawDustDevil(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, frame: AugustFrame) {
        let period: CGFloat = 52
        let position = t / period + 0.3
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.18
        guard local < span, BG.hash(cycle, 450) < 0.6 else { return }
        // Only when the ground was hot as the devil began.
        let start = CGFloat(cycle) * period - 0.3 * period
        guard AugustAir.thermal(start) > 0.35, look.night < 0.5 else { return }
        let u = local / span
        let fade = Double(sin(u * .pi)) * Double(1 - look.night)
        let side = BG.hash(cycle, 451)
        let baseX = (side < 0.5 ? BG.lerp(0.05, 0.25, side * 2) : BG.lerp(0.75, 0.95, (side - 0.5) * 2)) * size.width + u * 40
        let ground = fieldY(baseX, size: size) + 4
        let height = size.height * 0.1 * (0.6 + 0.4 * sin(u * .pi))

        ctx.blurredLayer(radius: 5) { haze in
            for j in 0..<4 {
                let f = CGFloat(j) / 3
                let c = CGPoint(x: baseX + sin(t * 2 + f * 3) * 4, y: ground - f * height)
                haze.fill(BG.ellipse(c, 5 + 14 * f, 6 + 4 * f), with: .color(BG.rgb(0.85, 0.72, 0.5, 0.18 * fade)))
            }
        }
        var dust = Path()
        for k in 0..<18 {
            let f = BG.fract(BG.hash(k, 452) + u * 1.5)
            let angle = t * 5 + CGFloat(k) * 0.9 + f * 8
            let radius = 4 + 18 * f
            let p = CGPoint(x: baseX + cos(angle) * radius, y: ground - f * height + sin(angle) * radius * 0.2)
            dust.addPath(BG.circle(p, BG.hash(k, 453, 0.8, 1.8)))
        }
        ctx.fill(dust, with: .color(BG.rgb(0.6, 0.48, 0.3, 0.6 * fade)))
    }

    /// Heat shimmer: faint wavering lines of hot air rising off the ground.
    static func drawShimmer(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AugustModel.Look, frame: AugustFrame) {
        let strength = frame.heat * look.shimmer
        guard strength > 0.02 else { return }
        let band = size.height * 0.18
        var lines = Path()
        for i in 0..<9 {
            let progress = BG.fract(BG.hash(i, 455) + t * 20 / band)
            let y0 = size.height - progress * band
            let amplitude = (1 + 1.5 * strength) * (1 - progress * 0.5)
            let phase = BG.hash(i, 456) * 6.28
            var x: CGFloat = 0
            lines.move(to: CGPoint(x: 0, y: y0 + sin(phase + t * 2.2) * amplitude))
            while x < size.width {
                x += 24
                lines.addLine(to: CGPoint(x: x, y: y0 + sin(x * 0.031 + phase + t * 2.2) * amplitude + sin(x * 0.083 - t * 1.4) * amplitude * 0.5))
            }
        }
        ctx.stroke(lines, with: .color(BG.rgb(1, 0.97, 0.9, Double(0.07 * strength))), lineWidth: 1)
    }

    // MARK: Post

    /// Lens flare ghosts along the sun-to-centre axis, dimmed when a cloud covers the sun.
    static func drawFlare(in ctx: inout GraphicsContext, size: CGSize, frame: AugustFrame, day: CGFloat) {
        let strength = Double(frame.sunlight * frame.sunlight * frame.sunFade * day)
        guard strength > 0.02 else { return }
        let c = frame.sun
        let axis = CGVector(dx: size.width / 2 - c.x, dy: size.height / 2 - c.y)
        let ghosts: [(CGFloat, CGFloat, Color)] = [
            (0.55, 0.22, BG.rgb(1, 0.85, 0.5)),
            (0.95, 0.12, BG.rgb(0.6, 1, 0.75)),
            (1.3, 0.38, BG.rgb(0.55, 0.75, 1)),
            (1.75, 0.18, BG.rgb(1, 0.6, 0.8))
        ]
        for (k, scale, color) in ghosts {
            let p = CGPoint(x: c.x + axis.dx * k, y: c.y + axis.dy * k)
            let r = sunRadius * scale * 2
            ctx.fill(
                BG.circle(p, r),
                with: .radialGradient(
                    Gradient(colors: [color.opacity(0), color.opacity(0.12 * strength), color.opacity(0.03 * strength), color.opacity(0)]),
                    center: p, startRadius: 0, endRadius: r
                )
            )
        }
        // A faint anamorphic streak through the sun.
        let streak = CGRect(x: c.x - sunRadius * 6, y: c.y - 1.5, width: sunRadius * 12, height: 3)
        ctx.fill(
            Path(ellipseIn: streak),
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.7, 0.85, 1, 0), BG.rgb(0.85, 0.92, 1, 0.22 * strength), BG.rgb(0.7, 0.85, 1, 0)]),
                startPoint: CGPoint(x: streak.minX, y: c.y),
                endPoint: CGPoint(x: streak.maxX, y: c.y)
            )
        )
    }
}

// MARK: - Art

private enum AugustArt {
    /// Balloon envelope (about 1 unit tall, mouth at the bottom).
    static let envelope: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.12, y: 0.4))
        path.addCurve(to: CGPoint(x: -0.42, y: -0.18), control1: CGPoint(x: -0.3, y: 0.22), control2: CGPoint(x: -0.42, y: 0.06))
        path.addCurve(to: CGPoint(x: 0.42, y: -0.18), control1: CGPoint(x: -0.42, y: -0.6), control2: CGPoint(x: 0.42, y: -0.6))
        path.addCurve(to: CGPoint(x: 0.12, y: 0.4), control1: CGPoint(x: 0.42, y: 0.06), control2: CGPoint(x: 0.3, y: 0.22))
        path.closeSubpath()
        return path
    }()

    /// Soaring hawk silhouette (wingspan 1), facing +x.
    static let hawk: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.5, y: 0.03))
        path.addQuadCurve(to: CGPoint(x: -0.06, y: -0.04), control: CGPoint(x: -0.28, y: -0.1))
        path.addQuadCurve(to: CGPoint(x: 0.12, y: -0.02), control: CGPoint(x: 0.04, y: -0.08))
        path.addQuadCurve(to: CGPoint(x: 0.06, y: -0.04), control: CGPoint(x: 0.1, y: -0.05))
        path.addQuadCurve(to: CGPoint(x: 0.5, y: 0.03), control: CGPoint(x: 0.28, y: -0.1))
        path.addQuadCurve(to: CGPoint(x: 0.07, y: 0.04), control: CGPoint(x: 0.26, y: 0))
        path.addLine(to: CGPoint(x: 0.0, y: 0.06))
        path.addLine(to: CGPoint(x: -0.16, y: 0.08))
        path.addLine(to: CGPoint(x: -0.14, y: 0.02))
        path.addQuadCurve(to: CGPoint(x: -0.5, y: 0.03), control: CGPoint(x: -0.3, y: 0))
        path.closeSubpath()
        return path
    }()
}
