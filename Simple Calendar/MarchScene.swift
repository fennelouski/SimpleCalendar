//
//  MarchScene.swift
//  Simple Calendar
//
//  March: emerald hills waking up on a breezy spring morning.
//
//  March comes in like a lion and goes out like a lamb, and the wind is the star.
//  One gust signal drives the scene, and it travels: a point on the screen feels each
//  gust `x / 350` seconds after the left edge, so bright waves visibly run through the
//  turf on the hills. Grass tufts along the crests bend, shamrocks sway and fold their
//  leaflets in strong gusts, a kite at the right edge tugs and swoops, small clouds
//  race over and drag their shadows across the hills, and the gold motes swirl.
//
//  The scene also follows the selected day:
//    * month progress - the wind eases from blustery (the lion) to gentle (the lamb),
//                       the hills green from olive to emerald, more clover grows, and
//                       late in the month lambs graze on the far hill
//    * equinox        - the morning light warms around the spring equinox
//    * St. Patrick's  - every clover gains its fourth leaf, the motes triple and a
//                       faint rainbow arcs over the hills
//  Each changes through one discrete 2.5 s transition (`SceneTransition`).
//

import SwiftUI

// MARK: - View

struct MarchShamrocksAnimation: View {
    let alpha: Double
    /// The day whose character the scene reflects (the user's selection/focus).
    let date: Date
    @State private var model = MarchModel()

    init(alpha: Double = 1.0, date: Date = Date()) {
        self.alpha = alpha
        self.date = date
    }

    var body: some View {
        let target = MarchModel.Target(date: date)
        let state = model
        AnimatedScene(daylight: { ctx, size, time, daylight in
            var weathered = target
            weathered.windScale = daylight.weather.map { 0.35 + 1.2 * Double($0.windiness) }
            let look = state.look(target: weathered, time: time)
            MarchScene.draw(in: &ctx, size: size, time: time, look: look, daylight: daylight)
        })
        .opacity(alpha)
    }
}

// MARK: - State

final class MarchModel {
    struct Target {
        let progress: Double
        /// 1 within a day or two of the spring equinox.
        let equinox: Double
        let stPatrick: Double

        init(date: Date) {
            let day = SceneDay(date: date)
            progress = day.progress
            let equinoxDay = Calendar(identifier: .gregorian).component(.day, from: SceneDay.season(0, year: day.year))
            let distance = day.month == 3 ? Double(abs(day.day - equinoxDay)) : 10
            equinox = max(0, 1 - max(0, distance - 1) / 3)
            stPatrick = day.month == 3 && day.day == 17 ? 1 : 0
        }

        /// Real wind, when Weather Backgrounds is on, in place of the lion-to-lamb month.
        var windScale: Double?
    }

    struct Look {
        var progress: CGFloat
        var equinox: CGFloat
        var stPatrick: CGFloat
        /// Wind displacement accumulated since the scene appeared.
        var drift: CGFloat

        var windOverride: CGFloat?
        /// The lion (1.4) to the lamb (0.45), or the real wind.
        var windScale: CGFloat { windOverride ?? BG.lerp(1.4, 0.45, progress) }
        var warmth: CGFloat { BG.lerp(0.35, 0.5, equinox) }
    }

    private let progressTransition = SceneTransition()
    private let equinoxTransition = SceneTransition()
    private let patrickTransition = SceneTransition()
    private var drift: CGFloat = 0
    private var lastTime: Double?

    func look(target: Target, time: Double) -> Look {
        let progress = progressTransition.value(target: target.progress, time: time)
        let equinox = equinoxTransition.value(target: target.equinox, time: time)
        let patrick = patrickTransition.value(target: target.stPatrick, time: time)
        let scale = target.windScale.map { CGFloat($0) } ?? BG.lerp(1.4, 0.45, CGFloat(progress))
        if let last = lastTime {
            let dt = CGFloat(min(max(time - last, 0), 0.1))
            drift += dt * MarchWind.speed(CGFloat(time)) * scale
        }
        lastTime = time
        return Look(progress: CGFloat(progress), equinox: CGFloat(equinox), stPatrick: CGFloat(patrick), drift: drift,
                    windOverride: target.windScale.map { CGFloat($0) })
    }
}

// MARK: - Wind

/// One gust signal for the whole scene, from incommensurate sines (periods of roughly
/// 6 to 25 s) so the gusts never settle into a visible loop.
private enum MarchWind {
    static func signal(_ t: CGFloat) -> CGFloat {
        0.38 * sin(t * 0.25) + 0.3 * sin(t * 0.47 + 1.3) + 0.2 * sin(t * 0.83 + 3.1) + 0.12 * sin(t * 1.07 + 0.4)
    }

