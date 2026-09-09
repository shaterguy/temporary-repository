# W20 boss presentation checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`

This checkpoint extends the already-integrated W20 ten-boss mechanics with production-oriented audiovisual identities. It does not claim final human art, listening, fun, balance, Android-device, signing, or release acceptance.

## Acceptance contract

- AC-W20P-01: all ten `boss_catalog.gd` boss IDs resolve one-to-one to unique non-placeholder project-authored SVG identities and restrained runtime motion treatment.
- AC-W20P-02: all ten boss audio identities resolve the exact five mechanical presentation cues (intro/opening/pressure/finale/break), for fifty unique cues total, through deterministic PCM16 synthesis.
- AC-W20P-03: `RegionSwarmEncounter` emits presentation cues from authoritative boss events and draws boss art below W20 danger telegraphs; `AudioDirector` binds capability-based regional encounters and resolves W20 cues without becoming combat authority.
- AC-W20P-04: runtime manifest, source record, and project-original provenance cover the complete W20 audiovisual set; the focused remote smoke checks unique imports, cue ownership, representative non-silence, live signal emission, retained phase gates, and reward-once behavior.
- AC-W20P-05: remote CI produces a 1280×720 ten-boss contact sheet, a deterministic fifty-cue boss review WAV, and a machine-readable parameter/audio metrics report using the exact candidate SHA. These are review inputs, not automatic human-quality approval.

## Non-regression contract

- NR-W20P-01: `implemented_content.bosses` stays `0` until human visual readability, listening/mix, and boss-balance gates pass.
- NR-W20P-02: W18/W19 region mechanics and W21-owned final five-region campaign/save topology are unchanged.
- NR-W20P-03: danger telegraphs remain drawn after decorative boss art and therefore retain information priority.
- REL-W20P-01: `1.0.0-dev1`, versionCode `1`, production package `com.shaterguy.lanternfall`, development package `com.shaterguy.lanternfall.dev`, and signing lineage are unchanged.
- SAFE-W20P-01: no new permissions, networking, accounts, storage contract, dependencies, signing material, or secrets are introduced.

## Review evidence contract

The `w20-boss-ci` workflow creates one attempt-specific artifact named `w20-boss-review-<run_id>-<run_attempt>` containing:

- `boss-contact-sheet.png`: actual 1280×720 Godot/Xvfb render of all ten project-authored boss identities with stable identity labels and review framing.
- `boss-review-mix.wav`: deterministic PCM16 mono / 32 kHz sequential review mix covering all fifty boss presentation cues.
- `boss-review-metrics.json`: per-cue peak/RMS/non-zero metrics plus the live W20 boss parameter envelope (health, contact damage, three phase telegraphs, intervals, damage, radius and derived damage-per-second pressure).

The automated balance envelope is intentionally `PASS_SANITY_ONLY`; it detects obvious parameter breakage but is not a gameplay-fun or difficulty PASS. Artifact names include both `github.run_id` and `github.run_attempt` so a rerun cannot collide with prior-attempt provenance.

## Evidence boundary

Automated PASS proves source/runtime integration and produces the human-facing review inputs. A visual reviewer must still inspect silhouette separation, hierarchy and clipping. A listener must still assess audibility, mix balance, repetition fatigue and timbral separation. Gameplay/balance acceptance still requires an actual play assessment beyond the measured sanity envelope. Until those gates are explicitly satisfied, `implemented_content.bosses` remains `0` and W20 remains production-AV-integrated awaiting human review.
