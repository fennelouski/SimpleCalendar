# October: Harvest Moon

> A deep autumn night. The moon (showing the true phase of the selected day) hangs over a field of stars as silver-lit clouds drift across it, a murmuration of bats pours out of a belfry and wheels through the sky, fog creeps along the ground, and two jack-o'-lanterns flicker in the corners.

## Product description

October is atmospheric and a little spooky, but cozy rather than frightening. The top of the screen falls into an indigo night full of twinkling stars. The moon is the star of the scene: a realistically lit sphere with dark maria, bright ray craters like Tycho and Copernicus, a soft terminator, and faint earthshine on its night side. Its phase is the *real* phase for the selected day. As the user moves between days, the moon smoothly waxes or wanes over 2.5 s. Thin clouds drift across the sky, silver-edged where they face the moon and occasionally passing right in front of it. A colony of bats streams out of an old belfry and murmurates across the sky in ribbons and ripples, rim-lit by moonlight, before funneling back home. Ground fog drifts along the bottom, and two carved pumpkins glow from within with candle flicker.

On full-moon days the moon is a true harvest moon: larger, warmer and brighter, with a stronger halo. On Halloween the bats swarm across the moon and the jack-o'-lanterns blaze.

## Mood and palette

| Role | Color |
|---|---|
| Night haze (top) | `#120D33` at 32% → 0 by 65% height |
| Stars | `#E0EDFF`, warm `#FFE6C7` (20%) |
| Moon highlands / maria | `#FCFAF0` → `#BDBDC2` limb / `#858A94` |
| Earthshine | moon albedo × `#57668F` at 3% |
| Moon halo | `#D1E0FF`, intensity 0.06 + 0.24 × illumination |
| Night cloud lit (by illumination) / body / shadow | `#8C94B3` → `#E6EBFF` / `#666B85` / `#29293D` |
| Bats | `#120D1A` at 92%, rim `#BFCCFF` at 45% |
| Fog | `#B8B3D9` at up to 32% |
| Pumpkin | `#FF9E26` → `#E0660A` → `#802E05` |
| Candle glow | `#FFF7B3` → `#FF9914` |

Key light: the moon. Its position, plus intensity = illumination.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Night haze and star field (110) | top 55% |
| 2 | Far | Moon with halo | slow swing across the top, y ≈ 13.5–20.5% |
| 3 | Mid | Night clouds (4) passing in front of the moon | y 8–30% |
| 4 | Far → Near | Belfry silhouette and bat murmuration (up to 400 bats) | belfry lower-left; flock in the upper 60% |
| 5 | Mid | Jack-o'-lanterns | bottom-left (5.5% W, H − 46 pt, 78 pt) and bottom-right (94% W, H − 36 pt, 58 pt) |
| 6 | Near | Ground fog | bottom 10% |
| 7 | Post | Bloom on the moon, candle light and rim light | |

## Elements

### Moon (the centerpiece)
- **Motion:** `x = W(0.5 + 0.33 sin(2πt/1500 + 0.95))`, `y = H(0.17 − 0.035 cos(…))`. It swings back and forth over 25 minutes, so there is never a wrap-around jump. Radius = 7.5% of min(W, H) (81 pt on 1080p).
- **Rendering:** the sphere shader from architecture 7.5.
  - Normal from the disc; light direction from the phase: `L = (sin 2πφ, 0, −cos 2πφ)`. Waxing is lit on the right and waning on the left (Northern Hemisphere view).
  - Lommel-Seeliger shading (no Lambert limb darkening) gives the flat, bright look of the real full moon.
  - Albedo: the procedural near-side map (maria and craters at the positions in `MoonPainter`: Procellarum, Imbrium, Serenitatis, Tranquillitatis, Crisium, Fecunditatis, Nubium, Nectaris, Vaporum, Humorum; craters Tycho with rays, Copernicus with rays, Kepler, Plato, Aristarchus plus about 18 small craters), or a licensed lunar albedo texture. Add subtle normal-mapped crater relief so the terminator looks rugged at quarter phases.
  - **Earthshine** on the unlit side: albedo × 3%, cool blue, strongest near new moon (scale by `1 − illumination`).
  - Halo: two radial glows (4.2r and 1.7r), intensity proportional to illumination.
