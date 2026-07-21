//
//  MonthAnimations.swift
//  Calendar Play
//
//  Created by Nathan Fennel on 11/23/25.
//

import SwiftUI
import Combine

// Helper for deterministic random numbers
struct LinearCongruentialGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: Int) { self.state = UInt64(seed) }
    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}

// MARK: - January: Snow Fall Animation
struct JanuarySnowAnimation: View {
    let alpha: Double
    @State private var snowflakes: [Snowflake] = []
    @State private var spawnTimer: Timer?

    struct Snowflake: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
    }

    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(snowflakes) { flake in
                    Circle()
                        .fill(Color.white.opacity(flake.opacity * alpha))
                        .frame(width: flake.size, height: flake.size)
                        .position(x: flake.x, y: flake.y)
                }
            }
            .onAppear {
                startSnowfall(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startSnowfall(size: newSize)
            }
            .onDisappear {
                spawnTimer?.invalidate()
            }
        }
    }

    private func startSnowfall(size: CGSize) {
        spawnTimer?.invalidate()
        snowflakes = []

        // Initial snowflakes scattered
        for _ in 0..<50 {
            addSnowflake(size: size, startRandomY: true)
        }

        // Continuous snowfall
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if snowflakes.count < 150 {
                addSnowflake(size: size)
            }
        }
    }
    
    private func addSnowflake(size: CGSize, startRandomY: Bool = false) {
        let startX = CGFloat.random(in: -50...size.width + 50)
        let startY = startRandomY ? CGFloat.random(in: -50...size.height) : -30
        let endY = size.height + 50
        
        let size = CGFloat.random(in: 2...6)
        // Depth effect: Larger flakes fall faster
        let speedFactor = size / 4.0 // 0.5 to 1.5
        let baseDuration = Double.random(in: 12...24)
        let duration = baseDuration / speedFactor
        
        let flake = Snowflake(
            x: startX,
            y: startY,
            size: size,
            opacity: Double.random(in: 0.3...0.8)
        )
        
        let id = flake.id
        snowflakes.append(flake)
        
        // Animate falling
        withAnimation(.linear(duration: duration)) {
            if let index = snowflakes.firstIndex(where: { $0.id == id }) {
                snowflakes[index].y = endY
                // Add some drift? Simplified to linear for now, or could use KeyframeAnimation in iOS 17, 
                // but standard Animation is safer for now. 
                // To add drift, we'd need more complex state, but simple falling is robust.
                snowflakes[index].x += CGFloat.random(in: -50...50)
            }
        }
        
        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            snowflakes.removeAll { $0.id == id }
        }
    }
}

// MARK: - February: Heart Clouds Animation
struct FebruaryHeartCloudsAnimation: View {
    let alpha: Double
    @State private var clouds: [HeartCloud] = []
    @State private var sineWaveTime: Double = 0
    @State private var sineTimer: Timer?
    @State private var cloudSpawnTimer: Timer?
    
    struct HeartCloud: Identifiable {
        let id = UUID()
        var x: CGFloat
        var baseY: CGFloat // Base Y position
        var size: CGFloat
        var sinePhase: Double // Phase offset for sine wave
        var sineAmplitude: CGFloat // Amplitude of sine wave movement
        var seed: Int = 0
        var isHeart: Bool = true
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Add snow to February
                JanuarySnowAnimation(alpha: alpha)
                
                ForEach(clouds) { cloud in
                    FebruaryCloudView(cloud: cloud, alpha: alpha, sineWaveTime: sineWaveTime)
                }
            }
            .onAppear {
                startClouds(size: geometry.size)
                startSineWave()
            }
            .onChange(of: geometry.size) { _, newSize in
                startClouds(size: newSize)
                startSineWave()
            }
            .onDisappear {
                sineTimer?.invalidate()
                cloudSpawnTimer?.invalidate()
            }
        }
    }

    private func startSineWave() {
        // Slow sine wave animation (one complete cycle every 12-15 seconds)
        sineTimer?.invalidate()
        sineTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            sineWaveTime += 0.01 // Slow increment for smooth sine wave
            if sineWaveTime > 2 * .pi {
                sineWaveTime = 0 // Reset to prevent overflow
            }
        }
    }

    private func startClouds(size: CGSize) {
        cloudSpawnTimer?.invalidate()
        clouds = []
        // More clouds (3-4 instead of 1-2)
        let cloudCount = Int.random(in: 3...4)
        for _ in 0..<cloudCount {
            let cloud = HeartCloud(
                x: CGFloat.random(in: -200...size.width + 200),
                baseY: CGFloat.random(in: size.height * 0.1...size.height * 0.8), // More vertical spread
                size: CGFloat.random(in: 140...180),
                sinePhase: Double.random(in: 0...2 * .pi),
                sineAmplitude: CGFloat.random(in: 25...40),
                seed: Int.random(in: 0...100),
                isHeart: Bool.random() // Mix hearts and normal clouds
            )
            clouds.append(cloud)
            
            // Animate horizontal movement
            let index = clouds.count - 1
            let startX = clouds[index].x
            let targetX = startX > size.width / 2 ? -200 : size.width + 200
            let duration = Double.random(in: 60...120) // Much slower (was 50-70)
            
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                clouds[index].x = targetX
            }
        }
        
        // Add new clouds periodically
        cloudSpawnTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            if clouds.count < 6 { // Allow more clouds
                let cloud = HeartCloud(
                    x: -200,
                    baseY: CGFloat.random(in: size.height * 0.1...size.height * 0.8),
                    size: CGFloat.random(in: 140...180),
                    sinePhase: Double.random(in: 0...2 * .pi),
                    sineAmplitude: CGFloat.random(in: 25...40),
                    seed: Int.random(in: 0...100),
                    isHeart: Bool.random()
                )
                clouds.append(cloud)
                
                let index = clouds.count - 1
                let duration = Double.random(in: 60...120) // Much slower
                
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    clouds[index].x = size.width + 200
                }
            }
        }
    }
}

private struct FebruaryCloudView: View {
    let cloud: FebruaryHeartCloudsAnimation.HeartCloud
    let alpha: Double
    let sineWaveTime: Double
    
    var body: some View {
        Group {
            if cloud.isHeart {
                HeartCloudShape(seed: cloud.seed)
                    .fill(Color.white.opacity(0.6 * alpha))
            } else {
                CloudShape(seed: cloud.seed)
                    .fill(Color.white.opacity(0.6 * alpha))
            }
        }
        .blur(radius: 10) // Fuzzier edges
        .frame(width: cloud.size, height: cloud.size * (cloud.isHeart ? 1.0 : 0.6))
        .position(
            x: cloud.x,
            y: cloud.baseY + sin(sineWaveTime + cloud.sinePhase) * cloud.sineAmplitude
        )
    }
}

struct HeartCloudShape: Shape {
    var seed: Int = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height
        
        // Create a proper heart shape base
        // Heart formula:
        // x = 16sin^3(t)
        // y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)
        // But we'll use a simpler bezier path for the main shape
        
        path.move(to: CGPoint(x: center.x, y: center.y + height * 0.45)) // Bottom tip
        
        // Left curve
        path.addCurve(
            to: CGPoint(x: center.x - width * 0.5, y: center.y - height * 0.1),
            control1: CGPoint(x: center.x - width * 0.2, y: center.y + height * 0.3),
            control2: CGPoint(x: center.x - width * 0.55, y: center.y + height * 0.1)
        )
        
