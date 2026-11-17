//
//  NovemberScene.swift
//  Simple Calendar
//
//  November: a blustery late-autumn day under heavy overcast.
//
//  Gusts are the star. A single wind signal drives everything in the scene, and it
//  *travels*: a point on the screen feels each gust `x / 600` seconds after the left
//  edge does, so waves of wind visibly sweep left to right. Leaves surge and swirl in
//  eddies, bare trees sway, streaks of wind show up in the air, the leaf pile rustles,
//  and the odd leaf is kicked back up off the ground.
//
//  The scene also follows the selected day:
//    * month progress  - leaves thin out and brown over the month, the sky greys,
//                        the pile deepens
//    * day character   - breezy / blustery / gale wind strength (hash of the date)
//    * Thanksgiving    - the wind drops, the light warms, golden leaves spiral in
//  All three change through one discrete 2.5 s transition and never stack.
//

import SwiftUI

// MARK: - View

struct NovemberLeavesAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = NovemberModel()

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = NovemberModel.Target(date: date)
        let state = model
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            NovemberScene.draw(in: &ctx, size: size, time: time, look: look)
        }
        .opacity(alpha)
    }
}

// MARK: - State: selection-driven look and the accumulated wind

/// Holds the discrete transitions and the integrated wind drift for the scene.
final class NovemberModel {
    /// What the selected day asks for.
    struct Target {
        let progress: Double   // 0 on Nov 1 ... 1 on Nov 30
        let windScale: Double  // breezy 0.6 / blustery 1 / gale 1.5
        let calm: Double       // 1 on Thanksgiving

        init(date: Date) {
            let calendar = Calendar(identifier: .gregorian)
            let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
            let day = parts.day ?? 1
            progress = min(max(Double(day - 1) / 29, 0), 1)

            let ordinal = calendar.ordinality(of: .day, in: .year, for: date) ?? day
            let roll = BG.hash((parts.year ?? 2026) * 400 + ordinal, 211)
            windScale = roll < 0.3 ? 0.6 : (roll < 0.8 ? 1 : 1.5)

            // US Thanksgiving: the fourth Thursday, always the 22nd...28th.
            let isThanksgiving = parts.month == 11 && parts.weekday == 5 && (22...28).contains(day)
            calm = isThanksgiving ? 1 : 0
        }
    }

    /// What the renderer needs for one frame.
    struct Look {
        var progress: CGFloat
        var windScale: CGFloat
        var calm: CGFloat
        /// Wind displacement accumulated since the scene appeared (keeps drift continuous
        /// when the wind strength changes).
        var drift: CGFloat

        /// Overall wind strength after Thanksgiving calm.
        var force: CGFloat { windScale * (1 - 0.8 * calm) }
        /// Fraction of airborne leaves still on the trees.
        var airborne: CGFloat { BG.lerp(1, 0.45, progress) }
        var pileScale: CGFloat { BG.lerp(1, 1.4, progress) }
        var overcast: CGFloat { progress * 0.3 }
    }

    private let progressTransition = NovemberTransition()
    private let windTransition = NovemberTransition()
    private let calmTransition = NovemberTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let progress = progressTransition.value(target: target.progress, time: time)
        let wind = windTransition.value(target: target.windScale, time: time)
        let calm = calmTransition.value(target: target.calm, time: time)
        let force = CGFloat(wind * (1 - 0.8 * calm))

        // Integrate the wind so drift stays continuous however the strength changes.
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * NovemberWind.speed(CGFloat(time)) * force
        }
        lastTime = time

        return Look(progress: CGFloat(progress), windScale: CGFloat(wind), calm: CGFloat(calm), drift: drift)
    }
}

/// A value that glides to a new target over `duration` and only then looks at the
/// current target again, so transitions never stack, queue or retarget mid-flight.
final class NovemberTransition {
    private let duration: Double
    private var shown: Double?
    private var from = 0.0
    private var delta = 0.0
    private var startTime: Double?

    init(duration: Double = 2.5) {
        self.duration = duration
    }

    func value(target: Double, time: Double) -> Double {
        guard shown != nil else {
            shown = target
            return target
        }
        if let start = startTime {
            let progress = (time - start) / duration
            if progress < 1 {
                return from + delta * Double(BG.easeInOut(CGFloat(progress)))
            }
            startTime = nil
            shown = from + delta
        }
        let current = shown ?? target
        if abs(target - current) > 0.0005 {
            from = current
            delta = target - current
            startTime = time
        }
        return current
    }
}

// MARK: - Wind

/// One wind signal for the whole scene. Built from incommensurate sines (periods of
/// roughly 8 to 33 s) so gusts never settle into an obvious loop.
private enum NovemberWind {
    static let base: CGFloat = 55
    static let gust: CGFloat = 48
    private static let parts: [(amp: CGFloat, rate: CGFloat, phase: CGFloat)] = [
        (0.36, 0.52, 0.0), (0.28, 0.317, 1.9), (0.20, 0.83, 4.1), (0.16, 0.191, 2.6)
    ]

