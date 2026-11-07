# August: High Summer

> A blazing sun arcs slowly across the top of the screen, pouring out rays and lens flare. Towering, sunlit cumulus clouds drift past, birds glide in the distance, and the air shimmers with heat near the bottom.

## Product description

August is bright, hot and expansive. A big, intense sun travels slowly across the top of the screen on a shallow arc over about twenty minutes. It has rotating god rays, a corona, and a subtle lens flare: a chain of colored ghosts reflecting through the center of the screen. Big cumulus clouds drift at different distances. Each one is lit on the side facing the sun, with silver linings when it passes near the sun and soft blue-gray shadows underneath. A few birds glide and flap far away. Near the bottom, the air wavers with heat shimmer.

The selected day's daylight sets how high the sun rides and how hot the light is. During the Perseid meteor shower peak, meteors streak across a sky that briefly dims to dusk.

## Mood and palette

| Role | Color |
|---|---|
| Top haze | `#FFEDB8` at 16% |
| Sun core / mid / rim | `#FFFCEB` / `#FFE37A` / `#FFB83D` (warmth 0.12) |
| Cloud lit / body / shadow | `#FFFFFF` / `#F2F5FC` / `#B8C4E0` |
| Birds | `#33384D` at 55% |
| Flare ghosts | `#FFD980`, `#99FFBF`, `#8CBFFF`, `#FF99CC` at ≤ 12% |

Key light: the sun itself (its position is the key light), intensity 1.0, warmth 0.12.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Warm haze | top 45% |
| 2 | Far | Sun, corona, god rays | arc at y ≈ 14% (see path) |
| 3 | Far | Distant birds (4) | y 18–40% |
| 4 | Far → Mid | Cumulus clouds (6, sorted far to near) | y 6–32% |
| 5 | Mid | Heat shimmer | bottom 18% (distortion only) |
| 6 | Post | Lens flare ghosts, bloom | |

## Elements

### Sun
- Path: progress `u = fract(0.5 + t/1200)`, so one crossing takes 20 minutes. `x = −4r + u·(W + 8r)`; `y = H·0.19 − H·0.07·4u(1 − u)`; radius r = 62 pt. It is fully off-screen when it wraps (port `SkyScene.sunPosition`).
- Celestial sun shader (architecture 7.5):
  - HDR core (5.0)
  - limb darkening
  - corona falloff to 2.1r
  - 16 god rays, length 3.2–5.8r, rotating at 0.02 rad/s and breathing
  - a wide bloom to 7r
- **Occlusion:** when a cloud passes in front of the sun, the rays and corona dim in proportion to cloud density along the sun's position. Sample the cloud density at the sun center from the cloud pass's ½-res density output. The cloud's sun-facing edge gets a bright silver lining.
- **Lens flare:** four ghosts along the sun → screen-center axis at 0.55, 0.95, 1.3 and 1.75. Soft discs, one hexagonal on High, plus a faint anamorphic streak through the sun. Flare intensity scales with the sun's visibility (occlusion).

### Cumulus clouds
- High tier: lit sprite clouds with a raymarched density detail texture. Medium and Low: sprite clouds.
- Six clouds, width 220–420 pt (far → near), drift 5–15 pt/s by depth. Far clouds are hazier (atmospheric perspective) and slightly blurred.
- Lighting toward the sun's *current* position, so as the sun crosses, the lit sides of the clouds swing. Towering tops (taller density masks) on the two nearest clouds.

### Birds
- A small, loose flock of 4–12 distant birds drawn with the GPU swarm system (architecture 7.10): simple chevron silhouettes, two-pose flap at 4–6 rad/s with intermittent glides, crossing in 40–70 s with slight altitude wander. They fade at the edges. Simplified on purpose; no CPU cost.

### Heat shimmer
- A distortion pass over the bottom 18%: screen-space UV offset from scrolling noise (amplitude 1.5 pt, rising at 20 pt/s), applied to the scene layers *beneath* the calendar only (it distorts the background, never the UI).

## Living behavior
- Wind: base (10, 0), gust 0.15. Clouds drift with it; birds bank slightly.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `daylightHours` | Sun arc height: peak y from 12% (long day) to 17% (shorter late-August day); sun warmth 0.08 → 0.2; heat shimmer amplitude ×1.0 → ×0.6 | 2.5 s discrete (applied as offsets to the sun path, so it never jumps) |

## Special days
- **Perseid meteor shower peak** (August 12–13, fixed dates): *meteor night*.
  - The sky dims to a dusk gradient (`#2E3866` at 30%) over 3 s and the sun fades out.
  - Stars appear (60).
  - Meteors streak from the radiant in the upper right: 1–3 every 4 s, length 120–260 pt, life 0.6–1.0 s, with a white-green HDR head and a fading trail.
  - The dusk holds while the day stays selected and reverts by transition when the selection leaves.

## Theme adaptation
- **Light:** the sun and rays render as a warm tint plus a darker orange rim so the disc reads on white. Clouds gain stronger shadow contrast (`#9AA8C8`). Flare ghosts are off. Meteor night uses a lighter dusk (15%).
- **Dark:** full HDR sun, bloom and flare.

## Readability guardrails
- The sun's center is never below 20% of H.
- Ray length is capped where rays cross the content-safe region (fade the rays beyond 3r inside it).
- Clouds stay above 34% of H.

## Metal implementation notes
- The cloud pass writes a ½-res density buffer used for sun occlusion and flare dimming.
- Heat shimmer is a post-pass on the scene composite before global opacity, restricted to the bottom band.
- `sceneParams[0] = (sunPeakY, warmth, shimmer, meteorNight)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Clouds | 6, raymarched detail | 6 sprites | 4 sprites |
| God rays | 16 | 12 | 8 |
| Lens flare | 4 ghosts + streak | 3 ghosts | off |
| Heat shimmer | on | on | off |
| Birds (GPU swarm) | 12 | 8 | 4 |

## Acceptance criteria
- [ ] The sun feels blindingly bright on dark themes yet is never uncomfortable.
- [ ] Clouds are lit from the sun's actual position; passing clouds occlude the sun and dim the rays and flare.
- [ ] No visible jump when the sun wraps around.
- [ ] Sun height follows daylight via discrete transitions.
- [ ] Perseid meteor night works and reverts cleanly.

## Enhancements
Small details that reward watching. Each keeps the month's original idea, follows its readability guardrails (edges and corners only for new scenery), and stays within the CPU rules in architecture section 13.

- **Clouds that evolve:** cloud density masks grow, billow and dissipate over 60–120 s instead of only translating.
- **Cloud shadows:** a soft strip of distant land (rolling fields) along the bottom 5% shows cloud shadows sweeping across it.
- **Building thunderhead:** on the hottest days (daylight above 14 h), one cumulus slowly grows into a tall anvil-topped thunderhead over about 10 minutes, then fades.

## Porting reference
`AugustSunCloudsAnimation`, `SkyScene` (sun path, clouds, birds) and `SunPainter` in the Canvas code.
