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

// MARK: - January: Snowfall

struct JanuarySnowAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.78, 0.88, 1), intensity: 0.22, depth: 0.45)
            SnowRenderer.draw(in: &ctx, size: size, time: time, density: 1, wind: CGFloat(sin(time * 0.05)) * 0.6)
            SnowRenderer.drawSnowbank(in: &ctx, size: size, time: time, height: size.height * 0.045)
        }
        .opacity(alpha)
    }
}

// MARK: - February: Heart clouds and floating hearts

struct FebruaryHeartCloudsAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.78, 0.88), intensity: 0.2, depth: 0.5)
            SnowRenderer.draw(in: &ctx, size: size, time: time, density: 0.4)
            FebruaryScene.drawClouds(in: &ctx, size: size, time: time)
            FebruaryScene.drawHearts(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum FebruaryScene {
    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for k in 0..<5 {
            let width = BG.hash(k, 21, 170, 250)
            let duration = BG.hash(k, 22, 100, 160)
            let span = size.width + width * 2
            var u = BG.fract(BG.hash(k, 23) + t / duration)
            if k % 2 == 1 { u = 1 - u }
            let x = u * span - width
            let y = size.height * BG.hash(k, 24, 0.12, 0.6) + sin(t * 0.25 + CGFloat(k) * 1.3) * 24
            let isHeart = k % 2 == 0
            let puffs = isHeart
                ? CloudPainter.heartPuffs(seed: k, width: width)
                : CloudPainter.cumulusPuffs(seed: k + 50, width: width * 1.25)
            CloudPainter.draw(
                in: &ctx,
                puffs: puffs,
                center: CGPoint(x: x, y: y),
                width: width,
                palette: .blush,
                opacity: 0.85
            )
        }
    }

    static func drawHearts(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for i in 0..<16 {
            let heartSize = BG.hash(i, 31, 16, 46)
            let depth = (heartSize - 16) / 30 // 0 far ... 1 near
            let speed = BG.lerp(14, 34, depth)
            let span = size.height + 140
            let progress = BG.fract(BG.hash(i, 33) + t * speed / span)
            let y = size.height + 70 - progress * span
            let x = BG.hash(i, 34) * size.width + sin(t * 0.6 + CGFloat(i)) * 34
            let flip = cos(t * BG.hash(i, 35, 0.5, 1.2) + BG.hash(i, 36) * 6.28)
            let tilt = sin(t * 0.8 + CGFloat(i)) * 0.25
            let fade = BG.smoothstep(0, 0.1, progress) * (1 - BG.smoothstep(0.82, 1, progress))
            let opacity = Double(fade * BG.lerp(0.55, 0.95, depth))
            drawHeart(in: &ctx, at: CGPoint(x: x, y: y), size: heartSize, rotation: Double(tilt), flip: flip, opacity: opacity)
        }
    }

    static func drawHeart(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, opacity: Double) {
        guard opacity > 0.01 else { return }
        ctx.glow(at: p, radius: size * 1.2, color: BG.rgb(1, 0.4, 0.6), intensity: 0.25 * opacity)

        var heart = ctx
        heart.opacity = opacity
        heart.translateBy(x: p.x, y: p.y)
        heart.rotate(by: .radians(rotation))
        heart.scaleBy(x: size * max(abs(flip), 0.08), y: size)

        let front = flip >= 0
        let colors = front
            ? [BG.rgb(1, 0.5, 0.64), BG.rgb(0.92, 0.16, 0.32), BG.rgb(0.62, 0.02, 0.18)]
            : [BG.rgb(0.75, 0.14, 0.3), BG.rgb(0.5, 0.03, 0.16)]
        heart.fill(
            HeartGeometry.unitPath,
            with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: -0.4, y: -0.45), endPoint: CGPoint(x: 0.35, y: 0.5))
        )
        heart.stroke(HeartGeometry.unitPath, with: .color(.white.opacity(0.18)), lineWidth: 0.03)
        if front {
            let gloss = BG.ellipse(.zero, 0.12, 0.065)
                .applying(CGAffineTransform(rotationAngle: -0.6).concatenating(CGAffineTransform(translationX: -0.2, y: -0.22)))
            heart.fill(gloss, with: .color(.white.opacity(0.6)))
            heart.fill(BG.circle(CGPoint(x: -0.06, y: -0.3), 0.025), with: .color(.white.opacity(0.7)))
        }
    }
}

// MARK: - March: Shamrocks on rolling hills

struct MarchShamrocksAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.75, 0.95, 0.7), intensity: 0.18, depth: 0.35)
            MarchScene.drawSparkles(in: &ctx, size: size, time: time)
            MarchScene.drawHill(in: &ctx, size: size, layer: 0)
            MarchScene.drawHill(in: &ctx, size: size, layer: 1)
            MarchScene.drawShamrocks(in: &ctx, size: size, time: time, layer: 1)
            MarchScene.drawHill(in: &ctx, size: size, layer: 2)
            MarchScene.drawShamrocks(in: &ctx, size: size, time: time, layer: 2)
        }
        .opacity(alpha)
    }
}

private enum MarchScene {
    static func hillY(layer: Int, x: CGFloat, size: CGSize) -> CGFloat {
        let heights: [CGFloat] = [0.1, 0.072, 0.042]
        let u = x / max(size.width, 1)
        let l = CGFloat(layer)
        let broad: CGFloat = 0.55 * sin(u * 3.1 + l * 1.7)
        let rolling: CGFloat = 0.3 * sin(u * 7.3 + l * 0.6)
        let bumps: CGFloat = 0.15 * sin(u * 15 + l * 2.9)
        let wave = broad + rolling + bumps
        return size.height - size.height * heights[layer] * (0.78 + 0.3 * wave)
    }

