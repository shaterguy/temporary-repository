extends RefCounted

const REGION_GLASS_GARDEN: String = "glass_garden"
const REGION_FLOODED_ARCHIVE: String = "flooded_archive"
const REGION_ASH_RAILWAY: String = "ash_railway"
const REGION_ECLIPSE_FORTRESS: String = "eclipse_fortress"
const PHASE_MATERIAL: String = "material"
const PHASE_SHADOW: String = "shadow"

const GLASS_GARDEN_BEHAVIORS := [
    {"behavior_id": "prism_skater", "base_archetype": "runner", "entry_pattern": "split_lane", "telegraph_scale": 0.82, "phase_preference": PHASE_MATERIAL, "role": "fast lane cutter", "counterplay": "cross the lane after its paired warning"},
    {"behavior_id": "shard_bloom", "base_archetype": "swarm", "entry_pattern": "wide_arc", "telegraph_scale": 1.18, "phase_preference": PHASE_MATERIAL, "role": "expanding perimeter pressure", "counterplay": "close the arc with a circuit before it converges"},
    {"behavior_id": "lattice_warden", "base_archetype": "swarm", "entry_pattern": "escort_pressure", "telegraph_scale": 1.30, "phase_preference": PHASE_MATERIAL, "role": "ark lane anchor", "counterplay": "pull it off the ark line or ward the objective"},
    {"behavior_id": "refraction_moth", "base_archetype": "runner", "entry_pattern": "phase_flank", "telegraph_scale": 0.95, "phase_preference": PHASE_SHADOW, "role": "shadow flank harrier", "counterplay": "preview the opposite phase before switching"},
    {"behavior_id": "sap_mirror", "base_archetype": "swarm", "entry_pattern": "close_pressure", "telegraph_scale": 1.05, "phase_preference": PHASE_SHADOW, "role": "close-range light tax", "counterplay": "leave room for a broad circuit rather than a tiny loop"},
    {"behavior_id": "glassroot_stalker", "base_archetype": "runner", "entry_pattern": "far_pressure", "telegraph_scale": 1.12, "phase_preference": PHASE_SHADOW, "role": "long-entry pursuit", "counterplay": "use route geometry to force a longer approach"},
]

const FLOODED_ARCHIVE_BEHAVIORS := [
    {"behavior_id": "ink_drifter", "base_archetype": "swarm", "entry_pattern": "current_arc", "telegraph_scale": 1.08, "phase_preference": PHASE_MATERIAL, "role": "current-borne arc pressure", "counterplay": "move perpendicular to the current lane"},
    {"behavior_id": "archive_leech", "base_archetype": "runner", "entry_pattern": "close_pressure", "telegraph_scale": 0.86, "phase_preference": PHASE_MATERIAL, "role": "objective pursuer", "counterplay": "intercept before it reaches the archive payload"},
    {"behavior_id": "drowned_indexer", "base_archetype": "swarm", "entry_pattern": "column_push", "telegraph_scale": 1.24, "phase_preference": PHASE_MATERIAL, "role": "column formation", "counterplay": "break the column with lateral movement"},
    {"behavior_id": "silt_scribe", "base_archetype": "swarm", "entry_pattern": "split_lane", "telegraph_scale": 1.00, "phase_preference": PHASE_SHADOW, "role": "split-lane recorder", "counterplay": "commit to one lane instead of standing between both"},
    {"behavior_id": "mnemonic_eel", "base_archetype": "runner", "entry_pattern": "phase_flank", "telegraph_scale": 0.90, "phase_preference": PHASE_SHADOW, "role": "shadow surge", "counterplay": "switch only after checking the shadow warning count"},
    {"behavior_id": "vault_mimic", "base_archetype": "swarm", "entry_pattern": "escort_pressure", "telegraph_scale": 1.34, "phase_preference": PHASE_SHADOW, "role": "ark diversion pressure", "counterplay": "trade personal space for direct ark protection"},
]

