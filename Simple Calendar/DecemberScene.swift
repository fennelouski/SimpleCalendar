//
//  DecemberScene.swift
//  Simple Calendar
//
//  December: a strand of old C9 bulbs over a snowy village at night.
//
//  The bulbs are the key light: every lit bulb is a small colored lamp that tints the
//  snowflakes and icicle drips near it and warms the wash along the top. A breeze is
//  the motion: it travels along the strand (each swag feels a gust `x / 300` s after
//  the left end), so the swags swing in sequence, the bulbs swing after them like
//  pendulums, the snow drifts with it, gusts knock clumps of snow off the cord, and
//  the village chimney smoke leans the same way.
//
//  The scene also follows the selected day:
//    * advent      - bulbs light up day by day (all lit from the 24th), each new one
//                    flickering on within the transition; one bulb stays dead until
//                    Christmas Eve
//    * solstice    - the sky deepens toward dusk blue around the 21st
//    * Christmas   - Dec 24-25: warm white breathing bulbs, a star, slow big flakes,
//                    and now and then a sleigh crossing the sky
//    * New Year's Eve - a one-shot countdown along the strand and a sparkle burst,
//                    then a gold-and-white chase
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct DecemberChristmasLightsAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = DecemberModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = DecemberModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            DecemberScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - State

final class DecemberModel {
    struct Target {
        /// Advent: how many of the 28 bulbs are lit.
        let lit: Double
        /// 1 on the winter solstice, fading over the days around it.
        let solstice: Double
        let christmas: Double
        let newYearsEve: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            let d = day.month == 12 ? day.day : 24
            lit = (Double(DecemberScene.bulbCount) * Double(min(d, 24)) / 24).rounded()
            let solsticeDay = Calendar(identifier: .gregorian).component(.day, from: SceneDay.season(3, year: day.year))
            solstice = max(0, 1 - Double(abs(d - solsticeDay)) / 4)
            christmas = d == 24 || d == 25 ? 1 : 0
            newYearsEve = d == 31 ? 1 : 0
        }
    }

    struct Look {
        var lit: CGFloat
        var solstice: CGFloat
        var christmas: CGFloat
        var newYearsEve: CGFloat
        /// Snow drift accumulated since the scene appeared.
        var drift: CGFloat
        /// Seconds into the New Year's Eve countdown, or -1.
        var countdown: CGFloat
    }

    static let countdownDuration: Double = 17

    private let litTransition = SceneTransition()
    private let solsticeTransition = SceneTransition()
    private let christmasTransition = SceneTransition()
    private let eveTransition = SceneTransition()
    private let countdown = SceneMoment(duration: DecemberModel.countdownDuration)
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let lit = litTransition.value(target: target.lit, time: time)
        let solstice = solsticeTransition.value(target: target.solstice, time: time)
        let christmas = christmasTransition.value(target: target.christmas, time: time)
        let eve = eveTransition.value(target: target.newYearsEve, time: time)
        var age: CGFloat = -1
        if let elapsed = countdown.elapsed(arrived: eve > 0.999, time: time) {
            age = CGFloat(elapsed)
        }
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * DecemberBreeze.speed(CGFloat(time))
        }
        lastTime = time
        return Look(
            lit: CGFloat(lit),
            solstice: CGFloat(solstice),
            christmas: CGFloat(christmas),
            newYearsEve: CGFloat(eve),
            drift: drift,
            countdown: age
        )
    }
}

// MARK: - Breeze

private enum DecemberBreeze {
    /// -1...1.5 wind felt at `x`: gusts travel left to right along the strand.
    static func wind(at x: CGFloat, _ t: CGFloat) -> CGFloat {
        let s = t - x / 300
        return 0.6 * sin(0.35 * s) + 0.25 * sin(0.9 * s + 1) + 0.7 * gust(s)
    }

    /// 0...1 occasional stronger gusts (periods of about 22 and 48 s).
    static func gust(_ s: CGFloat) -> CGFloat {
        BG.smoothstep(0.45, 0.95, 0.6 * sin(s * 0.13) + 0.4 * sin(s * 0.29 + 2))
    }

    /// Sideways snow speed in points per second.
    static func speed(_ t: CGFloat) -> CGFloat { 6 + 12 * wind(at: 0, t) }
}

// MARK: - Bulbs

private struct DecemberHue {
    var r: Double, g: Double, b: Double

    func mix(_ o: DecemberHue, _ a: Double) -> DecemberHue {
        DecemberHue(r: r + (o.r - r) * a, g: g + (o.g - g) * a, b: b + (o.b - b) * a)
    }

    var color: Color { BG.rgb(r, g, b) }
}

/// One bulb this frame.
private struct DecemberBulb {
    var socket: CGPoint
    var swing: Double
    var glow: CGPoint
    var hue: DecemberHue
    /// Pattern brightness (chase, twinkle, breathing).
    var brightness: CGFloat
    /// 0 unlit glass ... 1 lit.
    var on: CGFloat

    var light: CGFloat { brightness * on }
}

private struct DecemberSwag {
    var p0: CGPoint
    var control: CGPoint
    var p2: CGPoint

    func point(_ u: CGFloat) -> CGPoint {
        let a = (1 - u) * (1 - u)
        let b = 2 * (1 - u) * u
        let c = u * u
        return CGPoint(x: a * p0.x + b * control.x + c * p2.x, y: a * p0.y + b * control.y + c * p2.y)
    }
}

// MARK: - Art

private enum DecemberArt {
    static let hues: [DecemberHue] = [
        DecemberHue(r: 1, g: 0.16, b: 0.14),
        DecemberHue(r: 0.12, g: 0.88, b: 0.35),
        DecemberHue(r: 0.2, g: 0.45, b: 1),
        DecemberHue(r: 1, g: 0.72, b: 0.15),
        DecemberHue(r: 0.95, g: 0.3, b: 0.82)
    ]
    static let warmWhite = DecemberHue(r: 1, g: 0.89, b: 0.7)
    static let gold = DecemberHue(r: 1, g: 0.78, b: 0.32)
    static let white = DecemberHue(r: 1, g: 0.97, b: 0.92)

