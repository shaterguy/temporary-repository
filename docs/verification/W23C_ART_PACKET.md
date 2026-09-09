# W23C enemy/event/region art packet

Task: `SR-20260909-150106-PPO12Y`
Baseline branch/SHA: `v1.0.0-dev1` / `b253f0ec7d51ba656b1af7e0820f85023b06f854`
Scope: W23C only — 30 tracked general-enemy visual roles, 40 choice-event illustrations, five production-region visual mappings, runtime presentation bindings, provenance and focused automated review evidence.

## Acceptance-criteria mapping

- AC-12: the W23C manifest tracks 30 enemy visual roles, 40 W21 event illustrations and all five existing region environments with zero placeholders. W18/W19 mechanical `behavior_id` values and all forty W21 `event_id` values are the canonical mapping keys. `implemented_content` remains zero because human/balance/audio/final gates have not passed.
- AC-13: the actual W23 main shell uses the W23 encounter renderer and mounts the non-interactive story-event card. Focused CI imports the SVG atlases, validates runtime mapping and renders separate 1280×720 enemy/region and choice-event review sheets. Automated capture is not human visual acceptance.
- AC-16: new atlas artwork is project-original SVG with a dedicated provenance record. Existing W13/W18/W19 environment/enemy assets retain their original provenance. Signing lineage and final APK identity are unchanged.

## Non-regression contract

- W18/W19 behavior parameters, health/damage, spawn timing, route, phase, circuit and boss mechanics are unchanged.
- W21 event text, option order, story flags, persistent consequences, ending bias and save/world schema are unchanged.
- `lanternfall-world-v2`, `lanternfall-save-payload-v1`, package IDs, versionName/versionCode and signing configuration are unchanged.
- W23A character and W23B weapon/relic assets and runtime bindings remain intact.
- Restored enemies that predate the presentation map use a deterministic regional visual fallback; no save payload field is added solely for cosmetics.

## Focused verification

`w23c-world-event-art-ci` must validate exact 30/40/5 manifest counts, zero placeholders, 24 authored W18/W19 enemy atlas frames, 40 event atlas frames, Godot SVG import, one-to-one canonical ID coverage, exact live `behavior_id` binding for newly spawned regional enemies, main-scene event-HUD mounting, and both 1280×720 review captures. Foundation CI and the existing W23A/B workflow remain valid regression gates because this packet preserves their asserted counts and contracts.
