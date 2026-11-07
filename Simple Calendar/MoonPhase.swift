//
//  MoonPhase.swift
//  Simple Calendar
//
//  Lunar phase calculation, the discrete phase-transition animator used by the
//  October background, and a textured moon renderer with a soft terminator.
//

import SwiftUI

// MARK: - Astronomy

enum MoonPhase {
    /// 2000-01-01 12:00 UTC (J2000.0).
    private static let j2000 = Date(timeIntervalSince1970: 946_728_000)

    /// Phase at an instant as a fraction of the synodic cycle:
    /// 0 = new, 0.25 = first quarter, 0.5 = full, 0.75 = last quarter.
    ///
    /// Uses the Sun's and Moon's apparent ecliptic longitudes with the dominant
    /// periodic terms (equation of center, evection, variation, annual equation),
    /// which lands within about half an hour of published new/full moon times.
    static func fraction(at date: Date) -> Double {
        let d = date.timeIntervalSince(j2000) / 86_400
        func rad(_ degrees: Double) -> Double { degrees * .pi / 180 }

        let sunAnomaly = 357.5291 + 0.98560028 * d
        let sunLongitude = 280.4665 + 0.98564736 * d
            + 1.9148 * sin(rad(sunAnomaly))
            + 0.0200 * sin(rad(2 * sunAnomaly))

        let moonMeanLongitude = 218.3165 + 13.17639648 * d
        let moonAnomaly = 134.9634 + 13.06499295 * d
        let elongation = 297.8502 + 12.19074912 * d
        let latitudeArgument = 93.2721 + 13.22935024 * d

        var moonLongitude = moonMeanLongitude
        moonLongitude += 6.2888 * sin(rad(moonAnomaly))
        moonLongitude += 1.2740 * sin(rad(2 * elongation - moonAnomaly))
        moonLongitude += 0.6583 * sin(rad(2 * elongation))
        moonLongitude += 0.2136 * sin(rad(2 * moonAnomaly))
        moonLongitude -= 0.1856 * sin(rad(sunAnomaly))
        moonLongitude -= 0.1143 * sin(rad(2 * latitudeArgument))
        moonLongitude += 0.0588 * sin(rad(2 * elongation - 2 * moonAnomaly))
        moonLongitude += 0.0572 * sin(rad(2 * elongation - sunAnomaly - moonAnomaly))
        moonLongitude += 0.0533 * sin(rad(2 * elongation + moonAnomaly))

        let phase = (moonLongitude - sunLongitude) / 360
        return phase - floor(phase)
    }

    /// Phase for a calendar day, sampled at local noon so the whole day maps to one look.
    static func fraction(forDay date: Date, calendar: Calendar = .current) -> Double {
        let start = calendar.startOfDay(for: date)
        let noon = calendar.date(byAdding: .hour, value: 12, to: start) ?? start
        return fraction(at: noon)
    }

    /// Illuminated fraction of the disc (0 = new, 1 = full).
    static func illumination(_ phase: Double) -> Double {
        (1 - cos(2 * .pi * phase)) / 2
    }

    /// Signed shortest distance around the cycle from `a` to `b`, in -0.5...0.5.
    static func shortestDelta(from a: Double, to b: Double) -> Double {
        var delta = (b - a).truncatingRemainder(dividingBy: 1)
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        return delta
    }
}

// MARK: - Discrete phase animator

/// Moves the displayed moon phase toward the phase of the selected day.
///
/// Transitions never stack or retarget mid-flight: each one runs for its full
/// `duration`. Only when it completes does the animator look at the *current*
/// target (whatever the user's selection/focus is at that moment) and, if it
/// differs from what is shown, start the next transition from there.
/// Intermediate selections the user scrolled past are skipped.
final class MoonPhaseAnimator {
    let duration: Double
    private var shown: Double?
    private var from: Double = 0
    private var delta: Double = 0
    private var startTime: Double?

    init(duration: Double = 2.5) {
        self.duration = duration
    }

    /// Returns the phase to draw at `time` (seconds, monotonically increasing).
    func phase(target: Double, time: Double) -> Double {
        guard shown != nil else {
            // First appearance: show the selected day's moon as-is.
            shown = target
            return target
        }

        if let start = startTime {
            let progress = (time - start) / duration
            if progress < 1 {
                let eased = Double(BG.easeInOut(CGFloat(progress)))
                return wrap(from + delta * eased)
            }
            // Transition finished: settle exactly on its end value.
            startTime = nil
            shown = wrap(from + delta)
            return respond(to: target, time: time)
        }

        return respond(to: target, time: time)
    }