        // Top left lobe
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - height * 0.2),
            control1: CGPoint(x: center.x - width * 0.45, y: center.y - height * 0.45),
            control2: CGPoint(x: center.x - width * 0.1, y: center.y - height * 0.45)
        )
        
        // Top right lobe
        path.addCurve(
            to: CGPoint(x: center.x + width * 0.5, y: center.y - height * 0.1),
            control1: CGPoint(x: center.x + width * 0.1, y: center.y - height * 0.45),
            control2: CGPoint(x: center.x + width * 0.45, y: center.y - height * 0.45)
        )
        
        // Right curve
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + height * 0.45),
            control1: CGPoint(x: center.x + width * 0.55, y: center.y + height * 0.1),
            control2: CGPoint(x: center.x + width * 0.2, y: center.y + height * 0.3)
        )
        
        path.closeSubpath()
        
        // Add "fluff" circles along the perimeter to make it look like a cloud
        // We'll add random circles based on the seed
        // Use deterministic RNG based on seed
        var rng = LinearCongruentialGenerator(seed: seed)
        // Simple pseudo-random based on seed
        let randomOffset = { (range: ClosedRange<CGFloat>, generator: inout LinearCongruentialGenerator) -> CGFloat in
            return CGFloat.random(in: range, using: &generator)
        }
        
        // Add some random circles inside to fill it out
        for _ in 0..<8 {
            let rx = randomOffset(-0.3...0.3, &rng) * width
            let ry = randomOffset(-0.3...0.3, &rng) * height
            let rSize = randomOffset(0.15...0.3, &rng) * width
            path.addEllipse(in: CGRect(x: center.x + rx - rSize/2, y: center.y + ry - rSize/2, width: rSize, height: rSize))
        }
        
        return path
    }
}

// MARK: - March: Shamrocks Growing Animation
struct MarchShamrocksAnimation: View {
    let alpha: Double
    @State private var shamrocks: [Shamrock] = []
    @State private var spawnTimer: Timer?

    struct Shamrock: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var stemHeight: CGFloat = 0
        var petalProgress: CGFloat = 0
        var isFalling: Bool = false
        var rotation: Double = 0
        var leafCount: Int = 3
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(shamrocks) { shamrock in
                    ZStack(alignment: .bottom) {
                        // Stem - at the bottom
                        Rectangle()
                            .fill(Color.green.opacity(0.8 * alpha))
                            // Make stem taller to fix detached look (overlap with petals)
                            .frame(width: 2, height: shamrock.stemHeight * 1.5)
                        
                        // Petals - at the top of the stem
                        if shamrock.stemHeight > 5 {
                            ShamrockPetalsShape(leafCount: shamrock.leafCount)
                                .fill(Color.green.opacity(0.7 * alpha))
                                .frame(width: shamrock.size, height: shamrock.size)
                                .scaleEffect(shamrock.petalProgress)
                                .offset(y: -shamrock.stemHeight) // Move up to top of stem
                        }
                    }
                    .rotationEffect(.degrees(shamrock.rotation))
                    .position(
                        x: shamrock.x,
                        y: shamrock.isFalling ? shamrock.y : geometry.size.height
                    )
                    .opacity(shamrock.isFalling ? 0 : 1)
                }
            }
            .onAppear {
                startShamrocks(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startShamrocks(size: newSize)
            }
            .onDisappear {
                spawnTimer?.invalidate()
            }
        }
    }

    private func startShamrocks(size: CGSize) {
        spawnTimer?.invalidate()
        // Start with a few shamrocks
        for _ in 0..<3 {
            addShamrock(size: size)
        }

        // Schedule new shamrocks more frequently
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            addShamrock(size: size)
        }
    }
    
    @State private var shamrockCounter = 0
    
    private func addShamrock(size: CGSize) {
        shamrockCounter += 1
        let isFourLeaf = (shamrockCounter % 4 == 0)
        
        let shamrock = Shamrock(
            x: CGFloat.random(in: size.width * 0.15...size.width * 0.85),
            y: size.height,
            size: CGFloat.random(in: 25...45),
            leafCount: isFourLeaf ? 4 : 3
        )
        let shamrockId = shamrock.id
        shamrocks.append(shamrock)
        
        let stemTargetHeight = CGFloat.random(in: 30...50)
        
        // First: grow stem (6 seconds)
        DispatchQueue.main.async {
            if let index = self.shamrocks.firstIndex(where: { $0.id == shamrockId }) {
                withAnimation(.easeOut(duration: 6)) {
                    self.shamrocks[index].stemHeight = stemTargetHeight
                }
            }
        }
        
        // Then: sprout petals (4 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if let index = self.shamrocks.firstIndex(where: { $0.id == shamrockId }) {
                withAnimation(.easeOut(duration: 4)) {
                    self.shamrocks[index].petalProgress = 1.0
                }
            }
        }
        
        // After 15 seconds total, fall over and disappear
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if let index = self.shamrocks.firstIndex(where: { $0.id == shamrockId }) {
                withAnimation(.easeIn(duration: 2)) {
                    self.shamrocks[index].isFalling = true
                    self.shamrocks[index].rotation = 90
                    self.shamrocks[index].y = size.height + 50
                }
                
                // Remove after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.shamrocks.removeAll { $0.id == shamrockId }
                }
            }
        }
    }
}

struct ShamrockPetalsShape: Shape {
    var leafCount: Int = 3
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.5 // Slightly larger base radius
        
        // Create a shamrock shape
        for i in 0..<leafCount {
            let angle = Double(i) * 2 * .pi / Double(leafCount) - .pi / 2
            let leafCenter = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * 0.3,
                y: center.y + CGFloat(sin(angle)) * radius * 0.3
            )
            // Heart-shaped leaf - larger
            path.addEllipse(in: CGRect(
                x: leafCenter.x - radius * 0.45,
                y: leafCenter.y - radius * 0.45,
                width: radius * 0.9,
                height: radius * 0.9
            ))
        }
        
        return path
    }
}

// MARK: - April: Rain with Wind Animation
struct AprilRainAnimation: View {
    let alpha: Double
    @State private var raindrops: [Raindrop] = []
    @State private var spawnTimer: Timer?

    struct Raindrop: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var length: CGFloat
        var opacity: Double
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(raindrops) { drop in
                    Capsule()
                        .fill(Color.blue.opacity(drop.opacity * alpha))
                        .frame(width: 2, height: drop.length)
                        .position(x: drop.x, y: drop.y)
                }
            }
            .onAppear {
                startRain(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startRain(size: newSize)
            }
            .onDisappear {
                spawnTimer?.invalidate()
            }
        }
    }

    private func startRain(size: CGSize) {
        spawnTimer?.invalidate()
        raindrops = []

        // Initial raindrops
        for _ in 0..<100 {
            addRaindrop(size: size, startRandomY: true)
        }

        // Continuous rain
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            if raindrops.count < 300 {
                addRaindrop(size: size)
            }
        }
    }
    
    private func addRaindrop(size: CGSize, startRandomY: Bool = false) {
        let startX = CGFloat.random(in: -50...size.width + 50)
        let startY = startRandomY ? CGFloat.random(in: -50...size.height) : -50
        let endY = size.height + 50
        
        // Rain speed and depth
        // Slower rain (half speed) with randomness for depth
        let speed = Double.random(in: 400...600) 
        let distance = endY - startY
        let duration = Double(distance) / speed
        
        // Wind slant
        let slant = CGFloat.random(in: 20...50)
        
        let drop = Raindrop(
            x: startX,
            y: startY,
            length: CGFloat.random(in: 15...25),
            opacity: Double.random(in: 0.4...0.8)
        )
        
        let id = drop.id
        raindrops.append(drop)
        
        withAnimation(.linear(duration: duration)) {
            if let index = raindrops.firstIndex(where: { $0.id == id }) {
                raindrops[index].y = endY
                raindrops[index].x += slant
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            raindrops.removeAll { $0.id == id }
        }
    }
}

// MARK: - May: Flowers Growing Animation
struct MayFlowersAnimation: View {
    let alpha: Double
    @State private var flowers: [Flower] = []
    @State private var spawnTimer: Timer?

