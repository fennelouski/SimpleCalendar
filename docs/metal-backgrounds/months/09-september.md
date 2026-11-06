# September: Golden Hour

> A low, warm sun glows through amber haze. Golden-edged clouds drift by, and the first leaves of autumn let go, tumbling and flickering through the warm light on their way down.

## Product description

September is the turn of the season, a long golden late afternoon. The sun rides lower and warmer than in August, crossing the sky very slowly (over more than an hour) with a softer, more diffuse glow. The clouds are tinged peach and gold with rosy undersides. Leaves fall at different depths, tumbling in 3D so they flash their bright sunlit faces and darker backs. When a leaf crosses the sun's light, its edges catch a translucent glow. Some leaves fall close to the camera, large and out of focus.

The month progresses visibly: on September 1 the falling leaves are still mostly green-gold and few; by the end of the month they are many, and red and orange. The autumn equinox is the moment the light turns fully golden and a big gust releases a flurry of leaves.

## Mood and palette

| Role | Color |
|---|---|
| Top haze | `#FFCC8C` at 20% |
| Bottom haze | `#FFBF73` at 12% |
| Sun core / mid / rim | `#FFFCEB` / `#FFC659` / `#FF9E2E` (warmth 0.6) |
| Cloud lit / body / shadow | `#FFF7E6` / `#FAE6D1` / `#C7A8A8` |
| Leaves (late month) | `LeafPalette.autumn` set: orange `#FFB833`/`#D94D0D`, red `#F24D26`/`#8C0F14`, gold `#FFE04D`/`#CC8C0D`, brown `#BF7333`/`#663314` |
| Leaves (early month) | add green-gold `#B8C24D`/`#6B7A1F` and olive `#9EAD47`/`#4D5C1A` |

Key light: the low sun, warmth 0.6.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Amber haze top and bottom | |
| 2 | Far | Low sun with soft rays | arc around y 17–22% |
| 3 | Far → Mid | Golden clouds (5) | y 5–50% |
| 4 | Far | Distant small leaves (blurred slightly) | full |
| 5 | Mid | Falling leaves | full |
| 6 | Near | Large out-of-focus leaves | full, few |
| 7 | Post | Bloom on the sun and leaf rim light | |

## Elements

### Sun
- Path as in August with duration 4000 s and start 0.7; radius 58 pt; height parameter 0.17. Warmth 0.6: softer, wider corona (2.6r) and fewer, longer rays (12). Rays pass *through* the haze: brighten the haze density along each ray (cheap volumetric look).

### Clouds
- Five lit sprite clouds, golden palette, lit toward the sun. The undersides catch a rosy bounce color.

### Leaves
- Particle system with the shared wind. Each leaf has depth, size 16–34 pt (near ×1.6), fall speed 45–85 pt/s × depth, flutter (lateral pendulum ±40 pt at 0.8–1.6 rad/s), spin, and a 3D tumble (flip rate 0.9–2.2 rad/s).
- Shapes: maple (55%) and oval (45%) SDFs with veins (port `LeafPainter`).
- **Shading:**
  - front-face gradient from light to dark
  - cupped-surface highlight
  - darker, less saturated back face
  - **translucency:** when the leaf's face points toward the sun, its interior glows warmer and brighter (subsurface approximation, `pow(saturate(dot(faceNormal, sunDir)), 2)`), with a bright rim when edge-on to the sun
  - veins lighter on the front and darker on the back
- Fade in over the top 8% and out over the bottom 12%.

## Living behavior
- Wind: base 14 pt/s, gust 18 pt/s (smooth gusts over 10–27 s periods). Leaf drift integrates the wind so motion stays continuous.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `monthProgress` | Leaf count 30% → 100%; palette blend from early (green-gold) to late (red/orange) sets; haze warmth +15% | 2.5 s discrete (count by particle rank; palette via a per-leaf threshold so leaves change color only while off-screen) |
| `daylightHours` | Sun height and warmth: shorter days → lower, warmer sun | 2.5 s |

## Special days
- **Autumn equinox** (about September 22–23, computed): *leaf release*.
  - A strong gust (wind ×4 for 3 s) sweeps 40 extra leaves in from the left edge, swirling with curl turbulence, while the light warms to warmth 0.8.
  - The extra leaves settle and fall out naturally.
  - The warmer light holds while the day stays selected.

## Theme adaptation
- **Light:** sun as warm tint with an orange rim; leaves read well (saturated). Reduce haze to 10%.
- **Dark:** full bloom on the sun; leaf rim light blooms slightly.

## Readability guardrails
- At most 12 leaves larger than 30 pt inside the content-safe region.
- Near out-of-focus leaves fade to 50% opacity in the central 50% of the screen.

## Metal implementation notes
- Leaves share the particle kernel and SDF shader with November. Build them once as a `LeafSystem` and configure them per month.
- `sceneParams[0] = (leafAmount, paletteBlend, warmth, releaseGust)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Leaves (mid / far / near) | 40 / 30 / 6 | 26 / 18 / 4 | 16 / 10 / 0 |
| Clouds | 5 | 5 | 3 |
| Leaf translucency | full | full | rim only |

## Acceptance criteria
- [ ] The light feels like golden hour: warm, low and hazy.
- [ ] Leaves tumble convincingly and glow when backlit by the sun.
- [ ] Leaf count and color progress across the month via discrete transitions, with no visible color pops.
- [ ] Equinox leaf release plays once per arrival.

## Porting reference
`SeptemberLeavesAnimation`, `SkyScene`, `FallingLeavesRenderer` and `LeafPainter` in the Canvas code.
