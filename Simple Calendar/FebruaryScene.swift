//
//  FebruaryScene.swift
//  Simple Calendar
//
//  February: a blush-pink winter sky over a frozen park.
//
//  A slow heartbeat is the star. Its phase is integrated (so it can quicken toward
//  Valentine's Day without ever jumping), and each beat travels outward from the
//  middle of the screen: the heart-shaped clouds swell with it, the rising hearts'
//  glow and glass rims brighten, the horizon blush warms and the frozen pond's sheen
//  pulses, edge to edge, a moment later than the centre. Clouds slowly gather into
//  hearts and relax back into cumulus as they drift.
//
//  The scene also follows the selected day:
//    * romance     - closer to Feb 14 the clouds turn rosier, more of them become
//                    hearts, more hearts rise (the extra ones mostly glass) and the
//                    heartbeat quickens
//    * Valentine's - a one-shot heart shower bursting up from the bottom
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct FebruaryHeartCloudsAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = FebruaryModel()

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = FebruaryModel.Target(date: date)
        let state = model
        AnimatedScene(daylight: { ctx, size, time, daylight in
            let look = state.look(target: target, time: time)
            FebruaryScene.draw(in: &ctx, size: size, time: time, look: look, daylight: daylight)
        })
        .opacity(alpha)
    }
}

// MARK: - State

final class FebruaryModel {
    struct Target {
        /// 0 two weeks or more from Feb 14 ... 1 on Feb 14.
        let romance: Double
        let valentine: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            let distance = day.month == 2 ? Double(abs(day.day - 14)) : 14
            romance = 1 - min(max(distance / 14, 0), 1)
            valentine = day.month == 2 && day.day == 14 ? 1 : 0
        }
    }

    struct Look {
        var romance: CGFloat
        /// Breeze displacement accumulated since the scene appeared.
        var drift: CGFloat
        /// Heartbeats since the scene appeared (integrated, so the rate can change).
        var beat: CGFloat
        /// Seconds into the Valentine's heart shower, or -1.
        var showerAge: CGFloat

        /// Share of the clouds that gather into hearts.
        var heartShare: CGFloat { BG.lerp(0.4, 0.8, romance) }
    }

    static let showerDuration: Double = 12

    private let romanceTransition = SceneTransition()
    private let valentineTransition = SceneTransition()
    private let shower = SceneMoment(duration: FebruaryModel.showerDuration)
    private var drift: CGFloat = 0
    private var beat: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let romance = romanceTransition.value(target: target.romance, time: time)
        let valentine = valentineTransition.value(target: target.valentine, time: time)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * FebruaryAir.breeze(CGFloat(time))
            // About one beat every 9 s, quickening to one every 5.5 s on Feb 14.
            beat += dt * BG.lerp(0.11, 0.18, CGFloat(romance))
        }
        lastTime = time
        var showerAge: CGFloat = -1
        if let age = shower.elapsed(arrived: valentine > 0.999, time: time) {
            showerAge = CGFloat(age)
        }
        return Look(romance: CGFloat(romance), drift: drift, beat: beat, showerAge: showerAge)
    }
}

// MARK: - Air and heartbeat

private enum FebruaryAir {
    /// Gentle breeze, points per second (never reverses).
    static func breeze(_ t: CGFloat) -> CGFloat {
        4 + 2.5 * sin(t * 0.17) + 1.5 * sin(t * 0.43 + 1.1)
    }

    /// 0...1 heartbeat felt at `x`: a "lub" and a softer "dub", travelling outward from
    /// the centre of the screen.
    static func pulse(beat: CGFloat, x: CGFloat, width: CGFloat) -> CGFloat {
        let lag = abs(x - width / 2) / 400 * 0.15
        let f = BG.fract(beat - lag)
        func bump(_ c: CGFloat) -> CGFloat {
            let d = (f - c) / 0.035
            return exp(-d * d)
        }
        return min(1, bump(0.1) + 0.6 * bump(0.22))
    }
}

// MARK: - Art

private struct FebruaryBranchArt {
    var thick = Path()
    var mid = Path()
    var thin = Path()
}

