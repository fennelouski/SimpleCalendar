# February: Sweetheart Sky

> Soft rose-tinted clouds drift across a winter sky; some of them are unmistakably hearts. Glossy little hearts float upward like balloons, turning in the light, while a few late snowflakes fall.

## Product description

February is tender and a little playful. The sky has a blush-pink glow at the top. Large, billowy clouds drift slowly across, lit warmly from above with rosy shadows underneath, and every other cloud has gathered itself into a heart shape. In front of them, glossy candy-like hearts rise gently from the bottom of the screen, swaying and slowly flipping so you see their shiny front and darker back. A light dusting of snow still falls, reminding you it's winter.

The selected day sets how romantic the sky is: closer to Valentine's Day the clouds turn rosier and more hearts rise. On Valentine's Day itself, a shower of hearts bursts upward.

## Mood and palette

| Role | Color |
|---|---|
| Sky haze (top) | `#FFC7E0` at 20% → 0 by 50% height |
| Cloud lit / body / shadow | `#FFFAFC` / `#FFE6F0` / `#E6ADCC` |
| Heart front gradient | `#FF80A3` → `#EB2952` → `#9E052E` (top-left → bottom-right) |
| Heart back | `#BF244D` → `#800829` |
| Heart specular | `#FFFFFF` at 60% |
| Heart glow | `#FF6699` at 25% |
| Snow | `#FFFFFF` (40% density of January) |

Key light: high soft sun from the upper middle (0.5 W, −0.2 H), warmth 0.3.

## Scene composition (back to front)

| # | Layer | Element | Placement |
|---|---|---|---|
| 1 | Sky | Blush haze | top 50% |
| 2 | Far | Distant snow specks | full |
| 3 | Mid | 5 clouds (3 heart-shaped, 2 cumulus) | y 12%–60%, drifting horizontally in alternating directions |
| 4 | Mid | Snow crystals (sparse) | full |
| 5 | Mid/Near | Rising hearts (16) | full width, bottom to top |
| 6 | Post | Bloom on heart speculars | |

## Elements

### Heart clouds
- A lit cloud sprite (architecture 7.4) whose density mask is the parametric heart `x = 16 sin³t, y = 13 cos t − 5 cos 2t − 2 cos 3t − cos 4t`, dilated and broken up with fbm. The heart must stay recognizable while still reading as cloud: soft billowy edges, internal puffs, no hard outline.
- Width 170–250 pt. Drift time across the screen 100–160 s. Alternate clouds move in opposite directions. Vertical bob 24 pt over about 25 s.
- Lighting: silver-pink rim on the side facing the key light; rosy shadow `#E6ADCC` underneath.
- Every 40–70 s, one heart cloud slowly "breathes" (scale 1.0 → 1.04 → 1.0 over 4 s), a subtle heartbeat.

### Cumulus clouds
- Same system with an ellipsoid mask (port `CloudPainter.cumulusPuffs`), width × 1.25.

### Rising hearts
- SDF heart (`sdHeart`), size 16–46 pt. Depth follows size: small ones are farther, slower and paler.
- Rise speed 14–34 pt/s by depth. Sway ±34 pt (period about 10 s). Tilt ±0.25 rad.
- **3D flip:** x-scale = `cos(flipAngle)`, flip rate 0.5–1.2 rad/s. When `cos < 0`, show the back palette and hide the specular.
- Shading: linear gradient front, an inner rim light along the top lobes, a gloss ellipse at the upper-left lobe and a small catchlight dot that both go into the emissive target, plus a soft outer glow.
- Fade in over the bottom 10% of travel and out over the top 18%.

## Living behavior
- Wind: base (4, 0), gust 0.2, turbulence 0.1. Hearts and snow share it.

## Selection-driven behavior
| Signal | Effect | Transition |
|---|---|---|
| Distance in days from February 14, `d` | Romance `r = 1 − clamp(d / 14, 0, 1)`. Cloud palette shifts toward pink with `r` (lit `#FFFAFC`→`#FFF0F6`, body `#FFE6F0`→`#FFD1E3`), the share of heart-shaped clouds goes from 40% to 80%, rising heart count goes from 10 to 20 | 2.5 s discrete |

## Special days
- **Valentine's Day (February 14):** *heart shower*. Over 5 s about 60 extra hearts (sizes 10–30 pt) burst upward from the bottom third in a fan, faster (80–140 pt/s), flipping quickly, with a brief warm-pink bloom swell across the lower screen. They fade out by the time they reach 70% height.

## Theme adaptation
- **Light:** clouds would vanish on white, so raise shadow contrast (shadow `#D98FB5`) and add a soft pink outline glow (`#F2A6C8` at 25%). Hearts read well as they are. Snow uses January's light-theme recipe.
- **Dark:** clouds read as glowing pink masses. Keep cloud opacity at most 85% so the backdrop still tints them.

## Readability guardrails
- Clouds wider than 200 pt keep body saturation below 25% inside the content-safe region.
- At most 6 hearts larger than 30 pt are on screen at once.

## Metal implementation notes
- Cloud sprites: one quad each; the fragment shader evaluates heart or ellipse density plus fbm, and 4 light-direction density samples.
- Hearts: particle system, `kind` heart; the flip angle is integrated in the kernel.
- `sceneParams[0] = (romance, heartCloudShare, momentProgress, 0)`.

## Quality tiers
| Element | High | Medium | Low |
|---|---|---|---|
| Clouds | 5 (raymarched density detail) | 5 sprites | 4 sprites |
| Rising hearts (base) | 20 | 16 | 10 |
| Valentine burst | 60 | 40 | 24 |
| Snow | 40% of January's tier counts | same | same |

## Acceptance criteria
- [ ] Heart-shaped clouds are recognizable as hearts *and* as clouds.
- [ ] Hearts flip in 3D with distinct front and back shading and a glossy highlight.
- [ ] Romance level transitions discretely as the selection approaches February 14.
- [ ] Valentine's heart shower plays once per arrival.
- [ ] Looks deliberate and readable on both light and dark themes.

## Porting reference
`FebruaryHeartCloudsAnimation`, `FebruaryScene`, `CloudPainter.heartPuffs`, `HeartGeometry` in the Canvas code.