    static func drawHill(in ctx: inout GraphicsContext, size: CGSize, layer: Int) {
        let tops: [Color] = [BG.rgb(0.62, 0.82, 0.6), BG.rgb(0.42, 0.76, 0.4), BG.rgb(0.32, 0.7, 0.3)]
        let bottoms: [Color] = [BG.rgb(0.38, 0.62, 0.42), BG.rgb(0.18, 0.48, 0.22), BG.rgb(0.08, 0.36, 0.12)]
        let opacities: [Double] = [0.45, 0.6, 0.78]

        var ridge = Path()
        var fill = Path()
        fill.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        var highest = size.height
        while x <= size.width + 16 {
            let y = hillY(layer: layer, x: x, size: size)
            highest = min(highest, y)
            if x == 0 { ridge.move(to: CGPoint(x: x, y: y)) } else { ridge.addLine(to: CGPoint(x: x, y: y)) }
            fill.addLine(to: CGPoint(x: x, y: y))
            x += 16
        }
        fill.addLine(to: CGPoint(x: size.width + 16, y: size.height))
        fill.closeSubpath()

        var hill = ctx
        hill.opacity = opacities[layer]
        hill.fill(
            fill,
            with: .linearGradient(
                Gradient(colors: [tops[layer], bottoms[layer]]),
                startPoint: CGPoint(x: 0, y: highest),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        hill.stroke(ridge, with: .color(BG.rgb(0.85, 1, 0.75, 0.55)), lineWidth: 2)
    }

    static func drawShamrocks(in ctx: inout GraphicsContext, size: CGSize, time: Double, layer: Int) {
        let t = CGFloat(time)
        let slots = 10
        let period: CGFloat = 24
        let scale: CGFloat = layer == 2 ? 1 : 0.72
        for s in 0..<slots where (s % 2 == 0) == (layer == 2) {
            let cyclePosition = t / period + BG.hash(s, 41)
            let cycle = Int(floor(cyclePosition))
            let life = BG.fract(cyclePosition)
            let seed = s * 977 + cycle
            let x = (CGFloat(s) + 0.15 + 0.7 * BG.hash(seed, 42)) / CGFloat(slots) * size.width
            let groundY = hillY(layer: layer, x: x, size: size) + 6

            let grow = BG.easeInOut(BG.smoothstep(0, 0.22, life))
            let unfurl = BG.easeInOut(BG.smoothstep(0.15, 0.38, life))
            let wilt = BG.smoothstep(0.82, 1, life)
            let opacity = Double(1 - wilt)
            guard grow > 0.01, opacity > 0.01 else { continue }

            let lean: CGFloat = BG.hash(seed, 46) > 0.5 ? 1 : -1
            let stemHeight = BG.hash(seed, 44, 55, 95) * scale * grow * (1 - wilt * 0.3)
            let sway = sin(t * 0.9 + CGFloat(s)) * 6 * grow + wilt * 22 * lean
            let top = CGPoint(x: x + sway, y: groundY - stemHeight)

            var plant = ctx
            plant.opacity = opacity

            var stem = Path()
            stem.move(to: CGPoint(x: x, y: groundY))
            stem.addQuadCurve(to: top, control: CGPoint(x: x + sway * 0.2 + 8 * lean, y: groundY - stemHeight * 0.5))
            plant.stroke(
                stem,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.45, 0.8, 0.4), BG.rgb(0.12, 0.42, 0.16)]),
                    startPoint: top,
                    endPoint: CGPoint(x: x, y: groundY)
                ),
                style: StrokeStyle(lineWidth: 3.2 * scale, lineCap: .round)
            )

            let leafSize = BG.hash(seed, 45, 22, 32) * scale * unfurl
            guard leafSize > 0.5 else { continue }
            let fourLeaf = BG.hash(seed, 43) < 0.22
            if fourLeaf {
                plant.glow(at: top, radius: leafSize * 2.6, color: BG.rgb(1, 0.85, 0.3), intensity: 0.4, additive: true)
                let orbit = t * 1.4 + CGFloat(s)
                let sparklePoint = CGPoint(x: top.x + cos(orbit) * leafSize * 1.3, y: top.y + sin(orbit) * leafSize * 1.1)
                plant.sparkle(at: sparklePoint, size: 7, color: BG.rgb(1, 0.92, 0.55), intensity: 0.9)
            }
            let count = fourLeaf ? 4 : 3
            for j in 0..<count {
                let angle = -CGFloat.pi / 2 + CGFloat(j) * 2 * .pi / CGFloat(count) + sin(t * 0.7 + CGFloat(s)) * 0.08
                let spread = leafSize * 0.48
                let center = CGPoint(x: top.x + cos(angle) * spread, y: top.y + sin(angle) * spread)
                drawLeaflet(in: &plant, at: center, size: leafSize, rotation: Double(angle + .pi / 2), unfurl: unfurl)
            }
        }
    }

    static func drawLeaflet(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, unfurl: CGFloat) {
        var leaf = ctx
        leaf.translateBy(x: p.x, y: p.y)
        leaf.rotate(by: .radians(rotation))
        leaf.scaleBy(x: size * (0.4 + 0.6 * unfurl), y: size)
        leaf.fill(
            HeartGeometry.unitPath,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.58, 0.92, 0.45), BG.rgb(0.22, 0.66, 0.26), BG.rgb(0.07, 0.4, 0.15)]),
                startPoint: CGPoint(x: -0.3, y: -0.45),
                endPoint: CGPoint(x: 0.2, y: 0.5)
            )
        )
        var midrib = Path()
        midrib.move(to: CGPoint(x: 0, y: 0.45))
        midrib.addLine(to: CGPoint(x: 0, y: -0.28))
        leaf.stroke(midrib, with: .color(BG.rgb(0.8, 1, 0.7, 0.55)), lineWidth: 0.03)
        // Pale chevron that clover leaflets carry.
        var chevron = Path()
        chevron.move(to: CGPoint(x: -0.24, y: -0.1))
        chevron.addLine(to: CGPoint(x: 0, y: 0.1))
        chevron.addLine(to: CGPoint(x: 0.24, y: -0.1))
        leaf.stroke(chevron, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.05, lineCap: .round, lineJoin: .round))
        leaf.fill(BG.ellipse(CGPoint(x: -0.18, y: -0.22), 0.08, 0.04), with: .color(.white.opacity(0.35)))
    }

    static func drawSparkles(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for i in 0..<26 {
            let speed = BG.hash(i, 51, 10, 24)
            let span = size.height * 0.9
            let progress = BG.fract(BG.hash(i, 52) + t * speed / span)
            let y = size.height - progress * span
            let x = BG.hash(i, 53) * size.width + sin(t * 0.5 + CGFloat(i)) * 22
            let twinkle = pow(max(0, sin(t * BG.hash(i, 54, 1, 2.5) + BG.hash(i, 55) * 6.28)), 3)
            let fade = BG.smoothstep(0, 0.15, progress) * (1 - BG.smoothstep(0.75, 1, progress))
            let intensity = Double(twinkle * fade)
            ctx.glow(at: CGPoint(x: x, y: y), radius: 14, color: BG.rgb(1, 0.85, 0.35), intensity: intensity * 0.5)
            ctx.sparkle(at: CGPoint(x: x, y: y), size: BG.hash(i, 56, 4, 8), color: BG.rgb(1, 0.92, 0.6), intensity: intensity)
        }
    }
}

// MARK: - April: Storm clouds, wind-driven rain, splashes and lightning

