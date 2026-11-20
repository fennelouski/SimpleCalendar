//
//  JuneScene.swift
//  Simple Calendar
//
//  June: a sunny garden at midday, seen from under a leafy canopy.
//
//  Dappled light is the star. The canopy in the top-left corner sways in the breeze,
//  and that one sway signal breaks the sunbeams into moving dapples
//  (`JuneLight.dapple`): beams brighten and fade as gaps in the leaves open and close,
//  the dust in the air shows only where light gets through, and sunflecks slide over
//  the flower border along the bottom. Butterflies drift through it all on looping
//  paths, flapping and gliding.
//
//  The scene also follows the selected day:
//    * daylight      - longer days strengthen the beams and cool the light slightly;
//                      fireflies come out on warm evenings, most on the longest days
//    * day character - which species fly (hash); a butterfly only changes species
//                      while it is off-screen
//    * solstice      - the butterflies gather and orbit in the brightest beam
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct JuneButterfliesAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = JuneModel()

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = JuneModel.Target(date: date)
        let state = model
        AnimatedScene(daylight: { ctx, size, time, daylight in
            let look = state.look(target: target, time: time, width: size.width)
            JuneScene.draw(in: &ctx, size: size, time: time, look: look, daylight: daylight)
        })
        .opacity(alpha)
    }
}

// MARK: - State

final class JuneModel {
    struct Target {
        /// 0 on the shortest June day ... 1 on the longest.
        let daylight: Double
        /// 1 on the longest days (fireflies).
        let longDay: Double
        let solstice: Double
        /// Species of each of the five butterflies (duplicates allowed).
        let species: [Int]

        init(date: Date) {
            let day = SceneDay(date: date)
            let hours = day.daylightHours
            daylight = min(max((hours - 14.6) / 0.32, 0), 1)
            longDay = hours > 14.85 ? 1 : 0
            solstice = day.isSeasonDay(1) ? 1 : 0
            species = (0..<5).map { k in Int(day.roll(500 + k) * 5) % 5 }
        }
    }

    struct Look {
        var daylight: CGFloat
        var longDay: CGFloat
        var gather: CGFloat
        /// Breeze displacement accumulated since the scene appeared.
        var drift: CGFloat
        var species: [Int]

        var beamStrength: CGFloat { BG.lerp(0.7, 1.15, daylight) * (1 + 0.3 * gather) }
        var warmth: CGFloat { BG.lerp(0.3, 0.2, daylight) }
    }

    private let daylightTransition = SceneTransition()
    private let longDayTransition = SceneTransition()
    private let gatherTransition = SceneTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?
    private var species: [Int] = []
    private var crossings: [Int] = []

    func look(target: Target, time: Double, width: CGFloat) -> Look {
        let daylight = daylightTransition.value(target: target.daylight, time: time)
        let longDay = longDayTransition.value(target: target.longDay, time: time)
        let gather = gatherTransition.value(target: target.solstice, time: time)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * (6 + 3 * JuneLight.sway(CGFloat(time)))
        }
        lastTime = time

        // A butterfly takes the day's species only when it starts a new crossing, which
        // always begins off-screen.
        if species.isEmpty {
            species = target.species
            crossings = (0..<5).map { JuneScene.crossing(k: $0, time: CGFloat(time)) }
        } else {
            for k in 0..<5 {
                let crossing = JuneScene.crossing(k: k, time: CGFloat(time))
                if crossing != crossings[k] {
                    crossings[k] = crossing
                    // While gathering they orbit on-screen, so the crossing boundary is
                    // not off-screen then; wait for the next one.
                    if gather < 0.001 {
                        species[k] = target.species[k]
                    }
                }
            }
        }
        return Look(daylight: CGFloat(daylight), longDay: CGFloat(longDay), gather: CGFloat(gather), drift: drift, species: species)
    }
}

// MARK: - Light

private enum JuneLight {
    /// -1...1 canopy sway: a slow swing with gusts on top (periods of about 9 to 40 s).
    static func sway(_ t: CGFloat) -> CGFloat {
        0.45 * sin(t * 0.16) + 0.3 * sin(t * 0.41 + 1.2) + 0.25 * sin(t * 0.7 + 2.9)
    }

    /// 0...1 how much light gets through the canopy along a ray leaving the corner at
    /// `angle`. Gaps in the leaves open and close as the canopy sways.
    static func dapple(_ angle: CGFloat, _ t: CGFloat) -> CGFloat {
        let s = sway(t)
        let v = 0.5 + 0.28 * sin(angle * 11 + s * 1.5) + 0.22 * sin(angle * 27 - s * 2.3 + 1.7)
        return BG.smoothstep(0.28, 0.78, v)
    }
}

private struct JuneBeam {
    var angle: CGFloat
    var spread: CGFloat
    var strength: CGFloat
}

private struct JuneFrame {
    var origin: CGPoint
    var beams: [JuneBeam]
    var length: CGFloat

