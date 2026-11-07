//
//  BackgroundRendering.swift
//  Simple Calendar
//
//  Shared rendering toolkit for the month background scenes.
//
//  Every scene is drawn into a single `Canvas` driven by a `TimelineView`, so a
//  frame is a pure function of elapsed time. Particles derive their positions
//  from deterministic hashes instead of per-particle `@State` + timers, which
//  keeps the scenes leak-free and lets them afford real lighting: gradients,
//  depth-of-field blur, glows, and fake-3D tumbling.
//

import SwiftUI

// MARK: - Math helpers

/// Small math namespace for the background scenes (kept namespaced so the
/// helpers never collide with anything else in the module).
enum BG {
    /// Deterministic pseudo-random value in `0..<1` for an index/salt pair.
    static func hash(_ index: Int, _ salt: Int = 0) -> CGFloat {
        var x = UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
        x = x &+ UInt64(bitPattern: Int64(salt)) &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 30
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27
        x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return CGFloat(x >> 11) / CGFloat(UInt64(1) << 53)
    }

    /// Deterministic pseudo-random value in `lo...hi`.
    static func hash(_ index: Int, _ salt: Int, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        lo + (hi - lo) * hash(index, salt)
    }

    static func fract(_ x: CGFloat) -> CGFloat { x - floor(x) }

    static func clamp01(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    static func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = clamp01((x - edge0) / (edge1 - edge0))
        return t * t * (3 - 2 * t)
    }

    static func easeInOut(_ t: CGFloat) -> CGFloat {
        let x = clamp01(t)
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }

    /// Wraps `x` into `-margin ... length + margin` so particles re-enter on the far side.
    static func wrap(_ x: CGFloat, length: CGFloat, margin: CGFloat) -> CGFloat {
        let span = length + margin * 2
        return fract((x + margin) / span) * span - margin
    }

    static func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    static func ellipse(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
    }

    static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Animated canvas host

/// Hosts a scene: a `Canvas` re-rendered every display frame with the seconds
/// elapsed since the scene appeared.
struct AnimatedScene: View {
    private let render: (inout GraphicsContext, CGSize, Double) -> Void
    @State private var epoch = Date()

    init(render: @escaping (inout GraphicsContext, CGSize, Double) -> Void) {
        self.render = render
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(epoch)
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                render(&context, size, time)
            }
        }
    }
}

// MARK: - GraphicsContext conveniences

extension GraphicsContext {
    /// Draws `content` as one layer and blurs the composited result (depth of field).
    func blurredLayer(radius: CGFloat, _ content: (inout GraphicsContext) -> Void) {
        var layer = self
        if radius > 0 {
            layer.addFilter(.blur(radius: radius))
        }
        layer.drawLayer { inner in
            content(&inner)
        }
    }

    /// Soft radial glow: bright at the center, fading to transparent at `radius`.
    func glow(at center: CGPoint, radius: CGFloat, color: Color, intensity: Double, additive: Bool = false) {
        guard radius > 0, intensity > 0 else { return }
        var ctx = self
        if additive { ctx.blendMode = .plusLighter }
        let gradient = Gradient(stops: [
            .init(color: color.opacity(intensity), location: 0),
            .init(color: color.opacity(intensity * 0.45), location: 0.28),
            .init(color: color.opacity(intensity * 0.12), location: 0.6),
            .init(color: color.opacity(0), location: 1)
        ])
        ctx.fill(
            BG.circle(center, radius),
            with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius)
        )
    }

    /// A four-pointed twinkle star (lens sparkle).
    func sparkle(at center: CGPoint, size: CGFloat, color: Color, intensity: Double) {
        guard intensity > 0.01 else { return }
        var ctx = self
        ctx.blendMode = .plusLighter
        var star = Path()
        let arm = size
        let waist = size * 0.12
        star.move(to: CGPoint(x: center.x, y: center.y - arm))
        star.addQuadCurve(to: CGPoint(x: center.x + arm, y: center.y), control: CGPoint(x: center.x + waist, y: center.y - waist))
        star.addQuadCurve(to: CGPoint(x: center.x, y: center.y + arm), control: CGPoint(x: center.x + waist, y: center.y + waist))
        star.addQuadCurve(to: CGPoint(x: center.x - arm, y: center.y), control: CGPoint(x: center.x - waist, y: center.y + waist))
        star.addQuadCurve(to: CGPoint(x: center.x, y: center.y - arm), control: CGPoint(x: center.x - waist, y: center.y - waist))
        ctx.fill(star, with: .color(color.opacity(intensity)))
        ctx.glow(at: center, radius: size * 0.9, color: color, intensity: intensity * 0.6)
    }
}