    struct Flower: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var stemHeight: CGFloat = 0
        var petalProgress: CGFloat = 0
        var color: Color
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(flowers) { flower in
                    ZStack(alignment: .bottom) {
                        // Stem
                        Rectangle()
                            .fill(Color.green.opacity(0.8 * alpha))
                            .frame(width: 2, height: flower.stemHeight * 1.5) // Taller stems overlap with petals
                        
                        // Petals (only show when stem has grown)
                        if flower.stemHeight > 5 {
                            FlowerShape()
                                .fill(flower.color.opacity(0.8 * alpha))
                                .frame(width: flower.size * 2, height: flower.size * 2) // 2x larger petals
                                .scaleEffect(flower.petalProgress)
                                .offset(y: -flower.stemHeight) // Move up to top of stem
                        }
                    }
                    .position(
                        x: flower.x,
                        y: geometry.size.height
                    )
                }
            }
            .onAppear {
                startFlowers(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startFlowers(size: newSize)
            }
            .onDisappear {
                spawnTimer?.invalidate()
            }
        }
    }

    private func startFlowers(size: CGSize) {
        spawnTimer?.invalidate()
        // Add flowers periodically
        addFlower(size: size)
        // Make new ones bloom in 3 seconds after one fades away?
        // Actually, just consistent blooming every 3 seconds keeps the cycle going.
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            addFlower(size: size)
        }
    }
    
    private func addFlower(size: CGSize) {
        let colors: [Color] = [.pink, .purple, .yellow, .red, .orange]
        let flower = Flower(
            x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
            y: size.height,
            size: CGFloat.random(in: 20...35),
            color: colors.randomElement() ?? .pink
        )
        let flowerId = flower.id
        flowers.append(flower)
        
        let stemTargetHeight = CGFloat.random(in: 35...55)
        
        // First: grow stem (3 seconds)
        withAnimation(.easeOut(duration: 3)) {
            if let index = self.flowers.firstIndex(where: { $0.id == flowerId }) {
                self.flowers[index].stemHeight = stemTargetHeight
            }
        }
        
        // Then: sprout petals (2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 2)) {
                if let index = self.flowers.firstIndex(where: { $0.id == flowerId }) {
                    self.flowers[index].petalProgress = 1.0
                }
            }
        }
        
        // Fade away after 25 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
             withAnimation(.easeOut(duration: 2)) {
                 if let index = self.flowers.firstIndex(where: { $0.id == flowerId }) {
                    // We don't have an opacity property on Flower struct, but we control it in view?
                    // Let's add opacity to the struct logic or just remove it with animation.
                    // Since struct doesn't have opacity, let's shrink it down.
                    self.flowers[index].petalProgress = 0
                    self.flowers[index].stemHeight = 0
                 }
             }
        }
        
        // Remove after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 27) {
            self.flowers.removeAll { $0.id == flowerId }
        }
    }
}

struct FlowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // Create a simple flower shape (5 petals)
        for i in 0..<5 {
            let angle = Double(i) * 2 * .pi / 5
            let petalCenter = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * 0.45,
                y: center.y + CGFloat(sin(angle)) * radius * 0.45
            )
            path.addEllipse(in: CGRect(
                x: petalCenter.x - radius * 0.35,
                y: petalCenter.y - radius * 0.35,
                width: radius * 0.7,
                height: radius * 0.7
            ))
        }
        
        // Center circle
        path.addEllipse(in: CGRect(
            x: center.x - radius * 0.2,
            y: center.y - radius * 0.2,
            width: radius * 0.4,
            height: radius * 0.4
        ))
        
        return path
    }
}

// MARK: - June: Butterflies Animation (suggested)
// MARK: - June: Butterflies Animation
struct JuneButterfliesAnimation: View {
    let alpha: Double
    @State private var butterflies: [Butterfly] = []
    @State private var timer: Timer?
    @State private var currentSchemeIndex: Int = 0
    
    // 5 Different Color Templates
    private let schemes: [ButterflyScheme] = [
        // 1. Monarch Style (Orange/Black)
        ButterflyScheme(primary: .orange, secondary: .black, body: .black),
        // 2. Blue Morpho Style (Blue/Black)
        ButterflyScheme(primary: Color(red: 0.0, green: 0.5, blue: 1.0), secondary: .black, body: Color(white: 0.2)),
        // 3. Swallowtail Style (Yellow/Black)
        ButterflyScheme(primary: .yellow, secondary: .black, body: .black),
        // 4. Forest Green Style (Green/DarkGray)
        ButterflyScheme(primary: Color(red: 0.4, green: 0.8, blue: 0.4), secondary: Color(white: 0.2), body: Color(white: 0.2)),
        // 5. Purple Emperor (Purple/DarkPurple)
        ButterflyScheme(primary: .purple, secondary: Color(red: 0.2, green: 0.0, blue: 0.2), body: .black)
    ]
    
    struct ButterflyScheme {
        var primary: Color
        var secondary: Color
        var body: Color
    }
    
    struct Butterfly: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var scheme: ButterflyScheme
        var rotation: Double = 0
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(butterflies) { butterfly in
                    RealisticButterflyView(scheme: butterfly.scheme)
                        .frame(width: butterfly.size, height: butterfly.size)
                        .rotationEffect(.degrees(butterfly.rotation))
                        .position(x: butterfly.x, y: butterfly.y)
                }
            }
            .onAppear {
                startButterflies(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startButterflies(size: newSize)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startButterflies(size: CGSize) {
        timer?.invalidate()
        butterflies = []
        
        // Add first butterfly immediately
        addButterfly(size: size)
        
        // Schedule new butterflies every 20 seconds
        timer = Timer.scheduledTimer(
            withTimeInterval: .random(in: 12...22),
            repeats: true
        ) { _ in
            addButterfly(size: size)
        }
    }
    
    private func addButterfly(size: CGSize) {
        let startY = CGFloat.random(in: size.height * 0.2...size.height * 0.8)
        let targetY = CGFloat.random(in: size.height * 0.2...size.height * 0.8)
        
        let scheme = schemes[currentSchemeIndex]
        currentSchemeIndex = (currentSchemeIndex + 1) % schemes.count
        
        // Start off-screen left
        let butterfly = Butterfly(
            x: -60,
            y: startY,
            size: CGFloat.random(in: 30...100),
            scheme: scheme
        )
        butterflies.append(butterfly)
        
        let index = butterflies.count - 1
        let duration: Double = .random(in: 60...90)
        
        // Animate movement across screen
        withAnimation(.linear(duration: duration)) {
            butterflies[index].x = size.width + 60
            butterflies[index].y = targetY
        }
        
        // Slow rotation animation (+- 20 degrees)
        withAnimation(
            .easeInOut(
                duration: .random(
                    in: 8...12
                )
            ).repeatForever(autoreverses: true)
        ) {
            butterflies[index].rotation = Double.random(in: -20...20)
        }
        
        // Remove after crossing
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            butterflies.removeAll { $0.id == butterfly.id }
        }
    }
}

struct RealisticButterflyView: View {
    let scheme: JuneButterfliesAnimation.ButterflyScheme
    @State private var wingFlap: Double = 0
    @State private var time: Double = 0
    @State private var flapTimer: Timer?
    @State private var speedVariationPhase: Double = Double.random(in: 0...2 * .pi)
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Left Wing
                ZStack {
                    ButterflyWingShape()
                        .fill(scheme.primary)
                    ButterflyWingShape()
                        .stroke(scheme.secondary, lineWidth: 1)
                    ButterflyWingPatternShape()
                        .fill(scheme.secondary.opacity(0.6))
                }
                .frame(width: width / 2, height: height)
                // Left wing rotates along its right edge (center of body)
                .rotation3DEffect(.degrees(wingFlap), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                .position(x: width * 0.25, y: height / 2)
                
                // Right Wing (Mirrored)
                ZStack {
                    ButterflyWingShape()
                        .fill(scheme.primary)
                    ButterflyWingShape()
                        .stroke(scheme.secondary, lineWidth: 1)
                    ButterflyWingPatternShape()
                        .fill(scheme.secondary.opacity(0.6))
                }
                .frame(width: width / 2, height: height)
                .scaleEffect(x: -1, y: 1)
                // Right wing (flipped) rotates along its left edge (which is now trailing after flip)
                .rotation3DEffect(.degrees(-wingFlap), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                .position(x: width * 0.75, y: height / 2)
                
                // Body
                Capsule()
                    .fill(scheme.body)
                    .frame(width: width * 0.08, height: height * 0.55)
                    .position(x: width / 2, y: height / 2)
                
                // Antennae
                Path { path in
                    path.move(to: CGPoint(x: width * 0.46, y: height * 0.25))
                    path.addQuadCurve(to: CGPoint(x: width * 0.35, y: height * 0.05), control: CGPoint(x: width * 0.35, y: height * 0.15))
                    
                    path.move(to: CGPoint(x: width * 0.54, y: height * 0.25))
                    path.addQuadCurve(to: CGPoint(x: width * 0.65, y: height * 0.05), control: CGPoint(x: width * 0.65, y: height * 0.15))
                }
                .stroke(scheme.body, lineWidth: 1.5)
            }
        }
        .onAppear {
            startFlapping()
        }
        .onDisappear {
            flapTimer?.invalidate()
        }
    }
    
    private func startFlapping() {
        // Use a timer to manually animate the sine wave for flapping
        // This gives us complete control over the speed
        flapTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            time += 0.02
            
            // Calculate current flap frequency based on a slow sine wave
            // Varies between 0.5x and 1.5x speed over 5-10 seconds
            let slowSine = sin(time * 0.5 + speedVariationPhase) // 0.5 rad/s -> ~12s period
            let speedMultiplier = (1.0 + 0.5 * slowSine) * 0.025 + 0.25
            
            // Flap motion: fast sine wave for the actual wings
            // Base frequency ~5 Hz, modulated by speedMultiplier
            let flapFrequency = 5.0 * speedMultiplier
            
            // Update wing angle
            // Range: 0 to 60 degrees
            let rawSine = sin(time * flapFrequency * 2 * .pi)
            wingFlap = 30 + 30 * rawSine
        }
    }
}

