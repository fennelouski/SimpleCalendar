//
//  AprilScene.swift
//  Simple Calendar
//
//  April: a spring storm watched from a window.
//
//  The rain cycle is the star. One value, the rain amount, ebbs and flows on its own
//  clock between drizzle and downpour: it holds a level for 10-30 s, then eases to the
//  next over 15-30 s (`AprilRainCycle`). Everything follows it: how many drops fall
//  (each drop checks the amount when its fall began, so none pop in mid-air), how hard
//  the gusts swing the slant, how dark and low the clouds sit, how many beads gather on
//  the window, how busy the splashes are, and whether lightning may strike at all.
//  Rain falls in curtains that drift with the wind.
//
//  The scene also follows the selected day:
//    * day character - drizzle, showers or thunderstorm: the weights the rain cycle
//                      draws its next level from, how often lightning fires and how
//                      dark the cloud base sits
//    * Easter        - the storm breaks: rain tapers, the clouds part at the upper
//                      right, warm sunbeams slant in and a rainbow appears
//  The weather weights switch at once but never cut the rain off; the rest changes
//  through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct AprilRainAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = AprilModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = AprilModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            AprilScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class AprilModel {
    struct Target {
        /// Rain cycle weights for drizzle, light, steady, heavy and downpour.
        let weights: [Double]
        /// Share of lightning slots that fire (0 drizzle day, 0.3 showers, 1 thunderstorm).
        let lightning: Double
        /// Cloud-base darkness for the day.
        let darkness: Double
        let easter: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            let roll = day.roll(401)
            if roll < 0.35 {
                weights = [0.4, 0.4, 0.2, 0, 0]; lightning = 0; darkness = 0
            } else if roll < 0.8 {
                weights = [0, 0.25, 0.4, 0.3, 0.05]; lightning = 0.3; darkness = 0.5
            } else {
                weights = [0, 0, 0.25, 0.4, 0.35]; lightning = 1; darkness = 1
            }
            let easterDay = SceneDay.easter(year: day.year)
            let isEaster = day.month == 4 && easterDay.month == 4 && easterDay.day == day.day
            easter = isEaster ? 1 : 0
        }
    }

    struct Look {
        /// 0.15 drizzle ... 1 downpour, after the Easter taper.
        var amount: CGFloat
        var lightning: CGFloat
        var darkness: CGFloat
        var easter: CGFloat
        /// Wind displacement accumulated since the scene appeared.
        var drift: CGFloat
        /// The cycle, for looking up the amount when a drop's fall began.
        var cycle: AprilRainCycle

        /// Gust scale by level: x0.5 at drizzle ... x1.4 at downpour.
        var gustScale: CGFloat { BG.lerp(0.5, 1.4, BG.clamp01((amount - 0.15) / 0.85)) }
        /// Rain amount at an earlier moment (with the Easter taper applied).
        func amount(at t: CGFloat) -> CGFloat {
            BG.lerp(CGFloat(cycle.amount(at: Double(t))), 0.15, easter)
        }
    }

    private let cycle = AprilRainCycle()
    private let lightningTransition = SceneTransition()
    private let darknessTransition = SceneTransition()
    private let easterTransition = SceneTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let raw = cycle.advance(time: time, weights: target.weights)
        let lightning = lightningTransition.value(target: target.lightning, time: time)
        let darkness = darknessTransition.value(target: target.darkness, time: time)
        let easter = easterTransition.value(target: target.easter, time: time)
        let amount = BG.lerp(CGFloat(raw), 0.15, CGFloat(easter))
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * AprilWind.cloudSpeed(CGFloat(time)) * BG.lerp(0.5, 1.4, BG.clamp01((amount - 0.15) / 0.85))
        }
        lastTime = time
        return Look(
            amount: amount,
            lightning: CGFloat(lightning),
            darkness: CGFloat(darkness),
            easter: CGFloat(easter),
            drift: drift,
            cycle: cycle
        )
    }
}

/// The rain's ebb and flow: hold a level for 10-30 s, ease to the next over 15-30 s.
/// The next level comes from the selected day's weights, never repeats the current one
/// and moves at most two levels. Also keeps 4 s of history so drops can be shown or
/// hidden by the amount at the start of their fall.
final class AprilRainCycle {
    static let levels: [Double] = [0.15, 0.35, 0.6, 0.85, 1.0]