    private func respond(to target: Double, time: Double) -> Double {
        let current = shown ?? target
        let difference = MoonPhase.shortestDelta(from: current, to: target)
        if abs(difference) > 0.0005 {
            from = current
            delta = difference
            startTime = time
        }
        return current
    }

    private func wrap(_ value: Double) -> Double {
        value - floor(value)
    }
}

// MARK: - Moon renderer

enum MoonPainter {
    private struct Mare {
        let x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, angle: CGFloat
    }

    private struct Crater {
        let x: CGFloat, y: CGFloat, size: CGFloat, rays: Bool
    }

    /// Approximate near-side maria, in units of the moon's radius.
    private static let maria: [Mare] = [
        Mare(x: -0.55, y: -0.05, rx: 0.26, ry: 0.48, angle: 0.15),  // Oceanus Procellarum
        Mare(x: -0.28, y: -0.42, rx: 0.27, ry: 0.19, angle: -0.2),  // Imbrium
        Mare(x: 0.12, y: -0.38, rx: 0.15, ry: 0.14, angle: 0),      // Serenitatis
        Mare(x: 0.28, y: -0.12, rx: 0.2, ry: 0.15, angle: 0.35),    // Tranquillitatis
        Mare(x: 0.66, y: -0.3, rx: 0.11, ry: 0.09, angle: 0),       // Crisium
        Mare(x: 0.52, y: 0.12, rx: 0.11, ry: 0.17, angle: 0.2),     // Fecunditatis
        Mare(x: -0.18, y: 0.3, rx: 0.17, ry: 0.13, angle: 0),       // Nubium
        Mare(x: 0.33, y: 0.25, rx: 0.08, ry: 0.08, angle: 0),       // Nectaris
        Mare(x: 0.0, y: -0.2, rx: 0.08, ry: 0.06, angle: 0),        // Vaporum
        Mare(x: -0.45, y: 0.36, rx: 0.09, ry: 0.09, angle: 0)       // Humorum
    ]

    private static let craters: [Crater] = {
        var list: [Crater] = [
            Crater(x: -0.1, y: 0.72, size: 0.06, rays: true),    // Tycho
            Crater(x: -0.3, y: -0.12, size: 0.06, rays: true),   // Copernicus
            Crater(x: -0.56, y: -0.08, size: 0.035, rays: false), // Kepler
            Crater(x: -0.12, y: -0.7, size: 0.05, rays: false),  // Plato
            Crater(x: -0.68, y: -0.3, size: 0.03, rays: false)   // Aristarchus
        ]
        for i in 0..<18 {
            let angle = BG.hash(i, 801) * 2 * .pi
            let distance = sqrt(BG.hash(i, 802)) * 0.85
            list.append(Crater(
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: BG.hash(i, 803, 0.018, 0.05),
                rays: false
            ))
        }
        return list
    }()

    /// Draws the moon at `phase` (0 new ... 0.5 full ... 1 new), lit from the right while waxing.
    static func draw(in ctx: inout GraphicsContext, center c: CGPoint, radius r: CGFloat, phase: Double) {
        let lit = MoonPhase.illumination(phase)
        let moonlight = BG.rgb(0.82, 0.88, 1)

        // Halo scales with how much of the disc is lit.
        ctx.glow(at: c, radius: r * 4.2, color: moonlight, intensity: 0.06 + 0.24 * lit)
        ctx.glow(at: c, radius: r * 1.7, color: moonlight, intensity: 0.08 + 0.3 * lit)

        // Earthshine: the unlit disc, faint and cool.
        var dark = ctx
        dark.opacity = 0.45
        dark.addFilter(.colorMultiply(BG.rgb(0.34, 0.4, 0.58)))
        dark.drawLayer { layer in
            surface(in: &layer, center: c, radius: r)
        }

        // Sunlit part, masked with a blurred terminator so the shadow edge is soft.
        ctx.drawLayer { layer in
            layer.clipToLayer { mask in
                mask.addFilter(.blur(radius: r * 0.06))
                mask.fill(litPath(center: c, radius: r, phase: phase), with: .color(.white))
            }
            surface(in: &layer, center: c, radius: r)
        }
    }

