extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const BossAudioCatalogScript = preload("res://game/audio/boss_audio_catalog.gd")
const LegacyCatalogScript = preload("res://game/audio/audio_catalog.gd")

const ROOT: String = "res://assets/third_party/audio/w07"
const LICENSE_PATH: String = "res://assets/licenses/W07_CC0_AUDIO.md"
const MUSIC_EXPLORATION: String = ROOT + "/music/medieval_exploration.mp3"
const MUSIC_BATTLE: String = ROOT + "/music/medieval_battle.mp3"
const AMBIENCE_FOREST: String = ROOT + "/ambience/forest_ambience.mp3"
const HIT_PATH: String = ROOT + "/combat/hit_metal.ogg"
const DEATH_PATH: String = ROOT + "/combat/death_chop.ogg"

const AMBIENCE_CUE: String = "external:ambience:forest"
const HIT_CUE: String = "external:combat:hit"
const DEATH_CUE: String = "external:combat:death"

const UI_PATHS := {
    "open": ROOT + "/ui/ui_01.ogg",
    "confirm": ROOT + "/ui/ui_02.ogg",
    "back": ROOT + "/ui/ui_03.ogg",
    "focus": ROOT + "/ui/ui_04.ogg",
    "reject": ROOT + "/ui/ui_05.ogg",
    "reward": ROOT + "/ui/ui_06.ogg",
}

const SPECIAL_SPECS := {
    AMBIENCE_CUE: {
        "category": "ambience",
        "bus": "Music",
        "loop": true,
        "priority": 5,
        "cooldown": 0.0,
        "gain_db": -18.0,
        "provenance": "external_cc0",
    },
    HIT_CUE: {
        "category": "combat_hit",
        "bus": "SFX",
        "loop": false,
        "priority": 58,
        "cooldown": 0.03,
        "gain_db": -10.0,
        "provenance": "external_cc0",
    },
    DEATH_CUE: {
        "category": "combat_death",
        "bus": "SFX",
        "loop": false,
        "priority": 74,
        "cooldown": 0.06,
        "gain_db": -8.0,
        "provenance": "external_cc0",
    },
}


static func weapon_ids() -> Array[String]:
    var result := WeaponPartCatalogScript.weapon_ids()
    result.sort()
    return result


static func weapon_path(weapon_id: String) -> String:
    var ids := weapon_ids()
    var index := ids.find(weapon_id)
    if index < 0 or index >= 18:
        return ""
    return "%s/weapons/weapon_%02d.ogg" % [ROOT, index + 1]


static func ui_path(action_id: String) -> String:
    return str(UI_PATHS.get(action_id, ""))


static func stream_path_for(cue_id: String) -> String:
    if cue_id == AMBIENCE_CUE:
        return AMBIENCE_FOREST
    if cue_id == HIT_CUE:
        return HIT_PATH
    if cue_id == DEATH_CUE:
        return DEATH_PATH

    if cue_id.begins_with("region:"):
        var parts := cue_id.split(":")
        if parts.size() == 3:
            var layer := str(parts[2])
            if layer == "bed":
                return MUSIC_EXPLORATION
            if layer == "tension":
                return MUSIC_BATTLE
        return ""

    if cue_id.begins_with("boss:") and cue_id.ends_with(":music"):
        return MUSIC_BATTLE

    if cue_id.begins_with("weapon:"):
        return weapon_path(cue_id.trim_prefix("weapon:"))

    if cue_id.begins_with("ui:"):
        return ui_path(cue_id.trim_prefix("ui:"))

    if BossAudioCatalogScript.is_boss_cue(cue_id):
        var spec := BossAudioCatalogScript.cue_spec(cue_id)
        var bosses := BossAudioCatalogScript.boss_ids()
        var boss_index := bosses.find(str(spec.get("boss_id", "")))
        var stage_index := int(spec.get("stage_index", 0))
        var ids := weapon_ids()
        if boss_index < 0 or ids.is_empty():
            return HIT_PATH
        return weapon_path(ids[posmod(boss_index * 5 + stage_index, ids.size())])

    match cue_id:
        LegacyCatalogScript.REGION:
            return MUSIC_EXPLORATION
        LegacyCatalogScript.TENSION, LegacyCatalogScript.BOSS:
            return MUSIC_BATTLE
        LegacyCatalogScript.COMBAT:
            var ids := weapon_ids()
            return weapon_path(ids[0]) if not ids.is_empty() else HIT_PATH
        LegacyCatalogScript.CIRCUIT:
            return ui_path("confirm")
        LegacyCatalogScript.WARNING:
            return ui_path("reject")
        LegacyCatalogScript.REWARD:
            return ui_path("reward")
    return ""


static func cue_spec(cue_id: String) -> Dictionary:
    var value: Variant = SPECIAL_SPECS.get(cue_id, {})
    return value.duplicate(true) if value is Dictionary else {}


static func all_runtime_paths() -> PackedStringArray:
    var unique: Dictionary = {}
    for path in [MUSIC_EXPLORATION, MUSIC_BATTLE, AMBIENCE_FOREST, HIT_PATH, DEATH_PATH]:
        unique[path] = true
    for weapon_id in weapon_ids():
        var path := weapon_path(weapon_id)
        if not path.is_empty():
            unique[path] = true
    for raw_path in UI_PATHS.values():
        unique[str(raw_path)] = true
    var result := PackedStringArray()
    for raw_path in unique.keys():
        result.append(str(raw_path))
    result.sort()
    return result


static func provenance_snapshot() -> Dictionary:
    return {
        "runtime_mode": "external_cc0_files",
        "procedural_runtime": false,
        "license_path": LICENSE_PATH,
        "runtime_media_count": all_runtime_paths().size(),
        "music_tracks": 2,
        "ambience_tracks": 1,
        "weapon_sfx": weapon_ids().size(),
        "combat_feedback_sfx": 2,
        "ui_sfx": UI_PATHS.size(),
    }