    /// 0...1: lulls with gusts that build and pass.
    static func gust(_ t: CGFloat) -> CGFloat { BG.smoothstep(-0.2, 0.7, signal(t)) }

    /// Gusts sweep left to right: a point at `x` feels each one `x / 350` seconds late.
    static func gust(at x: CGFloat, _ t: CGFloat) -> CGFloat { gust(t - x / 350) }

    /// Horizontal wind speed, points per second (before the lion/lamb scale).
    static func speed(_ t: CGFloat) -> CGFloat { 12 + 34 * gust(t) }
}

// MARK: - Art

private enum MarchArt {
    /// Cottage with a thatched roof, width 1, base at the origin.
    static let cottage: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.45, y: -0.42, width: 0.9, height: 0.42))
        path.addRect(CGRect(x: 0.22, y: -0.82, width: 0.1, height: 0.3))
        return path
    }()

    static let thatch: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.56, y: -0.38))
        path.addQuadCurve(to: CGPoint(x: -0.1, y: -0.78), control: CGPoint(x: -0.42, y: -0.72))
        path.addLine(to: CGPoint(x: 0.1, y: -0.78))
        path.addQuadCurve(to: CGPoint(x: 0.56, y: -0.38), control: CGPoint(x: 0.42, y: -0.72))
        path.closeSubpath()
        return path
    }()

    static let cottageOpenings: Path = {
        var path = Path()
        path.addRect(CGRect(x: -0.06, y: -0.26, width: 0.12, height: 0.26))
        path.addRect(CGRect(x: -0.34, y: -0.3, width: 0.13, height: 0.11))
        path.addRect(CGRect(x: 0.21, y: -0.3, width: 0.13, height: 0.11))
        return path
    }()

    /// Diamond kite (height 1, centered).
    static let kite: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -0.5))
        path.addLine(to: CGPoint(x: 0.36, y: -0.1))
        path.addLine(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: -0.36, y: -0.1))
        path.closeSubpath()
        return path
    }()

    /// The kite's cross stripe.
    static let kiteBand: Path = Path(CGRect(x: -0.36, y: -0.13, width: 0.72, height: 0.06)).intersection(kite)
}

// MARK: - Scene

private enum MarchScene {
    static let heights: [CGFloat] = [0.1, 0.072, 0.042]

    static func draw(in ctx: inout GraphicsContext, size: CGSize, time: Double, look: MarchModel.Look, daylight: SceneDaylight) {
        let t = CGFloat(time)
        let dark = daylight.isDark
        let sun = daylight.sunPoint(in: size)
        let cover = daylight.weather?.cover ?? 0
        // Sunlit things: the kite is flown by day, the gold motes only shimmer in sunshine.
        let sunshine = Double(daylight.light * (1 - cover))
        let rain = Double(daylight.weather?.rain ?? 0)

        ctx.drawLayer { sky in
            drawSky(in: &sky, size: size, look: look, sun: sun, dark: dark)
            drawClouds(in: &sky, size: size, t: t, look: look, sun: sun)
            DaylightPainter.lowSunGrade(in: &sky, size: size, daylight: daylight, strength: 1.1)
            DaylightPainter.nightGrade(in: &sky, size: size, daylight: daylight, strength: 0.9)
        }
        DaylightPainter.stars(in: &ctx, size: size, time: time, daylight: daylight)
        DaylightPainter.moon(in: &ctx, size: size, daylight: daylight)
        WeatherPainter.cloudDeck(in: &ctx, size: size, time: time, daylight: daylight, seed: 3)
        if sunshine > 0.02 {
            var flown = ctx
            flown.opacity = Double(BG.smoothstep(0.3, 0.7, daylight.light)) * (1 - rain)
            drawKite(in: &flown, size: size, t: t, look: look)
            flown.opacity = sunshine
            drawMotes(in: &flown, size: size, t: t, look: look, near: false, dark: dark)
        }

        ctx.drawLayer { land in
            drawHill(in: &land, size: size, t: t, look: look, layer: 0, dark: dark)
            drawFarDetails(in: &land, size: size, t: t, look: look)
            drawMist(in: &land, size: size, t: t)
            var bow = look
            bow.stPatrick = max(look.stPatrick, WeatherPainter.rainbowChance(daylight))
            drawRainbow(in: &land, size: size, look: bow)
            drawHill(in: &land, size: size, t: t, look: look, layer: 1, dark: dark)
            drawCottage(in: &land, size: size, t: t, look: look)
            drawShamrocks(in: &land, size: size, t: t, look: look, layer: 1)
            drawHill(in: &land, size: size, t: t, look: look, layer: 2, dark: dark)
            var shadows = land
            shadows.opacity = Double(daylight.sunUp * (1 - cover))
            drawCloudShadows(in: &shadows, size: size, look: look, sun: sun)
            drawShamrocks(in: &land, size: size, t: t, look: look, layer: 2)
            WeatherPainter.dullLight(in: &land, size: size, daylight: daylight)
            DaylightPainter.lowSunGrade(in: &land, size: size, daylight: daylight)
            DaylightPainter.nightGrade(in: &land, size: size, daylight: daylight)
        }
        drawCottageLights(in: &ctx, size: size, t: t, daylight: daylight)
        if sunshine > 0.02 {
            var motes = ctx
            motes.opacity = sunshine
            drawMotes(in: &motes, size: size, t: t, look: look, near: true, dark: dark)
        }
        WeatherPainter.foreground(in: &ctx, size: size, time: time, daylight: daylight)
    }

