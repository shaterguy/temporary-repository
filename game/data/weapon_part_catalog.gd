extends RefCounted

const SCHEMA_VERSION: int = 2
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
    "sunwake_lance": {"label": "해뜸 관통창", "trigger": "dodge_release", "delivery": "piercing_lance", "transform": "circuit_split", "base_damage": 14, "handling": "회피 직후 회로 경계를 가르는 선형 다중 타격", "purpose": "회피 경로를 회로 경계와 겹쳐 다중 표적을 찌르는 기동 무장"},
    "shade_halo": {"label": "그늘 고리", "trigger": "steady_fire", "delivery": "halo_orbit", "transform": "shadow_fracture", "base_damage": 12, "handling": "안정적인 자동 호위 궤도와 그림자 위상 폭발력", "purpose": "그림자 위상에서 화력을 높여 위상 선택을 공격 결정으로 바꾸는 호위 무장"},
    "arklight_arc": {"label": "방주 섬광사슬", "trigger": "steady_fire", "delivery": "chain_arc", "transform": "ark_resonance", "base_damage": 11, "handling": "방주 압박 시 강화되는 연쇄 자동 공격", "purpose": "방주 압박 중 연쇄 화력을 강화하는 호위 특화 무장"},
    "ember_bolt": {"label": "잔화 등화탄", "trigger": "steady_fire", "delivery": "lantern_bolt", "transform": "ember_mark", "base_damage": 15, "handling": "단일 표적에 잔화 표식을 남기는 직선 화력", "purpose": "낮은 에너지 비용으로 표식 기반 후속 선택을 여는 단일 대상 무장"},
    "scatter_ricochet": {"label": "산란 도약편", "trigger": "steady_fire", "delivery": "fan_shards", "transform": "ricochet_once", "base_damage": 10, "handling": "부채형 다중 타격이 한 표적 더 도약하는 군중 제어", "purpose": "좁은 군집에서 대상 수를 늘려 압박을 분산하는 확산 무장"},
    "circuit_pulse": {"label": "회로 광맥파", "trigger": "circuit_birth", "delivery": "radiant_pulse", "transform": "material_anchor", "base_damage": 13, "handling": "회로 폐합 순간 물질 위상 광역 충격", "purpose": "회로를 공격 타이밍으로 전환해 물질 위상 군집을 정리하는 광역 무장"},
    "snare_chain": {"label": "구속 섬광사슬", "trigger": "circuit_birth", "delivery": "chain_arc", "transform": "snare_resonance", "base_damage": 12, "handling": "구속 회로와 결합할수록 강해지는 연쇄 타격", "purpose": "N02 구속 회로와 직접 시너지를 내는 제어-화력 결합 무장"},
    "ward_halo": {"label": "방벽 호위고리", "trigger": "circuit_birth", "delivery": "halo_orbit", "transform": "ark_resonance", "base_damage": 11, "handling": "회로 생성 뒤 방주 압박에 반응하는 호위 궤도", "purpose": "방주 주변 수비 동선을 회로와 호위 화력으로 묶는 방어형 무장"},
    "phase_lance": {"label": "잔광 위상창", "trigger": "phase_entry", "delivery": "piercing_lance", "transform": "phase_afterglow", "base_damage": 14, "handling": "위상 진입 직후 직선 관통으로 전환하는 폭발적 개시", "purpose": "N07 위상 전환 직후의 짧은 창구를 공격 기회로 바꾸는 관통 무장"},
    "dusk_bolt": {"label": "황혼 균열탄", "trigger": "phase_entry", "delivery": "lantern_bolt", "transform": "shadow_fracture", "base_damage": 16, "handling": "그림자 위상 진입에 집중된 고화력 단일 사격", "purpose": "그림자 위상 진입을 정예 표적 제거 타이밍으로 만드는 단일 대상 무장"},
    "phase_halo": {"label": "위상 잔화고리", "trigger": "phase_entry", "delivery": "halo_orbit", "transform": "ember_mark", "base_damage": 12, "handling": "위상 진입 주변을 돌며 표식을 누적하는 호위형 개시", "purpose": "위상 전환 직후 근접 위험을 밀어내고 표식 후속 선택을 준비하는 무장"},
    "pressure_fan": {"label": "압력 정박편", "trigger": "ark_pressure", "delivery": "fan_shards", "transform": "material_anchor", "base_damage": 13, "handling": "방주 압박 신호에 반응하는 물질 위상 부채 타격", "purpose": "방주가 압박받을 때 넓은 전면을 정리하는 구조 대응 무장"},
    "pressure_chain": {"label": "방주 공명사슬", "trigger": "ark_pressure", "delivery": "chain_arc", "transform": "ark_resonance", "base_damage": 12, "handling": "방주 압박 자체를 연쇄 공명으로 증폭", "purpose": "호위 실패 위험이 커질수록 군집 화력을 집중하는 고비용 호위 무장"},
    "confirmed_bolt": {"label": "확정 도약탄", "trigger": "hit_confirmed", "delivery": "lantern_bolt", "transform": "ricochet_once", "base_damage": 14, "handling": "명중 확인 뒤 단일탄이 한 번 더 도약", "purpose": "연속 명중을 작은 연쇄로 전환해 정예 주변의 보조 표적을 정리하는 무장"},
    "confirmed_chain": {"label": "확정 그림자사슬", "trigger": "hit_confirmed", "delivery": "chain_arc", "transform": "shadow_fracture", "base_damage": 12, "handling": "그림자 위상에서 명중 연쇄가 강화되는 추격형 타격", "purpose": "그림자 위상에서 안정적인 명중을 광역 추격 화력으로 전환하는 무장"},
    "confirmed_fan": {"label": "확정 잔화편", "trigger": "hit_confirmed", "delivery": "fan_shards", "transform": "ember_mark", "base_damage": 11, "handling": "명중 후 넓게 표식을 흩뿌리는 후속 확산", "purpose": "한 표적의 명중을 주변 표식 확산으로 연결하는 후속 공격 무장"},
    "dodge_fan": {"label": "회피 잔광편", "trigger": "dodge_release", "delivery": "fan_shards", "transform": "phase_afterglow", "base_damage": 11, "handling": "회피 직후 넓게 퍼지는 위상 잔광 파편", "purpose": "위상 전환 직후 회피를 넓은 탈출 화력으로 바꾸는 생존형 무장"},
    "dodge_bolt": {"label": "회로 절단탄", "trigger": "dodge_release", "delivery": "lantern_bolt", "transform": "circuit_split", "base_damage": 15, "handling": "회피 경로가 회로 경계를 넘을 때 단일탄이 분열", "purpose": "정밀 회피와 회로 배치를 결합해 단일 화력을 선택적으로 확장하는 무장"},
}


