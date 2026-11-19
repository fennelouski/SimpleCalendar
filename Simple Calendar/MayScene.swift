//
//  MayScene.swift
//  Simple Calendar
//
//  May: a meadow in bloom under late-morning light.
//
//  A warm breeze rolling through the meadow is the star. One gust signal drives the
//  scene and it travels: a point on the screen feels each gust `x / 300` seconds after
//  the left edge, so waves visibly run through the grass, each one carrying a silvery
//  sheen as the blades bend. The same gusts nod the flower heads, shake petals loose
//  from a blossoming branch in the top-left corner and carry them across, and pull
//  the seeds off dandelion clocks. Bees hop from open flower to open flower, and each
//  head dips when one lands.
//
//  The scene also follows the selected day:
//    * month progress - the meadow fills in: more flower slots, taller grass, more pollen
//    * Mother's Day   - every slot blooms in a wave and holds, and a shower of petals
//                       falls from the top
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct MayFlowersAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = MayModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = MayModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            MayScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class MayModel {
    struct Target {
        let progress: Double
        let mothersDay: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            progress = day.progress
            // US Mother's Day: the second Sunday of May.
            mothersDay = day.month == 5 && day.isNth(2, weekday: 1) ? 1 : 0
        }
    }

    struct Look {
        var progress: CGFloat
        var mothersDay: CGFloat
        /// Breeze displacement accumulated since the scene appeared.
        var drift: CGFloat
        /// Seconds into the Mother's Day petal shower, or -1.
        var showerAge: CGFloat

        var activeSlots: CGFloat { BG.lerp(5, 9, progress) }
        var grassScale: CGFloat { BG.lerp(0.8, 1.1, progress) }
        var pollen: CGFloat { BG.lerp(0.6, 1.2, progress) }
    }

    private let progressTransition = SceneTransition()
    private let motherTransition = SceneTransition()
    private let shower = SceneMoment(duration: 9)
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let progress = progressTransition.value(target: target.progress, time: time)
        let mother = motherTransition.value(target: target.mothersDay, time: time)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * MayWind.speed(CGFloat(time))
        }
        lastTime = time
        var showerAge: CGFloat = -1
        if let age = shower.elapsed(arrived: mother > 0.999, time: time) {
            showerAge = CGFloat(age)
        }
        return Look(progress: CGFloat(progress), mothersDay: CGFloat(mother), drift: drift, showerAge: showerAge)
    }
}

// MARK: - Wind

/// One gust signal for the meadow (periods of roughly 7 to 30 s).
private enum MayWind {
    static func signal(_ t: CGFloat) -> CGFloat {
        0.4 * sin(t * 0.21) + 0.3 * sin(t * 0.53 + 1.4) + 0.2 * sin(t * 0.89 + 2.2) + 0.1 * sin(t * 1.31)
    }

    /// 0...1 gust strength.
    static func gust(_ t: CGFloat) -> CGFloat { BG.smoothstep(-0.25, 0.75, signal(t)) }

    /// Gusts roll left to right: a point at `x` feels each one `x / 300` seconds late.
    static func gust(at x: CGFloat, _ t: CGFloat) -> CGFloat { gust(t - x / 300) }

    /// Breeze speed, points per second (never reverses).
    static func speed(_ t: CGFloat) -> CGFloat { 20 + 26 * gust(t) }
}

// MARK: - Flowers

private struct MayFlowerKind {
    let petals: Int
    let petalWidth: CGFloat
    let petalLength: CGFloat
    let inner: Color
    let outer: Color
    let center: Color
    let centerRim: Color
    let tulip: Bool
    let daisy: Bool
}

/// One flower slot this frame.
private struct MayFlower {
    var base: CGPoint
    var head: CGPoint
    var kind: Int
    var dandelion: Bool
    var grow: CGFloat
    var bloom: CGFloat
    var wilt: CGFloat
    var opacity: Double
    var radius: CGFloat
    var leafSide: CGFloat
    var seed: Int
    var start: CGFloat
    var period: CGFloat
}