struct AprilRainAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            let flash = AprilScene.lightning(time: time)
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.3, 0.35, 0.46), intensity: 0.26, depth: 0.5)
            AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.6, 0.7, 0.82), intensity: 0.16, depth: 0.2)
            if flash.intensity > 0.01 {
                AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.9, 0.93, 1), intensity: 0.35 * Double(flash.intensity), depth: 0.7)
                AprilScene.drawBolt(in: &ctx, size: size, seed: flash.cycle, intensity: flash.intensity)
            }
            AprilScene.drawClouds(in: &ctx, size: size, time: time, flash: flash.intensity)
            AprilScene.drawRain(in: &ctx, size: size, time: time)
            AprilScene.drawSplashes(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum AprilScene {
    static func wind(_ t: CGFloat) -> CGFloat {
        0.2 + 0.1 * sin(t * 0.11) + 0.05 * sin(t * 0.37 + 1)
    }

    /// Occasional distant lightning: a bright strike followed by a weaker re-strike.
    static func lightning(time: Double) -> (intensity: CGFloat, cycle: Int) {
        let period: CGFloat = 17
        let position = CGFloat(time) / period + 0.35
        let cycle = Int(floor(position))
        guard BG.hash(cycle, 66) < 0.7 else { return (0, cycle) }
        let local = BG.fract(position) * period
        var intensity: CGFloat = 0
        if local < 0.16 {
            intensity = 1 - local / 0.16
        } else if local > 0.26 && local < 0.62 {
            intensity = 0.7 * (1 - (local - 0.26) / 0.36)
        }
        return (intensity, cycle)
    }

    static func drawBolt(in ctx: inout GraphicsContext, size: CGSize, seed: Int, intensity: CGFloat) {
        var bolt = Path()
        var p = CGPoint(x: size.width * BG.hash(seed, 67, 0.15, 0.85), y: size.height * 0.02)
        bolt.move(to: p)
        let segments = 9
        for i in 0..<segments {
            p.x += BG.hash(seed * 31 + i, 68, -38, 38)
            p.y += size.height * 0.32 / CGFloat(segments)
            bolt.addLine(to: p)
        }
        ctx.blurredLayer(radius: 10) { glow in
            glow.stroke(bolt, with: .color(BG.rgb(0.75, 0.82, 1, Double(intensity))), lineWidth: 10)
        }
        ctx.stroke(bolt, with: .color(.white.opacity(Double(intensity))), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
    }

    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, time: Double, flash: CGFloat) {
        let t = CGFloat(time)
        for k in 0..<7 {
            let width = BG.lerp(340, 540, CGFloat(k) / 6) * BG.hash(k, 61, 0.9, 1.1)
            let speed = BG.hash(k, 62, 6, 14)
            let x = BG.wrap(BG.hash(k, 63) * size.width + t * speed, length: size.width, margin: width * 0.7)
            let y = size.height * BG.hash(k, 64, -0.02, 0.07)
            let center = CGPoint(x: x, y: y)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 300, width: width),
                center: center,
                width: width,
                palette: .storm,
                opacity: 0.8,
                lightDirection: CGVector(dx: 0.2, dy: -1)
            )
            if flash > 0.01 {
                ctx.glow(at: center, radius: width * 0.7, color: BG.rgb(0.85, 0.9, 1), intensity: Double(flash) * 0.45, additive: true)
            }
        }
    }

    static func drawRain(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let slant = wind(t)
        let norm = sqrt(1 + slant * slant)
        let direction = CGVector(dx: slant / norm, dy: 1 / norm)

        struct Layer {
            let count: Int, length: ClosedRange<CGFloat>, speed: ClosedRange<CGFloat>, width: CGFloat, opacity: Double, salt: Int
        }
        let layers = [
            Layer(count: 150, length: 10...16, speed: 700...900, width: 1, opacity: 0.32, salt: 0),
            Layer(count: 90, length: 20...30, speed: 950...1200, width: 1.5, opacity: 0.48, salt: 1000),
            Layer(count: 22, length: 46...70, speed: 1500...1800, width: 2.6, opacity: 0.4, salt: 2000)
        ]

        func drawLayer(_ layer: Layer, in target: inout GraphicsContext) {
            for i in 0..<layer.count {
                let seed = i + layer.salt
                let length = BG.hash(seed, 1, layer.length.lowerBound, layer.length.upperBound)
                let speed = BG.hash(seed, 2, layer.speed.lowerBound, layer.speed.upperBound)
                let span = size.height + length + 60
                let progress = BG.fract(BG.hash(seed, 3) + t * speed / span)
                let headY = progress * span - length - 20
                let headX = BG.wrap(BG.hash(seed, 4) * size.width + headY * slant, length: size.width, margin: 60)
                let head = CGPoint(x: headX, y: headY)
                let tail = CGPoint(x: headX - direction.dx * length, y: headY - direction.dy * length)
                var streak = Path()
                streak.move(to: tail)
                streak.addLine(to: head)
                target.stroke(
                    streak,
                    with: .linearGradient(
                        Gradient(colors: [BG.rgb(0.75, 0.85, 1, 0), BG.rgb(0.85, 0.92, 1, layer.opacity)]),
                        startPoint: tail,
                        endPoint: head
                    ),
                    style: StrokeStyle(lineWidth: layer.width, lineCap: .round)
                )
            }
        }

        drawLayer(layers[0], in: &ctx)
        drawLayer(layers[1], in: &ctx)
        ctx.blurredLayer(radius: 2.5) { near in
            drawLayer(layers[2], in: &near)
        }
    }

    static func drawSplashes(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for i in 0..<34 {
            let period = BG.hash(i, 71, 0.7, 1.4)
            let position = t / period + BG.hash(i, 72)
            let cycle = Int(floor(position))
            let life = BG.fract(position)
            let seed = i * 131 + cycle
            let depth = BG.hash(seed, 75)
            let x = BG.hash(seed, 73) * size.width
            let y = size.height - 4 - depth * size.height * 0.07
            let scale = BG.lerp(1, 0.55, depth)
            let fade = Double(1 - life)

            let radius = (3 + life * 16) * scale
            ctx.stroke(BG.ellipse(CGPoint(x: x, y: y), radius, radius * 0.28), with: .color(BG.rgb(0.88, 0.94, 1, 0.55 * fade)), lineWidth: 1.2)
            for d in 0..<3 {
                let spread = (CGFloat(d) - 1) * life * 12 * scale
                let hop = sin(life * .pi) * (8 + CGFloat(d % 2) * 6) * scale
                ctx.fill(BG.circle(CGPoint(x: x + spread, y: y - hop), 1.4 * scale), with: .color(.white.opacity(0.6 * fade)))
            }
        }
    }
}

// MARK: - May: Meadow of blooming flowers