// MARK: - Atmosphere

enum AtmospherePainter {
    /// Vertical haze band hugging the top of the screen.
    static func topHaze(in ctx: inout GraphicsContext, size: CGSize, color: Color, intensity: Double, depth: CGFloat = 0.4) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height * depth)
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [color.opacity(intensity), color.opacity(intensity * 0.35), color.opacity(0)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: rect.maxY)
            )
        )
    }

    /// Vertical haze band hugging the bottom of the screen.
    static func bottomHaze(in ctx: inout GraphicsContext, size: CGSize, color: Color, intensity: Double, depth: CGFloat = 0.3) {
        let top = size.height * (1 - depth)
        let rect = CGRect(x: 0, y: top, width: size.width, height: size.height - top)
        ctx.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [color.opacity(0), color.opacity(intensity * 0.4), color.opacity(intensity)]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    /// Twinkling star field in the upper part of the sky.
    static func stars(in ctx: inout GraphicsContext, size: CGSize, time: Double, count: Int, skyFraction: CGFloat, intensity: Double) {
        let t = CGFloat(time)
        for i in 0..<count {
            let x = BG.hash(i, 401) * size.width
            let y = pow(BG.hash(i, 402), 1.4) * size.height * skyFraction
            let rate = BG.hash(i, 403, 0.6, 2.2)
            let twinkle = 0.55 + 0.45 * sin(t * rate + BG.hash(i, 404) * 6.283)
            let magnitude = pow(BG.hash(i, 405), 3)
            let radius = 0.7 + magnitude * 1.8
            let alpha = Double(twinkle) * intensity * Double(0.35 + magnitude * 0.65)
            let tint = BG.hash(i, 406) < 0.2 ? BG.rgb(1, 0.9, 0.78) : BG.rgb(0.88, 0.93, 1)
            ctx.fill(BG.circle(CGPoint(x: x, y: y), radius), with: .color(tint.opacity(alpha)))
            if magnitude > 0.55 {
                ctx.sparkle(at: CGPoint(x: x, y: y), size: radius * 4.5, color: tint, intensity: alpha * 0.7)
            }
        }
    }
}

// MARK: - Volumetric clouds

/// Palette for a shaded cloud: lit top, body, and shadowed underside.
struct CloudPalette {
    var light: Color
    var body: Color
    var shade: Color

    static let summer = CloudPalette(light: BG.rgb(1, 1, 1), body: BG.rgb(0.95, 0.96, 0.99), shade: BG.rgb(0.72, 0.77, 0.88))
    static let golden = CloudPalette(light: BG.rgb(1, 0.97, 0.9), body: BG.rgb(0.98, 0.9, 0.82), shade: BG.rgb(0.78, 0.66, 0.66))
    static let blush = CloudPalette(light: BG.rgb(1, 0.98, 0.99), body: BG.rgb(1, 0.9, 0.94), shade: BG.rgb(0.9, 0.68, 0.8))
    static let storm = CloudPalette(light: BG.rgb(0.78, 0.8, 0.86), body: BG.rgb(0.55, 0.58, 0.66), shade: BG.rgb(0.3, 0.33, 0.41))
    static let night = CloudPalette(light: BG.rgb(0.82, 0.85, 0.95), body: BG.rgb(0.4, 0.42, 0.52), shade: BG.rgb(0.16, 0.16, 0.24))
}

enum CloudPainter {
    struct Puff {
        var offset: CGPoint
        var radius: CGFloat
    }