    /// Region of the disc lit by the sun. The limb side extends past the disc so
    /// the blurred mask only softens the terminator, not the moon's edge.
    static func litPath(center c: CGPoint, radius r: CGFloat, phase: Double) -> Path {
        let p = phase - floor(phase)
        let waxing = p <= 0.5
        let q = waxing ? p : 1 - p
        let squeeze = CGFloat(cos(2 * .pi * q)) // +1 new ... 0 quarter ... -1 full
        let outer = r * 1.2
        let steps = 48

        var path = Path()
        path.move(to: CGPoint(x: 0, y: -r))
        path.addLine(to: CGPoint(x: 0, y: -outer))
        for i in 0...steps {
            let a = -CGFloat.pi / 2 + CGFloat.pi * CGFloat(i) / CGFloat(steps)
            path.addLine(to: CGPoint(x: cos(a) * outer, y: sin(a) * outer))
        }
        path.addLine(to: CGPoint(x: 0, y: r))
        for i in 0...steps {
            let y = r - 2 * r * CGFloat(i) / CGFloat(steps)
            let x = squeeze * sqrt(max(0, r * r - y * y))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()

        var transform = CGAffineTransform(translationX: c.x, y: c.y)
        if !waxing {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        return path.applying(transform)
    }

    /// Fully lit lunar surface: limb darkening, maria, craters and ray systems.
    private static func surface(in ctx: inout GraphicsContext, center c: CGPoint, radius r: CGFloat) {
        let discPath = BG.circle(c, r)
        var disc = ctx
        disc.clip(to: discPath)

        disc.fill(
            discPath,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: BG.rgb(0.99, 0.98, 0.94), location: 0),
                    .init(color: BG.rgb(0.91, 0.9, 0.87), location: 0.6),
                    .init(color: BG.rgb(0.74, 0.74, 0.76), location: 1)
                ]),
                center: CGPoint(x: c.x - r * 0.12, y: c.y - r * 0.15),
                startRadius: 0,
                endRadius: r * 1.15
            )
        )

        // Maria, softened as one layer.
        disc.blurredLayer(radius: r * 0.045) { layer in
            for mare in maria {
                let transform = CGAffineTransform(rotationAngle: mare.angle)
                    .concatenating(CGAffineTransform(translationX: c.x + mare.x * r, y: c.y + mare.y * r))
                let shape = BG.ellipse(.zero, mare.rx * r, mare.ry * r).applying(transform)
                layer.fill(shape, with: .color(BG.rgb(0.5, 0.52, 0.58, 0.55)))
            }
        }

        // Regolith speckle.
        for i in 0..<70 {
            let angle = BG.hash(i, 811) * 2 * .pi
            let distance = sqrt(BG.hash(i, 812)) * r
            let p = CGPoint(x: c.x + cos(angle) * distance, y: c.y + sin(angle) * distance)
            let shade = BG.hash(i, 813) < 0.5 ? Color.black : Color.white
            disc.fill(BG.circle(p, r * BG.hash(i, 814, 0.006, 0.016)), with: .color(shade.opacity(0.08)))
        }

        // Craters: dark floor, shadowed wall, bright rim on the far side.
        for crater in craters {
            let p = CGPoint(x: c.x + crater.x * r, y: c.y + crater.y * r)
            let cr = crater.size * r
            if crater.rays {
                for ray in 0..<12 {
                    let a = CGFloat(ray) / 12 * 2 * .pi + BG.hash(ray, 820) * 0.3
                    let length = r * BG.hash(ray, 821, 0.25, 0.8)
                    var line = Path()
                    line.move(to: p)
                    line.addLine(to: CGPoint(x: p.x + cos(a) * length, y: p.y + sin(a) * length))
                    disc.stroke(line, with: .color(.white.opacity(0.13)), lineWidth: r * 0.014)
                }
            }
            let bowl = BG.circle(p, cr)
            disc.fill(bowl, with: .color(BG.rgb(0.58, 0.58, 0.6, 0.45)))
            disc.fill(
                bowl,
                with: .linearGradient(
                    Gradient(colors: [.black.opacity(0.28), .clear, .white.opacity(0.35)]),
                    startPoint: CGPoint(x: p.x - cr, y: p.y - cr),
                    endPoint: CGPoint(x: p.x + cr, y: p.y + cr)
                )
            )
            disc.stroke(bowl, with: .color(.white.opacity(0.18)), lineWidth: max(0.5, cr * 0.18))
        }
    }
}