    private var current = -1
    private var next = 0
    private var easing = false
    private var phaseStart = 0.0
    private var holdDuration = 0.0
    private var easeDuration = 0.0
    private var picks = 0
    private var samples = [Double](repeating: 0, count: 40)
    private var lastSlot = -1

    func advance(time: Double, weights: [Double]) -> Double {
        if current < 0 {
            var best = 0
            for j in weights.indices where weights[j] > weights[best] { best = j }
            current = best
            startHold(time)
        }
        var value = AprilRainCycle.levels[current]
        if easing {
            let u = (time - phaseStart) / easeDuration
            if u >= 1 {
                current = next
                easing = false
                startHold(time)
                value = AprilRainCycle.levels[current]
            } else {
                let eased = Double(BG.smoothstep(0, 1, CGFloat(u)))
                value = AprilRainCycle.levels[current] + (AprilRainCycle.levels[next] - AprilRainCycle.levels[current]) * eased
            }
        } else if time - phaseStart >= holdDuration {
            next = pick(weights)
            easing = true
            phaseStart = time
            easeDuration = 15 + 15 * Double(BG.hash(picks, 412))
        }
        record(time: time, value: value)
        return value
    }

    /// The amount at an earlier time (up to about 4 s back).
    func amount(at t: Double) -> Double {
        guard lastSlot >= 0 else { return AprilRainCycle.levels[2] }
        let slot = Int(floor(t * 10))
        if slot < 0 || slot >= lastSlot || slot <= lastSlot - 39 {
            return samples[lastSlot % 40]
        }
        return samples[slot % 40]
    }

    private func startHold(_ time: Double) {
        phaseStart = time
        holdDuration = 10 + 20 * Double(BG.hash(picks, 411))
    }

    private func pick(_ weights: [Double]) -> Int {
        picks += 1
        var total = 0.0
        for j in weights.indices where j != current && abs(j - current) <= 2 {
            total += weights[j]
        }
        if total <= 0 {
            // Nothing allowed nearby: step one level toward where the day's weather sits.
            var mean = 0.0, sum = 0.0
            for j in weights.indices {
                mean += Double(j) * weights[j]
                sum += weights[j]
            }
            let goal = sum > 0 ? mean / sum : 2
            return min(max(current + (goal > Double(current) ? 1 : -1), 0), AprilRainCycle.levels.count - 1)
        }
        var r = Double(BG.hash(picks, 413)) * total
        for j in weights.indices where j != current && abs(j - current) <= 2 {
            r -= weights[j]
            if r <= 0 && weights[j] > 0 { return j }
        }
        return min(current + 1, AprilRainCycle.levels.count - 1)
    }

    private func record(time: Double, value: Double) {
        let slot = Int(floor(time * 10))
        if lastSlot < 0 || slot - lastSlot >= 40 {
            for i in 0..<40 { samples[i] = value }
        } else if slot > lastSlot {
            for s in (lastSlot + 1)...slot { samples[s % 40] = value }
        } else {
            samples[slot % 40] = value
        }
        lastSlot = max(lastSlot, slot)
    }
}

// MARK: - Wind and lightning

private enum AprilWind {
    /// Rain slant (horizontal per vertical): base 0.2 with gusts over 9-28 s periods.
    static func slant(_ t: CGFloat, gustScale: CGFloat) -> CGFloat {
        0.2 + (0.1 * sin(t * 0.11) + 0.05 * sin(t * 0.37 + 1)) * gustScale
    }

    /// Cloud drift speed in points per second.
    static func cloudSpeed(_ t: CGFloat) -> CGFloat { 9 + 4 * sin(t * 0.11) }

    /// 0.5...1.3 rain curtains: a slow variation across x that drifts with the wind.
    static func curtain(_ x: CGFloat, width: CGFloat, drift: CGFloat) -> CGFloat {
        let u = (x - drift * 0.8) / max(width, 1)
        return 0.9 + 0.25 * sin(u * 2 * CGFloat.pi * 1.6) + 0.15 * sin(u * 2 * CGFloat.pi * 2.7 + 1.3)
    }
}

/// One depth layer of rain (far, mid, near).
private struct AprilRainLayer {
    let count: Int
    let length: ClosedRange<CGFloat>
    let speed: ClosedRange<CGFloat>
    let width: CGFloat
    let opacity: Double
    let salt: Int
}

