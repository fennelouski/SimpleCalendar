//
//  MonthAnimations.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//
//  Month background scenes. Each scene is rendered by `AnimatedScene` (a
//  TimelineView-driven Canvas) using the painters in BackgroundRendering.swift,
//  so everything is lit and shaded: gradients, glows, depth-of-field blur, and
//  fake-3D motion (tumbling leaves, flapping wings) instead of flat shapes.
//

import SwiftUI

// MARK: - July: Fireworks

struct JulyFireworksAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.04, 0.06, 0.2), intensity: 0.38, depth: 0.65)
            AtmospherePainter.stars(in: &ctx, size: size, time: time, count: 70, skyFraction: 0.5, intensity: 0.6)
            JulyScene.draw(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum JulyScene {
    static let interval: CGFloat = 1.5
    static let maxLifetime: CGFloat = 7

    static let palettes: [[Color]] = [
        [BG.rgb(1, 0.25, 0.3), BG.rgb(1, 0.85, 0.85)],
        [BG.rgb(0.3, 0.55, 1), BG.rgb(0.85, 0.92, 1)],
        [BG.rgb(1, 0.82, 0.3), BG.rgb(1, 0.95, 0.75)],
        [BG.rgb(0.35, 1, 0.5), BG.rgb(0.85, 1, 0.85)],
        [BG.rgb(0.85, 0.35, 1), BG.rgb(1, 0.7, 0.95)],
        [BG.rgb(1, 0.5, 0.15), BG.rgb(1, 0.85, 0.5)]
    ]

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let firstSlot = max(0, Int(floor((t - maxLifetime) / interval)))
        let lastSlot = Int(floor(t / interval))
        guard firstSlot <= lastSlot else { return }
        for slot in firstSlot...lastSlot {
            let count: Int
            if slot % 9 == 8 {
                count = 5 // Finale cluster.
            } else if slot % 4 == 3 {
                count = 2
            } else {
                count = BG.hash(slot, 90) < 0.25 ? 0 : 1
            }
            for j in 0..<count {
                let seed = slot * 16 + j
                let launch = CGFloat(slot) * interval + BG.hash(seed, 91) * interval * 0.9 + CGFloat(j) * 0.2
                let age = t - launch
                if age >= 0 {
                    drawFirework(in: &ctx, size: size, seed: seed, age: age)
                }
            }
        }
    }

    static func drawFirework(in ctx: inout GraphicsContext, size: CGSize, seed: Int, age: CGFloat) {
        let startX = size.width * BG.hash(seed, 92, 0.12, 0.88)
        let apex = CGPoint(x: startX + BG.hash(seed, 94, -60, 60), y: size.height * BG.hash(seed, 93, 0.12, 0.4))
        let riseTime = BG.hash(seed, 95, 1.2, 1.8)
        let palette = palettes[Int(BG.hash(seed, 96) * CGFloat(palettes.count)) % palettes.count]

        if age < riseTime {
            // Rocket climbing with a sparking tail.
            func rocket(_ u: CGFloat) -> CGPoint {
                let eased = 1 - (1 - u) * (1 - u)
                return CGPoint(x: BG.lerp(startX, apex.x, eased), y: BG.lerp(size.height + 10, apex.y, eased))
            }
            let u = age / riseTime
            for k in 0..<12 {
                let back = max(0, u - CGFloat(k) * 0.015)
                let p = rocket(back)
                let fade = Double(1 - CGFloat(k) / 12)
                ctx.fill(BG.circle(CGPoint(x: p.x + sin(CGFloat(k) * 2.1 + age * 30) * 1.5, y: p.y), 1.6), with: .color(BG.rgb(1, 0.8, 0.45, 0.8 * fade)))
            }
            let head = rocket(u)
            ctx.glow(at: head, radius: 14, color: BG.rgb(1, 0.85, 0.5), intensity: 0.7)
            ctx.fill(BG.circle(head, 2.2), with: .color(.white))
            return
        }

        let b = age - riseTime
        let life = BG.hash(seed, 97, 2.8, 4.6)
        guard b < life else { return }
        let kind = Int(BG.hash(seed, 98) * 5) % 5 // 0 peony, 1 chrysanthemum, 2 willow, 3 ring, 4 strobe

        // Burst flash lighting up the sky.
        let flash = max(0, 1 - b / 0.4)
        if flash > 0 {
            ctx.glow(at: apex, radius: 420, color: palette[0], intensity: Double(0.16 * flash))
            ctx.glow(at: apex, radius: 90, color: .white, intensity: Double(0.7 * flash))
        }

        let count = kind == 3 ? 44 : 60
        let baseSpeed = BG.hash(seed, 99, 150, 230)
        let drag: CGFloat = kind == 2 ? 0.9 : 1.6
        let gravity: CGFloat = kind == 2 ? 95 : 60
        let trail: CGFloat = (kind == 1 || kind == 2) ? 0.45 : 0.12
        let ringTilt = BG.hash(seed, 100, 0.3, 0.6)
        let ringSpin = BG.hash(seed, 101) * .pi
        let fade = 1 - BG.smoothstep(life * 0.5, life, b)

        func position(_ direction: CGVector, _ speed: CGFloat, _ tau: CGFloat) -> CGPoint {
            let distance = speed * (1 - exp(-drag * tau)) / drag
            return CGPoint(
                x: apex.x + direction.dx * distance,
                y: apex.y + direction.dy * distance + 0.5 * gravity * tau * tau
            )
        }

        for i in 0..<count {
            let particleSeed = seed * 97 + i
            let angle = CGFloat(i) / CGFloat(count) * 2 * .pi + BG.hash(particleSeed, 102) * 0.08
            var direction = CGVector(dx: cos(angle), dy: sin(angle))
            var speed = baseSpeed
            if kind == 3 {
                // A tilted ring: squash then rotate the circle.
                let squashed = CGVector(dx: direction.dx, dy: direction.dy * ringTilt)
                direction = CGVector(
                    dx: squashed.dx * cos(ringSpin) - squashed.dy * sin(ringSpin),
                    dy: squashed.dx * sin(ringSpin) + squashed.dy * cos(ringSpin)
                )
            } else {
                speed *= BG.hash(particleSeed, 103, 0.62, 1)
            }

            var alpha = fade
            if kind == 4 {
                alpha *= sin(b * 38 + CGFloat(i) * 1.7) > 0 ? 1 : 0.15
            }
            guard alpha > 0.02 else { continue }

            let head = position(direction, speed, b)
            let tail = position(direction, speed, max(0, b - trail))
            let color = palette[i % 2 == 0 ? 0 : 1]
            var streak = Path()
            streak.move(to: tail)
            streak.addLine(to: head)
            ctx.stroke(
                streak,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0), color.opacity(Double(alpha) * 0.75)]),
                    startPoint: tail,
                    endPoint: head
                ),
                style: StrokeStyle(lineWidth: kind == 2 ? 1.6 : 2.2, lineCap: .round)
            )
            let hot = b < 0.3 ? Color.white : color
            ctx.fill(BG.circle(head, kind == 2 ? 1.8 : 2.4), with: .color(hot.opacity(Double(alpha))))
            if kind == 2 && b > life * 0.6 && BG.hash(particleSeed, 104) < 0.4 {
                ctx.sparkle(at: head, size: 4, color: BG.rgb(1, 0.9, 0.6), intensity: Double(alpha) * 0.8)
            }
        }
        // Lingering smoke where the shell burst.
        let smoke = BG.smoothstep(0.2, 1.2, b) * fade
        ctx.glow(at: CGPoint(x: apex.x, y: apex.y + b * 12), radius: 120, color: BG.rgb(0.75, 0.75, 0.85), intensity: Double(0.08 * smoke))
    }
}

