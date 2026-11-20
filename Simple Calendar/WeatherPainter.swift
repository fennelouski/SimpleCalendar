//
//  WeatherPainter.swift
//  Simple Calendar
//
//  Real weather drawn over any month's scene: a cloud deck, rain with splashes, snow,
//  sleet, fog, lightning and the dull light of an overcast day. Each effect scales from
//  nothing, so the scene eases between states as the forecast hour changes.
//

import SwiftUI

enum WeatherPainter {

    // MARK: Sky (drawn behind the land)

    /// A deck of cloud drifting with the wind; lit from the sun by day, dim blue at night,
    /// slate grey and lower in a storm.
    static func cloudDeck(in ctx: inout GraphicsContext, size: CGSize, time: Double, daylight: SceneDaylight, seed: Int = 0) {
        guard let weather = daylight.weather else { return }
        let amount = Double(weather.overcast)
        guard amount > 0.02 else { return }
        let storm = Double(max(weather.storm, weather.rain * 0.6))
        let light = Double(daylight.light)
        let palette = CloudPalette(
            light: mixColor((0.82, 0.85, 0.95), (0.95 - 0.2 * storm, 0.95 - 0.18 * storm, 0.97 - 0.12 * storm), light),
            body: mixColor((0.3, 0.32, 0.42), (0.8 - 0.3 * storm, 0.82 - 0.29 * storm, 0.86 - 0.25 * storm), light),
            shade: mixColor((0.12, 0.12, 0.2), (0.55 - 0.25 * storm, 0.58 - 0.25 * storm, 0.66 - 0.24 * storm), light)
        )
        let sun = daylight.elevation > -4 ? daylight.sunPoint(in: size) : daylight.moonPoint(in: size)
        let drift = CGFloat(time) * (6 + weather.push * 2.2)
        let count = 6 + Int(4 * amount)
        for k in 0..<count {
            let depth = CGFloat(k) / CGFloat(max(count - 1, 1))
            let id = k + seed * 31
            let width: CGFloat = BG.lerp(520, 900, depth) * BG.hash(id, 721, 0.85, 1.15)
            let start: CGFloat = BG.hash(id, 722) * size.width
            let offset: CGFloat = drift * BG.lerp(0.4, 1, depth)
            let x = BG.wrap(start + offset, length: size.width, margin: width * 0.6)
            let lowest: CGFloat = 0.14 + 0.08 * CGFloat(storm)
            let y: CGFloat = size.height * BG.hash(id, 723, -0.06, lowest)
            CloudPainter.draw(
                in: &ctx, puffs: CloudPainter.cumulusPuffs(seed: k + 900 + seed, width: width), center: CGPoint(x: x, y: y),
                width: width, palette: palette, opacity: amount * Double(BG.lerp(0.45, 0.8, depth)),
                lightDirection: CGVector(dx: sun.x - x, dy: sun.y - y), softness: 0.06
            )
        }
    }

    // MARK: Over the whole scene

    /// Greys and darkens a dull or stormy day; call inside the scene's land layer.
    static func dullLight(in ctx: inout GraphicsContext, size: CGSize, daylight: SceneDaylight) {
        guard let weather = daylight.weather else { return }
        let amount = Double(weather.overcast) * 0.28 + Double(weather.storm) * 0.22 + Double(weather.rain) * 0.1
        guard amount > 0.01 else { return }
        var grade = ctx
        grade.blendMode = .sourceAtop
        grade.fill(Path(CGRect(origin: .zero, size: size)), with: .color(BG.rgb(0.33, 0.36, 0.42, amount * Double(0.4 + 0.6 * daylight.light))))
    }

    /// Precipitation, fog and lightning in front of the scene.
    /// `nativeSnow` / `nativeRain`: the scene already draws that precipitation from the weather.
    static func foreground(in ctx: inout GraphicsContext, size: CGSize, time: Double, daylight: SceneDaylight, nativeSnow: Bool = false, nativeRain: Bool = false) {
        guard let weather = daylight.weather else { return }
        fog(in: &ctx, size: size, time: time, weather: weather, daylight: daylight)
        let rain = weather.rain * (weather.sleet ? 0.6 : 1)
        if rain > 0.01, !nativeRain { self.rain(in: &ctx, size: size, time: time, amount: rain, weather: weather, daylight: daylight) }
        if weather.snow > 0.01, !nativeSnow {
            SnowRenderer.draw(in: &ctx, size: size, time: time, density: 0.25 + 1.6 * weather.snow, wind: weather.push * 1.5)
        }
        lightning(in: &ctx, size: size, time: time, weather: weather)
    }