- **Phase:** comes from the `moonPhase` signal (`MoonPhase.fraction(forDay:)`, sampled at local noon) through a `DiscreteTransition` (cyclic, 2.5 s). This is the defining feature of the month. See the selection table.

### Night clouds
- Four lit sprite clouds, widths 300–460 pt, crossing in 70–120 s, fading in and out at the edges.
- Lit toward the moon; the lit color brightens with illumination (dim on a crescent night, silver on a full moon).
- When a cloud passes in front of the moon, the moon is attenuated by the cloud's density (Beer-Lambert) and the cloud's edge around the moon gets a bright corona-like lining. On High, add a faint lunar corona (a colored diffraction ring, radius 1.4r) through thin cloud.

### Bat murmuration
The bats move as a true murmuration: hundreds of them streaming out of a belfry, folding into ribbons, rippling, scattering, regrouping, and streaming back home. Built on the GPU swarm system (architecture 7.10), so it costs no CPU.

- **Count:** up to 400 bats (High), at three depths. Near bats are larger, slightly blurred and fewer.
- **Belfry:** a small church-belfry silhouette in the lower-left corner (about 9% of W wide, sitting behind the left pumpkin and the fog), dark with a faint moonlit roof edge. It's the colony's home.
- **Cycle** (deterministic schedule, about 90 s per loop, never visibly repeating because the lead path keeps wandering):

  | Phase | Duration | What happens |
  |---|---|---|
  | Emerge | 8–12 s | bats pour out of the belfry in a column, staggered by index, and spiral up into the sky |
  | Murmurate | 40–60 s | the flock wanders the upper sky as a ribbon; ripple waves run through it every 6–10 s; occasional quick expansions (as if dodging a predator) |
  | Scatter | 5–8 s | the flock loosens across the sky (spread 1.0), then regroups |
  | Return | 10–14 s | the flock funnels down and back into the belfry |
  | Rest | 6–10 s | only a few stragglers flit near the belfry |

- **Moonlight reacts:** while a cloud covers the moon (density at the moon > 0.5), the flock loosens (spread +0.3) and the rim light fades. When the moon reappears, the flock tightens and the rims brighten.
- **Look (simplified on purpose):** bat silhouette SDF with ears and a scalloped wing edge, two-pose flap (`flap = sin(rate·t + φ)`, rate 13–19 rad/s). Rim light from the moon. Near bats crossing the moon disc show a faint warm glow through the wing membrane.
- **Readability:** the lead path stays in the upper 60% of the screen and is biased toward the sides; at most 40 bats are inside the content-safe region at once. Ripple and expansion speeds stay below 300 pt/s for anything larger than 4 pt.
- **Stopgap fallback:** if the GPU swarm isn't ready, layer the existing Canvas bats (`BatFlock` boids plus `OctoberScene.drawBat`) over the Metal October background (architecture section 16). That keeps their CPU cost and drops the belfry cycle, so replace it when the swarm lands.

### Jack-o'-lanterns
- SDF pumpkin: five ribs (outer ribs darker) with a linear gradient and rib grooves, a waxy specular highlight, a curved stem, and a carved face (triangle eyes, nose, toothy mouth).
- The face is emissive: HDR candle color with flicker `0.78 + 0.12 sin(13t) + 0.1 sin(23.7t + 1)` (the second pumpkin is offset).
- The candle lights the scene: a warm glow halo (1.8× size), light spilling onto the fog around it, and a contact shadow on the ground.

### Ground fog
- High tier: a ½-res volumetric fog band (3D noise, scrolling with the wind at 6–16 pt/s), lit by the moon from above and by the pumpkins from within. Medium and Low: five blurred noise-sprite banks.
- The fog drifts *over* the pumpkins (partially veiling them).

## Living behavior
- Wind: base (10, 0), gust 0.2. Clouds and fog follow it; bats are self-propelled.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| `moonPhase` | The moon's lit portion, earthshine, halo and cloud lighting | **2.5 s discrete, cyclic (shortest way around)**. A transition always completes. Selections made during it are ignored. On completion the moon re-reads the *current* selection and animates again if it differs. The first appearance shows the phase immediately. |
| `moonIllumination` | Star-field visibility: fewer faint stars near full moon (moonlight washes them out) | follows the phase transition |

