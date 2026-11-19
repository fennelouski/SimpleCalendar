//
//  SeptemberScene.swift
//  Simple Calendar
//
//  September: a long golden late afternoon as the first leaves let go.
//
//  The low sun's light is the star. Broad sunbeams fan out through the amber haze and
//  sweep slowly as they breathe, and passing clouds dim them all at once. One light
//  field (`SeptemberFrame.light(at:)`) drives everything they touch: leaves flare warm
//  and translucent as they tumble through a beam, dust motes only show inside one,
//  dew on a spider web glints as a beam crosses it, and the seed heads along the
//  bottom catch a golden rim. A gentle integrated breeze carries it all.
//
//  The scene also follows the selected day:
//    * month progress - more leaves fall, turning from green-gold to red and orange
//    * daylight       - shorter days lower and warm the sun
//    * equinox        - a strong gust releases a flurry of leaves and the light turns
//                       fully golden
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct SeptemberLeavesAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = SeptemberModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = SeptemberModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            SeptemberScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class SeptemberModel {
    struct Target {
        let progress: Double
        /// 0 on the longest September day ... 1 on the shortest.
        let shortDay: Double
        let equinox: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            progress = day.progress
            shortDay = 1 - min(max((day.daylightHours - 11.6) / 1.3, 0), 1)
            equinox = day.isSeasonDay(2) ? 1 : 0
        }
    }

    struct Look {
        var progress: CGFloat
        var shortDay: CGFloat
        var equinox: CGFloat
        /// Wind displacement accumulated since the scene appeared.
        var drift: CGFloat
        var wind: CGFloat
        /// Seconds into the equinox leaf release, or -1.
        var releaseAge: CGFloat

        var warmth: CGFloat { max(BG.lerp(0.5, 0.65, shortDay), 0.8 * equinox) }
        /// Fraction of the leaf particles in play (30% on the 1st, all by the end).
        var leafAmount: CGFloat { BG.lerp(0.3, 1, progress) }
    }

    static let releaseDuration: Double = 16

    private let progressTransition = SceneTransition()
    private let daylightTransition = SceneTransition()
    private let equinoxTransition = SceneTransition()
    private let release = SceneMoment(duration: SeptemberModel.releaseDuration)
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let progress = progressTransition.value(target: target.progress, time: time)
        let short = daylightTransition.value(target: target.shortDay, time: time)
        let equinox = equinoxTransition.value(target: target.equinox, time: time)

        var releaseAge: CGFloat = -1
        var surge: CGFloat = 0
        if let age = release.elapsed(arrived: equinox > 0.999, time: time) {
            releaseAge = CGFloat(age)
            // The release gust: wind x4 for about 3 s.
            surge = BG.smoothstep(0, 0.5, releaseAge) * (1 - BG.smoothstep(2.5, 3.5, releaseAge))
        }

        let wind = SeptemberAir.breeze(CGFloat(time)) * (1 + 3 * surge)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * wind
        }
        lastTime = time

        return Look(
            progress: CGFloat(progress),
            shortDay: CGFloat(short),
            equinox: CGFloat(equinox),
            drift: drift,
            wind: wind,
            releaseAge: releaseAge
        )
    }
}

// MARK: - Air and light

private enum SeptemberAir {
    /// Breeze in points per second: base 14 with smooth 10-27 s gusts (never reverses).
    static func breeze(_ t: CGFloat) -> CGFloat {
        14 + 18 * (0.45 * sin(t * 0.23) + 0.3 * sin(t * 0.61 + 1) + 0.15 * sin(t * 0.41 + 2.6))
    }

    /// 0...1 gust strength, reaching a point at `x` a little later than the left edge.
    static func gust(at x: CGFloat, _ t: CGFloat) -> CGFloat {
        let s = t - x / 500
        return BG.smoothstep(-0.3, 0.8, 0.45 * sin(s * 0.23) + 0.3 * sin(s * 0.61 + 1) + 0.15 * sin(s * 0.41 + 2.6))
    }
}

/// A sunbeam fanning out of the sun.
private struct SeptemberBeam {
    var angle: CGFloat
    var spread: CGFloat
    var strength: CGFloat
}

/// Everything about the light in one frame.
private struct SeptemberFrame {
    var sun: CGPoint
    var sunRadius: CGFloat
    var sunFade: CGFloat
    /// 0 (sun behind a cloud) ... 1 (clear).
    var sunlight: CGFloat
    var beams: [SeptemberBeam]
    var reach: CGFloat

    /// 0...1 golden light falling on a point: a soft glow around the sun, plus the
    /// beams, all dimmed together when a cloud covers the sun.
    func light(at p: CGPoint) -> CGFloat {
        let dx = p.x - sun.x
        let dy = p.y - sun.y
        let distance = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        var beam: CGFloat = 0
        for b in beams {
            let off = abs(angle - b.angle)
            beam = max(beam, (1 - BG.smoothstep(b.spread * 0.4, b.spread * 1.6, off)) * b.strength)
        }
        let falloff = 1 - BG.smoothstep(reach * 0.15, reach, distance) * 0.55
        let halo = 1 - BG.smoothstep(0, reach * 0.4, distance)
        return BG.clamp01((0.75 * beam * falloff + 0.4 * halo) * sunlight * sunFade)
    }
}