    /// 0...1 light at a point: inside a beam, scaled by how open the canopy is there.
    func light(at p: CGPoint) -> CGFloat {
        let angle = atan2(p.y - origin.y, p.x - origin.x)
        var best: CGFloat = 0
        for beam in beams {
            let off = abs(angle - beam.angle)
            best = max(best, (1 - BG.smoothstep(beam.spread * 0.5, beam.spread * 1.3, off)) * beam.strength)
        }
        return BG.clamp01(best)
    }
}

// MARK: - Species

private struct JuneSpecies {
    let base: Color
    let bright: Color
    let border: Color
    let spots: Color
    let eyespot: Bool
    let iridescent: Bool
}

private enum JuneArt {
    static let species: [JuneSpecies] = [
        // Monarch
        JuneSpecies(base: BG.rgb(0.85, 0.35, 0.02), bright: BG.rgb(1, 0.62, 0.12), border: BG.rgb(0.08, 0.05, 0.04), spots: .white, eyespot: false, iridescent: false),
        // Blue morpho
        JuneSpecies(base: BG.rgb(0.0, 0.25, 0.75), bright: BG.rgb(0.25, 0.85, 1), border: BG.rgb(0.04, 0.05, 0.12), spots: BG.rgb(0.85, 0.95, 1), eyespot: false, iridescent: true),
        // Swallowtail
        JuneSpecies(base: BG.rgb(0.95, 0.78, 0.1), bright: BG.rgb(1, 0.95, 0.5), border: BG.rgb(0.1, 0.08, 0.05), spots: BG.rgb(0.4, 0.6, 1), eyespot: true, iridescent: false),
        // Peacock
        JuneSpecies(base: BG.rgb(0.55, 0.06, 0.12), bright: BG.rgb(0.9, 0.25, 0.25), border: BG.rgb(0.2, 0.08, 0.06), spots: BG.rgb(1, 0.9, 0.5), eyespot: true, iridescent: false),
        // Emerald swallowtail
        JuneSpecies(base: BG.rgb(0.02, 0.32, 0.22), bright: BG.rgb(0.25, 0.95, 0.6), border: BG.rgb(0.03, 0.08, 0.06), spots: BG.rgb(0.8, 1, 0.85), eyespot: false, iridescent: true)
    ]

    /// Cabbage white, for the courting pair.
    static let white = JuneSpecies(base: BG.rgb(0.95, 0.95, 0.9), bright: BG.rgb(1, 1, 0.97), border: BG.rgb(0.35, 0.35, 0.35), spots: BG.rgb(0.2, 0.2, 0.2), eyespot: false, iridescent: false)

    static let forewing: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0.03, y: -0.1))
        path.addCurve(to: CGPoint(x: 0.47, y: -0.44), control1: CGPoint(x: 0.12, y: -0.32), control2: CGPoint(x: 0.32, y: -0.47))
        path.addCurve(to: CGPoint(x: 0.4, y: -0.05), control1: CGPoint(x: 0.55, y: -0.36), control2: CGPoint(x: 0.5, y: -0.13))
        path.addCurve(to: CGPoint(x: 0.03, y: 0.02), control1: CGPoint(x: 0.3, y: 0.01), control2: CGPoint(x: 0.12, y: 0.03))
        path.closeSubpath()
        return path
    }()

    static let hindwing: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0.03, y: 0.0))
        path.addCurve(to: CGPoint(x: 0.38, y: 0.12), control1: CGPoint(x: 0.18, y: -0.03), control2: CGPoint(x: 0.36, y: 0.0))
        path.addCurve(to: CGPoint(x: 0.2, y: 0.43), control1: CGPoint(x: 0.42, y: 0.27), control2: CGPoint(x: 0.32, y: 0.41))
        path.addCurve(to: CGPoint(x: 0.03, y: 0.13), control1: CGPoint(x: 0.1, y: 0.45), control2: CGPoint(x: 0.04, y: 0.29))
        path.closeSubpath()
        return path
    }()

    static let veins: Path = {
        var path = Path()
        let root = CGPoint(x: 0.04, y: -0.02)
        let ends: [CGPoint] = [
            CGPoint(x: 0.44, y: -0.42), CGPoint(x: 0.48, y: -0.3), CGPoint(x: 0.46, y: -0.17), CGPoint(x: 0.38, y: -0.07),
            CGPoint(x: 0.36, y: 0.16), CGPoint(x: 0.33, y: 0.3), CGPoint(x: 0.22, y: 0.4)
        ]
        for end in ends {
            path.move(to: root)
            path.addQuadCurve(to: end, control: CGPoint(x: (root.x + end.x) * 0.5, y: (root.y + end.y) * 0.5 + 0.03))
        }
        return path
    }()

    static let marginSpots: Path = {
        var path = Path()
        for i in 0..<5 {
            let u = CGFloat(i) / 4
            path.addPath(BG.circle(CGPoint(x: 0.47 - u * 0.04, y: -0.4 + u * 0.3), 0.013))
        }
        return path
    }()

    static let abdomenRings: Path = {
        var path = Path()
        for y in [0.02, 0.08, 0.14, 0.2] as [CGFloat] {
            path.move(to: CGPoint(x: -0.026, y: y))
            path.addLine(to: CGPoint(x: 0.026, y: y))
        }
        return path
    }()

    static let antennae: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.01, y: -0.22))
        path.addQuadCurve(to: CGPoint(x: -0.11, y: -0.4), control: CGPoint(x: -0.03, y: -0.34))
        path.move(to: CGPoint(x: 0.01, y: -0.22))
        path.addQuadCurve(to: CGPoint(x: 0.11, y: -0.4), control: CGPoint(x: 0.03, y: -0.34))
        return path
    }()
}

