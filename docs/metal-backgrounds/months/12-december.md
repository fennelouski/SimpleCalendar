# December: Strand of Lights

> A strand of old-fashioned C9 Christmas bulbs swags across the top of the screen, each glass bulb glowing and casting colored light, the strand swaying in the breeze while snow falls through the warm glow.

## Product description

December is warm and nostalgic. Hooked at four points along the top edge, a dark-green cord droops in shallow swags across the full width. From it hang big, old-style C9 bulbs: red, green, blue, amber and magenta glass. Each bulb is a lit glass object, with a hot white filament core fading into colored glass, a glossy highlight, and a green ribbed socket. They don't just glow; they *light the world around them*: colored halos, colored light catching the falling snowflakes nearby, and a soft warm wash along the top of the screen. A gentle chase pattern runs along the strand with occasional individual twinkles. The cord sways in the breeze and the bulbs swing slightly on their sockets. Snow falls behind and in front of the lights.

December counts down to Christmas: early in the month only some bulbs are lit, and each day lights more until the whole strand glows on the 24th, like an advent calendar. On Christmas the bulbs turn warm white and a star appears. On New Year's Eve the strand pulses in a countdown and ends in a sparkle burst.

## Mood and palette

| Role | Color |
|---|---|
| Warm wash (top) | `#FFB86B` at 12% → 0 by 22% height |
| Cord / highlight | `#0A3314` / `#66A666` at 55% |
| Socket | `#0D4019` → `#59A666` → `#0A3314` (cylinder) |
| Bulbs | red `#FF2924`, green `#1FE059`, blue `#3373FF`, amber `#FFB826`, magenta `#F24DD1` |
| Filament core | `#FFFFFF` HDR 4.0 |
| Christmas warm white | `#FFE3B3` |
| Snow | as January (60% density) |

Key light: the bulbs themselves (many small point lights), plus a dim cool ambient.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Warm wash | top 22% |
| 2 | Far | Distant snow | full |
| 3 | Mid | Snow crystals (lit by nearby bulbs) | full |
| 4 | Mid | Cord (4 swags, sag about 7.5% of H) | top edge |
| 5 | Mid | 28 C9 bulbs (7 per swag) | hanging from the cord |
| 6 | Near | Bokeh snow, tinted by bulb light | |
| 7 | Post | Strong bloom on filaments and glass | |

## Elements

### Cord
- Hooks at x = 0, W/4, W/2, 3W/4 and W, at y = −4 pt. Each swag is a quadratic Bézier with the control point at the midpoint plus `(wind·22, 2·sag)`. Sag is `0.075 H · (1 + 0.12 sin(0.5t + k)) + |wind|·4` (port `DecemberScene.drawStrand`).
- Rendering: a twisted two-wire look (two interleaved strokes with a helical highlight via a dashed offset pattern), 3.6 pt, dark green with a soft specular.
- Physics (High): a verlet rope per swag (16 segments) driven by the shared wind instead of the analytic curve. Bulbs hang from rope nodes and swing as pendulums. Medium and Low use the analytic curve.

### C9 bulbs
- SDF glass silhouette (port `DecemberScene.glass`: a teardrop hanging from a cylindrical socket), bulb length 36 pt.
- **Glass shading:**
  - an internal radial falloff from a hot filament (HDR white) through the bulb color to a slightly darker, more saturated rim
  - Fresnel-style edge brightening
  - a crisp specular streak on the upper left
  - when dim, the glass shows as tinted, not black (unlit-glass look: darker color plus a cool reflection)
- **Socket:** ribbed green cylinder (horizontal gradient plus rib lines).
- **Brightness:** `0.3 + 0.5·chase + 0.3·twinkle`, clamped to 0–1.
  - chase: `0.5 + 0.5 sin(2.2t − 0.55·index)`, a wave running along the strand
  - twinkle: `pow(max(0, sin(rate·t + φ)), 6)`, rate 1.5–3.5
