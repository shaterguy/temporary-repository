# W20 boss audiovisual direction

W20 gives all ten mechanical boss profiles a project-authored audiovisual identity without changing their W20 combat authority. Each vector silhouette is composed specifically for its boss pattern: line/navigation, ring/bell, cone/prism, cross/rootglass, lanes/memory, orbit/index, sweep/furnace, pillars/widow, spiral/corona, and collapse/black-sun. Runtime motion is restrained pulse/bob treatment so danger telegraphs remain visually dominant.

Audio is authored as deterministic PCM16 synthesis in `game/audio/boss_audio_catalog.gd`. Every boss owns one timbral profile and five catalog-resolved cues matching the mechanical catalog: intro, opening, pressure, finale, and break. Frequency, harmonic ratio, transient seed, stage envelope, and priority are explicit source parameters; no downloaded samples or generated third-party media are used.

The production-count gate remains closed until human review. Automated import, uniqueness, non-silence, cue-routing, and mechanics tests prove runtime integration only; they do not prove visual readability, mix quality, repetition fatigue, or encounter balance.
