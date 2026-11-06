# June: Butterfly Light

> Shafts of warm sunlight slant in from the top-left corner. Butterflies of five species flutter across on looping paths, wings flashing pattern and iridescence, while soft bokeh drifts in the haze.

## Product description

June is warm and luminous, the feeling of a sunny garden at midday. Soft god rays pour diagonally from the top-left corner and gently breathe in intensity. Out-of-focus discs of light float slowly, as if seen through a lens. Five butterflies travel across the screen on gentle wavy paths: a monarch, a blue morpho, a swallowtail, a peacock and an emerald swallowtail. Their wings flap with real 3D foreshortening and alternate between bursts of flapping and glides. The morpho and emerald flash iridescent color as their wings tilt. Each butterfly casts a faint shadow on the scene below.

The length of the selected day's daylight sets how strong the sunlight is. On the summer solstice the beams are at their brightest and the butterflies gather and circle together in the light.

## Mood and palette

| Role | Color |
|---|---|
| Sun glow (corner) | `#FFF2BF` at 30% |
| Beams | `#FFF2BF` at 30% → 0 |
| Bokeh | `#FFE699`, `#B3FFB3`, `#FFCCE6` at 12–20% |
| Monarch | base `#D95905`, bright `#FF9E1F`, border `#140D0A`, spots white |
| Blue morpho | base `#0040BF`, bright `#40D9FF`, border `#0A0D1F`, iridescent |
| Swallowtail | base `#F2C71A`, bright `#FFF280`, border `#1A140D`, eyespots |
| Peacock | base `#8C0F1F`, bright `#E64040`, eyespot ring `#FFE680` |
| Emerald swallowtail | base `#05523A`, bright `#40F299`, iridescent |

Key light: high sun beyond the top-left corner (0.06 W, −0.12 H), warmth 0.25.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Corner sun glow and god rays | from the top-left corner, angles 0.42–1.08 rad |
| 2 | Far | Dust motes in the beams | inside the beams only |
| 3 | Near (blurred) | Bokeh discs | full |
| 4 | Mid | Butterfly shadows | 0.9 × wingspan below each butterfly |
| 5 | Mid | Butterflies (5) | y 20–70% |
| 6 | Post | Bloom on wing iridescence and beam cores | |

## Elements

### God rays
- 7 beams computed in a full-screen pass as angular wedges from the corner with soft edges (polar-space noise for breakup). Intensity breathes `0.6 + 0.4 sin(0.3t + 1.9i)`. Beams drift ±0.03 rad over about 2 minutes.
- Dust motes (High: 80) are visible *only inside the beams*: multiply mote opacity by the beam mask, which sells the volumetric look.

### Bokeh
- 16 discs, radius 14–40 pt, with a slightly brighter rim and a faint hexagonal aperture shape on High. Slow drift, pulse 0.7–1.0.

### Butterflies
- Flight path: x crosses the screen over 38–58 s (alternate directions); `y = base + sin(progress · 2π · k) · 0.08 H + bob`, with a bob of ±10 pt at 2.7 rad/s. Heading follows the path tangent.
- **Wings:** forewing and hindwing SDFs per side (port `JuneScene.forewing`/`hindwing` silhouettes).
  - Flap = `sin(rate·t + φ) · amplitude`, rate 8–11 rad/s. Amplitude alternates between flapping (1.0) and gliding (0.25) on a slow `sin(0.4t)`.
  - Projection: each wing's x-scale = `0.1 + 0.9 · open`, which shows foreshortening as the wings rise. Add a subtle y-skew at full close for realism.
- **Wing shading:**
  - a radial gradient from the dark root through the bright mid-wing to a dark border
  - veins (stroked SDF curves from the root)
  - a white spot row along the outer margin
  - eyespots (concentric rings with a white catchlight) for the swallowtail and peacock
  - **iridescence** for the morpho and emerald: a thin-film-style hue shift driven by the wing tilt (`open`), so the color sweeps cyan → blue → violet as the wing angle changes, with a moving specular band. This goes to the emissive target.
- **Body:** segmented abdomen with a cylindrical gradient, fuzzy thorax (noise rim), head, and antennae with clubbed tips.
- **Shadow:** a soft ellipse below, width proportional to wing openness.

## Living behavior
- Wind: base (6, −2), gust 0.2. It slightly drifts butterfly paths and bokeh.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `daylightHours` | Beam intensity and sun glow scale from ×0.7 (shortest June day) to ×1.15 (solstice); warmth eases between 0.3 and 0.2 | 2.5 s discrete |
| Day character (hash) | Butterfly species mix: which 5 of the species appear, with duplicates allowed. Changes swap one butterfly at a time *off-screen*, never mid-screen | applied as butterflies leave the screen |

## Special days
- **Summer solstice** (about June 20–21, computed): *gathering*. Over 3 s the five butterflies leave their paths and converge into a loose, slowly orbiting cluster inside the brightest beam (orbit radius 120–200 pt), flapping in near-sync, with beam intensity ×1.3. They hold while the day stays selected and drift back to their paths when it changes.

## Theme adaptation
- **Light:** beams become a warm *shadowless* tint (multiply-style warm `#FFE7B0` at 15%) instead of additive light. Bokeh becomes faint warm rings. Butterflies read well as they are.
- **Dark:** beams additive with bloom; iridescence blooms.

## Readability guardrails
- Beam opacity is capped at 18% (after global opacity) where it crosses the content-safe region.
- At most two butterflies inside the content-safe region at once; others get a slight path bias toward the edges.

## Metal implementation notes
- Beams and motes: one full-screen pass plus a particle system with beam-mask modulation.
- Butterflies: CPU computes the path, heading and flap per butterfly into an instance buffer. One SDF shader draws both wings (mirrored via an instance side flag), the body and the antennae.
- `sceneParams[0] = (beamIntensity, warmth, gathering, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Butterflies | 5 | 5 | 3 |
| Beam dust motes | 80 | 40 | 0 |
| Bokeh | 16 (hex aperture) | 12 | 6 (no blur) |
| Iridescence | full thin-film | simplified sheen | simplified sheen |

## Acceptance criteria
- [ ] Wings show convincing 3D flapping with flap-and-glide rhythm.
- [ ] Each species is distinguishable; morpho and emerald visibly shimmer.
- [ ] Dust is visible only in the light shafts.
- [ ] Beam strength follows daylight via discrete transitions.
- [ ] Solstice gathering moment works and releases cleanly.

## Porting reference
`JuneButterfliesAnimation` and `JuneScene` (species, wing paths, flight paths, beams, bokeh) in `MonthAnimations.swift`.
