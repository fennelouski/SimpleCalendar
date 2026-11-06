# April: Spring Storm

> Heavy storm clouds roll along the top of the screen, rain slants down at three depths in the gusting wind, drops splash into rippling puddles below, and far off, lightning flickers inside the clouds.

## Product description

April is dramatic but calm, a spring rain watched from somewhere dry. Dark, heavy clouds sit along the top edge, layered and churning slowly, lit from within whenever distant lightning flickers. Rain falls at three depths: a fine far mist of short streaks, mid-distance drops, and a few long blurred streaks close to the camera. The wind gusts, so the rain's slant swings back and forth. At the bottom, drops land in a thin reflective sheet of water: rings spread, tiny droplets bounce up, and the water faintly mirrors the sky.

Each selected day has its own weather: drizzle, steady showers, or a full thunderstorm. When the storm breaks on Easter, the clouds part and a shaft of sunlight and a rainbow appear.

## Mood and palette

| Role | Color |
|---|---|
| Top haze | `#4D5975` at 26% |
| Bottom mist | `#99B3D1` at 16% |
| Storm cloud lit / body / shadow | `#C7CCDB` / `#8C94A8` / `#4D5469` |
| Rain streak head | `#D9EBFF` |
| Splash rings | `#E0F0FF` at 55% |
| Lightning | `#FFFFFF` core, `#BFD1FF` glow, HDR 8.0 |
| Puddle reflection tint | `#5C6B85` at 20% |

Key light: diffuse overcast from above (0.6 W, −0.5 H), intensity 0.5. Lightning temporarily becomes a second, very bright key light.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Top haze, bottom mist | |
| 2 | Far | Lightning bolt (occasional) | inside the cloud band, y 2–34% |
| 3 | Mid | Storm cloud band (7 clouds, partly off the top edge) | y −2% to 12% |
| 4 | Far | Far rain (short streaks) | full |
| 5 | Mid | Mid rain | full |
| 6 | Mid | Water sheet with splashes and reflections | bottom 7% |
| 7 | Near | Near rain (long, blurred) | full |
| 8 | Post | Bloom (lightning), flash lighting | |

## Elements

### Storm clouds
- High tier: a raymarched cloud slab (architecture 7.4) across the top 14% of the screen, density from 3D noise scrolling with the wind at 6–14 pt/s. Medium and Low: 7 lit cloud sprites, widths 340–540 pt.
- Dark, dense bodies with lighter tops. Undersides show rain shafts: a vertical falloff of density below the base, streaked by noise.

### Rain
- Three particle layers (High counts):
  - far: 400 streaks, length 10–16 pt, speed 700–900 pt/s, width 1 pt, 32%
  - mid: 240 streaks, 20–30 pt, 950–1200 pt/s, 1.5 pt, 48%
  - near: 40 streaks, 46–70 pt, 1500–1800 pt/s, 2.6 pt, 40%, near-layer blur
- Each streak is a capsule aligned with its velocity: transparent tail, bright head. A thin highlight on the side facing the key light makes them read as water, not lines.
- Slant `= wind.x / fallSpeed`, where `wind.x` follows the gust model: base 160 pt/s with ±80 pt/s gusts over 9–28 s periods (equivalent to the Canvas slant `0.2 + 0.1 sin(0.11t) + 0.05 sin(0.37t + 1)`).

### Water sheet and splashes
- A thin band at the bottom (7% of H) with a subtle vertical gradient and screen-space *reflection*: mirror the rain and cloud layers vertically into the band at 20% intensity, distorted by animated ripple normals.
- Splashes: when a mid or near particle passes the floor plane, the kernel converts it into a splash event (a ring-buffer append). Each splash draws an expanding elliptical ring (radius 3 → 19 pt, aspect 0.28) plus 2–3 droplets that hop in a parabola, all fading over 0.7–1.4 s. Splashes are smaller and fainter farther back (y deeper in the band = farther).
- Ripple normals from active splashes perturb the reflection.