struct ButterflyWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Draw left wing shape (anchored at right edge)
        path.move(to: CGPoint(x: w, y: h * 0.45))

        // Top Wing
        path.addCurve(
            to: CGPoint(x: w * 0.31, y: h * 0.02),
            control1: CGPoint(x: w * 0.80, y: h * 0.24),
            control2: CGPoint(x: w * 0.90, y: h * -0.05)
        )
        path.addCurve(
            to: CGPoint(x: w * CGFloat.random(in: 0.52...0.82), y: h * 0.72),
            control1: CGPoint(x: w * 0.06, y: h * 0.05),
            control2: CGPoint(x: -w * 0.10, y: h * 0.25)
        )

        // Bottom Wing
        path.move(to: CGPoint(x: w, y: h * 0.45))
        path.addCurve(
            to: CGPoint(x: w * 0.28, y: h * 0.86),
            control1: CGPoint(x: w * 0.60, y: h * 0.40),
            control2: CGPoint(x: w * 0.10, y: h * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.65),
            control1: CGPoint(x: w * 0.50, y: h * 0.98),
            control2: CGPoint(x: w * 0.90, y: h * 0.80)
        )

        path.closeSubpath()
        return path
    }
}

struct ButterflyWingPatternShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Decorative cutouts
        // Top
        path.addEllipse(in: CGRect(x: w * 0.4, y: h * 0.15, width: w * 0.3, height: h * 0.15))
        // Bottom
        path.addEllipse(in: CGRect(x: w * 0.5, y: h * 0.65, width: w * 0.25, height: h * 0.15))
        
        return path
    }
}

// MARK: - July: Fireworks Animation
struct JulyFireworksAnimation: View {
    let alpha: Double
    @State private var fireworks: [Firework] = []
    @State private var explosionCounter = 0
    @State private var spawnTimer: Timer?

    
    struct Firework: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var particles: [Particle] = []
        var explosionProgress: CGFloat = 0
        var isExploding: Bool = false
    }
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var angle: Double
        var distance: CGFloat
        var color: Color
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(fireworks) { firework in
                    // Rocket trail (when shooting up)
                    if !firework.isExploding {
                        Circle()
                            .fill(Color.orange.opacity(0.6 * alpha))
                            .frame(width: 3, height: 3)
                            .position(x: firework.x, y: firework.y)
                    }
                    
                    // Explosion particles
                    if firework.isExploding {
                        ForEach(firework.particles) { particle in
                            Circle()
                                .fill(particle.color.opacity(alpha))
                                .frame(width: 6, height: 6) // Larger particles (150%)
                                .position(
                                    x: firework.x + cos(particle.angle) * particle.distance * firework.explosionProgress,
                                    y: firework.y + sin(particle.angle) * particle.distance * firework.explosionProgress
                                )
                                .opacity((1 - firework.explosionProgress) * alpha)
                        }
                    }
                }
            }
            .onAppear {
                startFireworks(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startFireworks(size: newSize)
            }
            .onDisappear {
                spawnTimer?.invalidate()
            }
        }
    }

    private func startFireworks(size: CGSize) {
        spawnTimer?.invalidate()
        // Start first firework
        addFirework(size: size)

        // Schedule new fireworks (Twice as often -> 3.75s)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 3.75, repeats: true) { _ in
            DispatchQueue.main.async {
                explosionCounter += 1
                
                var count = 1
                // Every 7th -> group of 7
                if explosionCounter % 7 == 0 {
                    count = 7
                }
                // Every 3rd (and not 7th) -> group of 3
                else if explosionCounter % 3 == 0 {
                    count = 3
                }
                // Default random small group
                else {
                    count = Int.random(in: 1...2)
                }
                
                for _ in 0..<count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                        addFirework(size: size)
                    }
                }
            }
        }
    }
    
    private func addFirework(size: CGSize) {
        let startX = CGFloat.random(in: size.width * 0.2...size.width * 0.8)
        let explosionY = CGFloat.random(in: size.height * 0.15...size.height * 0.35)
        let firework = Firework(
            x: startX,
            y: size.height, // Start from bottom
            particles: [],
            isExploding: false // Will explode after shooting up
        )
        
        // Create particles
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
        var particles: [Particle] = []
        let minIntensity = CGFloat.random(in: 1...5) * 50
        let numberOfParticles = sqrt(minIntensity) * 4
        for i in 0..<(max(Int(numberOfParticles), 30)) {
            let angle = Double(i) * 2 * .pi / 30
            particles.append(Particle(
                x: firework.x,
                y: firework.y,
                angle: angle,
                distance: CGFloat.random(in: minIntensity...(minIntensity + 50)),
                color: colors.randomElement() ?? .red
            ))
        }
        
        var newFirework = firework
        newFirework.particles = particles
        fireworks.append(newFirework)
        
        let index = fireworks.count - 1
        
        // First: shoot up (2 seconds)
        withAnimation(.easeOut(duration: 2)) {
            fireworks[index].y = explosionY
        }
        
        // Then: explode (9 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard index < fireworks.count else { return }
            fireworks[index].isExploding = true
            withAnimation(.easeOut(duration: 9)) {
                fireworks[index].explosionProgress = 1.0
            }
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
            fireworks.removeAll { $0.id == firework.id }
        }
    }
}

// MARK: - August: Sun and Clouds Animation
struct AugustSunCloudsAnimation: View {
    let alpha: Double
    @State private var sunProgress: CGFloat = 0
    @State private var sunRotation: Double = 0
    @State private var clouds: [Cloud] = []
    @State private var cloudSpawnTimer: Timer?