private enum MayArt {
    static let kinds: [MayFlowerKind] = [
        MayFlowerKind(petals: 14, petalWidth: 0.15, petalLength: 0.5, inner: BG.rgb(0.9, 0.9, 0.98), outer: .white,
                      center: BG.rgb(1, 0.85, 0.2), centerRim: BG.rgb(0.85, 0.5, 0.05), tulip: false, daisy: true),
        MayFlowerKind(petals: 8, petalWidth: 0.26, petalLength: 0.5, inner: BG.rgb(0.75, 0.1, 0.45), outer: BG.rgb(1, 0.7, 0.85),
                      center: BG.rgb(1, 0.85, 0.25), centerRim: BG.rgb(0.8, 0.5, 0.1), tulip: false, daisy: false),
        MayFlowerKind(petals: 5, petalWidth: 0.4, petalLength: 0.48, inner: BG.rgb(0.7, 0.03, 0.05), outer: BG.rgb(1, 0.35, 0.18),
                      center: BG.rgb(0.15, 0.1, 0.12), centerRim: BG.rgb(0.05, 0.02, 0.05), tulip: false, daisy: false),
        MayFlowerKind(petals: 3, petalWidth: 0.3, petalLength: 0.62, inner: BG.rgb(0.78, 0.1, 0.35), outer: BG.rgb(1, 0.6, 0.72),
                      center: .clear, centerRim: .clear, tulip: true, daisy: false),
        MayFlowerKind(petals: 3, petalWidth: 0.3, petalLength: 0.62, inner: BG.rgb(0.92, 0.5, 0.05), outer: BG.rgb(1, 0.92, 0.4),
                      center: .clear, centerRim: .clear, tulip: true, daisy: false),
        MayFlowerKind(petals: 6, petalWidth: 0.3, petalLength: 0.45, inner: BG.rgb(0.35, 0.12, 0.6), outer: BG.rgb(0.75, 0.6, 1),
                      center: BG.rgb(1, 0.95, 0.6), centerRim: BG.rgb(0.9, 0.7, 0.2), tulip: false, daisy: false)
    ]

    /// Five-petal blossom (radius 1).
    static let blossom: Path = {
        var path = Path()
        for k in 0..<5 {
            let a = CGFloat(k) / 5 * 2 * CGFloat.pi - CGFloat.pi / 2
            path.addPath(BG.ellipse(.zero, 0.36, 0.55).applying(CGAffineTransform(translationX: cos(a) * 0.5, y: sin(a) * 0.5).rotated(by: a + CGFloat.pi / 2)))
        }
        return path
    }()

    /// Dandelion clock (radius 1): seed stalks with tufted tips.
    static let clockStalks: Path = {
        var path = Path()
        for k in 0..<24 {
            let a = CGFloat(k) / 24 * 2 * CGFloat.pi
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: cos(a) * 0.85, y: sin(a) * 0.85))
        }
        return path
    }()
}

// MARK: - Scene

private enum MayScene {
    static let slots = 9
    static let period: CGFloat = 28

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: MayModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let sun = CGPoint(x: size.width * 0.92, y: -size.height * 0.05)
        var flowers = makeFlowers(size: size, t: t, look: look, sun: sun)
        var bees = makeBees(flowers: flowers, size: size, t: t)
        for i in bees.indices where bees[i].landed > 0 {
            // A landing bee dips the head 3-5 pt; it springs back as she settles.
            let dip = 4 * bees[i].landed * (1 + 0.35 * sin(bees[i].landedAge * 14) * exp(-bees[i].landedAge * 3))
            flowers[bees[i].slot].head.y += dip
            bees[i].position.y += dip
        }

