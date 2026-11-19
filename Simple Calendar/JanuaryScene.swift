//
//  JanuaryScene.swift
//  Simple Calendar
//
//  January: a hushed winter afternoon seen through a frosted window.
//
//  Snow squalls are the star. One squall signal drives the scene, and it travels: a
//  point on the screen feels each squall `x / 220` seconds after the left edge, so
//  bands of heavier snow visibly sweep across. Inside a band the snow thickens, the
//  far hills white out, the pines lean, chimney smoke bends flat, spindrift streams
//  off the crest of the drift and loaded branches shed their snow.
//
//  The scene also follows the selected day:
//    * weather      - flurries / steady / heavy snow (hash of the date)
//    * daylight     - short days tint the air a deeper blue, longer days paler
//    * crystal habit- dendrites, plates or needles (hash), applied to new flakes only
//    * New Year's   - a one-shot glitter snow when Jan 1 is selected
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct JanuarySnowAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = JanuaryModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = JanuaryModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            JanuaryScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class JanuaryModel {
    struct Target {
        /// Flurries 0.5 / steady 1 / heavy 1.8.
        let density: Double
        /// Base wind in points per second.
        let windBase: Double
        /// Gust share: how hard squalls blow.
        let gust: Double
        /// 1 on heavy-snow days (haze, near bokeh, no sun dogs).
        let heavy: Double
        /// 0 pale (longer day) ... 1 deep blue (shortest days).
        let shortDay: Double
        /// 0 dendrites, 1 plates, 2 needles.
        let habit: Int
        let newYear: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            let weather = day.roll(101)
            if weather < 0.4 {
                density = 0.5; windBase = 2; gust = 0.3; heavy = 0
            } else if weather < 0.85 {
                density = 1; windBase = 6; gust = 0.3; heavy = 0
            } else {
                density = 1.8; windBase = 25; gust = 0.7; heavy = 1
            }
            shortDay = 1 - min(max((day.daylightHours - 9.2) / 1.1, 0), 1)
            let shape = day.roll(102)
            habit = shape < 0.6 ? 0 : (shape < 0.85 ? 1 : 2)
            newYear = day.month == 1 && day.day == 1 ? 1 : 0
        }
    }

    struct Look {
        var density: CGFloat
        var gust: CGFloat
        var heavy: CGFloat
        var shortDay: CGFloat
        /// Wind displacement accumulated since the scene appeared.
        var drift: CGFloat
        /// Current wind speed (points per second).
        var wind: CGFloat
        /// Flakes that formed before `habitChangedAt` keep `habitOld`.
        var habitOld: Int
        var habitNew: Int
        var habitChangedAt: CGFloat
        /// 0...1 New Year's glitter, and seconds into it.
        var glitter: CGFloat
        var glitterAge: CGFloat
    }

    private let densityTransition = SceneTransition()
    private let windTransition = SceneTransition()
    private let gustTransition = SceneTransition()
    private let heavyTransition = SceneTransition()
    private let daylightTransition = SceneTransition()
    private let habitTransition = SceneTransition()
    private let newYearTransition = SceneTransition()
    private let newYearMoment = SceneMoment(duration: 9)
    private var drift: CGFloat = 0
    private var lastTime: Double?
    private var habitOld = -1
    private var habitNew = -1
    private var habitChangedAt: Double = -1_000_000

    func look(target: Target, time: Double) -> Look {
        let density = densityTransition.value(target: target.density, time: time)
        let windBase = windTransition.value(target: target.windBase, time: time)
        let gust = gustTransition.value(target: target.gust, time: time)
        let heavy = heavyTransition.value(target: target.heavy, time: time)
        let short = daylightTransition.value(target: target.shortDay, time: time)

        // Crystal habit: switch only once its transition has fully settled.
        let habit = habitTransition.value(target: Double(target.habit), time: time)
        let settled = Int(habit.rounded())
        if habitNew < 0 {
            habitOld = settled
            habitNew = settled
        } else if abs(habit - Double(settled)) < 0.0001, settled != habitNew {
            habitOld = habitNew
            habitNew = settled
            habitChangedAt = time
        }

        // Integrate the wind so drift stays continuous whatever the weather does.
        let wind = CGFloat(windBase) + 60 * CGFloat(gust) * JanuarySquall.strength(CGFloat(time))
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * wind
        }
        lastTime = time

        let newYear = newYearTransition.value(target: target.newYear, time: time)
        var glitter: CGFloat = 0
        var glitterAge: CGFloat = 0
        if let age = newYearMoment.elapsed(arrived: newYear > 0.999, time: time) {
            glitterAge = CGFloat(age)
            glitter = BG.smoothstep(0, 0.8, glitterAge) * (1 - BG.smoothstep(6, 9, glitterAge)) * CGFloat(newYear)
        }

        return Look(
            density: CGFloat(density),
            gust: CGFloat(gust),
            heavy: CGFloat(heavy),
            shortDay: CGFloat(short),
            drift: drift,
            wind: wind,
            habitOld: habitOld,
            habitNew: habitNew,
            habitChangedAt: CGFloat(habitChangedAt),
            glitter: glitter,
            glitterAge: glitterAge
        )
    }
}

// MARK: - Squalls

