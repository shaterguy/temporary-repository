extends SceneTree

const ProductionCatalog = preload("res://game/audio/production_audio_catalog.gd")
const ProductionAudio = preload("res://game/audio/production_audio_synth.gd")
const AudioDirectorScript = preload("res://game/audio/audio_director.gd")
const BossAudioCatalog = preload("res://game/audio/boss_audio_catalog.gd")
const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var coverage := ProductionCatalog.coverage_snapshot()
    _expect(int(coverage.get("region_families", 0)) == 5, "five region families must be covered")
    _expect(int(coverage.get("region_runtime_ids", 0)) == 11, "all current region/runtime aliases must be covered")
    _expect(int(coverage.get("boss_music", 0)) == 10, "all ten bosses need dedicated music profiles")
    _expect(int(coverage.get("boss_event_cues", 0)) == 50, "all W20 boss event cues must remain mapped")
    _expect(int(coverage.get("weapon_sfx", 0)) == 18, "all curated weapons need attack SFX")
    _expect(int(coverage.get("ui_sfx", 0)) == 6, "six main UI actions need cues")
    _expect(int(coverage.get("primary_cues", 0)) == 44, "W24 primary production cue count drifted")
    _expect(int(coverage.get("effective_cues", 0)) == 97, "effective audio coverage count drifted")

    var required_region_ids: Array[String] = ["twilight_shipyard"]
    required_region_ids.append_array(RegionCatalogScript.all_parent_region_ids())
    required_region_ids.append_array(RegionCatalogScript.all_region_ids())
    for region_id in required_region_ids:
        _expect(not ProductionCatalog.region_profile_id(region_id).is_empty(), "missing region audio alias: %s" % region_id)

    var boss_ids := BossAudioCatalog.boss_ids()
    _expect(boss_ids.size() == 10, "boss catalog count drifted")
    for boss_id in boss_ids:
        _expect(not ProductionCatalog.boss_music_cue(boss_id).is_empty(), "missing boss music: %s" % boss_id)
        _expect(BossAudioCatalog.cue_ids_for_boss(boss_id).size() == 5, "boss event cue coverage drifted: %s" % boss_id)

    var weapon_ids := WeaponPartCatalogScript.weapon_ids()
    _expect(weapon_ids.size() == 18, "curated weapon count drifted")
    for weapon_id in weapon_ids:
        _expect(not ProductionCatalog.weapon_cue_id(weapon_id).is_empty(), "missing weapon cue: %s" % weapon_id)

    for cue_id in ProductionCatalog.primary_cue_ids():
        var spec := ProductionCatalog.cue_spec(cue_id)
        _expect(not spec.is_empty(), "missing production cue spec: %s" % cue_id)
        _expect(not bool(spec.get("placeholder", true)), "production cue may not be placeholder: %s" % cue_id)
        _expect(str(spec.get("provenance", "")) == "original_procedural", "production cue provenance drift: %s" % cue_id)
        var stream := ProductionAudio.render_cue(cue_id)
        _expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s must render PCM16" % cue_id)
        _expect(stream.mix_rate == ProductionCatalog.MIX_RATE, "%s sample rate mismatch" % cue_id)
        _expect(not stream.stereo, "%s must remain mono" % cue_id)
        var metrics := ProductionAudio.analyze(stream)
        _expect(float(metrics.get("peak", 0.0)) >= 0.035, "%s peak is effectively silent" % cue_id)
        _expect(float(metrics.get("rms", 0.0)) >= 0.004, "%s RMS is effectively silent" % cue_id)
        _expect(float(metrics.get("nonzero_ratio", 0.0)) >= 0.16, "%s contains too much silence" % cue_id)
        if bool(spec.get("loop", false)):
            _expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s music must loop" % cue_id)

    var director := AudioDirectorScript.new()
    var policy := director.policy_snapshot()
    _expect(int(policy.get("max_sfx_voices", 0)) == 8, "SFX voice pool must remain bounded at eight")
    _expect(str(policy.get("voice_steal_policy", "")) == "oldest-lower-priority-only", "voice-steal policy drifted")
    _expect(float(AudioDirectorScript.warning_linear_for_sfx(0.05)) > 0.05, "low non-zero warning bus must remain more salient than ordinary SFX")
    _expect(is_zero_approx(AudioDirectorScript.warning_linear_for_sfx(0.0)), "zero SFX must still mute warning bus")
    _expect(director.set_region("far_lantern_chain"), "director rejected a current region alias")
    _expect(str(director.production_snapshot().get("active_region_profile", "")) == "eclipse_fortress", "region alias did not select the production profile")
    _expect(director.set_boss_music("black_sun_reliquary"), "director rejected a current boss")
    _expect(str(director.production_snapshot().get("active_boss_id", "")) == "black_sun_reliquary", "boss music identity did not update")
    director.free()

    var packed: Resource = load("res://game/ui/main_shell.tscn")
    if not packed is PackedScene:
        _failures.append("main shell scene could not be loaded")
    else:
        var shell := (packed as PackedScene).instantiate()
        _expect(str(shell.get_script().resource_path) == "res://game/ui/main_shell_w24.gd", "main shell is not using the W24 audio bridge")
        shell.free()

    _finish()

func _finish() -> void:
    print("W24_REGION_FAMILIES=5")
    print("W24_REGION_RUNTIME_IDS=11")
    print("W24_BOSS_MUSIC=10")
    print("W24_BOSS_EVENT_CUES=50")
    print("W24_WEAPON_SFX=18")
    print("W24_UI_SFX=6")
    print("W24_PRIMARY_CUES=44")
    print("W24_EFFECTIVE_CUES=97")
    if _failures.is_empty():
        print("W24_WARNING_LOW_VOLUME=PASS")
        print("W24_MAIN_SHELL_AUDIO_BRIDGE=PASS")
        print("W24_PRODUCTION_AUDIO=PASS")
        quit(0)
        return
    for failure in _failures:
        printerr("W24_FAIL: %s" % failure)
    printerr("W24_PRODUCTION_AUDIO=FAIL")
    quit(1)

func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