private struct AprilFlash {
    var intensity: CGFloat
    var cycle: Int
    /// True during the first 0.1 s of a strike (rain "freezes" into droplets).
    var freeze: Bool
}

// MARK: - Scene

private enum AprilScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: AprilModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let flash = lightning(t: t, look: look)
        let slant = AprilWind.slant(t, gustScale: look.gustScale)

        drawSky(in: &ctx, size: size, look: look, flash: flash, dark: dark)
        if flash.intensity > 0.01 {
            drawBolt(in: &ctx, size: size, seed: flash.cycle, intensity: flash.intensity, dark: dark)
        }
        drawSunBreak(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawTreeline(in: &ctx, size: size, look: look)
        drawClouds(in: &ctx, size: size, t: t, look: look, flash: flash, dark: dark)
        drawShafts(in: &ctx, size: size, look: look)
        drawRain(in: &ctx, size: size, t: t, look: look, slant: slant, flash: flash, layer: 0, dark: dark)
        drawRain(in: &ctx, size: size, t: t, look: look, slant: slant, flash: flash, layer: 1, dark: dark)
        drawWater(in: &ctx, size: size, t: t, look: look, flash: flash, dark: dark)
        drawWalker(in: &ctx, size: size, t: t, look: look)
        drawSplashes(in: &ctx, size: size, t: t, look: look, dark: dark)
        ctx.blurredLayer(radius: 2.5) { near in
            drawRain(in: &near, size: size, t: t, look: look, slant: slant, flash: flash, layer: 2, dark: dark)
        }
        drawWindowDrops(in: &ctx, size: size, t: t, look: look, dark: dark)
    }

    /// Distant lightning: a strike and a weaker re-strike (never more than two pulses),
    /// only while the rain is heavy and only in the slots the day allows.
    static func lightning(t: CGFloat, look: AprilModel.Look) -> AprilFlash {
        let period: CGFloat = 17
        let position = t / period + 0.35
        let cycle = Int(floor(position))
        guard BG.hash(cycle, 66) < 0.7, BG.hash(cycle, 67) < look.lightning else { return AprilFlash(intensity: 0, cycle: cycle, freeze: false) }
        let start = (CGFloat(cycle) - 0.35) * period
        guard look.amount(at: start) >= 0.75 else { return AprilFlash(intensity: 0, cycle: cycle, freeze: false) }
        let local = BG.fract(position) * period
        var intensity: CGFloat = 0
        if local < 0.16 {
            intensity = 1 - local / 0.16
        } else if local > 0.26 && local < 0.62 {
            intensity = 0.7 * (1 - (local - 0.26) / 0.36)
        }
        return AprilFlash(intensity: intensity, cycle: cycle, freeze: local < 0.1)
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, look: AprilModel.Look, flash: AprilFlash, dark: Bool) {
        let heavy = Double(BG.clamp01((look.amount - 0.15) / 0.85))
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.3, 0.35, 0.46), intensity: 0.2 + 0.12 * heavy, depth: 0.5)
        AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.6, 0.7, 0.82), intensity: 0.16, depth: 0.2)
        if flash.intensity > 0.01 && dark {
            // Sky brighten, capped.
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.9, 0.93, 1), intensity: min(0.3, 0.35 * Double(flash.intensity)), depth: 0.7)
        }
    }

    /// A jagged main channel with a few forks, glowing behind the clouds.
    static func drawBolt(in ctx: inout GraphicsContext, size: CGSize, seed: Int, intensity: CGFloat, dark: Bool) {
        var bolt = Path()
        var p = CGPoint(x: size.width * BG.hash(seed, 67, 0.15, 0.85), y: size.height * 0.02)
        bolt.move(to: p)
        var joints: [CGPoint] = []
        let segments = 12
        for i in 0..<segments {
            p.x += BG.hash(seed * 31 + i, 68, -30, 30)
            p.y += size.height * 0.32 / CGFloat(segments)
            bolt.addLine(to: p)
            joints.append(p)
        }
        let forks = 2 + Int(BG.hash(seed, 69) * 3)
        for f in 0..<forks {
            var q = joints[min(2 + f * 2, joints.count - 1)]
            bolt.move(to: q)
            let side: CGFloat = BG.hash(seed * 7 + f, 70) < 0.5 ? -1 : 1
            for j in 0..<4 {
                q.x += side * BG.hash(seed * 13 + f * 5 + j, 71, 6, 22)
                q.y += BG.hash(seed * 13 + f * 5 + j, 72, 8, 18)
                bolt.addLine(to: q)
            }
        }
        let a = Double(intensity)
        if dark {
            ctx.blurredLayer(radius: 10) { glow in
                glow.stroke(bolt, with: .color(BG.rgb(0.75, 0.82, 1, a)), lineWidth: 10)
            }
            ctx.stroke(bolt, with: .color(.white.opacity(a)), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        } else {
            // Light theme: a brief cool shadow-glow instead of a brightening flash.
            ctx.blurredLayer(radius: 8) { glow in
                glow.stroke(bolt, with: .color(BG.rgb(0.35, 0.42, 0.6, 0.5 * a)), lineWidth: 8)
            }
            ctx.stroke(bolt, with: .color(BG.rgb(0.95, 0.97, 1, a)), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
    }

    /// Easter: the clouds part at the upper right, warm beams slant in and a rainbow
    /// fades in on the opposite side.
    static func drawSunBreak(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, dark: Bool) {
        let s = Double(look.easter)
        guard s > 0.01 else { return }
        let sun = CGPoint(x: size.width * 0.88, y: -size.height * 0.04)
        ctx.glow(at: sun, radius: size.width * 0.4, color: BG.rgb(1, 0.91, 0.69), intensity: 0.35 * s)
        ctx.blurredLayer(radius: 22) { beams in
            for i in 0..<6 {
                let angle = 1.9 + CGFloat(i) * 0.14 + sin(t * 0.06 + CGFloat(i)) * 0.03
                let spread = BG.hash(i, 420, 0.03, 0.06)
                let length = size.height * 1.3
                var wedge = Path()
                wedge.move(to: sun)
                wedge.addLine(to: CGPoint(x: sun.x + cos(angle - spread) * length, y: sun.y + sin(angle - spread) * length))
                wedge.addLine(to: CGPoint(x: sun.x + cos(angle + spread) * length, y: sun.y + sin(angle + spread) * length))
                wedge.closeSubpath()
                let breathe = 0.6 + 0.4 * Double(sin(t * 0.3 + CGFloat(i) * 1.7))
                beams.fill(wedge, with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 0.91, 0.69, 0.3 * s * breathe), BG.rgb(1, 0.91, 0.69, 0)]),
                    startPoint: sun,
                    endPoint: CGPoint(x: sun.x + cos(angle) * length * 0.8, y: sun.y + sin(angle) * length * 0.8)
                ))
            }
        }
        // Rainbow on the far side, low in the sky.
        let center = CGPoint(x: size.width * 0.18, y: size.height * 1.05)
        let radius = size.height * 0.55
        var arc = Path()
        for k in 0...40 {
            let a = CGFloat.pi + CGFloat.pi * 0.62 * CGFloat(k) / 40
            let p = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
            if k == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
        }
        let colors: [Color] = [
            BG.rgb(0.6, 0.3, 0.9), BG.rgb(0.3, 0.4, 1), BG.rgb(0.2, 0.75, 0.9), BG.rgb(0.3, 0.85, 0.35),
            BG.rgb(1, 0.92, 0.3), BG.rgb(1, 0.6, 0.2), BG.rgb(1, 0.25, 0.25)
        ]
        var stops: [Gradient.Stop] = [.init(color: colors[0].opacity(0), location: 0)]
        for (k, color) in colors.enumerated() {
            stops.append(.init(color: color.opacity(0.2 * s), location: 0.08 + 0.84 * CGFloat(k) / CGFloat(colors.count - 1)))
        }
        stops.append(.init(color: colors[colors.count - 1].opacity(0), location: 1))
        ctx.stroke(arc, with: .radialGradient(Gradient(stops: stops), center: center, startRadius: radius - 13, endRadius: radius + 13), lineWidth: 26)
    }

    /// A misty treeline and rooftops seen through the rain along the far bank.
    static func drawTreeline(in ctx: inout GraphicsContext, size: CGSize, look: AprilModel.Look) {
        let base = size.height * 0.935
        var line = Path()
        line.move(to: CGPoint(x: 0, y: base))
        var x: CGFloat = 0
        var i = 0
        while x <= size.width + 20 {
            let h = BG.hash(i, 430, 10, 30) * (BG.hash(i, 431) < 0.15 ? 1.6 : 1)
            line.addQuadCurve(to: CGPoint(x: x + 20, y: base - h), control: CGPoint(x: x + 4, y: base - h * 1.2))
            x += 20
            i += 1
        }
        line.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        line.addLine(to: CGPoint(x: 0, y: size.height))
        line.closeSubpath()
        let haze = 0.35 - 0.15 * Double(BG.clamp01((look.amount - 0.15) / 0.85))
        ctx.fill(line, with: .color(BG.rgb(0.32, 0.38, 0.45, haze)))
    }

    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, flash: AprilFlash, dark: Bool) {
        let heavy = BG.clamp01((look.amount - 0.15) / 0.85)
        let darkness = Double(BG.clamp01(0.3 * look.darkness + 0.7 * heavy))
        let palette = CloudPalette(
            light: BG.rgb(0.78 - 0.14 * darkness, 0.8 - 0.14 * darkness, 0.86 - 0.12 * darkness),
            body: BG.rgb(0.55 - 0.15 * darkness, 0.58 - 0.15 * darkness, 0.66 - 0.14 * darkness),
            shade: BG.rgb(0.3 - 0.1 * darkness, 0.33 - 0.1 * darkness, 0.41 - 0.1 * darkness)
        )
        let boltX = size.width * BG.hash(flash.cycle, 67, 0.15, 0.85)
        let lower = size.height * 0.03 * heavy
        for k in 0..<7 {
            let width = BG.lerp(340, 540, CGFloat(k) / 6) * BG.hash(k, 61, 0.9, 1.1)
            let x = BG.wrap(BG.hash(k, 63) * size.width + look.drift * BG.hash(k, 62, 0.7, 1.4), length: size.width, margin: width * 0.7)
            let y = size.height * BG.hash(k, 64, -0.02, 0.06) + lower
            let center = CGPoint(x: x, y: y)
            // Easter: the clouds part in the upper right.
            let part = look.easter * BG.smoothstep(size.width * 0.45, size.width * 0.85, x)
            var opacity = 0.82 * Double(1 - 0.9 * part)
            if !dark { opacity *= 0.85 }
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 300, width: width),
                center: CGPoint(x: center.x, y: center.y - part * size.height * 0.06),
                width: width,
                palette: palette,
                opacity: opacity,
                lightDirection: CGVector(dx: 0.2, dy: -1)
            )
            if flash.intensity > 0.01 {
                // Lit from within, strongest near the bolt.
                let near = 1 - BG.smoothstep(0, size.width * 0.5, abs(x - boltX))
                ctx.glow(at: center, radius: width * 0.7, color: BG.rgb(0.85, 0.9, 1), intensity: Double(flash.intensity * (0.2 + 0.5 * near)) * (dark ? 1 : 0.4), additive: dark)
            }
        }
    }

    /// Darker rain shafts hanging under the cloud band where the curtains are thickest.
    static func drawShafts(in ctx: inout GraphicsContext, size: CGSize, look: AprilModel.Look) {
        let alpha = Double(look.amount) * 0.14
        guard alpha > 0.02 else { return }
        ctx.blurredLayer(radius: 30) { shafts in
            for i in 0..<6 {
                let x = size.width * (CGFloat(i) + 0.5) / 6
                let c = AprilWind.curtain(x, width: size.width, drift: look.drift)
                guard c > 1 else { continue }
                let rect = CGRect(x: x - size.width * 0.06, y: size.height * 0.08, width: size.width * 0.12, height: size.height * 0.5)
                shafts.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.35, 0.4, 0.5, alpha * Double(c - 1) * 3), BG.rgb(0.35, 0.4, 0.5, 0)]),
                    startPoint: CGPoint(x: x, y: rect.minY),
                    endPoint: CGPoint(x: x, y: rect.maxY)
                ))
            }
        }
    }

    // MARK: Rain

    static let layers: [AprilRainLayer] = [
        AprilRainLayer(count: 300, length: 10...16, speed: 700...900, width: 1, opacity: 0.32, salt: 0),
        AprilRainLayer(count: 180, length: 20...30, speed: 950...1200, width: 1.5, opacity: 0.48, salt: 1000),
        AprilRainLayer(count: 30, length: 46...70, speed: 1500...1800, width: 2.6, opacity: 0.4, salt: 2000)
    ]

    /// One rain layer. Streaks are batched by curtain density into dim tails and bright
    /// heads, so each layer is a handful of strokes rather than one per drop.
    static func drawRain(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, slant: CGFloat, flash: AprilFlash, layer index: Int, dark: Bool) {
        let layer = layers[index]
        let norm = sqrt(1 + slant * slant)
        let dir = CGVector(dx: slant / norm, dy: 1 / norm)
        var tails = [Path(), Path()]
        var heads = [Path(), Path()]
        let freeze = flash.freeze && index > 0
        for i in 0..<layer.count {
            let seed = i + layer.salt
            let speed = BG.hash(seed, 2, layer.speed.lowerBound, layer.speed.upperBound)
            let length = BG.hash(seed, 1, layer.length.lowerBound, layer.length.upperBound)
            let span = size.height + length + 60
            let fallen = BG.hash(seed, 3) + t * speed / span
            let progress = BG.fract(fallen)
            // Shown or hidden by the rain amount when this fall began.
            let began = t - progress * span / speed
            guard BG.hash(seed, 5) < look.amount(at: began) else { continue }
            let headY = progress * span - length - 20
            let headX = BG.wrap(BG.hash(seed, 4) * size.width + headY * slant, length: size.width, margin: 60)
            let bucket = AprilWind.curtain(headX, width: size.width, drift: look.drift) > 0.95 ? 1 : 0
            let shown = freeze ? length * 0.15 : length
            let head = CGPoint(x: headX, y: headY)
            let mid = CGPoint(x: headX - dir.dx * shown * 0.45, y: headY - dir.dy * shown * 0.45)
            let tail = CGPoint(x: headX - dir.dx * shown, y: headY - dir.dy * shown)
            tails[bucket].move(to: tail)
            tails[bucket].addLine(to: mid)
            heads[bucket].move(to: mid)
            heads[bucket].addLine(to: head)
        }
        let color = dark ? BG.rgb(0.85, 0.92, 1) : BG.rgb(0.37, 0.47, 0.6)
        let base = dark ? layer.opacity : 0.4
        let style = StrokeStyle(lineWidth: layer.width, lineCap: .round)
        for bucket in 0..<2 {
            let curtain = bucket == 0 ? 0.6 : 1.0
            ctx.stroke(tails[bucket], with: .color(color.opacity(base * 0.35 * curtain)), style: style)
            ctx.stroke(heads[bucket], with: .color(color.opacity(base * curtain)), style: style)
        }
    }

    // MARK: Water

    static func waterTop(size: CGSize) -> CGFloat { size.height * 0.93 }

    /// A thin sheet of water along the bottom that mirrors the sky's tint, flickers with
    /// lightning and warms on Easter.
    static func drawWater(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, flash: AprilFlash, dark: Bool) {
        let top = waterTop(size: size)
        let rect = CGRect(x: 0, y: top, width: size.width, height: size.height - top)
        let warm = Double(look.easter)
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [
                BG.rgb(0.55 + 0.3 * warm, 0.62 + 0.2 * warm, 0.75, 0.32),
                BG.rgb(0.36, 0.42, 0.52, 0.42)
            ]),
            startPoint: CGPoint(x: 0, y: top),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        // Streaky reflections of the bright sky, rippling.
        var streaks = Path()
        for i in 0..<18 {
            let x = BG.hash(i, 440) * size.width + sin(t * 0.8 + CGFloat(i)) * 6
            let y = top + BG.hash(i, 441, 2, 8)
            let w = BG.hash(i, 442, 30, 90)
            streaks.addPath(BG.ellipse(CGPoint(x: x, y: y), w, 1.2))
        }
        let shine = 0.18 + 0.4 * Double(flash.intensity) * (dark ? 1 : 0.3) + 0.2 * warm
        ctx.fill(streaks, with: .color(BG.rgb(0.9, 0.93, 1, shine)))
        ctx.fill(Path(CGRect(x: 0, y: top - 0.5, width: size.width, height: 1.2)), with: .color(BG.rgb(0.85, 0.9, 1, 0.45)))
    }

    /// Splashes, analytic from the drops themselves: each landing mid or near drop (a
    /// quarter of them, to keep it light) leaves a ring and a couple of hopping droplets.
    static func drawSplashes(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, dark: Bool) {
        var rings = [Path(), Path(), Path()]
        var droplets = Path()
        let top = waterTop(size: size)
        for index in 1...2 {
            let layer = layers[index]
            for i in 0..<layer.count {
                let seed = i + layer.salt
                guard BG.hash(seed, 6) < 0.25 else { continue }
                let speed = BG.hash(seed, 2, layer.speed.lowerBound, layer.speed.upperBound)
                let length = BG.hash(seed, 1, layer.length.lowerBound, layer.length.upperBound)
                let span = size.height + length + 60
                let fallen = BG.hash(seed, 3) + t * speed / span
                // The last landing was at the start of this fall cycle.
                let landed = t - BG.fract(fallen) * span / speed
                let age = t - landed
                let life = BG.hash(seed, 7, 0.7, 1.4)
                guard age < life else { continue }
                let began = landed - span / speed
                guard BG.hash(seed, 5) < look.amount(at: began) else { continue }
                let cycle = Int(floor(fallen)) - 1
                let depth = BG.hash(seed * 31 + cycle, 75)
                let x = BG.hash(seed * 31 + cycle, 73) * size.width
                let y = size.height - 3 - depth * (size.height - top - 6)
                let scale = BG.lerp(1, 0.55, depth) * (index == 2 ? 1.3 : 1)
                let u = age / life
                let radius = (3 + u * 16) * scale
                rings[min(Int(u * 3), 2)].addPath(BG.ellipse(CGPoint(x: x, y: y), radius, radius * 0.28))
                for d in 0..<2 {
                    let spread = (CGFloat(d) * 2 - 1) * u * 10 * scale
                    let hop = sin(u * CGFloat.pi) * (8 + CGFloat(d) * 5) * scale
                    droplets.addPath(BG.circle(CGPoint(x: x + spread, y: y - hop), 1.3 * scale))
                }
            }
        }
        let color = dark ? BG.rgb(0.88, 0.94, 1) : BG.rgb(0.4, 0.5, 0.65)
        for (k, ring) in rings.enumerated() {
            ctx.stroke(ring, with: .color(color.opacity(0.55 * (1 - Double(k) / 3))), lineWidth: 1.1)
        }
        ctx.fill(droplets, with: .color(color.opacity(0.5)))
    }

    /// Now and then someone hurries along the far bank under a red umbrella, mirrored
    /// in the water.
    static func drawWalker(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look) {
        let period: CGFloat = 95
        let position = t / period + 0.45
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        let crossing: CGFloat = 34
        guard age < crossing else { return }
        let u = age / crossing
        let rightward = BG.hash(cycle, 450) < 0.5
        let x = rightward ? -30 + u * (size.width + 60) : size.width + 30 - u * (size.width + 60)
        let ground = waterTop(size: size) - 1
        let step = sin(age * 7)
        let h: CGFloat = 22
        let lean = 0.06 * (rightward ? 1 : -1)
        for mirror in [false, true] {
            var figure = ctx
            figure.opacity = mirror ? 0.22 : 0.85
            figure.translateBy(x: x, y: ground)
            figure.scaleBy(x: h, y: mirror ? -h * 0.6 : h)
            figure.rotate(by: .radians(Double(lean)))
            var body = Path()
            body.addEllipse(in: CGRect(x: -0.08, y: -0.8, width: 0.16, height: 0.16))
            body.addRoundedRect(in: CGRect(x: -0.1, y: -0.66, width: 0.2, height: 0.36), cornerSize: CGSize(width: 0.06, height: 0.06))
            body.move(to: CGPoint(x: -0.05, y: -0.32))
            body.addLine(to: CGPoint(x: -0.05 + step * 0.08, y: 0))
            body.addLine(to: CGPoint(x: 0.01 + step * 0.08, y: 0))
            body.addLine(to: CGPoint(x: 0.02, y: -0.32))
            body.closeSubpath()
            body.move(to: CGPoint(x: 0.0, y: -0.32))
            body.addLine(to: CGPoint(x: -step * 0.08 + 0.02, y: 0))
            body.addLine(to: CGPoint(x: -step * 0.08 + 0.08, y: 0))
            body.addLine(to: CGPoint(x: 0.06, y: -0.32))
            body.closeSubpath()
            figure.fill(body, with: .color(BG.rgb(0.18, 0.2, 0.26)))
            var handle = Path()
            handle.move(to: CGPoint(x: 0.04, y: -0.6))
            handle.addLine(to: CGPoint(x: 0.04, y: -1.05))
            figure.stroke(handle, with: .color(BG.rgb(0.15, 0.15, 0.18)), lineWidth: 0.03)
            var canopy = Path()
            canopy.move(to: CGPoint(x: -0.42, y: -0.92))
            canopy.addQuadCurve(to: CGPoint(x: 0.5, y: -0.92), control: CGPoint(x: 0.04, y: -1.42))
            canopy.addQuadCurve(to: CGPoint(x: -0.42, y: -0.92), control: CGPoint(x: 0.04, y: -0.98))
            canopy.closeSubpath()
            figure.fill(canopy, with: .linearGradient(
                Gradient(colors: [BG.rgb(0.95, 0.25, 0.25), BG.rgb(0.65, 0.08, 0.1)]),
                startPoint: CGPoint(x: -0.2, y: -1.3),
                endPoint: CGPoint(x: 0.3, y: -0.9)
            ))
        }
    }

    // MARK: Window

    /// Stylized beads on the window glass near the edges. They gather, sit, and some
    /// slide down with a short trail. More of them in heavier rain.
    static func drawWindowDrops(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: AprilModel.Look, dark: Bool) {
        let amount = BG.lerp(12, 24, BG.clamp01((look.amount - 0.15) / 0.85)) / 24
        var trails = Path()
        for k in 0..<24 {
            let period = BG.hash(k, 460, 9, 18)
            let position = t / period + BG.hash(k, 461)
            let cycle = Int(floor(position))
            let age = BG.fract(position) * period
            let seed = k * 97 + cycle
            guard BG.hash(k, 462) < amount else { continue }
            // Within 10% of an edge, never inside the content-safe region.
            let side = BG.hash(seed, 463)
            let x: CGFloat
            let y0: CGFloat
            if side < 0.35 {
                x = BG.hash(seed, 464, 0.01, 0.09) * size.width
                y0 = BG.hash(seed, 465, 0.05, 0.85) * size.height
            } else if side < 0.7 {
                x = (1 - BG.hash(seed, 464, 0.01, 0.09)) * size.width
                y0 = BG.hash(seed, 465, 0.05, 0.85) * size.height
            } else {
                x = BG.hash(seed, 464, 0.1, 0.9) * size.width
                y0 = BG.hash(seed, 465, 0.005, 0.07) * size.height
            }
            let r = BG.hash(seed, 466, 2.5, 5.5)
            let grow = BG.smoothstep(0, 0.6, age)
            let sit = BG.hash(seed, 467, 3, 7)
            let slides = BG.hash(seed, 468) < 0.5
            var y = y0
            if slides && age > sit {
                let a = age - sit
                y = y0 + 6 * a * a * r
                trails.move(to: CGPoint(x: x, y: y0))
                trails.addLine(to: CGPoint(x: x + sin(a) * 1.5, y: y - r))
            }
            let fade = Double(grow * (1 - BG.smoothstep(period - 1.2, period, age)))
            guard fade > 0.01, y < size.height + 10 else { continue }
            let p = CGPoint(x: x, y: y)
            let bead = BG.ellipse(p, r * grow, r * 1.1 * grow)
            ctx.fill(bead, with: .radialGradient(
                Gradient(colors: [BG.rgb(0.85, 0.9, 1, 0.12 * fade), BG.rgb(0.5, 0.58, 0.7, (dark ? 0.35 : 0.45) * fade)]),
                center: CGPoint(x: p.x + r * 0.2, y: p.y + r * 0.3), startRadius: 0, endRadius: r * 1.2
            ))
            ctx.fill(BG.circle(CGPoint(x: p.x - r * 0.35, y: p.y - r * 0.4), r * 0.22 * grow), with: .color(.white.opacity(0.75 * fade)))
        }
        ctx.stroke(trails, with: .color(BG.rgb(0.75, 0.82, 0.95, dark ? 0.25 : 0.35)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}