    /// Unit C9 bulb glass (socket at the origin, hanging toward +y).
    static let glass: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 1))
        path.addCurve(to: CGPoint(x: 0.2, y: 0.44), control1: CGPoint(x: 0.1, y: 0.9), control2: CGPoint(x: 0.22, y: 0.62))
        path.addCurve(to: CGPoint(x: 0, y: 0.26), control1: CGPoint(x: 0.18, y: 0.3), control2: CGPoint(x: 0.08, y: 0.26))
        path.addCurve(to: CGPoint(x: -0.2, y: 0.44), control1: CGPoint(x: -0.08, y: 0.26), control2: CGPoint(x: -0.18, y: 0.3))
        path.addCurve(to: CGPoint(x: 0, y: 1), control1: CGPoint(x: -0.22, y: 0.62), control2: CGPoint(x: -0.1, y: 0.9))
        path.closeSubpath()
        return path
    }()

    static let socket = Path(roundedRect: CGRect(x: -0.12, y: -0.02, width: 0.24, height: 0.32), cornerRadius: 0.05)

    static let ribs: Path = {
        var path = Path()
        for y in [0.06, 0.13, 0.2] as [CGFloat] {
            path.move(to: CGPoint(x: -0.11, y: y))
            path.addLine(to: CGPoint(x: 0.11, y: y))
        }
        return path
    }()

    /// Advent order: `ranks[i]` is when bulb `i` lights (a fixed shuffle).
    static let ranks: [Int] = {
        let order = (0..<DecemberScene.bulbCount).sorted { BG.hash($0, 720) < BG.hash($1, 720) }
        var ranks = [Int](repeating: 0, count: DecemberScene.bulbCount)
        for (position, index) in order.enumerated() { ranks[index] = position }
        return ranks
    }()

    /// The one bulb that stays out all month until Christmas Eve (lit early in advent,
    /// so its gap shows).
    static let deadBulb: Int = (0..<DecemberScene.bulbCount).sorted { BG.hash($0, 720) < BG.hash($1, 720) }[2]

    /// Evergreen, height 1 with its base at the origin.
    static let tree: Path = {
        var path = Path()
        let tiers: [(top: CGFloat, bottom: CGFloat, half: CGFloat)] = [
            (-1.0, -0.66, 0.16), (-0.82, -0.44, 0.25), (-0.62, -0.2, 0.34), (-0.4, -0.04, 0.42)
        ]
        for tier in tiers {
            path.move(to: CGPoint(x: 0, y: tier.top))
            path.addQuadCurve(to: CGPoint(x: -tier.half, y: tier.bottom), control: CGPoint(x: -tier.half * 0.3, y: (tier.top + tier.bottom) / 2))
            path.addQuadCurve(to: CGPoint(x: tier.half, y: tier.bottom), control: CGPoint(x: 0, y: tier.bottom - 0.05))
            path.addQuadCurve(to: CGPoint(x: 0, y: tier.top), control: CGPoint(x: tier.half * 0.3, y: (tier.top + tier.bottom) / 2))
            path.closeSubpath()
        }
        path.addRect(CGRect(x: -0.04, y: -0.05, width: 0.08, height: 0.06))
        return path
    }()

    /// Where the little lights sit on the tree (unit space), wound in a spiral.
    static let treeLights: [CGPoint] = (0..<26).map { (i: Int) -> CGPoint in
        let u = (CGFloat(i) + 0.5) / 26
        let y = -0.94 + 0.86 * u
        let half = 0.08 + 0.32 * u
        return CGPoint(x: sin(CGFloat(i) * 2.1) * half * 0.85, y: y)
    }

    /// Sleigh and reindeer silhouette (facing +x, about 1 unit long).
    static let sleigh: Path = {
        var path = Path()
        // Sleigh body and runner.
        path.move(to: CGPoint(x: -0.5, y: -0.06))
        path.addLine(to: CGPoint(x: -0.48, y: 0.06))
        path.addLine(to: CGPoint(x: -0.26, y: 0.06))
        path.addQuadCurve(to: CGPoint(x: -0.22, y: -0.04), control: CGPoint(x: -0.2, y: 0.04))
        path.addLine(to: CGPoint(x: -0.36, y: -0.02))
        path.addLine(to: CGPoint(x: -0.4, y: -0.1))
        path.closeSubpath()
        path.move(to: CGPoint(x: -0.52, y: 0.1))
        path.addLine(to: CGPoint(x: -0.2, y: 0.1))
        path.addQuadCurve(to: CGPoint(x: -0.17, y: 0.04), control: CGPoint(x: -0.15, y: 0.1))
        path.addLine(to: CGPoint(x: -0.18, y: 0.05))
        path.addQuadCurve(to: CGPoint(x: -0.2, y: 0.08), control: CGPoint(x: -0.18, y: 0.08))
        path.addLine(to: CGPoint(x: -0.52, y: 0.08))
        path.closeSubpath()
        // Reindeer.
        for k in 0..<3 {
            let x = -0.08 + CGFloat(k) * 0.2
            path.addEllipse(in: CGRect(x: x - 0.07, y: -0.03, width: 0.14, height: 0.06))
            path.move(to: CGPoint(x: x + 0.05, y: -0.02))
            path.addLine(to: CGPoint(x: x + 0.09, y: -0.08))
            path.addLine(to: CGPoint(x: x + 0.11, y: -0.07))
            path.addLine(to: CGPoint(x: x + 0.07, y: -0.01))
            path.closeSubpath()
        }
        return path
    }()
}

