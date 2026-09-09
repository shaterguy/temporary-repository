extends RefCounted

const SCHEMA_VERSION: int = 1
const MAX_EQUIPPED_RELICS: int = 4
const MAX_DAMAGE_BONUS: float = 0.75
const MAX_FLAT_DAMAGE: int = 8
const MAX_EXTRA_TARGETS: int = 2
const MAX_BARRIER_PRESSURE: int = 12
const FAMILY_ORDER: Array[String] = ["wake", "shadow", "circuit", "ark", "phase", "chain", "mark", "navigation"]
const RELIC_FAMILIES := {
    "wake": {"label": "항적", "condition": "dodge_trigger", "purpose": "회피 연계"},
    "shadow": {"label": "그림자", "condition": "shadow_phase", "purpose": "그림자 위상 연계"},
    "circuit": {"label": "회로", "condition": "circuit_boundary", "purpose": "회로 경계 연계"},
    "ark": {"label": "방주", "condition": "ark_pressure", "purpose": "방주 압박 연계"},
    "phase": {"label": "잔광", "condition": "phase_transition", "purpose": "위상 전환 연계"},
    "chain": {"label": "연쇄", "condition": "chain_delivery", "purpose": "연쇄 전달 연계"},
    "mark": {"label": "표식", "condition": "ember_transform", "purpose": "잔화 표식 연계"},
    "navigation": {"label": "항로", "condition": "material_phase", "purpose": "물질 위상 연계"},
}
const EFFECT_VARIANTS := [
    {"suffix": "edge", "label": "날", "effect": "damage_pct", "magnitude": 0.08, "target_gate": "any", "tradeoff": "조건부 비율 보너스"},
    {"suffix": "nail", "label": "못", "effect": "flat_damage", "magnitude": 2.0, "target_gate": "any", "tradeoff": "대상 수 변화 없음"},
    {"suffix": "fork", "label": "갈래", "effect": "extra_targets", "magnitude": 1.0, "target_gate": "any", "tradeoff": "피해 계수 변화 없음"},
    {"suffix": "ward", "label": "방벽", "effect": "barrier_pressure", "magnitude": 3.0, "target_gate": "any", "tradeoff": "직접 피해 변화 없음"},
    {"suffix": "lens", "label": "렌즈", "effect": "damage_pct", "magnitude": 0.12, "target_gate": "single", "tradeoff": "단일 대상 전용"},
    {"suffix": "pulse", "label": "맥동", "effect": "flat_damage", "magnitude": 3.0, "target_gate": "multi", "tradeoff": "다중 대상 전용"},
]

static func relic_ids() -> Array[String]:
    var ids: Array[String] = []
    for family_id: String in FAMILY_ORDER:
        for raw_variant: Variant in EFFECT_VARIANTS:
            var variant: Dictionary = raw_variant
            ids.append("%s_%s" % [family_id, str(variant.get("suffix", ""))])
    return ids

static func definition(relic_id: String) -> Dictionary:
    for family_id: String in FAMILY_ORDER:
        var family: Dictionary = RELIC_FAMILIES.get(family_id, {})
        for raw_variant: Variant in EFFECT_VARIANTS:
            var variant: Dictionary = raw_variant
            if "%s_%s" % [family_id, str(variant.get("suffix", ""))] == relic_id:
                return {"id": relic_id, "label": "%s의 %s" % [str(family.get("label", family_id)), str(variant.get("label", "유물"))], "family": family_id, "family_label": str(family.get("label", family_id)), "condition": str(family.get("condition", "always")), "effect": str(variant.get("effect", "")), "magnitude": float(variant.get("magnitude", 0.0)), "target_gate": str(variant.get("target_gate", "any")), "tradeoff": str(variant.get("tradeoff", "")), "purpose": str(family.get("purpose", ""))}
    return {}

static func selection_card(relic_id: String) -> Dictionary:
    var relic: Dictionary = definition(relic_id)
    if relic.is_empty():
        return {}
    return {"id": relic_id, "label": str(relic.get("label", relic_id)), "family": str(relic.get("family", "")), "condition": str(relic.get("condition", "always")), "effect": str(relic.get("effect", "")), "magnitude": float(relic.get("magnitude", 0.0)), "target_gate": str(relic.get("target_gate", "any")), "tradeoff": str(relic.get("tradeoff", "")), "purpose": str(relic.get("purpose", "")), "max_equipped": MAX_EQUIPPED_RELICS, "hard_limits": hard_limits()}