        drawSky(in: &ctx, size: size, sun: sun, dark: dark)
        drawPollen(in: &ctx, size: size, t: t, look: look, dark: dark, near: false)
        drawFarMeadow(in: &ctx, size: size, t: t)
        drawGrass(in: &ctx, size: size, t: t, look: look, row: 0)
        for flower in flowers {
            drawFlower(flower, in: &ctx, size: size, t: t, look: look, sun: sun, dark: dark)
        }
        drawSeeds(in: &ctx, size: size, t: t, look: look, flowers: flowers)
        drawGrass(in: &ctx, size: size, t: t, look: look, row: 1)
        drawBees(bees, in: &ctx, t: t)
        drawBranch(in: &ctx, size: size, t: t)
        drawPetals(in: &ctx, size: size, t: t, look: look)
        drawShower(in: &ctx, size: size, t: t, look: look)
        drawPollen(in: &ctx, size: size, t: t, look: look, dark: dark, near: true)
    }

    // MARK: Sky and land

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, sun: CGPoint, dark: Bool) {
        let sky = Gradient(stops: [
            .init(color: BG.rgb(0.6, 0.8, 1, 0.16), location: 0),
            .init(color: BG.rgb(0.9, 0.95, 1, 0.06), location: 0.6),
            .init(color: BG.rgb(0.95, 1, 0.85, 0.12), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        ctx.glow(at: sun, radius: size.width * 0.5, color: BG.rgb(1, 0.95, 0.78), intensity: dark ? 0.22 : 0.12)
    }

    static func hillY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.885 + 0.018 * sin(u * 3.9 + 2.1) + 0.008 * sin(u * 11 + 0.3))
    }

    /// Soft far meadow with blossoming trees near the edges.
    static func drawFarMeadow(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
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
            Gradient(colors: [BG.rgb(0.7, 0.88, 0.6, 0.38), BG.rgb(0.45, 0.7, 0.4, 0.42)]),
            startPoint: CGPoint(x: 0, y: size.height * 0.86),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        var trunks = Path()
        var crowns = Path()
        var blossoms = Path()
        for i in 0..<8 {
            let u = BG.hash(i, 1200)
            let tx = (u < 0.5 ? u * 0.5 : 0.75 + (u - 0.5) * 0.5) * size.width
            let r = BG.hash(i, 1201, 12, 22)
            let base = hillY(tx, size: size) + 2
            trunks.addRect(CGRect(x: tx - 1.5, y: base - r * 0.6, width: 3, height: r * 0.65))
            let c = CGPoint(x: tx + MayWind.gust(at: tx, t) * 1.5, y: base - r * 1.1)
            crowns.addPath(BG.ellipse(c, r, r * 0.8))
            for k in 0..<6 {
                let a = BG.hash(i * 10 + k, 1202) * 2 * CGFloat.pi
                let d = BG.hash(i * 10 + k, 1203, 0.2, 0.8) * r
                blossoms.addPath(BG.circle(CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d * 0.8), r * 0.22))
            }
        }
        ctx.fill(trunks, with: .color(BG.rgb(0.35, 0.25, 0.2, 0.45)))
        ctx.fill(crowns, with: .color(BG.rgb(0.45, 0.65, 0.4, 0.45)))
        ctx.fill(blossoms, with: .color(BG.rgb(1, 0.85, 0.9, 0.6)))
    }

    /// A grass row. Blades bend with the gust at their x, and a silvery sheen rides each
    /// wave as the blades lean over.
    static func drawGrass(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look, row: Int) {
        let count = Int(size.width / (row == 0 ? 5.5 : 7.5))
        let baseHeight = size.height * (row == 0 ? 0.08 : 0.055) * look.grassScale
        var blades = Path()
        for i in 0..<count {
            let seed = i + row * 5000
            let x = (CGFloat(i) + BG.hash(seed, 71)) / CGFloat(count) * (size.width + 20) - 10
            let h = baseHeight * BG.hash(seed, 72, 0.55, 1.25)
            let w = BG.hash(seed, 73, 3, 6.5)
            let gust = MayWind.gust(at: x, t)
            let bend = (gust * 1.1 + 0.15 + 0.12 * sin(t * 2.3 + x * 0.03)) * h * 0.35
            let tip = CGPoint(x: x + bend, y: size.height - h + abs(bend) * 0.25)
            blades.move(to: CGPoint(x: x - w / 2, y: size.height))
            blades.addQuadCurve(to: tip, control: CGPoint(x: x - w * 0.2 + bend * 0.3, y: size.height - h * 0.55))
            blades.addQuadCurve(to: CGPoint(x: x + w / 2, y: size.height), control: CGPoint(x: x + w * 0.3 + bend * 0.35, y: size.height - h * 0.5))
            blades.closeSubpath()
        }
        var grass = ctx
        grass.opacity = row == 0 ? 0.6 : 0.9
        // Tips facing the sun glow yellow-green (translucency).
        let tipColor = row == 0 ? BG.rgb(0.6, 0.82, 0.45) : BG.rgb(0.62, 0.9, 0.38)
        let baseColor = row == 0 ? BG.rgb(0.2, 0.42, 0.22) : BG.rgb(0.1, 0.38, 0.12)
        grass.fill(blades, with: .linearGradient(
            Gradient(colors: [tipColor, baseColor]),
            startPoint: CGPoint(x: 0, y: size.height - baseHeight * 1.25),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        // The sheen: the same blades, lit by the gust at each x.
        var stops: [Gradient.Stop] = []
        for k in 0...12 {
            let u = CGFloat(k) / 12
            let g = MayWind.gust(at: u * size.width, t)
            stops.append(.init(color: BG.rgb(0.92, 1, 0.82, Double(BG.smoothstep(0.35, 1, g)) * 0.45), location: u))
        }
        grass.fill(blades, with: .linearGradient(Gradient(stops: stops), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)))
    }

    // MARK: Flowers

    static func makeFlowers(size: CGSize, t: CGFloat, look: MayModel.Look, sun: CGPoint) -> [MayFlower] {
        var flowers: [MayFlower] = []
        flowers.reserveCapacity(slots * 2)
        let wave = look.mothersDay
        for s in 0..<slots {
            // Slots fill in through the month (5 to 9), faded in by rank.
            let rank = CGFloat((s * 4) % slots)
            let inUse = BG.clamp01(look.activeSlots - rank)
            // Mother's Day: a second, fixed flower grows in each slot, left to right.
            let hold = BG.smoothstep(CGFloat(s) / CGFloat(slots) * 0.6, CGFloat(s) / CGFloat(slots) * 0.6 + 0.4, wave)

            let position = t / period + BG.hash(s, 81)
            let cycle = Int(floor(position))
            let life = BG.fract(position)
            let seed = s * 613 + cycle
            if inUse * (1 - hold) > 0.01 {
                flowers.append(flower(slot: s, seed: seed, life: life, start: CGFloat(cycle) - BG.hash(s, 81), opacity: Double(inUse * (1 - hold)), held: false, size: size, t: t, look: look, sun: sun))
            }
            if hold > 0.01 {
                // Grown in by `hold`, then held at full bloom.
                let held = BG.lerp(0, 0.5, hold)
                flowers.append(flower(slot: s, seed: s * 613 + 99_991, life: held, start: 0, opacity: Double(hold), held: true, size: size, t: t, look: look, sun: sun))
            }
        }
        return flowers
    }

    static func flower(slot s: Int, seed: Int, life: CGFloat, start: CGFloat, opacity: Double, held: Bool, size: CGSize, t: CGFloat, look: MayModel.Look, sun: CGPoint) -> MayFlower {
        let kindIndex = Int(BG.hash(seed, 82) * CGFloat(MayArt.kinds.count)) % MayArt.kinds.count
        // One slot in four may grow a dandelion clock (never in the Mother's Day bloom).
        let dandelion = !held && BG.hash(seed, 87) < 0.25
        let x = (CGFloat(s) + 0.15 + 0.7 * BG.hash(seed, 83)) / CGFloat(slots) * size.width
        let groundY = size.height + 4
        let grow = BG.easeInOut(BG.smoothstep(0, 0.2, life))
        let bloom = BG.easeInOut(BG.smoothstep(0.16, 0.36, life))
        let wilt = BG.smoothstep(0.85, 1, life)
        let stemHeight = min(BG.hash(seed, 84, 80, 150), size.height * 0.15) * grow * (1 - 0.25 * wilt)
        let gust = MayWind.gust(at: x, t)
        let sway = (sin(t * 0.8 + CGFloat(s) * 1.7) * 7 + gust * 14) * grow + wilt * 10
        let head = CGPoint(x: x + sway, y: groundY - stemHeight)
        return MayFlower(
            base: CGPoint(x: x, y: groundY),
            head: head,
            kind: kindIndex,
            dandelion: dandelion,
            grow: grow,
            bloom: bloom,
            wilt: wilt,
            opacity: opacity * Double(1 - wilt * 0.9),
            radius: BG.hash(seed, 86, 26, 40) * (0.35 + 0.65 * bloom) * (1 - 0.3 * wilt),
            leafSide: BG.hash(seed, 85) > 0.5 ? 0.9 : -0.9,
            seed: seed,
            start: start * period,
            period: period
        )
    }

    static func drawFlower(_ f: MayFlower, in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look, sun: CGPoint, dark: Bool) {
        guard f.grow > 0.01, f.opacity > 0.01 else { return }
        var plant = ctx
        plant.opacity = f.opacity
        var stem = Path()
        let lean = f.head.x - f.base.x
        stem.move(to: f.base)
        stem.addQuadCurve(to: f.head, control: CGPoint(x: f.base.x - lean * 0.3, y: (f.base.y + f.head.y) / 2))
        plant.stroke(stem, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.5, 0.82, 0.38), BG.rgb(0.15, 0.45, 0.15)]),
            startPoint: f.head,
            endPoint: f.base
        ), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        let leafPoint = CGPoint(x: f.base.x + lean * 0.12, y: f.base.y - (f.base.y - f.head.y) * 0.35)
        drawStemLeaf(in: &plant, at: leafPoint, size: 34 * f.grow, rotation: Double(f.leafSide))

        if f.dandelion {
            drawDandelion(f, in: &plant, t: t)
            return
        }
        let kind = MayArt.kinds[f.kind]
        // Soft shadow on the grass and a colored glow.
        plant.fill(BG.ellipse(CGPoint(x: f.head.x + 6, y: f.head.y + f.radius * 1.2), f.radius * 0.8, f.radius * 0.18), with: .color(.black.opacity(0.08 * Double(f.bloom))))
        plant.glow(at: f.head, radius: f.radius * 1.9, color: kind.outer, intensity: 0.22 * Double(f.bloom))
        // Open heads turn up to about 12 degrees toward the sun and nod in the gusts.
        let toSun = BG.clamp01((sun.x - f.head.x) / (sun.x + 1)) * 0.21
        let nod = MayWind.gust(at: f.head.x, t) * 0.12 + f.wilt * 0.5
        let tilt = Double((toSun + nod) * f.bloom)
        if kind.tulip {
            drawTulip(in: &plant, at: f.head, radius: f.radius, kind: kind, bloom: f.bloom, tilt: tilt)
        } else {
            drawRadialFlower(in: &plant, at: f.head, radius: f.radius, kind: kind, bloom: f.bloom * (1 - 0.4 * f.wilt), spin: Double(sin(t * 0.3 + CGFloat(f.seed % 9)) * 0.06) + tilt, dark: dark)
        }
    }

    static func drawStemLeaf(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double) {
        guard size > 1 else { return }
        var leaf = ctx
        leaf.translateBy(x: p.x, y: p.y)
        leaf.rotate(by: .radians(rotation))
        leaf.translateBy(x: 0, y: -size * 0.45)
        leaf.scaleBy(x: size * 0.6, y: size)
        leaf.fill(LeafPainter.oval, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.55, 0.88, 0.4), BG.rgb(0.12, 0.45, 0.15)]),
            startPoint: CGPoint(x: -0.3, y: -0.5),
            endPoint: CGPoint(x: 0.3, y: 0.4)
        ))
        leaf.stroke(LeafPainter.ovalVeins, with: .color(BG.rgb(0.8, 1, 0.7, 0.45)), lineWidth: 0.03)
    }

    static func drawRadialFlower(in ctx: inout GraphicsContext, at p: CGPoint, radius r: CGFloat, kind: MayFlowerKind, bloom: CGFloat, spin: Double, dark: Bool) {
        var head = ctx
        head.translateBy(x: p.x, y: p.y)
        head.scaleBy(x: 1, y: 0.82)
        head.rotate(by: .radians(spin))
        let openness = 0.35 + 0.65 * bloom
        let shape = BG.ellipse(CGPoint(x: 0, y: -kind.petalLength * 0.55), kind.petalWidth, kind.petalLength * 0.55)
        var crease = Path()
        crease.move(to: CGPoint(x: 0, y: -0.05))
        crease.addLine(to: CGPoint(x: 0, y: -kind.petalLength * 0.9))
        for i in 0..<kind.petals {
            let angle = CGFloat(i) / CGFloat(kind.petals) * 2 * CGFloat.pi
            var petal = head
            petal.rotate(by: .radians(Double(angle)))
            petal.scaleBy(x: r, y: r * openness)
            petal.fill(shape, with: .linearGradient(
                Gradient(colors: [kind.inner, kind.outer]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: -kind.petalLength * 1.05)
            ))
            // Daisies get a soft violet edge so they still read on light themes.
            petal.stroke(shape, with: .color(kind.daisy && !dark ? BG.rgb(0.72, 0.7, 0.85, 0.5) : kind.inner.opacity(0.35)), lineWidth: 0.012)
            petal.stroke(crease, with: .color(.white.opacity(0.25)), lineWidth: 0.012)
        }
        let centerRadius = r * 0.22
        head.fill(BG.circle(.zero, centerRadius), with: .radialGradient(
            Gradient(colors: [kind.center, kind.centerRim]),
            center: CGPoint(x: -centerRadius * 0.3, y: -centerRadius * 0.3),
            startRadius: 0,
            endRadius: centerRadius * 1.3
        ))
        var dots = Path()
        for i in 0..<10 {
            let a = CGFloat(i) / 10 * 2 * CGFloat.pi
            dots.addPath(BG.circle(CGPoint(x: cos(a) * centerRadius * 0.65, y: sin(a) * centerRadius * 0.65), centerRadius * 0.12))
        }
        head.fill(dots, with: .color(kind.centerRim.opacity(0.8)))
        head.fill(BG.circle(CGPoint(x: -centerRadius * 0.3, y: -centerRadius * 0.35), centerRadius * 0.25), with: .color(.white.opacity(0.35)))
    }

    static func drawTulip(in ctx: inout GraphicsContext, at p: CGPoint, radius r: CGFloat, kind: MayFlowerKind, bloom: CGFloat, tilt: Double) {
        var head = ctx
        head.translateBy(x: p.x, y: p.y)
        head.rotate(by: .radians(tilt))
        head.scaleBy(x: r, y: r)
        let spread = 0.12 + 0.3 * bloom
        let angles: [CGFloat] = [-spread, spread, 0]
        let shape = BG.ellipse(CGPoint(x: 0, y: -0.42), kind.petalWidth, kind.petalLength * 0.62)
        for (index, angle) in angles.enumerated() {
            var petal = head
            petal.rotate(by: .radians(Double(angle)))
            let front = index == 2
            petal.fill(shape, with: .linearGradient(
                Gradient(colors: front ? [kind.outer, kind.inner] : [kind.outer.opacity(0.9), kind.inner.opacity(0.9)]),
                startPoint: CGPoint(x: 0, y: -0.95),
                endPoint: CGPoint(x: 0, y: 0.1)
            ))
            petal.stroke(shape, with: .color(kind.inner.opacity(0.4)), lineWidth: 0.02)
            if front {
                petal.fill(BG.ellipse(CGPoint(x: -0.1, y: -0.55), 0.05, 0.18), with: .color(.white.opacity(0.35)))
            }
        }
    }

    /// When a dandelion seeds, each seed leaves the clock at its own moment, but only if
    /// a gust is blowing then; otherwise it stays until the plant fades.
    static func seedDeparture(_ f: MayFlower, seed j: Int, t: CGFloat) -> CGFloat? {
        let leave = f.start + f.period * (0.5 + BG.hash(f.seed * 31 + j, 1210, 0, 0.3))
        guard MayWind.gust(at: f.base.x, leave) > 0.4 else { return nil }
        return leave
    }

    static func drawDandelion(_ f: MayFlower, in ctx: inout GraphicsContext, t: CGFloat) {
        let r = 16 * f.bloom
        guard r > 0.5 else { return }
        // Before it opens: a closed yellow flower.
        let yellow = 1 - BG.smoothstep(0.3, 0.5, f.bloom)
        if yellow > 0.01 {
            ctx.fill(BG.circle(f.head, 7), with: .color(BG.rgb(1, 0.85, 0.2, Double(yellow))))
        }
        var stalks = ctx
        stalks.translateBy(x: f.head.x, y: f.head.y)
        stalks.scaleBy(x: r, y: r)
        var tufts = Path()
        var remaining = 0
        for j in 0..<24 {
            if let leave = seedDeparture(f, seed: j, t: t), t > leave { continue }
            remaining += 1
            let a = CGFloat(j) / 24 * 2 * CGFloat.pi
            tufts.addPath(BG.circle(CGPoint(x: cos(a) * 0.9, y: sin(a) * 0.9), 0.1))
        }
        let fill = Double(remaining) / 24
        stalks.stroke(MayArt.clockStalks, with: .color(.white.opacity(0.5 * fill * Double(1 - yellow))), lineWidth: 0.03)
        stalks.fill(tufts, with: .color(.white.opacity(0.85 * Double(1 - yellow))))
        ctx.fill(BG.circle(f.head, 2), with: .color(BG.rgb(0.7, 0.6, 0.4)))
    }

    /// Seeds that have left a dandelion drift up and away on the breeze, then fade.
    static func drawSeeds(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look, flowers: [MayFlower]) {
        var seeds = Path()
        var alphaSum = 0.0
        var n = 0
        for f in flowers where f.dandelion && f.opacity > 0.01 {
            for j in 0..<24 {
                guard let leave = seedDeparture(f, seed: j, t: t), t > leave else { continue }
                let a = t - leave
                guard a < 12 else { continue }
                let angle = CGFloat(j) / 24 * 2 * CGFloat.pi
                let start = CGPoint(x: f.head.x + cos(angle) * 14, y: f.head.y + sin(angle) * 14)
                let p = CGPoint(
                    x: start.x + a * 30 + sin(a * 1.3 + CGFloat(j)) * 12,
                    y: start.y - a * 14 + sin(a * 0.9 + CGFloat(j)) * 8
                )
                seeds.addPath(BG.circle(p, 1.4))
                seeds.move(to: p)
                seeds.addLine(to: CGPoint(x: p.x - 2, y: p.y + 4))
                alphaSum += Double(1 - BG.smoothstep(8, 12, a))
                n += 1
            }
        }
        guard n > 0 else { return }
        ctx.fill(seeds, with: .color(.white.opacity(0.85 * alphaSum / Double(n))))
    }

    // MARK: Bees

    private struct Bee {
        var position: CGPoint
        var heading: CGFloat
        var slot: Int
        var landed: CGFloat
        var landedAge: CGFloat
    }

    /// Bees hop between flowers: a short curving flight, then a rest on the head.
    private static func makeBees(flowers: [MayFlower], size: CGSize, t: CGFloat) -> [Bee] {
        var bees: [Bee] = []
        let open = flowers.indices.filter { flowers[$0].bloom > 0.6 && flowers[$0].wilt < 0.3 && !flowers[$0].dandelion }
        guard open.count >= 2 else { return bees }
        for b in 0..<3 {
            let hop: CGFloat = BG.hash(b, 1220, 3.5, 5)
            let position = t / hop + BG.hash(b, 1221)
            let cycle = Int(floor(position))
            let phase = BG.fract(position)
            let from = open[Int(BG.hash(b * 7919 + cycle, 1222) * CGFloat(open.count)) % open.count]
            let to = open[Int(BG.hash(b * 7919 + cycle + 1, 1222) * CGFloat(open.count)) % open.count]
            let a = CGPoint(x: flowers[from].head.x, y: flowers[from].head.y - 6)
            let c = CGPoint(x: flowers[to].head.x, y: flowers[to].head.y - 6)
            let flight: CGFloat = 0.35
            if phase < flight {
                let u = BG.easeInOut(phase / flight)
                let arc = sin(u * CGFloat.pi) * 40
                let p = CGPoint(x: BG.lerp(a.x, c.x, u) + sin(t * 9 + CGFloat(b)) * 3, y: BG.lerp(a.y, c.y, u) - arc)
                bees.append(Bee(position: p, heading: c.x >= a.x ? 1 : -1, slot: to, landed: 0, landedAge: 0))
            } else {
                let rest = (phase - flight) * hop
                let p = CGPoint(x: c.x + sin(t * 2 + CGFloat(b)) * 2, y: c.y)
                bees.append(Bee(position: p, heading: BG.hash(b, 1223) < 0.5 ? 1 : -1, slot: to, landed: BG.smoothstep(0, 0.15, rest), landedAge: rest))
            }
        }
        return bees
    }

    private static func drawBees(_ bees: [Bee], in ctx: inout GraphicsContext, t: CGFloat) {
        for (i, bee) in bees.enumerated() {
            var b = ctx
            b.translateBy(x: bee.position.x, y: bee.position.y)
            b.scaleBy(x: bee.heading * 7, y: 7)
            // Wings: a quick blur-disc.
            let beat = 0.6 + 0.4 * sin(t * 60 + CGFloat(i))
            b.fill(BG.ellipse(CGPoint(x: -0.1, y: -0.7), 0.6, 0.45 * beat), with: .color(.white.opacity(0.45)))
            b.fill(BG.ellipse(.zero, 0.8, 0.55), with: .linearGradient(
                Gradient(stops: [
                    .init(color: BG.rgb(0.95, 0.75, 0.1), location: 0),
                    .init(color: BG.rgb(0.95, 0.75, 0.1), location: 0.3),
                    .init(color: BG.rgb(0.15, 0.1, 0.05), location: 0.31),
                    .init(color: BG.rgb(0.15, 0.1, 0.05), location: 0.48),
                    .init(color: BG.rgb(0.95, 0.75, 0.1), location: 0.49),
                    .init(color: BG.rgb(0.95, 0.75, 0.1), location: 0.66),
                    .init(color: BG.rgb(0.15, 0.1, 0.05), location: 0.67),
                    .init(color: BG.rgb(0.15, 0.1, 0.05), location: 1)
                ]),
                startPoint: CGPoint(x: 0.8, y: 0),
                endPoint: CGPoint(x: -0.8, y: 0)
            ))
            b.fill(BG.circle(CGPoint(x: 0.85, y: -0.05), 0.32), with: .color(BG.rgb(0.15, 0.1, 0.05)))
        }
    }

    // MARK: Petals and pollen

    /// A blossoming branch in the top-left corner; the gusts shake petals loose from it.
    static func drawBranch(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let gust = MayWind.gust(at: 0, t)
        let rot = sin(t * 0.5) * 0.012 + gust * 0.03 * sin(t * 2.2)
        let scale = min(size.width * 0.24, 360)
        var limb = ctx
        limb.translateBy(x: -8, y: -8)
        limb.rotate(by: .radians(Double(rot)))
        limb.scaleBy(x: scale, y: scale)
        var wood = Path()
        wood.move(to: .zero)
        wood.addQuadCurve(to: CGPoint(x: 0.95, y: 0.3), control: CGPoint(x: 0.5, y: 0.02))
        wood.move(to: CGPoint(x: 0.45, y: 0.1))
        wood.addQuadCurve(to: CGPoint(x: 0.7, y: 0.5), control: CGPoint(x: 0.62, y: 0.2))
        wood.move(to: CGPoint(x: 0.25, y: 0.05))
        wood.addQuadCurve(to: CGPoint(x: 0.3, y: 0.42), control: CGPoint(x: 0.34, y: 0.2))
        limb.stroke(wood, with: .color(BG.rgb(0.3, 0.2, 0.18, 0.8)), style: StrokeStyle(lineWidth: 0.018, lineCap: .round))
        var blossoms = Path()
        var leaves = Path()
        let ends: [(CGPoint, CGPoint, CGPoint)] = [
            (.zero, CGPoint(x: 0.5, y: 0.02), CGPoint(x: 0.95, y: 0.3)),
            (CGPoint(x: 0.45, y: 0.1), CGPoint(x: 0.62, y: 0.2), CGPoint(x: 0.7, y: 0.5)),
            (CGPoint(x: 0.25, y: 0.05), CGPoint(x: 0.34, y: 0.2), CGPoint(x: 0.3, y: 0.42))
        ]
        for (k, curve) in ends.enumerated() {
            for j in 0..<9 {
                let u = 0.25 + 0.75 * CGFloat(j) / 8
                let a = (1 - u) * (1 - u)
                let m = 2 * (1 - u) * u
                let c = u * u
                let p = CGPoint(x: a * curve.0.x + m * curve.1.x + c * curve.2.x, y: a * curve.0.y + m * curve.1.y + c * curve.2.y)
                let seed = k * 20 + j
                let off = CGPoint(x: BG.hash(seed, 1230, -0.04, 0.04), y: BG.hash(seed, 1231, -0.03, 0.05))
                let s = BG.hash(seed, 1232, 0.022, 0.034)
                let flutter = sin(t * 2 + CGFloat(seed)) * 0.1 * (0.3 + gust)
                blossoms.addPath(MayArt.blossom, transform: CGAffineTransform(translationX: p.x + off.x, y: p.y + off.y).rotated(by: flutter + CGFloat(seed)).scaledBy(x: s, y: s))
                if j % 3 == 1 {
                    leaves.addPath(LeafPainter.oval, transform: CGAffineTransform(translationX: p.x - off.x, y: p.y + 0.03).rotated(by: 2.2 + flutter).scaledBy(x: 0.03, y: 0.05))
                }
            }
        }
        limb.fill(leaves, with: .color(BG.rgb(0.4, 0.65, 0.3, 0.8)))
        limb.fill(blossoms, with: .color(BG.rgb(1, 0.82, 0.88, 0.95)))
        limb.stroke(blossoms, with: .color(BG.rgb(0.95, 0.55, 0.7, 0.6)), lineWidth: 0.002)
    }

    /// Petals blown off the branch, tumbling across the screen on the breeze.
    static func drawPetals(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look) {
        let colors = [BG.rgb(1, 0.75, 0.85), BG.rgb(1, 0.92, 0.95), BG.rgb(0.95, 0.6, 0.8)]
        let span = size.width + 120
        for i in 0..<14 {
            let travel = BG.hash(i, 92) * span + look.drift * BG.hash(i, 91, 1.2, 2.2)
            let progress = BG.fract(travel / span)
            let x = progress * span - 60
            let y = size.height * BG.hash(i, 93, 0.12, 0.7) + sin(t * 0.9 + CGFloat(i)) * 40 + progress * size.height * 0.08
            let flip = cos(t * BG.hash(i, 94, 1, 2.4) + CGFloat(i))
            let petalSize = BG.hash(i, 95, 10, 18)
            var opacity = Double(BG.smoothstep(0, 0.05, progress) * (1 - BG.smoothstep(0.95, 1, progress)))
            if petalSize > 14 {
                let cx = abs(x / size.width - 0.5)
                let cy = abs(y / size.height - 0.5)
                if cx < 0.2 && cy < 0.2 { opacity *= 0.4 }
            }
            drawPetal(in: &ctx, at: CGPoint(x: x, y: y), size: petalSize, rotation: Double(t * 0.8 + CGFloat(i)), flip: flip, color: colors[i % colors.count], opacity: opacity)
        }
    }

    static func drawPetal(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, color: Color, opacity: Double) {
        guard opacity > 0.01 else { return }
        var petal = ctx
        petal.opacity = opacity
        petal.translateBy(x: p.x, y: p.y)
        petal.rotate(by: .radians(rotation))
        petal.scaleBy(x: size * max(abs(flip), 0.1), y: size)
        petal.fill(BG.ellipse(.zero, 0.32, 0.5), with: .linearGradient(
            Gradient(colors: [color, color.opacity(flip < 0 ? 0.55 : 0.8)]),
            startPoint: CGPoint(x: 0, y: -0.5),
            endPoint: CGPoint(x: 0, y: 0.5)
        ))
    }

    /// Mother's Day: a gentle shower of petals falling from the top.
    static func drawShower(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look) {
        let age = look.showerAge
        guard age >= 0 else { return }
        let colors = [BG.rgb(1, 0.75, 0.85), BG.rgb(1, 0.92, 0.95), BG.rgb(0.95, 0.6, 0.8), BG.rgb(1, 0.85, 0.6)]
        for k in 0..<42 {
            let a = age - BG.hash(k, 1240, 0, 4)
            guard a > 0 else { continue }
            let p = CGPoint(
                x: BG.hash(k, 1241) * size.width + sin(a * 1.1 + CGFloat(k)) * 30 + a * 12,
                y: -20 + a * BG.hash(k, 1242, 40, 80)
            )
            let fade = Double(BG.smoothstep(0, 0.4, a) * (1 - BG.smoothstep(6, 9, age)))
            drawPetal(in: &ctx, at: p, size: BG.hash(k, 1243, 9, 15), rotation: Double(a * 1.4 + CGFloat(k)), flip: cos(a * 2 + CGFloat(k)), color: colors[k % colors.count], opacity: fade)
        }
    }

    static func drawPollen(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MayModel.Look, dark: Bool, near: Bool) {
        let color = dark ? BG.rgb(1, 0.92, 0.55) : BG.rgb(0.85, 0.64, 0)
        if near {
            ctx.blurredLayer(radius: 6) { bokeh in
                for i in 0..<6 {
                    let x = BG.wrap(BG.hash(i, 1250) * size.width + look.drift * 0.6, length: size.width, margin: 60)
                    let y = size.height * BG.hash(i, 1251, 0.2, 0.85) + sin(t * 0.2 + CGFloat(i)) * 30
                    let r = BG.hash(i, 1252, 18, 34)
                    let p = CGPoint(x: x, y: y)
                    bokeh.fill(BG.circle(p, r), with: .radialGradient(
                        Gradient(colors: [color.opacity(0.14), color.opacity(0.06), color.opacity(0)]),
                        center: p, startRadius: 0, endRadius: r
                    ))
                }
            }
            return
        }
        // About 19 motes early in May, 38 by the end, faded in by rank.
        let amount = 32 * look.pollen
        for i in 0..<40 {
            let visible = BG.clamp01(amount - CGFloat(i))
            guard visible > 0.01 else { continue }
            let x = BG.wrap(BG.hash(i, 97) * size.width + look.drift * BG.hash(i, 98, 0.2, 0.5) + sin(t * 0.4 + CGFloat(i)) * 30, length: size.width, margin: 20)
            let y = size.height * BG.hash(i, 99, 0.15, 0.85) + sin(t * 0.3 + CGFloat(i) * 2) * 26
            let pulse = (0.5 + 0.5 * sin(t * BG.hash(i, 100, 0.8, 1.8) + CGFloat(i))) * visible
            let p = CGPoint(x: x, y: y)
            ctx.glow(at: p, radius: 9, color: color, intensity: Double(0.45 * pulse), additive: dark)
            ctx.fill(BG.circle(p, 1.4), with: .color(color.opacity(Double((0.6 + 0.4 * pulse) * visible))))
        }
    }
}
