extends "res://game/ui/main_shell.gd"

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const CharacterRoleSurvivorScript = preload("res://game/combat/character_role_survivor.gd")
const W16SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const W16ArkConvoyScript = preload("res://game/world/ark_convoy.gd")
const W16LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const W16PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")
const W16RuntimeStateCodecScript = preload("res://game/world/runtime_state_codec.gd")

const W16_PLAYER_ORIGIN: Vector2 = Vector2(640.0, 360.0)
const W16_ARK_ORIGIN: Vector2 = Vector2(280.0, 360.0)

var selected_character_id: String = CharacterCatalogScript.ID_AURORA


func _mount_runtime_preview() -> void:
    combat_preview = CharacterRoleSurvivorScript.new()
    combat_preview.name = "W16CharacterSurvivorRuntime"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = W16_PLAYER_ORIGIN
    add_child(combat_preview)
    move_child(combat_preview, 1)
    combat_preview.connect("weapon_action", Callable(self, "_on_weapon_action"))

    ark_preview = W16ArkConvoyScript.new()
    ark_preview.name = "W16ArkRuntime"
    ark_preview.position = W16_ARK_ORIGIN
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))
    combat_preview.call("set_ark_provider", ark_preview)

    encounter_preview = W16SwarmEncounterScript.new()
    encounter_preview.name = "W16SwarmRuntime"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    encounter_preview.call("configure_player", combat_preview)
    encounter_preview.call("configure_escort_target", ark_preview)

    circuit_preview = W16LightCircuitControllerScript.new()
    circuit_preview.name = "W16LightCircuitRuntime"
    add_child(circuit_preview)
    move_child(circuit_preview, 1)
    circuit_preview.call("configure", combat_preview, ark_preview)
    encounter_preview.call("configure_area_effect_provider", circuit_preview.call("effect_provider"))
    circuit_preview.connect("circuit_activated", Callable(self, "_on_circuit_activated"))
    circuit_preview.connect("circuit_rejected", Callable(self, "_on_circuit_rejected"))

    phase_preview = W16PhaseBattlefieldControllerScript.new()
    phase_preview.name = "W16PhaseBattlefieldRuntime"
    add_child(phase_preview)
    move_child(phase_preview, 1)
    phase_preview.call("configure", combat_preview, encounter_preview, circuit_preview)
    phase_preview.connect("phase_changed", Callable(self, "_on_phase_changed"))
    phase_preview.connect("phase_rejected", Callable(self, "_on_phase_rejected"))


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if (
            shell_mode == MODE_HUB
            and key_event.pressed
            and not key_event.echo
            and key_event.keycode >= KEY_3
            and key_event.keycode <= KEY_8
        ):
            select_character_by_index(int(key_event.keycode - KEY_3))
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)


func select_character_by_index(index: int) -> bool:
    var ids := CharacterCatalogScript.character_ids()
    if index < 0 or index >= ids.size():
        return false
    return select_character(ids[index])


func select_character(character_id: String) -> bool:
    if shell_mode != MODE_HUB:
        return false
    var definition := CharacterCatalogScript.definition(character_id)
    if definition.is_empty():
        return false
    if not CharacterCatalogScript.is_unlocked(character_id, campaign.world):
        status_label.text = "W16 %s 잠김 · %s" % [
            str(definition.get("display_name", character_id)),
            str(definition.get("unlock_text", "해금 조건 미충족")),
        ]
        return false
    selected_character_id = character_id
    if is_instance_valid(combat_preview) and combat_preview.has_method("configure_character"):
        combat_preview.call("configure_character", selected_character_id, ark_preview)
    _show_hub_prompt()
    return true


func character_selection_snapshot() -> Dictionary:
    var entries: Array[Dictionary] = []
    for character_id in CharacterCatalogScript.character_ids():
        var definition := CharacterCatalogScript.definition(character_id)
        entries.append({
            "id": character_id,
            "display_name": str(definition.get("display_name", character_id)),
            "role_id": str(definition.get("role_id", "")),
            "role_name": str(definition.get("role_name", "")),
            "unlocked": CharacterCatalogScript.is_unlocked(character_id, campaign.world),
            "unlock_text": str(definition.get("unlock_text", "")),
        })
    return {
        "selected_character_id": selected_character_id,
        "entries": entries,
        "unlocked_count": CharacterCatalogScript.unlocked_character_ids(campaign.world).size(),
    }


