extends SceneTree

const ExternalAudio = preload("res://game/audio/external_audio_assets.gd")
const ProductionCatalog = preload("res://game/audio/production_audio_catalog.gd")
const BossAudioCatalog = preload("res://game/audio/boss_audio_catalog.gd")
const LegacyCatalog = preload("res://game/audio/audio_catalog.gd")
const AudioDirector = preload("res://game/audio/audio_director.gd")

var failures: Array[String] = []


func _initialize() -> void:
    _check_source_and_license()
    _check_runtime_media()
    _check_semantic_coverage()
    _check_director_runtime_resolution()
    if failures.is_empty():
        print("TEST_CONTRACT=w07-external-audio-v1")
        print("W07_EXTERNAL_MEDIA=29")
        print("W07_WEAPON_SFX_UNIQUE=18")
        print("W07_BOSS_EVENT_CUES=50")
        print("W07_PROCEDURAL_RUNTIME=DISABLED")
        print("W07_LISTENING_REVIEW=REQUIRED")
        print("RESULT=PASS")
        quit(0)
        return
    for failure in failures:
        print("FAIL: %s" % failure)
    print("RESULT=FAIL")
    quit(1)


func _check_source_and_license() -> void:
    _expect(FileAccess.file_exists(ExternalAudio.LICENSE_PATH), "CC0 license provenance is missing")
    var license_text := FileAccess.get_file_as_string(ExternalAudio.LICENSE_PATH)
    _expect("CC0 1.0 Universal" in license_text, "license provenance does not state CC0")
    _expect("50 RPG sound effects" in license_text, "RPG sound source is not recorded")
    _expect("Medieval: Exploration" in license_text, "exploration music source is not recorded")
    _expect("Medieval: Battle" in license_text, "battle music source is not recorded")
    _expect("Forest Ambience" in license_text, "ambience source is not recorded")


func _check_runtime_media() -> void:
    var paths := ExternalAudio.all_runtime_paths()
    _expect(paths.size() == 29, "expected 29 external runtime media files, got %d" % paths.size())
    for path in paths:
        _expect(FileAccess.file_exists(path), "runtime media file missing: %s" % path)
        _expect(ResourceLoader.exists(path), "runtime media was not imported: %s" % path)
        var stream: Resource = load(path)
        _expect(stream is AudioStream, "runtime media did not load as AudioStream: %s" % path)

    var weapon_paths: Dictionary = {}
    var weapon_ids := ExternalAudio.weapon_ids()
    _expect(weapon_ids.size() == 18, "expected 18 curated weapons, got %d" % weapon_ids.size())
    for weapon_id in weapon_ids:
        var path := ExternalAudio.weapon_path(weapon_id)
        _expect(not path.is_empty(), "weapon has no external SFX path: %s" % weapon_id)
        weapon_paths[path] = true
    _expect(weapon_paths.size() == 18, "weapon cues do not resolve to 18 distinct files")


func _check_semantic_coverage() -> void:
    for cue_id in ProductionCatalog.primary_cue_ids():
        _expect(not ExternalAudio.stream_path_for(cue_id).is_empty(), "primary cue is unmapped: %s" % cue_id)

    var boss_event_count := 0
    for boss_id in BossAudioCatalog.boss_ids():
        for cue_id in BossAudioCatalog.cue_ids_for_boss(boss_id):
            boss_event_count += 1
            _expect(not ExternalAudio.stream_path_for(cue_id).is_empty(), "boss event cue is unmapped: %s" % cue_id)
    _expect(boss_event_count == 50, "expected 50 boss event cues, got %d" % boss_event_count)

    for cue_id in [
        LegacyCatalog.REGION,
        LegacyCatalog.TENSION,
        LegacyCatalog.BOSS,
        LegacyCatalog.COMBAT,
        LegacyCatalog.CIRCUIT,
        LegacyCatalog.WARNING,
        LegacyCatalog.REWARD,
        ExternalAudio.AMBIENCE_CUE,
        ExternalAudio.HIT_CUE,
        ExternalAudio.DEATH_CUE,
    ]:
        _expect(not ExternalAudio.stream_path_for(cue_id).is_empty(), "system cue is unmapped: %s" % cue_id)

    var provenance := ExternalAudio.provenance_snapshot()
    _expect(str(provenance.get("runtime_mode", "")) == "external_cc0_files", "external provenance runtime mode regressed")
    _expect(not bool(provenance.get("procedural_runtime", true)), "procedural runtime flag regressed")


func _check_director_runtime_resolution() -> void:
    var source := FileAccess.get_file_as_string("res://game/audio/audio_director.gd")
    _expect("external_audio_assets.gd" in source, "audio director does not reference external asset resolver")
    _expect("ProductionAudio" not in source, "audio director still references ProductionAudio synth")
    _expect("AudioLibrary" not in source, "audio director still references representative synth library")
    _expect("render_cue(" not in source, "audio director still invokes procedural render_cue")
    _expect("MAX_ONE_SHOT_GAIN_DB: float = -6.0" in source, "mobile-safe one-shot gain ceiling is missing")
    _expect("_target_defeated_after_action" in source, "death SFX target-state resolution is missing")

    var director := AudioDirector.new()
    for cue_id in ProductionCatalog.primary_cue_ids():
        var stream: Variant = director.call("_stream_for", cue_id)
        _expect(stream is AudioStream, "director failed to load primary external stream: %s" % cue_id)
    for cue_id in [ExternalAudio.AMBIENCE_CUE, ExternalAudio.HIT_CUE, ExternalAudio.DEATH_CUE]:
        var stream: Variant = director.call("_stream_for", cue_id)
        _expect(stream is AudioStream, "director failed to load special external stream: %s" % cue_id)
    director.free()


func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