    /// -1...1
    static func signal(_ t: CGFloat) -> CGFloat {
        var s: CGFloat = 0
        for part in parts { s += part.amp * sin(part.rate * t + part.phase) }
        return s
    }

    /// Horizontal wind speed in points per second (never reverses).
    static func speed(_ t: CGFloat) -> CGFloat { base + gust * signal(t) }

    /// 0...1 gust strength: calm most of the time, with sharp swells.
    static func strength(_ t: CGFloat) -> CGFloat { BG.smoothstep(-0.15, 0.75, signal(t)) }

    /// Gusts sweep left to right: a point at `x` feels each gust `x / 600` seconds late.
    static func strength(at x: CGFloat, _ t: CGFloat) -> CGFloat { strength(t - x / 600) }
}

// MARK: - Leaf colors

private struct NovemberHue {
    let r: Double, g: Double, b: Double

    func mix(_ other: NovemberHue, _ amount: Double) -> NovemberHue {
        NovemberHue(r: r + (other.r - r) * amount, g: g + (other.g - g) * amount, b: b + (other.b - b) * amount)
    }

    var color: Color { BG.rgb(r, g, b) }
}

private struct NovemberLeafTones {
    let light: NovemberHue, dark: NovemberHue, vein: NovemberHue

    init(_ light: (Double, Double, Double), _ dark: (Double, Double, Double), _ vein: (Double, Double, Double)) {
        self.light = NovemberHue(r: light.0, g: light.1, b: light.2)
        self.dark = NovemberHue(r: dark.0, g: dark.1, b: dark.2)
        self.vein = NovemberHue(r: vein.0, g: vein.1, b: vein.2)
    }
}

private enum NovemberLeaves {
    /// Early-month fall color (matches `LeafPalette.autumn`).
    static let early: [NovemberLeafTones] = [
        NovemberLeafTones((1, 0.72, 0.2), (0.85, 0.3, 0.05), (1, 0.85, 0.5)),
        NovemberLeafTones((0.95, 0.3, 0.15), (0.55, 0.06, 0.08), (1, 0.6, 0.45)),
        NovemberLeafTones((1, 0.88, 0.3), (0.8, 0.55, 0.05), (1, 0.95, 0.65)),
        NovemberLeafTones((0.75, 0.45, 0.2), (0.4, 0.2, 0.08), (0.9, 0.65, 0.4)),
        NovemberLeafTones((0.95, 0.55, 0.2), (0.7, 0.2, 0.1), (1, 0.8, 0.5))
    ]

    /// Late-month: browns, tans and faded reds.
    static let late: [NovemberLeafTones] = [
        NovemberLeafTones((0.55, 0.36, 0.2), (0.3, 0.18, 0.08), (0.75, 0.55, 0.35)),
        NovemberLeafTones((0.75, 0.63, 0.45), (0.45, 0.35, 0.2), (0.88, 0.78, 0.6)),
        NovemberLeafTones((0.65, 0.3, 0.25), (0.35, 0.13, 0.13), (0.82, 0.55, 0.5))
    ]

    static let gold = NovemberLeafTones((1, 0.84, 0.32), (0.86, 0.5, 0.06), (1, 0.95, 0.65))

    /// Palette `index`, blended toward the late-month browns by `progress` and toward
    /// dark soil by `darken` (leaves deep in the pile).
    static func palette(_ index: Int, progress: CGFloat, darken: Double = 0) -> LeafPalette {
        let a = early[index % early.count]
        let b = late[index % late.count]
        let p = Double(progress)
        let soil = NovemberHue(r: 0.12, g: 0.07, b: 0.04)
        func tone(_ x: NovemberHue, _ y: NovemberHue) -> Color { x.mix(y, p).mix(soil, darken).color }
        return LeafPalette(light: tone(a.light, b.light), dark: tone(a.dark, b.dark), vein: tone(a.vein, b.vein))
    }

    static func goldPalette() -> LeafPalette {
        LeafPalette(light: gold.light.color, dark: gold.dark.color, vein: gold.vein.color)
    }
}

extension CloudPalette {
    /// Heavy late-autumn overcast: warm-lit tops, cold slate undersides.
    static let novemberOvercast = CloudPalette(
        light: BG.rgb(0.93, 0.86, 0.78),
        body: BG.rgb(0.7, 0.64, 0.62),
        shade: BG.rgb(0.42, 0.39, 0.42)
    )
}

// MARK: - Bare branches

/// Branches grouped by thickness so each group is one stroke.
private struct NovemberBranchArt {
    var thick = Path()
    var mid = Path()
    var thin = Path()
    var tips: [CGPoint] = []
}

