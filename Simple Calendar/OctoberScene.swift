//
//  OctoberScene.swift
//  Simple Calendar
//
//  October: a harvest-moon night over an old belfry.
//
//  Moonlight is the star. The moon shows the true phase of the selected day, and one
//  value, the moonlight reaching the ground (phase illumination, dimmed whenever a
//  cloud crosses the disc), lights everything else: the bats' rims and how tightly the
//  flock holds together, the belfry's roof edge, the glow in the fog beneath the moon,
//  the silver linings and a faint lunar corona in thin cloud, and how many stars show.
//
//  The bats murmurate on a deterministic cycle: they pour out of the belfry, wheel
//  across the sky as a rippling ribbon that trails a wandering lead path, scatter,
//  regroup, and funnel home, with a few stragglers flitting about while the rest roost.
//
//  The scene also follows the selected day:
//    * moon phase  - the real phase for the day (2.5 s cyclic transition,
//                    `MoonPhaseAnimator`); full-moon days get a larger, warmer harvest moon
//    * Halloween   - the colony doubles and sweeps across the moon on arrival, the
//                    jack-o'-lanterns blaze and green-white wisps drift through thicker fog
//

import SwiftUI

// MARK: - View

struct OctoberMoonBatsAnimation: View {
    let alpha: Double
    /// The day whose moon phase is shown (the user's current selection/focus).
    let moonDate: Date
    @State private var model = OctoberModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, moonDate: Date = Date()) {
        self.alpha = alpha
        self.moonDate = moonDate
    }

    var body: some View {
        let target = OctoberModel.Target(date: moonDate)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            OctoberScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class OctoberModel {
    struct Target {
        let phase: Double
        let halloween: Double

        init(date: Date) {
            phase = MoonPhase.fraction(forDay: date)
            let day = SceneDay(date: date)
            halloween = day.month == 10 && day.day == 31 ? 1 : 0
        }
    }

    struct Look {
        var phase: Double
        var halloween: CGFloat
        /// When the last Halloween sweep across the moon began (scene time). Kept after
        /// the sweep ends so bats trailing behind the lead finish it smoothly.
        var sweepStart: CGFloat
        /// Breeze displacement accumulated since the scene appeared.
        var drift: CGFloat

        var illumination: CGFloat { CGFloat(MoonPhase.illumination(phase)) }
        /// 0...1 how close to a full (harvest) moon.
        var harvest: CGFloat { BG.smoothstep(0.96, 0.995, illumination) }
    }

    private let moon = MoonPhaseAnimator(duration: 2.5)
    private let halloweenTransition = SceneTransition()
    private let sweep = SceneMoment(duration: 7)
    private var drift: CGFloat = 0
    private var lastTime: Double?
    private var sweepStart: CGFloat = -1_000_000

    func look(target: Target, time: Double) -> Look {
        let phase = moon.phase(target: target.phase, time: time)
        let halloween = halloweenTransition.value(target: target.halloween, time: time)
        if let age = sweep.elapsed(arrived: halloween > 0.999, time: time), age == 0 {
            sweepStart = CGFloat(time)
        }
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * (10 + 4 * sin(CGFloat(time) * 0.09))
        }
        lastTime = time
        return Look(phase: phase, halloween: CGFloat(halloween), sweepStart: sweepStart, drift: drift)
    }
}

// MARK: - Frame

private struct OctoberCloud {
    var center: CGPoint
    var width: CGFloat
    var opacity: Double
    var seed: Int
}

private struct OctoberFrame {
    var moon: CGPoint
    var moonRadius: CGFloat
    /// 0 (clear) ... 1 (moon fully behind cloud).
    var cover: CGFloat
    /// 0...1 moonlight reaching the scene.
    var moonlight: CGFloat
    var clouds: [OctoberCloud]
    var belfry: CGPoint
    var belfryScale: CGFloat
}

// MARK: - Art

