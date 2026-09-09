extends RefCounted

const PROFILES := {
    "drowned_navigator": {"path":"res://assets/runtime/w20/boss_drowned_navigator.svg","scale":1.08,"pulse_hz":0.82,"bob_hz":0.46,"bob_px":3.2,"accent":"#63e7dc"},
    "keel_bell_matron": {"path":"res://assets/runtime/w20/boss_keel_bell_matron.svg","scale":1.12,"pulse_hz":0.58,"bob_hz":0.34,"bob_px":2.4,"accent":"#f0c66f"},
    "prism_ossuary": {"path":"res://assets/runtime/w20/boss_prism_ossuary.svg","scale":1.06,"pulse_hz":1.12,"bob_hz":0.72,"bob_px":3.8,"accent":"#a983ff"},
    "rootglass_colossus": {"path":"res://assets/runtime/w20/boss_rootglass_colossus.svg","scale":1.18,"pulse_hz":0.52,"bob_hz":0.28,"bob_px":1.8,"accent":"#8fe6be"},
    "mnemonic_leviathan": {"path":"res://assets/runtime/w20/boss_mnemonic_leviathan.svg","scale":1.15,"pulse_hz":0.68,"bob_hz":0.41,"bob_px":4.1,"accent":"#76d6cf"},
    "index_regent": {"path":"res://assets/runtime/w20/boss_index_regent.svg","scale":1.07,"pulse_hz":0.94,"bob_hz":0.63,"bob_px":2.9,"accent":"#9faeff"},
    "furnace_conductor": {"path":"res://assets/runtime/w20/boss_furnace_conductor.svg","scale":1.10,"pulse_hz":1.26,"bob_hz":0.54,"bob_px":3.0,"accent":"#ffb34f"},
    "trestle_widow": {"path":"res://assets/runtime/w20/boss_trestle_widow.svg","scale":1.14,"pulse_hz":1.04,"bob_hz":0.86,"bob_px":4.4,"accent":"#d59373"},
    "corona_castellan": {"path":"res://assets/runtime/w20/boss_corona_castellan.svg","scale":1.11,"pulse_hz":0.76,"bob_hz":0.49,"bob_px":3.6,"accent":"#f06b73"},
    "black_sun_reliquary": {"path":"res://assets/runtime/w20/boss_black_sun_reliquary.svg","scale":1.20,"pulse_hz":0.44,"bob_hz":0.24,"bob_px":1.6,"accent":"#9c83cf"},
}

static func boss_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in PROFILES.keys():
        result.append(str(raw_id))
    result.sort()
    return result

static func profile_for(boss_id: String) -> Dictionary:
    var value: Variant = PROFILES.get(boss_id, {})
    return value.duplicate(true) if value is Dictionary else {}

static func path_for(boss_id: String) -> String:
    return str(profile_for(boss_id).get("path", ""))

static func animation_for(boss_id: String) -> Dictionary:
    var profile := profile_for(boss_id)
    return {
        "scale": float(profile.get("scale", 1.0)),
        "pulse_hz": float(profile.get("pulse_hz", 0.8)),
        "bob_hz": float(profile.get("bob_hz", 0.4)),
        "bob_px": float(profile.get("bob_px", 2.0)),
        "accent": str(profile.get("accent", "#ffffff")),
    }
