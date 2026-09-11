# W02 Medieval Rebuild Design Brief

DESIGN_OBJECTIVE
- Rebuild Lanternfall's presentation into a premium medieval-fantasy 2.5D Android experience while preserving the authoritative 2D combat, spawn, save, and progression model.
- Replace final-use simplistic handmade SVG/procedural presentation assets with licensed production assets and real audio.
- Keep combat state legible at mobile scale under dense survivor-like enemy counts.

INFORMATION_ARCHITECTURE
- Gameplay authority remains in the existing 2D world and data systems.
- WorldPresentation3D is a visual projection layer: gameplay Vector2 X/Y maps to presentation Vector3 X/Z; presentation never becomes authoritative for combat or saves.
- CombatCamera remains the gameplay/camera source of truth; a future orthographic Camera3D follows the same focus.
- WorldHUD remains world-relative where appropriate. ScreenUI remains a CanvasLayer for status HUD, modal menus, level-up choices, pause, and mobile controls.

COMPONENT_SPEC
- WorldPresentation3D: orthographic 3D scene containing terrain, landmarks, props, foliage, obstacles, lighting, shadows, and visual-only combat representatives.
- AssetLibrary/W02: CC0 medieval geometry imported with a per-file provenance ledger; first accepted geometry is KayKit hex_grass.
- StatusHUD: opaque/high-contrast HP, XP, timer, level, boss/status information and active weapon readout.
- WeaponHUD: recognizable weapon icon/name plus cooldown/charge/state; the equipped weapon must also have a corresponding world-side visual/attack representation.
- ModalPanel: opaque backdrop, game dimming, input capture, readable hierarchy, and minimum mobile touch targets.
- LevelUpCards: mutually exclusive choice cards with title, icon, concise effect summary, rarity/state treatment, and unambiguous selected/disabled states.

STATE_SPEC
- NORMAL: clear player silhouette, readable terrain, low-noise HUD.
- ATTACK: anticipation/weapon cue, active strike/projectile/AOE/minion cue, impact confirmation.
- HIT: victim-side flash/stagger/impact cue without obscuring hazards.
- LOW_HEALTH: persistent but restrained danger treatment; not color-only.
- LEVEL_UP: gameplay input blocked, background dimmed, opaque cards, explicit focus/selection state.
- BOSS: boss identity/health becomes dominant secondary information while normal survival HUD remains readable.
- MENU_PAUSE: gameplay blocked; modal is opaque and visually separate from world.

RESPONSIVE_SPEC
- Support both landscape and portrait-safe layouts through anchors/containers rather than hard-coded pixel offsets.
- Preserve platform safe areas and prevent critical HUD overlap with gesture/navigation regions.
- Interactive touch targets target at least 48 dp-equivalent visual/interaction size where applicable.
- Text and icons must remain readable on phone-class displays without relying on zoom.

INTERACTION_SPEC
- Existing movement/combat input contracts remain authoritative.
- Camera smoothly follows gameplay focus while the field extends for many viewport lengths; UI remains screen-space.
- Menus, pause, and level-up surfaces capture input so touches do not leak to gameplay.
- Combat feedback uses short, composable cues: anticipation, trail/projectile/AOE, impact, death, reward, and boss emphasis.

ACCESSIBILITY_SPEC
- Critical state is never communicated by hue alone; combine icon, shape, text, motion, or value contrast.
- Maintain high foreground/background contrast for HUD and modal copy.
- Avoid persistent full-screen shake/flashes; use amplitude/duration limits and preserve gameplay readability.
- Keep information density bounded so enemy/projectile silhouettes remain distinguishable.

VISUAL_CONSTRAINTS
- Target look: stylized low-poly medieval fantasy with coherent scale, material language, depth, lighting, and readable silhouettes.
- Approved initial art source: KayKit Medieval Hexagon Pack 1.0, CC0. Every imported file must be recorded in the provenance ledger before runtime integration.
- Handmade SVGs and procedural primitives may exist only as migration scaffolding; they are not accepted as final representative art.
- Real geometry/depth/shadows must create the 2.5D field impression; avoid a flat top-down reskin.
- VFX are subordinate to causality and collision readability; no uncontrolled bloom, particles, or screen shake.

AC_MAPPING
- AC-01: production art source/license/provenance plus elimination of simplistic final SVG presentation.
- AC-02: large world, camera follow, many-screen traversal, terrain/props/landmarks, performance-aware projection.
- AC-03: weapon identity, attack causality, distinct projectile/trail/AOE/minion silhouettes, level-up choice readability.
- AC-04: opaque/high-contrast ScreenUI, dimming/input blocking, mobile legibility.
- AC-06: movement/attack/hit/death/level-up/reward/boss feedback hierarchy.
- AC-07/AC-08: design is provisional until new runtime screenshots and actual-play evidence validate the integrated result.

OPEN_QUESTIONS
- No blocking design question for W02/W03. Runtime evidence must determine final orthographic angle, world-to-3D scale, shadow budget, prop density, and mobile VFX budget before those values are frozen.