private enum NovemberBranches {
    /// Recursively grows a branch in unit space (trunk length ~0.3, y negative is up).
    static func grow(_ art: inout NovemberBranchArt, from p: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, maxDepth: Int, seed: Int) {
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
        guard depth < maxDepth else {
            art.tips.append(end)
            return
        }
        let children = depth < 2 ? 2 : (BG.hash(seed, 302) < 0.35 ? 3 : 2)
        for c in 0..<children {
            let childSeed = seed * 5 + c + 1
            let spread = BG.hash(childSeed, 303, 0.28, 0.62)
            let side: CGFloat = c == 0 ? -1 : (c == 1 ? 1 : 0)
            let childAngle = angle + side * spread + BG.hash(childSeed, 304, -0.1, 0.1)
            let childLength = length * BG.hash(childSeed, 305, 0.66, 0.82)
            grow(&art, from: end, angle: childAngle, length: childLength, depth: depth + 1, maxDepth: maxDepth, seed: childSeed)
        }
    }

    /// Three standing tree silhouettes (about 1 unit tall).
    static let trees: [NovemberBranchArt] = (0..<3).map { variant in
        var art = NovemberBranchArt()
        grow(&art, from: .zero, angle: BG.hash(variant, 310, -0.08, 0.08), length: 0.3, depth: 0, maxDepth: 6, seed: 40 + variant)
        return art
    }

    /// Two limbs reaching in from the top corners (about 1 unit long).
    static let corners: [NovemberBranchArt] = [77, 78].map { seed in
        var art = NovemberBranchArt()
        grow(&art, from: .zero, angle: 2.0, length: 0.34, depth: 0, maxDepth: 7, seed: seed)
        return art
    }
}

// MARK: - Scene

private enum NovemberScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: NovemberModel.Look) {
        let t = CGFloat(time)
        let sun = CGPoint(x: size.width * 0.8, y: size.height * 0.07)

        drawSky(in: &ctx, size: size, t: t, look: look, sun: sun)
        drawGeese(in: &ctx, size: size, t: t)

        drawRidge(in: &ctx, size: size, layer: 0)
        drawTrees(in: &ctx, size: size, t: t, look: look, layer: 0)
        drawMist(in: &ctx, size: size, look: look, layer: 0)
        drawRidge(in: &ctx, size: size, layer: 1)
        drawTrees(in: &ctx, size: size, t: t, look: look, layer: 1)
        drawMist(in: &ctx, size: size, look: look, layer: 1)

        drawGround(in: &ctx, size: size, look: look)
        drawPile(in: &ctx, size: size, t: t, look: look, row: 0)

        // Far leaves, softly out of focus.
        ctx.blurredLayer(radius: 1.6) { far in
            for i in 0..<30 {
                drawAirborne(layer: 0, index: i, in: &far, size: size, t: t, look: look)
            }
        }
        drawWhirlwind(in: &ctx, size: size, t: t, look: look)
        for i in 0..<34 {
            drawAirborne(layer: 1, index: i, in: &ctx, size: size, t: t, look: look)
        }
        drawHarvestSwirl(in: &ctx, size: size, t: t, look: look)

        drawPile(in: &ctx, size: size, t: t, look: look, row: 1)
        drawSkitter(in: &ctx, size: size, t: t, look: look)
        drawPile(in: &ctx, size: size, t: t, look: look, row: 2)
        drawKicked(in: &ctx, size: size, t: t, look: look)

        // Near leaves, large and blurred as one layer.
        ctx.blurredLayer(radius: 6) { near in
            for i in 0..<6 {
                drawAirborne(layer: 2, index: i, in: &near, size: size, t: t, look: look)
            }
        }

