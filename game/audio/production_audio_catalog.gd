extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const BossAudioCatalogScript = preload("res://game/audio/boss_audio_catalog.gd")

const MIX_RATE: int = 32000
const MUSIC_SECONDS: float = 4.0
const REVIEW_SECONDS: float = 12.0
const LOW_REVIEW_GAIN: float = 0.12589254
const LOW_WARNING_GAIN: float = 0.25118864

const REGION_PROFILE_IDS := [
    "twilight_shipyard",
    "glass_garden",
    "flooded_archive",
    "ash_railway",
    "eclipse_fortress",
]

const REGION_ALIASES := {
    "twilight_shipyard": "twilight_shipyard",
    "glass_garden": "glass_garden",
    "brine_veins": "glass_garden",
    "blackglass_spires": "glass_garden",
    "flooded_archive": "flooded_archive",
    "drowned_archive": "flooded_archive",
    "storm_crown": "flooded_archive",
    "ash_railway": "ash_railway",
    "afterglow_frontier": "ash_railway",
    "eclipse_fortress": "eclipse_fortress",
    "far_lantern_chain": "eclipse_fortress",
}

const REGION_PROFILES := {
    "twilight_shipyard": {"base_hz":55.0,"accent_hz":293.66,"pulse_hz":1.00,"overtone":2.00,"seed":503},
    "glass_garden": {"base_hz":65.41,"accent_hz":392.00,"pulse_hz":1.25,"overtone":2.67,"seed":541},
    "flooded_archive": {"base_hz":49.00,"accent_hz":246.94,"pulse_hz":0.80,"overtone":1.50,"seed":587},
    "ash_railway": {"base_hz":73.42,"accent_hz":329.63,"pulse_hz":1.50,"overtone":1.33,"seed":631},
    "eclipse_fortress": {"base_hz":46.25,"accent_hz":369.99,"pulse_hz":0.67,"overtone":1.618,"seed":683},
}

const DELIVERY_BASE_HZ := {
    "piercing_lance": 520.0,
    "lantern_bolt": 760.0,
    "halo_orbit": 410.0,
    "radiant_pulse": 250.0,
    "chain_arc": 920.0,
    "fan_shards": 680.0,
}

const UI_SPECS := {
    "open": {"duration":0.28,"priority":58,"gain_db":-9.0,"style":0,"bus":"SFX"},
    "confirm": {"duration":0.24,"priority":68,"gain_db":-7.5,"style":1,"bus":"SFX"},
    "back": {"duration":0.22,"priority":64,"gain_db":-8.5,"style":2,"bus":"SFX"},
    "focus": {"duration":0.12,"priority":48,"gain_db":-11.0,"style":3,"bus":"SFX"},
    "reject": {"duration":0.48,"priority":94,"gain_db":-3.0,"style":4,"bus":"Warning"},
    "reward": {"duration":0.72,"priority":80,"gain_db":-5.0,"style":5,"bus":"SFX"},
}

static func region_profile_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in REGION_PROFILE_IDS:
        result.append(str(raw_id))
    return result

static func region_runtime_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in REGION_ALIASES.keys():
        result.append(str(raw_id))
    result.sort()
    return result

static func region_profile_id(region_id: String) -> String:
    return str(REGION_ALIASES.get(region_id, ""))

static func region_music_cue(region_id: String, layer: String) -> String:
    var profile_id := region_profile_id(region_id)
    if profile_id.is_empty() and region_id in REGION_PROFILE_IDS:
        profile_id = region_id
    if profile_id.is_empty() or layer not in ["bed", "tension"]:
        return ""
    return "region:%s:%s" % [profile_id, layer]

static func boss_ids() -> Array[String]:
    return BossAudioCatalogScript.boss_ids()

static func boss_music_cue(boss_id: String) -> String:
    if BossAudioCatalogScript.cue_ids_for_boss(boss_id).is_empty():
        return ""
    return "boss:%s:music" % boss_id

static func weapon_ids() -> Array[String]:
    var result := WeaponPartCatalogScript.weapon_ids()
    result.sort()
    return result

static func weapon_cue_id(weapon_id: String) -> String:
    if WeaponPartCatalogScript.recipe_for_weapon(weapon_id).is_empty():
        return ""
    return "weapon:%s" % weapon_id

static func ui_action_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in UI_SPECS.keys():
        result.append(str(raw_id))
    result.sort()
    return result

static func ui_cue_id(action_id: String) -> String:
    if not UI_SPECS.has(action_id):
        return ""
    return "ui:%s" % action_id