- **Light emission:** each lit bulb contributes a colored point light. A wide halo (2.1× length) goes into the scene. Nearby snow crystals within about 150 pt are tinted and brightened by the nearest bulbs (inverse-square falloff in the particle shader; on High, a light list of the 28 bulbs in a uniform buffer). The top wash is tinted by the average bulb color.
- **Swing:** each bulb rotates around its socket, `0.08 sin(1.3t + index) − wind·0.15` rad (or from the pendulum on High).

### Snow
- January's snow system at 60% density, with the bulb lighting described above.

## Living behavior
- Wind: `0.6 sin(0.35t) + 0.25 sin(0.9t + 1)` mapped to ±22 pt horizontal cord sway (High uses shared gust noise), and to a small snow drift.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `dayOfMonth` (1–24): **advent** | Lit bulb count = `round(28 · day / 24)` (all 28 from the 24th through the 31st). Unlit bulbs show as unlit glass. The order bulbs light in is a fixed shuffled sequence, so each new day lights *specific* new bulbs. | **2.5 s discrete**. The newly lit bulbs flicker on one after another within the transition, like real bulbs warming. Going backward turns them off in reverse. Never stacks. |
| Winter solstice proximity (about December 21) | Deepens the sky slightly: the top wash shifts toward a cooler dusk blue at the solstice | 2.5 s |

## Special days
- **Christmas Eve and Christmas Day (December 24–25):** *silent night*.
  - Over 3 s every bulb fades to warm white (`#FFE3B3`) with a slow, gentle breathing instead of the chase.
  - A bright four-point star with soft diffraction spikes appears near the top center, hanging just below the cord's center swag, and twinkles slowly.
  - Snowfall softens to large, slow flakes.
  - This holds while either day is selected.
- **New Year's Eve (December 31):** *countdown*.
  - The strand goes dark, then lights 10 bulb groups in sequence, one per second (a countdown).
  - Then all bulbs flash on together, and a burst of gold and white sparkles (40 particles) erupts from the strand and falls.
  - After that, the chase resumes in gold and white.
  - Plays once per arrival.

## Theme adaptation
- **Light:**
  - Halos become soft tinted pools (normal blend) rather than additive glow.
  - Unlit and dim glass shows as clearly colored glass.
  - Filaments stay bright cores with a darker colored rim so the bulbs still look lit on white.
  - The warm wash drops to 6%.
  - Snow uses January's light-theme recipe.
- **Dark:** full additive light and heavy bloom (bloom strength 1.3). Bulb light visibly colors nearby snow.

## Readability guardrails
- The strand plus the bulbs occupy at most the top 13% of H.
- Halo light below 15% of H is capped at +0.08 luminance after opacity.
- The Christmas star sits above 14% of H.

## Metal implementation notes
- The bulb light list (position, color, intensity × 28) goes in a uniform buffer read by the snow particle shader and the wash pass.
- Bulbs are drawn as instanced SDF quads. Filament cores also go to the emissive target for bloom.
- High-tier verlet ropes: a small compute kernel (4 swags × 16 nodes, 8 constraint iterations).
- `sceneParams[0] = (litCount, christmasMode, countdownProgress, solstice)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Rope | verlet physics | analytic curve | analytic curve |
| Bulb lighting on snow | all 28 lights | nearest 4 per particle | halos only |
| Snow | 60% of January High | 60% of January Medium | 60% of January Low |
| Bloom levels | 5 | 4 | 3 |

## Acceptance criteria
- [ ] Bulbs look like lit glass objects: filament core, colored glass, specular, socket.
- [ ] Bulb light visibly colors nearby falling snow (dark themes).
- [ ] The advent count matches the selected day, with bulbs warming on one by one within a single discrete transition.
- [ ] Christmas silent night and the New Year's Eve countdown play correctly.
- [ ] The cord and bulbs sway naturally with the wind.

## Porting reference
`DecemberChristmasLightsAnimation` and `DecemberScene` (strand geometry, bulb glass path, brightness pattern) in `MonthAnimations.swift`, and January's `SnowRenderer`.
