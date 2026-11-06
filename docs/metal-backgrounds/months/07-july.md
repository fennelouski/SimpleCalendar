# July: Night of Fireworks

> A deep summer night sky full of stars. Rockets streak upward trailing sparks and burst into peonies, chrysanthemums, willows, rings and crackling strobes, lighting the sky and leaving drifting smoke.

## Product description

July is a celebration, enjoyed from a distance. The top of the screen deepens into a navy night sky with twinkling stars. Fireworks launch from below the bottom edge every second or two: a rocket climbs with a crackling spark trail, then bursts. Bursts come in five styles:
- **peony:** a sphere of colored stars
- **chrysanthemum:** stars that leave long glowing trails
- **willow:** gold stars that droop and hang in long arcs
- **ring:** a tilted circle
- **strobe:** stars that flicker

Each burst briefly lights the sky around it and the smoke left behind. Every so often a finale cluster sends up several shells at once.

Weekends get more fireworks than weekdays. On Independence Day the show is a grand finale, and a Canada Day show uses red and white.

## Mood and palette

| Role | Color |
|---|---|
| Night haze (top) | `#0A0F33` at 38% → 0 by 65% height |
| Stars | `#E0EDFF` and warm `#FFE6C7` (20%) |
| Shell palettes (primary / secondary) | red `#FF404D`/`#FFD9D9`, blue `#4D8CFF`/`#D9EBFF`, gold `#FFD14D`/`#FFF2BF`, green `#59FF80`/`#D9FFD9`, violet `#D959FF`/`#FFB3F2`, orange `#FF8026`/`#FFD980` |
| Smoke | `#BFBFD9` at up to 8% |
| Rocket trail | `#FFCC73` |

Key light: none at rest (ambient night); each burst becomes a temporary point light.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Night haze and star field (70 stars) | top 50% |
| 2 | Far | Smoke from earlier bursts | around burst sites |
| 3 | Mid | Rockets and burst stars | apex y 12–40%, x 12–88% |
| 4 | Emissive | Star heads, flashes, crackle | |
| 5 | Post | Strong bloom, sky illumination | |

## Elements

### Launch schedule
- Slots every 1.5 s (deterministic, port `JulyScene.draw`): 25% of single slots are skipped; every 4th slot launches 2; every 9th slot launches a 5-shell finale cluster staggered by 0.2 s.
- Each shell: launch x 12–88% of W, apex y 12–40% of H (±60 pt horizontal drift), rise time 1.2–1.8 s, burst life 2.8–4.6 s.

### Rocket
- Ease-out climb; a spark trail of 12 fading points with a small lateral jitter, plus a bright head. In High tier the trail sheds real particles that fall and fade.

### Burst physics (all styles)
- Each star's position from the burst: `p(τ) = apex + dir · v · (1 − e^(−kτ)) / k + ½ g τ²`.
  - drag k: 1.6 (willow 0.9)
  - gravity g: 60 pt/s² (willow 95)
  - speed v: 150–230 pt/s × per-star 0.62–1.0 (ring: constant)
- Stars per shell: 60 (ring 44). High tier adds 30% secondary stars.
- **Trails:** capsule from `p(τ − trail)` to `p(τ)`, trail 0.12 s (chrysanthemum and willow 0.45 s), transparent → color.
- **Color over life:** white-hot for the first 0.3 s, then the palette color, cooling slightly redder as it fades. Alternate stars use primary and secondary colors.
- **Fade:** `1 − smoothstep(0.5·life, life, τ)`.
- **Ring:** directions squashed by a tilt of 0.3–0.6, then rotated by a random spin.
- **Strobe:** per-star flicker at about 6 Hz (`sin(38τ + 1.7i) > 0`). Per-star only, never the whole sky.
- **Willow crackle:** in the last 40% of life, 40% of willow stars emit tiny sparkles that bloom.

### Burst flash and sky lighting
- At burst: a white core flash (radius 90 pt, 0.4 s decay) and a wide colored sky glow (radius 420 pt, intensity 0.16).
- The burst acts as a point light: smoke and nearby star haze are tinted by the burst color while it decays.

### Smoke
- After each burst, a soft volumetric puff (noise sprite) forms at the apex. It grows, rises at 12 pt/s, drifts with the wind, and fades over 6–8 s. Max opacity 8%. Later bursts light it from within.

### Stars
- Hash-grid star field with twinkle and occasional diffraction sparkle (architecture 7.8).

## Living behavior
- Wind: base (8, 0), gust 0.2. It pushes smoke and slightly bends willow trails.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `isWeekend` | Weekend: slot interval 1.2 s, finale every 7th slot. Weekday: 1.5 s, every 9th | applied at the next slot boundary after a 2.5 s discrete transition of the density parameter |
| Day character (hash) | Palette bias: which two palettes are favored that day | 2.5 s |

## Special days
- **Independence Day (July 4, US):** *grand finale*.
  - Launch interval 0.6 s.
  - Red, white and blue palettes only.
  - Every 5th slot is a 7-shell cluster.
  - Every 20 s, a 4 s finale of 18 shells in rapid succession, with sky glow ×1.5.
  - Smoke opacity cap rises to 12%.
- **Canada Day (July 1, if that holiday is enabled):** red and white palettes, maple-leaf-shaped peonies (star directions sampled from the maple SDF outline).
- **Bastille Day (July 14, if enabled):** blue, white and red palettes in sequence.

## Theme adaptation
- **Light:** additive light disappears, so:
  - stars and burst stars use saturated tinted-over with a slightly darker core edge
  - sky glow becomes a soft colored tint at 8%
  - the night haze shrinks to 15% so the page doesn't darken
  - smoke becomes a faint gray shadow
- **Dark:** full additive with heavy bloom (bloom strength 1.4).

## Readability guardrails
- Bursts' apexes stay above 40% of H. Stars may fall lower but are faded by 60% of H.
- The sky glow is capped at +0.12 luminance after opacity.
- No full-screen flashes.

## Metal implementation notes
- The CPU computes the deterministic schedule and writes active shells `{seed, launchTime, apex, style, palette}` (at most 40).
- The GPU evaluates star positions *analytically* in the vertex shader from `(shell, starIndex, τ)`, so no simulation state is needed. That makes July fully deterministic and cheap.
- Rocket-trail debris (High) and smoke puffs use the particle system.
- `sceneParams[0] = (slotInterval, finaleEvery, paletteBias, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Stars per shell | 78 | 60 | 40 |
| Concurrent shells cap | 40 | 28 | 18 |
| Rocket debris particles | on | off | off |
| Smoke | volumetric sprite | sprite | glow only |
| Background stars | 120 | 70 | 50 |

## Acceptance criteria
- [ ] All five burst styles are distinct and physically convincing (drag, gravity, droop).
- [ ] Bursts light the sky and smoke around them.
- [ ] Weekend and weekday density differ; Independence Day finale is spectacular but within the photosensitivity rules.
- [ ] Fully deterministic: the same time gives the same frame.
- [ ] Within the GPU budget during the largest finale.

## Porting reference
`JulyFireworksAnimation` and `JulyScene` (schedule, burst physics, styles) in `MonthAnimations.swift`.
