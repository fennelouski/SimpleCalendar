# May: Meadow in Bloom

> A meadow fringes the bottom of the screen: swaying grass, and flowers that rise, open their petals, nod in the breeze and quietly fade. Petals and glowing pollen drift through warm spring light.

## Product description

May is lush and warm. Two rows of grass blades sway along the bottom, the back row muted, the front row bright. Flowers grow up through the grass in a gentle cycle: a stem rises with a leaf, a bud swells, and the petals open. There are daisies, pink cosmos, red poppies, pink and golden tulips, and violets. The flowers sway, then wilt back down so others can bloom. Pink petals tumble across the screen on the breeze, flipping in 3D. Tiny pollen motes glow in soft light coming from the top-right corner.

The meadow fills in as May progresses. On Mother's Day, the whole meadow blooms at once in a wave and a gentle shower of petals falls.

## Mood and palette

| Role | Color |
|---|---|
| Sunlight pool (top right) | `#FFF2C7` at 22% |
| Grass back tip / base | `#99D173` / `#336B38` at 60% |
| Grass front tip / base | `#8CE059` / `#1A611F` at 90% |
| Daisy petals / center | `#E6E6FA` → `#FFFFFF` / `#FFD933` → `#D98012` |
| Cosmos | `#BF1A73` → `#FFB3D9` |
| Poppy | `#B30808` → `#FF592E`, center `#261A1F` |
| Tulip pink / gold | `#C71A59` → `#FF99B8` / `#EB800D` → `#FFEB66` |
| Violet | `#591F99` → `#BF99FF` |
| Pollen | `#FFEB8C` HDR 1.8 |

Key light: late-morning sun, upper right (0.92 W, −0.05 H), warmth 0.3.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Sunlight pool | top right, radius 0.5 W |
| 2 | Far | Pollen motes (far) | y 15–85% |
| 3 | Mid | Back grass row | bottom 8% |
| 4 | Mid | Flowers (9 slots) | stems from the bottom edge, heads 80–150 pt up |
| 5 | Mid | Front grass row | bottom 5.5% |
| 6 | Mid/Near | Drifting petals | y 20–75% |
| 7 | Near | Large blurred pollen bokeh | sparse |
| 8 | Post | Bloom on pollen and sunlit petal edges | |

## Elements

### Grass
- Instanced blades: back row 340, front row 260 (High). Each blade is a tapered curved quad (3–6.5 pt wide at the base), bent by `bend = (gust(x, t) + lean) · height · 0.35`, where `gust` is the shared wind sampled at the blade's x (so waves of wind visibly travel across the meadow).
- Shading: base-to-tip gradient, translucency (blades facing the key light glow yellow-green at the tip), and a thin specular along the blade's midline.

### Flowers
- Nine slots, cycle 28 s. Each cycle picks a new kind and x position deterministically.
- Lifecycle per cycle:
  - 0–20%: stem grows to 80–150 pt
  - 16–36%: the bud opens (petals scale and rotate open; tulips go from cup-closed to cup-open)
  - 36–85%: sways ±7 pt; heads nod slightly with the wind
  - 85–100%: petals droop, the head lowers, and the flower fades
- One oval leaf on the stem at 35% height, pointing left or right.
- **Radial flowers** (daisy 14 petals, cosmos 8, poppy 5, violet 6): petals are SDF ellipses or teardrops with a gradient from the deep inner color to the light outer color, a center crease highlight, and a slight cupping (lighter rim). The head is foreshortened (y-scale 0.82) so it reads as seen slightly from the front. Centers are domed with a radial gradient plus a ring of stamen dots.
- **Tulips:** three overlapping cup petals (back two darker), vertical gradient, gloss streak on the front petal.
- Each open flower casts a soft colored glow (radius 1.9× head) and a subtle drop shadow on the grass.

### Drifting petals
- 14 pink and white petals moving left to right at 35–70 pt/s, bobbing ±40 pt, spinning, flipping in 3D (back face 55% opacity).

### Pollen
- 32 motes: drift 4–14 pt/s with sway, pulse 0.8–1.8 rad/s, additive glow radius 9 pt. Near-layer bokeh: 6 large, faint discs.

## Living behavior
- Wind: base (20, 0), gust 0.35, with spatial gusts that travel visibly across the grass.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `monthProgress` | The meadow fills in: active flower slots 5 → 9, grass height ×0.8 → ×1.1, pollen ×0.6 → ×1.2 | 2.5 s discrete |

## Special days
- **Mother's Day** (second Sunday of May in the US; use `HolidayManager` for the locale): *bloom wave*.
  - All nine slots grow and open in a left-to-right wave over 4 s, ignoring their cycle offsets.
  - Then they hold in full bloom while the day stays selected.
  - Petal drift ×3 for 6 s, falling gently from the top instead of blowing across.
  - When the selection leaves, flowers return to their normal cycles over the next transition.

## Theme adaptation
- **Light:** pollen uses tinted-over (deeper gold `#D9A400` with a halo). White daisies get a soft gray-violet petal edge (`#B8B3D9` at 50%) so they show on white. Reduce the sunlight pool to 12%.
- **Dark:** full bloom on pollen; sunlit petal rims glow.

## Readability guardrails
- Flower heads stay below 15% of H from the bottom.
- Drifting petals larger than 14 pt stay out of the central 40% of the screen. If one enters, fade it to 40% opacity.

## Metal implementation notes
- Grass: one instanced draw per row. The vertex shader bends blades using the wind function. No CPU per-blade work.
- Flowers: CPU lifecycle state into an instance buffer. One SDF fragment shader with a `kind` switch.
- Petals and pollen: particle system.
- `sceneParams[0] = (meadowFill, bloomWave, petalShower, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Grass blades back / front | 340 / 260 | 220 / 170 | 140 / 110 |
| Flower slots | 9 | 8 | 6 |
| Petals | 14 | 10 | 6 |
| Pollen / bokeh | 32 / 6 | 22 / 4 | 14 / 0 |

## Acceptance criteria
- [ ] Wind visibly travels across the grass in waves.
- [ ] Each flower type is recognizable and blooms with a convincing opening motion.
- [ ] No popping between flower cycles.
- [ ] The meadow fills in as May progresses, via discrete transitions.
- [ ] Mother's Day bloom wave plays on arrival and holds.

## Enhancements
Small details that reward watching. Each keeps the month's original idea, follows its readability guardrails (edges and corners only for new scenery), and stays within the CPU rules in architecture section 13.

- **Bees:** 2–4 bees (tiny striped SDFs with a blur-disc for wings) fly short curving hops between open flowers. When a bee lands, the flower head dips 3–5 pt and springs back.
- **Flowers follow the sun:** open flower heads tilt up to 12° toward the key light.
- **Dandelions:** one slot in four may grow a dandelion clock instead of a flower. When a gust passes, it releases 10–20 seeds that drift slowly up and across the scene and fade.

## Porting reference
`MayFlowersAnimation` and `MayScene` (flower kinds, grass, petals, pollen) in `MonthAnimations.swift`.