## Special days
- **Full moon (illumination ≥ 0.98 on the selected day):** *harvest moon*. Radius ×1.12, a warmer tint (`#FFF1D6`), halo ×1.4, cloud linings stronger. This rides on the same phase transition, with no separate moment.
- **Halloween (October 31):** *swarm*.
  - The colony doubles (up to 800 on High) and skips the rest phase.
  - Within 2 s of arrival the flock does a tight sweep across the moon disc, then resumes the murmuration.
  - Pumpkin flicker brightens ×1.3 and the fog thickens ×1.5.
  - Faint green-white wisps (curl-noise ribbons, 3 of them) drift through the fog.
  - These effects hold while October 31 remains selected; the sweep plays once per arrival.

## Theme adaptation
- **Light:**
  - The belfry becomes a pale blue-gray silhouette (`#7A8399` at 60%).
  - The night haze is reduced to 12% so the page doesn't darken.
  - The moon renders with stronger limb contrast and a thin cool outline so it reads on white.
  - Stars are off.
  - Bats become a lighter blue-gray (`#5C6680` at 70%).
  - Fog becomes a light lavender veil at 18%.
  - Pumpkins render normally, with candle glow as a warm tint.
- **Dark:** full night treatment, bloom on the moon and candles.

## Readability guardrails
- The moon's center stays above 21% of H.
- At most 40 bats inside the content-safe region at a time (the lead path keeps the flock in the upper 60% and biased to the sides).
- Fog stays in the bottom 10%. Pumpkins stay in the corners.

## Metal implementation notes
- The moon is its own pass into the far layer at full resolution (crisp edges, no blur). Its halo goes to the emissive target.
- The cloud pass outputs density at the moon's position for attenuation.
- Bats: GPU swarm (architecture 7.10). The CPU writes only the flock-state schedule values (`spread`, ripple, emergence progress) and the lead path parameters.
- `sceneParams[0] = (moonPhase, illumination, harvestMoon, halloween)`, `sceneParams[1] = (moonCenter.xy, moonRadius, cloudAtMoon)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Moon | full shader with normal relief | full shader | full shader, no relief |
| Stars | 160 | 110 | 70 |
| Bats (GPU swarm) | 400 (800 on Halloween) | 220 (440) | 120 (240) |
| Fog | volumetric | sprites | sprites |
| Lunar corona | on | off | off |

## Acceptance criteria
- [ ] The moon's phase matches the selected day (verify against published phases: within one day's appearance), lit on the correct side for waxing and waning.
- [ ] Phase changes animate over exactly 2.5 s, never stack, and pick up the latest selection when complete. Holding focus-scroll for 10 s produces a sequence of whole 2.5 s transitions, not a jitter.
- [ ] The moon looks like a lit sphere with a rugged terminator and earthshine, not a flat disc with a mask.
- [ ] Clouds attenuate the moon and get silver linings.
- [ ] Bats stream out of the belfry, murmurate with visible ripple waves, scatter and regroup, and return home, with moonlit rims.
- [ ] The flock reacts when clouds cover and uncover the moon.
- [ ] Bats add no measurable CPU cost (they're a pure GPU function of time).
- [ ] Harvest moon on full-moon days; Halloween swarm once per arrival.
- [ ] Snapshot tests at phases 0, 0.25, 0.5 and 0.75 in light and dark themes.

## Enhancements
Small details that reward watching. Each keeps the month's original idea, follows its readability guardrails, and stays within the CPU rules in architecture section 13.

- **Low harvest moon:** on full-moon days, the moon starts its swing low near the horizon line, larger and orange (`#FFC27A`), and whitens as it rises over about 3 minutes.
- **Moonlit fog:** the fog band brightens where it lies under the moon's screen position.

## Porting reference
`OctoberMoonBatsAnimation`, `OctoberScene`, `BatFlock` in `MonthAnimations.swift`, plus `MoonPhase`, `MoonPhaseAnimator` and `MoonPainter` in `MoonPhase.swift`. The phase math and the animator are already verified and should be reused, not rewritten.