private enum FebruaryArt {
    /// A bare tree about 1 unit tall, base at the origin.
    static let tree: FebruaryBranchArt = {
        var art = FebruaryBranchArt()
        func grow(from p: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, seed: Int) {
            let end = CGPoint(x: p.x + sin(angle) * length, y: p.y - cos(angle) * length)
            if depth <= 1 {
                art.thick.move(to: p)
                art.thick.addLine(to: end)
            } else if depth <= 3 {
                art.mid.move(to: p)
                art.mid.addLine(to: end)
            } else {
                art.thin.move(to: p)
                art.thin.addLine(to: end)
            }
            guard depth < 6 else { return }
            for c in 0..<2 {
                let childSeed = seed * 5 + c + 1
                let side: CGFloat = c == 0 ? -1 : 1
                let childAngle = angle + side * BG.hash(childSeed, 303, 0.3, 0.6) + BG.hash(childSeed, 304, -0.1, 0.1)
                grow(from: end, angle: childAngle, length: length * BG.hash(childSeed, 305, 0.66, 0.8), depth: depth + 1, seed: childSeed)
            }
        }
        grow(from: .zero, angle: 0.12, length: 0.3, depth: 0, seed: 61)
        return art
    }()

    /// Street lamp, 1 unit tall, base at the origin, lantern at the top.
    static let lamp: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.018, y: -0.86, width: 0.036, height: 0.86))
        path.addRect(CGRect(x: -0.06, y: -0.05, width: 0.12, height: 0.05))
        path.move(to: CGPoint(x: -0.08, y: -0.86))
        path.addLine(to: CGPoint(x: 0.08, y: -0.86))
        path.addLine(to: CGPoint(x: 0.06, y: -0.98))
        path.addLine(to: CGPoint(x: -0.06, y: -0.98))
        path.closeSubpath()
        path.move(to: CGPoint(x: -0.09, y: -0.98))
        path.addLine(to: CGPoint(x: 0, y: -1.04))
        path.addLine(to: CGPoint(x: 0.09, y: -0.98))
        path.closeSubpath()
        return path
    }()

    /// The right half of the unit heart (the shaded side of a folded paper heart).
    static let halfHeart: Path = Path(CGRect(x: 0, y: -0.6, width: 0.6, height: 1.2)).intersection(HeartGeometry.unitPath)

    /// A skater (about 1 unit tall, feet at the origin, facing +x).
    static let skater: Path = {
        var path = Path()
        path.addEllipse(in: CGRect(x: -0.08, y: -1.0, width: 0.16, height: 0.16))
        path.move(to: CGPoint(x: -0.1, y: -0.82))
        path.addLine(to: CGPoint(x: 0.12, y: -0.8))
        path.addLine(to: CGPoint(x: 0.16, y: -0.45))
        path.addLine(to: CGPoint(x: -0.16, y: -0.42))
        path.closeSubpath()
        path.move(to: CGPoint(x: -0.06, y: -0.44))
        path.addLine(to: CGPoint(x: 0.04, y: -0.44))
        path.addLine(to: CGPoint(x: 0.2, y: -0.02))
        path.addLine(to: CGPoint(x: 0.12, y: 0))
        path.closeSubpath()
        path.move(to: CGPoint(x: -0.04, y: -0.44))
        path.addLine(to: CGPoint(x: 0.04, y: -0.42))
        path.addLine(to: CGPoint(x: -0.32, y: -0.12))
        path.addLine(to: CGPoint(x: -0.36, y: -0.16))
        path.closeSubpath()
        return path
    }()
}

private enum FebruaryHeartLook {
    case candy, paper, glass
}

// MARK: - Scene

private enum FebruaryScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: FebruaryModel.Look, daylight: SceneDaylight) {
        let t = CGFloat(time)
        let dark = daylight.isDark
        let centerPulse = FebruaryAir.pulse(beat: look.beat, x: size.width / 2, width: size.width)
        let sun = daylight.sunPoint(in: size)
        let sunLight = Double(BG.smoothstep(-4, 3, CGFloat(daylight.elevation)) * (1 - (daylight.weather?.cover ?? 0)))

        ctx.drawLayer { sky in
            drawSky(in: &sky, size: size, look: look, pulse: centerPulse, sun: sun, sunLight: sunLight)
            DaylightPainter.lowSunGrade(in: &sky, size: size, daylight: daylight, strength: 1.2)
            DaylightPainter.nightGrade(in: &sky, size: size, daylight: daylight, strength: 0.9)
        }
        DaylightPainter.stars(in: &ctx, size: size, time: time, daylight: daylight)
        DaylightPainter.moon(in: &ctx, size: size, daylight: daylight)
        WeatherPainter.cloudDeck(in: &ctx, size: size, time: time, daylight: daylight, seed: 2)