    struct Cloud: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var seed: Int = 0
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sun moving across sky in an arc (SF Symbol)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 140)) // 2x size
                    .foregroundColor(.yellow.opacity(0.5 * alpha)) // 0.5x opacity
                    .rotationEffect(.degrees(sunRotation))
                    .position(
                        x: geometry.size.width * sunProgress,
                        y: calculateSunArcY(progress: sunProgress, height: geometry.size.height)
                    )
                
                // Clouds floating by
                ForEach(clouds) { cloud in
                    CloudShape(seed: cloud.seed)
                        .fill(Color.white.opacity(0.6 * alpha))
                        .blur(radius: 5) // Blur effect like February
                        .frame(width: cloud.size, height: cloud.size * 0.6)
                        .position(x: cloud.x, y: cloud.y)
                }
            }
            .onAppear {
                startAnimation(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startAnimation(size: newSize)
            }
            .onDisappear {
                cloudSpawnTimer?.invalidate()
            }
        }
    }

    private func calculateSunArcY(progress: CGFloat, height: CGFloat) -> CGFloat {
        // Create a slight arc: starts at 0.15, peaks at middle (0.12), ends at 0.15
        // Using a parabolic curve for the arc
        let startY = height * 0.15
        let peakY = height * 0.12 // Higher point in the middle (arc peaks)
        let arcHeight = startY - peakY // How much higher the arc goes
        
        // Parabolic arc: y = startY - arcHeight * 4 * progress * (1 - progress)
        // This creates a smooth arc that peaks in the middle
        let arcOffset = arcHeight * 4 * progress * (1 - progress)
        return startY - arcOffset
    }
    
    private func startAnimation(size: CGSize) {
        // Sun animation (1200 seconds - 5% speed)
        // Start random transit between 0.4 and 0.6
        let startProgress = Double.random(in: 0.4...0.6)
        sunProgress = startProgress
        
        let remaining = 1.0 - startProgress
        let duration = 1200.0 * remaining // Proportional duration
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            sunProgress = 1.0
        }
        
        // Slow rotation
        withAnimation(.linear(duration: 400).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        
        // Start clouds
        startClouds(size: size)
    }
    
    private func startClouds(size: CGSize) {
        cloudSpawnTimer?.invalidate()
        // Add more initial clouds (at least 4)
        for _ in 0..<4 {
            addCloud(size: size, randomX: true)
        }

        // Add new clouds periodically
        cloudSpawnTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { _ in
            addCloud(size: size, randomX: false)
        }
    }
    
    private func addCloud(size: CGSize, randomX: Bool = false) {
        let startX = randomX ? CGFloat.random(in: -150...size.width) : -150
        let cloud = Cloud(
            x: startX,
            y: CGFloat.random(in: size.height * 0.1...size.height * 0.3),
            size: CGFloat.random(in: 200...280), // Larger clouds
            seed: Int.random(in: 0...100)
        )
        clouds.append(cloud)
        
        let index = clouds.count - 1
        
        // Move cloud across screen
        // Randomize duration slightly to prevent "unit" movement
        let duration = Double.random(in: 60...100) // Much slower
        
        // Calculate remaining distance if starting in middle
        let remainingDistance = size.width + 150 - startX
        let totalDistance = size.width + 300
        let adjustedDuration = duration * (Double(remainingDistance) / Double(totalDistance))
        
        withAnimation(.linear(duration: adjustedDuration).repeatForever(autoreverses: false)) {
            clouds[index].x = size.width + 150
        }
        
        // Remove after crossing
        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration) {
            clouds.removeAll { $0.id == cloud.id }
        }
    }
}

struct CloudShape: Shape {
    var seed: Int = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // Use deterministic RNG
        var rng = LinearCongruentialGenerator(seed: seed)
        let randomOffset = { (range: ClosedRange<CGFloat>, generator: inout LinearCongruentialGenerator) -> CGFloat in
             return CGFloat.random(in: range, using: &generator)
        }
        
        // Base cloud
        path.addEllipse(in: CGRect(x: center.x - radius * 1.0, y: center.y - radius * 0.4, width: radius * 0.7, height: radius * 0.7))
        path.addEllipse(in: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.6, width: radius * 0.9, height: radius * 0.9))
        path.addEllipse(in: CGRect(x: center.x, y: center.y - radius * 0.5, width: radius * 1.0, height: radius * 1.0))
        path.addEllipse(in: CGRect(x: center.x + radius * 0.5, y: center.y - radius * 0.4, width: radius * 0.8, height: radius * 0.8))
        path.addEllipse(in: CGRect(x: center.x + radius * 0.3, y: center.y + radius * 0.1, width: radius * 0.6, height: radius * 0.6))
        
        // Add random variation based on seed
        for _ in 0..<3 {
            let rx = randomOffset(-0.8...0.8, &rng) * radius
            let ry = randomOffset(-0.5...0.5, &rng) * radius
            let rSize = randomOffset(0.6...0.9, &rng) * radius
            path.addEllipse(in: CGRect(x: center.x + rx, y: center.y + ry, width: rSize, height: rSize))
        }
        
        return path
    }
}

// MARK: - September: Sun, Clouds, and Falling Leaves Animation
struct SeptemberLeavesAnimation: View {
    let alpha: Double
    @State private var sunProgress: CGFloat = 0
    @State private var sunRotation: Double = 0
    @State private var clouds: [SeptemberCloud] = []
    @State private var leaves: [Leaf] = []
    @State private var cloudSpawnTimer: Timer?
    @State private var leafSpawnTimer: Timer?

    struct SeptemberCloud: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
    }
    
    struct Leaf: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double = 0
        var size: CGFloat
        var color: Color
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sun moving across sky (SF Symbol)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 140)) // 2x size
                    .foregroundColor(.yellow.opacity(0.5 * alpha)) // 0.5x opacity
                    .rotationEffect(.degrees(sunRotation))
                    .position(
                        x: geometry.size.width * sunProgress,
                        y: geometry.size.height * 0.15
                    )
                
                // Clouds floating by
                ForEach(clouds) { cloud in
                    CloudShape()
                        .fill(Color.white.opacity(0.6 * alpha))
                        .frame(width: cloud.size, height: cloud.size * 0.6)
                        .position(x: cloud.x, y: cloud.y)
                        .blur(radius: 30)
                }
                
                // Falling leaves
                ForEach(leaves) { leaf in
                    LeafShape()
                        .fill(leaf.color.opacity(0.7 * alpha))
                        .frame(width: leaf.size, height: leaf.size)
                        .rotationEffect(.degrees(leaf.rotation))
                        .position(x: leaf.x, y: leaf.y)
                }
            }
            .onAppear {
                startAnimation(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                startAnimation(size: newSize)
            }
            .onDisappear {
                cloudSpawnTimer?.invalidate()
                leafSpawnTimer?.invalidate()
            }
        }
    }

    private func startAnimation(size: CGSize) {
        // Sun animation (4000 seconds - 5% speed)
        // Start random transit between 0.6 and 0.8
        let startProgress = Double.random(in: 0.6...0.8)
        sunProgress = startProgress
        
        let remaining = 1.0 - startProgress
        let duration = 4000.0 * remaining
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            sunProgress = 1.0
        }
        
        // Slow rotation (slower)
        withAnimation(.linear(duration: 1400).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        
        // Start clouds
        startClouds(size: size)
        
        // Start leaves
        startLeaves(size: size)
    }
    
    private func startClouds(size: CGSize) {
        cloudSpawnTimer?.invalidate()
        // Add initial clouds
        for _ in 0..<4 {
            addCloud(size: size, randomX: true)
        }

        // Add new clouds periodically
        cloudSpawnTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { _ in
            addCloud(size: size, randomX: false)
        }
    }
    
    private func addCloud(size: CGSize, randomX: Bool = false) {
        let startX = randomX ? CGFloat.random(in: -150...size.width) : -150
        let cloud = SeptemberCloud(
            x: startX,
            y: CGFloat.random(in: size.height * 0.05...size.height * 0.6), // Wider Y range
            size: CGFloat.random(in: 200...350) // Larger clouds
        )
        clouds.append(cloud)
        
        let index = clouds.count - 1
        
        // Move cloud across screen
        // Randomize duration slightly to prevent "unit" movement
        let duration = Double.random(in: 70...120) // Much slower (70% slower approx)
        
        // Calculate remaining distance if starting in middle
        let remainingDistance = size.width + 150 - startX
        let totalDistance = size.width + 300
        let adjustedDuration = duration * (Double(remainingDistance) / Double(totalDistance))
        
        withAnimation(.linear(duration: adjustedDuration).repeatForever(autoreverses: false)) {
            clouds[index].x = size.width + 150
        }
        
        // Remove after crossing
        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration) {
            clouds.removeAll { $0.id == cloud.id }
        }
    }
    
    private func startLeaves(size: CGSize) {
        leafSpawnTimer?.invalidate()
        // Add fewer leaves (half the amount)
        for _ in 0..<10 {
            addLeaf(size: size, delay: Double.random(in: 0...3))
        }
        leafSpawnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in // Slower spawn rate
            addLeaf(size: size)
        }
    }
    
    private func addLeaf(size: CGSize, delay: Double = 0) {
        let colors: [Color] = [.orange, .red, .yellow, .brown]
        let leaf = Leaf(
            x: CGFloat.random(in: -50...size.width + 50),
            y: -30,
            size: CGFloat.random(in: 18...28),
            color: colors.randomElement() ?? .orange
        )
        let leafId = leaf.id
        leaves.append(leaf)
        
        let duration = Double.random(in: 6...9) // Slower fall
        let newRotation = Double.random(in: 360...1080)
        let xOffset = CGFloat.random(in: -80...80)
        
        // Fall and rotate (slower)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let index = self.leaves.firstIndex(where: { $0.id == leafId }) else { return }
            
            // Ensure index is still valid before accessing
            guard index < self.leaves.count else { return }
            
            withAnimation(.easeIn(duration: duration)) {
                // Check again inside animation block
                if let currentIndex = self.leaves.firstIndex(where: { $0.id == leafId }),
                   currentIndex < self.leaves.count {
                    self.leaves[currentIndex].y = size.height + 50
                    self.leaves[currentIndex].rotation = newRotation
                    self.leaves[currentIndex].x += xOffset
                }
            }
        }
        
        // Remove after falling
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration) {
            self.leaves.removeAll { $0.id == leafId }
        }
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height
        
        // More realistic leaf shape with pointed tip and rounded base
        // Start at tip (top)
        path.move(to: CGPoint(x: center.x, y: center.y - height * 0.5))
        
        // Left side with curves
        path.addQuadCurve(
            to: CGPoint(x: center.x - width * 0.35, y: center.y - height * 0.1),
            control: CGPoint(x: center.x - width * 0.2, y: center.y - height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - width * 0.25, y: center.y + height * 0.2),
            control: CGPoint(x: center.x - width * 0.3, y: center.y + height * 0.05)
        )
        
        // Bottom curve
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + height * 0.45),
            control: CGPoint(x: center.x - width * 0.1, y: center.y + height * 0.35)
        )
        
        // Right side (mirror)
        path.addQuadCurve(
            to: CGPoint(x: center.x + width * 0.25, y: center.y + height * 0.2),
            control: CGPoint(x: center.x + width * 0.1, y: center.y + height * 0.35)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x + width * 0.35, y: center.y - height * 0.1),
            control: CGPoint(x: center.x + width * 0.3, y: center.y + height * 0.05)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - height * 0.5),
            control: CGPoint(x: center.x + width * 0.2, y: center.y - height * 0.3)
        )
        
        path.closeSubpath()
        
        // Add a stem line at the bottom
        path.move(to: CGPoint(x: center.x, y: center.y + height * 0.45))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height * 0.5))
        
        return path
    }
}

