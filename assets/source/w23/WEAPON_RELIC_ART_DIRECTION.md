# W23B production weapon and relic art direction

Milestone: W23 art finalization / weapon-relic production pass
Baseline: W13 visual grammar + W17 causal weapon/relic contracts

## Production intent

W23B closes the per-item visual-asset gap for all 18 curated weapons and all 48 relics without changing W17 combat recipes, energy budgets, causal-chain limits, relic effects, save data, unlock semantics, or balance coefficients. The visual language retains the W13/W23A dark-navy contour, cold dusk materials, cyan/blue system light and one warm lantern focal point.

### Weapon grammar

Every curated weapon receives a distinct 128×128 editable SVG. Delivery form is the primary silhouette: lance, bolt, halo, chain, pulse, or fan. Trigger identity is expressed as a secondary frame or motion cue, while transform identity is a tertiary glyph or material accent. This makes the existing trigger → delivery → transform contract visible without inventing new gameplay meaning.

- dodge_release uses swept wake rails; steady_fire uses a stable lantern core.
- circuit_birth uses closed circuit rails; phase_entry uses split-phase wedges.
- ark_pressure uses hull/shield framing; hit_confirmed uses locked confirmation marks.
- circuit_split, shadow_fracture, ark_resonance, ember_mark, ricochet_once, material_anchor, snare_resonance and phase_afterglow each have a consistent overlay motif reused only where that existing transform is present.

### Relic grammar

All 48 relics are the exact W17 8-family × 6-variant set. Family identity controls the outer silhouette and cold accent; effect variant controls the inner glyph:

- wake / shadow / circuit / ark / phase / chain / mark / navigation each have a stable family frame.
- edge = blade slash, nail = driven spike, fork = branching prongs, ward = protected ring, lens = optic aperture, pulse = expanding pulse.

The family frame remains recognizable at 36×36 HUD size and the effect glyph remains readable at 48×48 choice-card size. Color is redundant with geometry so the set does not rely on hue alone.

## Runtime mapping and review

`game/presentation/w23_weapon_relic_art_catalog.gd` is the presentation authority that maps the existing W17 IDs to these SVGs. The W17 choice model adds `art_path` as presentation metadata only. `W23WeaponRelicHud` renders the selected weapon and equipped relics in the actual main scene without mutating combat state.

A dedicated 1280×720 review sheet renders all 18 weapons and all 48 relics. Automated import/render success is evidence that the assets are valid runtime resources; human visual acceptance and weapon/relic balance acceptance remain separate gates.

## Authorship and edit history

All 66 W23B SVG files were authored directly for LANTERNFALL in this repository on 2026-09-10. No stock image, third-party icon pack, copied game asset, external font, or separately licensed texture is embedded. Runtime SVGs are also the editable source.

- W23B-1: mapped exact W17 weapon/relic IDs before drawing.
- W23B-2: established delivery/family silhouette grammar and transform/effect glyph grammar.
- W23B-3: integrated art paths into actual choice-card data and live selected-build HUD.
- W23B-4: added exact-count, no-placeholder, import, runtime-mapping and 1280×720 review-capture checks.

This pass does not claim W23 complete. Enemy breadth, choice-event illustration, animation polish, full-screen readability review and human acceptance remain later W23 packets.