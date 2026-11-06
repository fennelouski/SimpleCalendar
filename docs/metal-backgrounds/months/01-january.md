# January: Winter Hush

> Snow drifts down through cold blue air, close flakes melting into soft bokeh, distant flakes a fine haze. A drift of fresh snow along the bottom catches the light in brief glints.

## Product description

January is the quietest month. The viewer should feel like they are looking out a window on a still, snowy afternoon. Snow falls at three distances at once: a fine haze far away, crisp six-armed crystals in the middle distance that slowly turn and catch the light, and a few huge, soft, out-of-focus flakes drifting past right in front of the "camera". The air at the top of the screen carries a pale, cold blue haze. Along the bottom edge, a low snowdrift with gentle rises and dips glints here and there as if sunlight hits ice crystals. Frost creeps in from the corners of the screen as delicate feathered patterns.

Each selected day has its own weather. Some days are light flurries, some a steady snowfall, a few are heavy snow with wind. Moving between days changes the weather through a smooth 2.5 s transition.

## Mood and palette

| Role | Color | Notes |
|---|---|---|
| Sky haze (top) | `#C7E0FF` at 22% fading to 0 by 45% height | cold, airy |
| Snow (lit) | `#FFFFFF` | |
| Snow (shadow side) | `#BDD1F2` | crystals and drift shading |
| Drift base | `#BCD1F2` → `#FFFFFF` (bottom → top) | |
| Glint | `#FFFFFF` HDR 3.0 | blooms |
| Frost | `#E8F3FF` at 35% | edges only |

Key light: low winter sun from the upper left (`keyLight` at (−0.1 W, 0.05 H), warmth 0.15, intensity 0.7).

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Cold haze band | top 45% |
| 2 | Far | Distant snow haze (tiny specks) | full screen |
| 3 | Mid | Snow crystals | full screen, denser near the edges |
| 4 | Mid | Snowdrift with sparkle glints | bottom 4.5% (two overlapping banks) |
| 5 | Mid | Frost feathers | four corners, max reach 14% of width |
| 6 | Near | Bokeh flakes | full screen, few |
| 7 | Post | Bloom on glints and crystal highlights | |

## Elements

### Distant snow (far layer)
- Tiny round specks, radius 0.9–2.1 pt, opacity 35–70%.
- Fall speed 22–42 pt/s. Lateral sway amplitude 14 pt, period 7–15 s.
- Blur: far-layer depth of field (about 2 px).

### Snow crystals (mid layer)
- Six-armed dendrite crystals drawn as an SDF: a central hexagonal plate, six arms, and 1–3 pairs of side branches per arm at 60°. Three crystal variants chosen by seed (see `SnowRenderer.crystals` for the reference shapes).
- Radius 5–11 pt. Fall speed 40–66 pt/s. Sway amplitude 32 pt. Spin −0.6…0.6 rad/s.
- Shading: lit face white; arms facing away from the key light tinted `#BDD1F2`; a thin specular highlight on the arm edges facing the key light that pulses as the crystal turns (`pow(max(0, dot(armDir, lightDir)), 8)`), sending a little energy into bloom.
- Soft halo: radius × 1.8 at 35% opacity.

### Bokeh flakes (near layer)
- Large soft discs, radius 18–42 pt, center opacity 42% falling to 0 at the edge, with a faint brighter rim (real lens bokeh).
- Fall speed 85–130 pt/s, sway 60 pt. Near-layer blur 10–14 px.

### Snowdrift
- Two overlapping banks. The back bank is slightly lower and bluer. The surface is a sum of three sines plus fbm detail (port `SnowRenderer.drawSnowbank`), height 4.5% of H.
- Shading: top-lit gradient, with subsurface-style blue in the troughs (`#BCD1F2`) and a crisp bright rim along the crest.
- Glints: 36 fixed points on the surface. Each sparkles briefly (`pow(max(0, sin(t·rate + φ)), 12)`, rate 0.8–1.8) as a four-point star with HDR intensity so it blooms.

### Frost feathers
- Grows inward from each screen corner: branching dendrites from a fractal growth function (precomputed once per session into a ½-res texture, using a deterministic seed), revealed by a slowly expanding mask.
- Breathes: reach oscillates ±10% over 40 s. Opacity 35%. Never enters the content-safe region.

## Living behavior
- Snow never resets visibly. Particles respawn above the top edge.
- Wind: base (6, 0) pt/s, gust 0.3, turbulence 0.15. Gusts make all three layers drift together, near ones most (parallax).

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| Day character, `hash(year·400 + dayOfYear)` | Picks a weather preset: **Flurries** (40% of days): density ×0.5, wind base 2 pt/s. **Steady** (45%): density ×1.0. **Heavy** (15%): density ×1.8, wind base 25 pt/s, gust 0.7, near bokeh ×2, haze +30% | 2.5 s discrete transition on density, wind and haze |
| `daylightHours` | Short days push the haze toward deeper blue `#9DBBEA`; longer days toward pale `#D6E8FF` | 2.5 s |

Density changes fade particles in or out by opacity (each particle has a stable "rank" 0…1 and is visible when `rank < density`). Never spawn or delete them abruptly.

## Special days
- **New Year's Day (January 1):** a *glitter snow* moment. For 6 s about 25% of mid crystals turn warm gold (`#FFD98A`) with brighter glints, and a slow cascade of gold sparkles falls from the top. Then everything eases back to white over 3 s.

## Theme adaptation
- **Dark:** as specified. Glints and highlights bloom.
- **Light:** white snow vanishes on white. Crystals and specks get a cool shadow edge (`#7F9CC9` at 45%, 1 pt wide on the side away from the light) so they read as falling snow. Bokeh becomes faint blue-gray (`#AFC4E6` at 20%). The drift gets a stronger blue shadow underside. Bloom −60%.

## Readability guardrails
- Crystal density in the content-safe region is at most 60% of the edge density.
- Bokeh flakes larger than 30 pt fade to 50% opacity while inside the central 50% of the screen.

## Metal implementation notes
- Particle system with three emitters (far, mid, near) sharing one integrate kernel. Particle `kind`: 0 speck, 1 crystal (variant in seed), 2 bokeh.
- Drift: one full-width quad, fragment shader evaluates the surface height and shading. Glints go to the emissive target.
- Frost: generate the frost texture once with a compute kernel (diffusion-limited-aggregation-style growth, or iterated branching L-system rasterized via SDF), sample in the sky pass with a growth mask.
- `sceneParams[0] = (density, hazeTint.rgb)`, `sceneParams[1] = (moment progress, momentKind, 0, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Distant specks | 600 | 360 | 200 |
| Crystals | 120 | 70 | 40 |
| Bokeh | 14 | 9 | 5 (no blur, fade only) |
| Frost | on | on | off |

## Acceptance criteria
- [ ] Three clearly different depths of snow with parallax during gusts.
- [ ] Crystals visibly rotate and sparkle as they turn toward the light.
- [ ] Snowdrift glints bloom on dark themes and remain visible on light themes.
- [ ] Changing the selected day changes the weather through one smooth 2.5 s transition; rapid scrolling never stacks transitions.
- [ ] January 1 glitter moment plays once on arrival and not again until the selection leaves and returns.
- [ ] Two-hour soak shows no visible loop or reset.
- [ ] Within the GPU budget on the reference Apple TV.

## Porting reference
Canvas implementation: `JanuarySnowAnimation` and `SnowRenderer.draw` / `SnowRenderer.drawSnowbank` in `Simple Calendar/MonthAnimations.swift` and `Simple Calendar/BackgroundRendering.swift`.
