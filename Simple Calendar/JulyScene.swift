//
//  JulyScene.swift
//  Simple Calendar
//
//  July: a fireworks show over a lake and a city skyline on a summer night.
//
//  The show is the star, and every burst is a light. A small scheduler (`JulyShow`)
//  launches shells slot by slot; each frame the live bursts become a light list, and
//  everything around answers to it: the sky glows in the burst's color, the smoke left
//  by earlier shells is lit from inside by later ones, the skyline's edges and the
//  crowd on the near shore catch the color, and the lake mirrors each burst in a
//  rippling streak.
//
//  The scene also follows the selected day:
//    * weekend        - more fireworks (shorter slots, more frequent finales)
//    * day character  - which two palettes the day favours
//    * Independence Day - a grand finale show in red, white and blue
//    * Canada Day     - red and white, with maple-leaf peonies
//    * Bastille Day   - blue, white and red in sequence
//  Density changes through one discrete 2.5 s transition (`SceneTransition`) and is
//  applied at the next slot, so shells already in the air are never disturbed.
//

import SwiftUI

// MARK: - View

struct JulyFireworksAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = JulyModel()
    @Environment(\.colorScheme) private var colorScheme

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = JulyModel.Target(date: date)
        let state = model
        let dark = colorScheme == .dark
        AnimatedScene { ctx, size, time in
            let look = state.look(target: target, time: time)
            JulyScene.draw(in: &ctx, size: size, time: time, look: look, dark: dark)
        }
        .opacity(alpha)
    }
}

// MARK: - Colors

struct JulyHue {
    var r: Double, g: Double, b: Double

    func mix(_ o: JulyHue, _ a: Double) -> JulyHue {
        JulyHue(r: r + (o.r - r) * a, g: g + (o.g - g) * a, b: b + (o.b - b) * a)
    }

    var color: Color { BG.rgb(r, g, b) }
}

/// Shell palettes: primary and secondary star colors.
enum JulyPalette {
    static let all: [(JulyHue, JulyHue)] = [
        (JulyHue(r: 1, g: 0.25, b: 0.3), JulyHue(r: 1, g: 0.85, b: 0.85)),    // 0 red
        (JulyHue(r: 0.3, g: 0.55, b: 1), JulyHue(r: 0.85, g: 0.92, b: 1)),    // 1 blue
        (JulyHue(r: 1, g: 0.82, b: 0.3), JulyHue(r: 1, g: 0.95, b: 0.75)),    // 2 gold
        (JulyHue(r: 0.35, g: 1, b: 0.5), JulyHue(r: 0.85, g: 1, b: 0.85)),    // 3 green
        (JulyHue(r: 0.85, g: 0.35, b: 1), JulyHue(r: 1, g: 0.7, b: 0.95)),    // 4 violet
        (JulyHue(r: 1, g: 0.5, b: 0.15), JulyHue(r: 1, g: 0.85, b: 0.5)),     // 5 orange
        (JulyHue(r: 1, g: 1, b: 1), JulyHue(r: 0.88, g: 0.92, b: 1))          // 6 white
    ]
}

// MARK: - State

/// One shell: launched at `launch`, rising, bursting, then leaving smoke.
struct JulyShell {
    var seed: Int
    var launch: CGFloat
    /// 0 peony, 1 chrysanthemum, 2 willow, 3 ring, 4 strobe, 5 shaped.
    var kind: Int
    /// For shaped shells: 0 heart, 1 star, 2 ring of rings, 3 maple leaf.
    var shape: Int
    var palette: Int
    /// Sky glow multiplier (1.5 for the Independence Day finale).
    var glow: CGFloat
}

final class JulyModel {
    struct Target {
        let weekend: Double
        /// The two palettes the day favours.
        let favored: (Int, Int)
        /// 0 none, 1 Independence Day, 2 Canada Day, 3 Bastille Day.
        let special: Int