        drawStreaks(in: &ctx, size: size, t: t, look: look)
        drawBranches(in: &ctx, size: size, t: t, look: look)
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look, sun: CGPoint) {
        let grey = Double(look.overcast)
        let calm = Double(look.calm)
        let sky = Gradient(stops: [
            .init(color: BG.rgb(0.5 - 0.06 * grey, 0.45 - 0.03 * grey, 0.43, 0.34 + 0.1 * grey), location: 0),
            .init(color: BG.rgb(0.74, 0.62, 0.52, 0.2), location: 0.45),
            .init(color: BG.rgb(0.95, 0.7, 0.45, 0), location: 0.82)
        ])
        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.7, 0.62, 0.55), intensity: 0.16 + grey * 0.4, depth: 0.45)
        AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.85, 0.55, 0.3), intensity: 0.14 * (1 + calm), depth: 0.25)

        // A pale sun smouldering behind the cloud deck.
        ctx.glow(at: sun, radius: size.width * 0.5, color: BG.rgb(1, 0.86, 0.62), intensity: 0.32 + 0.25 * calm - grey * 0.4)

        for k in 0..<5 {
            let depth = CGFloat(k) / 4
            let width = BG.lerp(420, 700, depth) * BG.hash(k, 331, 0.9, 1.1)
            let x = BG.wrap(BG.hash(k, 332) * size.width + look.drift * BG.lerp(0.05, 0.14, depth), length: size.width, margin: width * 0.7)
            let y = size.height * BG.hash(k, 333, -0.02, 0.13)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 700, width: width),
                center: CGPoint(x: x, y: y),
                width: width,
                palette: .novemberOvercast,
                opacity: Double(BG.lerp(0.4, 0.62, depth)),
                lightDirection: CGVector(dx: sun.x - x, dy: sun.y - y),
                softness: 0.05
            )
        }

        // Broken light falling through the deck.
        ctx.blurredLayer(radius: 26) { shafts in
            for i in 0..<5 {
                let angle = 1.95 + CGFloat(i) * 0.13 + sin(t * 0.07 + CGFloat(i)) * 0.03
                let spread = BG.hash(i, 335, 0.03, 0.06)
                let breathe = 0.5 + 0.5 * sin(t * 0.2 + CGFloat(i) * 1.7)
                let length = size.height * 1.1
                var wedge = Path()
                wedge.move(to: sun)
                wedge.addLine(to: CGPoint(x: sun.x + cos(angle - spread) * length, y: sun.y + sin(angle - spread) * length))
                wedge.addLine(to: CGPoint(x: sun.x + cos(angle + spread) * length, y: sun.y + sin(angle + spread) * length))
                wedge.closeSubpath()
                shafts.fill(
                    wedge,
                    with: .linearGradient(
                        Gradient(colors: [BG.rgb(1, 0.9, 0.7, Double(0.08 + 0.1 * breathe) * (1 + calm)), BG.rgb(1, 0.9, 0.7, 0)]),
                        startPoint: sun,
                        endPoint: CGPoint(x: sun.x + cos(angle) * length, y: sun.y + sin(angle) * length)
                    )
                )
            }
        }
    }

    /// A V of geese crossing high and slow every couple of minutes.
    static func drawGeese(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let period: CGFloat = 110
        let position = t / period + 0.2
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.32
        guard local < span else { return }
        let u = local / span
        let dir: CGFloat = cycle % 2 == 0 ? 1 : -1
        let travel = u * (size.width + 240)
        let lead = CGPoint(
            x: dir > 0 ? -120 + travel : size.width + 120 - travel,
            y: size.height * (0.09 + 0.06 * BG.hash(cycle, 380)) + sin(u * 5) * 8
        )
        for j in 0..<9 {
            let row = CGFloat((j + 1) / 2)
            let side: CGFloat = j == 0 ? 0 : (j % 2 == 1 ? -1 : 1)
            let p = CGPoint(x: lead.x - dir * row * 30, y: lead.y + side * row * 15)
            let flap = sin(t * 3.4 + CGFloat(j) * 0.7) * 5
            var goose = Path()
            goose.move(to: CGPoint(x: p.x - 11, y: p.y + flap))
            goose.addQuadCurve(to: p, control: CGPoint(x: p.x - 5, y: p.y - 5 + flap * 0.3))
            goose.addQuadCurve(to: CGPoint(x: p.x + 11, y: p.y + flap), control: CGPoint(x: p.x + 5, y: p.y - 5 + flap * 0.3))
            ctx.stroke(goose, with: .color(BG.rgb(0.16, 0.12, 0.12, 0.6)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: Land

    static func ridgeY(_ x: CGFloat, size: CGSize, layer: Int) -> CGFloat {
        let u = x / max(size.width, 1)
        let l = CGFloat(layer)
        let base = size.height * (layer == 0 ? 0.73 : 0.82)
        return base + size.height * (0.018 * sin(u * 4.1 + l * 2.3) + 0.01 * sin(u * 11 + l * 5.1))
    }

    static func drawRidge(in ctx: inout GraphicsContext, size: CGSize, layer: Int) {
        var fill = Path()
        fill.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            fill.addLine(to: CGPoint(x: x, y: ridgeY(x, size: size, layer: layer)))
            x += 20
        }
        fill.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        fill.closeSubpath()
        let top = size.height * (layer == 0 ? 0.7 : 0.79)
        let colors: [Color] = layer == 0
            ? [BG.rgb(0.5, 0.38, 0.33, 0.3), BG.rgb(0.75, 0.6, 0.5, 0.1)]
            : [BG.rgb(0.38, 0.27, 0.22, 0.42), BG.rgb(0.55, 0.4, 0.3, 0.2)]
        ctx.fill(fill, with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: size.height)))
    }

    static func drawTrees(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look, layer: Int) {
        let count = layer == 0 ? 15 : 8
        let ink = layer == 0 ? BG.rgb(0.32, 0.23, 0.21, 0.34) : BG.rgb(0.2, 0.14, 0.12, 0.5)
        let canopy = Double((1 - look.progress * 0.9) * (layer == 0 ? 0.5 : 0.42))
        for i in 0..<count {
            let seed = i + layer * 100 + 500
            let x = (CGFloat(i) + BG.hash(seed, 341, 0.1, 0.9)) / CGFloat(count) * size.width
            let base = ridgeY(x, size: size, layer: layer) + 6
            let scale = size.height * (layer == 0 ? BG.hash(seed, 342, 0.15, 0.23) : BG.hash(seed, 342, 0.24, 0.34))
            let art = NovemberBranches.trees[seed % NovemberBranches.trees.count]
            let gust = NovemberWind.strength(at: x, t) * min(look.force, 1.5)
            let sway = sin(t * 0.7 + CGFloat(i) * 1.3) * 0.01 + gust * 0.03 * sin(t * 2.1 + CGFloat(i))

            var tree = ctx
            tree.translateBy(x: x, y: base)
            tree.rotate(by: .radians(Double(sway)))
            tree.scaleBy(x: scale, y: scale)

            // The last of the leaf color, a soft canopy that thins through the month.
            if canopy > 0.02 {
                let tone = NovemberLeaves.early[Int(BG.hash(seed, 343) * 5) % 5]
                let c = CGPoint(x: 0, y: -0.7)
                tree.fill(
                    BG.ellipse(c, 0.46, 0.32),
                    with: .radialGradient(
                        Gradient(colors: [tone.light.color.opacity(canopy), tone.dark.color.opacity(canopy * 0.6), tone.dark.color.opacity(0)]),
                        center: c, startRadius: 0, endRadius: 0.46
                    )
                )
            }
            tree.stroke(art.thick, with: .color(ink), style: StrokeStyle(lineWidth: 0.03, lineCap: .round))
            tree.stroke(art.mid, with: .color(ink), style: StrokeStyle(lineWidth: 0.013, lineCap: .round))
            tree.stroke(art.thin, with: .color(ink), style: StrokeStyle(lineWidth: 0.005, lineCap: .round))
        }
    }

    static func drawMist(in ctx: inout GraphicsContext, size: CGSize, look: NovemberModel.Look, layer: Int) {
        let y = size.height * (layer == 0 ? 0.79 : 0.88)
        ctx.blurredLayer(radius: 22) { mist in
            for i in 0..<3 {
                let seed = i + layer * 10
                let x = BG.wrap(BG.hash(seed, 345) * size.width + look.drift * 0.05, length: size.width, margin: size.width * 0.3)
                let rx = size.width * BG.hash(seed, 346, 0.25, 0.4)
                let ry = size.height * BG.hash(seed, 347, 0.025, 0.045)
                let c = CGPoint(x: x, y: y + BG.hash(seed, 348, -8, 8))
                mist.fill(
                    BG.ellipse(c, rx, ry),
                    with: .radialGradient(
                        Gradient(colors: [BG.rgb(0.88, 0.78, 0.7, 0.3), BG.rgb(0.88, 0.78, 0.7, 0)]),
                        center: c, startRadius: 0, endRadius: rx
                    )
                )
            }
        }
    }

    static func drawGround(in ctx: inout GraphicsContext, size: CGSize, look: NovemberModel.Look) {
        let depth = 26 * look.pileScale
        var earth = Path()
        earth.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 16 {
            let u = x / max(size.width, 1)
            earth.addLine(to: CGPoint(x: x, y: size.height - depth * (0.7 + 0.3 * sin(u * 9) + 0.15 * sin(u * 23))))
            x += 16
        }
        earth.addLine(to: CGPoint(x: size.width + 16, y: size.height))
        earth.closeSubpath()
        ctx.fill(
            earth,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.3, 0.19, 0.1, 0.5), BG.rgb(0.14, 0.08, 0.04, 0.75)]),
                startPoint: CGPoint(x: 0, y: size.height - depth * 1.2),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    // MARK: Pile and ground leaves

    /// Cheap leaf for the dense pile: gradient body and veins only.
    static func drawFlatLeaf(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, palette: LeafPalette, maple: Bool, opacity: Double) {
        var leaf = ctx
        leaf.opacity = opacity
        leaf.translateBy(x: p.x, y: p.y)
        leaf.rotate(by: .radians(rotation))
        leaf.scaleBy(x: size * max(abs(flip), 0.3), y: size)
        leaf.fill(
            maple ? LeafPainter.maple : LeafPainter.oval,
            with: .linearGradient(
                Gradient(colors: [palette.light, palette.dark]),
                startPoint: CGPoint(x: -0.4, y: -0.5),
                endPoint: CGPoint(x: 0.4, y: 0.45)
            )
        )
        leaf.stroke(maple ? LeafPainter.mapleVeins : LeafPainter.ovalVeins, with: .color(palette.vein.opacity(0.45)), lineWidth: 0.03)
    }

    /// One of three overlapping rows of fallen leaves. They rustle and lift as gusts pass.
    static func drawPile(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look, row: Int) {
        let spacing: [CGFloat] = [46, 36, 42]
        let baseOffset: [CGFloat] = [12, 4, -4]
        let range: [CGFloat] = [14, 14, 10]
        let leafSize: [ClosedRange<CGFloat>] = [18...28, 22...34, 26...40]
        let darkness: [Double] = [0.5, 0.25, 0]
        let count = Int(size.width / spacing[row]) + 1

        struct PileLeaf {
            var p: CGPoint
            var size: CGFloat
            var rotation: Double
            var flip: CGFloat
            var index: Int
        }
        var leaves: [PileLeaf] = []
        leaves.reserveCapacity(count)
        var shadows = Path()
        for i in 0..<count {
            let seed = i + row * 700 + 12000
            let x = (CGFloat(i) + BG.hash(seed, 191)) / CGFloat(count) * size.width
            let gust = NovemberWind.strength(at: x, t) * min(look.force, 1.5)
            let lift = gust * BG.hash(seed, 196, 0.8, 3)
            let y = size.height - (baseOffset[row] + BG.hash(seed, 192) * range[row]) * look.pileScale - lift
            let s = BG.hash(seed, 193, leafSize[row].lowerBound, leafSize[row].upperBound)
            let rustle = Double(sin(t * 2.4 + CGFloat(i)) * 0.07 * gust)
            leaves.append(PileLeaf(
                p: CGPoint(x: x, y: y),
                size: s,
                rotation: Double(BG.hash(seed, 194) * 6.28) + rustle,
                flip: BG.hash(seed, 195, 0.55, 1),
                index: i + row * 3
            ))
            shadows.addPath(BG.ellipse(CGPoint(x: x + 3, y: y + s * 0.3), s * 0.4, s * 0.1))
        }
        ctx.fill(shadows, with: .color(BG.rgb(0.24, 0.15, 0.08, 0.35)))

        for leaf in leaves {
            let palette = NovemberLeaves.palette(leaf.index, progress: look.progress, darken: darkness[row])
            let maple = leaf.index % 3 != 0
            if row == 2 {
                LeafPainter.draw(in: &ctx, at: leaf.p, size: leaf.size, rotation: leaf.rotation, flip: leaf.flip, palette: palette, maple: maple, opacity: 0.92)
            } else {
                drawFlatLeaf(in: &ctx, at: leaf.p, size: leaf.size, rotation: leaf.rotation, flip: leaf.flip, palette: palette, maple: maple, opacity: 0.88)
            }
        }
    }

    /// Leaves cartwheeling along the ground instead of flying.
    static func drawSkitter(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        for i in 0..<6 {
            let seed = 400 + i
            let speedScale = BG.hash(seed, 390, 0.8, 1.5)
            let x = BG.wrap(BG.hash(seed, 391) * size.width + look.drift * speedScale * 1.1, length: size.width, margin: 60)
            let gust = NovemberWind.strength(at: x, t) * min(look.force, 1.5)
            let roll = look.drift * speedScale * 0.08 + BG.hash(seed, 392) * 6.28
            let hop = abs(sin(roll * 0.5)) * (4 + 36 * gust)
            let p = CGPoint(x: x, y: size.height - 16 * look.pileScale - hop)
            LeafPainter.draw(
                in: &ctx,
                at: p,
                size: BG.hash(seed, 393, 16, 26),
                rotation: Double(roll),
                flip: cos(roll * 0.6 + CGFloat(i)),
                palette: NovemberLeaves.palette(i + 2, progress: look.progress),
                maple: i % 2 == 0,
                opacity: 0.92
            )
        }
    }

    /// Now and then a gust kicks a leaf off the pile; it arcs up, tumbles and falls back.
    static func drawKicked(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        let period: CGFloat = 7
        for s in 0..<3 {
            let position = t / period + BG.hash(s, 350)
            let cycle = Int(floor(position))
            let age = BG.fract(position) * period
            let seed = cycle * 3 + s
            guard age < 3.8, BG.hash(seed, 351) < 0.6 else { continue }
            let x0 = BG.hash(seed, 352) * size.width
            guard NovemberWind.strength(at: x0, t - age) * look.force > 0.2 else { continue }
            let fade = BG.smoothstep(0, 0.15, age) * (1 - BG.smoothstep(3.2, 3.8, age))
            let p = CGPoint(
                x: x0 + age * (50 + 60 * look.force),
                y: size.height - 18 * look.pileScale - (55 * age - 14 * age * age)
            )
            LeafPainter.draw(
                in: &ctx,
                at: p,
                size: BG.hash(seed, 353, 20, 30),
                rotation: Double(age * 4 + BG.hash(seed, 354) * 6),
                flip: cos(age * 5 + BG.hash(seed, 355) * 6),
                palette: NovemberLeaves.palette(seed, progress: look.progress),
                maple: seed % 2 == 0,
                opacity: Double(fade) * 0.95
            )
        }
    }

    /// A small leaf devil: a handful of leaves spiralling up on a spinning column of air.
    static func drawWhirlwind(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        let period: CGFloat = 38
        let position = t / period + 0.55
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.12
        guard local < span, BG.hash(cycle, 230) < 0.7 else { return }
        let u = local / span
        let fade = Double(sin(u * .pi))
        let centerX = BG.hash(cycle, 231, 0.2, 0.8) * size.width + sin(u * 3) * 30
        let ground = size.height - 14 * look.pileScale
        for k in 0..<10 {
            let f = BG.fract(BG.hash(k, 232) + u * 1.2)
            let angle = u * 14 + CGFloat(k) * 0.63 + f * 6
            let radius = 18 + 60 * f
            let p = CGPoint(
                x: centerX + cos(angle) * radius,
                y: ground - f * size.height * 0.3 + sin(angle) * radius * 0.18
            )
            LeafPainter.draw(
                in: &ctx,
                at: p,
                size: BG.hash(k, 233, 16, 24),
                rotation: Double(angle * 1.4),
                flip: cos(angle * 1.3 + CGFloat(k)),
                palette: NovemberLeaves.palette(k, progress: look.progress),
                maple: k % 2 == 0,
                opacity: fade * 0.95
            )
        }
    }

    /// Thanksgiving: about twenty golden leaves spiral across the top and settle into the pile.
    static func drawHarvestSwirl(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        guard look.calm > 0.02 else { return }
        let palette = NovemberLeaves.goldPalette()
        let ground = size.height - 16 * look.pileScale
        for k in 0..<20 {
            let local = BG.fract((t - CGFloat(k) * 0.5) / 36)
            let edge = BG.smoothstep(0, 0.06, local) * (1 - BG.smoothstep(0.94, 1, local))
            let angle = local * 10 + CGFloat(k)
            let radius = 10 + 70 * sin(local * .pi)
            let eased = local * local
            let p = CGPoint(
                x: BG.lerp(size.width * 0.2, size.width * 0.8, local) + cos(angle) * radius,
                y: BG.lerp(size.height * 0.18, ground, eased) + sin(angle) * radius * 0.5
            )
            LeafPainter.draw(
                in: &ctx,
                at: p,
                size: BG.hash(k, 240, 18, 26),
                rotation: Double(angle),
                flip: cos(angle * 0.9),
                palette: palette,
                maple: k % 2 == 0,
                opacity: Double(edge * look.calm) * 0.95
            )
        }
    }

    // MARK: Airborne leaves

    /// A leaf in the wind. `layer`: 0 far, 1 mid, 2 near.
    static func drawAirborne(layer: Int, index: Int, in target: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        let seed = index + layer * 1000 + 9000
        let rank = BG.hash(seed, 161)
        let visible = BG.clamp01((look.airborne - rank) / 0.06)
        guard visible > 0.01 else { return }

        let depth: CGFloat = layer == 0 ? BG.hash(seed, 150, 0.2, 0.45) : (layer == 1 ? BG.hash(seed, 150, 0.5, 0.9) : 1)
        let x0 = BG.hash(seed, 155) * size.width
        // How hard the gust is blowing at this leaf right now.
        let local = min(NovemberWind.strength(at: x0, t) * look.force, 1.6)

        // Fall: constant speed, so gusts never teleport a leaf. They only add eddy motion.
        let fall = BG.hash(seed, 151, 30, 80) * BG.lerp(0.6, 1.25, depth)
        let span = size.height + 160
        let progress = BG.fract(BG.hash(seed, 152) + t * fall / span)

        let eddyAngle = t * BG.hash(seed, 162, 1.2, 2.4) + BG.hash(seed, 163) * 6.28
        let radius = BG.lerp(14, 52, depth) * local
        let flutter = sin(t * BG.hash(seed, 153, 0.8, 1.6) + BG.hash(seed, 154) * 6.28)

        // The leaf is carried by the integrated wind, held back by how far right it is
        // (the gust arrives later there), with a parallax factor for depth.
        let carried = (look.drift - NovemberWind.speed(t) * look.force * x0 / 600) * BG.lerp(0.55, 1.2, depth)
        let x = BG.wrap(
            x0 + carried + flutter * BG.lerp(18, 44, depth) + cos(eddyAngle) * radius,
            length: size.width,
            margin: 90
        )
        let y = progress * span - 80 + sin(eddyAngle) * radius * 0.75 - local * BG.hash(seed, 164, 6, 38)

        let rotation = Double(flutter * 0.9 + t * BG.hash(seed, 156, -0.8, 0.8) + local * sin(eddyAngle) * 0.6)
        let flipAngle = t * BG.hash(seed, 157, 0.9, 2.2) + BG.hash(seed, 158) * 6.28 + local * 1.2 * sin(eddyAngle * 1.3)
        let flip = cos(flipAngle)

        let leafSize: CGFloat
        switch layer {
        case 0: leafSize = BG.hash(seed, 165, 9, 17)
        case 1: leafSize = BG.hash(seed, 165, 17, 31)
        default: leafSize = BG.hash(seed, 165, 42, 62)
        }

        var opacity = (layer == 0 ? 0.55 : 0.92) * visible
        opacity *= BG.smoothstep(0, 0.06, progress) * (1 - BG.smoothstep(0.92, 1, progress))
        if layer == 2 {
            // Big near leaves stay out of the way of the calendar grid.
            let cx = 1 - BG.clamp01(abs(x / size.width - 0.5) / 0.3)
            let cy = 1 - BG.clamp01(abs(y / size.height - 0.5) / 0.3)
            opacity *= BG.lerp(1, 0.45, BG.smoothstep(0, 0.4, min(cx, cy)))
        }

        LeafPainter.draw(
            in: &target,
            at: CGPoint(x: x, y: y),
            size: leafSize,
            rotation: rotation,
            flip: flip,
            palette: NovemberLeaves.palette(Int(BG.hash(seed, 159) * 5), progress: look.progress),
            maple: BG.hash(seed, 160) < 0.55,
            opacity: Double(opacity)
        )
    }

    // MARK: Wind and foreground

    /// Thin streaks that appear in the air as a gust sweeps through.
    static func drawStreaks(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        for i in 0..<26 {
            let y = size.height * BG.hash(i, 360, 0.05, 0.85)
            let x = BG.wrap(BG.hash(i, 361) * size.width + look.drift * BG.hash(i, 362, 1.2, 2.2), length: size.width, margin: 220)
            let gust = NovemberWind.strength(at: x, t) * min(look.force, 1.5)
            let alpha = Double(gust) * 0.22
            guard alpha > 0.01 else { continue }
            let length = 50 + 170 * gust
            let head = CGPoint(x: x, y: y)
            let tail = CGPoint(x: x - length, y: y + sin(x * 0.01 + CGFloat(i)) * 3)
            var streak = Path()
            streak.move(to: tail)
            streak.addLine(to: head)
            ctx.stroke(
                streak,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 0.95, 0.88, 0), BG.rgb(1, 0.95, 0.88, alpha)]),
                    startPoint: tail,
                    endPoint: head
                ),
                style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
            )
        }
    }

    /// Bare limbs reaching in from the top corners, swaying in the gusts. A few leaves
    /// still cling to them early in the month; by the end they are bare.
    static func drawBranches(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: NovemberModel.Look) {
        let limbs: [(origin: CGPoint, mirror: CGFloat, scale: CGFloat)] = [
            (CGPoint(x: -4, y: -4), 1, size.width * 0.27),
            (CGPoint(x: size.width + 4, y: -4), -1, size.width * 0.2)
        ]
        let ink = BG.rgb(0.08, 0.055, 0.045, 0.78)
        let cling = 0.5 * (1 - look.progress * 0.9)

        for (k, limb) in limbs.enumerated() {
            let art = NovemberBranches.corners[k]
            let gust = NovemberWind.strength(at: limb.origin.x, t) * min(look.force, 1.5)
            let rot = sin(t * 0.6 + CGFloat(k) * 2) * 0.012 + gust * 0.03 * sin(t * 2.3 + CGFloat(k))

            var branch = ctx
            branch.translateBy(x: limb.origin.x, y: limb.origin.y)
            branch.rotate(by: .radians(Double(rot)))
            branch.scaleBy(x: limb.scale * limb.mirror, y: limb.scale)
            branch.stroke(art.thick, with: .color(ink), style: StrokeStyle(lineWidth: 0.017, lineCap: .round, lineJoin: .round))
            branch.stroke(art.mid, with: .color(ink), style: StrokeStyle(lineWidth: 0.008, lineCap: .round))
            branch.stroke(art.thin, with: .color(ink), style: StrokeStyle(lineWidth: 0.0028, lineCap: .round))

            // Clinging leaves hang from some of the twig tips.
            for (i, tip) in art.tips.enumerated() where BG.hash(i + k * 200, 370) < cling {
                let x = tip.x * limb.mirror * limb.scale
                let y = tip.y * limb.scale
                let p = CGPoint(
                    x: limb.origin.x + x * cos(rot) - y * sin(rot),
                    y: limb.origin.y + x * sin(rot) + y * cos(rot)
                )
                let flap = sin(t * BG.hash(i, 371, 1.5, 3) + CGFloat(i)) * (0.15 + gust * 0.6)
                LeafPainter.draw(
                    in: &ctx,
                    at: p,
                    size: BG.hash(i + k * 200, 372, 15, 22),
                    rotation: Double(CGFloat.pi + flap),
                    flip: 0.7 + 0.3 * sin(t * 1.1 + CGFloat(i)),
                    palette: NovemberLeaves.palette(i, progress: look.progress),
                    maple: i % 2 == 0,
                    opacity: 0.95
                )
            }
        }
    }
}