struct MayFlowersAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            ctx.glow(at: CGPoint(x: size.width * 0.92, y: -size.height * 0.05), radius: size.width * 0.5, color: BG.rgb(1, 0.95, 0.78), intensity: 0.22)
            MayScene.drawPollen(in: &ctx, size: size, time: time)
            MayScene.drawGrass(in: &ctx, size: size, time: time, row: 0)
            MayScene.drawFlowers(in: &ctx, size: size, time: time)
            MayScene.drawGrass(in: &ctx, size: size, time: time, row: 1)
            MayScene.drawDriftingPetals(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum MayScene {
    struct FlowerKind {
        let petals: Int
        let petalWidth: CGFloat
        let petalLength: CGFloat
        let inner: Color
        let outer: Color
        let center: Color
        let centerRim: Color
        let tulip: Bool
    }

    static let kinds: [FlowerKind] = [
        // Daisy
        FlowerKind(petals: 14, petalWidth: 0.15, petalLength: 0.5, inner: BG.rgb(0.9, 0.9, 0.98), outer: .white,
                   center: BG.rgb(1, 0.85, 0.2), centerRim: BG.rgb(0.85, 0.5, 0.05), tulip: false),
        // Cosmos
        FlowerKind(petals: 8, petalWidth: 0.26, petalLength: 0.5, inner: BG.rgb(0.75, 0.1, 0.45), outer: BG.rgb(1, 0.7, 0.85),
                   center: BG.rgb(1, 0.85, 0.25), centerRim: BG.rgb(0.8, 0.5, 0.1), tulip: false),
        // Poppy
        FlowerKind(petals: 5, petalWidth: 0.4, petalLength: 0.48, inner: BG.rgb(0.7, 0.03, 0.05), outer: BG.rgb(1, 0.35, 0.18),
                   center: BG.rgb(0.15, 0.1, 0.12), centerRim: BG.rgb(0.05, 0.02, 0.05), tulip: false),
        // Tulip (pink)
        FlowerKind(petals: 3, petalWidth: 0.3, petalLength: 0.62, inner: BG.rgb(0.78, 0.1, 0.35), outer: BG.rgb(1, 0.6, 0.72),
                   center: .clear, centerRim: .clear, tulip: true),
        // Tulip (golden)
        FlowerKind(petals: 3, petalWidth: 0.3, petalLength: 0.62, inner: BG.rgb(0.92, 0.5, 0.05), outer: BG.rgb(1, 0.92, 0.4),
                   center: .clear, centerRim: .clear, tulip: true),
        // Violet
        FlowerKind(petals: 6, petalWidth: 0.3, petalLength: 0.45, inner: BG.rgb(0.35, 0.12, 0.6), outer: BG.rgb(0.75, 0.6, 1),
                   center: BG.rgb(1, 0.95, 0.6), centerRim: BG.rgb(0.9, 0.7, 0.2), tulip: false)
    ]

    static func drawGrass(in ctx: inout GraphicsContext, size: CGSize, time: Double, row: Int) {
        let t = CGFloat(time)
        let count = row == 0 ? 170 : 130
        let baseHeight = size.height * (row == 0 ? 0.08 : 0.055)
        var blades = Path()
        for i in 0..<count {
            let seed = i + row * 500
            let x = (CGFloat(i) + BG.hash(seed, 71)) / CGFloat(count) * (size.width + 20) - 10
            let h = baseHeight * BG.hash(seed, 72, 0.55, 1.25)
            let w = BG.hash(seed, 73, 3, 6.5)
            let gust = sin(t * 1.1 + x * 0.012 + CGFloat(row)) * 0.6 + sin(t * 2.3 + x * 0.03) * 0.2
            let bend = (gust + 0.25) * h * 0.35
            let tip = CGPoint(x: x + bend, y: size.height - h)
            blades.move(to: CGPoint(x: x - w / 2, y: size.height))
            blades.addQuadCurve(to: tip, control: CGPoint(x: x - w * 0.2 + bend * 0.3, y: size.height - h * 0.55))
            blades.addQuadCurve(to: CGPoint(x: x + w / 2, y: size.height), control: CGPoint(x: x + w * 0.3 + bend * 0.35, y: size.height - h * 0.5))
            blades.closeSubpath()
        }
        var grass = ctx
        grass.opacity = row == 0 ? 0.6 : 0.9
        let tipColor = row == 0 ? BG.rgb(0.6, 0.82, 0.45) : BG.rgb(0.55, 0.88, 0.35)
        let baseColor = row == 0 ? BG.rgb(0.2, 0.42, 0.22) : BG.rgb(0.1, 0.38, 0.12)
        grass.fill(
            blades,
            with: .linearGradient(
                Gradient(colors: [tipColor, baseColor]),
                startPoint: CGPoint(x: 0, y: size.height - baseHeight * 1.25),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    static func drawFlowers(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let slots = 9
        let period: CGFloat = 28
        for s in 0..<slots {
            let position = t / period + BG.hash(s, 81)
            let cycle = Int(floor(position))
            let life = BG.fract(position)
            let seed = s * 613 + cycle
            let kind = kinds[Int(BG.hash(seed, 82) * CGFloat(kinds.count)) % kinds.count]
            let x = (CGFloat(s) + 0.15 + 0.7 * BG.hash(seed, 83)) / CGFloat(slots) * size.width
            let groundY = size.height + 4

            let grow = BG.easeInOut(BG.smoothstep(0, 0.2, life))
            let bloom = BG.easeInOut(BG.smoothstep(0.16, 0.36, life))
            let fade = BG.smoothstep(0.85, 1, life)
            let opacity = Double(1 - fade)
            guard grow > 0.01, opacity > 0.01 else { continue }

            let stemHeight = BG.hash(seed, 84, 80, 150) * grow
            let sway = sin(t * 0.8 + CGFloat(s) * 1.7) * 7 * grow
            let head = CGPoint(x: x + sway, y: groundY - stemHeight)
            var plant = ctx
            plant.opacity = opacity

            var stem = Path()
            stem.move(to: CGPoint(x: x, y: groundY))
            stem.addQuadCurve(to: head, control: CGPoint(x: x - sway * 0.3, y: groundY - stemHeight * 0.5))
            plant.stroke(
                stem,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(0.5, 0.82, 0.38), BG.rgb(0.15, 0.45, 0.15)]),
                    startPoint: head,
                    endPoint: CGPoint(x: x, y: groundY)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            // Leaf on the stem.
            let leafPoint = CGPoint(x: x - sway * 0.05, y: groundY - stemHeight * 0.35)
            drawStemLeaf(in: &plant, at: leafPoint, size: 34 * grow, rotation: BG.hash(seed, 85) > 0.5 ? 0.9 : -0.9)

            let radius = BG.hash(seed, 86, 26, 40) * (0.35 + 0.65 * bloom)
            plant.glow(at: head, radius: radius * 1.9, color: kind.outer, intensity: 0.22 * Double(bloom))
            if kind.tulip {
                drawTulip(in: &plant, at: head, radius: radius, kind: kind, bloom: bloom)
            } else {
                drawRadialFlower(in: &plant, at: head, radius: radius, kind: kind, bloom: bloom, spin: Double(sin(t * 0.3 + CGFloat(s)) * 0.06))
            }
        }
    }

    static func drawStemLeaf(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double) {
        guard size > 1 else { return }
        var leaf = ctx
        leaf.translateBy(x: p.x, y: p.y)
        leaf.rotate(by: .radians(rotation))
        leaf.translateBy(x: 0, y: -size * 0.45)
        leaf.scaleBy(x: size * 0.6, y: size)
        leaf.fill(
            LeafPainter.oval,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.55, 0.88, 0.4), BG.rgb(0.12, 0.45, 0.15)]),
                startPoint: CGPoint(x: -0.3, y: -0.5),
                endPoint: CGPoint(x: 0.3, y: 0.4)
            )
        )
        leaf.stroke(LeafPainter.ovalVeins, with: .color(BG.rgb(0.8, 1, 0.7, 0.45)), lineWidth: 0.03)
    }

    static func drawRadialFlower(in ctx: inout GraphicsContext, at p: CGPoint, radius r: CGFloat, kind: FlowerKind, bloom: CGFloat, spin: Double) {
        var head = ctx
        head.translateBy(x: p.x, y: p.y)
        head.scaleBy(x: 1, y: 0.82) // Seen slightly from the front.
        head.rotate(by: .radians(spin))

        let openness = 0.35 + 0.65 * bloom
        for i in 0..<kind.petals {
            let angle = CGFloat(i) / CGFloat(kind.petals) * 2 * .pi
            var petal = head
            petal.rotate(by: .radians(Double(angle)))
            petal.scaleBy(x: r, y: r * openness)
            let shape = BG.ellipse(CGPoint(x: 0, y: -kind.petalLength * 0.55), kind.petalWidth, kind.petalLength * 0.55)
            petal.fill(
                shape,
                with: .linearGradient(
                    Gradient(colors: [kind.inner, kind.outer]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: -kind.petalLength * 1.05)
                )
            )
            petal.stroke(shape, with: .color(kind.inner.opacity(0.35)), lineWidth: 0.012)
            // Central crease on each petal.
            var crease = Path()
            crease.move(to: CGPoint(x: 0, y: -0.05))
            crease.addLine(to: CGPoint(x: 0, y: -kind.petalLength * 0.9))
            petal.stroke(crease, with: .color(.white.opacity(0.25)), lineWidth: 0.012)
        }

        let centerRadius = r * 0.22
        head.fill(
            BG.circle(.zero, centerRadius),
            with: .radialGradient(
                Gradient(colors: [kind.center, kind.centerRim]),
                center: CGPoint(x: -centerRadius * 0.3, y: -centerRadius * 0.3),
                startRadius: 0,
                endRadius: centerRadius * 1.3
            )
        )
        for i in 0..<10 {
            let a = CGFloat(i) / 10 * 2 * .pi
            let dot = CGPoint(x: cos(a) * centerRadius * 0.65, y: sin(a) * centerRadius * 0.65)
            head.fill(BG.circle(dot, centerRadius * 0.12), with: .color(kind.centerRim.opacity(0.8)))
        }
        head.fill(BG.circle(CGPoint(x: -centerRadius * 0.3, y: -centerRadius * 0.35), centerRadius * 0.25), with: .color(.white.opacity(0.35)))
    }

    static func drawTulip(in ctx: inout GraphicsContext, at p: CGPoint, radius r: CGFloat, kind: FlowerKind, bloom: CGFloat) {
        var head = ctx
        head.translateBy(x: p.x, y: p.y)
        head.scaleBy(x: r, y: r)
        let spread = 0.12 + 0.3 * bloom
        let angles: [CGFloat] = [-spread, spread, 0]
        for (index, angle) in angles.enumerated() {
            var petal = head
            petal.rotate(by: .radians(Double(angle)))
            let shape = BG.ellipse(CGPoint(x: 0, y: -0.42), kind.petalWidth, kind.petalLength * 0.62)
            let front = index == 2
            petal.fill(
                shape,
                with: .linearGradient(
                    Gradient(colors: front ? [kind.outer, kind.inner] : [kind.outer.opacity(0.9), kind.inner.opacity(0.9)]),
                    startPoint: CGPoint(x: 0, y: -0.95),
                    endPoint: CGPoint(x: 0, y: 0.1)
                )
            )
            petal.stroke(shape, with: .color(kind.inner.opacity(0.4)), lineWidth: 0.02)
            if front {
                petal.fill(BG.ellipse(CGPoint(x: -0.1, y: -0.55), 0.05, 0.18), with: .color(.white.opacity(0.35)))
            }
        }
    }

    static func drawDriftingPetals(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let colors = [BG.rgb(1, 0.75, 0.85), BG.rgb(1, 0.92, 0.95), BG.rgb(0.95, 0.6, 0.8)]
        for i in 0..<14 {
            let speed = BG.hash(i, 91, 35, 70)
            let span = size.width + 120
            let progress = BG.fract(BG.hash(i, 92) + t * speed / span)
            let x = progress * span - 60
            let y = size.height * BG.hash(i, 93, 0.2, 0.75) + sin(t * 0.9 + CGFloat(i)) * 40
            let flip = cos(t * BG.hash(i, 94, 1, 2.4) + CGFloat(i))
            let petalSize = BG.hash(i, 95, 10, 18)
            var petal = ctx
            petal.translateBy(x: x, y: y)
            petal.rotate(by: .radians(Double(t * 0.8 + CGFloat(i))))
            petal.scaleBy(x: petalSize * max(abs(flip), 0.1), y: petalSize)
            let color = colors[i % colors.count]
            petal.fill(
                BG.ellipse(.zero, 0.32, 0.5),
                with: .linearGradient(
                    Gradient(colors: [color, color.opacity(flip < 0 ? 0.55 : 0.8)]),
                    startPoint: CGPoint(x: 0, y: -0.5),
                    endPoint: CGPoint(x: 0, y: 0.5)
                )
            )
        }
    }

    static func drawPollen(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for i in 0..<32 {
            let x = BG.wrap(BG.hash(i, 97) * size.width + t * BG.hash(i, 98, 4, 14) + sin(t * 0.4 + CGFloat(i)) * 30, length: size.width, margin: 20)
            let y = size.height * BG.hash(i, 99, 0.15, 0.85) + sin(t * 0.3 + CGFloat(i) * 2) * 26
            let pulse = 0.5 + 0.5 * sin(t * BG.hash(i, 100, 0.8, 1.8) + CGFloat(i))
            ctx.glow(at: CGPoint(x: x, y: y), radius: 9, color: BG.rgb(1, 0.92, 0.55), intensity: Double(0.45 * pulse), additive: true)
            ctx.fill(BG.circle(CGPoint(x: x, y: y), 1.4), with: .color(BG.rgb(1, 0.95, 0.7, Double(0.6 + 0.4 * pulse))))
        }
    }
}

