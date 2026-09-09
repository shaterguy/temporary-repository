class_name CharacterRoleModel
extends RefCounted

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")

const CIRCUIT_MAX_CHARGES: int = 2
const PHASE_MAX_CHARGES: int = 2
const ENGINEER_ATTACKS_PER_REPAIR: int = 4
const ENGINEER_REPAIR_AMOUNT: int = 8
const CLOSE_ESCORT_RADIUS: float = 220.0
const ENGINEER_RADIUS: float = 300.0
const OBSERVER_RANGE: float = 720.0

var character_id: String = ""
var role_id: String = ""
var circuit_charges: int = 0
var phase_charges: int = 0
var engineer_attack_count: int = 0
var _last_cause_id: String = ""
var _last_modifiers: Dictionary = {}


func configure(definition: Dictionary) -> bool:
    var next_character_id := str(definition.get("id", ""))
    var next_role_id := str(definition.get("role_id", ""))
    if next_character_id.is_empty() or next_role_id.is_empty():
        return false
    character_id = next_character_id
    role_id = next_role_id
    reset_runtime()
    return true


func reset_runtime() -> void:
    circuit_charges = 0
    phase_charges = 0
    engineer_attack_count = 0
    _last_cause_id = ""
    _last_modifiers = {}


func on_circuit_activated() -> Dictionary:
    if role_id != CharacterCatalogScript.ROLE_CIRCUIT_ARCHITECT:
        return {"applied": false, "charges": circuit_charges}
    var before := circuit_charges
    circuit_charges = mini(CIRCUIT_MAX_CHARGES, circuit_charges + 1)
    return {
        "applied": circuit_charges > before,
        "charges": circuit_charges,
        "max_charges": CIRCUIT_MAX_CHARGES,
    }


func on_phase_changed() -> Dictionary:
    if role_id != CharacterCatalogScript.ROLE_PHASE_SCOUT:
        return {"applied": false, "charges": phase_charges}
    phase_charges = PHASE_MAX_CHARGES
    return {
        "applied": true,
        "charges": phase_charges,
        "max_charges": PHASE_MAX_CHARGES,
    }


func attack_modifiers(cause_id: String, near_ark: bool) -> Dictionary:
    if not cause_id.is_empty() and cause_id == _last_cause_id and not _last_modifiers.is_empty():
        var repeated := _last_modifiers.duplicate(true)
        repeated["first_for_cause"] = false
        repeated["repair_amount"] = 0
        repeated["observer_followup_scale"] = 0.0
        return repeated

    var damage_multiplier := 1.0
    var repair_amount := 0
    var observer_followup_scale := 0.0

    match role_id:
        CharacterCatalogScript.ROLE_CIRCUIT_ARCHITECT:
            if circuit_charges > 0:
                circuit_charges -= 1
                damage_multiplier = 1.35
        CharacterCatalogScript.ROLE_CLOSE_ESCORT:
            if near_ark:
                damage_multiplier = 1.20
        CharacterCatalogScript.ROLE_ARK_ENGINEER:
            if near_ark:
                engineer_attack_count += 1
                if engineer_attack_count >= ENGINEER_ATTACKS_PER_REPAIR:
                    engineer_attack_count = 0
                    repair_amount = ENGINEER_REPAIR_AMOUNT
        CharacterCatalogScript.ROLE_PHASE_SCOUT:
            if phase_charges > 0:
                phase_charges -= 1
                damage_multiplier = 1.30
        CharacterCatalogScript.ROLE_RANGED_OBSERVER:
            observer_followup_scale = 0.55

    var modifiers := {
        "damage_multiplier": damage_multiplier,
        "repair_amount": repair_amount,
        "observer_followup_scale": observer_followup_scale,
        "first_for_cause": true,
        "circuit_charges": circuit_charges,
        "phase_charges": phase_charges,
        "engineer_attack_count": engineer_attack_count,
    }
    _last_cause_id = cause_id
    _last_modifiers = modifiers.duplicate(true)
    return modifiers


func incoming_armor_bonus(near_ark: bool) -> int:
    if role_id == CharacterCatalogScript.ROLE_CLOSE_ESCORT and near_ark:
        return 3
    return 0


func echo_damage_multiplier() -> float:
    if role_id == CharacterCatalogScript.ROLE_ECHO_RECORDER:
        return 1.50
    return 1.0


func ark_interaction_radius() -> float:
    match role_id:
        CharacterCatalogScript.ROLE_CLOSE_ESCORT:
            return CLOSE_ESCORT_RADIUS
        CharacterCatalogScript.ROLE_ARK_ENGINEER:
            return ENGINEER_RADIUS
    return 0.0


func observer_range() -> float:
    return OBSERVER_RANGE if role_id == CharacterCatalogScript.ROLE_RANGED_OBSERVER else 0.0


func status_snapshot() -> Dictionary:
    return {
        "character_id": character_id,
        "role_id": role_id,
        "circuit_charges": circuit_charges,
        "phase_charges": phase_charges,
        "engineer_attack_count": engineer_attack_count,
        "ark_interaction_radius": ark_interaction_radius(),
        "echo_damage_multiplier": echo_damage_multiplier(),
        "observer_range": observer_range(),
    }
