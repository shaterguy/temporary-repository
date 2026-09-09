extends RefCounted

const SCHEMA_VERSION: int = 1
const MAX_ENERGY_BUDGET: int = 7
const MAX_CHAIN_DEPTH: int = 3

const TRIGGERS := {
    "steady_fire": {"event": "auto_attack", "cost": 1, "label": "등화 연사", "deliveries": ["lantern_bolt", "halo_orbit", "chain_arc", "fan_shards"]},
    "dodge_release": {"event": "dodge_started", "cost": 2, "label": "회피 잔광", "deliveries": ["piercing_lance", "lantern_bolt", "radiant_pulse", "fan_shards"]},
    "circuit_birth": {"event": "circuit_activated", "cost": 2, "label": "회로 폐합", "deliveries": ["radiant_pulse", "chain_arc", "halo_orbit"]},
    "phase_entry": {"event": "phase_changed", "cost": 2, "label": "위상 진입", "deliveries": ["piercing_lance", "lantern_bolt", "halo_orbit"]},
    "ark_pressure": {"event": "ark_pressure", "cost": 2, "label": "방주 압력", "deliveries": ["radiant_pulse", "chain_arc", "fan_shards"]},
    "hit_confirmed": {"event": "hit_confirmed", "cost": 2, "label": "명중 연쇄", "deliveries": ["lantern_bolt", "chain_arc", "fan_shards"]},
}

const DELIVERIES := {
    "piercing_lance": {"cost": 3, "label": "관통창", "damage_multiplier": 1.00, "max_targets": 2},
    "lantern_bolt": {"cost": 2, "label": "등화탄", "damage_multiplier": 1.00, "max_targets": 1},
    "halo_orbit": {"cost": 3, "label": "호위 궤도", "damage_multiplier": 0.90, "max_targets": 2},
    "radiant_pulse": {"cost": 4, "label": "광맥 충격", "damage_multiplier": 0.72, "max_targets": 4},
    "chain_arc": {"cost": 3, "label": "연쇄 섬광", "damage_multiplier": 0.86, "max_targets": 3},
    "fan_shards": {"cost": 3, "label": "부채 파편", "damage_multiplier": 0.76, "max_targets": 3},
}

const TRANSFORMS := {
    "circuit_split": {"cost": 2, "label": "회로 경계 분열", "deliveries": ["piercing_lance", "lantern_bolt", "chain_arc"], "condition": "crosses_circuit_boundary"},
    "shadow_fracture": {"cost": 2, "label": "그림자 파쇄", "deliveries": ["lantern_bolt", "halo_orbit", "chain_arc"], "condition": "shadow_phase"},
    "material_anchor": {"cost": 1, "label": "물질 정박", "deliveries": ["piercing_lance", "radiant_pulse", "fan_shards"], "condition": "material_phase"},
    "ricochet_once": {"cost": 2, "label": "단발 도약", "deliveries": ["lantern_bolt", "chain_arc", "fan_shards"], "condition": "always"},
    "ember_mark": {"cost": 1, "label": "잔화 표식", "deliveries": ["piercing_lance", "lantern_bolt", "halo_orbit", "fan_shards"], "condition": "always"},
    "snare_resonance": {"cost": 2, "label": "구속 공명", "deliveries": ["radiant_pulse", "chain_arc", "fan_shards"], "condition": "snare_circuit_active"},
    "ark_resonance": {"cost": 2, "label": "방주 공명", "deliveries": ["halo_orbit", "radiant_pulse", "chain_arc"], "condition": "ark_pressure_active"},
    "phase_afterglow": {"cost": 2, "label": "위상 잔광", "deliveries": ["piercing_lance", "halo_orbit", "fan_shards"], "condition": "phase_transition_recent"},
}

const CURATED_WEAPONS := {
    "sunwake_lance": {"label": "해뜸 관통창", "trigger": "dodge_release", "delivery": "piercing_lance", "transform": "circuit_split", "base_damage": 14, "purpose": "회피 경로를 회로 경계와 겹쳐 다중 표적을 찌르는 기동 무장"},
    "shade_halo": {"label": "그늘 고리", "trigger": "steady_fire", "delivery": "halo_orbit", "transform": "shadow_fracture", "base_damage": 12, "purpose": "그림자 위상에서 화력을 높여 위상 선택을 공격 결정으로 바꾸는 호위 무장"},
    "arklight_arc": {"label": "방주 섬광사슬", "trigger": "steady_fire", "delivery": "chain_arc", "transform": "ark_resonance", "base_damage": 11, "purpose": "방주 압박 중 연쇄 화력을 강화하는 호위 특화 무장"},
}


static func recipe_for_weapon(weapon_id: String) -> Dictionary:
    if not CURATED_WEAPONS.has(weapon_id):
        return {}
    return CURATED_WEAPONS[weapon_id].duplicate(true)


static func recipe_cost(recipe: Dictionary) -> int:
    var trigger_id := str(recipe.get("trigger", ""))
    var delivery_id := str(recipe.get("delivery", ""))
    var transform_id := str(recipe.get("transform", ""))
    if not TRIGGERS.has(trigger_id) or not DELIVERIES.has(delivery_id) or not TRANSFORMS.has(transform_id):
        return -1
    return int(TRIGGERS[trigger_id].get("cost", 0)) + int(DELIVERIES[delivery_id].get("cost", 0)) + int(TRANSFORMS[transform_id].get("cost", 0))


static func validate_recipe(recipe: Dictionary) -> Dictionary:
    var trigger_id := str(recipe.get("trigger", ""))
    var delivery_id := str(recipe.get("delivery", ""))
    var transform_id := str(recipe.get("transform", ""))
    if not TRIGGERS.has(trigger_id):
        return {"valid": false, "reason": "unknown_trigger", "cost": -1}
    if not DELIVERIES.has(delivery_id):
        return {"valid": false, "reason": "unknown_delivery", "cost": -1}
    if not TRANSFORMS.has(transform_id):
        return {"valid": false, "reason": "unknown_transform", "cost": -1}
    var trigger: Dictionary = TRIGGERS[trigger_id]
    if delivery_id not in trigger.get("deliveries", []):
        return {"valid": false, "reason": "trigger_delivery_incompatible", "cost": recipe_cost(recipe)}
    var transform: Dictionary = TRANSFORMS[transform_id]
    if delivery_id not in transform.get("deliveries", []):
        return {"valid": false, "reason": "delivery_transform_incompatible", "cost": recipe_cost(recipe)}
    var cost := recipe_cost(recipe)
    if cost > MAX_ENERGY_BUDGET:
        return {"valid": false, "reason": "energy_budget", "cost": cost}
    return {"valid": true, "reason": "", "cost": cost, "max_energy": MAX_ENERGY_BUDGET, "max_chain_depth": MAX_CHAIN_DEPTH}


static func catalog_counts() -> Dictionary:
    return {"triggers": TRIGGERS.size(), "deliveries": DELIVERIES.size(), "transforms": TRANSFORMS.size(), "curated_weapons": CURATED_WEAPONS.size()}
