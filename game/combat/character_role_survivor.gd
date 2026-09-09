extends "res://game/combat/survivor_controller.gd"

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const CharacterRoleModelScript = preload("res://game/combat/character_role_model.gd")
const ArkRouteModelScript = preload("res://game/world/ark_route_model.gd")
const W23CombatModelScript = preload("res://game/combat/combat_model.gd")
const CHARACTER_VISUAL_SIZE := Vector2(48.0, 60.0)

signal character_role_event(event: Dictionary)

var role_model = CharacterRoleModelScript.new()
var _ark_provider: Node2D
var _character_texture: Texture2D
var _character_art_path: String = ""
var _character_art_status: String = ""


func _ready() -> void:
    super._ready()
    configure_character(CharacterCatalogScript.ID_AURORA)


func configure_character(character_id: String, ark_provider: Node2D = null) -> bool:
    var definition := CharacterCatalogScript.definition(character_id)
    if definition.is_empty() or not role_model.configure(definition):
        return false
    if not _load_character_visual(definition):
        return false
    if is_instance_valid(ark_provider):
        _ark_provider = ark_provider
    queue_redraw()
    character_role_event.emit({
        "type": "character_configured",
        "character_id": character_id,
        "role_id": str(definition.get("role_id", "")),
        "art_path": _character_art_path,
    })
    return true


func _load_character_visual(definition: Dictionary) -> bool:
    _character_art_path = str(definition.get("representative_art", ""))
    _character_art_status = str(definition.get("production_art_status", ""))
    _character_texture = null
    if _character_art_path.is_empty():
        return false
    var resource: Resource = load(_character_art_path)
    if not resource is Texture2D:
        return false
    _character_texture = resource as Texture2D
    return true


func character_visual_snapshot() -> Dictionary:
    return {
        "character_id": role_model.character_id,
        "role_id": role_model.role_id,
        "art_path": _character_art_path,
        "art_status": _character_art_status,
        "texture_loaded": _character_texture != null,
        "combat_size": CHARACTER_VISUAL_SIZE,
    }


func set_ark_provider(provider: Node2D) -> void:
    _ark_provider = provider


func character_status_snapshot() -> Dictionary:
    var snapshot := role_model.status_snapshot()
    var definition := CharacterCatalogScript.definition(role_model.character_id)
    snapshot["display_name"] = str(definition.get("display_name", role_model.character_id))
    snapshot["role_name"] = str(definition.get("role_name", role_model.role_id))
    snapshot["near_ark"] = _is_near_ark()
    snapshot["art_path"] = _character_art_path
    snapshot["art_status"] = _character_art_status
    return snapshot


func reset_character_runtime() -> void:
    role_model.reset_runtime()
    queue_redraw()


func on_circuit_activated(circuit_id: int, module_id: String) -> Dictionary:
    var result := role_model.on_circuit_activated()
    if bool(result.get("applied", false)):
        character_role_event.emit({
            "type": "circuit_charge_gained",
            "circuit_id": circuit_id,
            "module_id": module_id,
            "charges": int(result.get("charges", 0)),
        })
    return result


func on_phase_changed(phase_id: String) -> Dictionary:
    var result := role_model.on_phase_changed()
    if bool(result.get("applied", false)):
        character_role_event.emit({
            "type": "phase_charge_gained",
            "phase_id": phase_id,
            "charges": int(result.get("charges", 0)),
        })
    return result


func take_damage(raw_damage: int, armor: int = 0) -> Dictionary:
    var bonus_armor := role_model.incoming_armor_bonus(_is_near_ark())
    var result := super.take_damage(raw_damage, armor + bonus_armor)
    if bonus_armor > 0 and int(result.get("applied_damage", 0)) > 0:
        character_role_event.emit({
            "type": "escort_guard",
            "bonus_armor": bonus_armor,
            "applied_damage": int(result.get("applied_damage", 0)),
        })
    return result


func _apply_weapon_action(action: Dictionary, targets: Array[Dictionary]) -> void:
    if str(action.get("type", "")) != "weapon_damage":
        super._apply_weapon_action(action, targets)
        return

    var adjusted := action.duplicate(true)
    var modifiers := role_model.attack_modifiers(
        str(action.get("cause_id", "")),
        _is_near_ark()
    )
    var damage_multiplier := float(modifiers.get("damage_multiplier", 1.0))
    adjusted["damage"] = maxi(1, roundi(float(action.get("damage", 0)) * damage_multiplier))
    super._apply_weapon_action(adjusted, targets)

    if bool(modifiers.get("first_for_cause", false)):
        var repair_amount := int(modifiers.get("repair_amount", 0))
        if repair_amount > 0:
            var repaired := _repair_ark(repair_amount)
            if repaired > 0:
                character_role_event.emit({
                    "type": "ark_field_repair",
                    "repaired": repaired,
                })

        var observer_scale := float(modifiers.get("observer_followup_scale", 0.0))
        if observer_scale > 0.0:
            var followup := _apply_observer_followup(adjusted, targets, observer_scale)
            if bool(followup.get("hit", false)):
                character_role_event.emit(followup)

    if damage_multiplier > 1.0001:
        character_role_event.emit({
            "type": "role_damage_boost",
            "cause_id": str(action.get("cause_id", "")),
            "multiplier": damage_multiplier,
            "damage": int(adjusted.get("damage", 0)),
        })


