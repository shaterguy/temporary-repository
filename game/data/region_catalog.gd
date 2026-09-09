extends RefCounted

const REGION_GLASS_GARDEN: String = "glass_garden"
const REGION_FLOODED_ARCHIVE: String = "flooded_archive"
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


static func region_ids() -> Array[String]:
    return ["brine_veins", "blackglass_spires", "drowned_archive", "storm_crown"]


static func parent_region_ids() -> Array[String]:
    return [REGION_GLASS_GARDEN, REGION_FLOODED_ARCHIVE]


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
    return {}


static func catalog_counts() -> Dictionary:
    var behavior_ids: Array[String] = []
    for raw_behavior in GLASS_GARDEN_BEHAVIORS + FLOODED_ARCHIVE_BEHAVIORS:
        var behavior: Dictionary = raw_behavior
        var behavior_id := str(behavior.get("behavior_id", ""))
        if not behavior_id.is_empty() and not behavior_ids.has(behavior_id):
            behavior_ids.append(behavior_id)
    return {
        "parent_regions": parent_region_ids().size(),
        "subregion_route_profiles": region_ids().size(),
        "phase_states_per_region": 2,
        "enemy_behavior_definitions": behavior_ids.size(),
        "environment_assets": 2,
    }


static func validate_profile(profile: Dictionary) -> bool:
    if profile.is_empty():
        return false
    if not parent_region_ids().has(str(profile.get("parent_region_id", ""))):
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
    return enemies.size() == 6 and int(profile.get("required_circuits", 0)) > 0


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
    enemy_behaviors: Array
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
    }


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