    /// The cottage's two windows glow from dusk until bedtime (and again before dawn).
    static func drawCottageLights(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, daylight: SceneDaylight) {
        let x = size.width * 0.075
        let base = hillY(layer: 1, x: x, size: size) + 4
        let w: CGFloat = 46
        let panes = [CGRect(x: -0.34, y: -0.3, width: 0.13, height: 0.11), CGRect(x: 0.21, y: -0.3, width: 0.13, height: 0.11)]
        for (i, pane) in panes.enumerated() {
            let lit = DaylightPainter.windowLit(i, salt: 930, daylight: daylight)
            guard lit > 0.01 else { continue }
            let rect = CGRect(x: x + pane.minX * w, y: base + pane.minY * w, width: pane.width * w, height: pane.height * w)
            let flicker = Double(0.9 + 0.1 * sin(t * 2.3 + CGFloat(i) * 1.7))
            ctx.glow(at: CGPoint(x: rect.midX, y: rect.midY), radius: w * 0.5, color: BG.rgb(1, 0.72, 0.38), intensity: 0.5 * Double(lit) * flicker)
            ctx.fill(Path(rect), with: .color(BG.rgb(1, 0.82, 0.5, 0.95 * Double(lit) * flicker)))
        }
    }

    // MARK: Sky

    static func drawSky(in ctx: inout GraphicsContext, size: CGSize, look: MarchModel.Look, sun: CGPoint, dark: Bool) {
        let warm = Double(look.warmth)
        let sky = Gradient(stops: [
            .init(color: BG.rgb(0.55, 0.75, 0.95, 0.2), location: 0),
            .init(color: BG.rgb(0.8, 0.9, 0.95, 0.08), location: 0.55),
            .init(color: BG.rgb(0.75, 0.95, 0.7, 0.1), location: 1)
        ])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        AtmospherePainter.bottomHaze(in: &ctx, size: size, color: BG.rgb(0.75, 0.95, 0.7), intensity: 0.18, depth: 0.35)
        // Morning sun just past the top-right corner.
        ctx.glow(at: sun, radius: size.width * 0.45, color: BG.rgb(1, 0.95 - 0.1 * warm, 0.8 - 0.25 * warm), intensity: 0.3 + 0.15 * warm)
        ctx.glow(at: sun, radius: 140, color: BG.rgb(1, 0.97, 0.88), intensity: 0.5)
    }

    static func cloud(_ k: Int, size: CGSize, look: MarchModel.Look) -> (center: CGPoint, width: CGFloat) {
        let width = BG.hash(k, 901, 150, 240)
        let x = BG.wrap(BG.hash(k, 902) * size.width + look.drift * BG.hash(k, 903, 1.2, 2), length: size.width, margin: width * 0.7)
        let y = size.height * BG.hash(k, 904, 0.06, 0.24)
        return (CGPoint(x: x, y: y), width)
    }

    /// Small fair-weather clouds racing over with the wind.
    static func drawClouds(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look, sun: CGPoint) {
        for k in 0..<4 {
            let c = cloud(k, size: size, look: look)
            CloudPainter.draw(
                in: &ctx,
                puffs: CloudPainter.cumulusPuffs(seed: k + 910, width: c.width),
                center: c.center,
                width: c.width,
                palette: .summer,
                opacity: 0.7,
                lightDirection: CGVector(dx: sun.x - c.center.x, dy: sun.y - c.center.y),
                softness: 0.04
            )
        }
    }

    /// Cloud shadows sweeping over the hills.
    static func drawCloudShadows(in ctx: inout GraphicsContext, size: CGSize, look: MarchModel.Look, sun: CGPoint) {
        var land = ctx
        land.clip(to: hillPath(size: size, layer: 0))
        land.blurredLayer(radius: 16) { shade in
            for k in 0..<4 {
                let c = cloud(k, size: size, look: look)
                let x = c.center.x - (sun.x - c.center.x) * 0.12
                shade.fill(BG.ellipse(CGPoint(x: x, y: size.height * 0.95), c.width * 0.45, size.height * 0.04), with: .color(BG.rgb(0.05, 0.2, 0.1, 0.22)))
            }
        }
    }