private enum OctoberArt {
    /// Belfry tower (unit height, base at the origin).
    static let belfry: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.16, y: -0.62, width: 0.32, height: 0.62))
        path.addRect(CGRect(x: -0.2, y: -0.66, width: 0.4, height: 0.05))
        path.move(to: CGPoint(x: -0.2, y: -0.66))
        path.addLine(to: CGPoint(x: 0, y: -1.0))
        path.addLine(to: CGPoint(x: 0.2, y: -0.66))
        path.closeSubpath()
        path.addRect(CGRect(x: -0.008, y: -1.1, width: 0.016, height: 0.11))
        path.addRect(CGRect(x: -0.04, y: -1.07, width: 0.08, height: 0.014))
        // Nave.
        path.addRect(CGRect(x: 0.16, y: -0.3, width: 0.5, height: 0.3))
        path.move(to: CGPoint(x: 0.14, y: -0.3))
        path.addLine(to: CGPoint(x: 0.41, y: -0.44))
        path.addLine(to: CGPoint(x: 0.68, y: -0.3))
        path.closeSubpath()
        return path
    }()

    /// The arched belfry openings.
    static let openings: Path = {
        var path = Path()
        for x in [-0.1, 0.02] as [CGFloat] {
            path.move(to: CGPoint(x: x, y: -0.4))
            path.addLine(to: CGPoint(x: x, y: -0.5))
            path.addQuadCurve(to: CGPoint(x: x + 0.08, y: -0.5), control: CGPoint(x: x + 0.04, y: -0.57))
            path.addLine(to: CGPoint(x: x + 0.08, y: -0.4))
            path.closeSubpath()
        }
        return path
    }()

    /// Moonlit roof edges.
    static let roofline: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.2, y: -0.66))
        path.addLine(to: CGPoint(x: 0, y: -1.0))
        path.addLine(to: CGPoint(x: 0.2, y: -0.66))
        path.move(to: CGPoint(x: 0.14, y: -0.3))
        path.addLine(to: CGPoint(x: 0.41, y: -0.44))
        path.addLine(to: CGPoint(x: 0.68, y: -0.3))
        return path
    }()

    /// A gnarled bare tree (about 1 unit tall, base at the origin).
    static let tree: (trunk: Path, twigs: Path) = {
        var trunk = Path()
        var twigs = Path()
        func grow(from p: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, seed: Int) {
            let bend = BG.hash(seed, 1302, -0.25, 0.25)
            let end = CGPoint(x: p.x + sin(angle) * length, y: p.y - cos(angle) * length)
            let control = CGPoint(x: (p.x + end.x) / 2 + cos(angle) * length * bend, y: (p.y + end.y) / 2 + sin(angle) * length * bend)
            if depth <= 2 {
                trunk.move(to: p)
                trunk.addQuadCurve(to: end, control: control)
            } else {
                twigs.move(to: p)
                twigs.addQuadCurve(to: end, control: control)
            }
            guard depth < 6 else { return }
            for c in 0..<2 {
                let childSeed = seed * 5 + c + 1
                let side: CGFloat = c == 0 ? -1 : 1
                grow(from: end, angle: angle + side * BG.hash(childSeed, 1303, 0.3, 0.75), length: length * BG.hash(childSeed, 1304, 0.6, 0.8), depth: depth + 1, seed: childSeed)
            }
        }
        grow(from: .zero, angle: -0.08, length: 0.32, depth: 0, seed: 23)
        return (trunk, twigs)
    }()
}

// MARK: - Scene

