extends RefCounted

const MANIFEST_PATH: String = "res://assets/runtime/w13/art_manifest.json"
const PLAYER_IDS := ["player_aurora", "player_cinder"]
const ENEMY_IDS := [
    "enemy_dusk_mite",
    "enemy_rivet_hound",
    "enemy_glasswing",
    "enemy_chain_wraith",
    "enemy_ballast_guard",
    "enemy_hull_reaver",
    "enemy_emberling",
    "enemy_lantern_leech",
]
const SWARM_VISUALS := [
    "enemy_dusk_mite",
    "enemy_chain_wraith",
    "enemy_ballast_guard",
    "enemy_lantern_leech",
]
const RUNNER_VISUALS := [
    "enemy_rivet_hound",
    "enemy_hull_reaver",
    "enemy_glasswing",
    "enemy_emberling",
]
const PATHS := {
    "environment_twilight_shipyard": "res://assets/runtime/w13/environment_twilight_shipyard.svg",
    "player_aurora": "res://assets/runtime/w13/player_aurora.svg",
    "player_cinder": "res://assets/runtime/w13/player_cinder.svg",
    "enemy_dusk_mite": "res://assets/runtime/w13/enemy_dusk_mite.svg",
    "enemy_rivet_hound": "res://assets/runtime/w13/enemy_rivet_hound.svg",
    "enemy_glasswing": "res://assets/runtime/w13/enemy_glasswing.svg",
    "enemy_chain_wraith": "res://assets/runtime/w13/enemy_chain_wraith.svg",
    "enemy_ballast_guard": "res://assets/runtime/w13/enemy_ballast_guard.svg",
    "enemy_hull_reaver": "res://assets/runtime/w13/enemy_hull_reaver.svg",
    "enemy_emberling": "res://assets/runtime/w13/enemy_emberling.svg",
    "enemy_lantern_leech": "res://assets/runtime/w13/enemy_lantern_leech.svg",
    "boss_drowned_navigator": "res://assets/runtime/w13/boss_drowned_navigator.svg",
    "ark_lantern_bastion": "res://assets/runtime/w13/ark_lantern_bastion.svg",
    "hud_lantern_panel": "res://assets/runtime/w13/hud_lantern_panel.svg",
    "vfx_phase_burst": "res://assets/runtime/w13/vfx_phase_burst.svg",
}


static func all_asset_ids() -> Array[String]:
    var result: Array[String] = []
    for asset_id in PATHS.keys():
        result.append(str(asset_id))
    result.sort()
    return result


static func all_paths() -> Array[String]:
    var result: Array[String] = []
    for asset_id in all_asset_ids():
        result.append(str(PATHS[asset_id]))
    return result


static func path_for(asset_id: String) -> String:
    return str(PATHS.get(asset_id, ""))


static func player_id_for_slot(slot: int) -> String:
    return str(PLAYER_IDS[absi(slot) % PLAYER_IDS.size()])


static func enemy_visual_id(archetype: String, entity_id: int) -> String:
    if archetype == "boss":
        return "boss_drowned_navigator"
    var source: Array = RUNNER_VISUALS if archetype == "runner" else SWARM_VISUALS
    return str(source[absi(entity_id) % source.size()])