func character_tutorial_prompt() -> String:
    var definition := CharacterCatalogScript.definition(selected_character_id)
    return str(definition.get("tutorial", ""))


func _prepare_expedition(context: Dictionary) -> bool:
    if not CharacterCatalogScript.is_unlocked(selected_character_id, campaign.world):
        selected_character_id = CharacterCatalogScript.first_unlocked_character_id(campaign.world)
    if not super._prepare_expedition(context):
        return false
    if not is_instance_valid(combat_preview) or not combat_preview.has_method("configure_character"):
        return false
    return bool(combat_preview.call("configure_character", selected_character_id, ark_preview))


func _resume_saved_expedition() -> bool:
    var resume: Dictionary = campaign.world.resume_payload()
    var runtime_state: Dictionary = resume.get("runtime_state", {})
    var saved_character_id := str(runtime_state.get("character_id", ""))
    if (
        not saved_character_id.is_empty()
        and not CharacterCatalogScript.definition(saved_character_id).is_empty()
        and CharacterCatalogScript.is_unlocked(saved_character_id, campaign.world)
    ):
        selected_character_id = saved_character_id
    return super._resume_saved_expedition()


func _checkpoint_runtime(reason: String) -> Dictionary:
    if shell_mode != MODE_EXPEDITION:
        return {"ok": false, "status": "NOT_IN_EXPEDITION"}
    var runtime_state := W16RuntimeStateCodecScript.capture_runtime(
        combat_preview,
        ark_preview,
        circuit_preview,
        phase_preview,
        encounter_preview,
        _observation_summary()
    )
    if runtime_state.is_empty():
        return {"ok": false, "status": "RUNTIME_CAPTURE_FAILED"}
    runtime_state["character_id"] = selected_character_id
    var result := campaign.checkpoint(reason, runtime_state)
    if not bool(result.get("ok", false)) and is_instance_valid(status_label):
        status_label.text = "W16 체크포인트 실패: %s" % str(result.get("status", "UNKNOWN"))
    return result


func _enter_hub() -> void:
    if not CharacterCatalogScript.is_unlocked(selected_character_id, campaign.world):
        selected_character_id = CharacterCatalogScript.first_unlocked_character_id(campaign.world)
    super._enter_hub()
    if is_instance_valid(combat_preview) and combat_preview.has_method("configure_character"):
        combat_preview.call("configure_character", selected_character_id, ark_preview)


func _show_hub_prompt() -> void:
    super._show_hub_prompt()
    var roster: Array[String] = []
    var ids := CharacterCatalogScript.character_ids()
    for index in range(ids.size()):
        var character_id: String = ids[index]
        var definition := CharacterCatalogScript.definition(character_id)
        var marker := "" if CharacterCatalogScript.is_unlocked(character_id, campaign.world) else "잠김 "
        roster.append("%d:%s%s" % [
            index + 3,
            marker,
            str(definition.get("display_name", character_id)),
        ])
    var selected := CharacterCatalogScript.definition(selected_character_id)
    status_label.text += " · 캐릭터 %s[%s] · %s" % [
        str(selected.get("display_name", selected_character_id)),
        str(selected.get("role_name", "role")),
        " / ".join(roster),
    ]


func _show_expedition_status(prefix: String) -> void:
    super._show_expedition_status(prefix)
    var definition := CharacterCatalogScript.definition(selected_character_id)
    status_label.text += " · %s[%s]" % [
        str(definition.get("display_name", selected_character_id)),
        str(definition.get("role_name", "role")),
    ]


func _on_circuit_activated(circuit_id: int, module_id: String, light_remaining: float) -> void:
    if is_instance_valid(combat_preview) and combat_preview.has_method("on_circuit_activated"):
        combat_preview.call("on_circuit_activated", circuit_id, module_id)
    super._on_circuit_activated(circuit_id, module_id, light_remaining)


func _on_phase_changed(phase_id: String, immediate_threat_count: int) -> void:
    if is_instance_valid(combat_preview) and combat_preview.has_method("on_phase_changed"):
        combat_preview.call("on_phase_changed", phase_id)
    super._on_phase_changed(phase_id, immediate_threat_count)