private enum OctoberScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: OctoberModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let frame = makeFrame(size: size, t: t, look: look)

        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.07, 0.05, 0.2), intensity: dark ? 0.32 : 0.12, depth: 0.65)
        if dark {
            // Moonlight washes out the faint stars.
            AtmospherePainter.stars(in: &ctx, size: size, time: time, count: 110, skyFraction: 0.55, intensity: Double(0.8 * (1 - 0.45 * frame.moonlight)))
        }
        drawShootingStar(in: &ctx, size: size, t: t)
        drawMoon(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark)
        drawClouds(in: &ctx, size: size, look: look, frame: frame)

        drawHills(in: &ctx, size: size, t: t, frame: frame, dark: dark)
        drawBelfry(in: &ctx, frame: frame, dark: dark)
        drawBats(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark, near: false)

        let blaze: CGFloat = 1 + 0.3 * look.halloween
        let flicker = (0.78 + 0.12 * sin(t * 13) + 0.1 * sin(t * 23.7 + 1)) * blaze
        drawPumpkin(in: &ctx, at: CGPoint(x: size.width * 0.055, y: size.height - 46), size: 78, flicker: flicker)
        drawPumpkin(in: &ctx, at: CGPoint(x: size.width * 0.94, y: size.height - 36), size: 58, flicker: (0.85 + 0.15 * sin(t * 17 + 2)) * blaze)
        drawFog(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark)
        drawWisps(in: &ctx, size: size, t: t, look: look)
        ctx.blurredLayer(radius: 2.5) { near in
            drawBats(in: &near, size: size, t: t, look: look, frame: frame, dark: dark, near: true)
        }
    }

    static func makeFrame(size: CGSize, t: CGFloat, look: OctoberModel.Look) -> OctoberFrame {
        // The moon swings slowly across the top of the sky (no wrap-around jump). A
        // harvest moon starts its swing a little lower and rises over about 3 minutes.
        let orbit = 2 * CGFloat.pi * t / 1500 + 0.95
        let rise = look.harvest * (1 - BG.smoothstep(0, 180, t))
        let radius = min(size.width, size.height) * 0.075 * (1 + 0.12 * look.harvest)
        let moon = CGPoint(
            x: size.width * (0.5 + 0.33 * sin(orbit)),
            y: size.height * (0.17 - 0.035 * cos(orbit) + 0.1 * rise)
        )

        var clouds: [OctoberCloud] = []
        clouds.reserveCapacity(4)
        var cover: CGFloat = 0
        for k in 0..<4 {
            let width = BG.hash(k, 171, 300, 460)
            let duration = BG.hash(k, 172, 70, 120)
            let progress = BG.fract(BG.hash(k, 173) + t / duration)
            let x = -width + progress * (size.width + width * 2)
            let y = size.height * BG.hash(k, 174, 0.08, 0.3)
            let edgeFade = BG.smoothstep(0, 0.12, progress) * (1 - BG.smoothstep(0.88, 1, progress))
            let opacity = Double(0.6 * edgeFade)
            clouds.append(OctoberCloud(center: CGPoint(x: x, y: y), width: width, opacity: opacity, seed: k + 200))
            let dx = (moon.x - x) / (width * 0.42)
            let dy = (moon.y - y) / (width * 0.2)
            cover = max(cover, CGFloat(opacity / 0.6) * (1 - BG.smoothstep(0.4, 1.05, sqrt(dx * dx + dy * dy))))
        }
        let belfryScale = min(size.height * 0.26, 260)
        return OctoberFrame(
            moon: moon,
            moonRadius: radius,
            cover: cover,
            moonlight: look.illumination * (1 - 0.75 * cover),
            clouds: clouds,
            belfry: CGPoint(x: size.width * 0.1, y: size.height - 18),
            belfryScale: belfryScale
        )
    }

    // MARK: Sky

    static func drawMoon(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: OctoberModel.Look, frame: OctoberFrame, dark: Bool) {
        let rise = Double(look.harvest * (1 - BG.smoothstep(0, 180, t)))
        var moon = ctx
        if look.harvest > 0.01 {
            // Harvest moon: warmer, and orange while it is still low.
            let warm = Double(look.harvest)
            moon.addFilter(.colorMultiply(BG.rgb(1, 0.95 - 0.12 * rise - 0.01 * warm, 0.84 - 0.32 * rise - 0.04 * warm)))
            ctx.glow(at: frame.moon, radius: frame.moonRadius * 4.2, color: BG.rgb(1, 0.92, 0.8), intensity: 0.12 * warm)
        }
        MoonPainter.draw(in: &moon, center: frame.moon, radius: frame.moonRadius, phase: look.phase)
        if !dark {
            ctx.stroke(BG.circle(frame.moon, frame.moonRadius), with: .color(BG.rgb(0.55, 0.6, 0.75, 0.6)), lineWidth: 1)
        }
    }

    /// Night clouds lit toward the moon. Over the disc they dim it, take a bright lining,
    /// and in thin cloud show a faint colored lunar corona.
    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, look: OctoberModel.Look, frame: OctoberFrame) {
        let lit = Double(look.illumination)
        let palette = CloudPalette(
            light: BG.rgb(0.55 + 0.35 * lit, 0.58 + 0.34 * lit, 0.7 + 0.28 * lit),
            body: CloudPalette.night.body,
            shade: CloudPalette.night.shade
        )
        for cloud in frame.clouds where cloud.opacity > 0.01 {
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: cloud.seed, width: cloud.width),
                center: cloud.center,
                width: cloud.width,
                palette: palette,
                opacity: cloud.opacity,
                lightDirection: CGVector(dx: frame.moon.x - cloud.center.x, dy: frame.moon.y - cloud.center.y),
                softness: 0.06
            )
        }
        let r = frame.moonRadius
        let thin = Double(BG.smoothstep(0.1, 0.35, frame.cover) * (1 - BG.smoothstep(0.65, 0.95, frame.cover)))
        if thin > 0.01 {
            // Lining where the cloud meets the disc, and a faint diffraction ring.
            ctx.glow(at: frame.moon, radius: r * 2.2, color: BG.rgb(0.85, 0.9, 1), intensity: 0.35 * thin * lit * (1 + 0.4 * Double(look.harvest)), additive: true)
            ctx.stroke(BG.circle(frame.moon, r * 1.4), with: .radialGradient(
                Gradient(colors: [BG.rgb(0.6, 0.7, 1, 0), BG.rgb(0.6, 0.75, 1, 0.12 * thin * lit), BG.rgb(1, 0.75, 0.6, 0.1 * thin * lit), BG.rgb(1, 0.7, 0.6, 0)]),
                center: frame.moon, startRadius: r * 1.25, endRadius: r * 1.55
            ), lineWidth: r * 0.3)
        }
    }

    /// Now and then a shooting star.
    static func drawShootingStar(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let period: CGFloat = 70
        let position = t / period + 0.4
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        guard age < 0.9, BG.hash(cycle, 1310) < 0.7 else { return }
        let start = CGPoint(x: size.width * BG.hash(cycle, 1311, 0.2, 0.8), y: size.height * BG.hash(cycle, 1312, 0.03, 0.15))
        let dir: CGFloat = BG.hash(cycle, 1313) < 0.5 ? -1 : 1
        let head = CGPoint(x: start.x + dir * age * 320, y: start.y + age * 110)
        let tail = CGPoint(x: head.x - dir * 90, y: head.y - 31)
        var streak = Path()
        streak.move(to: tail)
        streak.addLine(to: head)
        let fade = Double(sin(age / 0.9 * .pi))
        ctx.stroke(streak, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.85, 0.9, 1, 0), BG.rgb(0.95, 0.97, 1, 0.8 * fade)]),
            startPoint: tail, endPoint: head
        ), lineWidth: 1.4)
    }

    // MARK: Land

    static func hillY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.9 + 0.02 * sin(u * 3.4 + 0.4) + 0.008 * sin(u * 9.7 + 1.8))
    }

    /// Dark hills, a gnarled tree at the right with an owl that blinks and turns its
    /// head, and a crooked fence, all with moonlit edges.
    static func drawHills(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, frame: OctoberFrame, dark: Bool) {
        var hills = Path()
        var ridge = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            let p = CGPoint(x: x, y: hillY(x, size: size))
            hills.addLine(to: p)
            if x == 0 { ridge.move(to: p) } else { ridge.addLine(to: p) }
            x += 20
        }
        hills.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        hills.closeSubpath()
        let ink = dark ? BG.rgb(0.05, 0.04, 0.1, 0.85) : BG.rgb(0.45, 0.48, 0.6, 0.55)
        ctx.fill(hills, with: .color(ink))
        let rim = BG.rgb(0.75, 0.8, 1, Double(0.15 + 0.35 * frame.moonlight))
        ctx.stroke(ridge, with: .color(rim), lineWidth: 1)

        // Tree.
        let base = CGPoint(x: size.width * 0.84, y: hillY(size.width * 0.84, size: size) + 4)
        let scale = min(size.height * 0.3, 300)
        let sway = sin(t * 0.4) * 0.006
        var tree = ctx
        tree.translateBy(x: base.x, y: base.y)
        tree.rotate(by: .radians(Double(sway)))
        tree.scaleBy(x: scale, y: scale)
        tree.stroke(OctoberArt.tree.trunk, with: .color(ink), style: StrokeStyle(lineWidth: 0.026, lineCap: .round))
        tree.stroke(OctoberArt.tree.twigs, with: .color(ink), style: StrokeStyle(lineWidth: 0.008, lineCap: .round))

        // Owl on a low limb.
        let owl = CGPoint(x: base.x - scale * 0.05, y: base.y - scale * 0.42)
        let turn = sin(t * 0.21) > 0.6 ? 1 : 0
        let blink = BG.fract(t / 6.3) < 0.04
        var bird = ctx
        bird.translateBy(x: owl.x, y: owl.y)
        bird.scaleBy(x: 9, y: 9)
        bird.fill(BG.ellipse(CGPoint(x: 0, y: 0), 0.8, 1.05), with: .color(ink))
        var ears = Path()
        ears.move(to: CGPoint(x: -0.6, y: -0.7))
        ears.addLine(to: CGPoint(x: -0.5, y: -1.25))
        ears.addLine(to: CGPoint(x: -0.2, y: -0.85))
        ears.move(to: CGPoint(x: 0.6, y: -0.7))
        ears.addLine(to: CGPoint(x: 0.5, y: -1.25))
        ears.addLine(to: CGPoint(x: 0.2, y: -0.85))
        bird.fill(ears, with: .color(ink))
        if !blink {
            let look = CGFloat(turn) * 0.18
            for side in [-1.0, 1.0] as [CGFloat] {
                let eye = CGPoint(x: side * 0.32 + look, y: -0.45)
                bird.fill(BG.circle(eye, 0.2), with: .color(BG.rgb(1, 0.75, 0.2, 0.9)))
                bird.fill(BG.circle(eye, 0.08), with: .color(.black))
            }
        }

        // Fence.
        var fence = Path()
        for i in 0..<7 {
            let fx = size.width * (0.62 + CGFloat(i) * 0.03)
            let fy = hillY(fx, size: size) + 6
            let lean = BG.hash(i, 1320, -0.12, 0.12)
            fence.move(to: CGPoint(x: fx, y: fy))
            fence.addLine(to: CGPoint(x: fx + lean * 20, y: fy - 22))
        }
        let rail0 = CGPoint(x: size.width * 0.62, y: hillY(size.width * 0.62, size: size) - 8)
        let rail1 = CGPoint(x: size.width * 0.8, y: hillY(size.width * 0.8, size: size) - 8)
        fence.move(to: rail0)
        fence.addLine(to: rail1)
        ctx.stroke(fence, with: .color(ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    static func drawBelfry(in ctx: inout GraphicsContext, frame: OctoberFrame, dark: Bool) {
        let transform = CGAffineTransform(translationX: frame.belfry.x, y: frame.belfry.y).scaledBy(x: frame.belfryScale, y: frame.belfryScale)
        let ink = dark ? BG.rgb(0.05, 0.04, 0.09, 0.95) : BG.rgb(0.48, 0.51, 0.6, 0.6)
        ctx.fill(OctoberArt.belfry.applying(transform), with: .color(ink))
        ctx.fill(OctoberArt.openings.applying(transform), with: .color(dark ? BG.rgb(0.12, 0.1, 0.2) : BG.rgb(0.35, 0.37, 0.45, 0.7)))
        ctx.stroke(OctoberArt.roofline.applying(transform), with: .color(BG.rgb(0.78, 0.84, 1, Double(0.12 + 0.45 * frame.moonlight))), lineWidth: 1.2)
    }

    // MARK: Bats

    /// Where the flock's lead is at time `t`: a slow wander through the upper sky,
    /// biased toward the sides, with the Halloween sweep across the moon.
    static func lead(_ t: CGFloat, size: CGSize, look: OctoberModel.Look, frame: OctoberFrame) -> CGPoint {
        let wander = sin(t * 0.045 + 0.3 * sin(t * 0.13))
        let side = wander + 0.25 * (wander >= 0 ? 1 : -1) * (1 - abs(wander))
        var p = CGPoint(
            x: size.width * (0.5 + 0.36 * max(-1, min(1, side))),
            y: size.height * (0.26 + 0.1 * sin(t * 0.07 + 1) + 0.04 * sin(t * 0.19))
        )
        // Halloween: a tight pass straight across the moon's face. It is a function of
        // time, so bats further back along the ribbon follow the lead through it.
        let a = t - look.sweepStart
        if a > 0 && a < 6.5 {
            let env = BG.smoothstep(0, 1.5, a) * (1 - BG.smoothstep(4.5, 6.5, a))
            let across = CGPoint(x: frame.moon.x + (a - 3) * 120, y: frame.moon.y + sin(a * 2) * 10)
            p = CGPoint(x: BG.lerp(p.x, across.x, env), y: BG.lerp(p.y, across.y, env))
        }
        return p
    }

    /// The murmuration. Each bat sits somewhere along a ribbon that trails the lead
    /// path, offset across it, with ripple waves running down the ribbon. The cycle:
    /// emerge from the belfry, murmurate, scatter, return, rest.
    static func drawBats(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: OctoberModel.Look, frame: OctoberFrame, dark: Bool, near: Bool) {
        let colony = near ? 8 : 52
        let extra = near ? 4 : 44
        let count = colony + Int(CGFloat(extra) * look.halloween)
        let period: CGFloat = 88
        let c = BG.fract(t / period + 0.02) * period
        // On Halloween the colony stays out (no return or rest); blended so switching
        // days never teleports a bat.
        let stayOut = look.halloween
        let home = CGPoint(x: frame.belfry.x, y: frame.belfry.y - frame.belfryScale * 0.48)
        // Clouds over the moon loosen the flock; scatter loosens it more.
        let scatter = BG.smoothstep(58, 61, c) * (1 - BG.smoothstep(63, 66, c))
        let dodge = pow(max(0, sin(t * 0.37)), 30)
        let spread = 1 + 0.3 * frame.cover + 1.2 * scatter + 0.6 * dodge
        let rimAlpha = Double(0.1 + 0.45 * frame.moonlight)

        for i in 0..<count {
            let seed = i + (near ? 5000 : 0)
            let f = CGFloat(i) / CGFloat(max(count - 1, 1))
            // Position along the ribbon (trailing the lead) and across it.
            let along = BG.hash(seed, 1330)
            let across = BG.hash(seed, 1331, -1, 1)
            let lag = along * 6
            let center = lead(t - lag, size: size, look: look, frame: frame)
            let ahead = lead(t - lag + 0.3, size: size, look: look, frame: frame)
            let tx = ahead.x - center.x
            let ty = ahead.y - center.y
            let length = max(0.001, sqrt(tx * tx + ty * ty))
            let nx = -ty / length
            let ny = tx / length
            let ripple = sin(along * 9 - t * 1.6) * 18 * pow(max(0, sin(t * 0.13 + 1)), 2)
            let width = (26 + 40 * along) * spread
            let jitter = CGPoint(x: sin(t * BG.hash(seed, 1332, 0.6, 1.4) + CGFloat(i)) * 12 * spread, y: cos(t * BG.hash(seed, 1333, 0.5, 1.2) + CGFloat(i)) * 9 * spread)
            let ribbon = CGPoint(
                x: center.x + nx * (across * width + ripple) + jitter.x,
                y: center.y + ny * (across * width + ripple) + jitter.y
            )
            var p = ribbon
            var visible: CGFloat = 1

            // Emerge: pour out of the belfry in a column, spiralling up into place.
            let join = 0.6 + 7 * f
            if c < join + 3.5 {
                let u = BG.smoothstep(join, join + 3.5, c)
                let s = max(0, c - join)
                let spiral = CGPoint(x: home.x + sin(s * 4 + CGFloat(i)) * 20 * s, y: home.y - s * 40)
                p = CGPoint(x: BG.lerp(spiral.x, p.x, u), y: BG.lerp(spiral.y, p.y, u))
                visible = BG.smoothstep(join, join + 0.4, c)
            }
            // Return: funnel down and back home, staggered.
            let leave = 66 + 8 * f
            if c > leave {
                let u = BG.smoothstep(leave, leave + 3.5, c)
                p = CGPoint(x: BG.lerp(p.x, home.x, u), y: BG.lerp(p.y, home.y, u))
                visible = 1 - BG.smoothstep(leave + 3, leave + 3.5, c)
            }
            // Rest: a few stragglers flit about the belfry.
            if c > 78 && i < 3 && !near {
                let a = t * 1.3 + CGFloat(i) * 2.1
                p = CGPoint(x: home.x + cos(a) * 50, y: home.y - 30 + sin(a * 1.7) * 20)
                visible = BG.smoothstep(78, 79, c) * (1 - BG.smoothstep(87, 88, c))
            }
            if stayOut > 0.001 {
                p = CGPoint(x: BG.lerp(p.x, ribbon.x, stayOut), y: BG.lerp(p.y, ribbon.y, stayOut))
                visible = BG.lerp(visible, 1, stayOut)
            }
            guard visible > 0.01 else { continue }

            let flap = sin(t * BG.hash(seed, 1334, 13, 19) + BG.hash(seed, 1335) * 6.28)
            let batSize = near ? BG.hash(seed, 1336, 44, 60) : BG.hash(seed, 1336, 18, 36)
            let bank = max(-0.5, min(0.5, ty / max(length, 1) * 0.8))
            drawBat(in: &ctx, at: p, size: batSize, flap: flap, bank: bank, moon: frame.moon, rim: rimAlpha, opacity: Double(visible), dark: dark)
        }
    }

    static func drawBat(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, flap: CGFloat, bank: CGFloat, moon: CGPoint, rim: Double, opacity: Double, dark: Bool) {
        var bat = ctx
        bat.opacity = opacity
        bat.translateBy(x: p.x, y: p.y)
        bat.rotate(by: .radians(Double(bank)))
        bat.scaleBy(x: size, y: size)

        let tipY = -0.32 * flap
        let wristY = -0.18 * flap - 0.05
        var wing = Path()
        wing.move(to: CGPoint(x: 0.05, y: -0.05))
        wing.addQuadCurve(to: CGPoint(x: 0.26, y: wristY), control: CGPoint(x: 0.14, y: wristY - 0.08))
        wing.addLine(to: CGPoint(x: 0.5, y: tipY))
        wing.addQuadCurve(to: CGPoint(x: 0.37, y: tipY * 0.4 + 0.1), control: CGPoint(x: 0.4, y: tipY * 0.7 + 0.02))
        wing.addQuadCurve(to: CGPoint(x: 0.22, y: wristY * 0.3 + 0.13), control: CGPoint(x: 0.27, y: wristY * 0.3 + 0.03))
        wing.addQuadCurve(to: CGPoint(x: 0.04, y: 0.1), control: CGPoint(x: 0.1, y: 0.03))
        wing.closeSubpath()

        var silhouette = Path()
        silhouette.addPath(wing)
        silhouette.addPath(wing.applying(CGAffineTransform(scaleX: -1, y: 1)))
        silhouette.addPath(BG.ellipse(CGPoint(x: 0, y: 0.02), 0.07, 0.13))
        silhouette.addPath(BG.circle(CGPoint(x: 0, y: -0.12), 0.055))
        silhouette.move(to: CGPoint(x: -0.05, y: -0.14))
        silhouette.addLine(to: CGPoint(x: -0.04, y: -0.24))
        silhouette.addLine(to: CGPoint(x: -0.012, y: -0.16))
        silhouette.move(to: CGPoint(x: 0.05, y: -0.14))
        silhouette.addLine(to: CGPoint(x: 0.04, y: -0.24))
        silhouette.addLine(to: CGPoint(x: 0.012, y: -0.16))

        bat.fill(silhouette, with: .color(dark ? BG.rgb(0.07, 0.05, 0.1, 0.92) : BG.rgb(0.36, 0.4, 0.5, 0.7)))
        // Moonlit rim on the edges facing the moon.
        let toMoon = CGVector(dx: moon.x - p.x, dy: moon.y - p.y)
        let distance = max(1, sqrt(toMoon.dx * toMoon.dx + toMoon.dy * toMoon.dy))
        bat.stroke(silhouette, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.75, 0.8, 1, rim), BG.rgb(0.75, 0.8, 1, 0)]),
            startPoint: CGPoint(x: toMoon.dx / distance * 0.5, y: toMoon.dy / distance * 0.5),
            endPoint: .zero
        ), lineWidth: 0.025)
    }

    // MARK: Ground

    static func drawPumpkin(in ctx: inout GraphicsContext, at p: CGPoint, size s: CGFloat, flicker: CGFloat) {
        let candle = BG.rgb(1, 0.6, 0.12)
        let groundShadow = CGPoint(x: p.x, y: p.y + s * 0.34)
        ctx.fill(
            BG.ellipse(groundShadow, s * 0.5, s * 0.07),
            with: .radialGradient(Gradient(colors: [.black.opacity(0.35), .black.opacity(0)]), center: groundShadow, startRadius: 0, endRadius: s * 0.5)
        )
        ctx.glow(at: p, radius: s * 1.8, color: candle, intensity: Double(0.32 * flicker))

        // Ribbed body, outer ribs first.
        for j in [-2, 2, -1, 1, 0] {
            let offset = CGFloat(j) * s * 0.15
            let rib = BG.ellipse(CGPoint(x: p.x + offset, y: p.y), s * (0.26 - abs(CGFloat(j)) * 0.025), s * 0.36)
            ctx.fill(rib, with: .linearGradient(
                Gradient(colors: [BG.rgb(1, 0.62, 0.15), BG.rgb(0.88, 0.4, 0.04), BG.rgb(0.5, 0.18, 0.02)]),
                startPoint: CGPoint(x: p.x + offset - s * 0.25, y: p.y - s * 0.3),
                endPoint: CGPoint(x: p.x + offset + s * 0.25, y: p.y + s * 0.35)
            ))
            ctx.stroke(rib, with: .color(BG.rgb(0.45, 0.15, 0.0, 0.5)), lineWidth: s * 0.012)
        }
        ctx.fill(BG.ellipse(CGPoint(x: p.x - s * 0.18, y: p.y - s * 0.18), s * 0.06, s * 0.1), with: .color(.white.opacity(0.18)))

        var stem = Path()
        stem.move(to: CGPoint(x: p.x - s * 0.045, y: p.y - s * 0.32))
        stem.addQuadCurve(to: CGPoint(x: p.x + s * 0.03, y: p.y - s * 0.47), control: CGPoint(x: p.x - s * 0.04, y: p.y - s * 0.42))
        stem.addLine(to: CGPoint(x: p.x + s * 0.07, y: p.y - s * 0.44))
        stem.addQuadCurve(to: CGPoint(x: p.x + s * 0.04, y: p.y - s * 0.31), control: CGPoint(x: p.x + s * 0.03, y: p.y - s * 0.38))
        stem.closeSubpath()
        ctx.fill(stem, with: .linearGradient(Gradient(colors: [BG.rgb(0.4, 0.45, 0.18), BG.rgb(0.2, 0.2, 0.08)]), startPoint: CGPoint(x: p.x - s * 0.05, y: p.y - s * 0.4), endPoint: CGPoint(x: p.x + s * 0.07, y: p.y - s * 0.4)))

        // Carved face, lit from within.
        var face = Path()
        for side in [-1.0, 1.0] as [CGFloat] {
            face.move(to: CGPoint(x: p.x + side * s * 0.2, y: p.y - s * 0.02))
            face.addLine(to: CGPoint(x: p.x + side * s * 0.13, y: p.y - s * 0.15))
            face.addLine(to: CGPoint(x: p.x + side * s * 0.06, y: p.y - s * 0.02))
            face.closeSubpath()
        }
        face.move(to: CGPoint(x: p.x - s * 0.035, y: p.y + s * 0.07))
        face.addLine(to: CGPoint(x: p.x, y: p.y + s * 0.01))
        face.addLine(to: CGPoint(x: p.x + s * 0.035, y: p.y + s * 0.07))
        face.closeSubpath()
        let mouthLeft = p.x - s * 0.24
        let mouthTop = p.y + s * 0.11
        face.move(to: CGPoint(x: mouthLeft, y: mouthTop))
        for i in 1...6 {
            let x = mouthLeft + s * 0.48 * CGFloat(i) / 6
            face.addLine(to: CGPoint(x: x - s * 0.04, y: mouthTop + (i % 2 == 0 ? s * 0.05 : 0)))
        }
        face.addLine(to: CGPoint(x: p.x + s * 0.24, y: mouthTop))
        face.addQuadCurve(to: CGPoint(x: mouthLeft, y: mouthTop), control: CGPoint(x: p.x, y: mouthTop + s * 0.22))
        face.closeSubpath()
        let f = Double(min(flicker, 1.3))
        ctx.fill(face, with: .radialGradient(
            Gradient(colors: [BG.rgb(1, 0.97, 0.7, min(1, f)), BG.rgb(1, 0.6, 0.08, min(1, f)), BG.rgb(0.7, 0.25, 0.02)]),
            center: CGPoint(x: p.x, y: p.y + s * 0.05),
            startRadius: 0,
            endRadius: s * 0.3
        ))
        ctx.stroke(face, with: .color(BG.rgb(0.4, 0.12, 0.0, 0.6)), lineWidth: s * 0.01)
    }

    /// Ground fog drifting over the pumpkins. It brightens beneath the moon, takes a warm
    /// glow around each pumpkin, and thickens on Halloween.
    static func drawFog(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: OctoberModel.Look, frame: OctoberFrame, dark: Bool) {
        let thick = 1 + 0.5 * look.halloween
        let base = dark ? BG.rgb(0.72, 0.7, 0.85) : BG.rgb(0.8, 0.78, 0.92)
        let maxAlpha = (dark ? 0.32 : 0.18) * Double(thick)
        ctx.blurredLayer(radius: 24) { fog in
            for i in 0..<5 {
                let x = BG.wrap(BG.hash(i, 181) * size.width + look.drift * BG.hash(i, 182, 0.6, 1.6), length: size.width, margin: size.width * 0.3)
                let y = size.height * BG.hash(i, 183, 0.94, 1.0)
                let rx = size.width * BG.hash(i, 184, 0.25, 0.4)
                let ry = size.height * BG.hash(i, 185, 0.04, 0.07) * thick
                let center = CGPoint(x: x, y: y)
                fog.fill(BG.ellipse(center, rx, ry), with: .radialGradient(
                    Gradient(colors: [base.opacity(maxAlpha), base.opacity(0)]),
                    center: center, startRadius: 0, endRadius: rx
                ))
            }
            // Moonlit patch beneath the moon.
            let under = CGPoint(x: frame.moon.x, y: size.height * 0.97)
            fog.fill(BG.ellipse(under, size.width * 0.2, size.height * 0.04), with: .radialGradient(
                Gradient(colors: [BG.rgb(0.85, 0.88, 1, 0.22 * Double(frame.moonlight)), BG.rgb(0.85, 0.88, 1, 0)]),
                center: under, startRadius: 0, endRadius: size.width * 0.2
            ))
            // Candlelight spilling into the fog.
            for x in [size.width * 0.055, size.width * 0.94] {
                let c = CGPoint(x: x, y: size.height - 30)
                fog.fill(BG.circle(c, 110), with: .radialGradient(
                    Gradient(colors: [BG.rgb(1, 0.6, 0.2, 0.18 * Double(thick)), BG.rgb(1, 0.6, 0.2, 0)]),
                    center: c, startRadius: 0, endRadius: 110
                ))
            }
        }
    }

    /// Halloween: three faint green-white wisps winding through the fog.
    static func drawWisps(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: OctoberModel.Look) {
        guard look.halloween > 0.01 else { return }
        ctx.blurredLayer(radius: 3) { wisps in
            for k in 0..<3 {
                var ribbon = Path()
                let x0 = BG.wrap(BG.hash(k, 1340) * size.width + t * BG.hash(k, 1341, 10, 22), length: size.width, margin: 160)
                let y0 = size.height * BG.hash(k, 1342, 0.86, 0.95)
                for j in 0...16 {
                    let u = CGFloat(j) / 16
                    let p = CGPoint(
                        x: x0 - u * 150,
                        y: y0 + sin(u * 6 + t * 1.3 + CGFloat(k)) * 10 - sin(u * CGFloat.pi) * 18
                    )
                    if j == 0 { ribbon.move(to: p) } else { ribbon.addLine(to: p) }
                }
                wisps.stroke(ribbon, with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.8, 1, 0.85, 0.5 * Double(look.halloween)), BG.rgb(0.8, 1, 0.85, 0)]),
                    startPoint: CGPoint(x: x0, y: y0),
                    endPoint: CGPoint(x: x0 - 150, y: y0)
                ), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }
}