### Lightning
- An event every 17 s on average (deterministic schedule, 70% of slots fire).
- Flash envelope: strike 0–0.16 s (1 → 0), then a re-strike 0.26–0.62 s (0.7 → 0). At most two pulses per event, which meets the photosensitivity rule.
- Bolt: a jagged polyline with fractal subdivision (main channel plus 2–4 forks), rendered with an HDR core (blooms strongly) and a blurred blue glow. It is partially occluded by the clouds: drawn behind the cloud band and visible through gaps and below the base.
- Flash lighting: during the flash, clouds get an internal scattering boost (lit color toward white, from the bolt's position), and a soft whole-sky brighten at the top (haze +35% × envelope).

## Living behavior
- Wind: base (160, 0) pt/s, gust 0.5, turbulence 0.2. Rain, cloud drift and ripple direction all follow it.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| Day character, `hash(year·400 + dayOfYear)` | **Drizzle** (35%): rain ×0.4, no lightning, lighter clouds. **Showers** (45%): ×1.0, lightning slots ×0.3. **Thunderstorm** (20%): ×1.5, all lightning slots fire, darker clouds, stronger gusts | 2.5 s discrete (rain density by particle rank, cloud darkness, gust strength) |

## Special days
- **Easter Sunday** (when it falls in April; from `HolidayManager`): *storm break*.
  - Over 4 s the rain tapers to drizzle and the clouds part in the upper right.
  - A warm shaft of sunlight (golden god rays, `#FFE8B0` at 30%) slants in.
  - A rainbow arc fades in on the opposite side.
  - Puddle reflections pick up the warm light.
  - This holds while the day stays selected.
- **April Fools' Day (April 1)**, optional and playful: one in three lightning events is replaced by the rain *pausing midair* for 1 s, then resuming. Gate this behind a feature flag; product sign-off required.

## Theme adaptation
- **Light:** rain streaks turn darker blue-gray (`#5E7799` at 40%) so they show on white. Clouds lose 15% opacity. Lightning flash brightening is replaced by a brief cool shadow-glow around the bolt.
- **Dark:** as specified, with full bloom on lightning.

## Readability guardrails
- The cloud band never extends below 16% of H.
- The lightning sky-brighten is capped at +0.15 luminance after opacity.
- Rain streaks are thin (≤ 2.6 pt), so fast motion is acceptable in the content-safe region (architecture section 11).

## Metal implementation notes
- One particle buffer with three emitters. A floor-plane test in the kernel appends splash events into a GPU ring buffer (`atomic_uint` head).
- Splashes are rendered instanced from the ring buffer.
- The reflection pass samples the already-rendered far and mid targets with a vertical flip and a ripple offset.
- The lightning schedule is computed on the CPU; the bolt geometry is generated per event into a small vertex buffer.
- `sceneParams[0] = (rainDensity, cloudDarkness, flash, 0)`, `sceneParams[1] = (boltOrigin.xy, sunBreak, rainbow)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Rain far / mid / near | 400 / 240 / 40 | 240 / 140 / 24 | 140 / 90 / 0 |
| Clouds | raymarched slab | 7 sprites | 5 sprites |
| Reflections | on | on (no ripple distortion) | off |
| Splash ring buffer | 256 | 128 | 64 |

## Acceptance criteria
- [ ] Rain has clear depth and the slant visibly swings with gusts.
- [ ] Splashes and ripples look physical; the water sheet reflects the scene.
- [ ] Lightning lights the clouds from within and never exceeds two pulses per event.
- [ ] Weather character changes per day via one discrete transition.
- [ ] Easter storm-break moment works when Easter is in April.

## Porting reference
`AprilRainAnimation` and `AprilScene` (rain layers, splashes, lightning envelope, bolt) in `MonthAnimations.swift`.