// MARK: - October: Moon and Bats Animation
// MARK: - October: Moon and Bats Animation
struct OctoberMoonBatsAnimation: View {
    let alpha: Double
    @State private var moonProgress: CGFloat = 0
    @State private var clouds: [Cloud] = []
    @State private var bats: [BatBoid] = []
    @State private var timer: Timer?
    @State private var viewSize: CGSize = .zero
    @State private var simulationTime: Double = 0
    @State private var cloudGeneration: Int = 0

    // Boid Configuration
    struct BatBoid: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var wingFlapSpeed: Double
    }
    
    struct Cloud: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double = 0
        var seed: Int = 0
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Moon moving across top (textured)
                TexturedMoonView()
                    .opacity(0.45 * alpha) // Half opacity (was 0.9)
                    .frame(width: 160, height: 160) // 2x size (was 80)
                    .position(
                        x: geometry.size.width * moonProgress,
                        y: geometry.size.height * 0.15
                    )
                
                // Clouds floating by
                ForEach(clouds) { cloud in
                    CloudShape(seed: cloud.seed)
                        .fill(Color.gray.opacity(cloud.opacity * 0.5 * alpha))
                        .blur(radius: 5) // Blur effect
                        .frame(width: cloud.size, height: cloud.size * 0.6)
                        .position(x: cloud.x, y: cloud.y)
                }
                
                // Bats flying in murmuration
                ForEach(bats) { bat in
                    BatView(color: Color.black.opacity(0.8 * alpha), flapSpeed: bat.wingFlapSpeed)
                        .frame(width: bat.size, height: bat.size * 0.6)
                        // Rotate bat to face velocity direction
                        .rotationEffect(.radians(atan2(bat.velocity.dy, bat.velocity.dx)))
                        .position(bat.position)
                }
            }
            .onAppear {
                viewSize = geometry.size
                startAnimation(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
                startAnimation(size: newSize)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startAnimation(size: CGSize) {
        // Moon animation (1200 seconds - 5% speed)
        // Start random transit between 0.75 and 0.9
        let startProgress = Double.random(in: 0.75...0.9)
        moonProgress = startProgress
        
        let remaining = 1.0 - startProgress
        let duration = 1200.0 * remaining
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            moonProgress = 1.0
        }
        
        // Start clouds
        startClouds(size: size)
        
        // Initialize Bats for Murmuration
        initBats(size: size)
        
        // Start Simulation Timer
        timer?.invalidate()
        simulationTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            simulationTime += 0.03
            updateBats()
        }
    }
    
    // MARK: - Cloud Logic
    private func startClouds(size: CGSize) {
        // Bump the generation so any in-flight asyncAfter chain from a
        // previous call (e.g. before a resize) recognizes it's stale and stops.
        cloudGeneration += 1
        let generation = cloudGeneration
        clouds = []
        for _ in 0..<5 {
            let delay = Double.random(in: 0...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard generation == cloudGeneration else { return }
                addCloud(size: size)
            }
        }
        scheduleNextCloud(size: size, generation: generation)
    }

    private func scheduleNextCloud(size: CGSize, generation: Int) {
        let interval = Double.random(in: 10...25)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            guard generation == cloudGeneration else { return }
            addCloud(size: size)
            scheduleNextCloud(size: size, generation: generation)
        }
    }
    
    private func addCloud(size: CGSize) {
        let baseDuration = Double.random(in: 15...50) // More random speed
        let extraDuration = Double.random(in: 0...20)
        let totalDuration = baseDuration + extraDuration
        
        let cloud = Cloud(
            x: -150,
            y: CGFloat.random(in: size.height * 0.12...size.height * 0.28),
            size: CGFloat.random(in: 200...280), // Much larger
            opacity: 0,
            seed: Int.random(in: 0...100)
        )
        let cloudId = cloud.id
        clouds.append(cloud)
        
        DispatchQueue.main.async {
            if let index = self.clouds.firstIndex(where: { $0.id == cloudId }) {
                withAnimation(.easeIn(duration: 2)) {
                    self.clouds[index].opacity = 1.0
                }
            }
        }
        
        DispatchQueue.main.async {
            if let index = self.clouds.firstIndex(where: { $0.id == cloudId }) {
                withAnimation(.linear(duration: totalDuration)) {
                    self.clouds[index].x = size.width + 150
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 2) {
            if let index = self.clouds.firstIndex(where: { $0.id == cloudId }) {
                withAnimation(.easeOut(duration: 2)) {
                    self.clouds[index].opacity = 0.0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            self.clouds.removeAll { $0.id == cloudId }
        }
    }
    
    // MARK: - Murmuration Logic (Boids Algorithm)
    private func initBats(size: CGSize) {
        bats = []
        let numBats = Int.random(in: 5...20)
        
        for _ in 0..<numBats {
            bats.append(BatBoid(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: size.height * 0.2...size.height * 0.6)
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -3...3),
                    dy: CGFloat.random(in: -1...1)
                ),
                size: CGFloat.random(in: 30...50),
                wingFlapSpeed: Double.random(in: 0.1...0.2)
            ))
        }
    }
    
    private func updateBats() {
        // Parameters for flocking behavior
        let visualRange: CGFloat = 80.0
        let protectedRange: CGFloat = 25.0 // Separation distance
        var centeringFactor: CGFloat = 0.005 // Cohesion
        let avoidFactor: CGFloat = 0.08 // Separation strength
        var matchingFactor: CGFloat = 0.05 // Alignment
        let turnFactor: CGFloat = 0.4
        let maxSpeed: CGFloat = 5.0
        let minSpeed: CGFloat = 2.0
        
        // Break murmuration every 17 seconds for 5 seconds
        let cycleTime = simulationTime.truncatingRemainder(dividingBy: 22)
        if cycleTime > 17 {
            // Random dispersal mode
            centeringFactor = -0.002 // Slight repulsion from center (disperse)
            matchingFactor = 0 // No alignment
            // avoidFactor stays to keep them from crashing
        }
        
        for i in 0..<bats.count {
            var boid = bats[i]
            
            var closeDx: CGFloat = 0
            var closeDy: CGFloat = 0
            var xVelAvg: CGFloat = 0
            var yVelAvg: CGFloat = 0
            var xPosAvg: CGFloat = 0
            var yPosAvg: CGFloat = 0
            var neighbors = 0
            
            // Interaction with other bats
            for otherBoid in bats {
                if otherBoid.id == boid.id { continue }
                
                let dx = boid.position.x - otherBoid.position.x
                let dy = boid.position.y - otherBoid.position.y
                let distance = sqrt(dx*dx + dy*dy)
                
                // Separation
                if distance < protectedRange {
                    closeDx += dx
                    closeDy += dy
                }
                
                // Alignment & Cohesion
                if distance < visualRange {
                    xVelAvg += otherBoid.velocity.dx
                    yVelAvg += otherBoid.velocity.dy
                    xPosAvg += otherBoid.position.x
                    yPosAvg += otherBoid.position.y
                    neighbors += 1
                }
            }
            
            // 1. Separation
            boid.velocity.dx += closeDx * avoidFactor
            boid.velocity.dy += closeDy * avoidFactor
            
            if neighbors > 0 {
                // 2. Alignment
                xVelAvg /= CGFloat(neighbors)
                yVelAvg /= CGFloat(neighbors)
                boid.velocity.dx += (xVelAvg - boid.velocity.dx) * matchingFactor
                boid.velocity.dy += (yVelAvg - boid.velocity.dy) * matchingFactor
                
                // 3. Cohesion
                xPosAvg /= CGFloat(neighbors)
                yPosAvg /= CGFloat(neighbors)
                boid.velocity.dx += (xPosAvg - boid.position.x) * centeringFactor
                boid.velocity.dy += (yPosAvg - boid.position.y) * centeringFactor
            }
            
            // Screen Edges (Soft turning)
            let margin: CGFloat = 50
            if boid.position.x < margin {
                boid.velocity.dx += turnFactor
            }
            if boid.position.x > viewSize.width - margin {
                boid.velocity.dx -= turnFactor
            }
            if boid.position.y < margin + 50 { // Keep away from top/moon
                boid.velocity.dy += turnFactor
            }
            if boid.position.y > viewSize.height * 0.7 { // Keep in upper/mid sky
                boid.velocity.dy -= turnFactor
            }
            
            // Update Position
            boid.position.x += boid.velocity.dx
            boid.position.y += boid.velocity.dy
            
            // Speed Limit
            let speed = sqrt(boid.velocity.dx * boid.velocity.dx + boid.velocity.dy * boid.velocity.dy)
            if speed > maxSpeed {
                boid.velocity.dx = (boid.velocity.dx / speed) * maxSpeed
                boid.velocity.dy = (boid.velocity.dy / speed) * maxSpeed
            } else if speed < minSpeed && speed > 0 {
                boid.velocity.dx = (boid.velocity.dx / speed) * minSpeed
                boid.velocity.dy = (boid.velocity.dy / speed) * minSpeed
            }
            
            bats[i] = boid
        }
    }
}

