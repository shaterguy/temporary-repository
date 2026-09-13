# R06 Medieval Mobile UI Readability Contract

Task: `SR-20260911-123932-QFFQM4`
Branch: `work/sr-20260911-medieval-rebuild`
Parent checkpoint: W05 combat visual rebuild.

## Scope

This checkpoint advances R03 AC-04 only. It does not change save/campaign semantics, gameplay rules, package identity, signing, permissions, or network behavior.

## Player-facing contract

- Slot and hub menus use a full-screen dim layer plus an effectively opaque medieval panel so world rendering cannot compete with menu text.
- Menu content remains inside the existing Android safe-area boundary.
- Primary choice targets are at least 72 px high, with at least 22 px button text and 20 px status text at the 1280×720 baseline.
- Normal, focus, hover, and pressed states are visibly distinct. A focus border remains readable for non-touch navigation.
- Slot choices state the action (`새 여정 시작` or `계속하기`) instead of exposing only a slot number.
- Hub choices expose destination and route identity instead of generic `선택 1/2` labels.
- Menu dim/card/content are removed during active expedition so the world and combat HUD regain visual priority.
- The dim layer stops pointer/touch propagation outside the active buttons. Existing gameplay touch input remains expedition-only.
- Korean UI text must use the pinned Noto Sans KR runtime asset materialized by `tools/fetch_noto_sans_kr.sh`; a host-only system fallback is not acceptance evidence.

## Fresh evidence policy

Prior pre-rebuild readability PASS evidence is stale by user requirement and is not used as acceptance evidence for this checkpoint.

The W06 workflow produces fresh rendered slot/hub images at 1280×720 and 2340×1080 from the exact candidate commit. Automated structural checks verify opacity, touch target size, typography floor, input blocking, state changes, and content-bearing labels. The workflow also verifies the exact shipped font resource and renders multiple distinct Hangul glyphs into a dedicated pixel probe; identical rendered fingerprints are treated as tofu/missing-glyph failure. Render generation is evidence for review, not a claim of final human visual acceptance.

The pinned font source, SHA-256 and OFL 1.1 redistribution record are stored under `assets/licenses/`. W06, W25 and the production Android export materialize the same pinned font before Godot import/export so verification and the shipped APK use the same font bytes.

## Non-regression

- R03 NR-01: save/campaign data structures and progression flow remain unchanged.
- R03 NR-02: package/signing lineage and security boundary remain unchanged.
- Existing W04 large-world/camera regression and W05 combat-visual regression remain valid and must still load the revised main scene.