    /// A kite tugging on its string from beyond the bottom-right corner, swooping in
    /// the gusts with its ribbon tail streaming downwind.
    static func drawKite(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look) {
        let anchor = CGPoint(x: size.width * 0.8, y: size.height + 30)
        let gust = MarchWind.gust(at: size.width * 0.88, t) * look.windScale
        let p = CGPoint(
            x: size.width * 0.9 + gust * 26 + sin(t * 0.37) * 12,
            y: size.height * 0.2 - gust * 22 + sin(t * 0.71) * 18 * (0.4 + gust)
        )
        let tilt = sin(t * 1.3) * 0.25 * (0.3 + gust) + 0.15
        var string = Path()
        string.move(to: anchor)
        string.addQuadCurve(to: p, control: CGPoint(x: (anchor.x + p.x) / 2 + 40, y: (anchor.y + p.y) / 2 + 30 * (1 - gust)))
        ctx.stroke(string, with: .color(BG.rgb(0.3, 0.3, 0.3, 0.35)), lineWidth: 0.7)

        // Tail: a ribbon with bows streaming out behind and below.
        var tail = Path()
        var bows = Path()
        let start = CGPoint(x: p.x - sin(tilt) * 16, y: p.y + cos(tilt) * 16)
        tail.move(to: start)
        for j in 1...10 {
            let u = CGFloat(j) / 10
            let q = CGPoint(
                x: start.x + u * (20 + 30 * gust) + sin(t * 4 - u * 7) * 6 * u,
                y: start.y + u * 70 * (1 - 0.3 * gust) + cos(t * 3.1 - u * 6) * 3 * u
            )
            tail.addLine(to: q)
            if j % 3 == 0 {
                bows.addPath(BG.ellipse(CGPoint(x: q.x - 3, y: q.y), 3, 1.6))
                bows.addPath(BG.ellipse(CGPoint(x: q.x + 3, y: q.y), 3, 1.6))
            }
        }
        ctx.stroke(tail, with: .color(BG.rgb(0.95, 0.85, 0.3, 0.8)), lineWidth: 1.4)
        ctx.fill(bows, with: .color(BG.rgb(0.2, 0.65, 0.35, 0.85)))

        var kite = ctx
        kite.translateBy(x: p.x, y: p.y)
        kite.rotate(by: .radians(Double(tilt)))
        kite.scaleBy(x: 34, y: 34)
        kite.fill(MarchArt.kite, with: .linearGradient(
            Gradient(colors: [BG.rgb(0.2, 0.75, 0.4), BG.rgb(0.1, 0.5, 0.25)]),
            startPoint: CGPoint(x: -0.3, y: -0.4),
            endPoint: CGPoint(x: 0.3, y: 0.4)
        ))
        kite.fill(MarchArt.kiteBand, with: .color(BG.rgb(1, 0.9, 0.4, 0.9)))
        var spars = Path()
        spars.move(to: CGPoint(x: 0, y: -0.5))
        spars.addLine(to: CGPoint(x: 0, y: 0.5))
        spars.move(to: CGPoint(x: -0.36, y: -0.1))
        spars.addLine(to: CGPoint(x: 0.36, y: -0.1))
        kite.stroke(spars, with: .color(BG.rgb(0.3, 0.2, 0.1, 0.5)), lineWidth: 0.025)
    }

    // MARK: Hills

    static func hillY(layer: Int, x: CGFloat, size: CGSize) -> CGFloat {
        let u = x / max(size.width, 1)
        let l = CGFloat(layer)
        let broad: CGFloat = 0.55 * sin(u * 3.1 + l * 1.7)
        let rolling: CGFloat = 0.3 * sin(u * 7.3 + l * 0.6)
        let bumps: CGFloat = 0.15 * sin(u * 15 + l * 2.9)
        return size.height - size.height * heights[layer] * (0.78 + 0.3 * (broad + rolling + bumps))
    }

    static func hillPath(size: CGSize, layer: Int) -> Path {
        var fill = Path()
        fill.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 16 {
            fill.addLine(to: CGPoint(x: x, y: hillY(layer: layer, x: x, size: size)))
            x += 16
        }
        fill.addLine(to: CGPoint(x: size.width + 16, y: size.height))
        fill.closeSubpath()
        return fill
    }