struct TexturedMoonView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Base Sphere with 3D-like shading (Light top-left, dark bottom-right)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color(white: 0.96), Color(white: 0.80)]),
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: size * 0.1,
                            endRadius: size * 0.9
                        )
                    )
                
                // Craters and Mares
                Group {
                    // Large Mare (Dark patch)
                    Ellipse()
                        .fill(Color(white: 0.6)) // Darker for contrast
                        .frame(width: size * 0.4, height: size * 0.3)
                        .offset(x: -size * 0.15, y: -size * 0.1)
                        .rotationEffect(.degrees(15))
                    
                    Ellipse()
                        .fill(Color(white: 0.55)) // Darker for contrast
                        .frame(width: size * 0.3, height: size * 0.25)
                        .offset(x: size * 0.2, y: size * 0.25)
                        .rotationEffect(.degrees(-10))
                    
                    // Distinct Craters
                    Group {
                        MoonCrater(size: size * 0.18).offset(x: size * 0.15, y: -size * 0.2)
                        MoonCrater(size: size * 0.14).offset(x: -size * 0.25, y: size * 0.15)
                        MoonCrater(size: size * 0.10).offset(x: -size * 0.1, y: -size * 0.25)
                        MoonCrater(size: size * 0.08).offset(x: size * 0.3, y: size * 0.05)
                        MoonCrater(size: size * 0.06).offset(x: 0, y: size * 0.35)
                        MoonCrater(size: size * 0.05).offset(x: -size * 0.3, y: -size * 0.1)
                        // Extra craters
                        MoonCrater(size: size * 0.04).offset(x: size * 0.1, y: size * 0.3)
                        MoonCrater(size: size * 0.03).offset(x: -size * 0.15, y: -size * 0.05)
                        MoonCrater(size: size * 0.05).offset(x: size * 0.25, y: -size * 0.25)
                        MoonCrater(size: size * 0.04).offset(x: -size * 0.05, y: size * 0.05)
                        MoonCrater(size: size * 0.03).offset(x: size * 0.05, y: -size * 0.35)
                        MoonCrater(size: size * 0.02).offset(x: -size * 0.35, y: size * 0.2)
                    }
                }
                .clipShape(Circle()) // Keep textures inside the moon sphere
                
                // Subtle Rim Light / Glow for contrast
                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: size * 0.02)
            }
        }
    }
}

// Helper view for craters
struct MoonCrater: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Crater base
            Circle()
                .fill(Color(white: 0.5)) // Darker for contrast against 0.9 moon
            
            // Inner shadow for depth (offset to bottom right to match moon lighting)
            Circle()
                .fill(Color(white: 0.65))
                .scaleEffect(0.7)
                .offset(x: size * 0.08, y: size * 0.08)
                .blur(radius: size * 0.05)
        }
        .frame(width: size, height: size)
    }
}

struct BatView: View {
    let color: Color
    var flapSpeed: Double = 0.15
    @State private var wingFlap: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Body
                Ellipse()
                    .fill(color)
                    .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.5)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Left Wing
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.5))
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: geometry.size.height * 0.2),
                        control: CGPoint(x: geometry.size.width * 0.1, y: geometry.size.height * 0.1)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width * 0.4, y: geometry.size.height * 0.6),
                        control: CGPoint(x: geometry.size.width * 0.1, y: geometry.size.height * 0.8)
                    )
                    path.closeSubpath()
                }
                .fill(color)
                // Flap animation using scale on Y axis to simulate 3D flapping
                .scaleEffect(y: wingFlap, anchor: .trailing)
                
                // Right Wing
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.5))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.2),
                        control: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.height * 0.1)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height * 0.6),
                        control: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8)
                    )
                    path.closeSubpath()
                }
                .fill(color)
                // Flap animation using scale on Y axis
                .scaleEffect(y: wingFlap, anchor: .leading)
            }
        }
        .onAppear {
            // Flap wings
            withAnimation(.easeInOut(duration: flapSpeed).repeatForever(autoreverses: true)) {
                wingFlap = -0.5 // Flap up/down
            }
        }
    }
}

// MARK: - November: Leaves Blowing Animation
// MARK: - November: Leaves Blowing Animation
struct NovemberLeavesAnimation: View {
    let alpha: Double
    @State private var leaves: [FallingLeaf] = []
    @State private var timer: Timer?
    @State private var animationTime: Double = 0
    @State private var viewSize: CGSize = .zero
    