        ctx.drawLayer { park in
            drawFarSnow(in: &park, size: size, t: t, look: look, dark: dark)
            drawHills(in: &park, size: size)
            drawPond(in: &park, size: size, t: t, look: look, dark: dark)
            // The heart clouds catch the sunset and go dusky violet after dark.
            drawClouds(in: &park, size: size, t: t, look: look, dark: dark)
            drawTree(in: &park, size: size, t: t, look: look)
            drawPair(in: &park, size: size, t: t, look: look)
            WeatherPainter.dullLight(in: &park, size: size, daylight: daylight)
            DaylightPainter.lowSunGrade(in: &park, size: size, daylight: daylight)
            DaylightPainter.nightGrade(in: &park, size: size, daylight: daylight, strength: 0.85)
        }
        // Lights and glowing hearts are not dimmed by the night: they light it.
        drawLamp(in: &ctx, size: size, t: t, look: look, lit: lampLit(daylight))
        drawHearts(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawShower(in: &ctx, size: size, look: look)
        WeatherPainter.foreground(in: &ctx, size: size, time: time, daylight: daylight)
        drawCrystals(in: &ctx, size: size, t: t, look: look, dark: dark)
    }

    /// The park lamp comes on as the light fails and burns through the night.
    static func lampLit(_ daylight: SceneDaylight) -> CGFloat {
        BG.smoothstep(0.75, 0.25, daylight.light)
    }