// MARK: - Leaf colors

private struct SeptemberHue {
    let r: Double, g: Double, b: Double

    func mix(_ other: SeptemberHue, _ amount: Double) -> Color {
        BG.rgb(r + (other.r - r) * amount, g + (other.g - g) * amount, b + (other.b - b) * amount)
    }
}

private struct SeptemberTones {
    let light: SeptemberHue, dark: SeptemberHue, vein: SeptemberHue

    init(_ light: (Double, Double, Double), _ dark: (Double, Double, Double), _ vein: (Double, Double, Double)) {
        self.light = SeptemberHue(r: light.0, g: light.1, b: light.2)
        self.dark = SeptemberHue(r: dark.0, g: dark.1, b: dark.2)
        self.vein = SeptemberHue(r: vein.0, g: vein.1, b: vein.2)
    }
}

private enum SeptemberLeaves {
    /// Early month: green-gold and olive, a little yellow.
    static let early: [SeptemberTones] = [
        SeptemberTones((0.72, 0.76, 0.3), (0.42, 0.48, 0.12), (0.9, 0.92, 0.6)),
        SeptemberTones((0.62, 0.68, 0.28), (0.3, 0.36, 0.1), (0.82, 0.86, 0.55)),
        SeptemberTones((0.9, 0.82, 0.3), (0.6, 0.5, 0.08), (1, 0.95, 0.6)),
        SeptemberTones((0.78, 0.72, 0.3), (0.5, 0.42, 0.1), (0.95, 0.9, 0.6)),
        SeptemberTones((0.68, 0.7, 0.25), (0.38, 0.42, 0.1), (0.88, 0.9, 0.55))
    ]

    /// Late month: the full autumn set.
    static let late: [SeptemberTones] = [
        SeptemberTones((1, 0.72, 0.2), (0.85, 0.3, 0.05), (1, 0.85, 0.5)),
        SeptemberTones((0.95, 0.3, 0.15), (0.55, 0.06, 0.08), (1, 0.6, 0.45)),
        SeptemberTones((1, 0.88, 0.3), (0.8, 0.55, 0.05), (1, 0.95, 0.65)),
        SeptemberTones((0.75, 0.45, 0.2), (0.4, 0.2, 0.08), (0.9, 0.65, 0.4)),
        SeptemberTones((0.95, 0.55, 0.2), (0.7, 0.2, 0.1), (1, 0.8, 0.5))
    ]

    /// Each leaf turns at its own threshold, so the canopy colors gradually through the
    /// month (and smoothly during a transition) instead of all at once.
    static func palette(seed: Int, progress: CGFloat) -> LeafPalette {
        let index = Int(BG.hash(seed, 159) * 5) % 5
        let threshold = BG.hash(seed, 171, 0.05, 0.95)
        let turn = Double(BG.smoothstep(threshold - 0.25, threshold + 0.25, progress))
        let a = early[index]
        let b = late[index]
        return LeafPalette(light: a.light.mix(b.light, turn), dark: a.dark.mix(b.dark, turn), vein: a.vein.mix(b.vein, turn))
    }
}

extension CloudPalette {
    /// Golden-hour cumulus: warm lit tops, rosy undersides.
    static let septemberGold = CloudPalette(
        light: BG.rgb(1, 0.97, 0.9),
        body: BG.rgb(0.98, 0.88, 0.78),
        shade: BG.rgb(0.8, 0.62, 0.64)
    )
}

// MARK: - Art

private struct SeptemberBranchArt {
    var thick = Path()
    var thin = Path()
    var tips: [CGPoint] = []
}

private enum SeptemberArt {
    /// Leafy limb reaching in from the top-left corner (about 1 unit long).
    static let branch: SeptemberBranchArt = {
        var art = SeptemberBranchArt()
        func grow(from p: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, seed: Int) {
            let end = CGPoint(x: p.x + cos(angle) * length, y: p.y + sin(angle) * length)
            if depth <= 1 {
                art.thick.move(to: p)
                art.thick.addLine(to: end)
            } else {
                art.thin.move(to: p)
                art.thin.addLine(to: end)
            }
            guard depth < 4 else {
                art.tips.append(end)
                return
            }
            for c in 0..<2 {
                let childSeed = seed * 3 + c + 1
                let side: CGFloat = c == 0 ? -1 : 1
                let childAngle = angle + side * BG.hash(childSeed, 601, 0.3, 0.6)
                grow(from: end, angle: childAngle, length: length * BG.hash(childSeed, 602, 0.62, 0.8), depth: depth + 1, seed: childSeed)
            }
            if depth >= 2 {
                art.tips.append(CGPoint(x: (p.x + end.x) / 2, y: (p.y + end.y) / 2))
            }
        }
        grow(from: .zero, angle: 0.5, length: 0.36, depth: 0, seed: 5)
        return art
    }()

