# November: Gusting Leaves

> A blustery late-autumn day under soft overcast light. Gusts sweep waves of leaves across the screen; they tumble, swirl in eddies and settle into a rustling pile along the bottom.

## Product description

November is about wind. The light is muted, a warm gray overcast with a rusty glow near the ground. Leaves don't drift gently like in September; they are *blown*. Gusts build and fade, and with each one a wave of leaves sweeps sideways across the screen, swirling in little eddies, tumbling end over end, some close to the camera and blurred. Along the bottom edge a thick pile of fallen leaves rustles and lifts slightly whenever a gust passes, sometimes kicking a leaf back up into the air.

As November goes on, the trees are emptying: fewer leaves are in the air, more are on the ground, browns take over from oranges, and the light grows grayer. On Thanksgiving a warm harvest glow settles over the scene and the wind calms.

## Mood and palette

| Role | Color |
|---|---|
| Top haze (overcast) | `#B39E8C` at 16% |
| Bottom glow | `#D98C4D` at 14% |
| Leaves (early month) | `LeafPalette.autumn` (orange, red, gold, brown, rust) |
| Leaves (late month) | browns `#8C5C33`/`#4D2E14`, tan `#BFA073`/`#735A33`, faded red `#A64D40`/`#592121` |
| Pile shadow | `#3D2614` at 35% |

Key light: diffuse overcast from above, (0.4 W, −0.6 H), intensity 0.55, warmth 0.4.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Overcast haze top, warm glow bottom | |
| 2 | Far | Distant leaves (small, slightly blurred) | full |
| 3 | Mid | Blown leaves | full |
| 4 | Mid | Leaf pile with contact shadows | bottom 4% |
| 5 | Near | Large blurred leaves | few |
| 6 | Post | Gentle bloom only on the bottom glow | |

## Elements

### Wind (the star of this month)
- Base 55 pt/s with strong gusts: gust amplitude 70 pt/s from low-frequency noise over 8–20 s periods. Gusts *travel*: the gust envelope is a function of `(t − x / 600)`, so the wave visibly sweeps from left to right.
- Curl-noise eddies (turbulence 0.6) make leaves loop and swirl within gusts.

### Blown leaves
- Leaf system shared with September (maple and oval SDFs, translucency off since the light is overcast, two-sided shading, veins).
- Motion: driven mainly by wind *force* with drag, not a fixed fall speed, so leaves can rise briefly in eddies. Gravity 30 pt/s², drag 1.2. Flutter, spin and 3D tumble faster than September (flip rate 1.5–3.5 rad/s during gusts).
- Depths: far 30, mid 34, near 6 (High).

### Leaf pile
- About `W / 22` leaves arranged along the bottom (y between H − 26 and H + 4 pt), overlapping, mostly face-up, with soft contact shadows between layers.
- **Rustle:** during a gust, pile leaves near the gust front rotate slightly (±0.06 rad) and lift 1–3 pt. Occasionally (High tier, at most one every 4 s) a pile leaf is *lifted* into the air as a blown leaf, and a falling leaf lands to replace it, so the pile feels alive. Swaps happen only during gusts.

## Living behavior
- See *Wind*. Gust cadence never syncs into a recognizable loop (noise-based, not a sum of two sines).

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `monthProgress` | Airborne leaves 100% → 45%; pile height ×1.0 → ×1.4; palette blend toward the late-month browns; haze grayer (overcast +30%) | 2.5 s discrete (counts by particle rank; palette changes only while leaves are off-screen) |
| Day character (hash) | Wind character: **Breezy** (30%): base ×0.6, gusts ×0.6. **Blustery** (50%): ×1. **Gale** (20%): base ×1.5, gusts ×1.5, near leaves ×2 | 2.5 s discrete |

## Special days
- **Thanksgiving** (US: fourth Thursday of November; Canada's is in October, and its October visit uses the same moment; respect enabled holidays): *harvest calm*.
  - Over 3 s the wind drops to a gentle breeze (base 10) and the light warms (bottom glow ×2, warmth 0.7).
  - A slow swirl of about 20 golden leaves spirals once across the center top area and settles into the pile.
  - Holds while selected.

## Theme adaptation
- **Light:** leaves read well. Reduce the haze to 10%, and render the pile's contact shadows at 20%.
- **Dark:** as specified. The pile gets a subtle warm rim from the bottom glow.

## Readability guardrails
- At most 14 airborne leaves larger than 26 pt inside the content-safe region; near leaves fade to 45% opacity there.
- The pile stays within the bottom 4% (5% at the end of the month).

## Metal implementation notes
- Reuse `LeafSystem` from September with a wind-driven integrator variant (force-based).
- The pile is a static instance buffer regenerated per month visit; rustle is applied in the vertex shader from the gust envelope at each leaf's x.
- Lift and land swaps: the CPU picks a pile index and spawns a particle at its position; the pile instance hides by opacity.
- `sceneParams[0] = (airborne, pileHeight, paletteBlend, overcast)`, `sceneParams[1] = (gustFrontX, gustStrength, harvestCalm, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Airborne leaves (far / mid / near) | 30 / 34 / 6 | 18 / 24 / 4 | 10 / 16 / 0 |
| Pile leaves | W/22 | W/28 | W/36 |
| Lift and land swaps | on | on | off |
| Curl eddies | full | reduced | off (wind only) |

## Acceptance criteria
- [ ] Gusts visibly travel across the screen as waves, with leaves swirling in eddies.
- [ ] The pile rustles in time with passing gusts and occasionally loses or gains a leaf.
- [ ] Leaves thin out and brown across the month via discrete transitions.
- [ ] Thanksgiving calm plays on arrival and holds.

## Enhancements
Small details that reward watching. Each keeps the month's original idea, follows its readability guardrails (edges and corners only for new scenery), and stays within the CPU rules in architecture section 13.

- **Bare branches:** dark branches enter from both top corners and sway in the gusts. Leaves visibly detach from them. They grow barer through the month (fewer attached leaves as `monthProgress` rises).
- **Ground skitter and leaf devils:** some leaves cartwheel along the bottom edge instead of flying. Strong gusts occasionally spin up a small leaf whirlwind (8–14 leaves on a rising spiral) that collapses after 3–5 s.
- **Weather on the leaves:** after a wet day (day hash), leaves look darker and glossier and fall straighter. In the last week of the month, the pile shows frost edges in the morning hours (real local time before 10:00).
- **Geese:** a V of geese crosses high and slow every few minutes (GPU swarm, simple silhouettes).

## Porting reference
`NovemberLeavesAnimation`, `NovemberScene.drawLeafPile`, `FallingLeavesRenderer` and `LeafPainter` in the Canvas code.