// MARK: - Scene

private enum DecemberScene {
    static let bulbCount = 28
    static let hooks = 4
    static let bulbsPerSwag = 7
    static let bulbLength: CGFloat = 36

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: DecemberModel.Look, dark: Bool) {
        let t = CGFloat(time)
        let swags = makeSwags(size: size, t: t)
        let bulbs = makeBulbs(swags: swags, t: t, look: look)

        drawSky(in: &ctx, size: size, look: look, bulbs: bulbs, dark: dark)
        drawSleigh(in: &ctx, size: size, t: t, look: look)
        drawFarHills(in: &ctx, size: size, t: t)
        drawFarSnow(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawVillage(in: &ctx, size: size, t: t, dark: dark)
        drawTree(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawCrystals(in: &ctx, size: size, t: t, look: look, bulbs: bulbs, dark: dark)
        drawSlowFlakes(in: &ctx, size: size, t: t, look: look, dark: dark)
        drawStar(in: &ctx, size: size, t: t, look: look)

        drawCord(in: &ctx, size: size, t: t, swags: swags, bulbs: bulbs, dark: dark)
        for bulb in bulbs {
            drawBulb(in: &ctx, bulb: bulb, t: t, dark: dark)
        }
        drawClump(in: &ctx, size: size, t: t, swags: swags)
        drawBurst(in: &ctx, size: size, look: look, bulbs: bulbs)
        drawBokeh(in: &ctx, size: size, t: t, look: look, bulbs: bulbs, dark: dark)
    }

    // MARK: Strand

    static func makeSwags(size: CGSize, t: CGFloat) -> [DecemberSwag] {
        var swags: [DecemberSwag] = []
        swags.reserveCapacity(hooks)
        for k in 0..<hooks {
            let p0 = CGPoint(x: size.width * CGFloat(k) / CGFloat(hooks), y: -4)
            let p2 = CGPoint(x: size.width * CGFloat(k + 1) / CGFloat(hooks), y: -4)
            let wind = DecemberBreeze.wind(at: (p0.x + p2.x) / 2, t)
            let sag = size.height * 0.075 * (1 + 0.12 * sin(t * 0.5 + CGFloat(k))) + abs(wind) * 4
            let control = CGPoint(x: (p0.x + p2.x) / 2 + wind * 22, y: p0.y + sag * 2)
            swags.append(DecemberSwag(p0: p0, control: control, p2: p2))
        }
        return swags
    }

    static func makeBulbs(swags: [DecemberSwag], t: CGFloat, look: DecemberModel.Look) -> [DecemberBulb] {
        var bulbs: [DecemberBulb] = []
        bulbs.reserveCapacity(bulbCount)
        let warm = Double(look.christmas)
        let eve = Double(look.newYearsEve)

        // New Year's Eve countdown: dark, then ten groups light one per second, then a flash.
        let age = look.countdown
        let counting = age >= 0

        // Old-filament buzz: now and then one bulb flickers for half a second.
        let buzzPeriod: CGFloat = 13
        let buzzCycle = Int(floor(t / buzzPeriod))
        let buzzAge = BG.fract(t / buzzPeriod) * buzzPeriod
        let buzzing = BG.hash(buzzCycle, 740) < 0.7 && buzzAge < BG.hash(buzzCycle, 741, 0.3, 0.6)
        let buzzBulb = Int(BG.hash(buzzCycle, 742) * CGFloat(bulbCount)) % bulbCount

        for (k, swag) in swags.enumerated() {
            for i in 0..<bulbsPerSwag {
                let index = k * bulbsPerSwag + i
                let u = (CGFloat(i) + 0.5) / CGFloat(bulbsPerSwag)
                let socket = swag.point(u)
                // Bulbs swing after the cord, like pendulums.
                let lagged = DecemberBreeze.wind(at: socket.x, t - 0.5)
                let swing = Double(sin(t * 1.3 + CGFloat(index)) * 0.08 - lagged * 0.15)
                let glow = CGPoint(x: socket.x - CGFloat(sin(swing)) * bulbLength * 0.6, y: socket.y + CGFloat(cos(swing)) * bulbLength * 0.6)

                // Color: the strand's colors, warm white at Christmas, gold and white on NYE.
                var hue = DecemberArt.hues[index % DecemberArt.hues.count]
                hue = hue.mix(DecemberArt.warmWhite, warm)
                hue = hue.mix(index % 2 == 0 ? DecemberArt.gold : DecemberArt.white, eve)

                // Pattern: a chase running along the strand, or slow breathing at Christmas.
                let chase = 0.5 + 0.5 * sin(t * 2.2 - CGFloat(index) * 0.55)
                let twinkle = pow(max(0, sin(t * BG.hash(index, 201, 1.5, 3.5) + BG.hash(index, 202) * 6.28)), 6)
                let pattern = BG.clamp01(0.3 + 0.5 * chase + 0.3 * twinkle)
                let breathe = 0.72 + 0.28 * sin(t * 0.8 + CGFloat(index) * 0.22)
                var brightness = BG.lerp(pattern, breathe, CGFloat(warm))

                // Advent: lit by rank; a bulb crossing its threshold flickers as it warms.
                let advent = BG.clamp01(look.lit - CGFloat(DecemberArt.ranks[index]))
                var on = advent
                if advent > 0.001 && advent < 0.999 {
                    on = BG.hash(index * 97 + Int(t * 18), 743) < advent ? 1 : 0.12
                }
                if index == DecemberArt.deadBulb {
                    on *= look.christmas
                }
                if buzzing && index == buzzBulb && on > 0.5 {
                    on *= BG.hash(Int(t * 30), 744) < 0.55 ? 1 : 0.25
                }
                if counting {
                    let group = CGFloat(index * 10 / bulbCount)
                    let countdownOn: CGFloat
                    if age < 1 {
                        countdownOn = 1 - BG.smoothstep(0, 1, age)
                    } else if age < 11 {
                        countdownOn = BG.smoothstep(1 + group, 1.2 + group, age)
                    } else {
                        countdownOn = 1
                    }
                    on = countdownOn
                    let flash = age >= 11 ? max(0, 1 - (age - 11) / 1.2) : 0
                    brightness = min(1, brightness + flash)
                }
                bulbs.append(DecemberBulb(socket: socket, swing: swing, glow: glow, hue: hue, brightness: brightness, on: on))
            }
        }
        return bulbs
    }

    /// Snow builds up on the strand over its first ten minutes on screen.
    static func capAmount(_ t: CGFloat) -> CGFloat { BG.smoothstep(0, 600, t) }

    static func drawCord(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, swags: [DecemberSwag], bulbs: [DecemberBulb], dark: Bool) {
        var cord = Path()
        for swag in swags {
            cord.move(to: swag.p0)
            cord.addQuadCurve(to: swag.p2, control: swag.control)
        }
        let cap = capAmount(t)
        if cap > 0.02 {
            var snow = ctx
            snow.translateBy(x: 0, y: -1.8)
            snow.stroke(cord, with: .color(.white.opacity(Double(0.9 * cap))), style: StrokeStyle(lineWidth: 1 + 2.6 * cap, lineCap: .round))
        }
        // Twisted two-wire cord with a helical highlight.
        ctx.stroke(cord, with: .color(BG.rgb(0.04, 0.2, 0.08)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        var highlight = ctx
        highlight.translateBy(x: 0, y: -0.8)
        highlight.stroke(cord, with: .color(BG.rgb(0.4, 0.65, 0.4, 0.55)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 3]))

        drawIcicles(in: &ctx, size: size, t: t, swags: swags, bulbs: bulbs, dark: dark)
    }

    /// Icicles slowly forming at the low points of each swag, each dripping now and
    /// then; the drop catches the color of the nearest bulb.
    static func drawIcicles(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, swags: [DecemberSwag], bulbs: [DecemberBulb], dark: Bool) {
        let grow = BG.smoothstep(0, 900, t)
        guard grow > 0.02 else { return }
        var ice = Path()
        for (k, swag) in swags.enumerated() {
            for (j, u) in ([0.43, 0.57, 0.29] as [CGFloat]).enumerated() {
                let seed = k * 3 + j
                let top = swag.point(u)
                let length = BG.hash(seed, 750, 8, 16) * grow
                ice.move(to: CGPoint(x: top.x - 1.6, y: top.y + 1))
                ice.addLine(to: CGPoint(x: top.x, y: top.y + 1 + length))
                ice.addLine(to: CGPoint(x: top.x + 1.6, y: top.y + 1))
                ice.closeSubpath()

                // Drip: a drop swells at the tip, then falls.
                let period = BG.hash(seed, 751, 3, 6)
                let phase = BG.fract(t / period + BG.hash(seed, 752))
                let tip = CGPoint(x: top.x, y: top.y + 1 + length)
                let nearest = bulbs[min(max(k * bulbsPerSwag + Int(u * CGFloat(bulbsPerSwag)), 0), bulbs.count - 1)]
                let tint = nearest.hue.mix(DecemberHue(r: 1, g: 1, b: 1), 0.4).color
                if phase < 0.7 {
                    let r = 0.4 + 1.2 * phase / 0.7
                    ctx.fill(BG.circle(CGPoint(x: tip.x, y: tip.y + r * 0.6), r * grow), with: .color(tint.opacity(0.75)))
                } else {
                    let a = (phase - 0.7) * period
                    let p = CGPoint(x: tip.x, y: tip.y + 1.5 + 420 * a * a)
                    let fade = Double(1 - BG.smoothstep(0.75, 1, phase))
                    ctx.fill(BG.ellipse(p, 1.1, 2), with: .color(tint.opacity(0.85 * fade)))
                    if dark {
                        ctx.glow(at: p, radius: 6, color: tint, intensity: 0.4 * fade * Double(nearest.light), additive: true)
                    }
                }
            }
        }
        ctx.fill(ice, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.92, 0.96, 1, 0.85), BG.rgb(0.75, 0.86, 1, 0.5)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height * 0.12)
        ))
    }

    static func drawBulb(in ctx: inout GraphicsContext, bulb: DecemberBulb, t: CGFloat, dark: Bool) {
        let light = Double(bulb.light)
        let color = bulb.hue.color
        let length = bulbLength
        if light > 0.01 {
            if dark {
                ctx.glow(at: bulb.glow, radius: length * 2.1, color: color, intensity: 0.5 * light)
                ctx.glow(at: bulb.glow, radius: length * 0.8, color: color, intensity: 0.45 * light, additive: true)
            } else {
                // Light theme: soft tinted pools instead of additive glow.
                ctx.glow(at: bulb.glow, radius: length * 1.7, color: color, intensity: 0.3 * light)
            }
        }

        var b = ctx
        b.translateBy(x: bulb.socket.x, y: bulb.socket.y)
        b.rotate(by: .radians(bulb.swing))
        b.scaleBy(x: length, y: length)

        b.fill(
            DecemberArt.socket,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.05, 0.25, 0.1), BG.rgb(0.35, 0.65, 0.4), BG.rgb(0.04, 0.2, 0.08)]),
                startPoint: CGPoint(x: -0.12, y: 0),
                endPoint: CGPoint(x: 0.12, y: 0)
            )
        )
        b.stroke(DecemberArt.ribs, with: .color(BG.rgb(0.02, 0.12, 0.05, 0.6)), lineWidth: 0.018)

        // Glass: hot filament core fading through the bulb's color to a deeper rim.
        let deep = bulb.hue.mix(DecemberHue(r: 0, g: 0, b: 0), 0.35).color
        b.fill(
            DecemberArt.glass,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color.white.opacity(0.15 + 0.85 * light), location: 0),
                    .init(color: color, location: 0.45),
                    .init(color: deep, location: 1)
                ]),
                center: CGPoint(x: -0.04, y: 0.58),
                startRadius: 0,
                endRadius: 0.42
            )
        )
        // Unlit glass stays tinted (darker color plus a cool reflection), never black.
        b.fill(DecemberArt.glass, with: .color(.black.opacity((1 - light) * (dark ? 0.45 : 0.22))))
        if light < 0.6 {
            b.fill(BG.ellipse(CGPoint(x: 0.08, y: 0.62), 0.04, 0.14), with: .color(BG.rgb(0.8, 0.9, 1, 0.3 * (1 - light))))
        }
        // Fresnel edge and the specular streak.
        b.stroke(DecemberArt.glass, with: .color(dark ? Color.white.opacity(0.2 + 0.15 * light) : deep.opacity(0.7)), lineWidth: dark ? 0.02 : 0.035)
        b.fill(BG.ellipse(CGPoint(x: -0.08, y: 0.5), 0.03, 0.11), with: .color(.white.opacity(0.75)))

        let cap = capAmount(t)
        if cap > 0.02 {
            b.fill(BG.ellipse(CGPoint(x: 0, y: -0.02), 0.15, 0.05 * cap), with: .color(.white.opacity(Double(0.9 * cap))))
        }
    }

    /// During a strong gust a clump of snow is knocked off the cord.
    static func drawClump(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, swags: [DecemberSwag]) {
        guard capAmount(t) > 0.3 else { return }
        let period: CGFloat = 9
        let position = t / period + 0.2
        let cycle = Int(floor(position))
        let age = BG.fract(position) * period
        guard age < 2.6 else { return }
        let k = Int(BG.hash(cycle, 760) * CGFloat(hooks)) % hooks
        let u = BG.hash(cycle, 761, 0.15, 0.85)
        let start = t - age
        let origin = swags[k].point(u)
        guard DecemberBreeze.gust(start - origin.x / 300) > 0.4 else { return }
        let fade = Double(1 - BG.smoothstep(1.8, 2.6, age))
        var clump = Path()
        for j in 0..<10 {
            let a = max(0, age - BG.hash(j, 762, 0, 0.2))
            let p = CGPoint(x: origin.x + BG.hash(j, 763, -10, 30) * a, y: origin.y + 2 + 130 * a * a)
            clump.addPath(BG.circle(p, BG.hash(j, 764, 1, 2.4)))
        }
        ctx.fill(clump, with: .color(.white.opacity(0.85 * fade)))
    }

    /// New Year's Eve: after the flash, gold and white sparkles erupt from the strand
    /// and fall.
    static func drawBurst(in ctx: inout GraphicsContext, size: CGSize, look: DecemberModel.Look, bulbs: [DecemberBulb]) {
        let age = look.countdown - 11
        guard look.countdown >= 0, age > 0 else { return }
        for k in 0..<40 {
            let origin = bulbs[k % bulbs.count].glow
            let angle = BG.hash(k, 770, 0.3, 2.85) + CGFloat.pi
            let speed = BG.hash(k, 771, 60, 180)
            let p = CGPoint(
                x: origin.x + cos(angle) * speed * age,
                y: origin.y + sin(angle) * speed * age * 0.6 + 70 * age * age
            )
            let fade = Double(1 - BG.smoothstep(2.5, 6, age))
            let color = k % 2 == 0 ? BG.rgb(1, 0.85, 0.45) : BG.rgb(1, 0.98, 0.92)
            ctx.sparkle(at: p, size: BG.hash(k, 772, 4, 8), color: color, intensity: fade * Double(0.6 + 0.4 * sin(age * 9 + CGFloat(k))))
        }
    }

    // MARK: Sky and land

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, look: DecemberModel.Look, bulbs: [DecemberBulb], dark: Bool) {
        let dusk = Double(look.solstice)
        let night = Gradient(stops: [
            .init(color: BG.rgb(0.1, 0.14, 0.3 + 0.08 * dusk, 0.3 + 0.1 * dusk), location: 0),
            .init(color: BG.rgb(0.18, 0.22, 0.4, 0.12), location: 0.5),
            .init(color: BG.rgb(0.6, 0.65, 0.8, 0.12), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(night, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        // Warm wash along the top, tinted by the average bulb light.
        var r = 0.0, g = 0.0, b = 0.0, total = 0.0
        for bulb in bulbs {
            let w = Double(bulb.light)
            r += bulb.hue.r * w
            g += bulb.hue.g * w
            b += bulb.hue.b * w
            total += w
        }
        let average = total > 0.01 ? DecemberHue(r: r / total, g: g / total, b: b / total) : DecemberHue(r: 1, g: 0.72, b: 0.42)
        let wash = DecemberHue(r: 1, g: 0.72, b: 0.42).mix(average, 0.45).mix(DecemberHue(r: 0.45, g: 0.5, b: 0.85), 0.35 * dusk)
        let strength = (dark ? 0.12 : 0.06) * min(1, 0.3 + total / 14)
        AtmospherePainter.topHaze(in: &ctx, size: size, color: wash.color, intensity: strength, depth: 0.22)
    }

    static func ridgeY(_ x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        return size.height * (0.87 + 0.018 * sin(u * 4.4 + 0.6) + 0.008 * sin(u * 12 + 1.9))
    }

    /// Far snowy hills with a few tiny window lights twinkling on them.
    static func drawFarHills(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 20 {
            hills.addLine(to: CGPoint(x: x, y: ridgeY(x, size: size)))
            x += 20
        }
        hills.addLine(to: CGPoint(x: size.width + 20, y: size.height))
        hills.closeSubpath()
        ctx.fill(hills, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.78, 0.84, 0.96, 0.35), BG.rgb(0.55, 0.62, 0.8, 0.3)]),
            startPoint: CGPoint(x: 0, y: size.height * 0.85),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        var lights = Path()
        for i in 0..<14 {
            let x = BG.hash(i, 780) * size.width
            let y = ridgeY(x, size: size) + BG.hash(i, 781, 4, 14)
            let on = BG.hash(i * 31 + Int(floor(t / BG.hash(i, 782, 20, 50))), 783) < 0.8
            guard on else { continue }
            lights.addPath(BG.circle(CGPoint(x: x, y: y), 1.3))
        }
        ctx.fill(lights, with: .color(BG.rgb(1, 0.82, 0.5, 0.75)))
    }

    /// A row of snow-roofed houses along the bottom with lit windows that come and go,
    /// and chimney smoke leaning with the breeze.
    static func drawVillage(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, dark: Bool) {
        let ground = size.height * 0.978
        var bodies = Path()
        var roofs = Path()
        var snow = Path()
        var windows = Path()
        var chimneys: [CGPoint] = []
        var x: CGFloat = -12
        var i = 0
        while x < size.width + 12 {
            let w = BG.hash(i, 790, 44, 92)
            let h = size.height * BG.hash(i, 791, 0.03, 0.06)
            let peak = w * BG.hash(i, 792, 0.22, 0.42)
            let top = ground - h
            bodies.addRect(CGRect(x: x, y: top, width: w, height: h + 2))
            roofs.move(to: CGPoint(x: x - 3, y: top + 1))
            roofs.addLine(to: CGPoint(x: x + w / 2, y: top - peak))
            roofs.addLine(to: CGPoint(x: x + w + 3, y: top + 1))
            roofs.closeSubpath()
            snow.move(to: CGPoint(x: x - 4, y: top + 1))
            snow.addLine(to: CGPoint(x: x + w / 2, y: top - peak - 1.5))
            snow.addLine(to: CGPoint(x: x + w + 4, y: top + 1))
            if i % 5 == 2 {
                // A steeple.
                let sx = x + w * 0.25
                bodies.addRect(CGRect(x: sx - 7, y: top - peak - h * 0.7, width: 14, height: h * 0.7 + peak))
                roofs.move(to: CGPoint(x: sx - 9, y: top - peak - h * 0.7))
                roofs.addLine(to: CGPoint(x: sx, y: top - peak - h * 0.7 - 30))
                roofs.addLine(to: CGPoint(x: sx + 9, y: top - peak - h * 0.7))
                roofs.closeSubpath()
            } else if BG.hash(i, 793) < 0.6 {
                let cx = x + w * 0.72
                let ctop = top - peak * 0.45 - 9
                bodies.addRect(CGRect(x: cx - 3, y: ctop, width: 6, height: 12))
                chimneys.append(CGPoint(x: cx, y: ctop))
            }
            let count = 1 + Int(BG.hash(i, 794) * 3)
            for j in 0..<count {
                let seed = i * 7 + j
                // Windows come and go as people move about.
                let period = BG.hash(seed, 795, 25, 70)
                let state = BG.hash(seed * 31 + Int(floor(t / period + BG.hash(seed, 796))), 797) < 0.75
                guard state else { continue }
                let wx = x + w * (CGFloat(j) + 0.5) / CGFloat(count) - 3.5
                windows.addRect(CGRect(x: wx, y: top + h * 0.3, width: 7, height: 8))
            }
            x += w + BG.hash(i, 798, 4, 16)
            i += 1
        }

        let ink = dark ? BG.rgb(0.12, 0.13, 0.22, 0.85) : BG.rgb(0.25, 0.28, 0.4, 0.7)
        ctx.blurredLayer(radius: 7) { glow in
            glow.fill(windows, with: .color(BG.rgb(1, 0.75, 0.35, 0.7)))
        }
        ctx.fill(bodies, with: .color(ink))
        ctx.fill(roofs, with: .color(ink))
        ctx.stroke(snow, with: .color(BG.rgb(0.96, 0.98, 1, 0.92)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
        ctx.fill(windows, with: .color(BG.rgb(1, 0.82, 0.45, 0.95)))

        // Snowy ground.
        ctx.fill(
            Path(CGRect(x: 0, y: ground - 1, width: size.width, height: size.height - ground + 1)),
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.98, 0.99, 1, 0.95), BG.rgb(0.78, 0.84, 0.96, 0.9)]),
                startPoint: CGPoint(x: 0, y: ground),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Chimney smoke leaning with the breeze at that spot.
        ctx.blurredLayer(radius: 4) { smoke in
            for (c, chimney) in chimneys.enumerated() {
                let lean = DecemberBreeze.wind(at: chimney.x, t)
                for k in 0..<6 {
                    let f = BG.fract(BG.hash(c * 6 + k, 799) + t * 0.08)
                    let p = CGPoint(x: chimney.x + f * f * 70 * lean + f * 8, y: chimney.y - f * 55)
                    let alpha = Double((1 - f) * BG.smoothstep(0, 0.1, f)) * 0.22
                    smoke.fill(BG.circle(p, 3 + 10 * f), with: .color(BG.rgb(0.75, 0.78, 0.88, alpha)))
                }
            }
        }
    }

    /// A decorated evergreen at the right edge with its own twinkling lights and star.
    static func drawTree(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look, dark: Bool) {
        let height = min(size.height * 0.2, 220)
        let base = CGPoint(x: size.width - height * 0.36, y: size.height * 0.985)
        let sway = DecemberBreeze.wind(at: base.x, t) * 0.008
        let transform = CGAffineTransform(translationX: base.x, y: base.y).rotated(by: sway).scaledBy(x: height * 0.85, y: height)
        ctx.fill(DecemberArt.tree.applying(transform), with: .linearGradient(
            Gradient(colors: [BG.rgb(0.08, 0.3, 0.18, 0.85), BG.rgb(0.03, 0.16, 0.1, 0.9)]),
            startPoint: CGPoint(x: base.x, y: base.y - height),
            endPoint: base
        ))
        var groups = [Path(), Path(), Path(), Path(), Path()]
        for (i, light) in DecemberArt.treeLights.enumerated() {
            let p = light.applying(transform)
            let twinkle = 0.5 + 0.5 * sin(t * BG.hash(i, 800, 1, 2.4) + CGFloat(i))
            groups[i % groups.count].addPath(BG.circle(p, 1.4 + 1.1 * twinkle))
        }
        ctx.blurredLayer(radius: 4) { glow in
            for (k, group) in groups.enumerated() {
                let hue = DecemberArt.hues[k].mix(DecemberArt.warmWhite, Double(look.christmas))
                glow.fill(group, with: .color(hue.color.opacity(dark ? 0.9 : 0.6)))
            }
        }
        for (k, group) in groups.enumerated() {
            let hue = DecemberArt.hues[k].mix(DecemberArt.warmWhite, Double(look.christmas))
            ctx.fill(group, with: .color(hue.mix(DecemberHue(r: 1, g: 1, b: 1), 0.4).color))
        }
        let top = CGPoint(x: 0, y: -1.02).applying(transform)
        ctx.sparkle(at: top, size: 9, color: BG.rgb(1, 0.9, 0.55), intensity: 0.75 + 0.25 * Double(sin(t * 1.1)))
    }

    /// Christmas: a bright star with soft diffraction spikes just under the strand's centre.
    static func drawStar(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look) {
        let s = Double(look.christmas)
        guard s > 0.01 else { return }
        let c = CGPoint(x: size.width / 2, y: size.height * 0.1 + sin(t * 0.4) * 2)
        let twinkle = 0.82 + 0.18 * Double(sin(t * 0.9))
        let strength = s * twinkle
        ctx.glow(at: c, radius: 90, color: BG.rgb(1, 0.9, 0.7), intensity: 0.35 * strength)
        var spikes = ctx
        spikes.blendMode = .plusLighter
        for (k, length) in ([70, 70, 70, 70, 30, 30, 30, 30] as [CGFloat]).enumerated() {
            let angle = CGFloat(k) * CGFloat.pi / 2 + (k >= 4 ? CGFloat.pi / 4 : 0)
            let end = CGPoint(x: c.x + cos(angle) * length, y: c.y + sin(angle) * length)
            var line = Path()
            line.move(to: c)
            line.addLine(to: end)
            spikes.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 0.95, 0.85, 0.7 * strength), BG.rgb(1, 0.95, 0.85, 0)]),
                    startPoint: c,
                    endPoint: end
                ),
                lineWidth: k >= 4 ? 1 : 1.6
            )
        }
        ctx.sparkle(at: c, size: 18, color: BG.rgb(1, 0.95, 0.82), intensity: strength)
    }

    /// Christmas: now and then a sleigh crosses high in the sky with a sparkling trail.
    static func drawSleigh(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look) {
        let s = Double(look.christmas)
        guard s > 0.01 else { return }
        let period: CGFloat = 80
        let position = t / period + 0.15
        let local = BG.fract(position)
        let span: CGFloat = 0.28
        guard local < span else { return }
        let u = local / span
        let x = -80 + u * (size.width + 160)
        let y = size.height * 0.2 - sin(u * .pi) * size.height * 0.05
        var sleigh = ctx
        sleigh.opacity = s * 0.75
        sleigh.translateBy(x: x, y: y)
        sleigh.rotate(by: .radians(Double(-cos(u * .pi) * 0.12)))
        sleigh.scaleBy(x: 70, y: 70)
        sleigh.fill(DecemberArt.sleigh, with: .color(BG.rgb(0.12, 0.1, 0.16)))
        for k in 0..<6 {
            let back = CGFloat(k + 1) * 14
            let p = CGPoint(x: x - 36 - back, y: y + 4 + sin(t * 3 + CGFloat(k)) * 3)
            ctx.sparkle(at: p, size: 4, color: BG.rgb(1, 0.9, 0.6), intensity: s * Double(1 - CGFloat(k) / 6) * 0.8)
        }
    }

    // MARK: Snow

    static func drawFarSnow(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look, dark: Bool) {
        let amount = BG.lerp(0.6, 0.25, look.christmas)
        var bands = [Path(), Path()]
        let span = size.height + 40
        for i in 0..<200 {
            let visible = BG.clamp01((amount - BG.hash(i, 160)) / 0.06)
            guard visible > 0.02 else { continue }
            let speed = BG.hash(i, 11, 22, 42)
            let progress = BG.fract(BG.hash(i, 12) + t * speed / span)
            let y = progress * span - 20
            let sway = sin(t * BG.hash(i, 13, 0.4, 0.9) + BG.hash(i, 14) * 6.28) * 14
            let x = BG.wrap(BG.hash(i, 15) * size.width + sway + look.drift * 0.45, length: size.width, margin: 20)
            bands[i % 2].addPath(BG.circle(CGPoint(x: x, y: y), BG.hash(i, 16, 0.9, 2) * visible))
        }
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.8, y: 0.8)
            for band in bands { shadow.fill(band, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45))) }
        }
        ctx.fill(bands[0], with: .color(.white.opacity(0.45)))
        ctx.fill(bands[1], with: .color(.white.opacity(0.65)))
    }

    /// Mid crystals; those near the strand glow in the color of the nearest bulbs.
    static func drawCrystals(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look, bulbs: [DecemberBulb], dark: Bool) {
        var crystals = Path()
        let amount = BG.lerp(0.6, 0.3, look.christmas)
        let span = size.height + 80
        let reachY = size.height * 0.13 + 150
        for i in 0..<44 {
            let seed = i + 1000
            let visible = BG.clamp01((amount - BG.hash(seed, 160)) / 0.06)
            guard visible > 0.02 else { continue }
            let speed = BG.hash(seed, 11, 40, 66)
            let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
            let y = progress * span - 40
            let sway = sin(t * BG.hash(seed, 13, 0.3, 0.7) + BG.hash(seed, 14) * 6.28) * 32
            let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 0.75, length: size.width, margin: 40)
            let radius = BG.hash(seed, 16, 5, 10) * visible
            let spin = t * BG.hash(seed, 18, -0.6, 0.6) + BG.hash(seed, 19) * 6.28
            crystals.addPath(
                SnowRenderer.crystals[i % SnowRenderer.crystals.count],
                transform: CGAffineTransform(translationX: x, y: y).rotated(by: spin).scaledBy(x: radius, y: radius)
            )

            // Colored light from the nearest bulbs.
            guard y < reachY else { continue }
            var best: CGFloat = 0
            var hue = DecemberHue(r: 1, g: 1, b: 1)
            for bulb in bulbs where bulb.light > 0.05 {
                let dx = bulb.glow.x - x
                let dy = bulb.glow.y - y
                let d2 = dx * dx + dy * dy
                guard d2 < 22500 else { continue }
                let falloff = 1 - sqrt(d2) / 150
                let w = bulb.light * falloff * falloff
                if w > best {
                    best = w
                    hue = bulb.hue
                }
            }
            if best > 0.03 {
                ctx.glow(at: CGPoint(x: x, y: y), radius: radius * 2.4, color: hue.color, intensity: Double(best) * (dark ? 0.9 : 0.45), additive: dark)
            }
        }
        let stroke = StrokeStyle(lineWidth: 1.1, lineCap: .round)
        if !dark {
            var shadow = ctx
            shadow.translateBy(x: 0.9, y: 0.9)
            shadow.stroke(crystals, with: .color(BG.rgb(0.5, 0.61, 0.79, 0.45)), style: stroke)
        }
        ctx.blurredLayer(radius: 3) { halo in
            halo.stroke(crystals, with: .color(.white.opacity(0.4)), lineWidth: 3)
        }
        ctx.stroke(crystals, with: .color(.white.opacity(0.9)), style: stroke)
    }

    /// Christmas: snowfall softens into large, slow flakes.
    static func drawSlowFlakes(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look, dark: Bool) {
        let amount = look.christmas
        guard amount > 0.01 else { return }
        var flakes = Path()
        let span = size.height + 60
        for i in 0..<30 {
            let seed = i + 3000
            let visible = BG.clamp01((amount - BG.hash(seed, 160)) / 0.08)
            guard visible > 0.02 else { continue }
            let speed = BG.hash(seed, 11, 14, 28)
            let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
            let y = progress * span - 30
            let sway = sin(t * BG.hash(seed, 13, 0.2, 0.45) + BG.hash(seed, 14) * 6.28) * 40
            let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 0.6, length: size.width, margin: 30)
            flakes.addPath(BG.circle(CGPoint(x: x, y: y), BG.hash(seed, 16, 2.6, 5) * visible))
        }
        ctx.blurredLayer(radius: 1.5) { soft in
            soft.fill(flakes, with: .color((dark ? Color.white : BG.rgb(0.72, 0.8, 0.94)).opacity(0.85)))
        }
    }

    /// Near-camera bokeh flakes, tinted by the bulbs they pass.
    static func drawBokeh(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: DecemberModel.Look, bulbs: [DecemberBulb], dark: Bool) {
        let span = size.height + 200
        ctx.blurredLayer(radius: 7) { near in
            for i in 0..<8 {
                let seed = i + 2000
                let speed = BG.hash(seed, 11, 85, 130)
                let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
                let y = progress * span - 100
                let sway = sin(t * BG.hash(seed, 13, 0.2, 0.5) + BG.hash(seed, 14) * 6.28) * 60
                let x = BG.wrap(BG.hash(seed, 15) * size.width + sway + look.drift * 1.2, length: size.width, margin: 100)
                let radius = BG.hash(seed, 16, 18, 38)
                var hue = dark ? DecemberHue(r: 1, g: 1, b: 1) : DecemberHue(r: 0.69, g: 0.77, b: 0.9)
                var best: CGFloat = 0
                for bulb in bulbs where bulb.light > 0.05 {
                    let dx = bulb.glow.x - x
                    let dy = bulb.glow.y - y
                    let d = sqrt(dx * dx + dy * dy)
                    let w = bulb.light * max(0, 1 - d / 220)
                    if w > best {
                        best = w
                        hue = hue.mix(bulb.hue, Double(min(w, 0.8)))
                    }
                }
                let cx = 1 - BG.clamp01(abs(x / size.width - 0.5) / 0.25)
                let cy = 1 - BG.clamp01(abs(y / size.height - 0.5) / 0.25)
                let center = radius > 30 ? BG.lerp(1, 0.5, BG.smoothstep(0, 0.5, min(cx, cy))) : 1
                let alpha = (dark ? 0.38 : 0.2) * Double(center)
                let p = CGPoint(x: x, y: y)
                near.fill(
                    BG.circle(p, radius),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: hue.color.opacity(alpha * 0.7), location: 0),
                            .init(color: hue.color.opacity(alpha * 0.6), location: 0.6),
                            .init(color: hue.color.opacity(alpha), location: 0.86),
                            .init(color: hue.color.opacity(0), location: 1)
                        ]),
                        center: p, startRadius: 0, endRadius: radius
                    )
                )
            }
        }
    }
}