// MARK: - June: Butterflies in sunbeams

struct JuneButterfliesAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            JuneScene.drawSunbeams(in: &ctx, size: size, time: time)
            JuneScene.drawBokeh(in: &ctx, size: size, time: time)
            JuneScene.drawButterflies(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum JuneScene {
    struct Species {
        let base: Color
        let bright: Color
        let border: Color
        let spots: Color
        let eyespot: Bool
        let iridescent: Bool
    }

    static let species: [Species] = [
        // Monarch
        Species(base: BG.rgb(0.85, 0.35, 0.02), bright: BG.rgb(1, 0.62, 0.12), border: BG.rgb(0.08, 0.05, 0.04), spots: .white, eyespot: false, iridescent: false),
        // Blue morpho
        Species(base: BG.rgb(0.0, 0.25, 0.75), bright: BG.rgb(0.25, 0.85, 1), border: BG.rgb(0.04, 0.05, 0.12), spots: BG.rgb(0.85, 0.95, 1), eyespot: false, iridescent: true),
        // Swallowtail
        Species(base: BG.rgb(0.95, 0.78, 0.1), bright: BG.rgb(1, 0.95, 0.5), border: BG.rgb(0.1, 0.08, 0.05), spots: BG.rgb(0.4, 0.6, 1), eyespot: true, iridescent: false),
        // Peacock
        Species(base: BG.rgb(0.55, 0.06, 0.12), bright: BG.rgb(0.9, 0.25, 0.25), border: BG.rgb(0.2, 0.08, 0.06), spots: BG.rgb(1, 0.9, 0.5), eyespot: true, iridescent: false),
        // Emerald swallowtail
        Species(base: BG.rgb(0.02, 0.32, 0.22), bright: BG.rgb(0.25, 0.95, 0.6), border: BG.rgb(0.03, 0.08, 0.06), spots: BG.rgb(0.8, 1, 0.85), eyespot: false, iridescent: true)
    ]

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

    static func drawSunbeams(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let origin = CGPoint(x: size.width * 0.06, y: -size.height * 0.12)
        let warm = BG.rgb(1, 0.95, 0.75)
        ctx.glow(at: origin, radius: size.width * 0.4, color: warm, intensity: 0.3)
        ctx.blurredLayer(radius: 22) { beams in
            for i in 0..<7 {
                let angle = 0.42 + CGFloat(i) * 0.11 + sin(t * 0.05 + CGFloat(i)) * 0.03
                let spread = BG.hash(i, 111, 0.022, 0.05)
                let breathe = 0.6 + 0.4 * sin(t * 0.3 + CGFloat(i) * 1.9)
                let length = size.height * 1.7
                var beam = Path()
                beam.move(to: origin)
                beam.addLine(to: CGPoint(x: origin.x + cos(angle - spread) * length, y: origin.y + sin(angle - spread) * length))
                beam.addLine(to: CGPoint(x: origin.x + cos(angle + spread) * length, y: origin.y + sin(angle + spread) * length))
                beam.closeSubpath()
                beams.fill(
                    beam,
                    with: .linearGradient(
                        Gradient(colors: [warm.opacity(Double(0.3 * breathe)), warm.opacity(0)]),
                        startPoint: origin,
                        endPoint: CGPoint(x: origin.x + cos(angle) * length * 0.8, y: origin.y + sin(angle) * length * 0.8)
                    )
                )
            }
        }
    }

    static func drawBokeh(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let colors = [BG.rgb(1, 0.9, 0.6), BG.rgb(0.7, 1, 0.7), BG.rgb(1, 0.8, 0.9)]
        ctx.blurredLayer(radius: 5) { bokeh in
            for i in 0..<16 {
                let x = BG.wrap(BG.hash(i, 121) * size.width + t * BG.hash(i, 122, -8, 8), length: size.width, margin: 50)
                let y = size.height * BG.hash(i, 123) + sin(t * 0.2 + CGFloat(i)) * 30
                let r = BG.hash(i, 124, 14, 40)
                let p = CGPoint(x: x, y: y)
                let color = colors[i % colors.count]
                let pulse = Double(0.7 + 0.3 * sin(t * 0.5 + CGFloat(i)))
                bokeh.fill(
                    BG.circle(p, r),
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(0.2 * pulse), color.opacity(0.12 * pulse), color.opacity(0)]),
                        center: p, startRadius: 0, endRadius: r
                    )
                )
            }
        }
    }

    static func flightPosition(k: Int, time t: CGFloat, size: CGSize) -> CGPoint {
        let duration = BG.hash(k, 81, 38, 58)
        let progress = BG.fract(BG.hash(k, 82) + t / duration)
        let travel = k % 2 == 0 ? progress : 1 - progress
        let x = -120 + travel * (size.width + 240)
        let baseY = size.height * BG.hash(k, 83, 0.2, 0.7)
        let wave = sin(progress * 2 * .pi * BG.hash(k, 84, 1.5, 3)) * size.height * 0.08
        let bob = sin(t * 2.7 + CGFloat(k)) * 10
        return CGPoint(x: x, y: baseY + wave + bob)
    }

    static func drawButterflies(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for k in 0..<5 {
            let p = flightPosition(k: k, time: t, size: size)
            let ahead = flightPosition(k: k, time: t + 0.15, size: size)
            let heading = atan2(ahead.y - p.y, ahead.x - p.x)
            let wingspan = BG.hash(k, 85, 56, 96)
            let glide = BG.smoothstep(-0.3, 0.4, sin(t * 0.4 + CGFloat(k) * 2))
            let flap = sin(t * BG.hash(k, 86, 8, 11) + CGFloat(k)) * BG.lerp(0.25, 1, glide)
            let open = 0.5 + 0.5 * flap
            drawButterfly(in: &ctx, at: p, wingspan: wingspan, open: open, heading: heading, species: species[k % species.count])
        }
    }

    static func drawButterfly(in ctx: inout GraphicsContext, at p: CGPoint, wingspan: CGFloat, open: CGFloat, heading: CGFloat, species: Species) {
        // Soft shadow cast on the scene below.
        let shadowCenter = CGPoint(x: p.x + wingspan * 0.15, y: p.y + wingspan * 0.9)
        let shadowWidth = wingspan * (0.18 + 0.32 * open)
        ctx.fill(
            BG.ellipse(shadowCenter, shadowWidth, wingspan * 0.08),
            with: .radialGradient(Gradient(colors: [.black.opacity(0.16), .black.opacity(0)]), center: shadowCenter, startRadius: 0, endRadius: shadowWidth)
        )

        var body = ctx
        body.translateBy(x: p.x, y: p.y)
        body.rotate(by: .radians(Double(heading + .pi / 2)))
        body.scaleBy(x: wingspan, y: wingspan)

        for side in [-1.0, 1.0] as [CGFloat] {
            var wing = body
            wing.scaleBy(x: side * (0.1 + 0.9 * open), y: 1)
            let gradient = Gradient(stops: [
                .init(color: species.border, location: 0),
                .init(color: species.base, location: 0.18),
                .init(color: species.bright, location: 0.55),
                .init(color: species.base, location: 0.78),
                .init(color: species.border, location: 0.9)
            ])
            let root = CGPoint(x: 0.03, y: 0)
            wing.fill(hindwing, with: .radialGradient(gradient, center: root, startRadius: 0, endRadius: 0.5))
            wing.fill(forewing, with: .radialGradient(gradient, center: root, startRadius: 0, endRadius: 0.56))
            if species.iridescent {
                // Structural color: a sheen that slides as the wing tilts.
                let shift = (open - 0.5) * 0.4
                wing.fill(
                    forewing,
                    with: .linearGradient(
                        Gradient(colors: [.white.opacity(0), .white.opacity(0.4), .white.opacity(0)]),
                        startPoint: CGPoint(x: 0.05 + shift, y: -0.45),
                        endPoint: CGPoint(x: 0.45 + shift, y: 0.05)
                    )
                )
            }
            wing.stroke(veins, with: .color(species.border.opacity(0.45)), lineWidth: 0.01)
            wing.stroke(forewing, with: .color(species.border.opacity(0.8)), lineWidth: 0.012)
            wing.stroke(hindwing, with: .color(species.border.opacity(0.8)), lineWidth: 0.012)
            for i in 0..<5 {
                let u = CGFloat(i) / 4
                let spot = CGPoint(x: 0.47 - u * 0.04, y: -0.4 + u * 0.3)
                wing.fill(BG.circle(spot, 0.013), with: .color(species.spots.opacity(0.9)))
            }
            if species.eyespot {
                let eye = CGPoint(x: 0.22, y: 0.25)
                wing.fill(BG.circle(eye, 0.06), with: .color(species.spots))
                wing.fill(BG.circle(eye, 0.042), with: .color(.black))
                wing.fill(BG.circle(eye, 0.022), with: .color(BG.rgb(0.3, 0.55, 1)))
                wing.fill(BG.circle(CGPoint(x: eye.x - 0.012, y: eye.y - 0.012), 0.008), with: .color(.white))
            }
        }

        // Thorax and abdomen with a rounded highlight.
        let thorax = Path(roundedRect: CGRect(x: -0.028, y: -0.17, width: 0.056, height: 0.42), cornerRadius: 0.028)
        body.fill(
            thorax,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.35, 0.3, 0.28), BG.rgb(0.06, 0.05, 0.05)]),
                startPoint: CGPoint(x: -0.03, y: 0),
                endPoint: CGPoint(x: 0.03, y: 0)
            )
        )
        body.fill(BG.circle(CGPoint(x: 0, y: -0.2), 0.036), with: .color(BG.rgb(0.1, 0.08, 0.08)))
        var antennae = Path()
        antennae.move(to: CGPoint(x: -0.01, y: -0.22))
        antennae.addQuadCurve(to: CGPoint(x: -0.11, y: -0.4), control: CGPoint(x: -0.03, y: -0.34))
        antennae.move(to: CGPoint(x: 0.01, y: -0.22))
        antennae.addQuadCurve(to: CGPoint(x: 0.11, y: -0.4), control: CGPoint(x: 0.03, y: -0.34))
        body.stroke(antennae, with: .color(BG.rgb(0.1, 0.08, 0.08)), lineWidth: 0.012)
        body.fill(BG.circle(CGPoint(x: -0.11, y: -0.4), 0.014), with: .color(BG.rgb(0.1, 0.08, 0.08)))
        body.fill(BG.circle(CGPoint(x: 0.11, y: -0.4), 0.014), with: .color(BG.rgb(0.1, 0.08, 0.08)))
    }
}

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

