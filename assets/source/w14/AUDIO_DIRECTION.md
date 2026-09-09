# W14 Representative Audio Direction

LANTERNFALL W14 defines an original procedural audio identity for the Twilight Shipyard vertical slice.

- Region: low lantern-engine drone, salt-metal bell motif, restrained texture.
- Combat: short arc-lance sweep with metallic transient; repeated events are voice-limited and cooldown-gated.
- Boss: Drowned Navigator layer shares the region pitch family but adds undertow pulse and horn-like tension.
- Circuit: rising four-step harmonic bloom that reads as activation rather than a UI beep.
- Warning: two-part high-priority pulse with a low anchor so it remains distinguishable from weapon noise.
- Reward: four-note release figure that resolves the warning/tension language.

Runtime playback is generated as deterministic 16-bit mono PCM at 32 kHz through AudioStreamWAV. Music, effects, and warning buses are separated. The audio director owns voice priority, cooldown, layer crossfades, and user-facing music/effects/vibration settings; gameplay models remain authoritative for state and damage.

The CI review artifact renders the same recipes into a normal-level mix, an -18 dB low-volume mix, and a standalone warning WAV. These files are evidence for listening review, not proof that a human has listened to them.

No external samples, model-generated audio files, or third-party music are used in W14. Full-game music/SFX coverage and mastering remain W24 work.