const ASH_RAILWAY_BEHAVIORS := [
    {"behavior_id": "cinder_switchman", "base_archetype": "swarm", "entry_pattern": "split_lane", "telegraph_scale": 1.06, "phase_preference": PHASE_MATERIAL, "role": "rail-junction lane splitter", "counterplay": "commit after the signal arm reveals the live rail"},
    {"behavior_id": "boiler_hound", "base_archetype": "runner", "entry_pattern": "close_pressure", "telegraph_scale": 0.84, "phase_preference": PHASE_MATERIAL, "role": "short-burst carriage hunter", "counterplay": "sidestep the pressure burst instead of outrunning it"},
    {"behavior_id": "slag_brakeman", "base_archetype": "swarm", "entry_pattern": "escort_pressure", "telegraph_scale": 1.28, "phase_preference": PHASE_MATERIAL, "role": "Ark speed suppressor", "counterplay": "break its escort line before the next switchback"},
    {"behavior_id": "ghost_trestler", "base_archetype": "runner", "entry_pattern": "phase_flank", "telegraph_scale": 0.92, "phase_preference": PHASE_SHADOW, "role": "trestle-gap phase flanker", "counterplay": "preview shadow gaps before crossing the rail fan"},
    {"behavior_id": "ash_conductor", "base_archetype": "swarm", "entry_pattern": "column_push", "telegraph_scale": 1.20, "phase_preference": PHASE_SHADOW, "role": "formation conductor", "counterplay": "cut across the column while its signal is re-arming"},
    {"behavior_id": "ember_stowaway", "base_archetype": "runner", "entry_pattern": "far_pressure", "telegraph_scale": 1.10, "phase_preference": PHASE_SHADOW, "role": "rear-car pursuit", "counterplay": "use a wide circuit to deny the long approach"},
]

const ECLIPSE_FORTRESS_BEHAVIORS := [
    {"behavior_id": "umbra_sentinel", "base_archetype": "swarm", "entry_pattern": "column_push", "telegraph_scale": 1.30, "phase_preference": PHASE_MATERIAL, "role": "bastion column anchor", "counterplay": "leave the firing corridor before the shield line locks"},
    {"behavior_id": "corona_lancer", "base_archetype": "runner", "entry_pattern": "far_pressure", "telegraph_scale": 0.96, "phase_preference": PHASE_MATERIAL, "role": "long-lane solar lancer", "counterplay": "cross the beam lane during the charge flare"},
    {"behavior_id": "gate_choir", "base_archetype": "swarm", "entry_pattern": "wide_arc", "telegraph_scale": 1.36, "phase_preference": PHASE_MATERIAL, "role": "portcullis perimeter pressure", "counterplay": "collapse one side of the arc before the gate closes"},
    {"behavior_id": "penumbra_duelist", "base_archetype": "runner", "entry_pattern": "phase_flank", "telegraph_scale": 0.88, "phase_preference": PHASE_SHADOW, "role": "phase-reading flank duelist", "counterplay": "delay the switch until its opposite-lane tell appears"},
    {"behavior_id": "black_sun_deacon", "base_archetype": "swarm", "entry_pattern": "escort_pressure", "telegraph_scale": 1.26, "phase_preference": PHASE_SHADOW, "role": "Ark corruption escort", "counterplay": "screen the Ark instead of chasing the outer formation"},
    {"behavior_id": "occlusion_wisp", "base_archetype": "runner", "entry_pattern": "close_pressure", "telegraph_scale": 0.90, "phase_preference": PHASE_SHADOW, "role": "visibility-collapse pursuer", "counterplay": "keep a circuit reserve for the post-switch rush"},
]


static func region_ids() -> Array[String]:
    return ["brine_veins", "blackglass_spires", "drowned_archive", "storm_crown"]


static func parent_region_ids() -> Array[String]:
    return [REGION_GLASS_GARDEN, REGION_FLOODED_ARCHIVE]


static func w19_region_ids() -> Array[String]:
    return ["afterglow_frontier", "far_lantern_chain"]


static func w19_parent_region_ids() -> Array[String]:
    return [REGION_ASH_RAILWAY, REGION_ECLIPSE_FORTRESS]


static func all_region_ids() -> Array[String]:
    var result := region_ids()
    result.append_array(w19_region_ids())
    return result


static func all_parent_region_ids() -> Array[String]:
    var result := parent_region_ids()
    result.append_array(w19_parent_region_ids())
    return result


