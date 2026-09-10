# W23D Presentation Polish

Status: presentation-only polish candidate; automated geometry, localization, tutorial-scope, render-capture, and human screenshot review are required before final visual PASS.

## Objective

W23D closes the presentation-integration gap after W23A/B/C without changing gameplay, content schemas, package identity, versioning, permissions, signing, save behavior, or balance. The player-facing shell removes milestone/development copy, expedition guidance is touch-first, character-role tutorial copy is hub-only, representative combat telemetry uses localized labels instead of route/status/module/phase IDs, and combat HUD panels stay out of the lower touch-control band.

## Readability matrix

- 1280x720: baseline 16:9 review.
- 1920x1080: desktop/full-HD 16:9 review.
- 2340x1080: representative Android 19.5:9 review.
- 2640x1080: wide 22:9 boundary review.

The integration smoke checks the representative player/Ark/pause/combat/guidance rectangles against the W23 loadout panel, keeps all combat presentation above the lower 45% touch-control band, and checks W23 story/loadout rectangles against viewport bounds and each other. The render capture produces combat and hub/story PNGs for every matrix entry with representative weapon and relic labels populated.

## Player-facing copy contract

- Main shell startup copy is product-facing and contains no foundation/build-in-progress wording.
- Known milestone prefixes such as W12/W16/W17/W18/W22/W26 are stripped from visible status copy at the final shell layer.
- Known route, region, circuit-module, and phase IDs are mapped to player-facing Korean labels before display.
- Representative HUD headings and telemetry are Korean player-facing labels; raw route/status/module/phase IDs are not rendered.
- Weapon and relic HUD text comes from the canonical weapon/relic catalog labels rather than raw IDs.
- Story footer displays the canonical story-event title rather than the event ID.

## Tutorial and touch contract

- Character-role tactical tutorial is visible in HUB only and carries no W16 prefix.
- First-expedition movement and phase guidance names the mobile left pad, circular dodge button, and diamond phase button instead of leading with WASD/Space/Q.
- Settlement guidance describes the action outcome without exposing desktop debug-key copy.
- During EXPEDITION, representative combat/guidance panels and the weapon/relic panel remain above the lower 45% touch-control band for every readability-matrix viewport.
- The weapon/relic panel uses the upper-right expedition rail below the pause panel.

## Motion contract

- Story reveal duration: 0.18 seconds.
- Maximum story-card reveal slide: 12 px.
- Loadout border motion: subtle alpha pulse only.
- Gameplay hitboxes, enemy positions, player position, Ark position, telegraph timing, and combat state are not modified by W23D presentation motion.

## Automated evidence

Workflow: `.github/workflows/w23d-presentation-polish-ci.yml`

Expected assertions:

- `W23D_HUD_COLLISION=PASS`
- `W23D_STORY_CARD_BOUNDS=PASS`
- `W23D_TOUCH_CLEARANCE=PASS`
- `W23D_LOCALIZATION=PASS`
- `W23D_TUTORIAL_SCOPE=PASS`
- `W23D_PRESENTATION_POLISH=PASS`
- `W23D_CAPTURE=PASS`
- 4 combat captures + 4 story captures at the matrix resolutions.

The existing W23A/B and W23C workflows remain authoritative for production-art count, provenance, runtime mapping, and their established review sheets. W23D does not replace or relax those contracts.

## Human-review boundary

Automated geometry and screenshot generation do not by themselves prove subjective hierarchy, animation feel, color readability on real panels, or device-specific touch/OS chrome behavior. The generated W23D captures must be inspected after the new candidate run. Those subjective items remain `PENDING` until that inspection or a later final verification explicitly resolves them.