    /// Puffs for a cumulus cloud of the given width, centered on the origin.
    static func cumulusPuffs(seed: Int, width: CGFloat) -> [Puff] {
        var puffs: [Puff] = []
        let count = 7 + Int(BG.hash(seed, 1) * 4)
        for i in 0..<count {
            let u = (CGFloat(i) + 0.5) / CGFloat(count)
            let x = (u - 0.5) * width * 0.78
            let bell = sin(u * .pi)
            let radius = width * (0.1 + 0.13 * bell) * BG.hash(seed * 31 + i, 2, 0.8, 1.15)
            let lift = width * 0.1 * bell * BG.hash(seed * 31 + i, 3, 0.6, 1.3)
            puffs.append(Puff(offset: CGPoint(x: x, y: -lift), radius: radius))
        }
        // A flat-bottomed base so the cloud sits on an invisible layer of air.
        puffs.append(Puff(offset: CGPoint(x: -width * 0.18, y: width * 0.05), radius: width * 0.14))
        puffs.append(Puff(offset: CGPoint(x: width * 0.16, y: width * 0.05), radius: width * 0.15))
        return puffs
    }

    /// Puffs arranged along a heart outline, plus fill puffs in the interior.
    static func heartPuffs(seed: Int, width: CGFloat) -> [Puff] {
        var puffs: [Puff] = []
        let outline = 18
        for i in 0..<outline {
            let p = HeartGeometry.point(at: CGFloat(i) / CGFloat(outline))
            let radius = width * 0.11 * BG.hash(seed * 17 + i, 5, 0.85, 1.2)
            puffs.append(Puff(offset: CGPoint(x: p.x * width * 0.92, y: p.y * width * 0.92), radius: radius))
        }
        for i in 0..<6 {
            let x = BG.hash(seed * 13 + i, 6, -0.18, 0.18) * width
            let y = BG.hash(seed * 13 + i, 7, -0.14, 0.12) * width
            puffs.append(Puff(offset: CGPoint(x: x, y: y), radius: width * 0.17))
        }
        return puffs
    }

    /// Draws a shaded, soft-edged cloud. `lightDirection` points from the cloud toward the light.
    static func draw(
        in ctx: inout GraphicsContext,
        puffs: [Puff],
        center: CGPoint,
        width: CGFloat,
        palette: CloudPalette,
        opacity: Double,
        lightDirection: CGVector = CGVector(dx: -0.35, dy: -1),
        softness: CGFloat = 0.03
    ) {
        guard opacity > 0.01 else { return }
        let length = max(0.001, sqrt(lightDirection.dx * lightDirection.dx + lightDirection.dy * lightDirection.dy))
        let lx = lightDirection.dx / length
        let ly = lightDirection.dy / length

        var cloud = ctx
        cloud.opacity = opacity
        cloud.blurredLayer(radius: width * softness) { layer in
            // Shadowed underside: the whole silhouette, shifted away from the light.
            var silhouette = Path()
            for puff in puffs {
                let c = CGPoint(x: center.x + puff.offset.x, y: center.y + puff.offset.y)
                silhouette.addPath(BG.circle(c, puff.radius))
            }
            layer.fill(silhouette, with: .color(palette.shade))

            // Body: every puff lit from the light direction, back-to-front.
            for puff in puffs {
                let c = CGPoint(x: center.x + puff.offset.x, y: center.y + puff.offset.y)
                let r = puff.radius * 0.94
                let hot = CGPoint(x: c.x + lx * r * 0.45, y: c.y + ly * r * 0.45 - r * 0.08)
                let gradient = Gradient(stops: [
                    .init(color: palette.light, location: 0),
                    .init(color: palette.body, location: 0.55),
                    .init(color: palette.shade.opacity(0.0), location: 1)
                ])
                let lit = CGPoint(x: c.x + lx * r * 0.08, y: c.y + ly * r * 0.08)
                layer.fill(
                    BG.circle(lit, r),
                    with: .radialGradient(gradient, center: hot, startRadius: 0, endRadius: r * 1.45)
                )
            }
        }
    }
}

// MARK: - Heart geometry

enum HeartGeometry {
    /// Point on the classic parametric heart, normalized to roughly -0.5...0.5 (tip pointing down).
    static func point(at u: CGFloat) -> CGPoint {
        let t = u * 2 * .pi
        let s = sin(t)
        let x = 16 * s * s * s
        let y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
        return CGPoint(x: x / 34, y: -y / 34 + 0.04)
    }