static func profile_for_region(region_id: String) -> Dictionary:
    match region_id:
        "brine_veins":
            return _profile(
                region_id,
                REGION_GLASS_GARDEN,
                "유리 정원 · 염수맥",
                "supply_causeway",
                "align_prism_lattice",
                "프리즘 격자 정렬",
                1,
                "res://assets/runtime/w18/environment_glass_garden.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(98.0, 118.0), Vector2(232.0, 76.0), Vector2(348.0, 176.0), Vector2(522.0, 84.0), Vector2(680.0, 0.0)]),
                    "travel_speed": 54.0,
                    "threat_level": 1,
                    "supply_cost": 8,
                    "supply_reward": 28,
                    "reward_id": "prism_seed_cache",
                    "entry_direction": Vector2(-1.0, 0.42).normalized(),
                    "defend_target": "supply_pod",
                },
                _glass_phase_rules(),
                GLASS_GARDEN_BEHAVIORS
            )
        "blackglass_spires":
            return _profile(
                region_id,
                REGION_GLASS_GARDEN,
                "유리 정원 · 흑유리 첨탑",
                "risk_channel",
                "stabilize_refraction_beacon",
                "굴절 등대 안정화",
                1,
                "res://assets/runtime/w18/environment_glass_garden.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(132.0, -154.0), Vector2(304.0, -82.0), Vector2(430.0, -208.0), Vector2(568.0, -112.0), Vector2(680.0, 0.0)]),
                    "travel_speed": 88.0,
                    "threat_level": 3,
                    "supply_cost": 14,
                    "supply_reward": 5,
                    "reward_id": "blackglass_focus",
                    "entry_direction": Vector2(1.0, -0.48).normalized(),
                    "defend_target": "ark_core",
                },
                _glass_phase_rules(),
                GLASS_GARDEN_BEHAVIORS
            )
        "drowned_archive":
            return _profile(
                region_id,
                REGION_FLOODED_ARCHIVE,
                "침수 기록원 · 가라앉은 서고",
                "supply_causeway",
                "recover_memory_folios",
                "기억 장서 회수",
                2,
                "res://assets/runtime/w18/environment_flooded_archive.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(96.0, 52.0), Vector2(196.0, 148.0), Vector2(344.0, 126.0), Vector2(466.0, 214.0), Vector2(592.0, 116.0), Vector2(710.0, 0.0)]),
                    "travel_speed": 50.0,
                    "threat_level": 2,
                    "supply_cost": 10,
                    "supply_reward": 30,
                    "reward_id": "sealed_memory_folios",
                    "entry_direction": Vector2(-1.0, 0.18).normalized(),
                    "defend_target": "supply_pod",
                },
                _archive_phase_rules(),
                FLOODED_ARCHIVE_BEHAVIORS
            )
        "storm_crown":
            return _profile(
                region_id,
                REGION_FLOODED_ARCHIVE,
                "침수 기록원 · 폭풍 왕관",
                "risk_channel",
                "seal_pressure_vault",
                "압력 금고 봉인",
                2,
                "res://assets/runtime/w18/environment_flooded_archive.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(120.0, -86.0), Vector2(248.0, -198.0), Vector2(392.0, -108.0), Vector2(516.0, -224.0), Vector2(630.0, -94.0), Vector2(710.0, 0.0)]),
                    "travel_speed": 82.0,
                    "threat_level": 3,
                    "supply_cost": 16,
                    "supply_reward": 6,
                    "reward_id": "storm_index_core",
                    "entry_direction": Vector2(1.0, -0.22).normalized(),
                    "defend_target": "ark_core",
                },
                _archive_phase_rules(),
                FLOODED_ARCHIVE_BEHAVIORS
            )
        "afterglow_frontier":
            return _profile(
                region_id,
                REGION_ASH_RAILWAY,
                "재의 철도 · 잔광 분기점",
                "supply_causeway",
                "reignite_signal_chain",
                "신호 연쇄 재점화",
                2,
                "res://assets/runtime/w19/environment_ash_railway.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(104.0, 76.0), Vector2(214.0, -26.0), Vector2(326.0, 94.0), Vector2(458.0, 18.0), Vector2(594.0, 126.0), Vector2(736.0, 0.0)]),
                    "travel_speed": 62.0,
                    "threat_level": 2,
                    "supply_cost": 12,
                    "supply_reward": 32,
                    "reward_id": "signal_coal_reserve",
                    "entry_direction": Vector2(-1.0, 0.30).normalized(),
                    "defend_target": "signal_carriage",
                },
                _ash_phase_rules(),
                ASH_RAILWAY_BEHAVIORS,
                {
                    "choice_id": "deep_rescue_patrol",
                    "persistent_axis": "residents",
                    "horizontal_unlock": "rescue_network",
                    "access_right": "post_final_patrol",
                    "support_id": "veteran_rescuers",
                    "shop_modifier": "legacy_exchange",
                    "threat_route": "frontier_pressure",
                    "failure_contract": "recoverable_no_dead_end",
                }
            )
        "far_lantern_chain":
            return _profile(
                region_id,
                REGION_ECLIPSE_FORTRESS,
                "식의 성채 · 원환 관문",
                "risk_channel",
                "break_eclipse_seal",
                "식 봉인 파쇄",
                3,
                "res://assets/runtime/w19/environment_eclipse_fortress.svg",
                {
                    "points": PackedVector2Array([Vector2.ZERO, Vector2(112.0, -124.0), Vector2(246.0, -168.0), Vector2(318.0, -44.0), Vector2(472.0, -194.0), Vector2(612.0, -136.0), Vector2(762.0, 0.0)]),
                    "travel_speed": 92.0,
                    "threat_level": 3,
                    "supply_cost": 18,
                    "supply_reward": 8,
                    "reward_id": "eclipse_gate_sigil",
                    "entry_direction": Vector2(1.0, -0.34).normalized(),
                    "defend_target": "ark_core",
                },
                _fortress_phase_rules(),
                ECLIPSE_FORTRESS_BEHAVIORS,
                {
                    "choice_id": "lighthouse_survey",
                    "persistent_axis": "lighthouse",
                    "horizontal_unlock": "survey_beacon",
                    "access_right": "post_final_survey",
                    "support_id": "survey_fleet",
                    "shop_modifier": "rare_circuit_stock",
                    "threat_route": "anomaly_pressure",
                    "failure_contract": "recoverable_no_dead_end",
                }
            )
    return {}