    static func rain(in ctx: inout GraphicsContext, size: CGSize, time: Double, amount: CGFloat, weather: SceneWeather, daylight: SceneDaylight) {
        let t = CGFloat(time)
        let count = Int(40 + 300 * amount)
        let slant = min(weather.push / 22, 0.7)
        let alphaScale = Double(0.45 + 0.55 * daylight.light)
        for i in 0..<count {
            let depth = BG.hash(i, 731)
            let speed = BG.lerp(850, 1500, depth)
            let length = BG.lerp(14, 38, depth) * (0.7 + 0.6 * amount)
            let travel = size.height + 80
            let y = BG.fract(BG.hash(i, 732) + t * speed / travel) * travel - 40
            let start: CGFloat = BG.hash(i, 733) * size.width
            let x = BG.wrap(start + (y + 40) * slant, length: size.width, margin: 40)
            var drop = Path()
            drop.move(to: CGPoint(x: x, y: y))
            drop.addLine(to: CGPoint(x: x - slant * length, y: y - length))
            let alpha = Double(BG.lerp(0.12, 0.34, depth)) * alphaScale
            ctx.stroke(drop, with: .color(BG.rgb(0.82, 0.87, 0.95, alpha)), style: StrokeStyle(lineWidth: BG.lerp(0.8, 1.8, depth), lineCap: .round))
        }
        // Splashes popping along the ground.
        let splashes = Int(12 + 60 * amount)
        for i in 0..<splashes {
            let period = BG.hash(i, 735, 0.35, 0.8)
            let phase = BG.fract(t / period + BG.hash(i, 736))
            guard phase < 0.35 else { continue }
            let cycle = Int(floor(t / period + BG.hash(i, 736)))
            let x = BG.hash(i * 97 + cycle, 737) * size.width
            let y = size.height * BG.hash(i * 97 + cycle, 738, 0.93, 0.995)
            let grow = phase / 0.35
            let r = 3 + 7 * grow
            ctx.stroke(BG.ellipse(CGPoint(x: x, y: y), r, r * 0.3),
                       with: .color(BG.rgb(0.85, 0.9, 0.97, Double(0.35 * (1 - grow)) * alphaScale)), lineWidth: 1)
        }
    }