    /// Unit heart path (about 1 x 1), centered on the origin.
    static let unitPath: Path = {
        var path = Path()
        let steps = 72
        for i in 0...steps {
            let p = point(at: CGFloat(i) / CGFloat(steps))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }()
}

// MARK: - Sun

enum SunPainter {
    /// Draws a glowing sun with rotating god rays and a subtle lens flare.
    /// `warmth` 0 = high noon white-yellow, 1 = deep golden hour.
    static func draw(in ctx: inout GraphicsContext, center c: CGPoint, radius r: CGFloat, time: Double, warmth: CGFloat, canvas: CGSize, flare: Bool = true) {
        let t = CGFloat(time)
        let core = BG.rgb(1, 0.99, 0.92)
        let mid = BG.rgb(1, Double(0.9 - 0.12 * warmth), Double(0.5 - 0.25 * warmth))
        let rim = BG.rgb(1, Double(0.72 - 0.2 * warmth), Double(0.25 - 0.12 * warmth))

        // Wide atmospheric bloom.
        ctx.glow(at: c, radius: r * 7, color: mid, intensity: 0.32)

        // Slowly rotating, breathing god rays (soft wedges, blurred as one layer).
        ctx.blurredLayer(radius: r * 0.12) { rays in
            let count = 16
            for i in 0..<count {
                let base = CGFloat(i) / CGFloat(count) * 2 * .pi + t * 0.02
                let breathe = 0.75 + 0.25 * sin(t * 0.35 + CGFloat(i) * 1.7)
                let length = r * (3.2 + 2.6 * BG.hash(i, 71)) * breathe
                let spread = 0.045 + 0.03 * BG.hash(i, 72)
                var wedge = Path()
                wedge.move(to: c)
                wedge.addLine(to: CGPoint(x: c.x + cos(base - spread) * length, y: c.y + sin(base - spread) * length))
                wedge.addLine(to: CGPoint(x: c.x + cos(base + spread) * length, y: c.y + sin(base + spread) * length))
                wedge.closeSubpath()
                rays.fill(
                    wedge,
                    with: .radialGradient(
                        Gradient(colors: [core.opacity(0.55), mid.opacity(0.22), mid.opacity(0)]),
                        center: c, startRadius: r * 0.6, endRadius: length
                    )
                )
            }
        }

        // Corona.
        ctx.glow(at: c, radius: r * 2.1, color: mid, intensity: 0.75)

        // Disc with limb darkening and a hot core.
        let disc = Gradient(stops: [
            .init(color: core, location: 0),
            .init(color: core, location: 0.35),
            .init(color: mid, location: 0.8),
            .init(color: rim, location: 1)
        ])
        ctx.fill(BG.circle(c, r), with: .radialGradient(disc, center: CGPoint(x: c.x - r * 0.12, y: c.y - r * 0.15), startRadius: 0, endRadius: r * 1.1))
        ctx.glow(at: c, radius: r * 1.25, color: core, intensity: 0.5, additive: true)

        guard flare else { return }
        // Lens flare ghosts along the line from the sun through the screen center.
        let screenCenter = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
        let axis = CGVector(dx: screenCenter.x - c.x, dy: screenCenter.y - c.y)
        let ghosts: [(CGFloat, CGFloat, Color)] = [
            (0.55, 0.22, BG.rgb(1, 0.85, 0.5)),
            (0.95, 0.12, BG.rgb(0.6, 1, 0.75)),
            (1.3, 0.38, BG.rgb(0.55, 0.75, 1)),
            (1.75, 0.18, BG.rgb(1, 0.6, 0.8))
        ]
        for (k, size, color) in ghosts {
            let p = CGPoint(x: c.x + axis.dx * k, y: c.y + axis.dy * k)
            let gr = r * size * 2
            ctx.fill(
                BG.circle(p, gr),
                with: .radialGradient(
                    Gradient(colors: [color.opacity(0.0), color.opacity(0.12), color.opacity(0.03), color.opacity(0)]),
                    center: p, startRadius: 0, endRadius: gr
                )
            )
        }
    }
}

// MARK: - Snow

enum SnowRenderer {
    /// Unit snow crystals (radius 1) with six branched arms.
    static let crystals: [Path] = (0..<3).map { (variant: Int) -> Path in
        var path = Path()
        for arm in 0..<6 {
            let a = CGFloat(arm) / 6 * 2 * .pi
            let dir = CGPoint(x: cos(a), y: sin(a))
            path.move(to: .zero)
            path.addLine(to: dir)
            let branches: [CGFloat] = variant == 0 ? [0.45, 0.72] : (variant == 1 ? [0.55] : [0.35, 0.6, 0.8])
            for b in branches {
                let base = CGPoint(x: dir.x * b, y: dir.y * b)
                let len: CGFloat = (1 - b) * 0.55 + 0.12
                for side in [-1.0, 1.0] as [CGFloat] {
                    let ba = a + side * .pi / 3
                    path.move(to: base)
                    path.addLine(to: CGPoint(x: base.x + cos(ba) * len, y: base.y + sin(ba) * len))
                }
            }
        }
        return path
    }

