# W23A production character art direction

Milestone: W23 art finalization / character production pass
Baseline: W13 representative visual grammar

## Production intent

W23A closes the character-specific visual gap left by W16 without changing character mechanics, unlock rules, save schema, or combat balance. The six playable identities share the W13 dark-navy contour language, cold dusk materials, and one warm allied lantern focal point, but each role receives a deliberately different silhouette that remains distinguishable at the 48x60 combat draw size.

- Aurora / circuit architect: upward split coat, lateral circuit rails, cyan circuit traces and a compact lantern core.
- Cinder / close escort: broad plated shoulders and low center-of-mass escort silhouette with ember-orange accents.
- Rivet / Ark engineer: asymmetric copper tool rig and backpack mass with green service-light accents.
- Veil / phase scout: narrow mask, split cloak and translucent phase wedges that avoid enlarging the collision/readability footprint.
- Mneme / echo recorder: memory-reel halo and trailing ribbon lines; the body remains compact so echo decoration cannot be mistaken for a hitbox.
- Vesper / ranged observer: tall optic mast and narrow observation profile with green/cyan lens accents.

## Combat readability

The character image is drawn inside a 48x60 centered rect. Health and role-state rings stay outside the sprite, so a richer silhouette does not cover status information. Existing danger telegraphs remain downstream of their gameplay systems and are not replaced by decorative character effects. The review showcase renders each identity at presentation scale and at the exact combat scale side by side in a 1280x720 capture.

## Authorship and edit history

All six W23A SVG files are project-original vector artwork authored directly for LANTERNFALL in this repository on 2026-09-10. No stock image, third-party sprite, copied game asset, or external art file is embedded. Runtime SVGs are the editable vector source used by Godot.

- W23A-1: preserved W13 contour, material and warm/cold lighting grammar.
- W23A-2: differentiated the six silhouettes around their actual W16 roles.
- W23A-3: constrained the runtime draw size to 48x60 and moved health/role indicators outside the artwork.
- W23A-4: added a 1280x720 review scene/capture contract and focused CI import/runtime checks.

This pass does not claim that W23 is complete. Weapon/relic/event/enemy breadth, animation polish, full-screen readability review and human visual acceptance remain later W23 work packets.
