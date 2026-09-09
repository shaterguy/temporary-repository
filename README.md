# LANTERNFALL: 잔광의 항로

Android 2D action-survival game project. The design target is a premium, replayable survivor-style game built around a moving lantern ark and seven connected systems: battlefield routes, movement-drawn light circuits, causal modular weapons, tactical echoes from prior expeditions, disclosed enemy doctrines, a persistent world network, and dual-phase battlefields.

## Product baseline

- Engine baseline: Godot 4.7.2 Standard, typed GDScript, GL Compatibility.
- Target: Android 10 / API 29+; arm64 is the primary device ABI. x86_64 is a CI/emulator validation variant.
- Production application ID plan: `com.shaterguy.lanternfall`.
- Development application ID plan: `com.shaterguy.lanternfall.dev`.
- Offline single-player, landscape, Korean-first, no ads or in-app purchases in the current product baseline.

## Signing invariant

The first user-installable APK must use a durable, non-debug signing lineage. Debug signing, per-build random keys, and signing material from unrelated apps are prohibited fallbacks. Private keys and passwords must never be committed to this public repository or emitted in CI logs/artifacts. Source development may continue while protected signing-secret injection remains unavailable, but no user-installable APK is to be represented as deliverable-ready until the signing gate is satisfied and verified.

## Development flow

`main` is the stable repository baseline. Active implementation begins on `v1.0.0-dev1` and later development/RC branches. Tests, CI, Android export, signing, and release provenance are introduced as traced implementation work; a passing scaffold is not equivalent to game completion or a quality claim.

The canonical product design and acceptance criteria are maintained in the Vibe Coding project records for SelfRun task `SR-20260909-150106-PPO12Y`.