// MARK: - Scene

private enum JuneScene {
    /// Which crossing butterfly `k` is on (it wraps off-screen between crossings).
    static func crossing(k: Int, time t: CGFloat) -> Int {
        Int(floor(BG.hash(k, 82) + t / BG.hash(k, 81, 38, 58)))
    }

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: JuneModel.Look, daylight: SceneDaylight) {
        let t = CGFloat(time)
        let dark = daylight.isDark
        let frame = makeFrame(size: size, t: t, look: look)
        let cover = daylight.weather?.cover ?? 0
        // Beams, dapples and dust need direct sun; they fade with the sun and under cloud.
        let sunshine = Double(daylight.sunUp * (1 - cover))
        let flying = Double(BG.smoothstep(0.35, 0.75, daylight.light) * (1 - (daylight.weather?.rain ?? 0)))

        DaylightPainter.stars(in: &ctx, size: size, time: time, daylight: daylight, cover: 0.3)
        DaylightPainter.moon(in: &ctx, size: size, daylight: daylight)
        WeatherPainter.cloudDeck(in: &ctx, size: size, time: time, daylight: daylight, seed: 6)
        if sunshine > 0.01 {
            var lit = ctx
            lit.opacity = sunshine
            drawSunAndBeams(in: &lit, size: size, t: t, look: look, frame: frame, dark: dark)
            drawMotes(in: &lit, size: size, t: t, look: look, frame: frame)
            drawBokeh(in: &lit, size: size, t: t, look: look, dark: dark)
        }
        ctx.drawLayer { garden in
            drawGarden(in: &garden, size: size, t: t, frame: frame, dark: dark)
            WeatherPainter.rainbow(in: &garden, size: size, daylight: daylight, strength: WeatherPainter.rainbowChance(daylight))
            if flying > 0.02 {
                var wings = garden
                wings.opacity = flying
                drawButterflies(in: &wings, size: size, t: t, look: look, frame: frame)
                drawCourting(in: &wings, size: size, t: t, look: look)
            }
            drawResting(in: &garden, size: size, t: t, look: look)
            drawCanopy(in: &garden, size: size, t: t)
            WeatherPainter.dullLight(in: &garden, size: size, daylight: daylight)
            DaylightPainter.lowSunGrade(in: &garden, size: size, daylight: daylight)
            DaylightPainter.nightGrade(in: &garden, size: size, daylight: daylight)
        }
        // Midsummer evenings: fireflies, most on the longest days.
        DaylightPainter.fireflies(in: &ctx, size: size, time: time, daylight: daylight, season: 0.7 + 0.3 * look.longDay)
        WeatherPainter.foreground(in: &ctx, size: size, time: time, daylight: daylight)
    }

    /// The beam the butterflies gather in on the solstice.
    static let gatherBeam = 3

    static func makeFrame(size: CGSize, t: CGFloat, look: JuneModel.Look) -> JuneFrame {
        let origin = CGPoint(x: size.width * 0.06, y: -size.height * 0.12)
        var beams: [JuneBeam] = []
        beams.reserveCapacity(7)
        for i in 0..<7 {
            let angle = 0.42 + CGFloat(i) * 0.11 + sin(t * 0.05 + CGFloat(i)) * 0.03
            let breathe = 0.6 + 0.4 * sin(t * 0.3 + CGFloat(i) * 1.9)
            // The gathering beam opens up fully on the solstice.
            let open = i == gatherBeam ? max(JuneLight.dapple(angle, t), look.gather) : JuneLight.dapple(angle, t)
            beams.append(JuneBeam(
                angle: angle,
                spread: BG.hash(i, 111, 0.022, 0.05),
                strength: breathe * (0.35 + 0.65 * open) * min(look.beamStrength, 1.3)
            ))
        }
        return JuneFrame(origin: origin, beams: beams, length: size.height * 1.7)
    }

    // MARK: Light

    static func drawSunAndBeams(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look, frame: JuneFrame, dark: Bool) {
        let warmth = Double(look.warmth)
        let warm = BG.rgb(1, 0.97 - 0.1 * warmth, 0.85 - 0.25 * warmth)
        let strength = Double(look.beamStrength)
        let origin = frame.origin
        ctx.glow(at: origin, radius: size.width * 0.4, color: warm, intensity: 0.3 * strength)
        var beamCtx = ctx
        if !dark {
            // Light theme: a warm tint rather than added light.
            beamCtx.opacity = 0.6
        }
        beamCtx.blurredLayer(radius: 22) { beams in
            if dark { beams.blendMode = .plusLighter }
            for beam in frame.beams {
                let length = frame.length
                var wedge = Path()
                wedge.move(to: origin)
                wedge.addLine(to: CGPoint(x: origin.x + cos(beam.angle - beam.spread) * length, y: origin.y + sin(beam.angle - beam.spread) * length))
                wedge.addLine(to: CGPoint(x: origin.x + cos(beam.angle + beam.spread) * length, y: origin.y + sin(beam.angle + beam.spread) * length))
                wedge.closeSubpath()
                beams.fill(
                    wedge,
                    with: .linearGradient(
                        Gradient(colors: [warm.opacity(min(0.3 * Double(beam.strength), 0.3)), warm.opacity(0)]),
                        startPoint: origin,
                        endPoint: CGPoint(x: origin.x + cos(beam.angle) * length * 0.8, y: origin.y + sin(beam.angle) * length * 0.8)
                    )
                )
            }
        }
    }

    /// Dust that shows only where a beam lights it.
    static func drawMotes(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look, frame: JuneFrame) {
        for i in 0..<70 {
            let x = BG.wrap(BG.hash(i, 1100) * size.width + look.drift * 0.25 + sin(t * 0.21 + CGFloat(i)) * 26, length: size.width, margin: 20)
            let y = size.height * BG.hash(i, 1101, 0.05, 0.9) + sin(t * 0.17 + CGFloat(i) * 1.7) * 22
            let p = CGPoint(x: x, y: y)
            let lit = frame.light(at: p)
            let alpha = Double(lit * lit) * (0.6 + 0.4 * Double(sin(t * BG.hash(i, 1102, 0.8, 2) + CGFloat(i))))
            guard alpha > 0.04 else { continue }
            ctx.fill(BG.circle(p, BG.hash(i, 1103, 0.7, 1.6)), with: .color(BG.rgb(1, 0.97, 0.85, 0.8 * alpha)))
        }
    }

    static func drawBokeh(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look, dark: Bool) {
        let colors = [BG.rgb(1, 0.9, 0.6), BG.rgb(0.7, 1, 0.7), BG.rgb(1, 0.8, 0.9)]
        ctx.blurredLayer(radius: 5) { bokeh in
            for i in 0..<16 {
                let x = BG.wrap(BG.hash(i, 121) * size.width + t * BG.hash(i, 122, -8, 8) + look.drift * 0.4, length: size.width, margin: 50)
                let y = size.height * BG.hash(i, 123) + sin(t * 0.2 + CGFloat(i)) * 30
                let r = BG.hash(i, 124, 14, 40)
                let p = CGPoint(x: x, y: y)
                let color = colors[i % colors.count]
                let pulse = Double(0.7 + 0.3 * sin(t * 0.5 + CGFloat(i)))
                if dark {
                    bokeh.fill(BG.circle(p, r), with: .radialGradient(
                        Gradient(stops: [
                            .init(color: color.opacity(0.14 * pulse), location: 0),
                            .init(color: color.opacity(0.12 * pulse), location: 0.7),
                            .init(color: color.opacity(0.24 * pulse), location: 0.88),
                            .init(color: color.opacity(0), location: 1)
                        ]),
                        center: p, startRadius: 0, endRadius: r
                    ))
                } else {
                    bokeh.stroke(BG.circle(p, r * 0.92), with: .color(BG.rgb(0.95, 0.75, 0.4, 0.18 * pulse)), lineWidth: 2)
                }
            }
        }
    }

    // MARK: Canopy and garden

    /// Leafy branches across the top-left corner, between the sun and the scene. They
    /// sway with the same signal that dapples the light.
    static func drawCanopy(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let sway = JuneLight.sway(t)
        var shade = Path()
        var lit = Path()
        var twigs = Path()
        let reach = min(size.width * 0.34, 480)
        for b in 0..<3 {
            let baseAngle = 0.2 + CGFloat(b) * 0.42
            let length = reach * BG.hash(b, 1110, 0.75, 1)
            let bend = sway * 0.04 * CGFloat(b + 1)
            let start = CGPoint(x: -10, y: -10)
            let end = CGPoint(x: start.x + cos(baseAngle + bend) * length, y: start.y + sin(baseAngle + bend) * length)
            let control = CGPoint(x: start.x + cos(baseAngle) * length * 0.5, y: start.y + sin(baseAngle) * length * 0.5 + 20)
            twigs.move(to: start)
            twigs.addQuadCurve(to: end, control: control)
            for j in 0..<22 {
                let seed = b * 100 + j
                let u = BG.hash(seed, 1111, 0.2, 1)
                let a = (1 - u) * (1 - u)
                let m = 2 * (1 - u) * u
                let c = u * u
                let p = CGPoint(x: a * start.x + m * control.x + c * end.x, y: a * start.y + m * control.y + c * end.y)
                let side: CGFloat = j % 2 == 0 ? 1 : -1
                let flutter = sin(t * BG.hash(seed, 1112, 1.5, 3) + CGFloat(j)) * 0.15 + sway * 0.2
                let angle = baseAngle + side * BG.hash(seed, 1113, 0.6, 1.3) + flutter
                let s = BG.hash(seed, 1114, 18, 30) * (1.1 - u * 0.3)
                let center = CGPoint(x: p.x + cos(angle) * s * 0.4, y: p.y + sin(angle) * s * 0.4)
                let transform = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: angle + CGFloat.pi / 2)
                    .scaledBy(x: s * 0.6, y: s)
                // A fixed share of leaves catch the sun on their edges.
                if BG.hash(seed, 1115) < 0.3 {
                    lit.addPath(LeafPainter.oval, transform: transform)
                } else {
                    shade.addPath(LeafPainter.oval, transform: transform)
                }
            }
        }
        ctx.stroke(twigs, with: .color(BG.rgb(0.2, 0.16, 0.1, 0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        ctx.fill(shade, with: .color(BG.rgb(0.12, 0.3, 0.12, 0.72)))
        ctx.fill(lit, with: .color(BG.rgb(0.55, 0.8, 0.3, 0.8)))
    }

    static let perches: [CGFloat] = [0.07, 0.93]

    /// Coneflowers that butterflies rest on, one near each bottom corner.
    static func perch(_ k: Int, size: CGSize, t: CGFloat) -> CGPoint {
        let x = size.width * perches[k] + sin(t * 0.6 + CGFloat(k)) * 3 + JuneLight.sway(t) * 2
        return CGPoint(x: x, y: size.height * 0.84)
    }

    /// A flower border along the bottom: grass, lavender, foxgloves and two coneflowers,
    /// with sunflecks sliding over it as the canopy moves.
    static func drawGarden(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, frame: JuneFrame, dark: Bool) {
        let ground = size.height
        let sway = JuneLight.sway(t)
        var blades = Path()
        let count = Int(size.width / 7)
        for i in 0..<count {
            let x = (CGFloat(i) + BG.hash(i, 1120)) / CGFloat(count) * (size.width + 20) - 10
            let edge = min(x, size.width - x) / size.width
            let h = size.height * BG.hash(i, 1121, 0.025, 0.05) * (edge < 0.18 ? 1.6 : 1)
            let bend = (0.2 + 0.25 * sway + 0.08 * sin(t * 1.4 + CGFloat(i))) * h * 0.4
            let w = BG.hash(i, 1122, 2.5, 5)
            blades.move(to: CGPoint(x: x - w / 2, y: ground))
            blades.addQuadCurve(to: CGPoint(x: x + bend, y: ground - h), control: CGPoint(x: x - w * 0.2 + bend * 0.3, y: ground - h * 0.55))
            blades.addQuadCurve(to: CGPoint(x: x + w / 2, y: ground), control: CGPoint(x: x + w * 0.3 + bend * 0.35, y: ground - h * 0.5))
            blades.closeSubpath()
        }
        ctx.fill(blades, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.55, 0.85, 0.4, 0.8), BG.rgb(0.15, 0.4, 0.15, 0.9)]),
            startPoint: CGPoint(x: 0, y: ground - size.height * 0.08),
            endPoint: CGPoint(x: 0, y: ground)
        ))

        // Lavender and foxglove spikes in the corners.
        var lavender = Path()
        var foxglove = Path()
        var stems = Path()
        for i in 0..<14 {
            let left = i < 7
            let u = BG.hash(i, 1123, 0.0, 0.16)
            let x = (left ? u : 1 - u) * size.width
            let h = size.height * BG.hash(i, 1124, 0.07, 0.14)
            let bend = sway * 6 + sin(t * 0.9 + CGFloat(i)) * 3
            let top = CGPoint(x: x + bend, y: ground - h)
            stems.move(to: CGPoint(x: x, y: ground))
            stems.addQuadCurve(to: top, control: CGPoint(x: x, y: ground - h * 0.5))
            let isFoxglove = i % 3 == 0
            for j in 0..<8 {
                let f = CGFloat(j) / 8
                let p = CGPoint(x: x + bend * (1 - f * 0.4) + (j % 2 == 0 ? 2.5 : -2.5), y: top.y + f * h * 0.45)
                if isFoxglove {
                    foxglove.addPath(BG.ellipse(p, 3.4, 4.5))
                } else {
                    lavender.addPath(BG.ellipse(p, 1.8, 2.6))
                }
            }
        }
        ctx.stroke(stems, with: .color(BG.rgb(0.2, 0.45, 0.2, 0.8)), lineWidth: 1.4)
        ctx.fill(lavender, with: .color(BG.rgb(0.6, 0.45, 0.85, 0.9)))
        ctx.fill(foxglove, with: .color(BG.rgb(0.92, 0.5, 0.75, 0.9)))

        // Coneflowers (the perches).
        for k in 0..<2 {
            let head = perch(k, size: size, t: t)
            var stem = Path()
            stem.move(to: CGPoint(x: size.width * perches[k], y: ground))
            stem.addQuadCurve(to: head, control: CGPoint(x: size.width * perches[k], y: (ground + head.y) / 2))
            ctx.stroke(stem, with: .color(BG.rgb(0.2, 0.45, 0.2, 0.9)), lineWidth: 2.2)
            var petals = Path()
            for j in 0..<12 {
                let a = CGFloat(j) / 12 * 2 * CGFloat.pi
                let p = CGPoint(x: head.x + cos(a) * 11, y: head.y + 3 + sin(a) * 4 + 4)
                petals.addPath(BG.ellipse(.zero, 3, 8).applying(CGAffineTransform(translationX: p.x, y: p.y).rotated(by: a + CGFloat.pi / 2)))
            }
            ctx.fill(petals, with: .color(BG.rgb(0.95, 0.5, 0.7, 0.92)))
            ctx.fill(BG.ellipse(head, 7, 5.5), with: .radialGradient(
                Gradient(colors: [BG.rgb(0.8, 0.45, 0.1), BG.rgb(0.4, 0.18, 0.05)]),
                center: CGPoint(x: head.x - 2, y: head.y - 2), startRadius: 0, endRadius: 8
            ))
        }

        // Sunflecks: soft bright patches where light gets through to the garden.
        var flecks = ctx
        if dark { flecks.blendMode = .plusLighter }
        flecks.blurredLayer(radius: 8) { patch in
            for i in 0..<12 {
                let x = size.width * (CGFloat(i) + 0.5) / 12 + sin(t * 0.13 + CGFloat(i)) * 20
                let p = CGPoint(x: x, y: ground - size.height * 0.03)
                let light = frame.light(at: p)
                guard light > 0.1 else { continue }
                patch.fill(BG.ellipse(p, 30 + 20 * light, 9), with: .color(BG.rgb(1, 0.95, 0.7, 0.35 * Double(light))))
            }
        }
    }

    // MARK: Butterflies

    static func flightPosition(k: Int, time t: CGFloat, size: CGSize, look: JuneModel.Look) -> CGPoint {
        let duration = BG.hash(k, 81, 38, 58)
        let progress = BG.fract(BG.hash(k, 82) + t / duration)
        let travel = k % 2 == 0 ? progress : 1 - progress
        let x = -120 + travel * (size.width + 240)
        // Keep most of them toward the top or bottom band, away from the middle.
        let band = k % 3 == 1 ? BG.hash(k, 83, 0.42, 0.55) : (k % 2 == 0 ? BG.hash(k, 83, 0.18, 0.32) : BG.hash(k, 83, 0.6, 0.72))
        let wave = sin(progress * 2 * CGFloat.pi * BG.hash(k, 84, 1.5, 3)) * size.height * 0.08
        let bob = sin(t * 2.7 + CGFloat(k)) * 10
        return CGPoint(x: x, y: size.height * band + wave + bob - sin(look.drift * 0.004 + CGFloat(k)) * 6)
    }

    /// Solstice gathering: a loose orbit inside the gathering beam.
    static func orbitPosition(k: Int, time t: CGFloat, size: CGSize, frame: JuneFrame) -> CGPoint {
        let best = frame.beams[gatherBeam]
        let reach = min(size.width, size.height) * 0.55
        let center = CGPoint(x: frame.origin.x + cos(best.angle) * reach, y: frame.origin.y + sin(best.angle) * reach)
        let radius = BG.hash(k, 1140, 120, 200)
        let angle = t * 0.35 + CGFloat(k) * 2 * CGFloat.pi / 5
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius * 0.55 + sin(t * 2.7 + CGFloat(k)) * 8)
    }

    static func position(k: Int, time t: CGFloat, size: CGSize, look: JuneModel.Look, frame: JuneFrame) -> CGPoint {
        let path = flightPosition(k: k, time: t, size: size, look: look)
        guard look.gather > 0.001 else { return path }
        let orbit = orbitPosition(k: k, time: t, size: size, frame: frame)
        let g = BG.easeInOut(look.gather)
        return CGPoint(x: BG.lerp(path.x, orbit.x, g), y: BG.lerp(path.y, orbit.y, g))
    }

    static func drawButterflies(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look, frame: JuneFrame) {
        for k in 0..<5 {
            let p = position(k: k, time: t, size: size, look: look, frame: frame)
            let ahead = position(k: k, time: t + 0.15, size: size, look: look, frame: frame)
            let heading = atan2(ahead.y - p.y, ahead.x - p.x)
            let wingspan = BG.hash(k, 85, 56, 96)
            let glide = BG.smoothstep(-0.3, 0.4, sin(t * 0.4 + CGFloat(k) * 2))
            // In the gathering they flap almost in sync.
            let phase = BG.lerp(CGFloat(k), 0, look.gather)
            let flap = sin(t * BG.hash(k, 86, 8, 11) + phase) * BG.lerp(0.25, 1, glide)
            let species = JuneArt.species[look.species[k] % JuneArt.species.count]
            drawButterfly(in: &ctx, at: p, wingspan: wingspan, open: 0.5 + 0.5 * flap, heading: heading, species: species)
        }
    }

    /// Now and then a pair of whites meet, spiral around each other for a few seconds,
    /// and part.
    static func drawCourting(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look) {
        let period: CGFloat = 70
        let position = t / period + 0.25
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        let life: CGFloat = 22
        guard age < life else { return }
        let rightward = BG.hash(cycle, 1150) < 0.5
        let y = size.height * BG.hash(cycle, 1151, 0.62, 0.74)
        func point(_ k: Int, _ dt: CGFloat) -> CGPoint {
            let uu = (age + dt) / life
            let xx = rightward ? -60 + uu * (size.width + 120) : size.width + 60 - uu * (size.width + 120)
            let spiral = BG.smoothstep(0.38, 0.45, uu) * (1 - BG.smoothstep(0.6, 0.67, uu))
            let sign: CGFloat = k == 0 ? 1 : -1
            let a = (t + dt) * 4 + (k == 0 ? 0 : CGFloat.pi)
            let apart = 40 * (1 - spiral)
            return CGPoint(
                x: xx + cos(a) * 18 * spiral + sign * apart * 0.6,
                y: y + sin(a) * 14 * spiral - 26 * spiral + sin((t + dt) * 2.6 + CGFloat(k)) * 8 + sign * apart * 0.2
            )
        }
        for k in 0..<2 {
            let p = point(k, 0)
            let ahead = point(k, 0.1)
            let heading = atan2(ahead.y - p.y, ahead.x - p.x)
            let flap = sin(t * 12 + CGFloat(k))
            drawButterfly(in: &ctx, at: p, wingspan: 40, open: 0.5 + 0.5 * flap, heading: heading, species: JuneArt.white)
        }
    }

    /// Every minute or so a butterfly flies down to a corner coneflower, rests with its
    /// wings slowly opening and closing, then flies on.
    static func drawResting(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JuneModel.Look) {
        let period: CGFloat = 60
        let position = t / period + 0.6
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        let rest = BG.hash(cycle, 1160, 6, 12)
        let fly: CGFloat = 4
        guard age < fly * 2 + rest else { return }
        let k = BG.hash(cycle, 1161) < 0.5 ? 0 : 1
        let flower = perch(k, size: size, t: t)
        let landing = CGPoint(x: flower.x, y: flower.y - 2)
        let outward: CGFloat = k == 0 ? -1 : 1
        let away = CGPoint(x: landing.x + outward * 60 - outward * 220, y: size.height * 0.55)
        let p: CGPoint
        let open: CGFloat
        let heading: CGFloat
        if age < fly {
            let u = BG.easeInOut(age / fly)
            p = CGPoint(x: BG.lerp(away.x, landing.x, u), y: BG.lerp(away.y, landing.y, u) - sin(u * CGFloat.pi) * 40)
            open = 0.5 + 0.5 * sin(t * 10)
            heading = atan2(landing.y - away.y, landing.x - away.x)
        } else if age < fly + rest {
            p = landing
            open = 0.55 + 0.45 * sin((age - fly) * 1.2)
            heading = -CGFloat.pi / 2
        } else {
            let u = BG.easeInOut((age - fly - rest) / fly)
            let exit = CGPoint(x: landing.x + outward * 200, y: size.height * 0.5)
            p = CGPoint(x: BG.lerp(landing.x, exit.x, u), y: BG.lerp(landing.y, exit.y, u) - sin(u * CGFloat.pi) * 30)
            open = 0.5 + 0.5 * sin(t * 10)
            heading = atan2(exit.y - landing.y, exit.x - landing.x)
        }
        let fade = Double(BG.smoothstep(0, 0.8, age) * (1 - BG.smoothstep(fly * 2 + rest - 0.8, fly * 2 + rest, age)))
        var layer = ctx
        layer.opacity = fade
        let species = JuneArt.species[Int(BG.hash(cycle, 1162) * 5) % 5]
        drawButterfly(in: &layer, at: p, wingspan: 52, open: open, heading: heading, species: species)
    }

    static func drawButterfly(in ctx: inout GraphicsContext, at p: CGPoint, wingspan: CGFloat, open: CGFloat, heading: CGFloat, species: JuneSpecies) {
        // Soft shadow on the scene below.
        let shadowCenter = CGPoint(x: p.x + wingspan * 0.15, y: p.y + wingspan * 0.9)
        let shadowWidth = wingspan * (0.18 + 0.32 * open)
        ctx.fill(
            BG.ellipse(shadowCenter, shadowWidth, wingspan * 0.08),
            with: .radialGradient(Gradient(colors: [.black.opacity(0.16), .black.opacity(0)]), center: shadowCenter, startRadius: 0, endRadius: shadowWidth)
        )

        var body = ctx
        body.translateBy(x: p.x, y: p.y)
        body.rotate(by: .radians(Double(heading + CGFloat.pi / 2)))
        body.scaleBy(x: wingspan, y: wingspan)

        let gradient = Gradient(stops: [
            .init(color: species.border, location: 0),
            .init(color: species.base, location: 0.18),
            .init(color: species.bright, location: 0.55),
            .init(color: species.base, location: 0.78),
            .init(color: species.border, location: 0.9)
        ])
        let root = CGPoint(x: 0.03, y: 0)
        for side in [-1.0, 1.0] as [CGFloat] {
            var wing = body
            // Foreshortening as the wing rises, with a slight skew near closed.
            wing.scaleBy(x: side * (0.1 + 0.9 * open), y: 1)
            wing.fill(JuneArt.hindwing, with: .radialGradient(gradient, center: root, startRadius: 0, endRadius: 0.5))
            wing.fill(JuneArt.forewing, with: .radialGradient(gradient, center: root, startRadius: 0, endRadius: 0.56))
            if species.iridescent {
                // Thin-film shimmer: the hue sweeps cyan to blue to violet as the wing tilts,
                // with a moving specular band.
                let tilt = Double(open)
                let film = BG.rgb(0.3 + 0.5 * (1 - tilt), 0.9 - 0.6 * (1 - tilt), 1)
                let shift = (open - 0.5) * 0.4
                var sheen = wing
                sheen.blendMode = .plusLighter
                sheen.fill(
                    JuneArt.forewing,
                    with: .linearGradient(
                        Gradient(colors: [film.opacity(0), film.opacity(0.45), .white.opacity(0.35), film.opacity(0)]),
                        startPoint: CGPoint(x: 0.05 + shift, y: -0.45),
                        endPoint: CGPoint(x: 0.45 + shift, y: 0.05)
                    )
                )
                sheen.fill(JuneArt.hindwing, with: .radialGradient(
                    Gradient(colors: [film.opacity(0.3), film.opacity(0)]),
                    center: CGPoint(x: 0.2 + shift * 0.5, y: 0.2), startRadius: 0, endRadius: 0.3
                ))
            }
            wing.stroke(JuneArt.veins, with: .color(species.border.opacity(0.45)), lineWidth: 0.01)
            wing.stroke(JuneArt.forewing, with: .color(species.border.opacity(0.8)), lineWidth: 0.012)
            wing.stroke(JuneArt.hindwing, with: .color(species.border.opacity(0.8)), lineWidth: 0.012)
            wing.fill(JuneArt.marginSpots, with: .color(species.spots.opacity(0.9)))
            if species.eyespot {
                let eye = CGPoint(x: 0.22, y: 0.25)
                wing.fill(BG.circle(eye, 0.06), with: .color(species.spots))
                wing.fill(BG.circle(eye, 0.042), with: .color(.black))
                wing.fill(BG.circle(eye, 0.022), with: .color(BG.rgb(0.3, 0.55, 1)))
                wing.fill(BG.circle(CGPoint(x: eye.x - 0.012, y: eye.y - 0.012), 0.008), with: .color(.white))
            }
        }

        // Fuzzy thorax, segmented abdomen, head and clubbed antennae.
        body.fill(BG.ellipse(CGPoint(x: 0, y: -0.1), 0.04, 0.08), with: .radialGradient(
            Gradient(colors: [BG.rgb(0.45, 0.38, 0.32), BG.rgb(0.1, 0.08, 0.08)]),
            center: CGPoint(x: -0.01, y: -0.12), startRadius: 0, endRadius: 0.09
        ))
        let abdomen = Path(roundedRect: CGRect(x: -0.026, y: -0.04, width: 0.052, height: 0.29), cornerRadius: 0.026)
        body.fill(abdomen, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.35, 0.3, 0.28), BG.rgb(0.06, 0.05, 0.05)]),
            startPoint: CGPoint(x: -0.03, y: 0),
            endPoint: CGPoint(x: 0.03, y: 0)
        ))
        body.stroke(JuneArt.abdomenRings, with: .color(BG.rgb(0.6, 0.55, 0.5, 0.4)), lineWidth: 0.008)
        body.fill(BG.circle(CGPoint(x: 0, y: -0.2), 0.036), with: .color(BG.rgb(0.1, 0.08, 0.08)))
        body.stroke(JuneArt.antennae, with: .color(BG.rgb(0.1, 0.08, 0.08)), lineWidth: 0.012)
        body.fill(BG.circle(CGPoint(x: -0.11, y: -0.4), 0.014), with: .color(BG.rgb(0.1, 0.08, 0.08)))
        body.fill(BG.circle(CGPoint(x: 0.11, y: -0.4), 0.014), with: .color(BG.rgb(0.1, 0.08, 0.08)))
    }
}