func _apply_tactical_echo_fire(action: Dictionary) -> Dictionary:
    var multiplier := role_model.echo_damage_multiplier()
    if multiplier <= 1.0001:
        return super._apply_tactical_echo_fire(action)

    var adjusted := action.duplicate(true)
    adjusted["damage"] = maxi(1, roundi(float(action.get("damage", 1)) * multiplier))
    var result := super._apply_tactical_echo_fire(adjusted)
    if bool(result.get("hit", false)):
        character_role_event.emit({
            "type": "echo_recorder_boost",
            "target_id": int(result.get("target_id", -1)),
            "damage": int(adjusted.get("damage", 0)),
            "multiplier": multiplier,
        })
    return result


func _is_near_ark() -> bool:
    if not is_instance_valid(_ark_provider):
        return false
    var radius := role_model.ark_interaction_radius()
    if radius <= 0.0:
        return false
    return global_position.distance_to(_ark_provider.global_position) <= radius


func _repair_ark(requested_amount: int) -> int:
    if requested_amount <= 0 or not is_instance_valid(_ark_provider):
        return 0
    var ark_model: Variant = _ark_provider.get("model")
    if ark_model == null:
        return 0
    if str(ark_model.get("status")) == ArkRouteModelScript.STATUS_FAILED_RECOVERABLE:
        return 0
    var before := int(ark_model.get("durability"))
    var after := mini(ArkRouteModelScript.MAX_DURABILITY, before + requested_amount)
    if after <= before:
        return 0
    ark_model.set("durability", after)
    _ark_provider.queue_redraw()
    return after - before


func _apply_observer_followup(
    primary_action: Dictionary,
    targets: Array[Dictionary],
    damage_scale: float
) -> Dictionary:
    var max_range := role_model.observer_range()
    if max_range <= 0.0 or damage_scale <= 0.0:
        return {"type": "observer_followup", "hit": false, "reason": "inactive"}

    var primary_id := int(primary_action.get("target_id", -1))
    var best_id := -1
    var best_distance := -1.0
    for target in targets:
        if not bool(target.get("active", true)):
            continue
        var target_id := int(target.get("id", -1))
        if target_id < 0 or target_id == primary_id:
            continue
        var target_position_value: Variant = target.get("position", null)
        if not target_position_value is Vector2:
            continue
        var target_position: Vector2 = target_position_value
        var distance: float = float(model.position.distance_to(target_position))
        if distance > max_range:
            continue
        if distance > best_distance + 0.0001 or (is_equal_approx(distance, best_distance) and target_id < best_id):
            best_id = target_id
            best_distance = distance

    if best_id < 0:
        return {"type": "observer_followup", "hit": false, "reason": "no_secondary_target"}

    var damage := maxi(1, roundi(float(primary_action.get("damage", 1)) * damage_scale))
    var handled := false
    if is_instance_valid(_target_provider) and _target_provider.has_method("apply_target_damage"):
        handled = bool(_target_provider.call("apply_target_damage", best_id, damage))
    if not handled:
        var target_object := instance_from_id(best_id)
        if target_object != null and is_instance_valid(target_object) and target_object.has_method("take_damage"):
            target_object.call("take_damage", damage)
            handled = true

    return {
        "type": "observer_followup",
        "hit": handled,
        "target_id": best_id,
        "damage": damage,
        "distance": best_distance,
        "non_recursive": true,
    }


func _draw() -> void:
    super._draw()
    if _character_texture != null:
        draw_texture_rect(
            _character_texture,
            Rect2(-CHARACTER_VISUAL_SIZE * 0.5, CHARACTER_VISUAL_SIZE),
            false
        )
        var health_ratio := clampf(
            float(model.health) / float(W23CombatModelScript.MAX_HEALTH),
            0.0,
            1.0
        )
        draw_arc(
            Vector2.ZERO,
            35.0,
            -PI * 0.5,
            -PI * 0.5 + TAU * health_ratio,
            32,
            Color(1.0, 0.93, 0.70, 0.95),
            3.0,
            true
        )
    var ring_color := Color(0.78, 0.88, 1.0, 0.88)
    match role_model.role_id:
        CharacterCatalogScript.ROLE_CIRCUIT_ARCHITECT:
            ring_color = Color(0.42, 0.92, 0.92, 0.90)
        CharacterCatalogScript.ROLE_CLOSE_ESCORT:
            ring_color = Color(1.0, 0.48, 0.25, 0.90)
        CharacterCatalogScript.ROLE_ARK_ENGINEER:
            ring_color = Color(0.96, 0.78, 0.30, 0.90)
        CharacterCatalogScript.ROLE_PHASE_SCOUT:
            ring_color = Color(0.60, 0.46, 1.0, 0.90)
        CharacterCatalogScript.ROLE_ECHO_RECORDER:
            ring_color = Color(0.78, 0.48, 0.96, 0.90)
        CharacterCatalogScript.ROLE_RANGED_OBSERVER:
            ring_color = Color(0.46, 0.86, 0.58, 0.90)
    draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 32, ring_color, 2.5, true)