// MARK: - August: Blazing sun and drifting cumulus

struct AugustSunCloudsAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.93, 0.72), intensity: 0.16, depth: 0.45)
            let sun = SkyScene.sunPosition(size: size, time: time, duration: 1200, start: 0.5, height: 0.14, radius: 62)
            SunPainter.draw(in: &ctx, center: sun, radius: 62, time: time, warmth: 0.12, canvas: size)
            SkyScene.drawBirds(in: &ctx, size: size, time: time)
            SkyScene.drawClouds(in: &ctx, size: size, time: time, count: 6, yRange: 0.06...0.32, palette: .summer, light: sun, salt: 0)
        }
        .opacity(alpha)
    }
}

// MARK: - September: Golden-hour sun, clouds and falling leaves

struct SeptemberLeavesAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.8, 0.55), intensity: 0.2, depth: 0.5)
            AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(1, 0.75, 0.45), intensity: 0.12, depth: 0.3)
            let sun = SkyScene.sunPosition(size: size, time: time, duration: 4000, start: 0.7, height: 0.17, radius: 58)
            SunPainter.draw(in: &ctx, center: sun, radius: 58, time: time, warmth: 0.6, canvas: size)
            SkyScene.drawClouds(in: &ctx, size: size, time: time, count: 5, yRange: 0.05...0.5, palette: .golden, light: sun, salt: 40)
            FallingLeavesRenderer.draw(in: &ctx, size: size, time: time, count: 22, windBase: 14, gustiness: 18, fallSpeed: 45...85, salt: 0)
        }
        .opacity(alpha)
    }
}

