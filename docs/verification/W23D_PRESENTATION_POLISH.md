# W23D Presentation Polish

Status: automated candidate verification only; human visual inspection remains pending.

## Objective

W23D closes the presentation-integration gap after W23A/B/C without changing gameplay, content schemas, package identity, versioning, or signing. Combat danger information remains above decoration, the W23 loadout HUD avoids the established representative HUD, story art stays inside the screen, and transition motion is presentation-only.

## Readability matrix

- 1280x720: baseline 16:9 review.
- 1920x1080: desktop/full-HD 16:9 review.
- 2340x1080: representative Android 19.5:9 review.
- 2640x1080: wide 22:9 boundary review.

The integration smoke checks the representative player/Ark/pause/weapon/notice rectangles against the W23 loadout panel and checks W23 story/loadout rectangles against viewport bounds and each other. The render capture produces combat and hub/story PNGs for every matrix entry.

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
- `W23D_PRESENTATION_POLISH=PASS`
- `W23D_CAPTURE=PASS`
- 4 combat captures + 4 story captures at the matrix resolutions.

The existing W23A/B and W23C workflows remain authoritative for production-art count, provenance, runtime mapping, and their established review sheets. W23D does not replace or relax those contracts.

## Human-review boundary

Automated geometry and screenshots do not prove final art direction, subjective hierarchy, animation feel, color readability on real panels, or device-specific touch/OS chrome behavior. Those items remain `PENDING` until a human visual review or later final verification explicitly resolves them.
