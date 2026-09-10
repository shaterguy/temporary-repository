# W23D Presentation Polish

Status: static presentation visual review PASS for candidate `8a7a6808eef099477ecd3a740489aaaa29c4ef7c`; automated geometry/localization/tutorial-scope/render-capture and direct inspection of all 8 generated screenshots are complete. Android device-specific touch/OS-chrome behavior and non-static animation feel remain outside this W23D static-review PASS and are tracked under R04/final verification.

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

Verified candidate: `8a7a6808eef099477ecd3a740489aaaa29c4ef7c`

- Run: `34441740065`
- Job: `102758023943`
- Artifact: `10138188610` (`w23d-presentation-review-34441740065-1`)
- Result: all workflow steps succeeded on the verified candidate.
- Evidence set: 4 combat captures + 4 hub/story captures covering the full readability matrix.

Expected assertions:

- `W23D_HUD_COLLISION=PASS`
- `W23D_STORY_CARD_BOUNDS=PASS`
- `W23D_TOUCH_CLEARANCE=PASS`
- `W23D_LOCALIZATION=PASS`
- `W23D_KOREAN_GLYPHS=PASS`
- `W23D_TUTORIAL_SCOPE=PASS`
- `W23D_PRESENTATION_POLISH=PASS`
- `W23D_CAPTURE=PASS`
- 4 combat captures + 4 story captures at the matrix resolutions.

The existing W23A/B and W23C workflows remain authoritative for production-art count, provenance, runtime mapping, and their established review sheets. W23D does not replace or relax those contracts.

## Direct screenshot review

All 8 exact screenshots from artifact `10138188610` were independently inspected after the final Korean-glyph fix. The reviewed captures show rendered Korean glyphs, no obvious clipping, no exposed raw route/status/module/phase IDs or W-number milestone labels, and no obvious overlap between the reviewed combat HUD and the lower touch-control area at the captured matrix sizes.

Static screenshot review therefore closes the W23D visual-review requirement for candidate `8a7a6808eef099477ecd3a740489aaaa29c4ef7c`. It does not claim Android device behavior, OS-chrome/safe-area behavior outside the captured contract, live animation feel, audio quality, or final whole-game art direction.

## Human-review boundary

The direct screenshot review is PASS for the captured static presentation scope above. Android device-specific touch/OS-chrome behavior remains pending R04. Live animation feel, audio listening/mix quality, and broader whole-game subjective quality remain separate final-verification scopes and are not inferred from this W23D screenshot PASS.
