# Metal Backgrounds: Architecture

This is the engineering spec shared by all twelve month scenes. Month documents describe *what* each scene is. This document describes *how* every scene is built, hosted, driven, and verified. Build the infrastructure here once and every month plugs into it.

---

## 1. Goals and non-goals

**Goals**
- One Metal renderer hosts all twelve month scenes behind the month grid.
- tvOS is the primary target (1920×1080 points, drawn at 3840×2160 on 4K TVs). iOS and macOS share the same code.
- Shared GPU systems (particles, clouds, bloom, noise, wind, sun/moon, sky) so each month is mostly *content*, not plumbing.
- Scenes react to the selected/focused day through discrete transitions (section 9).
- Fits a fixed GPU budget and degrades gracefully on older hardware.
- **Stays off the CPU.** The app already works the CPU hard, so the background must cost almost nothing there: under 0.5 ms of CPU per frame, rendered off the main thread (section 13).
- Deterministic enough for snapshot tests.

**Non-goals**
- No 3D engine (RealityKit/SceneKit) and no third-party engines. Plain Metal and MetalKit only.
- No HDR/EDR output to the TV. Render internally in HDR (float targets) and tonemap to SDR.
- No interaction with the scene itself. It never takes focus or touches.
- No visionOS Metal path. visionOS keeps the Canvas fallback.

---

## 2. Where it plugs in

The public entry point does not change:

```swift
MonthBackgroundAnimationView(currentDate: Date, selectedDate: Date?)
```

