# W13 representative art verification record

Task: `SR-20260909-150106-PPO12Y`
Baseline: `043ab47eea06bb288d02ee2c4160d75e87d79c2a`
Branch: `v1.0.0-dev1`
Mapped acceptance criteria: AC-12, AC-13, AC-14, AC-16.

## Scope

W13 establishes a representative production visual language without changing W04∼W12 gameplay/save semantics. The runtime set contains one Twilight Shipyard environment, two player visual identities, eight enemy visual identities, one Ark, one boss, one HUD chrome set and one VFX set. All fifteen runtime assets are original editable SVG vectors tracked by `assets/runtime/w13/art_manifest.json`, the W13 art-direction/edit record and the project-original provenance record.

The eight enemy visuals are presentation variants over the already implemented W05 behavior families. They therefore do not increment `implemented_content.enemy_behaviors`; visual variety is not misrepresented as eight completed gameplay behaviors. The same rule applies to player/boss/region production counts until their gameplay/content contracts are complete.

## Runtime integration

`game/ui/main_shell.tscn` mounts the Twilight Shipyard behind the existing runtime and mounts a separate representative art layer plus combat HUD above the W04∼W12 model nodes. The presentation layer reads existing runtime state, paints player/Ark/enemy visual identities, re-renders active circuits and danger telegraphs above decorative art, and animates idle/engine/enemy sway plus weapon/phase burst VFX. Low-VFX mode suppresses decorative burst VFX only; danger telegraphs remain rendered.

The legacy foundation text stays visible in slot/hub modes. During an expedition the HUD hides that foundation block and mirrors its field-log status into the combat HUD, preserving operational feedback rather than dropping it.

## Automated evidence contract

`w13-representative-art-v1` retains all thirteen W04∼W12 fast-test suites and adds a fourteenth representative-art suite. The new suite validates exact asset counts/kinds, non-placeholder state, unique SVG payloads, authored path+gradient geometry, Texture2D importability, catalog mapping and main-shell/showcase scene mounting.

CI additionally launches Godot under Xvfb with OpenGL compatibility rendering, renders `game/presentation/w13_showcase.tscn` at exactly 1280×720, saves a PNG, verifies the render process and uploads the PNG using an attempt-specific artifact identity. This creates actual render evidence rather than treating headless import success as visual evidence.

## Visual acceptance boundary

Automated PNG production is necessary but not sufficient for AC-13 visual PASS. A later verification step must inspect the actual rendered PNG for silhouette separation, warm/cold hierarchy, HUD readability, telegraph precedence, clipping/overlap and obvious visual defects. Audio is not part of W13 and remains a later production milestone. Therefore W13 may advance art implementation while AC-13 remains PARTIAL until rendered output is actually inspected.
