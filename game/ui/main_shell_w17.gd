extends "res://game/ui/main_shell_w16.gd"

const W17WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const W17RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const W17BuildCatalogScript = preload("res://game/data/weapon_build_catalog.gd")
const W17ChoiceModelScript = preload("res://game/ui/weapon_relic_choice_model.gd")
const W17WeaponRelicSurvivorScript = preload("res://game/combat/weapon_relic_survivor.gd")
const W17SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const W17ArkConvoyScript = preload("res://game/world/ark_convoy.gd")
const W17LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const W17PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")

const W17_PLAYER_ORIGIN: Vector2 = Vector2(640.0, 360.0)
const W17_ARK_ORIGIN: Vector2 = Vector2(280.0, 360.0)

var selected_weapon_id: String = "shade_halo"
var selected_relic_ids: Array[String] = []
var selected_representative_build_index: int = -1
var _w17_last_ark_durability: int = -1
var _w17_ark_tracking_armed: bool = false


func _mount_runtime_preview() -> void:
    combat_preview = W17WeaponRelicSurvivorScript.new()
    combat_preview.name = "W17WeaponRelicSurvivorRuntime"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = W17_PLAYER_ORIGIN
    add_child(combat_preview)
    move_child(combat_preview, 1)
    combat_preview.connect("weapon_action", Callable(self, "_on_weapon_action"))

    ark_preview = W17ArkConvoyScript.new()
    ark_preview.name = "W17ArkRuntime"
    ark_preview.position = W17_ARK_ORIGIN
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))
    combat_preview.call("set_ark_provider", ark_preview)

    encounter_preview = W17SwarmEncounterScript.new()
    encounter_preview.name = "W17SwarmRuntime"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    encounter_preview.call("configure_player", combat_preview)
    encounter_preview.call("configure_escort_target", ark_preview)

    circuit_preview = W17LightCircuitControllerScript.new()
    circuit_preview.name = "W17LightCircuitRuntime"
    add_child(circuit_preview)
    move_child(circuit_preview, 1)
    circuit_preview.call("configure", combat_preview, ark_preview)
    encounter_preview.call("configure_area_effect_provider", circuit_preview.call("effect_provider"))
    circuit_preview.connect("circuit_activated", Callable(self, "_on_circuit_activated"))
    circuit_preview.connect("circuit_rejected", Callable(self, "_on_circuit_rejected"))

    phase_preview = W17PhaseBattlefieldControllerScript.new()
    phase_preview.name = "W17PhaseBattlefieldRuntime"
    add_child(phase_preview)
    move_child(phase_preview, 1)
    phase_preview.call("configure", combat_preview, encounter_preview, circuit_preview)
    phase_preview.connect("phase_changed", Callable(self, "_on_phase_changed"))
    phase_preview.connect("phase_rejected", Callable(self, "_on_phase_rejected"))


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if shell_mode == MODE_HUB and key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_B:
                var build_ids: Array[String] = W17BuildCatalogScript.build_ids()
                if not build_ids.is_empty():
                    selected_representative_build_index = (selected_representative_build_index + 1) % build_ids.size()
                    select_representative_build(selected_representative_build_index)
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_Z:
                select_weapon_choice(0)
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_X:
                select_relic_choice(0)
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)


func select_representative_build(index: int) -> bool:
    if shell_mode != MODE_HUB:
        return false
    var build_ids: Array[String] = W17BuildCatalogScript.build_ids()
    if index < 0 or index >= build_ids.size():
        return false
    var validation: Dictionary = W17BuildCatalogScript.validate_build(build_ids[index])
    if not bool(validation.get("valid", false)):
        return false
    selected_representative_build_index = index
    selected_weapon_id = str(validation.get("weapon_id", ""))
    selected_relic_ids = _w17_string_array(validation.get("relic_ids", []))
    if not _apply_selected_build_to_runtime():
        return false
    _show_hub_prompt()
    return true


func weapon_choice_snapshot(seed_offset: int = 0) -> Array[Dictionary]:
    var segment_index: int = int(campaign.world.get("segment_index")) if campaign != null and campaign.world != null else 0
    return W17ChoiceModelScript.weapon_choices(selected_weapon_id, segment_index * 31 + seed_offset)


func relic_choice_snapshot(seed_offset: int = 0) -> Array[Dictionary]:
    var segment_index: int = int(campaign.world.get("segment_index")) if campaign != null and campaign.world != null else 0
    return W17ChoiceModelScript.relic_choices(selected_relic_ids, segment_index * 47 + seed_offset)


func select_weapon_choice(index: int) -> bool:
    if shell_mode != MODE_HUB:
        return false
    var choices: Array[Dictionary] = weapon_choice_snapshot()
    if index < 0 or index >= choices.size():
        return false
    selected_weapon_id = str(choices[index].get("id", ""))
    selected_representative_build_index = -1
    if not _apply_selected_build_to_runtime():
        return false
    _show_hub_prompt()
    return true


func select_relic_choice(index: int) -> bool:
    if shell_mode != MODE_HUB:
        return false
    var choices: Array[Dictionary] = relic_choice_snapshot()
    if index < 0 or index >= choices.size():
        return false
    selected_relic_ids = _w17_string_array(choices[index].get("resulting_loadout", []))
    selected_representative_build_index = -1
    if not _apply_selected_build_to_runtime():
        return false
    _show_hub_prompt()
    return true