    /// Three depth layers: distant specks, mid crystals that spin, and near-camera bokeh.
    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, density: CGFloat = 1, wind: CGFloat = 0) {
        let t = CGFloat(time)
        let w = size.width
        let h = size.height

        // Far specks.
        let farCount = Int(120 * density)
        for i in 0..<farCount {
            let speed = BG.hash(i, 11, 22, 42)
            let span = h + 40
            let progress = BG.fract(BG.hash(i, 12) + t * speed / span)
            let y = progress * span - 20
            let sway = sin(t * BG.hash(i, 13, 0.4, 0.9) + BG.hash(i, 14) * 6.28) * 14
            let x = BG.wrap(BG.hash(i, 15) * w + sway + wind * progress * 120, length: w, margin: 20)
            let radius = BG.hash(i, 16, 0.9, 2.1)
            ctx.fill(BG.circle(CGPoint(x: x, y: y), radius), with: .color(.white.opacity(Double(BG.hash(i, 17, 0.35, 0.7)))))
        }

        // Mid crystals with a faint glow and slow spin.
        let midCount = Int(42 * density)
        for i in 0..<midCount {
            let seed = i + 1000
            let speed = BG.hash(seed, 11, 40, 66)
            let span = h + 80
            let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
            let y = progress * span - 40
            let sway = sin(t * BG.hash(seed, 13, 0.3, 0.7) + BG.hash(seed, 14) * 6.28) * 32
            let x = BG.wrap(BG.hash(seed, 15) * w + sway + wind * progress * 200, length: w, margin: 40)
            let radius = BG.hash(seed, 16, 5, 11)
            let spin = t * BG.hash(seed, 18, -0.6, 0.6) + BG.hash(seed, 19) * 6.28
            let p = CGPoint(x: x, y: y)
            ctx.glow(at: p, radius: radius * 1.8, color: .white, intensity: 0.35)
            var flake = ctx
            flake.translateBy(x: x, y: y)
            flake.rotate(by: .radians(Double(spin)))
            flake.scaleBy(x: radius, y: radius)
            let crystal = crystals[i % crystals.count]
            flake.stroke(crystal, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 0.14, lineCap: .round))
        }