        init(date: Date) {
            let day = SceneDay(date: date)
            weekend = day.weekday == 1 || day.weekday == 7 ? 1 : 0
            let a = Int(day.roll(701) * 6) % 6
            let b = (a + 1 + Int(day.roll(702) * 5)) % 6
            favored = (a, b)
            if day.month == 7 && day.day == 4 {
                special = 1
            } else if day.month == 7 && day.day == 1 {
                special = 2
            } else if day.month == 7 && day.day == 14 {
                special = 3
            } else {
                special = 0
            }
        }
    }

    struct Look {
        var shells: [JulyShell]
        var independence: CGFloat
        /// Wind displacement accumulated since the scene appeared.
        var drift: CGFloat
    }

    private let show = JulyShow()
    private let weekendTransition = SceneTransition()
    private let independenceTransition = SceneTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let weekend = weekendTransition.value(target: target.weekend, time: time)
        let independence = independenceTransition.value(target: target.special == 1 ? 1 : 0, time: time)
        show.advance(time: CGFloat(time), weekend: CGFloat(weekend), favored: target.favored, special: target.special)
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * (8 + 4 * sin(CGFloat(time) * 0.13))
        }
        lastTime = time
        return Look(shells: show.shells, independence: CGFloat(independence), drift: drift)
    }
}

/// Launches shells slot by slot with the settings in force at each slot, and keeps them
/// while they rise, burst and smoke. Bounded (shells retire after 14 s).
final class JulyShow {
    private(set) var shells: [JulyShell] = []
    private var slot = 0
    private var nextSlot: CGFloat?
    private var nextFinale: CGFloat?
    private var finaleCount = 0

    func advance(time t: CGFloat, weekend: CGFloat, favored: (Int, Int), special: Int) {
        if nextSlot == nil { nextSlot = t + 0.4 }
        guard var next = nextSlot else { return }
        // After a pause, pick up from now without backfilling missed slots (they would
        // all appear at once, mid-flight).
        if t - next > 2 { next = t }
        let interval = special == 1 ? 0.6 : BG.lerp(1.5, 1.2, weekend)
        let finaleEvery = special == 1 ? 5 : (weekend > 0.5 ? 7 : 9)
        while next <= t {
            launchSlot(at: next, interval: interval, finaleEvery: finaleEvery, favored: favored, special: special)
            slot += 1
            next += interval
        }
        nextSlot = next

        // Independence Day: every 20 s, an 18-shell finale over 4 s.
        if special == 1 {
            if nextFinale == nil || t - (nextFinale ?? t) > 20 { nextFinale = t + 3 }
            if let finale = nextFinale, t >= finale {
                finaleCount += 1
                for k in 0..<18 {
                    let seed = 900_000 + finaleCount * 32 + k
                    shells.append(makeShell(seed: seed, launch: finale + CGFloat(k) * 4 / 18, favored: favored, special: special, glow: 1.5, index: k))
                }
                nextFinale = finale + 20
            }
        } else {
            nextFinale = nil
        }

        shells.removeAll { t - $0.launch > 14 }
        if shells.count > 64 { shells.removeFirst(shells.count - 64) }
    }

    private func launchSlot(at time: CGFloat, interval: CGFloat, finaleEvery: Int, favored: (Int, Int), special: Int) {
        let count: Int
        if slot % finaleEvery == finaleEvery - 1 {
            count = special == 1 ? 7 : 5
        } else if slot % 4 == 3 {
            count = 2
        } else {
            count = BG.hash(slot, 90) < 0.25 ? 0 : 1
        }
        for j in 0..<count {
            let seed = slot * 16 + j
            let launch = time + BG.hash(seed, 91) * interval * 0.9 + CGFloat(j) * 0.2
            shells.append(makeShell(seed: seed, launch: launch, favored: favored, special: special, glow: 1, index: slot + j))
        }
    }

