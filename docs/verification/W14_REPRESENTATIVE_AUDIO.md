# W14 Representative Audio Verification

## Scope and acceptance mapping

W14 implements representative audio for the Twilight Shipyard runtime and maps to AC-13 (actual audiovisual review) while preserving the existing W03-W13 gameplay contracts. It does not claim full production audio coverage; W24 remains the full audio/polish milestone.

Representative identities: region bed, combat tension layer, Drowned Navigator boss layer, arc-lance combat strike, light-circuit activation, cross-phase warning, and salvage reward.

## Runtime integration contract

- `AudioDirector` is a project autoload and creates separate Music, SFX, and Warning buses.
- Music and SFX volume plus vibration enable state are independently controllable through the director API.
- Region/tension/boss music layers are crossfaded rather than restarted for every event.
- Eight SFX voices are bounded by priority/cooldown policy. A warning has higher priority and gain than combat spam and may replace a lower-priority voice.
- Existing W12 runtime signals drive combat, damage warning, circuit, phase, route failure, and reward cues.
- Encounter enemy count drives tension. Boss presence is read from the encounter pool without mutating combat state; this is a presentation-only W14 bridge.

## Provenance and generated review evidence

The sound source is original deterministic procedural synthesis at PCM16 mono / 32 kHz. `assets/runtime/w14/audio_manifest.json` inventories all seven identities and `assets/licenses/W14_ORIGINAL_AUDIO.md` records provenance.

CI generates:
- `representative-mix.wav`
- `representative-mix-low.wav` at -18 dB
- `warning-cue.wav`

The normal and low-volume mixes use the same runtime recipes and intentionally exercise region, combat, circuit, warning, boss, and reward transitions. Artifact existence and signal metrics are machine-verifiable; actual listening remains a separate human evidence requirement and must not be inferred from headless playback.

## Test contract preflight

The W14 branch must retain all 14 pre-existing fast-test suites and add only `representative_audio` as suite 15. The expected runner markers are `TEST_CONTRACT=w14-representative-audio-v1`, `SUITES=15`, and `RESULT=PASS`. Headless import must reject script compile/parse errors. CI must also retain the W13 render evidence step so W14 cannot silently regress the representative screen contract.

Before branch mutation the Actions candidate is valid only if the test runner, workflow assertions, audio manifest, content manifest, and exact pinned Godot identity agree. The W14 artifact name includes both workflow run id and run attempt to avoid rerun identity collisions.

## Remaining review boundary

A generated WAV and waveform metrics are not a listening PASS. The Result handoff must preserve human listening as pending until a real auditory review is available. That residual review does not authorize changing version, package id, signing lineage, network scope, or production content counts.
