extends SceneTree

const ProductionCatalog = preload("res://game/audio/production_audio_catalog.gd")
const ProductionAudio = preload("res://game/audio/production_audio_synth.gd")

var _failures: Array[String] = []
var _saved_files: int = 0

func _initialize() -> void:
    call_deferred("_render")

func _render() -> void:
    var regions := ProductionCatalog.region_profile_ids()
    var bosses := ProductionCatalog.boss_ids()
    var weapons := ProductionCatalog.weapon_ids()
    var ui_actions := ProductionCatalog.ui_action_ids()

    for region_index in range(regions.size()):
        var review_weapons: Array[String] = []
        for weapon_index in range(weapons.size()):
            if weapon_index % regions.size() == region_index:
                review_weapons.append(weapons[weapon_index])
        var boss_id := bosses[(region_index * 2) % bosses.size()]
        _save(
            ProductionAudio.render_review_mix(regions[region_index], boss_id, review_weapons, false),
            "res://artifacts/w24/region_%s_normal.wav" % regions[region_index]
        )
        _save(
            ProductionAudio.render_review_mix(regions[region_index], boss_id, review_weapons, true),
            "res://artifacts/w24/region_%s_low.wav" % regions[region_index]
        )

    for boss_id in bosses:
        _save(
            ProductionAudio.render_cue(ProductionCatalog.boss_music_cue(boss_id)),
            "res://artifacts/w24/boss_%s.wav" % boss_id
        )

    for weapon_id in weapons:
        _save(
            ProductionAudio.render_cue(ProductionCatalog.weapon_cue_id(weapon_id)),
            "res://artifacts/w24/weapon_%s.wav" % weapon_id
        )

    for action_id in ui_actions:
        _save(
            ProductionAudio.render_cue(ProductionCatalog.ui_cue_id(action_id)),
            "res://artifacts/w24/ui_%s.wav" % action_id
        )

    print("W24_AUDIO_RATE=%d" % ProductionCatalog.MIX_RATE)
    print("W24_AUDIO_FORMAT=PCM16_MONO")
    print("W24_LOW_VOLUME_MIX_GAIN_DB=-18")
    print("W24_LOW_VOLUME_WARNING_RELATIVE_DB=6")
    print("W24_REGION_REVIEW_FILES=10")
    print("W24_BOSS_REVIEW_FILES=10")
    print("W24_WEAPON_REVIEW_FILES=18")
    print("W24_UI_REVIEW_FILES=6")
    print("W24_TOTAL_REVIEW_FILES=%d" % _saved_files)
    if _failures.is_empty() and _saved_files == 44:
        print("W24_AUDIO_RENDER=PASS")
        quit(0)
        return
    for failure in _failures:
        printerr("W24_AUDIO_FAIL: %s" % failure)
    printerr("W24_AUDIO_RENDER=FAIL")
    quit(1)

func _save(stream: AudioStreamWAV, path: String) -> void:
    var metrics := ProductionAudio.analyze(stream)
    if float(metrics.get("peak", 0.0)) < 0.02 or float(metrics.get("rms", 0.0)) < 0.002:
        _failures.append("silent review stream: %s" % path)
        return
    var error := stream.save_to_wav(path)
    if error != OK:
        _failures.append("save failed %s: %s" % [path, error_string(error)])
        return
    _saved_files += 1