    // MARK: Sky and land

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, look: FebruaryModel.Look, pulse: CGFloat, sun: CGPoint, sunLight: Double) {
        let r = Double(look.romance)
        let sky = Gradient(stops: [
            .init(color: BG.rgb(1, 0.72 + 0.04 * (1 - r), 0.85, 0.24 + 0.06 * r), location: 0),
            .init(color: BG.rgb(1, 0.85, 0.92, 0.1), location: 0.5),
            .init(color: BG.rgb(1, 0.8, 0.85, 0.14 + 0.06 * Double(pulse)), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.78, 0.88), intensity: 0.2, depth: 0.5)
        // The soft winter sun wherever it is in the sky (the key light).
        ctx.glow(at: sun, radius: size.width * 0.45, color: BG.rgb(1, 0.95, 0.9), intensity: 0.28 * sunLight)
    }

    static func hillY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.885 + 0.02 * sin(u * 3.3 + 0.7) + 0.008 * sin(u * 10.4 + 2))
    }

    static func drawHills(in ctx: inout GraphicsContext, size: CGSize) {
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            hills.addLine(to: CGPoint(x: x, y: hillY(x, size: size)))
            x += 20
        }
        hills.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        hills.closeSubpath()
        ctx.fill(hills, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.98, 0.94, 0.98, 0.6), BG.rgb(0.85, 0.8, 0.92, 0.5)]),
            startPoint: CGPoint(x: 0, y: size.height * 0.86),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
    }

    /// A frozen pond at the bottom with two skaters gliding hand in hand. Its sheen
    /// reflects the blush sky and pulses with the heartbeat.
    static func drawPond(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, dark: Bool) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.955)
        let rx = size.width * 0.22
        let ry = size.height * 0.025
        let pond = BG.ellipse(center, rx, ry)
        let pulse = Double(FebruaryAir.pulse(beat: look.beat, x: center.x, width: size.width))
        ctx.fill(pond, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.8, 0.85, 0.98, 0.7), BG.rgb(0.95, 0.82, 0.92, 0.7)]),
            startPoint: CGPoint(x: 0, y: center.y - ry),
            endPoint: CGPoint(x: 0, y: center.y + ry)
        ))
        ctx.fill(pond, with: .radialGradient(
            Gradient(colors: [BG.rgb(1, 0.85, 0.92, 0.25 + 0.2 * pulse), BG.rgb(1, 0.85, 0.92, 0)]),
            center: CGPoint(x: center.x - rx * 0.2, y: center.y - ry * 0.3), startRadius: 0, endRadius: rx * 0.7
        ))
        ctx.stroke(pond, with: .color(BG.rgb(1, 1, 1, 0.5)), lineWidth: 1)

        // Skaters: a slow figure-eight around the pond.
        let a = t * 0.16
        for k in 0..<2 {
            let phase = a - CGFloat(k) * 0.07
            let x = center.x + sin(phase) * rx * 0.72
            let y = center.y + sin(phase * 2) * ry * 0.45
            let vx = cos(phase)
            let height: CGFloat = 15 - CGFloat(k) * 1.5
            var skater = ctx
            skater.translateBy(x: x, y: y)
            skater.scaleBy(x: (vx >= 0 ? 1 : -1) * height, y: height)
            skater.rotate(by: .radians(Double(sin(phase * 2) * 0.12)))
            skater.fill(FebruaryArt.skater, with: .color(k == 0 ? BG.rgb(0.55, 0.12, 0.25, 0.8) : BG.rgb(0.2, 0.2, 0.4, 0.8)))
            // Reflection on the ice.
            var mirror = ctx
            mirror.translateBy(x: x, y: y)
            mirror.scaleBy(x: (vx >= 0 ? 1 : -1) * height, y: -height * 0.5)
            mirror.fill(FebruaryArt.skater, with: .color(BG.rgb(0.4, 0.3, 0.5, dark ? 0.18 : 0.12)))
        }
    }

    /// A bare tree at the left edge with a pair of lovebirds on a low limb. About once
    /// a minute they shuffle together and touch beaks, and a tiny heart floats up.
    static func drawTree(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look) {
        let base = CGPoint(x: size.width * 0.045, y: hillY(size.width * 0.045, size: size) + 8)
        let scale = min(size.height * 0.42, 420)
        let sway = sin(t * 0.5) * 0.008
        var tree = ctx
        tree.translateBy(x: base.x, y: base.y)
        tree.rotate(by: .radians(Double(sway)))
        tree.scaleBy(x: scale, y: scale)
        let ink = BG.rgb(0.3, 0.2, 0.25, 0.7)
        tree.stroke(FebruaryArt.tree.thick, with: .color(ink), style: StrokeStyle(lineWidth: 0.028, lineCap: .round))
        tree.stroke(FebruaryArt.tree.mid, with: .color(ink), style: StrokeStyle(lineWidth: 0.012, lineCap: .round))
        tree.stroke(FebruaryArt.tree.thin, with: .color(ink), style: StrokeStyle(lineWidth: 0.005, lineCap: .round))

        // Perch: a low limb of its own.
        var limb = Path()
        let start = CGPoint(x: base.x + scale * 0.02, y: base.y - scale * 0.42)
        let end = CGPoint(x: base.x + scale * 0.3, y: base.y - scale * 0.48)
        limb.move(to: start)
        limb.addQuadCurve(to: end, control: CGPoint(x: base.x + scale * 0.16, y: base.y - scale * 0.5))
        ctx.stroke(limb, with: .color(ink), style: StrokeStyle(lineWidth: scale * 0.012, lineCap: .round))
        // Snow along the limb.
        var snow = ctx
        snow.translateBy(x: 0, y: -2)
        snow.stroke(limb, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        let period: CGFloat = 50
        let position = t / period + 0.3
        let local = BG.fract(position) * period
        let together = BG.smoothstep(0, 1.2, local) * (1 - BG.smoothstep(3.4, 4.6, local))
        let perchY = base.y - scale * 0.475
        for k in 0..<2 {
            let side: CGFloat = k == 0 ? -1 : 1
            let x = base.x + scale * 0.17 + side * (11 - 5 * together)
            let hop = abs(sin(t * 2.2 + CGFloat(k) * 1.7)) * 1.5 * (1 - together)
            let lean = together * 0.35 * -side
            var bird = ctx
            bird.translateBy(x: x, y: perchY - 6 - hop)
            bird.rotate(by: .radians(Double(lean)))
            bird.scaleBy(x: -side * 7, y: 7)
            let body = k == 0 ? BG.rgb(0.85, 0.12, 0.18) : BG.rgb(0.95, 0.5, 0.6)
            bird.fill(BG.ellipse(CGPoint(x: 0.1, y: 0.1), 0.85, 0.7), with: .radialGradient(
                Gradient(colors: [body, body.opacity(0.8)]),
                center: CGPoint(x: -0.2, y: -0.2), startRadius: 0, endRadius: 1.1
            ))
            bird.fill(BG.circle(CGPoint(x: -0.55, y: -0.5), 0.45), with: .color(body))
            var beak = Path()
            beak.move(to: CGPoint(x: -0.95, y: -0.55))
            beak.addLine(to: CGPoint(x: -1.3, y: -0.45))
            beak.addLine(to: CGPoint(x: -0.95, y: -0.38))
            beak.closeSubpath()
            bird.fill(beak, with: .color(BG.rgb(1, 0.7, 0.2)))
            bird.fill(BG.circle(CGPoint(x: -0.65, y: -0.62), 0.09), with: .color(.black))
            var tail = Path()
            tail.move(to: CGPoint(x: 0.8, y: 0.1))
            tail.addLine(to: CGPoint(x: 1.5, y: 0.5))
            tail.addLine(to: CGPoint(x: 1.4, y: 0.75))
            tail.closeSubpath()
            bird.fill(tail, with: .color(body.opacity(0.85)))
        }
        // The little heart they make.
        let rise = local - 1.4
        if rise > 0 && rise < 3 {
            let p = CGPoint(x: base.x + scale * 0.17, y: perchY - 16 - rise * 14)
            let fade = Double(sin(rise / 3 * .pi))
            drawHeart(in: &ctx, at: p, size: 9 + rise * 2, rotation: 0, flip: 1, opacity: fade, material: .candy, glow: 0.5)
        }
    }

    /// A street lamp at the right edge, its warm pink-gold light catching the snow.
    static func drawLamp(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, lit: CGFloat) {
        let dark = lit > 0.5
        let height = min(size.height * 0.24, 240)
        let base = CGPoint(x: size.width * 0.94, y: hillY(size.width * 0.94, size: size) + 10)
        let lantern = CGPoint(x: base.x, y: base.y - height * 0.92)
        let flicker = Double(0.94 + 0.06 * sin(t * 3.1) * sin(t * 1.7 + 1)) * Double(0.15 + 0.85 * lit)
        ctx.glow(at: lantern, radius: height * BG.lerp(0.55, 0.75, lit), color: BG.rgb(1, 0.82, 0.7), intensity: Double(BG.lerp(0.2, 0.35, lit)) * flicker)
        ctx.fill(FebruaryArt.lamp.applying(CGAffineTransform(translationX: base.x, y: base.y).scaledBy(x: height, y: height)), with: .color(BG.rgb(0.2, 0.16, 0.22, 0.85)))
        ctx.fill(BG.ellipse(lantern, height * 0.05, height * 0.05), with: .color(BG.rgb(1, 0.92, 0.75, 0.95 * flicker)))
        ctx.glow(at: lantern, radius: height * 0.12, color: BG.rgb(1, 0.9, 0.7), intensity: 0.7 * flicker, additive: dark)

        // Snowflakes drifting through the lamplight light up.
        for i in 0..<14 {
            let f = BG.fract(BG.hash(i, 850) + t * BG.hash(i, 851, 0.05, 0.1))
            let x = lantern.x + BG.hash(i, 852, -1, 1) * height * 0.4 + sin(t * 0.7 + CGFloat(i)) * 10
            let y = lantern.y - height * 0.3 + f * height * 0.9
            let dx = x - lantern.x
            let dy = y - lantern.y
            let lit = 1 - min(1, sqrt(dx * dx + dy * dy) / (height * 0.5))
            guard lit > 0.02 else { continue }
            let alpha = Double(lit * BG.smoothstep(0, 0.1, f) * (1 - BG.smoothstep(0.85, 1, f)))
            ctx.fill(BG.circle(CGPoint(x: x, y: y), 1.6), with: .color(BG.rgb(1, 0.92, 0.82, 0.9 * alpha)))
        }
    }

    // MARK: Clouds

    /// Five clouds drifting in alternating directions. Each slowly gathers into a heart
    /// and relaxes back to cumulus; romance sets how many do, and the heartbeat swells them.
    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, dark: Bool) {
        let r = Double(look.romance)
        let palette = CloudPalette(
            light: BG.rgb(1, 0.98 - 0.04 * r, 0.99 - 0.03 * r),
            body: BG.rgb(1, 0.9 - 0.08 * r, 0.94 - 0.05 * r),
            shade: dark ? BG.rgb(0.9, 0.68, 0.8) : BG.rgb(0.85, 0.56, 0.71)
        )
        for k in 0..<5 {
            let width = BG.hash(k, 21, 190, 260)
            let duration = BG.hash(k, 22, 100, 160)
            let span = size.width + width * 2
            var u = BG.fract(BG.hash(k, 23) + t / duration)
            if k % 2 == 1 { u = 1 - u }
            let x = u * span - width
            let y = size.height * BG.hash(k, 24, 0.12, 0.55) + sin(t * 0.25 + CGFloat(k) * 1.3) * 24
            let center = CGPoint(x: x, y: y)

            // How much of a heart this cloud is right now.
            let rank = BG.hash(k, 25)
            let eligible = BG.clamp01((look.heartShare - rank) / 0.12)
            let cycle = 0.5 + 0.5 * sin(t * 2 * CGFloat.pi / BG.hash(k, 26, 20, 40) + BG.hash(k, 27) * 6.28)
            let heart = eligible * BG.smoothstep(0.25, 0.75, cycle)
            let swell = 1 + 0.04 * FebruaryAir.pulse(beat: look.beat, x: x, width: size.width) * heart

            let puffs = morphPuffs(seed: k, width: width, heart: heart, swell: swell)
            if !dark {
                // Soft pink outline glow so the cloud reads on white.
                ctx.glow(at: center, radius: width * 0.7, color: BG.rgb(0.95, 0.65, 0.78), intensity: 0.22)
            }
            CloudPainter.draw(
                in: &ctx,
                puffs: puffs,
                center: center,
                width: width,
                palette: palette,
                opacity: 0.82,
                lightDirection: CGVector(dx: size.width * 0.5 - x, dy: -size.height * 0.2 - y),
                softness: 0.035
            )
        }
    }

    /// Heart puffs, blended toward a squashed cumulus layout of the same puffs.
    static func morphPuffs(seed: Int, width: CGFloat, heart: CGFloat, swell: CGFloat) -> [CloudPainter.Puff] {
        let hearts = CloudPainter.heartPuffs(seed: seed, width: width)
        var puffs: [CloudPainter.Puff] = []
        puffs.reserveCapacity(hearts.count)
        for (i, h) in hearts.enumerated() {
            let lump = BG.hash(seed * 41 + i, 28, 0.85, 1.2)
            let cumulus = CGPoint(x: h.offset.x * 1.25, y: h.offset.y * 0.32 - (h.offset.y < 0 ? width * 0.05 * lump : 0))
            let offset = CGPoint(
                x: BG.lerp(cumulus.x, h.offset.x, heart) * swell,
                y: BG.lerp(cumulus.y, h.offset.y, heart) * swell
            )
            let radius = BG.lerp(h.radius * 1.12 * lump, h.radius, heart) * swell
            puffs.append(CloudPainter.Puff(offset: offset, radius: radius))
        }
        return puffs
    }

    // MARK: Hearts

    static func drawHearts(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, dark: Bool) {
        // 10 hearts rising far from Feb 14, up to 20 on it.
        let amount = BG.lerp(0.5, 1, look.romance)
        for i in 0..<20 {
            let rank = CGFloat(i) / 20 + BG.hash(i, 30, 0, 0.05)
            let visible = BG.clamp01((amount - rank) / 0.05)
            guard visible > 0.01 else { continue }
            // The extra romance hearts are mostly glass.
            let material: FebruaryHeartLook
            let roll = BG.hash(i, 37)
            if rank > 0.5 {
                material = roll < 0.6 ? .glass : .candy
            } else {
                material = roll < 0.3 ? .paper : (roll < 0.4 ? .glass : .candy)
            }
            // At most a handful of big ones.
            let heartSize = i % 4 == 0 ? BG.hash(i, 31, 30, 46) : BG.hash(i, 31, 16, 30)
            let depth = (heartSize - 16) / 30
            let speed = BG.lerp(14, 34, depth)
            let span = size.height + 140
            let progress = BG.fract(BG.hash(i, 33) + t * speed / span)
            let y = size.height + 70 - progress * span
            let x = BG.wrap(BG.hash(i, 34) * size.width + sin(t * 0.6 + CGFloat(i)) * 34 + look.drift * BG.lerp(0.3, 0.8, depth), length: size.width, margin: 60)
            let flip = cos(t * BG.hash(i, 35, 0.5, 1.2) + BG.hash(i, 36) * 6.28)
            let tilt = sin(t * 0.8 + CGFloat(i)) * 0.25
            let fade = BG.smoothstep(0, 0.1, progress) * (1 - BG.smoothstep(0.82, 1, progress))
            let opacity = Double(fade * visible * BG.lerp(0.55, 0.95, depth))
            let pulse = FebruaryAir.pulse(beat: look.beat, x: x, width: size.width)
            drawHeart(in: &ctx, at: CGPoint(x: x, y: y), size: heartSize, rotation: Double(tilt), flip: flip, opacity: opacity, material: material, glow: 0.25 + 0.35 * pulse)
        }
    }

    static func drawHeart(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, opacity: Double, material: FebruaryHeartLook, glow: CGFloat) {
        guard opacity > 0.01 else { return }
        ctx.glow(at: p, radius: size * 1.2, color: BG.rgb(1, 0.4, 0.6), intensity: Double(glow) * opacity)

        var heart = ctx
        heart.opacity = opacity
        heart.translateBy(x: p.x, y: p.y)
        heart.rotate(by: .radians(rotation))
        heart.scaleBy(x: size * max(abs(flip), 0.08), y: size)
        let front = flip >= 0
        let shape = HeartGeometry.unitPath

        switch material {
        case .candy:
            let colors = front
                ? [BG.rgb(1, 0.5, 0.64), BG.rgb(0.92, 0.16, 0.32), BG.rgb(0.62, 0.02, 0.18)]
                : [BG.rgb(0.75, 0.14, 0.3), BG.rgb(0.5, 0.03, 0.16)]
            heart.fill(shape, with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: -0.4, y: -0.45), endPoint: CGPoint(x: 0.35, y: 0.5)))
            heart.stroke(shape, with: .color(.white.opacity(0.18)), lineWidth: 0.03)
            if front {
                let gloss = BG.ellipse(.zero, 0.12, 0.065)
                    .applying(CGAffineTransform(rotationAngle: -0.6).concatenating(CGAffineTransform(translationX: -0.2, y: -0.22)))
                heart.fill(gloss, with: .color(.white.opacity(0.6)))
                heart.fill(BG.circle(CGPoint(x: -0.06, y: -0.3), 0.025), with: .color(.white.opacity(0.7)))
            }
        case .paper:
            let colors = front
                ? [BG.rgb(1, 0.72, 0.78), BG.rgb(0.95, 0.5, 0.6)]
                : [BG.rgb(0.95, 0.82, 0.85), BG.rgb(0.88, 0.68, 0.74)]
            heart.fill(shape, with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: -0.4, y: -0.45), endPoint: CGPoint(x: 0.35, y: 0.5)))
            // The fold down the middle, one half a touch darker.
            heart.fill(FebruaryArt.halfHeart, with: .color(BG.rgb(0.6, 0.2, 0.3, 0.12)))
            var crease = Path()
            crease.move(to: CGPoint(x: 0, y: -0.07))
            crease.addLine(to: CGPoint(x: 0, y: 0.54))
            heart.stroke(crease, with: .color(BG.rgb(0.6, 0.2, 0.3, 0.35)), lineWidth: 0.02)
        case .glass:
            heart.fill(shape, with: .radialGradient(
                Gradient(colors: [BG.rgb(1, 0.85, 0.9, 0.12), BG.rgb(1, 0.5, 0.65, 0.3)]),
                center: CGPoint(x: -0.1, y: -0.1), startRadius: 0, endRadius: 0.6
            ))
            heart.stroke(shape, with: .color(.white.opacity(Double(0.55 + 0.4 * glow))), lineWidth: 0.045)
            heart.stroke(shape, with: .color(BG.rgb(1, 0.45, 0.6, 0.5)), lineWidth: 0.015)
            heart.fill(BG.ellipse(CGPoint(x: -0.2, y: -0.2), 0.05, 0.1), with: .color(.white.opacity(0.75)))
        }
    }

    /// About once a minute two hearts rise side by side, drift together, touch, and
    /// become one slightly larger heart with a sparkle.
    static func drawPair(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look) {
        let period: CGFloat = 62
        let position = t / period + 0.55
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        let life: CGFloat = 26
        guard age < life else { return }
        let u = age / life
        let side = BG.hash(cycle, 860)
        let baseX = (side < 0.5 ? BG.lerp(0.12, 0.3, side * 2) : BG.lerp(0.7, 0.88, (side - 0.5) * 2)) * size.width
        let y = size.height + 40 - u * (size.height + 100)
        let fade = Double(BG.smoothstep(0, 0.06, u) * (1 - BG.smoothstep(0.85, 1, u)))
        let merge = BG.smoothstep(0.3, 0.45, u)
        let x = baseX + sin(t * 0.5 + CGFloat(cycle)) * 20
        let pulse = FebruaryAir.pulse(beat: look.beat, x: x, width: size.width)
        if merge < 1 {
            let gap = 34 * (1 - merge)
            for k in 0..<2 {
                let sign: CGFloat = k == 0 ? -1 : 1
                let flip = cos(t * 0.8 + CGFloat(k) * 2) * (1 - merge) + merge
                drawHeart(in: &ctx, at: CGPoint(x: x + sign * gap, y: y), size: 22, rotation: Double(sign * 0.25 * (1 - merge)), flip: flip, opacity: fade * Double(1 - merge * 0.5), material: .candy, glow: 0.3 + 0.3 * pulse)
            }
        }
        if merge > 0 {
            drawHeart(in: &ctx, at: CGPoint(x: x, y: y), size: 22 * BG.lerp(1, 1.3, merge), rotation: 0, flip: cos(t * 0.6) * 0.3 + 0.7, opacity: fade * Double(merge), material: .candy, glow: 0.4 + 0.4 * pulse)
        }
        let sparkle = BG.smoothstep(0.42, 0.45, u) * (1 - BG.smoothstep(0.46, 0.52, u))
        if sparkle > 0.01 {
            ctx.sparkle(at: CGPoint(x: x + 8, y: y - 14), size: 12, color: BG.rgb(1, 0.92, 0.95), intensity: Double(sparkle) * fade)
        }
    }

    /// Valentine's Day: a fan of hearts bursting up from the bottom third.
    static func drawShower(in ctx: inout GraphicsContext, size: CGSize, look: FebruaryModel.Look) {
        let age = look.showerAge
        guard age >= 0 else { return }
        let swell = BG.smoothstep(0, 0.6, age) * (1 - BG.smoothstep(1.5, 4, age))
        if swell > 0.01 {
            ctx.glow(at: CGPoint(x: size.width / 2, y: size.height * 1.05), radius: size.width * 0.6, color: BG.rgb(1, 0.55, 0.72), intensity: 0.3 * Double(swell))
        }
        for k in 0..<60 {
            let a = age - BG.hash(k, 870, 0, 5)
            guard a > 0 else { continue }
            let angle = -CGFloat.pi / 2 + BG.hash(k, 871, -0.6, 0.6)
            let speed = BG.hash(k, 872, 80, 140)
            let start = CGPoint(x: size.width * BG.hash(k, 873, 0.2, 0.8), y: size.height * BG.hash(k, 874, 0.72, 1.02))
            let p = CGPoint(x: start.x + cos(angle) * speed * a, y: start.y + sin(angle) * speed * a + 8 * a * a)
            // Gone by the time they reach 70% of the way up.
            let reach = 1 - BG.smoothstep(size.height * 0.45, size.height * 0.3, p.y)
            let fade = BG.smoothstep(0, 0.3, a) * reach
            guard fade > 0.01 else { continue }
            drawHeart(
                in: &ctx,
                at: p,
                size: BG.hash(k, 875, 10, 30),
                rotation: Double(sin(a * 2 + CGFloat(k)) * 0.3),
                flip: cos(a * BG.hash(k, 876, 2.5, 4.5) + CGFloat(k)),
                opacity: Double(fade) * 0.95,
                material: k % 5 == 0 ? .glass : .candy,
                glow: 0.4
            )
        }
    }

    // MARK: Snow

    /// A light dusting of late snow (about 40% of January's).
    static func drawFarSnow(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, dark: Bool) {
        var specks = Path()
        let span = size.height + 40
        for i in 0..<60 {
            let speed = BG.hash(i, 11, 22, 42)
            let progress = BG.fract(BG.hash(i, 12) + t * speed / span)
            let y = progress * span - 20
            let sway = sin(t * BG.hash(i, 13, 0.4, 0.9) + BG.hash(i, 14) * 6.28) * 14
            let x = BG.wrap(BG.hash(i, 15) * size.width + sway + look.drift * 0.5, length: size.width, margin: 20)
            specks.addPath(BG.circle(CGPoint(x: x, y: y), BG.hash(i, 16, 0.9, 2)))
        }
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.8, y: 0.8)
            shadow.fill(specks, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45)))
        }
        ctx.fill(specks, with: .color(.white.opacity(0.6)))
    }

    static func drawCrystals(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: FebruaryModel.Look, dark: Bool) {
        var crystals = Path()
        let span = size.height + 80
        for i in 0..<16 {
            let seed = i + 1000
            let speed = BG.hash(seed, 11, 40, 66)
            let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
            let y = progress * span - 40
            let sway = sin(t * BG.hash(seed, 13, 0.3, 0.7) + BG.hash(seed, 14) * 6.28) * 32
            let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 0.8, length: size.width, margin: 40)
            let radius = BG.hash(seed, 16, 5, 9)
            let spin = t * BG.hash(seed, 18, -0.6, 0.6) + BG.hash(seed, 19) * 6.28
            crystals.addPath(
                SnowRenderer.crystals[i % SnowRenderer.crystals.count],
                transform: CGAffineTransform(translationX: x, y: y).rotated(by: spin).scaledBy(x: radius, y: radius)
            )
        }
        let stroke = StrokeStyle(lineWidth: 1.1, lineCap: .round)
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.9, y: 0.9)
            shadow.stroke(crystals, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45)), style: stroke)
        }
        ctx.stroke(crystals, with: .color(.white.opacity(0.85)), style: stroke)
    }
}