    static func fog(in ctx: inout GraphicsContext, size: CGSize, time: Double, weather: SceneWeather, daylight: SceneDaylight) {
        let amount = Double(weather.fog)
        guard amount > 0.02 else { return }
        let light = Double(daylight.light)
        let tone = BG.rgb(0.1 + 0.72 * light, 0.11 + 0.73 * light, 0.15 + 0.72 * light)
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [tone.opacity(0.18 * amount), tone.opacity(0.55 * amount)]),
            startPoint: CGPoint(x: 0, y: size.height * 0.2), endPoint: CGPoint(x: 0, y: size.height)))
        ctx.blurredLayer(radius: 30) { bank in
            for i in 0..<4 {
                let start: CGFloat = BG.hash(i, 741) * size.width
                let drift: CGFloat = CGFloat(time) * BG.hash(i, 742, 4, 10)
                let x = BG.wrap(start + drift, length: size.width, margin: size.width * 0.35)
                let c = CGPoint(x: x, y: size.height * BG.hash(i, 743, 0.55, 0.92))
                let rx = size.width * BG.hash(i, 744, 0.3, 0.5)
                bank.fill(BG.ellipse(c, rx, size.height * 0.06), with: .color(tone.opacity(0.4 * amount)))
            }
        }
    }

    /// Distant flashes, now and then a visible bolt, roughly every 6–15 s in a storm.
    static func lightning(in ctx: inout GraphicsContext, size: CGSize, time: Double, weather: SceneWeather) {
        let storm = Double(weather.storm)
        guard storm > 0.05 else { return }
        let window = 7.0
        let cycle = Int(floor(time / window))
        guard Double(BG.hash(cycle, 751)) < 0.55 * storm else { return }
        let local = time - Double(cycle) * window - Double(BG.hash(cycle, 752)) * 4
        guard local >= 0, local < 0.6 else { return }
        // Two quick pulses, as real lightning flickers.
        let pulse = max(exp(-pow((local - 0.05) / 0.04, 2)), 0.7 * exp(-pow((local - 0.22) / 0.06, 2)))
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(BG.rgb(0.85, 0.88, 1, 0.32 * pulse * storm)))
        guard BG.hash(cycle, 753) < 0.45 else { return }
        var bolt = Path()
        var p = CGPoint(x: size.width * BG.hash(cycle, 754, 0.15, 0.85), y: 0)
        bolt.move(to: p)
        for step in 0..<9 {
            p = CGPoint(x: p.x + BG.hash(cycle * 13 + step, 755, -40, 40), y: p.y + size.height * 0.065)
            bolt.addLine(to: p)
        }
        ctx.stroke(bolt, with: .color(BG.rgb(0.95, 0.96, 1, 0.9 * pulse)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        ctx.glow(at: p, radius: 120, color: BG.rgb(0.8, 0.85, 1), intensity: 0.3 * pulse)
    }

    // MARK: Rainbow

    /// 0...1: a rainbow shows after a shower, with the sun out behind you and not too high.
    static func rainbowChance(_ daylight: SceneDaylight) -> CGFloat {
        guard let weather = daylight.weather else { return 0 }
        let showers = BG.smoothstep(0.02, 0.15, weather.rain) * (1 - BG.smoothstep(0.55, 0.85, weather.rain))
        let sunOut = daylight.sunUp * (1 - BG.smoothstep(0.6, 0.9, CGFloat(weather.cloud)))
        let lowSun = 1 - BG.smoothstep(32, 42, CGFloat(daylight.elevation))
        return showers * sunOut * lowSun
    }

    /// A rainbow arc opposite the sun, rising from behind the land.
    static func rainbow(in ctx: inout GraphicsContext, size: CGSize, daylight: SceneDaylight, strength: CGFloat) {
        let s = Double(strength)
        guard s > 0.01 else { return }
        let sun = daylight.sunPoint(in: size)
        let center = CGPoint(x: size.width - min(max(sun.x, size.width * 0.15), size.width * 0.85), y: size.height * 1.25)
        let radius = size.width * 0.9
        var arc = Path()
        for k in 0...48 {
            let a = CGFloat.pi + CGFloat.pi * CGFloat(k) / 48
            let p = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
            if k == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
        }
        let band: CGFloat = 28
        let colors: [Color] = [
            BG.rgb(0.6, 0.3, 0.9), BG.rgb(0.3, 0.4, 1), BG.rgb(0.2, 0.75, 0.9), BG.rgb(0.3, 0.85, 0.35),
            BG.rgb(1, 0.92, 0.3), BG.rgb(1, 0.6, 0.2), BG.rgb(1, 0.25, 0.25)
        ]
        var stops: [Gradient.Stop] = [.init(color: colors[0].opacity(0), location: 0)]
        for (k, color) in colors.enumerated() {
            stops.append(.init(color: color.opacity(0.18 * s), location: 0.08 + 0.84 * CGFloat(k) / CGFloat(colors.count - 1)))
        }
        stops.append(.init(color: colors[colors.count - 1].opacity(0), location: 1))
        ctx.stroke(arc, with: .radialGradient(Gradient(stops: stops), center: center, startRadius: radius - band / 2, endRadius: radius + band / 2), lineWidth: band)
    }

    private static func mixColor(_ night: (Double, Double, Double), _ day: (Double, Double, Double), _ f: Double) -> Color {
        BG.rgb(night.0 + (day.0 - night.0) * f, night.1 + (day.1 - night.1) * f, night.2 + (day.2 - night.2) * f)
    }
}