func weapon_relic_selection_snapshot() -> Dictionary:
    return {
        "selected_weapon_id": selected_weapon_id,
        "selected_relic_ids": _w17_copy_ids(selected_relic_ids),
        "weapon_choices": weapon_choice_snapshot(),
        "relic_choices": relic_choice_snapshot(),
        "weapon_count": W17WeaponPartCatalogScript.catalog_counts().get("curated_weapons", 0),
        "relic_count": W17RelicCatalogScript.catalog_counts().get("relics", 0),
        "representative_build_count": W17BuildCatalogScript.build_ids().size(),
        "relic_limits": W17RelicCatalogScript.hard_limits(),
    }


func _prepare_expedition(context: Dictionary) -> bool:
    _w17_ark_tracking_armed = false
    if not super._prepare_expedition(context):
        return false
    _w17_last_ark_durability = _w17_current_ark_durability()
    _w17_ark_tracking_armed = true
    return _apply_selected_build_to_runtime()


func _resume_saved_expedition() -> bool:
    var restored: bool = super._resume_saved_expedition()
    if not restored or not is_instance_valid(combat_preview):
        return restored
    var weapon_status: Dictionary = combat_preview.call("weapon_status_snapshot")
    var snapshot_state: Dictionary = weapon_status.get("snapshot", {})
    selected_weapon_id = str(snapshot_state.get("equipped_weapon_id", selected_weapon_id))
    selected_relic_ids = _w17_string_array(snapshot_state.get("equipped_relic_ids", []))
    selected_representative_build_index = -1
    _w17_last_ark_durability = _w17_current_ark_durability()
    _w17_ark_tracking_armed = true
    return true


func _show_hub_prompt() -> void:
    super._show_hub_prompt()
    var weapon_card: Dictionary = W17WeaponPartCatalogScript.choice_card(selected_weapon_id)
    var weapon_choices: Array[Dictionary] = weapon_choice_snapshot()
    var relic_choices: Array[Dictionary] = relic_choice_snapshot()
    var weapon_option: String = str(weapon_choices[0].get("label", "-")) if not weapon_choices.is_empty() else "-"
    var relic_option: String = str(relic_choices[0].get("label", "-")) if not relic_choices.is_empty() else "-"
    status_label.text += " · W17 %s / 유물 %d · B:대표빌드 Z:%s X:%s" % [str(weapon_card.get("label", selected_weapon_id)), selected_relic_ids.size(), weapon_option, relic_option]


func _show_expedition_status(prefix: String) -> void:
    super._show_expedition_status(prefix)
    var weapon_card: Dictionary = W17WeaponPartCatalogScript.choice_card(selected_weapon_id)
    status_label.text += " · %s/유물%d" % [str(weapon_card.get("label", selected_weapon_id)), selected_relic_ids.size()]


func _on_circuit_activated(circuit_id: int, module_id: String, light_remaining: float) -> void:
    if shell_mode == MODE_EXPEDITION and is_instance_valid(combat_preview) and combat_preview.has_method("resolve_external_weapon_trigger"):
        combat_preview.call("resolve_external_weapon_trigger", "circuit_activated", "circuit-%d" % circuit_id, {"module_id": module_id})
    super._on_circuit_activated(circuit_id, module_id, light_remaining)


func _on_phase_changed(phase_id: String, immediate_threat_count: int) -> void:
    if shell_mode == MODE_EXPEDITION and is_instance_valid(combat_preview) and combat_preview.has_method("resolve_external_weapon_trigger"):
        var generation: int = 0
        var phase_model: Variant = phase_preview.get("model") if is_instance_valid(phase_preview) else null
        if phase_model != null:
            generation = int(phase_model.get("transition_generation"))
        combat_preview.call("resolve_external_weapon_trigger", "phase_changed", "phase-%s-%d" % [phase_id, generation], {"phase": phase_id})
    super._on_phase_changed(phase_id, immediate_threat_count)


func _on_ark_state_changed(route_status: String, route_id: String) -> void:
    var current_durability: int = _w17_current_ark_durability()
    if (
        shell_mode == MODE_EXPEDITION
        and _w17_ark_tracking_armed
        and _w17_last_ark_durability >= 0
        and current_durability >= 0
        and current_durability < _w17_last_ark_durability
        and is_instance_valid(combat_preview)
        and combat_preview.has_method("resolve_external_weapon_trigger")
    ):
        combat_preview.call(
            "resolve_external_weapon_trigger",
            "ark_pressure",
            "durability-%d-to-%d" % [_w17_last_ark_durability, current_durability],
            {"ark_pressure_active": true}
        )
    if current_durability >= 0:
        _w17_last_ark_durability = current_durability
    super._on_ark_state_changed(route_status, route_id)


func _apply_selected_build_to_runtime() -> bool:
    if not is_instance_valid(combat_preview):
        return false
    var weapon_model: Variant = combat_preview.get("weapon_model")
    if weapon_model == null:
        return false
    if not bool(weapon_model.call("equip_curated_weapon", selected_weapon_id)):
        return false
    return bool(weapon_model.call("equip_relics", selected_relic_ids))


func _w17_current_ark_durability() -> int:
    if not is_instance_valid(ark_preview):
        return -1
    var ark_model: Variant = ark_preview.get("model")
    if ark_model == null:
        return -1
    return int(ark_model.get("durability"))


static func _w17_string_array(raw_value: Variant) -> Array[String]:
    var result: Array[String] = []
    if not raw_value is Array:
        return result
    for raw_item: Variant in raw_value:
        result.append(str(raw_item))
    return result


static func _w17_copy_ids(source: Array[String]) -> Array[String]:
    var copied: Array[String] = []
    for item: String in source:
        copied.append(item)
    return copied