    private func makeShell(seed: Int, launch: CGFloat, favored: (Int, Int), special: Int, glow: CGFloat, index: Int) -> JulyShell {
        var kind = Int(BG.hash(seed, 98) * 5) % 5
        var shape = 0
        if BG.hash(seed, 105) < 0.04 {
            kind = 5
            shape = Int(BG.hash(seed, 106) * 3) % 3
        }
        let palette: Int
        switch special {
        case 1:
            // Red, white and blue.
            palette = [0, 6, 1][Int(BG.hash(seed, 96) * 3) % 3]
        case 2:
            // Red and white, often a maple leaf.
            palette = BG.hash(seed, 96) < 0.55 ? 0 : 6
            if kind == 0 || BG.hash(seed, 107) < 0.2 {
                kind = 5
                shape = 3
            }
        case 3:
            // Blue, white and red in sequence.
            palette = [1, 6, 0][index % 3]
        default:
            let roll = BG.hash(seed, 96)
            if roll < 0.3 {
                palette = favored.0
            } else if roll < 0.6 {
                palette = favored.1
            } else {
                palette = Int(BG.hash(seed, 97) * 6) % 6
            }
        }
        return JulyShell(seed: seed, launch: launch, kind: kind, shape: shape, palette: palette, glow: glow)
    }
}

// MARK: - Lights

/// The skyline geometry for the last canvas size.
final class JulySkylineCache {
    var size: CGSize = .zero
    var city = Path()
    var windows = Path()
}


/// A live burst acting as a point light this frame.
private struct JulyLight {
    var position: CGPoint
    var hue: JulyHue
    var intensity: CGFloat
}

// MARK: - Scene

private enum JulyScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: JulyModel.Look, dark: Bool) {
        let t = CGFloat(time)
        var lights: [JulyLight] = []
        lights.reserveCapacity(24)
        for shell in look.shells {
            let g = geometry(shell, size: size)
            let b = t - shell.launch - g.rise
            guard b >= 0, b < g.life else { continue }
            let flash = max(0, 1 - b / 0.4)
            let fade = 1 - BG.smoothstep(g.life * 0.5, g.life, b)
            let intensity = max(flash, 0.3 * fade) * shell.glow
            lights.append(JulyLight(position: g.apex, hue: JulyPalette.all[shell.palette].0, intensity: intensity))
        }