private enum SkyScene {
    /// Sun drifting left to right on a shallow arc; it is fully off-screen when it wraps.
    static func sunPosition(size: CGSize, time: Double, duration: CGFloat, start: CGFloat, height: CGFloat, radius: CGFloat) -> CGPoint {
        let progress = BG.fract(start + CGFloat(time) / duration)
        let margin = radius * 4
        let x = -margin + progress * (size.width + margin * 2)
        let arc = 4 * progress * (1 - progress)
        let y = size.height * (height + 0.05) - size.height * 0.07 * arc
        return CGPoint(x: x, y: y)
    }

    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, time: Double, count: Int, yRange: ClosedRange<CGFloat>, palette: CloudPalette, light: CGPoint, salt: Int) {
        let t = CGFloat(time)
        for k in 0..<count {
            let depth = CGFloat(k) / CGFloat(max(count - 1, 1)) // far first, near last
            let width = BG.lerp(220, 420, depth) * BG.hash(k + salt, 131, 0.9, 1.1)
            let speed = BG.lerp(5, 15, depth)
            let x = BG.wrap(BG.hash(k + salt, 132) * size.width + t * speed, length: size.width, margin: width * 0.7)
            let y = size.height * BG.hash(k + salt, 133, yRange.lowerBound, yRange.upperBound)
            let center = CGPoint(x: x, y: y)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + salt + 100, width: width),
                center: center,
                width: width,
                palette: palette,
                opacity: Double(BG.lerp(0.6, 0.92, depth)),
                lightDirection: CGVector(dx: light.x - center.x, dy: light.y - center.y),
                softness: BG.lerp(0.05, 0.025, depth)
            )
        }
    }

    static func drawBirds(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        for i in 0..<4 {
            let duration = BG.hash(i, 141, 40, 70)
            let progress = BG.fract(BG.hash(i, 142) + t / duration)
            let x = -40 + progress * (size.width + 80)
            let y = size.height * BG.hash(i, 143, 0.18, 0.4) + sin(t * 0.4 + CGFloat(i)) * 14
            let span = BG.hash(i, 144, 10, 18)
            let beat = sin(t * BG.hash(i, 145, 4, 6) + CGFloat(i))
            let wingY = beat * span * 0.35
            var bird = Path()
            bird.move(to: CGPoint(x: x - span, y: y + wingY))
            bird.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - span * 0.5, y: y - span * 0.35 + wingY * 0.3))
            bird.addQuadCurve(to: CGPoint(x: x + span, y: y + wingY), control: CGPoint(x: x + span * 0.5, y: y - span * 0.35 + wingY * 0.3))
            ctx.stroke(bird, with: .color(BG.rgb(0.2, 0.22, 0.3, 0.55)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Leaves falling through gusty wind, tumbling in 3D, with near leaves out of focus.
private enum FallingLeavesRenderer {
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, count: Int, windBase: CGFloat, gustiness: CGFloat, fallSpeed: ClosedRange<CGFloat>, salt: Int) {
        let t = CGFloat(time)
        // Integral of the wind speed so horizontal drift stays continuous.
        let slowGust: CGFloat = -0.6 / 0.23 * cos(t * 0.23)
        let fastGust: CGFloat = -0.4 / 0.61 * cos(t * 0.61 + 1)
        let drift: CGFloat = windBase * t + gustiness * (slowGust + fastGust)
        let gust: CGFloat = sin(t * 0.23) * 0.6 + sin(t * 0.61 + 1) * 0.4

        func drawLeaf(_ i: Int, in target: inout GraphicsContext, near: Bool) {
            let seed = i + salt
            let depth: CGFloat = near ? 1 : BG.hash(seed, 150, 0.3, 0.85)
            let speed = BG.lerp(fallSpeed.lowerBound, fallSpeed.upperBound, BG.hash(seed, 151)) * BG.lerp(0.6, 1.3, depth)
            let span = size.height + 140
            let progress = BG.fract(BG.hash(seed, 152) + t * speed / span)
            let y = progress * span - 70
            let flutterRate = BG.hash(seed, 153, 0.8, 1.6)
            let flutter = sin(t * flutterRate + BG.hash(seed, 154) * 6.28)
            let x = BG.wrap(BG.hash(seed, 155) * size.width + drift * depth + flutter * 40, length: size.width, margin: 70)
            let rotation = Double(flutter * 0.9 + t * BG.hash(seed, 156, -0.8, 0.8) + gust * 0.3)
            let flip = cos(t * BG.hash(seed, 157, 0.9, 2.2) + BG.hash(seed, 158) * 6.28)
            let leafSize = BG.lerp(16, 34, depth) * (near ? 1.6 : 1)
            let fade = BG.smoothstep(0, 0.08, progress) * (1 - BG.smoothstep(0.88, 1, progress))
            let palette = LeafPalette.autumn[Int(BG.hash(seed, 159) * CGFloat(LeafPalette.autumn.count)) % LeafPalette.autumn.count]
            LeafPainter.draw(
                in: &target,
                at: CGPoint(x: x, y: y),
                size: leafSize,
                rotation: rotation,
                flip: flip,
                palette: palette,
                maple: BG.hash(seed, 160) < 0.55,
                opacity: Double(fade * BG.lerp(0.6, 0.95, depth))
            )
        }

        let nearCount = max(1, count / 6)
        for i in 0..<count {
            drawLeaf(i, in: &ctx, near: false)
        }
        ctx.blurredLayer(radius: 4) { near in
            for i in 0..<nearCount {
                drawLeaf(i + 5000, in: &near, near: true)
            }
        }
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

// MARK: - November: Wind-blown leaves

struct NovemberLeavesAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(0.7, 0.62, 0.55), intensity: 0.16, depth: 0.45)
            AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.85, 0.55, 0.3), intensity: 0.14, depth: 0.25)
            FallingLeavesRenderer.draw(in: &ctx, size: size, time: time, count: 34, windBase: 55, gustiness: 70, fallSpeed: 30...80, salt: 9000)
            NovemberScene.drawLeafPile(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum NovemberScene {
    static func drawLeafPile(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let gust = sin(t * 0.23) * 0.6 + sin(t * 0.61 + 1) * 0.4
        let count = Int(size.width / 22)
        for i in 0..<count {
            let x = BG.hash(i, 191) * size.width
            let y = size.height - BG.hash(i, 192, -4, 26)
            let rustle = Double(sin(t * 2.2 + CGFloat(i)) * 0.06 * max(0, gust))
            let palette = LeafPalette.autumn[i % LeafPalette.autumn.count]
            LeafPainter.draw(
                in: &ctx,
                at: CGPoint(x: x, y: y),
                size: BG.hash(i, 193, 20, 34),
                rotation: Double(BG.hash(i, 194) * 6.28) + rustle,
                flip: BG.hash(i, 195, 0.55, 1),
                palette: palette,
                maple: i % 3 != 0,
                opacity: 0.85
            )
        }
    }
}

// MARK: - December: Glowing C9 light strand over snowfall

struct DecemberChristmasLightsAnimation: View {
    let alpha: Double

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        AnimatedScene { ctx, size, time in
            AtmospherePainter.topHaze(in: &ctx, size: size, color: BG.rgb(1, 0.72, 0.42), intensity: 0.12, depth: 0.22)
            SnowRenderer.draw(in: &ctx, size: size, time: time, density: 0.6, wind: CGFloat(sin(time * 0.35)) * 0.3)
            DecemberScene.drawStrand(in: &ctx, size: size, time: time)
        }
        .opacity(alpha)
    }
}

