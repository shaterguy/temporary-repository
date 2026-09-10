# W25 Android input, accessibility, lifecycle and save-failure hardening

Task: `SR-20260909-150106-PPO12Y`
Continuation: `SR-20260910-121926-5B5U4L`
Branch: `v1.0.0-dev1`
Baseline before W25: `59403b5a2673728b3ab8570ac065605f2763ed41`
R04 repair baseline: `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT=VALID`
`ACTION_PREFLIGHT=VALID`
`PREVENTION_RULES=PR-001,PR-002,PR-007`

## Scope

W25 is a bounded Android/mobile hardening slice. It adds runtime touch controls without replacing the already verified W24 shell entry point. Version identity, package identity, signing lineage, save schema and campaign settlement semantics are unchanged.

Implemented contract:

- independent pointer IDs for movement, dodge and phase input; a second movement pointer cannot steal the active stick;
- fixed or floating virtual stick, left/right-handed inversion, bounded control scale and opacity, haptics opt-out, reduced-flash and reduced-motion preference flags;
- circular dodge and diamond phase controls so the two primary actions are not distinguished by color alone;
- safe-area-aware control layout checked at 1280x720, 1600x720, 1760x720 and 1024x768 logical viewports;
- application pause/focus loss and viewport changes cancel transient touch ownership before stale pointers can remain latched;
- the expedition overlay forwards only transient movement/dodge/phase state into the existing W12+ combat bridge; auto attack and prior gameplay semantics remain unchanged;
- explicit pre-expedition touch buttons expose save-slot choices 1-3 and hub/story choices 1-2, forwarding to the existing `select_save_slot()` and polymorphic `select_world_choice()` methods instead of duplicating campaign logic;
- the pre-expedition touch row is visible only in `SLOT_SELECT` and `HUB`, hides choice 3 in the two-option hub/event state, and is hidden in `EXPEDITION` so it cannot overlap the W25 movement/action overlay;
- existing SaveStore durability is exercised against stale temporary files, interrupted primary-to-backup promotion, corrupt-primary recovery, an invalid storage parent and double corruption.

## R04 continuation defect and repair contract

R04 API36 run `34455506910` reused the exact W28 production APK, verified package/version/signature, installed successfully and booted an Android 16 Google APIs x86_64 runtime exposing `arm64-v8a` through `libndk_translation.so`. The run then failed at the first user-flow transition: injecting the keyboard `1` key did not produce the expected `HUB/new_game` save state.

Independent source review showed a product-level Android usability gap rather than a save-store defect: the W24 final shell inherits the original `main_shell.gd` behavior where save-slot selection and hub departure are handled only by `InputEventKey`; `mobile_input_overlay.gd` accepts touch only after `shell_mode == EXPEDITION`; and `main_shell.tscn` contained no pre-expedition Button nodes. A phone user therefore had no visible touch path from first launch into gameplay.

The repair keeps all existing campaign methods authoritative and adds a presentation/input adapter only. Standard Godot `Button` controls provide the actual touch/click target. Their pressed signals call the existing slot/world-choice methods, so keyboard and touch converge on the same save, campaign, checkpoint and failure handling.

The updated W25 smoke instantiates the actual `main_shell.tscn`, uses a unique temporary save root, emits the mounted Button pressed signals, and requires the real shell to transition `SLOT_SELECT -> HUB -> EXPEDITION`. It also requires the three slot buttons to become two hub buttons and the touch row to disappear after expedition entry before the existing multitouch/accessibility/lifecycle assertions continue.

## TEST_CONTRACT_PREFLIGHT

Status: `VALID`.

Authority sources are the current W24 shell inheritance chain, `game/ui/main_shell.gd`, `game/ui/main_shell.tscn`, `game/ui/mobile_input_overlay.gd`, `platform/android/safe_area.gd`, `game/core/save_store.gd`, existing SaveStore unit coverage and R04 run-17 evidence. Existing pointer, accessibility, lifecycle and save-recovery tests remain valid. The new pre-expedition test asserts actual scene controls and state transitions rather than accepting keyboard injection as a proxy for Android touch usability.

Expected W25 smoke markers:

- `W25_LAYOUT_MATRIX=1280x720,1600x720,1760x720,1024x768`
- `W25_PRE_EXPEDITION_TOUCH_NAV=PASS`
- `W25_MULTITOUCH=PASS`
- `W25_ACCESSIBILITY=PASS`
- `W25_LIFECYCLE_INPUT_RESET=PASS`
- `W25_SAVE_RECOVERY=PASS`
- `W25_ANDROID_HARDENING=PASS`

The headless smoke does not replace the later R04 production-APK Android runtime test. Physical-device cutout/gesture-navigation feel, low-storage behavior, thermal/performance and haptics remain post-delivery/device-specific gates.

## ACTION_PREFLIGHT

Status: `VALID`.

- authoritative repair baseline: `eb4b542275f13929334d72cc4e3eba492bb8ef9c` on `v1.0.0-dev1`;
- intended mutation: new pre-expedition touch adapter + scene Button mount + affected W25 integration/static contract + this document;
- unchanged identity: `versionName=1.0.0-dev1`, `versionCode=1`, PROD package `com.shaterguy.lanternfall`, DEV suffix `.dev`;
- unchanged persistence identity: `lanternfall-world-v2`, `lanternfall-save-payload-v1`;
- no new network access, account system, broad storage permission, analytics, advertising, payment, Android permission or signing material;
- the R04 failure evidence is reused; no duplicate reproduction run is created merely for the BUILDER role transition;
- CI uses the repository-pinned Godot version/digest and a pinned checkout action; the candidate changes real product behavior and contains no no-op trigger commit.

Prevention compliance:

- PR-001: PASS. Read-only R04 artifact/log/source evidence identified the product touch gap before mutation; the new run is required to verify the actual fix, not to probe tool capability.
- PR-002: PASS. All candidate commits contain functional or verification-contract changes; no empty/no-op trigger commit is used.
- PR-007: PASS. The W25 canonical validation path is updated in the same change so the new Android-entry requirement cannot be omitted from the blocking W25 smoke.

## Residual risk

The fix closes the source-confirmed absence of a phone-touch path for slot and hub choices, but final acceptance still requires rebuilding the production APK with the same durable signing lineage and rerunning R04 on that exact artifact. API36 SwiftShader rendering also remains a separate environment/runtime observation until the post-fix R04 run determines whether it blocks visible Android presentation.