    struct FallingLeaf: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double = 0
        var size: CGFloat
        var color: Color
        var speed: Double
        var drift: Double
        var startTime: Double
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(leaves) { leaf in
                    // Calculate opacity based on position: fade in at top, fade out at bottom
                    let currentY = leaf.y
                    let fadeInHeight = geometry.size.height * 0.1 // Fade in over top 10%
                    let fadeOutStart = geometry.size.height * 0.85 // Start fading out at 85% down
                    let fadeOutHeight = geometry.size.height * 0.15 // Fade out over bottom 15%
                    
                    let opacity: Double = {
                        if currentY < fadeInHeight {
                            // Fading in at top
                            return Double(currentY / fadeInHeight)
                        } else if currentY > fadeOutStart {
                            // Fading out at bottom
                            let fadeOutProgress = (currentY - fadeOutStart) / fadeOutHeight
                            return Double(1.0 - min(1.0, fadeOutProgress))
                        } else {
                            // Fully visible in middle
                            return 1.0
                        }
                    }()
                    
                    LeafShape()
                        .fill(leaf.color.opacity(opacity * 0.7 * alpha))
                        .frame(width: leaf.size, height: leaf.size)
                        .rotationEffect(.degrees(leaf.rotation))
                        .position(x: leaf.x, y: leaf.y)
                }
            }
            .onAppear {
                viewSize = geometry.size
                startLeaves()
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
                startLeaves()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startLeaves() {
        timer?.invalidate()
        leaves = [] // Reset for a clean start allows the visual of "starting over" if resized, but user wants continuous.
        // However, if we don't clear, we might get duplicates on resize. 
        // Let's clear for now as it's safer for layout changes.
        
        guard viewSize.width > 0 && viewSize.height > 0 else { return }
        
        // Add initial leaves to populate the screen immediately
        for _ in 0..<15 {
            addLeaf(startY: CGFloat.random(in: -100...viewSize.height))
        }
        
        // Create a timer that runs in .common mode so it doesn't pause during scrolling
        let checkTimer = Timer(timeInterval: 0.3, repeats: true) { _ in
            self.addLeaf(startY: -30)
        }
        RunLoop.main.add(checkTimer, forMode: .common)
        self.timer = checkTimer
    }
    
    private func addLeaf(startY: CGFloat, startTime: Double = 0) {
        let colors: [Color] = [.orange, .red, .yellow, .brown]
        let leaf = FallingLeaf(
            x: CGFloat.random(in: -50...viewSize.width + 50),
            y: startY,
            rotation: Double.random(in: 0...360),
            size: CGFloat.random(in: 20...30),
            color: colors.randomElement() ?? .orange,
            speed: 0, // Unused
            drift: 0, // Unused
            startTime: 0 // Unused
        )
        
        let id = leaf.id
        leaves.append(leaf)
        
        // Speed increased by 30% (was 30...60) -> approx 40...80
        // More variance
        let speed = Double.random(in: 20...90) 
        let distance = viewSize.height + 100 - startY
        let duration = Double(distance) / speed
        let drift = CGFloat.random(in: -50...50)
        let finalRotation = leaf.rotation + Double.random(in: 180...720)
        
        withAnimation(.easeIn(duration: duration)) {
            if let index = leaves.firstIndex(where: { $0.id == id }) {
                leaves[index].y = viewSize.height + 100
                leaves[index].x += drift
                leaves[index].rotation = finalRotation
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            leaves.removeAll { $0.id == id }
        }
    }
    

}

// MARK: - December: Christmas Lights Animation
struct DecemberChristmasLightsAnimation: View {
    let alpha: Double
    @State private var lights: [Light] = []
    @State private var windOffset: CGFloat = 0 // Wind displacement
    @State private var windTimer: Timer?
    @State private var flickerTimer: Timer?

    struct Light: Identifiable {
        let id = UUID()
        var x: CGFloat
        var baseY: CGFloat // Base Y position for draping
        var brightness: Double = 1.0
        var color: Color
    }
    
    init(alpha: Double = 1.0) {
        self.alpha = alpha
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Add falling snow for winter atmosphere
                JanuarySnowAnimation(alpha: alpha)
                
                // Green cord connecting lights (draping effect with wind) - drawn behind bulbs
                Path { path in
                    let startY: CGFloat = 0 // Top of screen
                    let midY = geometry.size.height * 0.07 // Slight drape
                    let endY: CGFloat = 0 // Top of screen
                    
                    // Calculate wind-affected positions
                    let startWindY = startY + windOffset * 0.1 // Top moves very little
                    let midWindY = midY + windOffset * 0.8 // Middle moves more
                    let endWindY = endY + windOffset * 0.1 // Top moves very little
                    
                    path.move(to: CGPoint(x: 0, y: startWindY))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: endWindY),
                        control: CGPoint(x: geometry.size.width / 2, y: midWindY)
                    )
                }
                .stroke(Color.green.opacity(0.6 * alpha), lineWidth: 2)
                
                // Lights along the cord (with wind movement) - drawn on top so they overlap cord
                ForEach(lights) { light in
                    VintageBulbShape()
                        .fill(light.color.opacity(light.brightness * alpha))
                        .frame(width: 10, height: 18) // Skinnier (reduced width from 14 to 10)
                        .rotationEffect(.degrees(180)) // Upside down
                        .position(
                            x: light.x,
                            y: calculateCordY(
                                x: light.x,
                                width: geometry.size.width,
                                startY: 0, // Match path start
                                midY: geometry.size.height * 0.07, // Match path mid
                                endY: 0 // Match path end
                            ) + 9 // Hang 9 pixels below the cord (half the bulb height)
                        )
                        .shadow(color: light.color.opacity(light.brightness * 0.5 * alpha), radius: 5)
                }
            }
            .onAppear {
                startLights(size: geometry.size)
                startWindAnimation()
            }
            .onChange(of: geometry.size) { _, newSize in
                windTimer?.invalidate()
                startLights(size: newSize)
                startWindAnimation()
            }
            .onDisappear {
                windTimer?.invalidate()
                flickerTimer?.invalidate()
            }
        }
    }

    /// Calculate Y position on the cord curve with wind effect
    /// Uses the same quadratic Bezier curve formula as the cord path
    private func calculateCordY(x: CGFloat, width: CGFloat, startY: CGFloat, midY: CGFloat, endY: CGFloat) -> CGFloat {
        // Normalize x position (0 to 1) for the Bezier curve parameter t
        let t = x / width
        
        // Calculate wind-affected control points (same as cord)
        let startWindY = startY + windOffset * 0.1
        let midWindY = midY + windOffset * 0.8
        let endWindY = endY + windOffset * 0.1
        
        // Quadratic Bezier curve formula: P(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
        // P₀ = start point, P₁ = control point, P₂ = end point
        let y = (1 - t) * (1 - t) * startWindY + 2 * (1 - t) * t * midWindY + t * t * endWindY
        
        return y
    }
    
    private func startWindAnimation() {
        // Occasional subtle wind gusts
        windTimer?.invalidate()
        windTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
            // Random wind strength (subtle)
            let windStrength = CGFloat.random(in: -8...8)
            let duration = Double.random(in: 3...6)
            
            // Animate wind
            withAnimation(.easeInOut(duration: duration)) {
                windOffset = windStrength
            }
            
            // Return to neutral (or slight opposite)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeInOut(duration: duration * 0.8)) {
                    windOffset = windStrength * 0.3 // Slight return, not fully neutral
                }
            }
        }
    }
    
    private func startLights(size: CGSize) {
        // Create bunting of lights across top with draping effect
        let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange]
        let spacing = size.width / 25 // More lights
        lights = []
        
        let startY = 0.0
        let midY = size.height * 0.07
        let endY = 0.0
        
        for i in 0..<25 {
            let x = spacing * CGFloat(i) + spacing / 2
            // Calculate Y position using the same quadratic Bezier formula as the cord
            let t = x / size.width
            let y = (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * midY + t * t * endY
            
            lights.append(Light(
                x: x,
                baseY: y, // Store base Y (though we'll recalculate from cord formula)
                brightness: Double.random(in: 0.3...1.0),
                color: colors[i % colors.count]
            ))
        }
        
        // Animate flickering/dimming
        animateLights()
    }
    
    private func animateLights() {
        flickerTimer?.invalidate()
        flickerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            for i in lights.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 0.3...1.0))) {
                    lights[i].brightness = Double.random(in: 0.2...1.0)
                }
            }
        }
    }
}

struct VintageBulbShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height
        
        // Vintage Christmas bulb shape: rounded bulb with small base
        // Main bulb (oval/rounded shape)
        let bulbWidth = width * 0.85
        let bulbHeight = height * 0.75
        let bulbRect = CGRect(
            x: center.x - bulbWidth / 2,
            y: center.y - bulbHeight / 2,
            width: bulbWidth,
            height: bulbHeight
        )
        path.addEllipse(in: bulbRect)
        
        // Small base/neck at bottom (rectangular with rounded top)
        let baseWidth = width * 0.25
        let baseHeight = height * 0.25
        let baseRect = CGRect(
            x: center.x - baseWidth / 2,
            y: center.y + bulbHeight / 2 - baseHeight * 0.3,
            width: baseWidth,
            height: baseHeight
        )
        path.addRoundedRect(in: baseRect, cornerSize: CGSize(width: baseWidth * 0.3, height: baseWidth * 0.3))
        
        return path
    }
}