private enum DecemberScene {
    static let colors: [Color] = [
        BG.rgb(1, 0.16, 0.14),
        BG.rgb(0.12, 0.88, 0.35),
        BG.rgb(0.2, 0.45, 1),
        BG.rgb(1, 0.72, 0.15),
        BG.rgb(0.95, 0.3, 0.82)
    ]

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

    static func drawStrand(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let t = CGFloat(time)
        let wind = sin(t * 0.35) * 0.6 + sin(t * 0.9 + 1) * 0.25
        let hooks = 4
        let bulbsPerSwag = 7
        let bulbLength: CGFloat = 36

        var cord = Path()
        var bulbs: [(point: CGPoint, swing: Double, index: Int)] = []

        for k in 0..<hooks {
            let p0 = CGPoint(x: size.width * CGFloat(k) / CGFloat(hooks), y: -4)
            let p2 = CGPoint(x: size.width * CGFloat(k + 1) / CGFloat(hooks), y: -4)
            let sag = size.height * 0.075 * (1 + 0.12 * sin(t * 0.5 + CGFloat(k))) + abs(wind) * 4
            let control = CGPoint(x: (p0.x + p2.x) / 2 + wind * 22, y: p0.y + sag * 2)
            cord.move(to: p0)
            cord.addQuadCurve(to: p2, control: control)

            for i in 0..<bulbsPerSwag {
                let u = (CGFloat(i) + 0.5) / CGFloat(bulbsPerSwag)
                let a = (1 - u) * (1 - u)
                let b = 2 * (1 - u) * u
                let c = u * u
                let point = CGPoint(x: a * p0.x + b * control.x + c * p2.x, y: a * p0.y + b * control.y + c * p2.y)
                let index = k * bulbsPerSwag + i
                let swing = Double(sin(t * 1.3 + CGFloat(index)) * 0.08 - wind * 0.15)
                bulbs.append((point: point, swing: swing, index: index))
            }
        }

        // Cord: dark twisted wire with a highlight.
        ctx.stroke(cord, with: .color(BG.rgb(0.04, 0.2, 0.08)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        var highlight = ctx
        highlight.translateBy(x: 0, y: -0.8)
        highlight.stroke(cord, with: .color(BG.rgb(0.4, 0.65, 0.4, 0.55)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 3]))

        for bulb in bulbs {
            let color = colors[bulb.index % colors.count]
            let chase = 0.5 + 0.5 * sin(t * 2.2 - CGFloat(bulb.index) * 0.55)
            let twinkle = pow(max(0, sin(t * BG.hash(bulb.index, 201, 1.5, 3.5) + BG.hash(bulb.index, 202) * 6.28)), 6)
            let brightness = BG.clamp01(0.3 + 0.5 * chase + 0.3 * twinkle)
            drawBulb(in: &ctx, at: bulb.point, length: bulbLength, swing: bulb.swing, color: color, brightness: brightness)
        }
    }

    static func drawBulb(in ctx: inout GraphicsContext, at socket: CGPoint, length: CGFloat, swing: Double, color: Color, brightness: CGFloat) {
        let glowCenter = CGPoint(x: socket.x - CGFloat(sin(swing)) * length * 0.6, y: socket.y + CGFloat(cos(swing)) * length * 0.6)
        ctx.glow(at: glowCenter, radius: length * 2.1, color: color, intensity: Double(0.5 * brightness))
        ctx.glow(at: glowCenter, radius: length * 0.8, color: color, intensity: Double(0.45 * brightness), additive: true)

        var bulb = ctx
        bulb.translateBy(x: socket.x, y: socket.y)
        bulb.rotate(by: .radians(swing))
        bulb.scaleBy(x: length, y: length)

        // Socket: a small green cylinder.
        let socketRect = Path(roundedRect: CGRect(x: -0.12, y: -0.02, width: 0.24, height: 0.32), cornerRadius: 0.05)
        bulb.fill(
            socketRect,
            with: .linearGradient(
                Gradient(colors: [BG.rgb(0.05, 0.25, 0.1), BG.rgb(0.35, 0.65, 0.4), BG.rgb(0.04, 0.2, 0.08)]),
                startPoint: CGPoint(x: -0.12, y: 0),
                endPoint: CGPoint(x: 0.12, y: 0)
            )
        )

        // Glass: hot white core fading through the bulb's color to a darker rim.
        let core = Color.white.opacity(Double(0.35 + 0.65 * brightness))
        bulb.fill(
            glass,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: core, location: 0),
                    .init(color: color, location: 0.45),
                    .init(color: color.opacity(0.85), location: 1)
                ]),
                center: CGPoint(x: -0.04, y: 0.58),
                startRadius: 0,
                endRadius: 0.42
            )
        )
        bulb.fill(glass, with: .color(.black.opacity(Double((1 - brightness) * 0.45))))
        bulb.fill(BG.ellipse(CGPoint(x: -0.08, y: 0.5), 0.03, 0.11), with: .color(.white.opacity(0.75)))
        bulb.stroke(glass, with: .color(.white.opacity(0.2)), lineWidth: 0.02)
    }
}
