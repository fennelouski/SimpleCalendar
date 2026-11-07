# Metal Month Backgrounds

Every month of Simple Calendar has a living background scene behind the month grid. This folder is the product and engineering spec for rebuilding all twelve scenes on **Metal**, primarily for **tvOS**. It is written so an agent or engineer can pick up any one document and build that piece end to end.

## Why Metal

The scenes currently draw with SwiftUI `Canvas`: paths and gradients are rebuilt on the CPU every frame. That limits us to a few hundred particles, cheap blurs, and 2D-looking lighting. On a 4K TV across a room, the scenes should look like a window into a world, not clip art. Metal lets every month have:

- **Real light.** Glow and bloom from bright things, rim light from the sun or moon, volumetric clouds lit from inside, and a moon that is an actually lit sphere.
- **Scale.** Thousands of GPU-simulated particles (snow, rain, sparks, pollen) instead of hundreds.
- **Depth.** Several parallax layers with real depth-of-field blur, atmospheric haze, and fog.
- **Physicality.** Wind fields shared by everything in a scene, gravity and drag on sparks, and curl-noise turbulence.

## Documents

| Document | What it covers |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | The engineering spec: view and renderer structure, frame loop, shared GPU systems (particles, clouds, bloom, noise, wind, celestial bodies), the selection-driven state model, theming, readability rules, quality tiers, fallbacks, testing, and the build order. **Read this first.** |
| [months/01-january.md](months/01-january.md) | January: Winter Hush (snowfall, frost, drifts) |
| [months/02-february.md](months/02-february.md) | February: Sweetheart Sky (heart clouds, floating hearts) |
| [months/03-march.md](months/03-march.md) | March: Emerald Hills (shamrocks, rolling hills, gold motes) |
| [months/04-april.md](months/04-april.md) | April: Spring Storm (rain, storm clouds, lightning, puddles) |
| [months/05-may.md](months/05-may.md) | May: Meadow in Bloom (grass, flowers, petals, pollen) |
| [months/06-june.md](months/06-june.md) | June: Butterfly Light (butterflies, sunbeams, bokeh) |
| [months/07-july.md](months/07-july.md) | July: Night of Fireworks (fireworks, stars, smoke) |
| [months/08-august.md](months/08-august.md) | August: High Summer (blazing sun, cumulus, heat shimmer) |
| [months/09-september.md](months/09-september.md) | September: Golden Hour (low sun, first falling leaves) |
| [months/10-october.md](months/10-october.md) | October: Harvest Moon (phase-accurate moon, bats, fog, jack-o'-lanterns) |
| [months/11-november.md](months/11-november.md) | November: Gusting Leaves (wind-blown leaves, leaf piles, overcast light) |
| [months/12-december.md](months/12-december.md) | December: Strand of Lights (glowing bulbs, snowfall, warm glow) |

## Product principles (apply to every month)

1. **The calendar comes first.** The scene is a backdrop. Day numbers, event titles and focus highlights must stay readable on every theme, light or dark. See *Readability* in the architecture doc.
2. **Alive, never busy.** Motion is slow and continuous. Nothing flashes, strobes, or pulls the eye from the grid, except a deliberate, rare moment such as a lightning flash or a finale burst, and those stay soft.
3. **Responsive to the selected day.** Each month reacts to the day the user has selected or focused (moon phase, daylight, holidays). Those reactions follow one rule: **transitions are discrete**. A transition always runs to completion (default 2.5 s), and only then does the scene look at the *current* selection and transition again if it changed. Transitions never stack, queue, or retarget mid-flight.
4. **Seamless forever.** A scene can sit on screen for hours. There are no visible loops, resets, pops, or wrap-around jumps. Anything that recycles does so off-screen or while invisible.
5. **Physically plausible light.** Every scene has a key light (sun, moon, lightning, bulbs) and everything in it is lit consistently by that light.
6. **Deterministic.** Given the same time and selection, a frame looks the same, which makes snapshot tests possible.
7. **Light on the CPU.** The app already works the CPU hard. The background renders off the main thread and costs under 0.5 ms of CPU per frame. Motion lives on the GPU, and scenes run at 30 fps unless they need 60. See *CPU budget and frame rate* in the architecture doc.

## Current state

- The scenes ship today as SwiftUI `Canvas` renderers in `Simple Calendar/MonthAnimations.swift`, built on the toolkit in `Simple Calendar/BackgroundRendering.swift`. `Simple Calendar/MoonPhase.swift` has the moon phase astronomy and the discrete transition animator.
- `MonthBackgroundAnimationView(currentDate:selectedDate:)` picks the month's scene. `ContentView` shows it behind the grid in month view only.
- The Canvas scenes run at 30 fps and pause while hidden (an interim CPU saving). They are the **visual reference and the fallback**. Each month spec points at the Canvas code to port from. Keep the Canvas path working after the Metal versions land.

## Definition of done (whole project)

- All twelve months render through Metal on tvOS, iOS, and macOS, using the shared renderer described in the architecture doc.
- Each month meets its own acceptance checklist.
- The background stays within both the GPU budget and the CPU budget in the architecture doc on the reference Apple TV, with no dropped frames during focus navigation.
- The Canvas fallback still works where Metal is unavailable or when the fallback is forced for debugging.
- Snapshot tests exist for every month at fixed times and selections.