// MARK: - October: Phase-accurate moon, bats, fog and jack-o'-lanterns

struct OctoberMoonBatsAnimation: View {
    let alpha: Double
    /// The day whose moon phase is shown (the user's current selection/focus).
    let moonDate: Date
    @State private var moonAnimator = MoonPhaseAnimator(duration: 2.5)
    @State private var flock = BatFlock()

    init(alpha: Double = 1.0, moonDate: Date = Date()) {
        self.alpha = alpha
        self.moonDate = moonDate
    }

    var body: some View {
        let targetPhase = MoonPhase.fraction(forDay: moonDate)
        let animator = moonAnimator
        let bats = flock
        AnimatedScene { ctx, size, time in
            let phase = animator.phase(target: targetPhase, time: time)
            OctoberScene.draw(in: &ctx, size: size, time: time, phase: phase, flock: bats)
        }
        .opacity(alpha)
    }
}

private enum OctoberScene {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, phase: Double, flock: BatFlock) {
        let t = CGFloat(time)
        AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.07, 0.05, 0.2), intensity: 0.32, depth: 0.65)
        AtmospherePainter.stars(in: &ctx, size: size, time: time, count: 110, skyFraction: 0.55, intensity: 0.8)

        // The moon swings slowly across the top of the sky (no wrap-around jump).
        let orbit = 2 * CGFloat.pi * t / 1500 + 0.95
        let moonRadius = min(size.width, size.height) * 0.075
        let moon = CGPoint(
            x: size.width * (0.5 + 0.33 * sin(orbit)),
            y: size.height * (0.17 - 0.035 * cos(orbit))
        )
        MoonPainter.draw(in: &ctx, center: moon, radius: moonRadius, phase: phase)

        drawClouds(in: &ctx, size: size, time: t, moon: moon, phase: phase)

        flock.step(time: time, size: size)
        for bat in flock.bats {
            let flap = sin(CGFloat(time * bat.flapRate) + bat.flapPhase)
            let bank = max(-0.5, min(0.5, bat.velocity.dy / 6))
            drawBat(in: &ctx, at: bat.position, size: bat.size, flap: flap, bank: bank, moon: moon)
        }

        let flicker = 0.78 + 0.12 * sin(t * 13) + 0.1 * sin(t * 23.7 + 1)
        drawPumpkin(in: &ctx, at: CGPoint(x: size.width * 0.055, y: size.height - 46), size: 78, flicker: flicker)
        drawPumpkin(in: &ctx, at: CGPoint(x: size.width * 0.94, y: size.height - 36), size: 58, flicker: 0.85 + 0.15 * sin(t * 17 + 2))
        drawFog(in: &ctx, size: size, time: t)
    }

    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, time t: CGFloat, moon: CGPoint, phase: Double) {
        let lit = MoonPhase.illumination(phase)
        let palette = CloudPalette(
            light: BG.rgb(0.55 + 0.35 * lit, 0.58 + 0.34 * lit, 0.7 + 0.28 * lit),
            body: CloudPalette.night.body,
            shade: CloudPalette.night.shade
        )
        for k in 0..<4 {
            let width = BG.hash(k, 171, 300, 460)
            let duration = BG.hash(k, 172, 70, 120)
            let progress = BG.fract(BG.hash(k, 173) + t / duration)
            let x = -width + progress * (size.width + width * 2)
            let y = size.height * BG.hash(k, 174, 0.08, 0.3)
            let edgeFade = BG.smoothstep(0, 0.12, progress) * (1 - BG.smoothstep(0.88, 1, progress))
            let center = CGPoint(x: x, y: y)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 200, width: width),
                center: center,
                width: width,
                palette: palette,
                opacity: Double(0.6 * edgeFade),
                lightDirection: CGVector(dx: moon.x - center.x, dy: moon.y - center.y),
                softness: 0.06
            )
        }
    }

    static func drawBat(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, flap: CGFloat, bank: CGFloat, moon: CGPoint) {
        var bat = ctx
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
        var ears = Path()
        ears.move(to: CGPoint(x: -0.05, y: -0.14))
        ears.addLine(to: CGPoint(x: -0.04, y: -0.24))
        ears.addLine(to: CGPoint(x: -0.012, y: -0.16))
        ears.move(to: CGPoint(x: 0.05, y: -0.14))
        ears.addLine(to: CGPoint(x: 0.04, y: -0.24))
        ears.addLine(to: CGPoint(x: 0.012, y: -0.16))
        silhouette.addPath(ears)

        bat.fill(silhouette, with: .color(BG.rgb(0.07, 0.05, 0.1, 0.92)))
        // Moonlit rim on the edges facing the moon.
        let toMoon = CGVector(dx: moon.x - p.x, dy: moon.y - p.y)
        let distance = max(1, sqrt(toMoon.dx * toMoon.dx + toMoon.dy * toMoon.dy))
        bat.stroke(
            silhouette,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.75, 0.8, 1, 0.45), BG.rgb(0.75, 0.8, 1, 0)]),
                startPoint: CGPoint(x: toMoon.dx / distance * 0.5, y: toMoon.dy / distance * 0.5),
                endPoint: .zero
            ),
            lineWidth: 0.025
        )
    }

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
            ctx.fill(
                rib,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 0.62, 0.15), BG.rgb(0.88, 0.4, 0.04), BG.rgb(0.5, 0.18, 0.02)]),
                    startPoint: CGPoint(x: p.x + offset - s * 0.25, y: p.y - s * 0.3),
                    endPoint: CGPoint(x: p.x + offset + s * 0.25, y: p.y + s * 0.35)
                )
            )
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
        let teeth = 6
        for i in 1...teeth {
            let x = mouthLeft + s * 0.48 * CGFloat(i) / CGFloat(teeth)
            face.addLine(to: CGPoint(x: x - s * 0.04, y: mouthTop + (i % 2 == 0 ? s * 0.05 : 0)))
        }
        face.addLine(to: CGPoint(x: p.x + s * 0.24, y: mouthTop))
        face.addQuadCurve(to: CGPoint(x: mouthLeft, y: mouthTop), control: CGPoint(x: p.x, y: mouthTop + s * 0.22))
        face.closeSubpath()
        ctx.fill(
            face,
            with: .radialGradient(
                Gradient(colors: [BG.rgb(1, 0.97, 0.7, Double(flicker)), BG.rgb(1, 0.6, 0.08, Double(flicker)), BG.rgb(0.7, 0.25, 0.02)]),
                center: CGPoint(x: p.x, y: p.y + s * 0.05),
                startRadius: 0,
                endRadius: s * 0.3
            )
        )
        ctx.stroke(face, with: .color(BG.rgb(0.4, 0.12, 0.0, 0.6)), lineWidth: s * 0.01)
    }

    static func drawFog(in ctx: inout GraphicsContext, size: CGSize, time t: CGFloat) {
        ctx.blurredLayer(radius: 24) { fog in
            for i in 0..<5 {
                let x = BG.wrap(BG.hash(i, 181) * size.width + t * BG.hash(i, 182, 6, 16), length: size.width, margin: size.width * 0.3)
                let y = size.height * BG.hash(i, 183, 0.94, 1.0)
                let rx = size.width * BG.hash(i, 184, 0.25, 0.4)
                let ry = size.height * BG.hash(i, 185, 0.04, 0.07)
                let center = CGPoint(x: x, y: y)
                fog.fill(
                    BG.ellipse(center, rx, ry),
                    with: .radialGradient(
                        Gradient(colors: [BG.rgb(0.72, 0.7, 0.85, 0.32), BG.rgb(0.72, 0.7, 0.85, 0)]),
                        center: center, startRadius: 0, endRadius: rx
                    )
                )
            }
        }
    }
}

