# W07 External Audio Replacement Verification

## Objective
Replace the active runtime procedural sine/noise audio path with redistributable external production audio while preserving existing gameplay cue identifiers and event routing.

## Runtime sources
All W07 runtime files are CC0 1.0 Universal and are tracked in `assets/licenses/W07_CC0_AUDIO.md` with upstream URLs and SHA-256 values.

- RandomMind, `Medieval: Exploration`: region/exploration music.
- RandomMind, `Medieval: Battle`: tension and boss music.
- TinyWorlds, `Forest Ambience`: looping ambience bed.
- Kenney, `50 RPG sound effects`: 18 distinct weapon sounds plus dedicated hit/death sounds.
- Kenney, `Interface Sounds`: six UI sounds.

The imported runtime set contains 29 media files and `assets/third_party/audio/w07/SHA256SUMS.txt` records each exact shipped file.

## Runtime replacement contract
`game/audio/external_audio_assets.gd` maps the existing semantic cue space to external files. `game/audio/audio_director.gd` loads only those mapped `AudioStream` resources and has no procedural render fallback.

Coverage requirements:

1. Five production region profiles × bed/tension layers resolve to external music.
2. Ten boss music identifiers resolve to external battle music.
3. Eighteen curated weapon identifiers resolve one-to-one to 18 distinct OGG files.
4. All 50 boss presentation event cues resolve to external one-shot files.
5. Six production UI actions resolve to six external UI files.
6. Legacy combat/circuit/warning/reward cues remain functional through external mappings.
7. Hit and death feedback use dedicated external files; death is decided from the post-damage encounter snapshot.
8. Forest ambience is mounted as a looping low-level music-bus layer.
9. The active audio director does not reference `ProductionAudio`, `AudioLibrary`, or `render_cue(`.
10. One-shot gain is capped at -6 dB before bus gain to reduce harsh playback on mobile speakers.

## Automated verification
The authoritative W07 workflow is `.github/workflows/w07-external-audio-ci.yml` using the pinned Godot toolchain in `toolchain.lock`.

The workflow verifies source/license provenance, 29 media files, 18 distinct weapon files, file hashes, Godot import, resource decoding, semantic cue coverage, absence of procedural runtime calls, and produces a listening bundle containing the exact shipped audio plus provenance documents.

Expected markers:

- `TEST_CONTRACT=w07-external-audio-v1`
- `W07_EXTERNAL_MEDIA=29`
- `W07_WEAPON_SFX_UNIQUE=18`
- `W07_BOSS_EVENT_CUES=50`
- `W07_PROCEDURAL_RUNTIME=DISABLED`
- `W07_LISTENING_REVIEW=REQUIRED`
- `RESULT=PASS`

## Human listening gate
Automated loading, hashes, routing, and gain policy do not substitute for perceptual listening. `W07_LISTENING_REVIEW=REQUIRED` remains intentionally open until the uploaded listening bundle is auditioned on representative mobile playback and the following are confirmed:

- medieval music and ambience are tonally suitable and loop acceptably;
- all 18 weapon cues are audibly distinguishable in gameplay context;
- hit/death/UI cues are recognizable and not distractingly mismatched;
- no cue is painfully loud, clipped, or excessively sharp on a phone speaker;
- transitions between exploration, tension, and boss layers are acceptable.

Until that review is performed, AC-05 is implemented and automation-verified but perceptual verification remains pending.