static func catalog_counts() -> Dictionary:
    return {
        "parent_regions": parent_region_ids().size(),
        "subregion_route_profiles": region_ids().size(),
        "phase_states_per_region": 2,
        "enemy_behavior_definitions": _unique_behavior_count(GLASS_GARDEN_BEHAVIORS + FLOODED_ARCHIVE_BEHAVIORS),
        "environment_assets": 2,
    }


static func w19_catalog_counts() -> Dictionary:
    return {
        "parent_regions": w19_parent_region_ids().size(),
        "subregion_route_profiles": w19_region_ids().size(),
        "phase_states_per_region": 2,
        "enemy_behavior_definitions": _unique_behavior_count(ASH_RAILWAY_BEHAVIORS + ECLIPSE_FORTRESS_BEHAVIORS),
        "environment_assets": 2,
        "persistent_world_connections": 2,
    }


static func full_catalog_counts() -> Dictionary:
    return {
        "parent_regions": all_parent_region_ids().size(),
        "subregion_route_profiles": all_region_ids().size(),
        "phase_states_per_region": 2,
        "enemy_behavior_definitions": _unique_behavior_count(GLASS_GARDEN_BEHAVIORS + FLOODED_ARCHIVE_BEHAVIORS + ASH_RAILWAY_BEHAVIORS + ECLIPSE_FORTRESS_BEHAVIORS),
        "environment_assets": 4,
        "persistent_world_connections": 2,
    }