/// Bat murmuration (boids), stepped once per rendered frame.
final class BatFlock {
    struct Bat {
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var flapRate: Double
        var flapPhase: CGFloat
    }

    private(set) var bats: [Bat] = []
    private var lastTime: Double?
    private var lastSize: CGSize = .zero

    func step(time: Double, size: CGSize) {
        if bats.isEmpty || size != lastSize {
            spawn(size: size)
            lastSize = size
            lastTime = time
            return
        }
        let dt = min(max(time - (lastTime ?? time), 0), 0.1)
        lastTime = time
        // Tuning below was authored for 0.03 s simulation ticks.
        let ticks = CGFloat(dt / 0.03)
        guard ticks > 0 else { return }

        let visualRange: CGFloat = 80
        let protectedRange: CGFloat = 25
        var centering: CGFloat = 0.005
        let avoid: CGFloat = 0.08
        var matching: CGFloat = 0.05
        let turn: CGFloat = 0.4
        let maxSpeed: CGFloat = 5
        let minSpeed: CGFloat = 2

        // Scatter for 5 s out of every 22 s, then regroup.
        if time.truncatingRemainder(dividingBy: 22) > 17 {
            centering = -0.002
            matching = 0
        }

        let snapshot = bats
        for i in bats.indices {
            var boid = bats[i]
            var closeDx: CGFloat = 0, closeDy: CGFloat = 0
            var velocityX: CGFloat = 0, velocityY: CGFloat = 0
            var positionX: CGFloat = 0, positionY: CGFloat = 0
            var neighbors: CGFloat = 0

            for (j, other) in snapshot.enumerated() where j != i {
                let dx = boid.position.x - other.position.x
                let dy = boid.position.y - other.position.y
                let distance = sqrt(dx * dx + dy * dy)
                if distance < protectedRange {
                    closeDx += dx
                    closeDy += dy
                }
                if distance < visualRange {
                    velocityX += other.velocity.dx
                    velocityY += other.velocity.dy
                    positionX += other.position.x
                    positionY += other.position.y
                    neighbors += 1
                }
            }

            boid.velocity.dx += closeDx * avoid * ticks
            boid.velocity.dy += closeDy * avoid * ticks
            if neighbors > 0 {
                boid.velocity.dx += (velocityX / neighbors - boid.velocity.dx) * matching * ticks
                boid.velocity.dy += (velocityY / neighbors - boid.velocity.dy) * matching * ticks
                boid.velocity.dx += (positionX / neighbors - boid.position.x) * centering * ticks
                boid.velocity.dy += (positionY / neighbors - boid.position.y) * centering * ticks
            }

            let margin: CGFloat = 50
            if boid.position.x < margin { boid.velocity.dx += turn * ticks }
            if boid.position.x > size.width - margin { boid.velocity.dx -= turn * ticks }
            if boid.position.y < margin + 50 { boid.velocity.dy += turn * ticks }
            if boid.position.y > size.height * 0.7 { boid.velocity.dy -= turn * ticks }

            let speed = sqrt(boid.velocity.dx * boid.velocity.dx + boid.velocity.dy * boid.velocity.dy)
            if speed > maxSpeed {
                boid.velocity.dx = boid.velocity.dx / speed * maxSpeed
                boid.velocity.dy = boid.velocity.dy / speed * maxSpeed
            } else if speed < minSpeed && speed > 0 {
                boid.velocity.dx = boid.velocity.dx / speed * minSpeed
                boid.velocity.dy = boid.velocity.dy / speed * minSpeed
            }

            boid.position.x += boid.velocity.dx * ticks
            boid.position.y += boid.velocity.dy * ticks
            bats[i] = boid
        }
    }

    private func spawn(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        bats = (0..<Int.random(in: 10...20)).map { _ in
            Bat(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: size.height * 0.2...size.height * 0.6)
                ),
                velocity: CGVector(dx: CGFloat.random(in: -3...3), dy: CGFloat.random(in: -1...1)),
                size: CGFloat.random(in: 30...52),
                flapRate: Double.random(in: 13...19),
                flapPhase: CGFloat.random(in: 0...(2 * .pi))
            )
        }
    }
}
