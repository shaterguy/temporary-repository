extends "res://game/ui/main_shell_w22.gd"

const W23WeaponRelicSurvivorScript = preload("res://game/combat/weapon_relic_survivor.gd")
const W23RegionArkConvoyScript = preload("res://game/world/region_ark_convoy.gd")
const W23RegionSwarmEncounterScript = preload("res://game/combat/w23_region_swarm_encounter.gd")
const W23LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const W23PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")
const W23WorldEventArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")


func _mount_runtime_preview() -> void:
    combat_preview = W23WeaponRelicSurvivorScript.new()
    combat_preview.name = "W18WeaponRelicSurvivorRuntime"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = W17_PLAYER_ORIGIN
    add_child(combat_preview)
    move_child(combat_preview, 1)
    combat_preview.connect("weapon_action", Callable(self, "_on_weapon_action"))

    ark_preview = W23RegionArkConvoyScript.new()
    ark_preview.name = "W18RegionArkRuntime"
    ark_preview.position = W17_ARK_ORIGIN
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))
    combat_preview.call("set_ark_provider", ark_preview)

    encounter_preview = W23RegionSwarmEncounterScript.new()
    encounter_preview.name = "W18RegionSwarmRuntime"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    encounter_preview.call("configure_player", combat_preview)
    encounter_preview.call("configure_escort_target", ark_preview)

    circuit_preview = W23LightCircuitControllerScript.new()
    circuit_preview.name = "W18LightCircuitRuntime"
    add_child(circuit_preview)
    move_child(circuit_preview, 1)
    circuit_preview.call("configure", combat_preview, ark_preview)
    encounter_preview.call("configure_area_effect_provider", circuit_preview.call("effect_provider"))
    circuit_preview.connect("circuit_activated", Callable(self, "_on_circuit_activated"))
    circuit_preview.connect("circuit_rejected", Callable(self, "_on_circuit_rejected"))

    phase_preview = W23PhaseBattlefieldControllerScript.new()
    phase_preview.name = "W18PhaseBattlefieldRuntime"
    add_child(phase_preview)
    move_child(phase_preview, 1)
    phase_preview.call("configure", combat_preview, encounter_preview, circuit_preview)
    phase_preview.connect("phase_changed", Callable(self, "_on_phase_changed"))
    phase_preview.connect("phase_rejected", Callable(self, "_on_phase_rejected"))


func select_world_choice(option_index: int) -> bool:
    var resolved := super.select_world_choice(option_index)
    _sync_story_event_art()
    return resolved


func _show_hub_prompt() -> void:
    super._show_hub_prompt()
    _sync_story_event_art()


func _enter_hub() -> void:
    super._enter_hub()
    _sync_story_event_art()


func _prepare_expedition(context: Dictionary) -> bool:
    _clear_story_event_art()
    return super._prepare_expedition(context)


func campaign_story_snapshot() -> Dictionary:
    var snapshot := super.campaign_story_snapshot()
    var pending: Variant = snapshot.get("pending_event", {})
    if pending is Dictionary:
        var event_id := str((pending as Dictionary).get("event_id", ""))
        snapshot["pending_event_art"] = W23WorldEventArtCatalogScript.event_art_snapshot(event_id)
    else:
        snapshot["pending_event_art"] = {}
    return snapshot


func _sync_story_event_art() -> void:
    var hud := get_node_or_null("W23WorldEventHud")
    if hud == null:
        return
    if campaign != null and campaign.world != null and campaign.world.has_pending_story_event():
        var event: Dictionary = campaign.current_story_event()
        var event_id := str(event.get("event_id", ""))
        if not event_id.is_empty() and bool(hud.call("show_event", event_id)):
            return
    hud.call("clear_event")


func _clear_story_event_art() -> void:
    var hud := get_node_or_null("W23WorldEventHud")
    if hud != null:
        hud.call("clear_event")