static func validate_loadout(relic_ids_value: Array[String]) -> Dictionary:
    if relic_ids_value.size() > MAX_EQUIPPED_RELICS:
        return {"valid": false, "reason": "relic_slot_limit"}
    var seen_ids: Dictionary = {}
    var seen_families: Dictionary = {}
    for relic_id: String in relic_ids_value:
        var relic: Dictionary = definition(relic_id)
        if relic.is_empty():
            return {"valid": false, "reason": "unknown_relic", "relic_id": relic_id}
        if seen_ids.has(relic_id):
            return {"valid": false, "reason": "duplicate_relic", "relic_id": relic_id}
        var family_id: String = str(relic.get("family", ""))
        if seen_families.has(family_id):
            return {"valid": false, "reason": "family_conflict", "family": family_id}
        seen_ids[relic_id] = true
        seen_families[family_id] = true
    return {"valid": true, "reason": "", "equipped": relic_ids_value.duplicate()}

static func effect_summary(relic_ids_value: Array[String], recipe: Dictionary, context: Dictionary, selected_target_count: int) -> Dictionary:
    var validation: Dictionary = validate_loadout(relic_ids_value)
    if not bool(validation.get("valid", false)):
        return {"valid": false, "reason": str(validation.get("reason", "invalid_relic_loadout")), "damage_multiplier": 1.0, "flat_damage": 0, "extra_targets": 0, "barrier_pressure": 0, "activated_relic_ids": [], "disclosures": []}
    var damage_bonus: float = 0.0
    var flat_damage: int = 0
    var extra_targets: int = 0
    var barrier_pressure: int = 0
    var activated: Array[String] = []
    var disclosures: Array[Dictionary] = []
    for relic_id: String in relic_ids_value:
        var relic: Dictionary = definition(relic_id)
        if not _condition_met(str(relic.get("condition", "always")), recipe, context) or not _target_gate_met(str(relic.get("target_gate", "any")), selected_target_count):
            continue
        var effect_id: String = str(relic.get("effect", ""))
        var magnitude: float = float(relic.get("magnitude", 0.0))
        if effect_id == "damage_pct":
            damage_bonus += magnitude
        elif effect_id == "flat_damage":
            flat_damage += roundi(magnitude)
        elif effect_id == "extra_targets":
            extra_targets += roundi(magnitude)
        elif effect_id == "barrier_pressure":
            barrier_pressure += roundi(magnitude)
        activated.append(relic_id)
        disclosures.append(selection_card(relic_id))
    return {"valid": true, "reason": "", "damage_multiplier": 1.0 + clampf(damage_bonus, 0.0, MAX_DAMAGE_BONUS), "flat_damage": clampi(flat_damage, 0, MAX_FLAT_DAMAGE), "extra_targets": clampi(extra_targets, 0, MAX_EXTRA_TARGETS), "barrier_pressure": clampi(barrier_pressure, 0, MAX_BARRIER_PRESSURE), "activated_relic_ids": activated, "disclosures": disclosures}

static func hard_limits() -> Dictionary:
    return {"max_equipped_relics": MAX_EQUIPPED_RELICS, "max_damage_bonus": MAX_DAMAGE_BONUS, "max_flat_damage": MAX_FLAT_DAMAGE, "max_extra_targets": MAX_EXTRA_TARGETS, "max_barrier_pressure": MAX_BARRIER_PRESSURE, "chain_depth_immutable": true, "cause_identity_immutable": true}

static func catalog_counts() -> Dictionary:
    return {"families": FAMILY_ORDER.size(), "variants_per_family": EFFECT_VARIANTS.size(), "relics": relic_ids().size()}

static func _condition_met(condition_id: String, recipe: Dictionary, context: Dictionary) -> bool:
    if condition_id == "dodge_trigger":
        return str(recipe.get("trigger", "")) == "dodge_release"
    if condition_id == "shadow_phase":
        return str(context.get("phase", "material")) == "shadow"
    if condition_id == "circuit_boundary":
        return bool(context.get("crosses_circuit_boundary", false))
    if condition_id == "ark_pressure":
        return bool(context.get("ark_pressure_active", false)) or str(recipe.get("trigger", "")) == "ark_pressure"
    if condition_id == "phase_transition":
        return bool(context.get("phase_transition_recent", false)) or str(recipe.get("trigger", "")) == "phase_entry"
    if condition_id == "chain_delivery":
        return str(recipe.get("delivery", "")) == "chain_arc"
    if condition_id == "ember_transform":
        return str(recipe.get("transform", "")) == "ember_mark"
    if condition_id == "material_phase":
        return str(context.get("phase", "material")) == "material"
    return false

static func _target_gate_met(target_gate: String, selected_target_count: int) -> bool:
    if target_gate == "single":
        return selected_target_count <= 1
    if target_gate == "multi":
        return selected_target_count > 1
    return true
