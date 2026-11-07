# March: Emerald Hills

> Layered green hills roll along the bottom of the screen. Shamrocks sprout, unfurl their leaves, sway, and wilt in an endless cycle, while golden motes of luck drift up into the air.

## Product description

March is about spring waking up. Three layers of rolling hills sit along the bottom, misty and pale in the distance and rich emerald up close, each with a sunlit ridge line. Shamrocks grow out of the two nearer hills: a stem rises, three heart-shaped leaflets unfurl with their pale chevron markings, they sway in a gentle breeze, and eventually droop and fade so a new one can sprout somewhere else. Now and then a rare four-leaf clover appears and glows softly gold, with a sparkle orbiting it. Golden motes rise slowly from the hills and twinkle.

As the selected day moves through March, the hills get greener and more shamrocks grow. On St. Patrick's Day the hills fill with clovers and a faint rainbow arcs over the scene.

## Mood and palette

| Role | Color |
|---|---|
| Bottom haze | `#BFF2B3` at 18% |
| Far hill top / base | `#9ED199` / `#619E6B` at 45% |
| Mid hill top / base | `#6BC266` / `#2E7A38` at 60% |
| Near hill top / base | `#52B34D` / `#145C1F` at 78% |
| Ridge light | `#D9FFBF` at 55% |
| Leaflet light / mid / dark | `#94EB73` / `#38A842` / `#126626` |
| Chevron | `#FFFFFF` at 28% |
| Gold mote | `#FFD959` HDR 2.0 |

Key light: morning sun from the upper right (1.05 W, 0.0 H), warmth 0.35.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Green haze | bottom 35% |
| 2 | Far | Gold motes (far) | lower 90% |
| 3 | Far | Far hill | crest around 10% of H from the bottom |
| 4 | Mid | Mid hill | crest around 7.2% |
| 5 | Mid | Shamrocks (back row, scale 0.72) | on the mid hill surface |
| 6 | Mid | Near hill | crest around 4.2% |
| 7 | Mid | Shamrocks (front row, scale 1.0) | on the near hill surface |
| 8 | Near | Gold motes (near, blurred) | lower 70% |
| 9 | Post | Bloom on motes and four-leaf glow | |

## Elements

### Hills
- Ridge height `h(x) = H·hᵢ·(0.78 + 0.3·(0.55 sin(3.1u + 1.7i) + 0.3 sin(7.3u + 0.6i) + 0.15 sin(15u + 2.9i)))` (port `MarchScene.hillY`), plus fine fbm grass texture.
- Shading: vertical gradient, a lighter ridge rim facing the key light, and soft grass-blade noise near the crest (anisotropic noise stretched vertically) so it reads as turf, not plastic.
- Far hill gets atmospheric haze (blend 35% toward the sky haze color).

### Shamrocks
- Ten slots across the width, alternating back and front rows. Each slot cycles every 24 s with a random offset. Every cycle picks a new x position within the slot (deterministic: `hash(slot·977 + cycle)`).
- Lifecycle per cycle:
  - 0–22%: stem grows, ease-in-out
  - 15–38%: leaflets unfurl (width 40% → 100%, rotate open)
  - 38–82%: sway, ±6 pt at the top, period about 7 s
  - 82–100%: wilt (stem shortens 30%, leans 22 pt, fades out)
- Stem: a quadratic curve, width 3.2 pt × scale, gradient from dark at the base to light at the top.
- Leaflets: SDF hearts with the tip toward the center, three at 120° (four for a four-leaf clover). Each has a gradient from bright lobes to a dark center, a midrib, the pale chevron typical of clover, and a small specular highlight.
- **Four-leaf clover:** 22% chance per cycle. Gold glow (`#FFD94D`, radius 2.6× leaf size, additive) and a sparkle orbiting at 1.4 rad/s.

### Gold motes
- 26 total (High tier): 70% far, 30% near (blurred). Rise 10–24 pt/s with ±22 pt sway; twinkle `pow(max(0, sin(rate·t + φ)), 3)`; four-point sparkle at peaks.

## Living behavior
- Wind: base (3, 0), gust 0.25. Shamrock sway and mote drift both follow it.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `monthProgress` (day of March) | Spring greening: hills go from a muted olive (top `#8DB37A`) on March 1 to the full emerald palette by March 31. Shamrock slots in use go from 6 to 10. | 2.5 s discrete |
| Near the spring equinox (about March 20) | Key light warmth eases from 0.35 to 0.5 | same transition |

## Special days
- **St. Patrick's Day (March 17):**
  - All active shamrocks become four-leaf clovers for that visit.
  - Gold motes ×3.
  - A faint rainbow arc fades in over 3 s: center (0.5 W, 1.25 H), radius 0.9 W, spectral band 28 pt wide at 18% opacity, upper half only, hidden behind the hills.
  - The rainbow stays as long as March 17 remains selected. It fades out over 2.5 s when the selection leaves.

## Theme adaptation
- **Light:** reduce hill opacity by 15% and saturation by 10% so the bottom doesn't get heavy. Gold motes use the tinted-over recipe (deeper gold `#E0A800` with a soft halo).
- **Dark:** motes and the four-leaf glow bloom.

## Readability guardrails
- The hills must stay in the bottom 11% of the screen.
- Shamrock tops never exceed 16% of H from the bottom.

## Metal implementation notes
- Hills: one full-width quad per layer. The fragment shader computes the ridge, the gradient and the grass noise.
- Shamrocks: CPU decides lifecycle state per slot and writes an instance buffer `{position, scale, stemHeight, sway, unfurl, wilt, leafCount, opacity}`. The vertex and fragment shaders draw the stem and leaflets as SDF instances.
- Motes: particle system, additive.
- `sceneParams[0] = (greening, activeSlots, rainbow, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Shamrock slots | 10 | 8 | 6 |
| Gold motes | 26 | 18 | 10 |
| Grass noise on hills | on | on | off |
| Rainbow | on | on | on |

## Acceptance criteria
- [ ] Hills look like soft turf with depth and lit ridges, not flat bands.
- [ ] Shamrocks visibly grow, unfurl, sway and wilt, with no popping between cycles.
- [ ] Four-leaf clovers are rare, glowing and delightful.
- [ ] Hills green up across March via discrete transitions.
- [ ] St. Patrick's Day shows all four-leaf clovers and a rainbow.

## Enhancements
Small details that reward watching. Each keeps the month's original idea, follows its readability guardrails (edges and corners only for new scenery), and stays within the CPU rules in architecture section 13.

- **Clover patches:** new shamrocks sprout next to existing ones along a spreading patch (runner growth) rather than at isolated random spots. Each patch lives for 2–4 cycles, then fades and starts somewhere else.
- **Dew and mist:** early in each shamrock's life its leaflets carry 1–3 dew beads that glint (emissive), and a thin morning mist lifts off the far hill and dissipates over the first 30 s after the month appears.
- **Leaflets fold:** real clover folds its leaflets in strong wind and at night. During gusts above 0.6, leaflets fold up toward the stem by up to 40% and reopen after.
- **Hidden four-leaf clover:** besides the rare glowing ones, each visit hides one unglowing four-leaf clover among the others, revealed only by a glint every 8–12 s.

## Porting reference
`MarchShamrocksAnimation` and `MarchScene` in `MonthAnimations.swift`.
