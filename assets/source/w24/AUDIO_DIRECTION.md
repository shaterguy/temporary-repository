# W24 Production Audio Direction

W24 expands the retained W14/W20 audio language into full current-game coverage without replacing gameplay authority or changing save/version/signing identity.

## Shared language

- All five region families use a shared Lanternfall engine/pulse vocabulary, but each receives a distinct low register, accent register, rhythmic pulse, overtone ratio and deterministic texture seed.
- Every region has a base bed and a tension layer. The runtime director crossfades the tension layer from live encounter density rather than swapping hard-coded tracks.
- All ten bosses receive a dedicated looping music profile derived from the same project-original pitch identity already used by their W20 event cue profile. The fifty retained W20 intro/opening/pressure/finale/break cues remain the event layer.
- All eighteen curated weapons receive their own procedural attack identity. Delivery geometry supplies the broad timbre and the exact weapon identity adds pitch, envelope, transform color and transient variation.
- UI open/confirm/back/focus/reject/reward cues use the same harmonic vocabulary and are integrated through the actual main-shell interaction path. Reject remains a Warning-bus cue rather than a cosmetic click.

## Mix and concurrency

- Runtime synthesis stays deterministic PCM16 mono at 32 kHz.
- Music, SFX and Warning remain separate buses. The user-facing music and SFX controls remain independent from vibration.
- The SFX pool remains bounded at eight simultaneous voices. Saturation may steal only the oldest voice with lower priority; equal/higher-priority voices are not displaced.
- At low SFX settings the Warning bus follows a zero-preserving salience curve: zero still means mute, while non-zero low settings keep warnings above ordinary combat cues.
- Region and boss music streams change only through AudioDirector. Gameplay models continue to own health, damage, phase, route and boss state.

## Review contract

CI renders 44 WAV files from the same runtime synthesis code: five normal region mixes, five -18 dB region mixes with warnings held 6 dB above the low mix, ten boss tracks, eighteen weapon tracks and six UI tracks. Automated waveform metrics verify that the files are valid/non-silent; they do not certify musical quality, masking, fatigue or subjective clarity. Human listening remains required before AC-13 can become a final PASS.

No downloaded sample, stock music, copied melody, external sound library or model-generated audio binary is part of W24.