        // Near-camera bokeh, blurred as one layer.
        let nearCount = max(1, Int(9 * density))
        ctx.blurredLayer(radius: 7) { near in
            for i in 0..<nearCount {
                let seed = i + 2000
                let speed = BG.hash(seed, 11, 85, 130)
                let span = h + 200
                let progress = BG.fract(BG.hash(seed, 12) + t * speed / span)
                let y = progress * span - 100
                let sway = sin(t * BG.hash(seed, 13, 0.2, 0.5) + BG.hash(seed, 14) * 6.28) * 60
                let x = BG.wrap(BG.hash(seed, 15) * w + sway + wind * progress * 320, length: w, margin: 100)
                let radius = BG.hash(seed, 16, 18, 42)
                let p = CGPoint(x: x, y: y)
                near.fill(
                    BG.circle(p, radius),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.42), .white.opacity(0.25), .white.opacity(0)]),
                        center: p, startRadius: 0, endRadius: radius
                    )
                )
            }
        }
    }

    /// Soft snowbank along the bottom edge, with cold shadows and glints.
    static func drawSnowbank(in ctx: inout GraphicsContext, size: CGSize, time: Double, height: CGFloat) {
        let w = size.width
        let h = size.height
        let t = CGFloat(time)
        func surface(_ x: CGFloat, _ layer: CGFloat) -> CGFloat {
            let u = x / max(w, 1)
            let ripple: CGFloat = sin(u * 9 + layer * 2) * 0.35
            let detail: CGFloat = sin(u * 23 + layer * 5) * 0.15
            let swell: CGFloat = sin(u * 4.3 + layer) * 0.5
            let wave = ripple + detail + swell
            return h - height * (0.75 + 0.35 * wave) * (1 - layer * 0.35)
        }
        for layer in [0, 1] as [CGFloat] {
            var bank = Path()
            bank.move(to: CGPoint(x: 0, y: h))
            var x: CGFloat = 0
            while x <= w {
                bank.addLine(to: CGPoint(x: x, y: surface(x, layer)))
                x += 12
            }
            bank.addLine(to: CGPoint(x: w, y: surface(w, layer)))
            bank.addLine(to: CGPoint(x: w, y: h))
            bank.closeSubpath()
            let top = h - height * 1.5
            let shade = layer == 0 ? BG.rgb(0.74, 0.82, 0.95) : BG.rgb(0.86, 0.91, 0.99)
            ctx.fill(
                bank,
                with: .linearGradient(
                    Gradient(colors: [BG.rgb(1, 1, 1, 0.9), shade.opacity(0.85)]),
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
        }
        // Glints that catch the light on the snow surface.
        for i in 0..<36 {
            let x = BG.hash(i, 501) * w
            let y = surface(x, 1) + BG.hash(i, 502, 4, height * 0.6)
            let pulse = pow(max(0, sin(t * BG.hash(i, 503, 0.8, 1.8) + BG.hash(i, 504) * 6.28)), 12)
            ctx.sparkle(at: CGPoint(x: x, y: y), size: 6, color: .white, intensity: Double(pulse) * 0.9)
        }
    }
}

// MARK: - Leaves

struct LeafPalette {
    var light: Color
    var dark: Color
    var vein: Color

    static let autumn: [LeafPalette] = [
        LeafPalette(light: BG.rgb(1, 0.72, 0.2), dark: BG.rgb(0.85, 0.3, 0.05), vein: BG.rgb(1, 0.85, 0.5)),
        LeafPalette(light: BG.rgb(0.95, 0.3, 0.15), dark: BG.rgb(0.55, 0.06, 0.08), vein: BG.rgb(1, 0.6, 0.45)),
        LeafPalette(light: BG.rgb(1, 0.88, 0.3), dark: BG.rgb(0.8, 0.55, 0.05), vein: BG.rgb(1, 0.95, 0.65)),
        LeafPalette(light: BG.rgb(0.75, 0.45, 0.2), dark: BG.rgb(0.4, 0.2, 0.08), vein: BG.rgb(0.9, 0.65, 0.4)),
        LeafPalette(light: BG.rgb(0.95, 0.55, 0.2), dark: BG.rgb(0.7, 0.2, 0.1), vein: BG.rgb(1, 0.8, 0.5))
    ]
}

enum LeafPainter {
    /// Maple outline (unit size, stem at the bottom).
    static let maple: Path = {
        let right: [CGPoint] = [
            CGPoint(x: 0.06, y: -0.3), CGPoint(x: 0.16, y: -0.36), CGPoint(x: 0.12, y: -0.17),
            CGPoint(x: 0.33, y: -0.3), CGPoint(x: 0.29, y: -0.19), CGPoint(x: 0.47, y: -0.15),
            CGPoint(x: 0.36, y: -0.03), CGPoint(x: 0.42, y: 0.05), CGPoint(x: 0.22, y: 0.07),
            CGPoint(x: 0.26, y: 0.2), CGPoint(x: 0.08, y: 0.13), CGPoint(x: 0.02, y: 0.26)
        ]
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -0.5))
        for p in right { path.addLine(to: p) }
        for p in right.reversed() { path.addLine(to: CGPoint(x: -p.x, y: p.y)) }
        path.closeSubpath()
        return path
    }()

    /// Elliptic leaf with a pointed tip (unit size, stem at the bottom).
    static let oval: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -0.5))
        path.addCurve(to: CGPoint(x: 0, y: 0.32), control1: CGPoint(x: 0.42, y: -0.28), control2: CGPoint(x: 0.36, y: 0.2))
        path.addCurve(to: CGPoint(x: 0, y: -0.5), control1: CGPoint(x: -0.36, y: 0.2), control2: CGPoint(x: -0.42, y: -0.28))
        path.closeSubpath()
        return path
    }()

    static let mapleVeins: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0.45))
        path.addLine(to: CGPoint(x: 0, y: -0.42))
        for side in [-1.0, 1.0] as [CGFloat] {
            path.move(to: CGPoint(x: 0, y: 0.1))
            path.addLine(to: CGPoint(x: 0.4 * side, y: -0.14))
            path.move(to: CGPoint(x: 0, y: 0.16))
            path.addLine(to: CGPoint(x: 0.36 * side, y: 0.04))
            path.move(to: CGPoint(x: 0, y: -0.05))
            path.addLine(to: CGPoint(x: 0.28 * side, y: -0.27))
        }
        return path
    }()

    static let ovalVeins: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0.46))
        path.addLine(to: CGPoint(x: 0, y: -0.44))
        for i in 0..<4 {
            let y = 0.18 - CGFloat(i) * 0.16
            for side in [-1.0, 1.0] as [CGFloat] {
                path.move(to: CGPoint(x: 0, y: y))
                path.addQuadCurve(to: CGPoint(x: 0.26 * side, y: y - 0.14), control: CGPoint(x: 0.14 * side, y: y - 0.02))
            }
        }
        return path
    }()

    /// Draws a leaf tumbling in 3D. `flip` is the cosine of the tumble angle:
    /// 1 shows the front face, -1 the (darker) back face, 0 is edge-on.
    static func draw(in ctx: inout GraphicsContext, at p: CGPoint, size: CGFloat, rotation: Double, flip: CGFloat, palette: LeafPalette, maple: Bool, opacity: Double = 1) {
        guard opacity > 0.01 else { return }
        var leaf = ctx
        leaf.opacity = opacity
        leaf.translateBy(x: p.x, y: p.y)
        leaf.rotate(by: .radians(rotation))
        let squash = max(abs(flip), 0.06)
        leaf.scaleBy(x: size * squash, y: size)

        let outline = maple ? LeafPainter.maple : LeafPainter.oval
        let backside = flip < 0
        let light = backside ? palette.dark : palette.light
        let dark = backside ? palette.dark.opacity(0.85) : palette.dark
        leaf.fill(
            outline,
            with: .linearGradient(
                Gradient(colors: [light, dark]),
                startPoint: CGPoint(x: -0.4, y: -0.5),
                endPoint: CGPoint(x: 0.4, y: 0.45)
            )
        )
        // Light falloff toward the edges suggests a curled, cupped surface.
        leaf.fill(
            outline,
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(backside ? 0.0 : 0.22), Color.white.opacity(0)]),
                center: CGPoint(x: -0.1, y: -0.15), startRadius: 0, endRadius: 0.45
            )
        )
        leaf.stroke(maple ? LeafPainter.mapleVeins : LeafPainter.ovalVeins, with: .color(palette.vein.opacity(backside ? 0.25 : 0.55)), lineWidth: 0.025)
        // Stem.
        var stem = Path()
        stem.move(to: CGPoint(x: 0, y: maple ? 0.24 : 0.3))
        stem.addQuadCurve(to: CGPoint(x: 0.04, y: 0.56), control: CGPoint(x: 0.0, y: 0.45))
        leaf.stroke(stem, with: .color(palette.dark), style: StrokeStyle(lineWidth: 0.035, lineCap: .round))
    }
}