static func cue_spec(cue_id: String) -> Dictionary:
    if cue_id.begins_with("region:"):
        var parts := cue_id.split(":")
        if parts.size() != 3:
            return {}
        var profile_id := str(parts[1])
        var layer := str(parts[2])
        if not REGION_PROFILES.has(profile_id) or layer not in ["bed", "tension"]:
            return {}
        var profile: Dictionary = REGION_PROFILES[profile_id]
        return {
            "cue_id": cue_id,
            "category": "region_music",
            "profile_id": profile_id,
            "layer": layer,
            "bus": "Music",
            "duration": MUSIC_SECONDS,
            "loop": true,
            "priority": 18 if layer == "bed" else 28,
            "cooldown": 0.0,
            "gain_db": -8.5 if layer == "bed" else -10.0,
            "base_hz": float(profile.get("base_hz", 55.0)),
            "accent_hz": float(profile.get("accent_hz", 293.66)),
            "pulse_hz": float(profile.get("pulse_hz", 1.0)),
            "overtone": float(profile.get("overtone", 2.0)),
            "seed": int(profile.get("seed", 1)),
            "placeholder": false,
            "provenance": "original_procedural",
        }
    if cue_id.begins_with("boss:"):
        var parts := cue_id.split(":")
        if parts.size() != 3 or str(parts[2]) != "music":
            return {}
        var boss_id := str(parts[1])
        var event_cues := BossAudioCatalogScript.cue_ids_for_boss(boss_id)
        if event_cues.is_empty():
            return {}
        var seed_spec := BossAudioCatalogScript.cue_spec(str(event_cues[0]))
        return {
            "cue_id": cue_id,
            "category": "boss_music",
            "boss_id": boss_id,
            "bus": "Music",
            "duration": MUSIC_SECONDS,
            "loop": true,
            "priority": 36,
            "cooldown": 0.0,
            "gain_db": -7.0,
            "base_hz": float(seed_spec.get("base_hz", 73.42)),
            "overtone": float(seed_spec.get("overtone", 2.0)),
            "phase_bias": float(seed_spec.get("phase_bias", 0.0)),
            "seed": int(seed_spec.get("seed", 1)),
            "placeholder": false,
            "provenance": "original_procedural",
        }
    if cue_id.begins_with("weapon:"):
        var weapon_id := cue_id.trim_prefix("weapon:")
        var recipe := WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
        if recipe.is_empty():
            return {}
        var sorted_ids := weapon_ids()
        var weapon_index := maxi(0, sorted_ids.find(weapon_id))
        var delivery_id := str(recipe.get("delivery", "lantern_bolt"))
        var transform_id := str(recipe.get("transform", ""))
        return {
            "cue_id": cue_id,
            "category": "weapon",
            "weapon_id": weapon_id,
            "delivery": delivery_id,
            "transform": transform_id,
            "bus": "SFX",
            "duration": 0.38 + float(weapon_index % 5) * 0.045,
            "loop": false,
            "priority": 38 + weapon_index % 7,
            "cooldown": 0.045 + float(weapon_index % 3) * 0.015,
            "gain_db": -8.0 + float(weapon_index % 3) * 0.6,
            "base_hz": float(DELIVERY_BASE_HZ.get(delivery_id, 620.0)) * (1.0 + float(weapon_index % 4) * 0.055),
            "accent_hz": 1180.0 + float(weapon_index) * 41.0,
            "seed": 761 + weapon_index * 37,
            "placeholder": false,
            "provenance": "original_procedural",
        }
    if cue_id.begins_with("ui:"):
        var action_id := cue_id.trim_prefix("ui:")
        if not UI_SPECS.has(action_id):
            return {}
        var ui_spec: Dictionary = UI_SPECS[action_id]
        return {
            "cue_id": cue_id,
            "category": "ui",
            "action_id": action_id,
            "bus": str(ui_spec.get("bus", "SFX")),
            "duration": float(ui_spec.get("duration", 0.2)),
            "loop": false,
            "priority": int(ui_spec.get("priority", 50)),
            "cooldown": 0.04,
            "gain_db": float(ui_spec.get("gain_db", -8.0)),
            "style": int(ui_spec.get("style", 0)),
            "seed": 1201 + int(ui_spec.get("style", 0)) * 53,
            "placeholder": false,
            "provenance": "original_procedural",
        }
    return {}

static func has_cue(cue_id: String) -> bool:
    return not cue_spec(cue_id).is_empty()

static func primary_cue_ids() -> Array[String]:
    var result: Array[String] = []
    for region_id in region_profile_ids():
        result.append(region_music_cue(region_id, "bed"))
        result.append(region_music_cue(region_id, "tension"))
    for boss_id in boss_ids():
        result.append(boss_music_cue(boss_id))
    for weapon_id in weapon_ids():
        result.append(weapon_cue_id(weapon_id))
    for action_id in ui_action_ids():
        result.append(ui_cue_id(action_id))
    return result

static func coverage_snapshot() -> Dictionary:
    var boss_event_cues := 0
    for boss_id in boss_ids():
        boss_event_cues += BossAudioCatalogScript.cue_ids_for_boss(boss_id).size()
    return {
        "region_families": region_profile_ids().size(),
        "region_runtime_ids": region_runtime_ids().size(),
        "boss_music": boss_ids().size(),
        "boss_event_cues": boss_event_cues,
        "weapon_sfx": weapon_ids().size(),
        "ui_sfx": ui_action_ids().size(),
        "primary_cues": primary_cue_ids().size(),
        "reused_system_cues": 3,
        "effective_cues": primary_cue_ids().size() + boss_event_cues + 3,
    }