    /// A hill: greening from olive to emerald through the month, with a sunlit rim,
    /// grass tufts along the crest that bend in the gusts, and bright waves running
    /// through the turf as each gust passes.
    static func drawHill(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look, layer: Int, dark: Bool) {
        let green = Double(look.progress)
        func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Color {
            BG.rgb(a.0 + (b.0 - a.0) * green, a.1 + (b.1 - a.1) * green, a.2 + (b.2 - a.2) * green)
        }
        let tops: [Color] = [
            mix((0.68, 0.74, 0.55), (0.62, 0.82, 0.6)),
            mix((0.58, 0.66, 0.42), (0.42, 0.76, 0.4)),
            mix((0.55, 0.7, 0.48), (0.32, 0.7, 0.3))
        ]
        let bottoms: [Color] = [
            mix((0.45, 0.55, 0.42), (0.38, 0.62, 0.42)),
            mix((0.3, 0.4, 0.22), (0.18, 0.48, 0.22)),
            mix((0.2, 0.3, 0.12), (0.08, 0.36, 0.12))
        ]
        let opacities: [Double] = dark ? [0.45, 0.6, 0.78] : [0.38, 0.51, 0.66]

        var ridge = Path()
        var tufts = Path()
        var highest = size.height
        var x: CGFloat = 0
        while x <= size.width + 16 {
            let y = hillY(layer: layer, x: x, size: size)
            highest = min(highest, y)
            if x == 0 { ridge.move(to: CGPoint(x: x, y: y)) } else { ridge.addLine(to: CGPoint(x: x, y: y)) }
            x += 16
        }

        var hill = ctx
        hill.opacity = opacities[layer]
        hill.fill(
            hillPath(size: size, layer: layer),
            with: .linearGradient(
                Gradient(colors: [tops[layer], bottoms[layer]]),
                startPoint: CGPoint(x: 0, y: highest),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        hill.stroke(ridge, with: .color(BG.rgb(0.85, 1, 0.75, 0.55)), lineWidth: 2)

        guard layer > 0 else { return }
        // Grass tufts leaning with the gust at their x.
        let spacing: CGFloat = layer == 2 ? 5 : 7
        let blade: CGFloat = layer == 2 ? 9 : 6
        var bx: CGFloat = 0
        var i = 0
        while bx <= size.width {
            let gx = bx + BG.hash(i + layer * 1000, 920, -2, 2)
            let base = hillY(layer: layer, x: gx, size: size) + 2
            let gust = MarchWind.gust(at: gx, t) * look.windScale
            let h = blade * BG.hash(i + layer * 1000, 921, 0.6, 1.3)
            let bend = (0.2 + 0.7 * gust + 0.08 * sin(t * 2 + CGFloat(i))) * h
            tufts.move(to: CGPoint(x: gx - 1, y: base))
            tufts.addQuadCurve(to: CGPoint(x: gx + bend, y: base - h), control: CGPoint(x: gx, y: base - h * 0.6))
            tufts.addQuadCurve(to: CGPoint(x: gx + 1, y: base), control: CGPoint(x: gx + 1 + bend * 0.2, y: base - h * 0.5))
            bx += spacing
            i += 1
        }
        hill.fill(tufts, with: .color(tops[layer]))

        // Bright waves running through the turf: the ridge, lit by the gust at each x.
        var stops: [Gradient.Stop] = []
        for k in 0...10 {
            let u = CGFloat(k) / 10
            let g = MarchWind.gust(at: u * size.width, t) * min(look.windScale, 1.2)
            stops.append(.init(color: BG.rgb(0.9, 1, 0.75, Double(0.4 * g)), location: u))
        }
        hill.stroke(
            ridge,
            with: .linearGradient(Gradient(stops: stops), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)),
            style: StrokeStyle(lineWidth: layer == 2 ? 9 : 6, lineCap: .round, lineJoin: .round)
        )
    }

    /// A dry-stone wall along the far hill, and lambs grazing late in the month.
    static func drawFarDetails(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look) {
        var wall = Path()
        var x: CGFloat = size.width * 0.55
        wall.move(to: CGPoint(x: x, y: hillY(layer: 0, x: x, size: size) + 10))
        while x <= size.width {
            x += 12
            wall.addLine(to: CGPoint(x: x, y: hillY(layer: 0, x: x, size: size) + 10 + (x - size.width * 0.55) * 0.02))
        }
        ctx.stroke(wall, with: .color(BG.rgb(0.45, 0.48, 0.42, 0.45)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [4, 1.5]))

        // Out like a lamb: up to five lambs appear in the last week or so.
        let lambs = BG.smoothstep(0.65, 0.95, look.progress) * 5
        guard lambs > 0.01 else { return }
        for k in 0..<5 {
            let visible = BG.clamp01(lambs - CGFloat(k))
            guard visible > 0.01 else { continue }
            let u = BG.hash(k, 930, 0.08, 0.5)
            let lx = size.width * u + sin(t * 0.02 + CGFloat(k) * 2) * 30
            let ly = hillY(layer: 0, x: lx, size: size) + BG.hash(k, 931, 6, 14)
            let grazing = sin(t * BG.hash(k, 932, 0.3, 0.6) + CGFloat(k)) > 0
            let facing: CGFloat = cos(t * 0.02 + CGFloat(k) * 2) > 0 ? 1 : -1
            var lamb = ctx
            lamb.opacity = Double(visible) * 0.85
            lamb.translateBy(x: lx, y: ly)
            lamb.scaleBy(x: facing * 7, y: 7)
            lamb.fill(BG.ellipse(.zero, 1, 0.6), with: .color(BG.rgb(0.98, 0.98, 0.95)))
            lamb.fill(BG.ellipse(CGPoint(x: 0.95, y: grazing ? 0.35 : -0.35), 0.38, 0.3), with: .color(BG.rgb(0.25, 0.22, 0.2)))
            var legs = Path()
            for lx2 in [-0.55, -0.25, 0.3, 0.6] as [CGFloat] {
                legs.move(to: CGPoint(x: lx2, y: 0.4))
                legs.addLine(to: CGPoint(x: lx2, y: 0.95))
            }
            lamb.stroke(legs, with: .color(BG.rgb(0.25, 0.22, 0.2)), lineWidth: 0.16)
        }
    }

    /// Morning mist lifting off the far hill over the first 30 s after the scene appears.
    static func drawMist(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat) {
        let fade = 1 - BG.smoothstep(0, 30, t)
        guard fade > 0.01 else { return }
        ctx.blurredLayer(radius: 18) { mist in
            for i in 0..<4 {
                let x = size.width * BG.hash(i, 935, 0.1, 0.9)
                let y = size.height * 0.9 - t * 0.8
                let c = CGPoint(x: x, y: y)
                let rx = size.width * 0.3
                mist.fill(BG.ellipse(c, rx, size.height * 0.03), with: .radialGradient(
                    Gradient(colors: [BG.rgb(0.95, 1, 0.95, 0.45 * Double(fade)), BG.rgb(0.95, 1, 0.95, 0)]),
                    center: c, startRadius: 0, endRadius: rx
                ))
            }
        }
    }

    /// A whitewashed cottage with a thatched roof on the left of the mid hill.
    static func drawCottage(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look) {
        let x = size.width * 0.075
        let base = hillY(layer: 1, x: x, size: size) + 4
        let w: CGFloat = 46
        let transform = CGAffineTransform(translationX: x, y: base).scaledBy(x: w, y: w)
        ctx.fill(MarchArt.cottage.applying(transform), with: .color(BG.rgb(0.96, 0.95, 0.9, 0.85)))
        ctx.fill(MarchArt.thatch.applying(transform), with: .linearGradient(
            Gradient(colors: [BG.rgb(0.78, 0.65, 0.4), BG.rgb(0.55, 0.42, 0.25)]),
            startPoint: CGPoint(x: x, y: base - w * 0.8),
            endPoint: CGPoint(x: x, y: base - w * 0.38)
        ))
        ctx.fill(MarchArt.cottageOpenings.applying(transform), with: .color(BG.rgb(0.25, 0.3, 0.35, 0.8)))
        // Peat smoke, bent by the wind.
        let chimney = CGPoint(x: x + w * 0.27, y: base - w * 0.82)
        let gust = MarchWind.gust(at: x, t) * look.windScale
        ctx.blurredLayer(radius: 4) { smoke in
            for k in 0..<6 {
                let f = BG.fract(BG.hash(k, 940) + t * 0.09)
                let p = CGPoint(x: chimney.x + f * f * (40 + 90 * gust) + f * 6, y: chimney.y - f * 50 * (1 - 0.5 * gust))
                smoke.fill(BG.circle(p, 3 + 9 * f), with: .color(BG.rgb(0.7, 0.72, 0.75, Double((1 - f) * BG.smoothstep(0, 0.1, f)) * 0.3)))
            }
        }
    }

    /// St. Patrick's Day: a faint rainbow arcing over the hills (hidden behind them).
    static func drawRainbow(in ctx: inout GraphicsContext, size: CGSize, look: MarchModel.Look) {
        let s = Double(look.stPatrick)
        guard s > 0.01 else { return }
        let center = CGPoint(x: size.width * 0.5, y: size.height * 1.25)
        let radius = size.width * 0.9
        // Upper half of the circle (y above the centre), built point by point.
        var arc = Path()
        for k in 0...48 {
            let a = CGFloat.pi + CGFloat.pi * CGFloat(k) / 48
            let p = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
            if k == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
        }
        let band: CGFloat = 28
        let colors: [Color] = [
            BG.rgb(0.6, 0.3, 0.9), BG.rgb(0.3, 0.4, 1), BG.rgb(0.2, 0.75, 0.9), BG.rgb(0.3, 0.85, 0.35),
            BG.rgb(1, 0.92, 0.3), BG.rgb(1, 0.6, 0.2), BG.rgb(1, 0.25, 0.25)
        ]
        var stops: [Gradient.Stop] = [.init(color: colors[0].opacity(0), location: 0)]
        for (k, color) in colors.enumerated() {
            stops.append(.init(color: color.opacity(0.18 * s), location: 0.08 + 0.84 * CGFloat(k) / CGFloat(colors.count - 1)))
        }
        stops.append(.init(color: colors[colors.count - 1].opacity(0), location: 1))
        ctx.stroke(arc, with: .radialGradient(
            Gradient(stops: stops),
            center: center, startRadius: radius - band / 2, endRadius: radius + band / 2
        ), lineWidth: band)
    }

    // MARK: Shamrocks

    /// Ten slots, alternating rows. Each new plant sprouts beside the last one in its
    /// patch (runner growth); a patch lives for a few cycles and then moves on.
    static func drawShamrocks(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look, layer: Int) {
        let slots = 10
        let period: CGFloat = 24
        let scale: CGFloat = layer == 2 ? 1 : 0.72
        // 6 slots in use on March 1, all 10 by the end of the month.
        let active = BG.lerp(0.6, 1, look.progress)
        for s in 0..<slots where (s % 2 == 0) == (layer == 2) {
            let rank = (CGFloat((s * 7) % slots) + 0.5) / CGFloat(slots)
            let inUse = BG.clamp01((active - rank) / 0.05)
            guard inUse > 0.01 else { continue }
            let cyclePosition = t / period + BG.hash(s, 41)
            let cycle = Int(floor(cyclePosition))
            let life = BG.fract(cyclePosition)
            let seed = s * 977 + cycle

            // Patch: 2-4 cycles long; each plant sprouts a step along from the last.
            let patchLength = 2 + Int(BG.hash(s, 950) * 3)
            let patch = cycle / patchLength
            let step = cycle - patch * patchLength
            let patchStart = (CGFloat(s) + 0.15 + 0.4 * BG.hash(s * 131 + patch, 951)) / CGFloat(slots) * size.width
            let direction: CGFloat = BG.hash(s * 131 + patch, 952) < 0.5 ? -1 : 1
            let x = patchStart + direction * CGFloat(step) * 14 * scale
            let groundY = hillY(layer: layer, x: x, size: size) + 6

            let grow = BG.easeInOut(BG.smoothstep(0, 0.22, life))
            let unfurl = BG.easeInOut(BG.smoothstep(0.15, 0.38, life))
            let wilt = BG.smoothstep(0.82, 1, life)
            let opacity = Double((1 - wilt) * inUse)
            guard grow > 0.01, opacity > 0.01 else { continue }

            let gust = MarchWind.gust(at: x, t) * look.windScale
            let lean: CGFloat = BG.hash(seed, 46) > 0.5 ? 1 : -1
            let stemHeight = BG.hash(seed, 44, 55, 95) * scale * grow * (1 - wilt * 0.3)
            let sway = sin(t * 0.9 + CGFloat(s)) * 6 * grow + gust * 10 * grow + wilt * 22 * lean
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
            // Four leaves: rare and glowing, one hidden plain one per slot set, or all of
            // them on St. Patrick's Day (the fourth leaf grows in during the transition).
            let lucky = BG.hash(seed, 43) < 0.22
            let hidden = s == 3 && cycle % 3 == 0
            let fourth = lucky || hidden ? 1 : look.stPatrick
            let glowing = lucky ? 1 : look.stPatrick
            if glowing > 0.01 {
                plant.glow(at: top, radius: leafSize * 2.6, color: BG.rgb(1, 0.85, 0.3), intensity: Double(0.4 * glowing), additive: true)
                let orbit = t * 1.4 + CGFloat(s)
                let sparklePoint = CGPoint(x: top.x + cos(orbit) * leafSize * 1.3, y: top.y + sin(orbit) * leafSize * 1.1)
                plant.sparkle(at: sparklePoint, size: 7, color: BG.rgb(1, 0.92, 0.55), intensity: Double(0.9 * glowing))
            }
            if hidden && glowing < 0.5 {
                // The hidden four-leaf clover gives itself away with a glint now and then.
                let glint = pow(max(0, sin(t * 2 * CGFloat.pi / 10 + CGFloat(s))), 30)
                if glint > 0.05 {
                    plant.sparkle(at: CGPoint(x: top.x - leafSize * 0.3, y: top.y - leafSize * 0.3), size: 6, color: BG.rgb(1, 1, 0.85), intensity: Double(glint))
                }
            }

            // Strong gusts fold the leaflets up toward the stem.
            let fold = BG.smoothstep(0.6, 0.9, gust) * 0.4
            let dew = BG.smoothstep(0.12, 0.2, life) * (1 - BG.smoothstep(0.45, 0.55, life))
            let tremble = sin(t * 0.7 + CGFloat(s)) * 0.08 + gust * 0.12 * sin(t * 3 + CGFloat(s))
            for j in 0..<4 {
                let three = -CGFloat.pi / 2 + CGFloat(min(j, 2)) * 2 * CGFloat.pi / 3
                let four = -CGFloat.pi / 2 + CGFloat(j) * CGFloat.pi / 2
                let angle = BG.lerp(three, four, fourth) + tremble
                let share: CGFloat = j == 3 ? fourth : 1
                guard share > 0.02 else { continue }
                let spread = leafSize * 0.48 * (1 - fold * 0.5)
                let center = CGPoint(x: top.x + cos(angle) * spread, y: top.y + sin(angle) * spread)
                drawLeaflet(in: &plant, at: center, size: leafSize * share, rotation: Double(angle + CGFloat.pi / 2), unfurl: unfurl * (1 - fold))
                if dew > 0.02 && j < 1 + Int(BG.hash(seed, 47) * 3) {
                    let bead = CGPoint(x: center.x + cos(angle) * leafSize * 0.12, y: center.y + sin(angle) * leafSize * 0.12)
                    plant.fill(BG.circle(bead, 1.5), with: .color(BG.rgb(0.9, 1, 0.95, 0.85 * Double(dew))))
                    let glint = pow(max(0, sin(t * 3 + CGFloat(j + s))), 8) * dew
                    if glint > 0.1 {
                        plant.sparkle(at: bead, size: 4, color: .white, intensity: Double(glint))
                    }
                }
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
        leaf.stroke(MarchLeaflet.midrib, with: .color(BG.rgb(0.8, 1, 0.7, 0.55)), lineWidth: 0.03)
        leaf.stroke(MarchLeaflet.chevron, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.05, lineCap: .round, lineJoin: .round))
        leaf.fill(BG.ellipse(CGPoint(x: -0.18, y: -0.22), 0.08, 0.04), with: .color(.white.opacity(0.35)))
    }

    // MARK: Motes

    /// Golden motes of luck rising and twinkling; they swirl in the gusts. Tripled on
    /// St. Patrick's Day.
    static func drawMotes(in ctx: inout GraphicsContext, size: CGSize, t: CGFloat, look: MarchModel.Look, near: Bool, dark: Bool) {
        let base = near ? 8 : 18
        let count = base + Int(CGFloat(base * 2) * look.stPatrick)
        let color = dark ? BG.rgb(1, 0.85, 0.35) : BG.rgb(0.88, 0.66, 0)
        let draw: (inout GraphicsContext) -> Void = { layer in
            for i in 0..<count {
                let seed = i + (near ? 500 : 0)
                let extra = i >= base
                let appear: CGFloat = extra ? BG.clamp01((look.stPatrick * CGFloat(base * 2) - CGFloat(i - base)) / 2) : 1
                guard appear > 0.01 else { continue }
                let speed = BG.hash(seed, 51, 10, 24)
                let span = size.height * (near ? 0.7 : 0.9)
                let progress = BG.fract(BG.hash(seed, 52) + t * speed / span)
                let y = size.height - progress * span
                let swirl = sin(t * 0.5 + CGFloat(i)) * 22
                let x = BG.wrap(BG.hash(seed, 53) * size.width + swirl + look.drift * (near ? 0.5 : 0.3), length: size.width, margin: 20)
                let twinkle = pow(max(0, sin(t * BG.hash(seed, 54, 1, 2.5) + BG.hash(seed, 55) * 6.28)), 3)
                let fade = BG.smoothstep(0, 0.15, progress) * (1 - BG.smoothstep(0.75, 1, progress))
                let intensity = Double(twinkle * fade * appear)
                guard intensity > 0.01 else { continue }
                let p = CGPoint(x: x, y: y)
                layer.glow(at: p, radius: near ? 20 : 14, color: color, intensity: intensity * 0.5, additive: dark)
                layer.sparkle(at: p, size: BG.hash(seed, 56, 4, 8) * (near ? 1.4 : 1), color: dark ? BG.rgb(1, 0.92, 0.6) : color, intensity: intensity)
            }
        }
        if near {
            ctx.blurredLayer(radius: 2.5) { layer in draw(&layer) }
        } else {
            draw(&ctx)
        }
    }
}

private enum MarchLeaflet {
    static let midrib: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0.45))
        path.addLine(to: CGPoint(x: 0, y: -0.28))
        return path
    }()

    /// The pale chevron clover leaflets carry.
    static let chevron: Path = {
        var path = Path()
        path.move(to: CGPoint(x: -0.24, y: -0.1))
        path.addLine(to: CGPoint(x: 0, y: 0.1))
        path.addLine(to: CGPoint(x: 0.24, y: -0.1))
        return path
    }()
}