/// One slow weather signal for the whole scene, built from incommensurate sines
/// (periods of roughly 17 to 90 s) so squalls never settle into a visible loop.
private enum JanuarySquall {
    static func signal(_ t: CGFloat) -> CGFloat {
        0.4 * sin(t * 0.071) + 0.3 * sin(t * 0.113 + 1.7) + 0.2 * sin(t * 0.191 + 4.2) + 0.1 * sin(t * 0.37 + 0.9)
    }

    /// 0...1: calm most of the time, with squalls that build and pass.
    static func strength(_ t: CGFloat) -> CGFloat { BG.smoothstep(0.05, 0.65, signal(t)) }

    /// Squalls sweep left to right: a point at `x` feels each one `x / 220` seconds late.
    static func strength(at x: CGFloat, _ t: CGFloat) -> CGFloat { strength(t - x / 220) }
}

// MARK: - Art

private enum JanuaryArt {
    /// Hexagonal plate crystal (radius 1).
    static let plate: Path = {
        var path = Path()
        for ring in [1.0, 0.55] as [CGFloat] {
            for k in 0...6 {
                let a = CGFloat(k) / 6 * 2 * CGFloat.pi
                let p = CGPoint(x: cos(a) * ring, y: sin(a) * ring)
                if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
        }
        for k in 0..<6 {
            let a = CGFloat(k) / 6 * 2 * CGFloat.pi
            path.move(to: CGPoint(x: cos(a) * 0.55, y: sin(a) * 0.55))
            path.addLine(to: CGPoint(x: cos(a), y: sin(a)))
        }
        return path
    }()

    /// Needle crystal (length 2, along x).
    static let needle: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -1, y: 0))
        path.addLine(to: CGPoint(x: 1, y: 0))
        for x in [-0.7, 0.7] as [CGFloat] {
            path.move(to: CGPoint(x: x, y: -0.12))
            path.addLine(to: CGPoint(x: x, y: 0.12))
        }
        return path
    }()

    static func crystal(habit: Int, variant: Int) -> Path {
        switch habit {
        case 1: return plate
        case 2: return needle
        default: return SnowRenderer.crystals[variant % SnowRenderer.crystals.count]
        }
    }

    /// Frost feathers growing out of a corner (unit reach, corner at the origin, growing
    /// toward +x/+y).
    static let frost: Path = {
        var path = Path()
        func frond(from p: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, seed: Int) {
            let end = CGPoint(x: p.x + cos(angle) * length, y: p.y + sin(angle) * length)
            path.move(to: p)
            path.addLine(to: end)
            guard depth < 2 else { return }
            let sides = 4
            for j in 1...sides {
                let u = CGFloat(j) / CGFloat(sides + 1)
                let q = CGPoint(x: p.x + cos(angle) * length * u, y: p.y + sin(angle) * length * u)
                let branch = length * 0.36 * (1 - u * 0.55) * BG.hash(seed * 7 + j, 501, 0.75, 1.15)
                frond(from: q, angle: angle - CGFloat.pi / 3, length: branch, depth: depth + 1, seed: seed * 7 + j)
                frond(from: q, angle: angle + CGFloat.pi / 3, length: branch * BG.hash(seed * 7 + j, 502, 0.7, 1), depth: depth + 1, seed: seed * 7 + j + 3)
            }
        }
        let fronds: [(angle: CGFloat, length: CGFloat)] = [(0.2, 1), (0.78, 0.72), (1.36, 0.92)]
        for (k, f) in fronds.enumerated() {
            frond(from: .zero, angle: f.angle, length: f.length, depth: 0, seed: k + 1)
        }
        return path
    }()

    /// Snow-laden pine, height 1 with its base at the origin.
    static let pineBody: Path = {
        var path = Path()
        for tier in pineTiers {
            path.move(to: CGPoint(x: 0, y: tier.top))
            path.addQuadCurve(to: CGPoint(x: -tier.half, y: tier.bottom), control: CGPoint(x: -tier.half * 0.3, y: (tier.top + tier.bottom) / 2))
            path.addLine(to: CGPoint(x: tier.half, y: tier.bottom))
            path.addQuadCurve(to: CGPoint(x: 0, y: tier.top), control: CGPoint(x: tier.half * 0.3, y: (tier.top + tier.bottom) / 2))
            path.closeSubpath()
        }
        path.addRect(CGRect(x: -0.04, y: -0.07, width: 0.08, height: 0.08))
        return path
    }()

    static let pineSnow: Path = {
        var path = Path()
        for tier in pineTiers {
            let h = tier.bottom - tier.top
            path.move(to: CGPoint(x: 0, y: tier.top))
            path.addQuadCurve(to: CGPoint(x: -tier.half * 0.42, y: tier.top + h * 0.42), control: CGPoint(x: -tier.half * 0.12, y: tier.top + h * 0.2))
            path.addQuadCurve(to: CGPoint(x: tier.half * 0.38, y: tier.top + h * 0.36), control: CGPoint(x: 0, y: tier.top + h * 0.3))
            path.closeSubpath()
            path.move(to: CGPoint(x: -tier.half * 1.02, y: tier.bottom))
            path.addQuadCurve(to: CGPoint(x: tier.half * 1.02, y: tier.bottom), control: CGPoint(x: 0, y: tier.bottom - h * 0.22))
            path.addQuadCurve(to: CGPoint(x: -tier.half * 1.02, y: tier.bottom), control: CGPoint(x: 0, y: tier.bottom - h * 0.05))
            path.closeSubpath()
        }
        return path
    }()

    static let pineTiers: [(top: CGFloat, bottom: CGFloat, half: CGFloat)] = [
        (-1.0, -0.6, 0.18), (-0.78, -0.34, 0.28), (-0.54, -0.06, 0.38)
    ]

    /// Small cabin, width 1 with its base at the origin.
    static let cabin: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.4, y: -0.5, width: 0.8, height: 0.5))
        path.move(to: CGPoint(x: -0.52, y: -0.48))
        path.addLine(to: CGPoint(x: 0, y: -0.92))
        path.addLine(to: CGPoint(x: 0.52, y: -0.48))
        path.closeSubpath()
        path.addRect(CGRect(x: 0.2, y: -0.95, width: 0.1, height: 0.3))
        return path
    }()

    static let cabinSnow: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.56, y: -0.46))
        path.addLine(to: CGPoint(x: 0, y: -0.97))
        path.addLine(to: CGPoint(x: 0.56, y: -0.46))
        path.addLine(to: CGPoint(x: 0.5, y: -0.43))
        path.addLine(to: CGPoint(x: 0, y: -0.88))
        path.addLine(to: CGPoint(x: -0.5, y: -0.43))
        path.closeSubpath()
        return path
    }()

    static let cabinWindows: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.27, y: -0.36, width: 0.15, height: 0.15))
        path.addRect(CGRect(x: 0.08, y: -0.36, width: 0.15, height: 0.15))
        return path
    }()
}