static func recipe_for_weapon(weapon_id: String) -> Dictionary:
    if not CURATED_WEAPONS.has(weapon_id):
        return {}
    return CURATED_WEAPONS[weapon_id].duplicate(true)


static func weapon_ids() -> Array[String]:
    var ids: Array[String] = []
    for raw_id in CURATED_WEAPONS.keys():
        ids.append(str(raw_id))
    return ids


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


static func choice_card(weapon_id: String) -> Dictionary:
    var recipe := recipe_for_weapon(weapon_id)
    if recipe.is_empty():
        return {}
    var trigger_id := str(recipe.get("trigger", ""))
    var delivery_id := str(recipe.get("delivery", ""))
    var transform_id := str(recipe.get("transform", ""))
    var transform: Dictionary = TRANSFORMS.get(transform_id, {})
    return {
        "id": weapon_id,
        "label": str(recipe.get("label", weapon_id)),
        "trigger": trigger_id,
        "trigger_label": str(TRIGGERS.get(trigger_id, {}).get("label", trigger_id)),
        "delivery": delivery_id,
        "delivery_label": str(DELIVERIES.get(delivery_id, {}).get("label", delivery_id)),
        "transform": transform_id,
        "transform_label": str(transform.get("label", transform_id)),
        "condition": str(transform.get("condition", "always")),
        "base_damage": int(recipe.get("base_damage", 0)),
        "energy_cost": recipe_cost(recipe),
        "max_energy": MAX_ENERGY_BUDGET,
        "max_chain_depth": MAX_CHAIN_DEPTH,
        "handling": str(recipe.get("handling", "")),
        "purpose": str(recipe.get("purpose", "")),
    }


static func comparison(from_weapon_id: String, to_weapon_id: String) -> Dictionary:
    var current := recipe_for_weapon(from_weapon_id)
    var candidate := recipe_for_weapon(to_weapon_id)
    if candidate.is_empty():
        return {"valid": false, "reason": "unknown_weapon"}
    var validation := validate_recipe(candidate)
    if not bool(validation.get("valid", false)):
        return {"valid": false, "reason": str(validation.get("reason", "invalid_recipe"))}
    var changed: Array[String] = []
    for field in ["trigger", "delivery", "transform", "base_damage"]:
        if current.get(field) != candidate.get(field):
            changed.append(str(field))
    var card := choice_card(to_weapon_id)
    return {
        "valid": true,
        "from_weapon": from_weapon_id,
        "to_weapon": to_weapon_id,
        "changed_fields": changed,
        "energy_before": recipe_cost(current),
        "energy_after": recipe_cost(candidate),
        "energy_delta": recipe_cost(candidate) - recipe_cost(current),
        "base_damage_before": int(current.get("base_damage", 0)),
        "base_damage_after": int(candidate.get("base_damage", 0)),
        "condition": str(card.get("condition", "always")),
        "delivery_form": str(card.get("delivery_label", "")),
        "handling": str(card.get("handling", "")),
        "max_energy": MAX_ENERGY_BUDGET,
        "max_chain_depth": MAX_CHAIN_DEPTH,
    }


static func catalog_counts() -> Dictionary:
    return {"triggers": TRIGGERS.size(), "deliveries": DELIVERIES.size(), "transforms": TRANSFORMS.size(), "curated_weapons": CURATED_WEAPONS.size()}