    /// Orb web (radius 1): radial spokes and a sagging spiral.
    static let spokes = 14
    static let rings = 9

    static func webPoint(spoke: Int, ring: Int) -> CGPoint {
        let a = CGFloat(spoke) / CGFloat(spokes) * 2 * CGFloat.pi + BG.hash(spoke, 610, -0.08, 0.08)
        let r = 0.14 + 0.86 * CGFloat(ring) / CGFloat(rings - 1)
        return CGPoint(x: cos(a) * r, y: sin(a) * r)
    }

    static let web: Path = {
        var path = Path()
        for s in 0..<spokes {
            path.move(to: .zero)
            path.addLine(to: webPoint(spoke: s, ring: rings - 1))
        }
        for ring in 0..<rings {
            for s in 0...spokes {
                let p = webPoint(spoke: s % spokes, ring: ring)
                if s == 0 {
                    path.move(to: p)
                } else {
                    let q = webPoint(spoke: s - 1, ring: ring)
                    // Each strand sags slightly toward the hub between spokes.
                    let mid = CGPoint(x: (p.x + q.x) * 0.46, y: (p.y + q.y) * 0.46)
                    path.addQuadCurve(to: p, control: mid)
                }
            }
        }
        return path
    }()

    /// Where dew beads sit on the web.
    static let beads: [CGPoint] = (0..<44).map { (i: Int) -> CGPoint in
        let spoke = Int(BG.hash(i, 612) * CGFloat(spokes)) % spokes
        let ring = 1 + Int(BG.hash(i, 613) * CGFloat(rings - 1)) % (rings - 1)
        let a = webPoint(spoke: spoke, ring: ring)
        let b = webPoint(spoke: (spoke + 1) % spokes, ring: ring)
        let u = BG.hash(i, 614, 0.2, 0.8)
        return CGPoint(x: BG.lerp(a.x, b.x, u) * 0.94, y: BG.lerp(a.y, b.y, u) * 0.94)
    }
}

// MARK: - Scene