// MARK: - Scene

private enum JanuaryScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: JanuaryModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let sun = CGPoint(x: size.width * 0.1, y: size.height * 0.035)

        drawSky(in: &ctx, size: size, t: t, look: look, sun: sun)
        drawSunDogs(in: &ctx, size: size, t: t, look: look, sun: sun)
        drawFarHills(in: &ctx, size: size, t: t, look: look)
        drawWhiteout(in: &ctx, size: size, t: t, look: look, row: 0)
        drawMidPines(in: &ctx, size: size, t: t, look: look)
        drawSnowDump(in: &ctx, size: size, t: t, look: look)

        drawFarSnow(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawCrystals(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawWhiteout(in: &ctx, size: size, t: t, look: look, row: 1)

        drawDrift(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawHare(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawSpindrift(in: &ctx, size: size, t: t, look: look, dark: dark)

        drawGlitterCascade(in: &ctx, size: size, look: look)
        drawBokeh(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawFrost(in: &ctx, size: size, t: t, dark: dark)
    }

    /// How many of a layer's particles are showing, 0...1, for a particle at `x`.
    /// Squalls thicken the snow locally as they pass.
    static func coverage(look: JanuaryModel.Look, x: CGFloat, t: CGFloat) -> CGFloat {
        let local = look.density * (1 + 0.45 * JanuarySquall.strength(at: x, t))
        return local / 2.6
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, sun: CGPoint) {
        let s = Double(look.shortDay)
        let heavy = Double(look.heavy)
        let squall = Double(JanuarySquall.strength(t - size.width / 440))
        // Deep blue on short days, paler as the days lengthen.
        let r = 0.84 - 0.22 * s, g = 0.91 - 0.18 * s, b = 1 - 0.08 * s
        let sky = Gradient(stops: [
            .init(color: BG.rgb(r * 0.85, g * 0.88, b, 0.3 + 0.1 * heavy), location: 0),
            .init(color: BG.rgb(r, g, b, 0.14), location: 0.5),
            .init(color: BG.rgb(0.92, 0.95, 1, 0.1 + 0.08 * squall), location: 0.85)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(r, g, b), intensity: 0.22 * (1 + 0.3 * heavy) + 0.08 * squall, depth: 0.45)

        // A pale, low winter sun behind the haze (the key light).
        let veil = 1 - 0.6 * heavy - 0.4 * squall
        ctx.glow(at: sun, radius: size.width * 0.32, color: BG.rgb(1, 0.95, 0.85), intensity: 0.22 * veil)
        ctx.glow(at: sun, radius: 70, color: BG.rgb(1, 0.97, 0.9), intensity: 0.5 * veil)
        ctx.fill(BG.circle(sun, 26), with: .color(BG.rgb(1, 0.99, 0.95, 0.55 * veil)))
    }

    /// Two faint prismatic sun dogs about 22 degrees either side of the sun, and a whisper
    /// of the halo that joins them. Clear-ish days only.
    static func drawSunDogs(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, sun: CGPoint) {
        let clarity = (1 - look.heavy) * (1 - JanuarySquall.strength(t)) * (0.85 + 0.15 * sin(t * 0.05))
        guard clarity > 0.02 else { return }
        let reach = min(size.width * 0.17, 260)
        let alpha = Double(clarity)
        ctx.stroke(
            BG.circle(sun, reach),
            with: .radialGradient(
                Gradient(colors: [BG.rgb(1, 0.6, 0.45, 0), BG.rgb(1, 0.85, 0.7, 0.06 * alpha), BG.rgb(0.75, 0.85, 1, 0.04 * alpha), BG.rgb(0.75, 0.85, 1, 0)]),
                center: sun, startRadius: reach - 8, endRadius: reach + 8
            ),
            lineWidth: 10
        )
        for side in [-1.0, 1.0] as [CGFloat] {
            let p = CGPoint(x: sun.x + side * reach, y: sun.y + 6)
            // Red inner edge (toward the sun), fading through gold to a blue-white tail.
            let inner = CGPoint(x: p.x - side * 10, y: p.y)
            ctx.fill(
                BG.ellipse(p, 16, 30),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: BG.rgb(1, 0.4, 0.3, 0.15 * alpha), location: 0),
                        .init(color: BG.rgb(1, 0.85, 0.5, 0.13 * alpha), location: 0.35),
                        .init(color: BG.rgb(0.7, 0.85, 1, 0.08 * alpha), location: 0.7),
                        .init(color: BG.rgb(0.7, 0.85, 1, 0), location: 1)
                    ]),
                    center: inner, startRadius: 0, endRadius: 34
                )
            )
        }
    }

    // MARK: Land

    static func ridgeY(_ x: CGFloat, size: CGSize, layer: Int) -> CGFloat {
        let u = x / max(size.width, 1)
        let l = CGFloat(layer)
        let base = size.height * (layer == 0 ? 0.84 : 0.9)
        return base + size.height * (0.02 * sin(u * 3.6 + l * 2.2) + 0.01 * sin(u * 9.5 + l * 4.1))
    }

    static func ridgePath(size: CGSize, layer: Int) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            path.addLine(to: CGPoint(x: x, y: ridgeY(x, size: size, layer: layer)))
            x += 20
        }
        path.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        path.closeSubpath()
        return path
    }

    /// Far snowy hills with a line of small pines and a cabin with a lit window, its
    /// chimney smoke bent by the wind.
    static func drawFarHills(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look) {
        let top = size.height * 0.8
        ctx.fill(
            ridgePath(size: size, layer: 0),
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.93, 0.96, 1, 0.42), BG.rgb(0.72, 0.8, 0.93, 0.36)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        var bodies = Path()
        var caps = Path()
        for i in 0..<22 {
            let x = (CGFloat(i) + BG.hash(i, 510, 0.1, 0.9)) / 22 * size.width
            guard abs(x / size.width - 0.86) > 0.035 else { continue } // leave room for the cabin
            let h = BG.hash(i, 511, 18, 34)
            let base = ridgeY(x, size: size, layer: 0) + 4
            let transform = CGAffineTransform(translationX: x, y: base).scaledBy(x: h * 0.8, y: h)
            bodies.addPath(JanuaryArt.pineBody, transform: transform)
            caps.addPath(JanuaryArt.pineSnow, transform: transform)
        }
        ctx.fill(bodies, with: .color(BG.rgb(0.2, 0.3, 0.36, 0.38)))
        ctx.fill(caps, with: .color(BG.rgb(0.95, 0.97, 1, 0.5)))

        // Cabin.
        let cabinX = size.width * 0.86
        let cabinBase = ridgeY(cabinX, size: size, layer: 0) + 3
        let w: CGFloat = 30
        let cabin = CGAffineTransform(translationX: cabinX, y: cabinBase).scaledBy(x: w, y: w)
        let warm = 0.85 + 0.15 * sin(t * 1.7) * sin(t * 0.63 + 1)
        ctx.fill(JanuaryArt.cabin.applying(cabin), with: .color(BG.rgb(0.28, 0.24, 0.26, 0.55)))
        ctx.fill(JanuaryArt.cabinSnow.applying(cabin), with: .color(BG.rgb(0.97, 0.98, 1, 0.75)))
        ctx.fill(JanuaryArt.cabinWindows.applying(cabin), with: .color(BG.rgb(1, 0.8, 0.45, Double(0.9 * warm))))
        ctx.glow(at: CGPoint(x: cabinX, y: cabinBase - w * 0.3), radius: w * 1.4, color: BG.rgb(1, 0.75, 0.4), intensity: Double(0.35 * warm))

        // Chimney smoke, laid flat by the wind.
        let chimney = CGPoint(x: cabinX + w * 0.25, y: cabinBase - w * 0.95)
        let lean = min(look.wind / 40, 1.4)
        ctx.blurredLayer(radius: 5) { smoke in
            for k in 0..<9 {
                let f = BG.fract(BG.hash(k, 515) + t * 0.07)
                let rise = f * 70 * (1 - 0.5 * lean)
                let carry = f * f * 150 * lean + f * 12
                let c = CGPoint(x: chimney.x + carry + sin(t * 0.6 + CGFloat(k)) * 4 * f, y: chimney.y - rise)
                let alpha = Double((1 - f) * BG.smoothstep(0, 0.08, f)) * 0.28
                smoke.fill(BG.circle(c, 4 + 16 * f), with: .color(BG.rgb(0.85, 0.87, 0.92, alpha)))
            }
        }
    }

    /// Larger pines at the edges of a nearer ridge, leaning as squalls pass.
    static func drawMidPines(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look) {
        let top = size.height * 0.87
        ctx.fill(
            ridgePath(size: size, layer: 1),
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.97, 0.98, 1, 0.5), BG.rgb(0.78, 0.85, 0.96, 0.45)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        var bodies = Path()
        var caps = Path()
        for i in 0..<pineCount {
            let p = pine(i, size: size, t: t, look: look)
            let transform = CGAffineTransform(translationX: p.base.x, y: p.base.y)
                .rotated(by: p.lean)
                .scaledBy(x: p.height * 0.75, y: p.height)
            bodies.addPath(JanuaryArt.pineBody, transform: transform)
            caps.addPath(JanuaryArt.pineSnow, transform: transform)
        }
        ctx.fill(bodies, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.16, 0.3, 0.28, 0.6), BG.rgb(0.08, 0.17, 0.17, 0.66)]),
            startPoint: CGPoint(x: 0, y: size.height * 0.7),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        ctx.fill(caps, with: .color(BG.rgb(0.97, 0.98, 1, 0.82)))
    }

    static let pineCount = 8

    /// Mid pine `i`: four at each edge.
    static func pine(_ i: Int, size: CGSize, t: CGFloat, look: JanuaryModel.Look) -> (base: CGPoint, height: CGFloat, lean: CGFloat) {
        let left = i < pineCount / 2
        let slot = CGFloat(i % (pineCount / 2))
        let u = (slot + BG.hash(i, 520, 0.15, 0.85)) / CGFloat(pineCount / 2) * 0.17
        let x = (left ? u : 1 - u) * size.width
        let height = size.height * BG.hash(i, 521, 0.09, 0.15)
        let squall = JanuarySquall.strength(at: x, t)
        let lean = sin(t * 0.6 + CGFloat(i) * 1.3) * 0.008 + squall * look.gust * 0.09 * (1 + 0.25 * sin(t * 2.3 + CGFloat(i)))
        return (CGPoint(x: x, y: ridgeY(x, size: size, layer: 1) + 5), height, lean)
    }

    /// Now and then a loaded pine sheds a clump of snow, more often in squalls.
    static func drawSnowDump(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look) {
        let period: CGFloat = 19
        let position = t / period + 0.4
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        guard age < 4, BG.hash(cycle, 525) < 0.6 else { return }
        let index = Int(BG.hash(cycle, 526) * CGFloat(pineCount)) % pineCount
        let tree = pine(index, size: size, t: t - age, look: look)
        let tier = BG.hash(cycle, 527) < 0.5 ? 1 : 2
        let ledge = JanuaryArt.pineTiers[tier]
        let side: CGFloat = BG.hash(cycle, 528) < 0.5 ? -1 : 1
        let origin = CGPoint(x: tree.base.x + side * ledge.half * tree.height * 0.6, y: tree.base.y + ledge.bottom * tree.height)
        let fade = 1 - BG.smoothstep(2.5, 4, age)
        let ground = ridgeY(origin.x, size: size, layer: 1) + 6

        ctx.blurredLayer(radius: 4) { puff in
            let c = CGPoint(x: origin.x + side * age * 8, y: min(origin.y + 60 * age * age, ground))
            puff.fill(BG.circle(c, 6 + 10 * age), with: .color(.white.opacity(Double(0.35 * fade))))
        }
        var clumps = Path()
        for k in 0..<12 {
            let vx = BG.hash(k, 529, 4, 26) * side + look.wind * 0.3
            let delay = BG.hash(k, 530, 0, 0.25)
            let a = max(0, age - delay)
            let p = CGPoint(x: origin.x + vx * a, y: min(origin.y + 70 * a * a, ground))
            clumps.addPath(BG.circle(p, BG.hash(k, 531, 1, 2.6)))
        }
        ctx.fill(clumps, with: .color(.white.opacity(Double(0.85 * fade))))
    }

    /// A whiteout veil that rides the squall across the screen: a row of soft blobs whose
    /// strength follows the squall at each blob, so the band travels smoothly.
    static func drawWhiteout(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, row: Int) {
        let y = size.height * (row == 0 ? 0.83 : 0.12)
        let maxAlpha: Double = row == 0 ? 0.32 : 0.12
        let count = 10
        let spacing = size.width / CGFloat(count - 1)
        for i in 0..<count {
            let x = CGFloat(i) * spacing
            let s = Double(JanuarySquall.strength(at: x, t) * (0.6 + 0.4 * look.gust / 0.7))
            guard s > 0.02 else { continue }
            let c = CGPoint(x: x, y: y)
            let rx = spacing * 1.1
            ctx.fill(
                BG.ellipse(c, rx, size.height * 0.12),
                with: .radialGradient(
                    Gradient(colors: [BG.rgb(0.95, 0.97, 1, maxAlpha * s), BG.rgb(0.95, 0.97, 1, 0)]),
                    center: c, startRadius: 0, endRadius: rx
                )
            )
        }
    }

    // MARK: Snow

    /// Fine distant snow, batched into three paths by brightness. Particles fade in and
    /// out by shrinking, so density changes never pop.
    static func drawFarSnow(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        var bands = [Path(), Path(), Path()]
        let span = size.height + 40
        for i in 0..<300 {
            let speed = BG.hash(i, 11, 22, 42)
            let progress = BG.fract(BG.hash(i, 12) + t * speed / span)
            let y = progress * span - 20
            let sway = sin(t * BG.hash(i, 13, 0.4, 0.9) + BG.hash(i, 14) * 6.28) * 14
            let x = BG.wrap(BG.hash(i, 15) * size.width + sway + look.drift * 0.45, length: size.width, margin: 20)
            let visible = BG.clamp01((coverage(look: look, x: x, t: t) - BG.hash(i, 160)) / 0.06)
            guard visible > 0.02 else { continue }
            let radius = BG.hash(i, 16, 0.9, 2.1) * visible
            bands[i % 3].addPath(BG.circle(CGPoint(x: x, y: y), radius))
        }
        let alphas: [Double] = [0.38, 0.52, 0.68]
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.8, y: 0.8)
            for band in bands {
                shadow.fill(band, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45)))
            }
        }
        for (k, band) in bands.enumerated() {
            ctx.fill(band, with: .color(.white.opacity(alphas[k])))
        }
    }

    /// Mid-distance crystals that turn slowly and flash as a face catches the light.
    /// All crystals are stroked as one path, with one blurred halo pass.
    static func drawCrystals(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        var white = Path()
        var gold = Path()
        var glints: [(CGPoint, CGFloat, Bool)] = []
        let span = size.height + 80
        for i in 0..<110 {
            let seed = i + 1000
            let speed = BG.hash(seed, 11, 40, 66)
            let fallen = BG.hash(seed, 12) + t * speed / span
            let progress = BG.fract(fallen)
            let y = progress * span - 40
            let sway = sin(t * BG.hash(seed, 13, 0.3, 0.7) + BG.hash(seed, 14) * 6.28) * 32
            let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 0.75, length: size.width, margin: 40)
            // Mid crystals stay sparser in the middle of the screen than at its edges.
            let edge = min(abs(x / size.width - 0.5), abs(y / size.height - 0.5)) * 2
            let thin = BG.lerp(0.6, 1, BG.smoothstep(0.2, 0.7, edge))
            let visible = BG.clamp01((coverage(look: look, x: x, t: t) * thin - BG.hash(seed, 160)) / 0.06)
            guard visible > 0.02 else { continue }

            // Flakes that formed before the last habit change keep the old habit.
            let born = (floor(fallen) - BG.hash(seed, 12)) * span / speed
            let habit = born < look.habitChangedAt ? look.habitOld : look.habitNew
            let radius = BG.hash(seed, 16, 5, 11) * visible * (habit == 2 ? 0.9 : 1)
            let spin = t * BG.hash(seed, 18, -0.6, 0.6) + BG.hash(seed, 19) * 6.28
            let transform = CGAffineTransform(translationX: x, y: y).rotated(by: spin).scaledBy(x: radius, y: radius)
            let isGold = look.glitter > 0.01 && BG.hash(seed, 170) < 0.25
            if isGold {
                gold.addPath(JanuaryArt.crystal(habit: habit, variant: i), transform: transform)
            } else {
                white.addPath(JanuaryArt.crystal(habit: habit, variant: i), transform: transform)
            }
            // A face turning toward the low sun flashes briefly.
            let flash = pow(max(0, cos(spin * 3 + 0.8)), 24)
            if flash > 0.35, glints.count < 8 {
                glints.append((CGPoint(x: x, y: y), radius * CGFloat(flash), isGold))
            }
        }

        let stroke = StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.9, y: 0.9)
            shadow.stroke(white, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45)), style: stroke)
            shadow.stroke(gold, with: .color(BG.rgb(0.6, 0.45, 0.2, 0.45)), style: stroke)
        }
        ctx.blurredLayer(radius: 3) { halo in
            halo.stroke(white, with: .color(.white.opacity(0.45)), lineWidth: 3)
            halo.stroke(gold, with: .color(BG.rgb(1, 0.85, 0.54, 0.6 * Double(look.glitter))), lineWidth: 3.4)
        }
        ctx.stroke(white, with: .color(.white.opacity(0.9)), style: stroke)
        let g = Double(look.glitter)
        ctx.stroke(gold, with: .color(.white.opacity(0.9 * (1 - g))), style: stroke)
        ctx.stroke(gold, with: .color(BG.rgb(1, 0.85, 0.54, 0.95 * g)), style: stroke)

        for (p, r, isGold) in glints {
            let color = isGold ? BG.rgb(1, 0.9, 0.6) : BG.rgb(0.95, 0.98, 1)
            ctx.sparkle(at: p, size: r * 1.2 + 3, color: color, intensity: 0.85)
        }
    }

    /// Big, soft out-of-focus flakes drifting past the "camera", with a brighter rim
    /// like real lens bokeh.
    static func drawBokeh(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        let amount = 0.2 + 0.2 * look.density + 0.35 * look.heavy
        let tint = dark ? BG.rgb(1, 1, 1) : BG.rgb(0.69, 0.77, 0.9)
        let strength: Double = dark ? 0.42 : 0.2
        let span = size.height + 200
        ctx.blurredLayer(radius: 7) { near in
            for i in 0..<16 {
                let seed = i + 2000
                let visible = BG.clamp01((amount - BG.hash(seed, 160)) / 0.08)
                guard visible > 0.02 else { continue }
                let speed = BG.hash(seed, 11, 85, 130)
                let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
                let y = progress * span - 100
                let sway = sin(t * BG.hash(seed, 13, 0.2, 0.5) + BG.hash(seed, 14) * 6.28) * 60
                let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 1.3, length: size.width, margin: 100)
                let radius = BG.hash(seed, 16, 18, 42)
                // Big flakes ease off over the centre of the grid.
                let cx = 1 - BG.clamp01(abs(x / size.width - 0.5) / 0.25)
                let cy = 1 - BG.clamp01(abs(y / size.height - 0.5) / 0.25)
                let center = radius > 30 ? BG.lerp(1, 0.5, BG.smoothstep(0, 0.5, min(cx, cy))) : 1
                let alpha = strength * Double(visible * center)
                let p = CGPoint(x: x, y: y)
                near.fill(
                    BG.circle(p, radius),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: tint.opacity(alpha * 0.7), location: 0),
                            .init(color: tint.opacity(alpha * 0.6), location: 0.6),
                            .init(color: tint.opacity(alpha), location: 0.86),
                            .init(color: tint.opacity(0), location: 1)
                        ]),
                        center: p, startRadius: 0, endRadius: radius
                    )
                )
            }
        }
    }

    /// New Year's Day: a slow cascade of gold sparkles from the top of the screen.
    static func drawGlitterCascade(in ctx: inout GraphicsContext, size: CGSize, look: JanuaryModel.Look) {
        guard look.glitter > 0.01 else { return }
        let age = look.glitterAge
        for k in 0..<26 {
            let start = BG.hash(k, 540, 0, 3)
            let a = age - start
            guard a > 0 else { continue }
            let x = BG.hash(k, 541) * size.width + sin(a * 1.3 + CGFloat(k)) * 18
            let y = -10 + a * BG.hash(k, 542, 45, 80)
            let twinkle = 0.5 + 0.5 * sin(a * 6 + CGFloat(k))
            ctx.sparkle(at: CGPoint(x: x, y: y), size: BG.hash(k, 543, 4, 8), color: BG.rgb(1, 0.85, 0.54), intensity: Double(look.glitter * twinkle))
        }
    }

    // MARK: Drift

    /// The drift builds by up to a quarter over its first half hour on screen, then holds.
    static func driftHeight(size: CGSize, t: CGFloat) -> CGFloat {
        size.height * 0.045 * (1 + 0.25 * BG.easeInOut(min(t / 1800, 1)))
    }

    static func driftSurface(_ x: CGFloat, size: CGSize, height: CGFloat, layer: CGFloat) -> CGFloat {
        let u = x / max(size.width, 1)
        let wave = sin(u * 9 + layer * 2) * 0.35 + sin(u * 23 + layer * 5) * 0.15 + sin(u * 4.3 + layer) * 0.5
        return size.height - height * (0.75 + 0.35 * wave) * (1 - layer * 0.35)
    }

    static func drawDrift(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        let height = driftHeight(size: size, t: t)
        let h = size.height
        for layer in [0, 1] as [CGFloat] {
            var bank = Path()
            var crest = Path()
            bank.move(to: CGPoint(x: 0, y: h))
            var x: CGFloat = 0
            while x <= size.width + 12 {
                let p = CGPoint(x: x, y: driftSurface(x, size: size, height: height, layer: layer))
                bank.addLine(to: p)
                if x == 0 { crest.move(to: p) } else { crest.addLine(to: p) }
                x += 12
            }
            bank.addLine(to: CGPoint(x: size.width + 12, y: h))
            bank.closeSubpath()
            let top = h - height * 1.5
            let trough = layer == 0 ? BG.rgb(0.74, 0.82, 0.95) : BG.rgb(0.86, 0.91, 0.99)
            let deep = dark ? trough : BG.rgb(0.62, 0.72, 0.9)
            ctx.fill(
                bank,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 1, 1, 0.92), deep.opacity(0.88)]),
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            // Crisp, sunlit rim along the crest.
            ctx.stroke(crest, with: .color(.white.opacity(dark ? 0.9 : 0.6)), lineWidth: 1.2)
            if !dark {
                var under = ctx
                under.translateBy(x: 0, y: 2)
                under.stroke(crest, with: .color(BG.rgb(0.55, 0.66, 0.84, 0.35)), lineWidth: 1.4)
            }
        }
        // Glints where low sun catches ice crystals on the surface.
        for i in 0..<36 {
            let x = BG.hash(i, 501) * size.width
            let y = driftSurface(x, size: size, height: height, layer: 1) + BG.hash(i, 502, 4, height * 0.6)
            let pulse = pow(max(0, sin(t * BG.hash(i, 503, 0.8, 1.8) + BG.hash(i, 504) * 6.28)), 12)
            guard pulse > 0.02 else { continue }
            ctx.sparkle(at: CGPoint(x: x, y: y), size: 6, color: dark ? .white : BG.rgb(0.55, 0.7, 0.95), intensity: Double(pulse) * 0.9)
        }
    }

    /// Spindrift: fine snow lifting off the crest and streaming downwind as a squall passes.
    static func drawSpindrift(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        let height = driftHeight(size: size, t: t)
        let color = dark ? Color.white : BG.rgb(0.6, 0.7, 0.88)
        for i in 0..<48 {
            let x0 = BG.hash(i, 545) * size.width
            let s = JanuarySquall.strength(at: x0, t) * BG.clamp01(look.gust / 0.5)
            let lift = BG.smoothstep(0.45, 0.9, s)
            guard lift > 0.02 else { continue }
            let age = BG.fract(BG.hash(i, 546) + t / BG.hash(i, 547, 1.2, 2.6))
            let crest = driftSurface(x0, size: size, height: height, layer: 0)
            let p = CGPoint(
                x: x0 + age * (40 + look.wind * 2.2),
                y: crest - age * BG.hash(i, 548, 6, 22) + sin(age * 9 + CGFloat(i)) * 2
            )
            let alpha = Double(lift * (1 - age) * BG.smoothstep(0, 0.1, age)) * 0.75
            ctx.fill(BG.circle(p, BG.hash(i, 549, 0.8, 1.7)), with: .color(color.opacity(alpha)))
        }
    }

    /// A snowshoe hare hops across the drift every couple of minutes, leaving prints that
    /// slowly fill back in.
    static func drawHare(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JanuaryModel.Look, dark: Bool) {
        let period: CGFloat = 110
        let position = t / period + 0.7
        let cycle = Int(floor(position))
        let elapsed = BG.fract(position) * period
        let crossing: CGFloat = 16
        let hops = 26
        let rightward = BG.hash(cycle, 550) < 0.5
        let travel = size.width + 80
        let hopLength = travel / CGFloat(hops)
        let height = driftHeight(size: size, t: t)
        func xAt(_ distance: CGFloat) -> CGFloat {
            rightward ? -40 + distance : size.width + 40 - distance
        }

        // Prints: one pair per landing so far, fading over about 25 s.
        let progress = min(elapsed / crossing, 1)
        let landed = Int(floor(progress * CGFloat(hops)))
        if landed > 0 {
            var prints = Path()
            for k in 0..<landed {
                let landTime = CGFloat(k + 1) / CGFloat(hops) * crossing
                guard elapsed - landTime < 25 else { continue }
                let x = xAt(CGFloat(k + 1) * hopLength)
                let y = driftSurface(x, size: size, height: height, layer: 1) + 5
                prints.addPath(BG.ellipse(CGPoint(x: x - 3, y: y), 2.4, 1.1))
                prints.addPath(BG.ellipse(CGPoint(x: x + 3, y: y + 1), 2.4, 1.1))
            }
            let fade = 1 - BG.smoothstep(crossing, crossing + 25, elapsed)
            ctx.fill(prints, with: .color(BG.rgb(0.5, 0.62, 0.82, 0.35 * Double(fade))))
        }

        guard elapsed < crossing else { return }
        let phase = progress * CGFloat(hops)
        let hop = floor(phase)
        let f = phase - hop
        let airborne = f < 0.55
        let g = airborne ? f / 0.55 : 1
        let distance = (hop + g) * hopLength
        let x = xAt(distance)
        let surface = driftSurface(x, size: size, height: height, layer: 1)
        let jump = airborne ? sin(g * .pi) * 14 : 0
        let p = CGPoint(x: x, y: surface - 5 - jump)
        ctx.fill(BG.ellipse(CGPoint(x: x, y: surface + 3), 9 * (1 - jump / 30), 1.6), with: .color(BG.rgb(0.45, 0.55, 0.75, 0.25)))

        var hare = ctx
        hare.translateBy(x: p.x, y: p.y)
        hare.scaleBy(x: rightward ? 18 : -18, y: 18)
        hare.rotate(by: .radians(airborne ? Double(cos(g * .pi) * -0.25) : 0))
        let fur = dark ? BG.rgb(0.98, 0.98, 1) : BG.rgb(0.92, 0.94, 0.98)
        let shade = BG.rgb(0.68, 0.75, 0.88)
        let stretch: CGFloat = airborne ? 1.15 : 1
        hare.fill(
            BG.ellipse(CGPoint(x: 0, y: 0.08), 0.48 * stretch, 0.3 / stretch),
            with: .linearGradient(Gradient(colors: [fur, shade]), startPoint: CGPoint(x: 0, y: -0.2), endPoint: CGPoint(x: 0, y: 0.4))
        )
        hare.fill(BG.circle(CGPoint(x: 0.42, y: -0.14), 0.19), with: .color(fur))
        var ears = Path()
        ears.addPath(BG.ellipse(.zero, 0.06, 0.22).applying(CGAffineTransform(translationX: 0.33, y: -0.4).rotated(by: -0.5)))
        ears.addPath(BG.ellipse(.zero, 0.06, 0.22).applying(CGAffineTransform(translationX: 0.43, y: -0.38).rotated(by: -0.35)))
        hare.fill(ears, with: .color(fur))
        hare.fill(BG.circle(CGPoint(x: 0.5, y: -0.17), 0.035), with: .color(BG.rgb(0.1, 0.1, 0.15)))
        hare.stroke(BG.ellipse(CGPoint(x: 0, y: 0.08), 0.48 * stretch, 0.3 / stretch), with: .color(shade.opacity(dark ? 0.3 : 0.7)), lineWidth: 0.04)
    }

    // MARK: Window

    /// Frost feathers growing in from the corners of the window, breathing slowly.
    static func drawFrost(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, dark: Bool) {
        let reach = size.width * 0.14 * (0.95 + 0.05 * sin(t * 2 * CGFloat.pi / 40))
        let corners: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 1, 1), (size.width, 0, -1, 1), (0, size.height, 1, -1), (size.width, size.height, -1, -1)
        ]
        var frost = Path()
        let haze = dark ? BG.rgb(0.91, 0.95, 1) : BG.rgb(0.62, 0.72, 0.86)
        for (ox, oy, mx, my) in corners {
            frost.addPath(JanuaryArt.frost, transform: CGAffineTransform(a: reach * mx, b: 0, c: 0, d: reach * my, tx: ox, ty: oy))
            let c = CGPoint(x: ox, y: oy)
            ctx.fill(
                BG.circle(c, reach * 0.8),
                with: .radialGradient(Gradient(colors: [haze.opacity(0.16), haze.opacity(0)]), center: c, startRadius: 0, endRadius: reach * 0.8)
            )
        }
        ctx.stroke(frost, with: .color(haze.opacity(dark ? 0.35 : 0.3)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }
}