        drawSky(in: &ctx, size: size, time: time, look: look, lights: lights, dark: dark)
        drawAirplane(in: &ctx, size: size, t: t)
        drawSmoke(in: &ctx, size: size, t: t, look: look, lights: lights, dark: dark)
        // Thin each burst when many are in the air at once (the July 4 finale), so the
        // busiest moments stay within budget.
        let starScale: CGFloat = lights.count > 24 ? 0.5 : (lights.count > 14 ? 0.7 : 1)
        for shell in look.shells {
            drawShell(shell, in: &ctx, size: size, t: t, dark: dark, starScale: starScale)
        }
        drawSkyline(in: &ctx, size: size, t: t, lights: lights, dark: dark)
        drawLake(in: &ctx, size: size, t: t, lights: lights, dark: dark)
        drawShore(in: &ctx, size: size, t: t, lights: lights, dark: dark)
    }

    /// Where a shell launches, peaks, and how long it rises and burns.
    static func geometry(_ shell: JulyShell, size: CGSize) -> (start: CGFloat, apex: CGPoint, rise: CGFloat, life: CGFloat) {
        let seed = shell.seed
        let startX = size.width * BG.hash(seed, 92, 0.12, 0.88)
        let apex = CGPoint(x: startX + BG.hash(seed, 94, -60, 60), y: size.height * BG.hash(seed, 93, 0.12, 0.38))
        return (startX, apex, BG.hash(seed, 95, 1.2, 1.8), BG.hash(seed, 97, 2.8, 4.6))
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: JulyModel.Look, lights: [JulyLight], dark: Bool) {
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.04, 0.06, 0.2), intensity: dark ? 0.38 : 0.15, depth: 0.65)
        AtmospherePainter.stars(in: &ctx, size: size, time: time, count: dark ? 80 : 40, skyFraction: 0.5, intensity: dark ? 0.6 : 0.35)
        // Each burst lights the sky around it, in its color (capped).
        for light in lights where light.intensity > 0.02 {
            let boost = Double(min(light.intensity, 1.5))
            ctx.glow(at: light.position, radius: 420, color: light.hue.color, intensity: (dark ? 0.16 : 0.08) * boost)
        }
    }

    /// Now and then a plane crosses high up, its lights blinking.
    static func drawAirplane(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let period: CGFloat = 130
        let position = t / period + 0.2
        let cycle = Int(floor(position))
        let local = BG.fract(position)
        let span: CGFloat = 0.45
        guard local < span else { return }
        let u = local / span
        let rightward = BG.hash(cycle, 710) < 0.5
        let x = rightward ? -20 + u * (size.width + 40) : size.width + 20 - u * (size.width + 40)
        let y = size.height * BG.hash(cycle, 711, 0.04, 0.09) + u * 10
        let blink = BG.fract(t * 0.8) < 0.12
        ctx.fill(BG.circle(CGPoint(x: x, y: y), 1.1), with: .color(BG.rgb(1, 1, 0.95, 0.7)))
        if blink {
            ctx.glow(at: CGPoint(x: x - 4, y: y), radius: 6, color: BG.rgb(1, 0.3, 0.3), intensity: 0.8, additive: true)
        }
        if BG.fract(t * 0.8 + 0.5) < 0.08 {
            ctx.glow(at: CGPoint(x: x + 4, y: y), radius: 6, color: BG.rgb(1, 1, 1), intensity: 0.7, additive: true)
        }
    }

    /// Smoke left by each burst: it grows, rises, drifts with the wind and lingers up to
    /// 12 s, lit from inside by later bursts nearby in their colors.
    static func drawSmoke(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: JulyModel.Look, lights: [JulyLight], dark: Bool) {
        let cap = 0.08 + 0.04 * Double(look.independence)
        ctx.blurredLayer(radius: 18) { smoke in
            for shell in look.shells {
                let g = geometry(shell, size: size)
                let b = t - shell.launch - g.rise
                guard b > 0.2, b < 12 else { continue }
                let grow = BG.smoothstep(0.2, 2.5, b)
                let fade = 1 - BG.smoothstep(6, 12, b)
                // Carried downwind (about 8 pt/s) as it rises.
                let c = CGPoint(x: g.apex.x + b * 8, y: g.apex.y - b * 12 + 20)
                let r = 40 + 90 * grow
                var tint = dark ? JulyHue(r: 0.75, g: 0.75, b: 0.85) : JulyHue(r: 0.55, g: 0.55, b: 0.6)
                var lit: CGFloat = 0
                for light in lights {
                    let dx = light.position.x - c.x
                    let dy = light.position.y - c.y
                    let w = light.intensity * max(0, 1 - sqrt(dx * dx + dy * dy) / 320)
                    if w > lit {
                        lit = w
                        tint = tint.mix(light.hue, Double(min(w, 1)) * 0.7)
                    }
                }
                let alpha = cap * Double(grow * fade) * (1 + Double(lit) * (dark ? 1.5 : 0.5))
                smoke.fill(BG.circle(c, r), with: .radialGradient(
                    Gradient(colors: [tint.color.opacity(alpha), tint.color.opacity(alpha * 0.4), tint.color.opacity(0)]),
                    center: c, startRadius: 0, endRadius: r
                ))
            }
        }
    }

    // MARK: Shells

    static func drawShell(_ shell: JulyShell, in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, dark: Bool, starScale: CGFloat) {
        let g = geometry(shell, size: size)
        let age = t - shell.launch
        guard age >= 0 else { return }
        var layer = ctx
        if dark { layer.blendMode = .plusLighter }

        if age < g.rise {
            // Rocket climbing with a crackling spark trail.
            func rocket(_ u: CGFloat) -> CGPoint {
                let eased = 1 - (1 - u) * (1 - u)
                return CGPoint(x: BG.lerp(g.start, g.apex.x, eased), y: BG.lerp(size.height + 10, g.apex.y, eased))
            }
            let u = age / g.rise
            var sparks = Path()
            for k in 0..<12 {
                let p = rocket(max(0, u - CGFloat(k) * 0.015))
                sparks.addPath(BG.circle(CGPoint(x: p.x + sin(CGFloat(k) * 2.1 + age * 30) * 1.5, y: p.y + CGFloat(k) * 0.5), 1.6 * (1 - CGFloat(k) / 14)))
            }
            layer.fill(sparks, with: .color(BG.rgb(1, 0.8, 0.45, 0.65)))
            let head = rocket(u)
            layer.glow(at: head, radius: 14, color: BG.rgb(1, 0.85, 0.5), intensity: 0.7)
            layer.fill(BG.circle(head, 2.2), with: .color(dark ? .white : BG.rgb(1, 0.75, 0.35)))
            return
        }

        let b = age - g.rise
        guard b < g.life else { return }
        let palette = JulyPalette.all[shell.palette]
        let flash = max(0, 1 - b / 0.4)
        if flash > 0 {
            layer.glow(at: g.apex, radius: 90, color: .white, intensity: Double(0.6 * flash) * (dark ? 1 : 0.4))
        }

        let kind = shell.kind
        let count = Int(CGFloat(kind == 3 ? 44 : 60) * starScale)
        let baseSpeed = BG.hash(shell.seed, 99, 150, 230)
        let drag: CGFloat = kind == 2 ? 0.9 : 1.6
        let gravity: CGFloat = kind == 2 ? 95 : 60
        let trail: CGFloat = (kind == 1 || kind == 2) ? 0.45 : 0.12
        let ringTilt = BG.hash(shell.seed, 100, 0.3, 0.6)
        let ringSpin = BG.hash(shell.seed, 101) * CGFloat.pi
        let fade = Double(1 - BG.smoothstep(g.life * 0.5, g.life, b))
        guard fade > 0.02 else { return }

        func position(_ direction: CGVector, _ speed: CGFloat, _ tau: CGFloat) -> CGPoint {
            let distance = speed * (1 - exp(-drag * tau)) / drag
            return CGPoint(x: g.apex.x + direction.dx * distance, y: g.apex.y + direction.dy * distance + 0.5 * gravity * tau * tau)
        }

        // Stars batched by color, with dim tails, bright leads and head dots; stars that
        // have fallen low over the grid go in a fainter set.
        var tails = [Path(), Path()]
        var leads = [Path(), Path()]
        var heads = [Path(), Path(), Path(), Path()]
        var crackle = Path()
        let low = size.height * 0.5
        for i in 0..<count {
            let starSeed = shell.seed * 97 + i
            let angle = CGFloat(i) / CGFloat(count) * 2 * CGFloat.pi + BG.hash(starSeed, 102) * 0.08
            var direction = CGVector(dx: cos(angle), dy: sin(angle))
            var speed = baseSpeed
            if kind == 3 {
                let squashed = CGVector(dx: direction.dx, dy: direction.dy * ringTilt)
                direction = CGVector(
                    dx: squashed.dx * cos(ringSpin) - squashed.dy * sin(ringSpin),
                    dy: squashed.dx * sin(ringSpin) + squashed.dy * cos(ringSpin)
                )
            } else if kind == 5 {
                direction = shapeDirection(shell.shape, u: CGFloat(i) / CGFloat(count))
            } else {
                speed *= BG.hash(starSeed, 103, 0.62, 1)
            }
            let head = position(direction, speed, b)
            let lead = position(direction, speed, max(0, b - trail * 0.35))
            let tail = position(direction, speed, max(0, b - trail))
            let c = i % 2
            tails[c].move(to: tail)
            tails[c].addLine(to: lead)
            // Strobe stars flicker one by one (about 6 Hz), never the whole sky.
            if kind == 4 && sin(b * 38 + CGFloat(i) * 1.7) <= 0 { continue }
            leads[c].move(to: lead)
            leads[c].addLine(to: head)
            heads[c + (head.y > low ? 2 : 0)].addPath(BG.circle(head, kind == 2 ? 1.8 : 2.3))
            if kind == 2 && b > g.life * 0.6 && BG.hash(starSeed, 104) < 0.4 && sin(b * 23 + CGFloat(i)) > 0.4 {
                crackle.addPath(BG.circle(CGPoint(x: head.x + BG.hash(starSeed, 108, -4, 4), y: head.y + BG.hash(starSeed, 109, -4, 4)), 1.2))
            }
        }

        // White-hot at first, then the palette, cooling slightly redder as it fades.
        let hot = Double(1 - BG.smoothstep(0, 0.3, b))
        let cool = Double(BG.smoothstep(g.life * 0.6, g.life, b)) * 0.3
        let ember = JulyHue(r: 1, g: 0.45, b: 0.25)
        let hues = [palette.0, palette.1].map { $0.mix(ember, cool).mix(JulyHue(r: 1, g: 1, b: 1), hot) }
        let width: CGFloat = kind == 2 ? 1.5 : 2
        for c in 0..<2 {
            let color = hues[c].color
            layer.stroke(tails[c], with: .color(color.opacity(0.28 * fade)), style: StrokeStyle(lineWidth: width, lineCap: .round))
            layer.stroke(leads[c], with: .color(color.opacity(0.75 * fade)), style: StrokeStyle(lineWidth: width, lineCap: .round))
            layer.fill(heads[c], with: .color(color.opacity(fade)))
            layer.fill(heads[c + 2], with: .color(color.opacity(0.4 * fade)))
            if !dark {
                // Light theme: a slightly darker core edge so the stars read on white.
                let edge = hues[c].mix(JulyHue(r: 0, g: 0, b: 0), 0.35).color
                layer.stroke(heads[c], with: .color(edge.opacity(0.6 * fade)), lineWidth: 0.8)
            }
        }
        if kind == 2 {
            layer.fill(crackle, with: .color(BG.rgb(1, 0.92, 0.65, fade)))
        }
    }

    /// Star directions for shaped shells (magnitude up to 1).
    static func shapeDirection(_ shape: Int, u: CGFloat) -> CGVector {
        switch shape {
        case 0:
            let p = HeartGeometry.point(at: u)
            return CGVector(dx: p.x * 1.9, dy: (p.y - 0.04) * 1.9)
        case 1:
            // Five-pointed star outline.
            let points = 10
            let k = Int(floor(u * CGFloat(points)))
            let f = u * CGFloat(points) - CGFloat(k)
            func corner(_ i: Int) -> CGPoint {
                let a = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(points) * 2 * CGFloat.pi
                let r: CGFloat = i % 2 == 0 ? 1 : 0.42
                return CGPoint(x: cos(a) * r, y: sin(a) * r)
            }
            let a = corner(k)
            let b = corner(k + 1)
            return CGVector(dx: BG.lerp(a.x, b.x, f), dy: BG.lerp(a.y, b.y, f))
        case 2:
            // Ring of six small rings.
            let ring = Int(u * 6) % 6
            let local = u * 6 - floor(u * 6)
            let ca = CGFloat(ring) / 6 * 2 * CGFloat.pi
            let la = local * 2 * CGFloat.pi
            return CGVector(dx: cos(ca) * 0.7 + cos(la) * 0.25, dy: sin(ca) * 0.7 + sin(la) * 0.25)
        default:
            // Maple leaf: five pointed lobes, the top one tallest, and a short stem.
            let a = u * 2 * CGFloat.pi
            let fromUp = a - CGFloat.pi / 2
            let lobes = pow(max(0, cos(fromUp * 5)), 3)
            let up = 0.5 + 0.5 * cos(fromUp)
            let r = 0.35 + 0.65 * lobes * (0.55 + 0.45 * up)
            return CGVector(dx: cos(a) * r, dy: -sin(a) * r)
        }
    }

    // MARK: Land and water

    static func skylineTop(size: CGSize) -> CGFloat { size.height * 0.9 }

    /// A city skyline along the far shore. Its edges catch the color of the bursts.
    static let skyline = JulySkylineCache()

    /// Building outlines and lit windows depend only on the canvas size, so they are
    /// built once per size and reused every frame.
    static func buildSkyline(size: CGSize) -> (city: Path, windows: Path) {
        let base = size.height * 0.94
        var city = Path()
        var windows = Path()
        var x: CGFloat = -5
        var i = 0
        while x < size.width + 5 {
            let w = BG.hash(i, 720, 18, 46)
            let edge = min(x, size.width - x) / size.width
            let tall = edge < 0.2 ? 1.5 : 1
            let h = size.height * BG.hash(i, 721, 0.02, 0.05) * tall
            city.addRect(CGRect(x: x, y: base - h, width: w, height: h + 2))
            if BG.hash(i, 722) < 0.15 {
                city.addRect(CGRect(x: x + w * 0.45, y: base - h - 12, width: 2, height: 12))
            }
            var wy = base - h + 4
            var row = 0
            while wy < base - 4 {
                var wx = x + 3
                var col = 0
                while wx < x + w - 4 {
                    if BG.hash(i * 131 + row * 17 + col, 723) < 0.3 {
                        windows.addRect(CGRect(x: wx, y: wy, width: 2, height: 2.5))
                    }
                    wx += 5
                    col += 1
                }
                wy += 6
                row += 1
            }
            x += w + BG.hash(i, 724, 0, 6)
            i += 1
        }
        return (city, windows)
    }

    static func drawSkyline(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, lights: [JulyLight], dark: Bool) {
        if skyline.size != size {
            let built = buildSkyline(size: size)
            skyline.city = built.city
            skyline.windows = built.windows
            skyline.size = size
        }
        let city = skyline.city
        let windows = skyline.windows
        ctx.fill(city, with: .color(dark ? BG.rgb(0.05, 0.06, 0.12, 0.92) : BG.rgb(0.2, 0.22, 0.32, 0.75)))
        ctx.fill(windows, with: .color(BG.rgb(1, 0.85, 0.55, dark ? 0.7 : 0.5)))
        // Rim light from the bursts on the tops of the buildings.
        var r = 0.0, g = 0.0, b = 0.0, total = 0.0
        for light in lights {
            let w = Double(light.intensity)
            r += light.hue.r * w
            g += light.hue.g * w
            b += light.hue.b * w
            total += w
        }
        guard total > 0.02 else { return }
        var rim = ctx
        rim.translateBy(x: 0, y: -0.5)
        if dark { rim.blendMode = .plusLighter }
        rim.stroke(city, with: .color(BG.rgb(r / total, g / total, b / total, min(0.6, total * 0.3))), lineWidth: 1)
    }

    /// The lake mirrors each burst as a rippling streak of its color.
    static func drawLake(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, lights: [JulyLight], dark: Bool) {
        let top = size.height * 0.94
        let rect = CGRect(x: 0, y: top, width: size.width, height: size.height - top)
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [dark ? BG.rgb(0.06, 0.08, 0.18, 0.85) : BG.rgb(0.3, 0.35, 0.5, 0.45), dark ? BG.rgb(0.02, 0.03, 0.08, 0.9) : BG.rgb(0.2, 0.24, 0.38, 0.55)]),
            startPoint: CGPoint(x: 0, y: top),
            endPoint: CGPoint(x: 0, y: size.height)
        ))
        var lake = ctx
        lake.clip(to: Path(rect))
        if dark { lake.blendMode = .plusLighter }
        for light in lights where light.intensity > 0.03 {
            let a = Double(min(light.intensity, 1.2)) * 0.25
            for k in 0..<5 {
                let y = top + 3 + CGFloat(k) * (size.height - top) / 5
                let wobble = sin(t * 3 + CGFloat(k) * 1.7 + light.position.x * 0.01) * 6
                lake.fill(BG.ellipse(CGPoint(x: light.position.x + wobble, y: y), 26 - CGFloat(k) * 3, 1.6), with: .color(light.hue.color.opacity(a * (1 - Double(k) * 0.15))))
            }
        }
        lake.fill(Path(CGRect(x: 0, y: top, width: size.width, height: 1)), with: .color(BG.rgb(0.6, 0.65, 0.8, 0.3)))
    }

    /// Silhouettes on the near shore at the corners, rim-lit by the show, and a child
    /// waving a sparkler.
    static func drawShore(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, lights: [JulyLight], dark: Bool) {
        var people = Path()
        let ground = size.height + 2
        let spots: [(CGFloat, CGFloat)] = [(0.03, 1), (0.065, 0.8), (0.1, 1.05), (0.9, 0.95), (0.94, 1.1), (0.975, 0.75)]
        for (k, spot) in spots.enumerated() {
            let x = size.width * spot.0
            let h: CGFloat = 46 * spot.1
            let sway = sin(t * 0.4 + CGFloat(k)) * 1.5
            people.addEllipse(in: CGRect(x: x - h * 0.11 + sway, y: ground - h, width: h * 0.22, height: h * 0.22))
            people.addRoundedRect(in: CGRect(x: x - h * 0.2, y: ground - h * 0.78, width: h * 0.4, height: h * 0.8), cornerSize: CGSize(width: h * 0.14, height: h * 0.14))
        }
        ctx.fill(people, with: .color(dark ? BG.rgb(0.02, 0.02, 0.05, 0.95) : BG.rgb(0.15, 0.15, 0.22, 0.8)))
        if let brightest = lights.max(by: { $0.intensity < $1.intensity }), brightest.intensity > 0.05 {
            var rim = ctx
            rim.translateBy(x: 0, y: -0.6)
            if dark { rim.blendMode = .plusLighter }
            rim.stroke(people, with: .color(brightest.hue.color.opacity(Double(min(brightest.intensity, 1)) * 0.5)), lineWidth: 1)
        }

        // Sparkler at the child's hand (the smallest figure, bottom-right).
        let hand = CGPoint(x: size.width * 0.975 + 9 + sin(t * 1.3) * 6, y: ground - 32 + cos(t * 1.7) * 5)
        ctx.glow(at: hand, radius: 26, color: BG.rgb(1, 0.85, 0.5), intensity: 0.45, additive: dark)
        var sparks = Path()
        for k in 0..<18 {
            let a = BG.hash(k * 7 + Int(t * 12), 730) * 2 * CGFloat.pi
            let r = BG.hash(k * 7 + Int(t * 12), 731, 4, 16)
            sparks.move(to: CGPoint(x: hand.x + cos(a) * r * 0.4, y: hand.y + sin(a) * r * 0.4))
            sparks.addLine(to: CGPoint(x: hand.x + cos(a) * r, y: hand.y + sin(a) * r))
        }
        var spark = ctx
        if dark { spark.blendMode = .plusLighter }
        spark.stroke(sparks, with: .color(BG.rgb(1, 0.92, 0.7, 0.85)), lineWidth: 0.8)
        spark.fill(BG.circle(hand, 2), with: .color(.white))
    }
}