private enum SeptemberScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: SeptemberModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let frame = makeFrame(size: size, t: t, look: look)

        drawSky(in: &ctx, size: size, look: look, frame: frame, dark: dark)
        drawSun(in: &ctx, frame: frame, look: look, dark: dark)
        drawClouds(in: &ctx, size: size, t: t, look: look, frame: frame)
        drawBeams(in: &ctx, size: size, frame: frame, look: look)
        drawGeese(in: &ctx, size: size, t: t)
        drawHills(in: &ctx, size: size, frame: frame, look: look)

        ctx.blurredLayer(radius: 1.6) { far in
            for i in 0..<30 {
                drawFalling(layer: 0, index: i, in: &far, size: size, t: t, look: look, frame: frame)
            }
        }
        drawMotes(in: &ctx, size: size, t: t, look: look, frame: frame)
        for i in 0..<40 {
            drawFalling(layer: 1, index: i, in: &ctx, size: size, t: t, look: look, frame: frame)
        }
        drawRelease(in: &ctx, size: size, t: t, look: look, frame: frame)
        drawGrass(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark)
        drawBranch(in: &ctx, size: size, t: t, look: look, frame: frame)
        drawWeb(in: &ctx, size: size, t: t, look: look, frame: frame, dark: dark)

        ctx.blurredLayer(radius: 5) { near in
            for i in 0..<6 {
                drawFalling(layer: 2, index: i, in: &near, size: size, t: t, look: look, frame: frame)
            }
        }
    }

    static func makeFrame(size: CGSize, t: CGFloat, look: SeptemberModel.Look) -> SeptemberFrame {
        let r: CGFloat = 58
        let progress = BG.fract(0.7 + t / 4000)
        let margin = r * 4
        let height = BG.lerp(0.13, 0.17, look.shortDay)
        let sun = CGPoint(
            x: -margin + progress * (size.width + margin * 2),
            y: size.height * (height + 0.05) - size.height * 0.07 * 4 * progress * (1 - progress)
        )
        let fade = BG.smoothstep(0, 0.03, progress) * (1 - BG.smoothstep(0.97, 1, progress))

        var cover: CGFloat = 0
        for k in 0..<5 {
            let c = cloud(k, size: size, look: look)
            let dx = (sun.x - c.center.x) / (c.width * 0.42)
            let dy = (sun.y - c.center.y) / (c.width * 0.2)
            cover = max(cover, CGFloat(c.opacity) * (1 - BG.smoothstep(0.45, 1.05, sqrt(dx * dx + dy * dy))))
        }

        var beams: [SeptemberBeam] = []
        beams.reserveCapacity(7)
        for k in 0..<7 {
            let kk = CGFloat(k)
            let angle = BG.lerp(0.35, 2.8, (kk + 0.5) / 7) + 0.12 * sin(t * 0.05 + kk * 1.7) + 0.05 * sin(t * 0.13 + kk)
            let breathe = 0.55 + 0.45 * sin(t * 0.21 + kk * 2.3)
            beams.append(SeptemberBeam(angle: angle, spread: BG.hash(k, 620, 0.04, 0.085), strength: breathe))
        }
        return SeptemberFrame(
            sun: sun,
            sunRadius: r,
            sunFade: fade,
            sunlight: 1 - 0.8 * cover,
            beams: beams,
            reach: max(size.width, size.height) * 1.1
        )
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, look: SeptemberModel.Look, frame: SeptemberFrame, dark: Bool) {
        let warm = Double(look.warmth)
        let haze: Double = dark ? 1 : 0.5
        let sky = Gradient(stops: [
            .init(color: BG.rgb(0.55, 0.5, 0.62, 0.16), location: 0),
            .init(color: BG.rgb(1, 0.78 - 0.08 * warm, 0.5 - 0.1 * warm, 0.12), location: 0.5),
            .init(color: BG.rgb(1, 0.72 - 0.1 * warm, 0.4, 0.18), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        let progress = Double(look.progress)
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.8, 0.55), intensity: 0.2 * haze * (1 + 0.15 * progress), depth: 0.5)
        AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(1, 0.75, 0.45), intensity: 0.12 * haze * (1 + 0.15 * progress), depth: 0.3)
    }

    static func drawSun(in ctx: inout GraphicsContext, frame: SeptemberFrame, look: SeptemberModel.Look, dark: Bool) {
        let fade = Double(frame.sunFade)
        guard fade > 0.01 else { return }
        let c = frame.sun
        let r = frame.sunRadius
        let warm = Double(look.warmth)
        let veil = 0.5 + 0.5 * Double(frame.sunlight)
        let mid = BG.rgb(1, 0.85 - 0.12 * warm, 0.45 - 0.2 * warm)
        let rim = BG.rgb(1, 0.66 - 0.12 * warm, 0.22 - 0.08 * warm)
        ctx.glow(at: c, radius: r * 8, color: mid, intensity: 0.3 * fade * veil)
        ctx.glow(at: c, radius: r * 2.6, color: mid, intensity: 0.7 * fade * veil)
        let disc = Gradient(stops: [
            .init(color: BG.rgb(1, 0.99, 0.92), location: 0),
            .init(color: BG.rgb(1, 0.97, 0.85), location: 0.4),
            .init(color: mid, location: 0.82),
            .init(color: rim, location: 1)
        ])
        var sun = ctx
        sun.opacity = fade
        sun.fill(BG.circle(c, r), with: .radialGradient(disc, center: CGPoint(x: c.x - r * 0.1, y: c.y - r * 0.12), startRadius: 0, endRadius: r * 1.1))
        if !dark {
            sun.stroke(BG.circle(c, r), with: .color(rim.opacity(0.6)), lineWidth: 2)
        }
        sun.glow(at: c, radius: r * 1.3, color: BG.rgb(1, 0.97, 0.88), intensity: 0.45 * veil, additive: true)
    }

    /// Broad beams fanning through the haze. They are the same beams `light(at:)` reads.
    static func drawBeams(in ctx: inout GraphicsContext, size: CGSize, frame: SeptemberFrame, look: SeptemberModel.Look) {
        let base = Double(frame.sunlight * frame.sunFade)
        guard base > 0.02 else { return }
        let sun = frame.sun
        let length = frame.reach
        let warm = Double(look.warmth)
        ctx.blurredLayer(radius: 24) { shafts in
            for beam in frame.beams {
                var wedge = Path()
                wedge.move(to: sun)
                wedge.addLine(to: CGPoint(x: sun.x + cos(beam.angle - beam.spread) * length, y: sun.y + sin(beam.angle - beam.spread) * length))
                wedge.addLine(to: CGPoint(x: sun.x + cos(beam.angle + beam.spread) * length, y: sun.y + sin(beam.angle + beam.spread) * length))
                wedge.closeSubpath()
                let alpha = base * Double(0.06 + 0.1 * beam.strength)
                shafts.fill(
                    wedge,
                    with: .linearGradient(
                        Gradient(colors: [BG.rgb(1, 0.88 - 0.08 * warm, 0.6, alpha), BG.rgb(1, 0.85, 0.6, 0)]),
                        startPoint: sun,
                        endPoint: CGPoint(x: sun.x + cos(beam.angle) * length * 0.75, y: sun.y + sin(beam.angle) * length * 0.75)
                    )
                )
            }
        }
    }

    static func cloud(_ k: Int, size: CGSize, look: SeptemberModel.Look) -> (center: CGPoint, width: CGFloat, opacity: Double, depth: CGFloat) {
        let depth = CGFloat(k) / 4
        let width = BG.lerp(220, 420, depth) * BG.hash(k + 40, 131, 0.9, 1.1)
        let x = BG.wrap(BG.hash(k + 40, 132) * size.width + look.drift * BG.lerp(0.25, 0.7, depth), length: size.width, margin: width * 0.7)
        let y = size.height * BG.hash(k + 40, 133, 0.05, 0.36)
        return (CGPoint(x: x, y: y), width, Double(BG.lerp(0.55, 0.85, depth)), depth)
    }

    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame) {
        for k in 0..<5 {
            let c = cloud(k, size: size, look: look)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 140, width: c.width),
                center: c.center,
                width: c.width,
                palette: .septemberGold,
                opacity: c.opacity,
                lightDirection: CGVector(dx: frame.sun.x - c.center.x, dy: frame.sun.y - c.center.y),
                softness: BG.lerp(0.05, 0.03, c.depth)
            )
            // Golden rim where the cloud's edge faces the sun.
            let dx = frame.sun.x - c.center.x
            let dy = frame.sun.y - c.center.y
            let distance = max(1, sqrt(dx * dx + dy * dy))
            let near = Double((1 - BG.smoothstep(c.width * 0.3, c.width * 1.1, distance)) * frame.sunFade) * c.opacity
            if near > 0.01 {
                let edge = CGPoint(x: c.center.x + dx / distance * c.width * 0.36, y: c.center.y + dy / distance * c.width * 0.15)
                ctx.glow(at: edge, radius: c.width * 0.32, color: BG.rgb(1, 0.85, 0.55), intensity: 0.55 * near, additive: true)
            }
        }
    }

    /// A loose, wavy skein of geese crossing high every few minutes.
    static func drawGeese(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let period: CGFloat = 150
        let position = t / period + 0.35
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.3
        guard local < span else { return }
        let u = local / span
        let dir: CGFloat = BG.hash(cycle, 630) < 0.65 ? -1 : 1
        let count = 8 + Int(BG.hash(cycle, 631) * 8)
        let travel = u * (size.width + 360)
        let lead = CGPoint(
            x: dir > 0 ? -160 + travel : size.width + 160 - travel,
            y: size.height * BG.hash(cycle, 632, 0.08, 0.16) + sin(u * 4) * 10
        )
        let vee = BG.hash(cycle, 633) < 0.6
        var flock = Path()
        for j in 0..<count {
            let row = CGFloat((j + 1) / 2)
            let side: CGFloat = j == 0 ? 0 : (j % 2 == 1 ? -1 : 1)
            let p: CGPoint
            if vee {
                p = CGPoint(x: lead.x - dir * row * 26, y: lead.y + side * row * 12 + sin(t * 0.8 + CGFloat(j)) * 2)
            } else {
                // A wavy line instead of a V.
                let k = CGFloat(j)
                p = CGPoint(x: lead.x - dir * k * 22, y: lead.y + sin(k * 0.8 + t * 0.6) * 9)
            }
            let flap = sin(t * 3.4 + CGFloat(j) * 0.7) * 4
            flock.move(to: CGPoint(x: p.x - 9, y: p.y + flap))
            flock.addQuadCurve(to: p, control: CGPoint(x: p.x - 4, y: p.y - 4 + flap * 0.3))
            flock.addQuadCurve(to: CGPoint(x: p.x + 9, y: p.y + flap), control: CGPoint(x: p.x + 4, y: p.y - 4 + flap * 0.3))
        }
        ctx.stroke(flock, with: .color(BG.rgb(0.3, 0.2, 0.18, 0.5)), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
    }

    // MARK: Land

    static func hillY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.9 + 0.022 * sin(u * 3.2 + 1.1) + 0.01 * sin(u * 8.7 + 0.4))
    }

    /// Hazy amber hills with a few round trees just starting to turn.
    static func drawHills(in ctx: inout GraphicsContext, size: CGSize, frame: SeptemberFrame, look: SeptemberModel.Look) {
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            hills.addLine(to: CGPoint(x: x, y: hillY(x, size: size)))
            x += 20
        }
        hills.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        hills.closeSubpath()
        ctx.fill(
            hills,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.75, 0.55, 0.42, 0.3), BG.rgb(0.55, 0.42, 0.25, 0.42)]),
                startPoint: CGPoint(x: 0, y: size.height * 0.86),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        for i in 0..<11 {
            let u = BG.hash(i, 640)
            let x = (u < 0.5 ? u * 0.56 : 0.72 + (u - 0.5) * 0.56) * size.width
            let r = BG.hash(i, 641, 10, 20)
            let base = hillY(x, size: size) + 2
            let c = CGPoint(x: x, y: base - r * 0.9)
            let tone = SeptemberLeaves.palette(seed: i + 900, progress: look.progress * 0.7)
            ctx.fill(Path(CGRect(x: x - 1.5, y: base - r * 0.4, width: 3, height: r * 0.45)), with: .color(BG.rgb(0.3, 0.2, 0.14, 0.45)))
            var crown = ctx
            crown.opacity = 0.5
            crown.fill(
                BG.ellipse(c, r, r * 0.85),
                with: .radialGradient(
                    Gradient(colors: [tone.light, tone.dark]),
                    center: CGPoint(x: c.x + (frame.sun.x > c.x ? r * 0.35 : -r * 0.35), y: c.y - r * 0.3),
                    startRadius: 0, endRadius: r * 1.3
                )
            )
        }
    }

    /// Tall grass and seed heads along the bottom, swaying in the breeze and rim-lit
    /// gold where the light falls on them.
    static func drawGrass(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame, dark: Bool) {
        var blades = Path()
        var heads = Path()
        var litHeads = Path()
        let count = Int(size.width / 9)
        for i in 0..<count {
            let x = (CGFloat(i) + BG.hash(i, 650)) / CGFloat(count) * (size.width + 20) - 10
            let h = size.height * BG.hash(i, 651, 0.035, 0.075)
            let gust = SeptemberAir.gust(at: x, t) * min(look.wind / 30, 2)
            let bend = (0.25 + 0.6 * gust + 0.12 * sin(t * 1.3 + CGFloat(i) * 0.7)) * h * 0.35
            let tip = CGPoint(x: x + bend, y: size.height - h)
            let w = BG.hash(i, 652, 2, 4)
            blades.move(to: CGPoint(x: x - w / 2, y: size.height))
            blades.addQuadCurve(to: tip, control: CGPoint(x: x - w * 0.2 + bend * 0.3, y: size.height - h * 0.55))
            blades.addQuadCurve(to: CGPoint(x: x + w / 2, y: size.height), control: CGPoint(x: x + w * 0.3 + bend * 0.35, y: size.height - h * 0.5))
            blades.closeSubpath()
            if i % 3 == 0 {
                // An oat-like seed head nodding at the tip.
                let head = BG.ellipse(.zero, 2.4, 6).applying(
                    CGAffineTransform(translationX: tip.x, y: tip.y - 4).rotated(by: 0.3 + bend / h)
                )
                heads.addPath(head)
                if frame.light(at: tip) > 0.25 {
                    litHeads.addPath(head)
                }
            }
        }
        ctx.fill(
            blades,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.85, 0.72, 0.38, 0.75), BG.rgb(0.45, 0.38, 0.16, 0.85)]),
                startPoint: CGPoint(x: 0, y: size.height * 0.92),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        ctx.fill(heads, with: .color(BG.rgb(0.8, 0.62, 0.32, 0.85)))
        var rim = ctx
        if dark { rim.blendMode = .plusLighter }
        rim.stroke(litHeads, with: .color(BG.rgb(1, 0.85, 0.5, 0.75)), lineWidth: 1.2)
    }

    // MARK: Leaves

    /// A falling leaf. `layer`: 0 far, 1 mid, 2 near.
    static func drawFalling(layer: Int, index: Int, in target: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame) {
        let seed = index + layer * 1000 + 5000
        let visible = BG.clamp01((look.leafAmount - BG.hash(seed, 161)) / 0.06)
        guard visible > 0.01 else { return }

        let depth: CGFloat = layer == 0 ? BG.hash(seed, 150, 0.2, 0.45) : (layer == 1 ? BG.hash(seed, 150, 0.5, 0.9) : 1)
        let speed = BG.hash(seed, 151, 45, 85) * BG.lerp(0.6, 1.3, depth)
        let span = size.height + 140
        let progress = BG.fract(BG.hash(seed, 152) + t * speed / span)
        let y = progress * span - 70
        let flutter = sin(t * BG.hash(seed, 153, 0.8, 1.6) + BG.hash(seed, 154) * 6.28)
        let x = BG.wrap(
            BG.hash(seed, 155) * size.width + look.drift * BG.lerp(0.5, 1.1, depth) + flutter * 40,
            length: size.width,
            margin: 70
        )
        let rotation = Double(flutter * 0.9 + t * BG.hash(seed, 156, -0.8, 0.8))
        let flip = cos(t * BG.hash(seed, 157, 0.9, 2.2) + BG.hash(seed, 158) * 6.28)
        let leafSize: CGFloat
        switch layer {
        case 0: leafSize = BG.hash(seed, 165, 10, 17)
        case 1: leafSize = BG.hash(seed, 165, 16, 30)
        default: leafSize = BG.hash(seed, 165, 40, 56)
        }

        var opacity = BG.smoothstep(0, 0.08, progress) * (1 - BG.smoothstep(0.88, 1, progress)) * visible
        opacity *= layer == 0 ? 0.6 : 0.95
        if layer == 2 {
            let cx = 1 - BG.clamp01(abs(x / size.width - 0.5) / 0.25)
            let cy = 1 - BG.clamp01(abs(y / size.height - 0.5) / 0.25)
            opacity *= BG.lerp(1, 0.5, BG.smoothstep(0, 0.5, min(cx, cy)))
        }
        let p = CGPoint(x: x, y: y)
        drawLeaf(
            in: &target,
            at: p,
            size: leafSize,
            rotation: rotation,
            flip: flip,
            palette: SeptemberLeaves.palette(seed: seed, progress: look.progress),
            maple: BG.hash(seed, 160) < 0.55,
            opacity: Double(opacity),
            light: layer == 0 ? 0 : frame.light(at: p)
        )
    }

    /// A leaf with backlit translucency: facing the viewer inside a sunbeam, its body
    /// glows warm and bright.
    static func drawLeaf(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, palette: LeafPalette, maple: Bool, opacity: Double, light: CGFloat) {
        LeafPainter.draw(in: &ctx, at: p, size: size, rotation: rotation, flip: flip, palette: palette, maple: maple, opacity: opacity)
        let glow = Double(light * light * (0.35 + 0.65 * abs(flip)))
        guard glow > 0.03, opacity > 0.01 else { return }
        var lit = ctx
        lit.opacity = opacity
        lit.blendMode = .plusLighter
        lit.translateBy(x: p.x, y: p.y)
        lit.rotate(by: .radians(rotation))
        lit.scaleBy(x: size * max(abs(flip), 0.06), y: size)
        lit.fill(
            maple ? LeafPainter.maple : LeafPainter.oval,
            with: .radialGradient(
                Gradient(colors: [BG.rgb(1, 0.85, 0.45, 0.6 * glow), BG.rgb(1, 0.6, 0.2, 0.2 * glow)]),
                center: CGPoint(x: 0, y: -0.05), startRadius: 0, endRadius: 0.55
            )
        )
    }

    /// Equinox: a gust sweeps a flurry of extra leaves in from the left; they swirl,
    /// then settle into the ordinary fall and drop out of view.
    static func drawRelease(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame) {
        let age = look.releaseAge
        guard age >= 0 else { return }
        let end = CGFloat(SeptemberModel.releaseDuration)
        for k in 0..<40 {
            let seed = k + 7000
            let a = age - BG.hash(seed, 660, 0, 2.5)
            guard a > 0 else { continue }
            let push = BG.hash(seed, 661, 320, 560)
            let x = -40 + push * (1 - exp(-a / 1.6)) * 1.6 + 26 * a
            let swirl = a * BG.hash(seed, 662, 1.5, 3) + BG.hash(seed, 663) * 6.28
            let p = CGPoint(
                x: x + cos(swirl) * 30,
                y: size.height * BG.hash(seed, 664, 0.08, 0.55) + 14 * a + 3.2 * a * a + sin(swirl) * 24
            )
            guard p.y < size.height + 40 else { continue }
            let fade = BG.smoothstep(0, 0.3, a) * (1 - BG.smoothstep(end - 2, end, age)) * (1 - BG.smoothstep(size.height * 0.9, size.height + 20, p.y))
            drawLeaf(
                in: &ctx,
                at: p,
                size: BG.hash(seed, 665, 16, 28),
                rotation: Double(swirl * 1.3),
                flip: cos(swirl * 1.7 + CGFloat(k)),
                palette: SeptemberLeaves.palette(seed: seed, progress: max(look.progress, 0.6)),
                maple: k % 2 == 0,
                opacity: Double(fade) * 0.95,
                light: frame.light(at: p)
            )
        }
    }

    /// Golden motes drifting in the air, visible only where a beam lights them.
    static func drawMotes(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame) {
        for i in 0..<40 {
            let x = BG.wrap(BG.hash(i, 670) * size.width + look.drift * 0.3 + sin(t * 0.3 + CGFloat(i)) * 30, length: size.width, margin: 20)
            let y = size.height * BG.hash(i, 671, 0.15, 0.9) + sin(t * 0.23 + CGFloat(i) * 2) * 24
            let p = CGPoint(x: x, y: y)
            let lit = frame.light(at: p)
            let twinkle = 0.6 + 0.4 * sin(t * BG.hash(i, 672, 1, 2.5) + CGFloat(i))
            let alpha = Double(pow(lit, 1.5) * twinkle)
            guard alpha > 0.04 else { continue }
            ctx.fill(BG.circle(p, BG.hash(i, 673, 0.8, 1.8)), with: .color(BG.rgb(1, 0.93, 0.7, 0.85 * alpha)))
            ctx.glow(at: p, radius: 6, color: BG.rgb(1, 0.85, 0.5), intensity: 0.35 * alpha, additive: true)
        }
    }

    // MARK: Framing

    /// A leafy limb in the top-left corner. Now and then one of its leaves tugs at its
    /// stem, lets go and joins the fall; a fresh one fades in later.
    static func drawBranch(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame) {
        let art = SeptemberArt.branch
        let origin = CGPoint(x: -6, y: -6)
        let scale = min(size.width * 0.26, 420)
        let gust = SeptemberAir.gust(at: 0, t) * min(look.wind / 30, 2)
        let rot = sin(t * 0.55) * 0.012 + gust * 0.025 * sin(t * 2.1)

        var limb = ctx
        limb.translateBy(x: origin.x, y: origin.y)
        limb.rotate(by: .radians(Double(rot)))
        limb.scaleBy(x: scale, y: scale)
        let ink = BG.rgb(0.2, 0.13, 0.09, 0.8)
        limb.stroke(art.thick, with: .color(ink), style: StrokeStyle(lineWidth: 0.022, lineCap: .round))
        limb.stroke(art.thin, with: .color(ink), style: StrokeStyle(lineWidth: 0.008, lineCap: .round))

        let cosR = cos(rot)
        let sinR = sin(rot)
        for (i, tip) in art.tips.enumerated() {
            let lx = tip.x * scale
            let ly = tip.y * scale
            let anchor = CGPoint(x: origin.x + lx * cosR - ly * sinR, y: origin.y + lx * sinR + ly * cosR)
            let seed = i + 8000
            let leafSize = BG.hash(seed, 680, 15, 22)
            let palette = SeptemberLeaves.palette(seed: seed, progress: look.progress * 0.8)
            let maple = i % 3 != 0
            let sway = sin(t * BG.hash(seed, 681, 1.2, 2.4) + CGFloat(i)) * (0.12 + gust * 0.5)

            // Every fourth leaf cycles: hangs, tugs, lets go, and later grows back.
            guard i % 4 == 1 else {
                drawLeaf(in: &ctx, at: anchor, size: leafSize, rotation: Double(CGFloat.pi * 0.9 + sway), flip: 0.75 + 0.25 * sin(t + CGFloat(i)), palette: palette, maple: maple, opacity: 0.95, light: frame.light(at: anchor))
                continue
            }
            let hang = BG.hash(seed, 682, 18, 40)
            let fall: CGFloat = 20
            let period = hang + fall
            let position = t / period + BG.hash(seed, 683)
            let local = BG.fract(position) * period
            if local < hang {
                let tug = BG.smoothstep(hang - 1.6, hang, local)
                let jerk = sin(local * 14) * 0.35 * tug
                let grow = BG.smoothstep(0, 3, local)
                drawLeaf(in: &ctx, at: anchor, size: leafSize, rotation: Double(CGFloat.pi * 0.9 + sway + jerk), flip: 0.8, palette: palette, maple: maple, opacity: Double(grow) * 0.95, light: frame.light(at: anchor))
            } else {
                let a = local - hang
                let flutter = sin(a * 1.4 + CGFloat(i))
                let p = CGPoint(x: anchor.x + a * 24 + flutter * 26, y: anchor.y + 28 * a + 2.2 * a * a)
                let fade = 1 - BG.smoothstep(size.height * 0.88, size.height + 10, p.y)
                drawLeaf(in: &ctx, at: p, size: leafSize, rotation: Double(CGFloat.pi * 0.9 + a * 1.6 + flutter * 0.8), flip: cos(a * 1.9), palette: palette, maple: maple, opacity: Double(fade) * 0.95, light: frame.light(at: p))
            }
        }
    }

    /// A dewy orb web in the top-right corner. Its beads glint in turn as the light
    /// moves over them, and it sways a little in the gusts.
    static func drawWeb(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: SeptemberModel.Look, frame: SeptemberFrame, dark: Bool) {
        let r = min(size.width, size.height) * 0.12
        let gust = SeptemberAir.gust(at: size.width, t) * min(look.wind / 30, 2)
        let center = CGPoint(x: size.width - r * 1.05 + gust * 4, y: r * 1.05 + sin(t * 0.7) * 1.5 + gust * 2)
        let lit = frame.light(at: center)
        let thread = dark ? BG.rgb(0.95, 0.92, 0.85) : BG.rgb(0.45, 0.4, 0.35)

        // Anchor lines to the screen edges.
        var anchors = Path()
        anchors.move(to: CGPoint(x: center.x - r * 0.4, y: center.y - r * 0.92))
        anchors.addLine(to: CGPoint(x: center.x - r * 0.7, y: -2))
        anchors.move(to: CGPoint(x: center.x + r * 0.92, y: center.y - r * 0.3))
        anchors.addLine(to: CGPoint(x: size.width + 2, y: center.y - r * 0.6))
        anchors.move(to: CGPoint(x: center.x + r * 0.6, y: center.y + r * 0.75))
        anchors.addLine(to: CGPoint(x: size.width + 2, y: center.y + r * 1.4))
        ctx.stroke(anchors, with: .color(thread.opacity(0.35)), lineWidth: 0.7)

        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: sin(t * 0.4) * 0.02 + gust * 0.04)
            .scaledBy(x: r, y: r * 0.96)
        ctx.stroke(SeptemberArt.web.applying(transform), with: .color(thread.opacity(Double(0.22 + 0.3 * lit))), lineWidth: 0.6)

        var beads = Path()
        for (i, bead) in SeptemberArt.beads.enumerated() {
            let p = bead.applying(transform)
            beads.addPath(BG.circle(p, BG.hash(i, 690, 0.9, 1.8)))
            let glint = pow(max(0, sin(t * BG.hash(i, 691, 0.6, 1.4) + BG.hash(i, 692) * 6.28)), 10) * (0.3 + 0.7 * lit)
            if glint > 0.15 {
                ctx.sparkle(at: p, size: 5, color: BG.rgb(1, 0.95, 0.8), intensity: Double(glint))
            }
        }
        ctx.fill(beads, with: .color((dark ? BG.rgb(1, 0.97, 0.9) : BG.rgb(0.75, 0.82, 0.92)).opacity(0.55 + 0.35 * Double(lit))))
    }
}