- `currentDate` picks the month (1–12).
- `selectedDate` (the user's selection; on tvOS it follows focus) drives the selection-reactive parameters. It falls back to `currentDate` when nil.
- `ContentView` shows this view behind the grid only in month view, at full screen, ignoring safe areas.
- `FeatureFlags.shared.backgroundAnimationsEnabled` still hides the background entirely.

Inside, `MonthBackgroundAnimationView` chooses:

```text
if Metal is available and FeatureFlags.metalBackgroundsEnabled (new flag, default true)
    → MetalBackgroundView(month:, signals:, theme:)
else
    → existing Canvas scene (MonthAnimations.swift)
```

---

## 3. File layout

The `Simple Calendar` folder is an Xcode *synchronized* group, so new files and subfolders join the app target automatically, `.metal` files included. They compile into the default Metal library.

```text
Simple Calendar/
  MetalBackgrounds/
    MetalBackgroundView.swift      // SwiftUI bridge: CAMetalLayer-backed UIView/NSView representable
    BackgroundRenderer.swift       // render-thread frame loop (CAMetalDisplayLink), scene switching, post-processing
    RendererResources.swift        // device, queue, pipeline cache, shared textures and targets
    FrameContext.swift             // per-frame CPU data handed to scenes
    SceneSignals.swift             // selection-derived signals (moon phase, daylight, holidays…)
    DiscreteTransition.swift       // generic no-stacking transition (generalizes MoonPhaseAnimator)
    QualityTier.swift              // device tiering and adaptive downgrade
    ShaderTypes.swift              // Swift mirrors of shader structs (+ layout tests)
    Systems/
      ParticleSystem.swift         // GPU particle buffers and dispatch
      SwarmSystem.swift            // GPU flow-field flocks (bats, birds)
      CloudSystem.swift
      SkySystem.swift
      CelestialSystem.swift        // sun and moon
      PostProcessing.swift         // layer blur, bloom, composite/tonemap
    Scenes/
      MonthScene.swift             // protocol
      JanuaryScene.swift … DecemberScene.swift
    Shaders/
      Common.metal                 // hashing, noise, color, SDF helpers, shared structs
      Particles.metal              // generic integrate/respawn kernels and billboard rendering
      Sky.metal, Clouds.metal, Celestial.metal, Post.metal
      January.metal … December.metal
```

Keep `MoonPhase.swift` (astronomy) as is and reuse it. `MoonPhaseAnimator` becomes a specialization of `DiscreteTransition` (section 9).

---

## 4. View layer: `MetalBackgroundView`

A `UIViewRepresentable` (iOS/tvOS) / `NSViewRepresentable` (macOS) wrapping a plain view whose backing layer is a `CAMetalLayer` (UIKit: override `layerClass`; AppKit: `wantsLayer = true` and `makeBackingLayer()`). Frames are driven by a **`CAMetalDisplayLink`** (iOS 17, tvOS 17, macOS 14) running on a dedicated render thread, not by `MTKView` on the main thread (section 5).

`CAMetalLayer` configuration:

| Property | Value | Why |
|---|---|---|
| `device` | shared `MTLDevice` | one device app-wide |
| `pixelFormat` | `.bgra8Unorm_srgb` | final composite writes linear values; hardware encodes sRGB |
| `framebufferOnly` | `true` | the drawable is only a render target |
| `isOpaque` | `false` (plus `view.isOpaque = false` and a clear background color on UIKit) | premultiplied-alpha compositing over SwiftUI; clear to `(0, 0, 0, 0)` each frame so the theme gradient shows through |
| `drawableSize` | bounds × screen scale, set on the main thread in `layoutSubviews` / `layout` | follow layout and scale |
| `maximumDrawableCount` | 3 | matches triple buffering |
| display link `preferredFrameRateRange` | per month (section 13) | 30 or 60 fps |
| user interaction | disabled; also `.allowsHitTesting(false)` in SwiftUI | never steals touches or tvOS focus |

**Pausing.** Set the display link's `isPaused` when the view leaves the window, when `scenePhase != .active`, when the feature flag turns off, or when a full-screen presentation covers the month view (on tvOS: settings, templates, view-mode picker, event management, quick add, permission primer; the day-detail slide-out only partly covers it, so keep rendering). `ContentView.isMonthBackgroundCovered` already computes this for the Canvas path; reuse it. Resume with a time *continuation*, not a jump: the scene clock does not advance while paused, so particles don't teleport.

**Updates.** `updateUIView`/`updateNSView` hands the new `month`, `SceneSignals` target, `ThemeInfo` and pause state to the renderer through a small lock-protected inbox (section 5). The renderer applies them on its next frame. SwiftUI never drives animation and never blocks on the GPU or the render thread.

---

## 5. Renderer and frame loop

`BackgroundRenderer` owns the device, command queue, `RendererResources`, the current `MonthScene` (and an outgoing one during a cross-fade), and the frame clock. It is the `CAMetalDisplayLink` delegate; each `metalDisplayLink(_:needsUpdate:)` callback renders one frame into `update.drawable`.

**Threading.** The display link is added to the run loop of a **dedicated render thread** (a `Thread` with its own `RunLoop`, quality of service `.userInteractive`). All per-frame work (clock, transitions, uniform writes, encoding) happens there, so the background never competes with focus animations, scrolling or SwiftUI updates on the main thread.
- The project defaults to `MainActor` isolation. Declare the renderer, scenes, systems and their helpers `nonisolated` so they run on the render thread.
- The main thread talks to the renderer only through an inbox: a `Mutex<RendererInbox>` (Synchronization framework) holding the latest month, signals target, theme and pause flag. The render thread reads it once per frame. No other shared mutable state.
- Never wait on GPU completion on any thread except through the in-flight semaphore on the render thread.
- Take the frame size from `update.drawable.texture` and rebuild size-dependent targets when it changes, rather than reading layer properties off the main thread.

**Per frame**

1. `inFlight.wait()` (a `DispatchSemaphore(value: 3)`, i.e. triple buffering).
2. Advance the clock from `update.targetPresentationTimestamp` (smoother than sampling `CACurrentMediaTime()`): `dt = clamp(now - last, 0, 1/20)`; `time += dt`.
3. Resolve signals: update `DiscreteTransition`s against the latest `SceneSignals` target (section 9).
4. `scene.update(frame)`: CPU-side logic (schedules, spawn decisions, transition-driven parameters). Write per-frame uniforms into this frame's slot of the uniform ring buffer.
5. Encode compute: particle simulation, any procedural texture updates.
6. Encode scene render passes into HDR targets (`.rgba16Float`, premultiplied alpha) by depth layer (section 7.6).
7. Post: layer blur (depth of field) → bloom → composite. The composite combines layers, applies the theme adaptation and global opacity, tonemaps, dithers with blue noise, and writes premultiplied output to the drawable.
8. `present(drawable)`; commit; the completion handler signals the semaphore and records `gpuEndTime - gpuStartTime` for the budget monitor.

**Uniform layout.** Define shared structs once in `Common.metal` and mirror them in `ShaderTypes.swift` with `SIMD` types. Avoid `float3` in shared structs because of its 16-byte alignment trap; use `float4`, or `packed_float3` on the Metal side. Add a unit test that asserts `MemoryLayout<…>.stride` matches the expected sizes.

```c
struct FrameUniforms {
    float  time;            // seconds since scene start (continues across pauses)
    float  deltaTime;
    float2 resolution;      // drawable pixels
    float2 pointSize;       // layout points (1920×1080 on tvOS)
    float  pixelScale;      // resolution / pointSize
    float  globalOpacity;   // default 0.6 (current product value)
    float4 backdropColor;   // theme calendarBackground, linear
    float  isDarkTheme;     // 0 or 1
    float  quality;         // 0 low, 1 medium, 2 high
    float4 wind;            // xy base wind (points/s), z gust 0..1, w turbulence
    float4 keyLight;        // xy screen position of the key light (points), z intensity, w warmth
    float4 sceneParams[8];  // month-specific, documented per month
};
```

**Units.** Author everything in **layout points** with origin top-left and y down, matching the Canvas code, then convert to pixels in shaders with `pixelScale`. Specs in month docs use points on a 1920×1080 reference screen. Positions given as fractions are of width or height.

---

## 6. Scene protocol

```swift
/// Runs on the render thread: declare conforming types `nonisolated`.
protocol MonthScene: AnyObject {
    /// 1...12
    static var month: Int { get }
    /// Build pipelines (from the shared cache), buffers and textures. Must be fast; pipelines are prewarmed.
    init(resources: RendererResources, quality: QualityTier) throws
    /// CPU logic for this frame: schedules, transition-driven values, uniform writes.
    func update(_ frame: FrameContext)
    /// GPU work: compute dispatches and draws into the layer targets.
    func encode(_ frame: FrameContext, encoders: SceneEncoders)
    /// Quality changed at runtime (adaptive downgrade). Rebuild counts and targets as needed.
    func qualityDidChange(_ quality: QualityTier)
}
```

`FrameContext` carries time, `dt`, sizes, quality, `ThemeInfo`, the resolved (transitioned) signals, and the frame's uniform buffer slot. `SceneEncoders` hands out a render encoder per depth layer, plus compute.

---

## 7. Shared GPU systems

### 7.1 Noise and hashing (`Common.metal`)
- `pcg_hash(uint)`, `hash21`, `hash22` for deterministic per-particle and per-pixel randomness. Seeds are integers derived from `(elementIndex, cycleIndex, salt)`, exactly as `BG.hash` does in the Canvas code. That lets CPU logic and GPU rendering agree.
- Gradient/simplex noise 2D and 3D, `fbm` (4–6 octaves), domain warping, and **curl noise** (divergence-free, for turbulence).
- Precomputed textures, generated once at launch on the GPU and cached: a tileable 3D noise volume (64³, `.r8Unorm`) for clouds and fog, a tileable 2D blue-noise texture (128², for dithering and jitter), and a 2D fbm texture (512²).

### 7.2 Particle system
A generic GPU particle system. Each month configures it.

- Storage: one `MTLBuffer` per system, struct of
  `{ float4 positionDepth (xy points, z depth 0 far…1 near, w size); float4 velocitySpin (xy, z angle, w angular velocity); float4 lifeSeed (age, lifetime, seed, kind); float4 tint }`.
- **Integrate kernel:** gravity, linear and quadratic drag, wind (scene wind × depth parallax), curl-noise turbulence, flutter (oscillating lateral force for leaves and petals), spin.
- **Respawn:** a particle that dies or leaves the respawn bounds is re-seeded *deterministically* from `(index, generation)`. Spawn positions are chosen so respawns happen off-screen or at zero opacity. No popping.
- **Render:** instanced quads (6 vertices × instance count). The vertex shader expands a billboard from `positionDepth` and rotation. The fragment shader draws the particle `kind` as a signed-distance shape (section 7.7) or from a small atlas.
- **Depth:** particles carry depth 0…1. Render them into the far, mid or near layer by depth bucket so depth of field applies (section 7.6). Size, speed, opacity and blur all scale with depth (the parallax rule: near = larger, faster, blurrier).
- **Blend modes:** premultiplied *over* for solid things (leaves, petals, snow crystals) and *additive* for emitters (sparks, glints, pollen). In light themes additive switches to tinted-over (section 10).
- **Warm-up:** when a scene starts, simulate N fixed steps (default 4 s at 1/60) in one compute dispatch loop so the screen is already populated. Never start empty.
- **Determinism for tests:** with a fixed seed and fixed step count the state is reproducible. Snapshot tests use warm-up plus a fixed time.

### 7.3 Wind
One wind model per scene, shared by particles, grass, clouds, cords and fog, so everything moves together.
- `wind(t) = base + gust(t)`, where `gust` is low-frequency 1D noise (periods of 8–30 s), and spatial variation comes from 2D curl noise scrolled by the base wind.
- Exposed in `FrameUniforms.wind`. Month docs give base, gust and turbulence values.

### 7.4 Clouds
Two techniques. A month chooses per tier.
- **Lit cloud sprites (all tiers).** A cloud is a large quad. The fragment shader evaluates density from fbm shaped by an ellipsoid or heart mask. Lighting comes from 3–4 density samples toward the key light (Beer-Lambert), plus a silver lining where density is thin and faces the light, and an ambient term from below. Output premultiplied color.
- **Raymarched slab (High tier).** A half-resolution full-screen pass marching a horizontal slab of 3D noise (16–24 steps, blue-noise jitter, temporal stability via a time-stable noise offset), upscaled bilaterally. Use it only where a month asks.

Cloud palettes are given per month as *lit*, *body* and *shadow* colors, matching the Canvas `CloudPalette` values.

### 7.5 Celestial bodies (`Celestial.metal`)
- **Sun.** Disc with limb darkening, HDR core (values up to 6.0 before tonemap), corona falloff, god rays (polar fbm in angle × radius, slowly rotating), and lens flare ghosts along the line from the sun through the screen center. Warmth parameter 0 (noon) … 1 (golden hour).
- **Moon.** Drawn as a lit sphere. From the disc UV reconstruct the normal `n = (x, y, sqrt(1 − x² − y²))`. The sun direction comes from the phase: `L = (sin(2π·phase), 0, −cos(2π·phase))` in view space, so phase 0 is fully dark (new), 0.25 lit on the right, 0.5 fully lit. Shade with a **Lommel-Seeliger** term `μ0 / (μ0 + μ)`, not Lambert; the real moon has little limb darkening and Lambert looks like a ball. Albedo comes from a procedural maria and crater map (port the maria and crater layout from `MoonPainter`) or a bundled equirectangular moon texture asset (public domain, NASA LRO-derived; licensing must be confirmed before shipping). Add earthshine on the night side (about 3% albedo, cool blue tint) and a halo scaled by illumination. The terminator softness comes out of the shading naturally.
- Both feed `FrameUniforms.keyLight` so the rest of the scene is lit consistently.

### 7.6 Depth layers and depth of field
Every scene renders into up to three HDR layer targets plus one emissive target:

| Layer | Resolution | Blur | Use |
|---|---|---|---|
| Far | ½ res | 2–6 px (at 1080p) | distant particles, far hills, far clouds |
| Mid | full res | none | the in-focus plane: the main subjects |
| Near | ½ res | 8–16 px | big out-of-focus foreground particles (bokeh) |
| Emissive | ½ res | via bloom | anything that should bloom (sun, bulbs, sparks, glints) |

Blur is dual-Kawase (downsample/upsample) for speed. Layers composite back-to-front.

### 7.7 Shapes as signed-distance functions
Hearts, leaves (maple and oval), petals, shamrock leaflets, bats, butterfly wings and bulbs are drawn as **2D SDFs** in fragment shaders. They stay crisp at 4K, give free anti-aliasing (`smoothstep` over `fwidth`), and support shading: gradients across the shape, rim light from the key light direction, an inner glow, and a fake 3D tumble by scaling the local x axis by `cos(flipAngle)` and switching to the back-face palette when it is negative. Collect shared SDFs in `Common.metal` (`sdHeart`, `sdMapleLeaf`, `sdOvalLeaf`, `sdPetal`, `sdBat`, `sdWing`, `sdC9Bulb`). The vector shapes in the Canvas code (`LeafPainter.maple`, `HeartGeometry`, `DecemberScene.glass`, …) are the reference silhouettes.

### 7.8 Sky and atmosphere (`Sky.metal`)
Full-screen pass with: vertical haze bands (top and bottom), procedural star field (a hash grid with one candidate star per cell, magnitude distribution, twinkle, occasional diffraction sparkle), and optional color grading of the scene. It is translucent; the theme backdrop shows through.

### 7.9 Bloom, tonemap, composite (`Post.metal`)
- Bloom: threshold on the emissive and HDR layers (soft knee), dual-Kawase pyramid of 5 levels, added back with per-month strength.
- Tonemap: ACES-fit curve (or Reinhard with white point 4.0). Then theme adaptation (section 10), global opacity, premultiply, and blue-noise dither to avoid banding in gentle gradients (critical on TVs).

### 7.10 Swarms: GPU flow-field flocks (`Swarm.metal`)
Bats (October) and bird flocks (August, September, November) use one GPU system. It gives the murmuration look (ribbons, a ripple that runs through the flock, gathering and scattering) without simulating each agent against its neighbors, so it costs no CPU and little GPU even with hundreds of agents.

Each agent's position is an **analytic function of time and its index**, evaluated in the vertex shader:

```text
lead(t)      = a slowly wandering path for the flock center
               (sum of 3 low-frequency Lissajous terms + 1D noise, kept in the sky region)
lag_i        = per-agent delay along the path, 0…L seconds (L = 4–8 s)
               → agents trail the leader and form a ribbon
frame(t)     = local frame from lead'(t − lag_i): tangent and normal
offset_i(t)  = per-agent offset in that frame, scaled by a shape envelope:
               shape(u_i, t) = 1 + A · sin(k · u_i − ω t)      // the ripple that runs through the flock
               where u_i = lag_i / L
spread(t)    = 0…1 scatter amount (gathered ↔ scattered), from the scene's flock-state schedule
pos_i(t)     = lead(t − lag_i) + frame · offset_i · shape · lerp(1, 4, spread) + small per-agent noise
heading_i    = direction of d pos_i / dt (finite difference in the shader)
flap_i       = sin(rate_i · t + φ_i)
```

- **Flock states** (gathered, rippling, scattering, regrouping) come from a deterministic schedule on the CPU. The CPU only sends `spread`, ripple amplitude and the lead path parameters. **Emergence and return** (bats leaving or entering a belfry, birds entering from off-screen) blend each agent between a source point and its flock position, staggered by index so they stream out in a column.
- Agents render as instanced SDF silhouettes (section 7.7), sized and blurred by a depth value per agent.
- Because positions are pure functions of time, swarms are fully deterministic, so snapshot tests work, and need no simulation state.
- **Simplification is acceptable.** Bats and birds can be simple silhouettes with a two-pose flap. The flock motion carries the effect, not the anatomy.

---

## 8. Scene signals (from the selected day)

`SceneSignals` is computed on the CPU whenever `selectedDate ?? currentDate` changes:

| Signal | Source | Notes |
|---|---|---|
| `date`, `dayOfMonth`, `weekday`, `dayOfYear`, `isWeekend`, `isToday` | `Calendar` | |
| `daysInMonth`, `monthProgress` | `Calendar` | `(day − 1) / (daysInMonth − 1)` |
| `moonPhase` (0…1), `moonIllumination` | `MoonPhase.fraction(forDay:)`, `MoonPhase.illumination` | sampled at local noon |
| `sunriseHour`, `sunsetHour`, `daylightHours` | `DaylightManager.sunriseTimeInHours(for:latitude:longitude:)` / `sunsetTimeInHours` | use the same location source the rest of the app uses |
| `specialDay` | `HolidayManager.shared.holidaysOn(date)` mapped to a `SpecialDay` enum (see month docs), plus fixed-date fallbacks | respect enabled holiday categories; never show a moment for a disabled holiday |

The mapping from holiday names to `SpecialDay` lives in one place (`SceneSignals.swift`). Match on stable identifiers, not localized display strings. If `CalendarHoliday` lacks a stable identifier, add one.

---

## 9. Discrete transitions (product rule, applies everywhere)

Any visual parameter driven by the selection changes through a **discrete transition**:

1. When a transition starts, it runs its **full duration** (default **2.5 s**, ease-in-out).
2. While it runs, selection changes are **ignored**: no stacking, no queueing, no retargeting mid-flight.
3. When it completes, the transition looks at the **current** target (the selection *now*). If it differs from what is shown, a new transition starts from the shown value to that target. Values the user scrolled past are skipped.
4. On first appearance the value is shown immediately, without a transition.
5. Cyclic values (moon phase, hue angles) take the shortest way around the cycle.

```swift
final class DiscreteTransition<Value> {
    init(duration: Double = 2.5,
         interpolate: @escaping (Value, Value, Double) -> Value,
         distance: @escaping (Value, Value) -> Double,   // 0 means "same"
         epsilon: Double = 0.0005)
    func value(target: Value, time: Double) -> Value
    var isAnimating: Bool { get }
}
```

`MoonPhaseAnimator` in `MoonPhase.swift` is the reference implementation and has the expected behavior verified; generalize it rather than rewriting the logic.

**Special-day moments** are one-shot effects (a finale, a burst, a sparkle shower) that play when a transition *settles* on a special day. A moment plays once per arrival. It does not replay until the selection leaves that day and comes back. Moments also never stack: if a moment is playing, a new arrival waits for it to finish and then re-checks the current selection.

---

## 10. Theming (light and dark)

The scene sits over the theme's gradient (`CalendarGradientBackground`), which can be near-white or near-black.

- `ThemeInfo { backdropColor, isDark }` goes into uniforms every frame.
- **Dark themes:** emissive elements (stars, glows, sparks, bulbs) composite additively and bloom.
- **Light themes:** additive light disappears over white. Each emissive element has a *light-theme recipe*: render as tinted over-blending with a slightly deeper color and a soft darker halo (a "shadow glow") so the shape still reads. Bloom strength drops by about 60%. Silhouettes (bats, birds, branches) get lighter and bluer (atmospheric perspective) so they don't punch holes in a white page.
- Each month doc gives its light-theme adjustments.

---

## 11. Readability rules

The scene must never compete with the grid.

- **Global opacity:** the composite multiplies the scene by `globalOpacity` (currently 0.6, matching today's product).
- **Content-safe region:** the central region where day cells sit (roughly x 4%–96%, y 12%–94% on tvOS). Inside it:
  - Local luminance contrast against the backdrop, after opacity, stays ≤ 0.25 for any element larger than 40 pt.
  - No large saturated fills behind text. Big shapes (clouds, hills) keep saturation low or sit at the edges.
  - Fast motion (> 300 pt/s) only for small elements (≤ 4 pt wide, e.g. rain streaks).
- **Edge weighting:** months put the visually heaviest elements (moon, sun, hills, light strands, leaf piles) at the top or bottom edges, and density falls toward the center. Use `edgeWeight(uv)` in `Common.metal` where useful.
- **Focus:** tvOS focus highlights and selected-day colors must stay obviously distinct over every frame of every month. Check with snapshot tests at the brightest moment of each scene (lightning, firework flash, sun center).
- **Photosensitivity:** nothing flashes more than 3 times per second over a large area. Lightning flashes are at most two pulses per event, events at least 10 s apart. Strobe fireworks twinkle per particle, never full-screen.
- A debug overlay (`#if DEBUG`) visualizes the luminance contrast map so violations are easy to spot.

---

## 12. Quality tiers and budget

**Budget:** the background may use at most **4 ms of GPU time per frame** at 60 fps on the reference device, and at most **64 MB** of GPU memory. The reference device is the oldest Apple TV 4K supported by the current tvOS (check Apple's compatibility list). Also profile on the oldest Apple TV model the current tvOS supports at all.

| Tier | Selection | Notes |
|---|---|---|
| High | `device.supportsFamily(.apple7)` or newer, and all Macs | full counts, raymarched clouds where specified, full-res mid layer |
| Medium | `.apple5`/`.apple6` | ~60% particle counts, sprite clouds only, bloom 4 levels |
| Low | older | ~35% counts, no near-layer blur (fade instead), bloom 3 levels, ½-res mid layer for soft elements |

**Adaptive downgrade:** if the measured GPU time exceeds the budget for 60 consecutive frames, step down one tier through `qualityDidChange`. Never step back up during a session. Log tier changes in debug builds.

Each month doc lists its particle and element counts per tier.

---

## 13. CPU budget and frame rate

The app already works the CPU hard. The background's job is to look rich while costing the CPU almost nothing.

**Budget:** at most **0.5 ms of CPU per frame**, render thread and main thread combined, measured on the oldest supported Apple TV. Zero main-thread work per frame.

**Rules**
1. **The CPU never loops over particles, blades, bats or drops.** Motion is either an analytic function of time evaluated in shaders (fireworks, swarms, grass, rain, snow) or simulated in GPU compute (wind-driven leaves, ropes). CPU per-frame work is limited to schedules and transitions over a few dozen items at most (flower slots, firework shells, bulb states).
2. **One small upload per frame.** The CPU writes `FrameUniforms` and, where a month needs it, a small instance buffer (≤ 4 KB) into the ring buffer. Nothing else changes per frame.
3. **No allocations per frame.** No Swift arrays, closures or objects created in the frame loop. Buffers, textures and pipelines are created once (pipelines at launch, on a background queue) and reused.
4. **A fixed, small encoding.** Each month encodes the same short list of passes every frame (target: ≤ 12 draw or dispatch calls). Static geometry is generated once on the GPU.
5. **Render off the main thread** with `CAMetalDisplayLink` (section 5).
6. **Lowest frame rate that looks right** (table below). Halving the frame rate halves the per-frame cost. A special-day moment may raise its month to 60 fps for its duration.
7. **Don't render what nobody sees** (pausing rules in section 4).
8. **SwiftUI only reports changes** (month, selected day, theme, pause). Animation never runs through SwiftUI state.
9. **Measure it.** Wrap the frame in an `os_signpost` interval. The debug HUD shows CPU ms per frame next to GPU ms. Every month PR attaches an Instruments *Time Profiler* capture alongside the *Metal System Trace*.

**Frame rate per month**

| Month | fps | Why |
|---|---|---|
| January, February, March, May, June, August, September, October, December | 30 | slow drift, growth and glow; 30 fps is indistinguishable here |
| April | 60 | fast rain streaks |
| July | 60 | fast sparks and trails |
| November | 30, rising to 60 during strong gusts | leaves move fast only in gusts |

Set this through `preferredFrameRateRange` on the display link. Timing uses real time (section 5), so motion speed doesn't depend on frame rate.

**Interim Canvas mitigations (already shipped).** Until Metal lands, the Canvas scenes are capped at 30 fps and pause when the app is inactive or a full-screen sheet covers the month view (`AnimatedScene` in `BackgroundRendering.swift`, `isMonthBackgroundCovered` in `ContentView.swift`).

---

## 14. Month switching, warm-up and lifecycle

- **Pipelines** compile at build time (`.metal` files) and are created asynchronously at launch for all months (`makeRenderPipelineState(descriptor:completionHandler:)`), so the first switch into a month never hitches. Optionally use an `MTLBinaryArchive`.
- **Switching months** (navigating Feb → Mar): cross-fade the outgoing scene into the incoming one over **1.2 s**. Both render during the fade. The incoming scene is warmed up (particles pre-simulated) before the fade starts. After the fade, free the outgoing scene's buffers.
- **Month view hidden** (switching to week or year view): pause rendering and free per-scene buffers after 10 s hidden. Pipelines stay cached.
- **Memory warnings:** drop to the Low tier's buffers and release noise textures that can be regenerated.

---

## 15. Accessibility

- **Reduce Motion** (`accessibilityReduceMotion`): freeze scene time at a pleasant, scene-specific "hero" moment. The scene still re-lights for selection changes (for example, the moon phase updates), but by a 2.5 s cross-fade between still frames instead of motion. No particles fall.
- **Reduce Transparency:** lower `globalOpacity` to 0.35.
- **Increase Contrast:** lower `globalOpacity` to 0.3 and halve bloom.
- The existing feature flag can turn the background off entirely.

---

## 16. Fallback

Keep the Canvas implementation (`MonthAnimations.swift`, `BackgroundRendering.swift`) compiling and working. Use it when:
- `MTLCreateSystemDefaultDevice()` returns nil,
- running on visionOS,
- `FeatureFlags.metalBackgroundsEnabled` is false (debug toggle in Settings for QA comparison).

Both paths read the same `SceneSignals` and the same transition logic.

**Partial fallback for October bats.** If the GPU swarm (section 7.10) isn't ready when October's Metal scene ships, the existing Canvas bats (`BatFlock` and `OctoberScene.drawBat`) may be layered on top of the Metal October background as a stopgap. That keeps the CPU cost of the current bats, so treat it as temporary and replace it with the GPU swarm.

---

## 17. Testing

- **Unit tests** (`Simple CalendarTests`):
  - `MoonPhase` accuracy against published new/full moon instants (within 1 hour).
  - `DiscreteTransition`: no retargeting mid-flight; re-samples the latest target on completion; cyclic shortest path; first value immediate. Port the scenario already verified for `MoonPhaseAnimator`.
  - `SceneSignals` special-day mapping per locale-independent identifier.
  - `ShaderTypes` struct strides.
- **Snapshot tests:** render a month offscreen into a 1920×1080 texture at a fixed time, quality tier, theme (light and dark) and selection. Compare to recorded PNGs with a perceptual tolerance. Cover at least: each month's hero frame, each special-day moment's peak frame, and October at phases 0, 0.25, 0.5, 0.75.
- **Performance:** a `#if DEBUG` HUD shows CPU ms, GPU ms, frame rate, tier, and particle counts. Before merging a month, capture an Instruments *Metal System Trace* and a *Time Profiler* run on the reference device during 30 s of focus navigation, and attach the numbers to the PR. A month fails review if it exceeds the CPU budget in section 13.
- **Soak:** leave each month running for 2 hours with no growth in memory and no visible loops, pops or drift.

---

## 18. Build order

| Milestone | Scope | Why this order |
|---|---|---|
| M0 Infrastructure | `MetalBackgroundView`, renderer, uniforms, layer targets, bloom/composite, noise textures, `DiscreteTransition`, `SceneSignals`, quality tiers, fallback switch, debug HUD | everything depends on it |
| M1 October (pilot) | moon (celestial system), sky and stars, sprite clouds, GPU swarm for the bats (or the Canvas bats overlay as a stopgap, section 16), fog | exercises every system plus the selection-driven transition |
| M2 Particle months | January, December, November, April | particle system at scale, wind, depth of field, light-theme recipes |
| M3 Sky months | August, September, June | sun, god rays, raymarched clouds (High), butterflies |
| M4 Garden and celebration months | February, March, May, July | SDF-heavy content, growth lifecycles, fireworks |

Each month lands as its own PR, includes its snapshot tests and performance numbers, and keeps the Canvas fallback for that month intact.