static func validate_profile(profile: Dictionary) -> bool:
    if profile.is_empty():
        return false
    var parent_region_id := str(profile.get("parent_region_id", ""))
    if not all_parent_region_ids().has(parent_region_id):
        return false
    if not ["risk_channel", "supply_causeway"].has(str(profile.get("route_id", ""))):
        return false
    var route: Variant = profile.get("route_config", null)
    var phases: Variant = profile.get("phase_rules", null)
    var enemies: Variant = profile.get("enemy_behaviors", null)
    if not route is Dictionary or not phases is Dictionary or not enemies is Array:
        return false
    var points: Variant = route.get("points", null)
    if not points is PackedVector2Array or points.size() < 2:
        return false
    if not phases.has(PHASE_MATERIAL) or not phases.has(PHASE_SHADOW):
        return false
    if enemies.size() != 6 or int(profile.get("required_circuits", 0)) <= 0:
        return false
    if w19_parent_region_ids().has(parent_region_id):
        var connection: Variant = profile.get("world_connection", null)
        if not connection is Dictionary or not _validate_world_connection(connection):
            return false
    return true


static func _profile(
    region_id: String,
    parent_region_id: String,
    display_name: String,
    route_id: String,
    objective_id: String,
    objective_label: String,
    required_circuits: int,
    background_asset: String,
    route_config: Dictionary,
    phase_rules: Dictionary,
    enemy_behaviors: Array,
    world_connection: Dictionary = {}
) -> Dictionary:
    return {
        "region_id": region_id,
        "parent_region_id": parent_region_id,
        "display_name": display_name,
        "route_id": route_id,
        "objective_id": objective_id,
        "objective_label": objective_label,
        "required_circuits": required_circuits,
        "requires_both_phases": true,
        "background_asset": background_asset,
        "route_config": route_config.duplicate(true),
        "phase_rules": phase_rules.duplicate(true),
        "enemy_behaviors": enemy_behaviors.duplicate(true),
        "world_connection": world_connection.duplicate(true),
    }


static func _validate_world_connection(connection: Dictionary) -> bool:
    for key: String in ["choice_id", "persistent_axis", "horizontal_unlock", "access_right", "support_id", "shop_modifier", "threat_route", "failure_contract"]:
        if str(connection.get(key, "")).is_empty():
            return false
    return str(connection.get("failure_contract", "")) == "recoverable_no_dead_end"


static func _unique_behavior_count(behaviors: Array) -> int:
    var behavior_ids: Array[String] = []
    for raw_behavior: Variant in behaviors:
        if not raw_behavior is Dictionary:
            continue
        var behavior_id := str((raw_behavior as Dictionary).get("behavior_id", ""))
        if not behavior_id.is_empty() and not behavior_ids.has(behavior_id):
            behavior_ids.append(behavior_id)
    return behavior_ids.size()


static func _glass_phase_rules() -> Dictionary:
    return {
        PHASE_MATERIAL: {"hazard_id": "sunlit_shards", "terrain_rule": "solid_prism_lanes", "counterplay": "use cover before closing a circuit"},
        PHASE_SHADOW: {"hazard_id": "mirror_roots", "terrain_rule": "shadow_root_detours", "counterplay": "switch after checking flank warnings"},
    }


static func _archive_phase_rules() -> Dictionary:
    return {
        PHASE_MATERIAL: {"hazard_id": "flood_current", "terrain_rule": "visible_archive_columns", "counterplay": "cross currents at column breaks"},
        PHASE_SHADOW: {"hazard_id": "memory_undertow", "terrain_rule": "submerged_memory_lanes", "counterplay": "use phase preview before entering undertow pockets"},
    }


static func _ash_phase_rules() -> Dictionary:
    return {
        PHASE_MATERIAL: {"hazard_id": "ember_switchline", "terrain_rule": "live_rail_switchbacks", "counterplay": "read signal arms before entering the next rail fan"},
        PHASE_SHADOW: {"hazard_id": "cinder_sink", "terrain_rule": "ghost_trestle_gaps", "counterplay": "preview the missing trestle before committing to shadow"},
    }


static func _fortress_phase_rules() -> Dictionary:
    return {
        PHASE_MATERIAL: {"hazard_id": "corona_lockbeam", "terrain_rule": "bastion_firing_corridors", "counterplay": "cross during the lockbeam charge window"},
        PHASE_SHADOW: {"hazard_id": "umbra_portcullis", "terrain_rule": "shadow_gate_crossfire", "counterplay": "switch only after a safe gate pocket is visible"},
    }
