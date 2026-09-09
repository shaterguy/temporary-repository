extends "res://game/ui/main_shell_w17.gd"

const W18RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const W18RegionExpeditionModelScript = preload("res://game/world/region_expedition_model.gd")
const W18WeaponRelicSurvivorScript = preload("res://game/combat/weapon_relic_survivor.gd")
const W18RegionArkConvoyScript = preload("res://game/world/region_ark_convoy.gd")
const W18RegionSwarmEncounterScript = preload("res://game/combat/region_swarm_encounter.gd")
const W18LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const W18PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")
const W18RuntimeStateCodecScript = preload("res://game/world/runtime_state_codec.gd")
const W18_DEFAULT_BACKGROUND: String = "res://assets/runtime/w13/environment_twilight_shipyard.svg"

var region_model = W18RegionExpeditionModelScript.new()
var _w18_background_path: String = W18_DEFAULT_BACKGROUND
var _w18_objective_gate_required: bool = true


func _mount_runtime_preview() -> void:
    combat_preview = W18WeaponRelicSurvivorScript.new()
    combat_preview.name = "W18WeaponRelicSurvivorRuntime"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = W17_PLAYER_ORIGIN
    add_child(combat_preview)
    move_child(combat_preview, 1)
    combat_preview.connect("weapon_action", Callable(self, "_on_weapon_action"))

    ark_preview = W18RegionArkConvoyScript.new()
    ark_preview.name = "W18RegionArkRuntime"
    ark_preview.position = W17_ARK_ORIGIN
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))
    combat_preview.call("set_ark_provider", ark_preview)

    encounter_preview = W18RegionSwarmEncounterScript.new()
    encounter_preview.name = "W18RegionSwarmRuntime"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    encounter_preview.call("configure_player", combat_preview)
    encounter_preview.call("configure_escort_target", ark_preview)

    circuit_preview = W18LightCircuitControllerScript.new()
    circuit_preview.name = "W18LightCircuitRuntime"
    add_child(circuit_preview)
    move_child(circuit_preview, 1)
    circuit_preview.call("configure", combat_preview, ark_preview)
    encounter_preview.call("configure_area_effect_provider", circuit_preview.call("effect_provider"))
    circuit_preview.connect("circuit_activated", Callable(self, "_on_circuit_activated"))
    circuit_preview.connect("circuit_rejected", Callable(self, "_on_circuit_rejected"))

    phase_preview = W18PhaseBattlefieldControllerScript.new()
    phase_preview.name = "W18PhaseBattlefieldRuntime"
    add_child(phase_preview)
    move_child(phase_preview, 1)
    phase_preview.call("configure", combat_preview, encounter_preview, circuit_preview)
    phase_preview.connect("phase_changed", Callable(self, "_on_phase_changed"))
    phase_preview.connect("phase_rejected", Callable(self, "_on_phase_rejected"))


func _prepare_expedition(context: Dictionary) -> bool:
    _w18_objective_gate_required = true
    var has_w18_region := region_model.configure(context)
    if has_w18_region:
        if not bool(ark_preview.call("configure_region_route", str(context.get("route_id", "")), region_model.route_config())):
            return false
    else:
        ark_preview.call("clear_region_route")

    if not super._prepare_expedition(context):
        return false

    if has_w18_region:
        if not bool(encounter_preview.call("configure_region_profile", region_model.spawn_profile())):
            return false
    else:
        encounter_preview.call("clear_region_profile")
    _apply_region_background()
    return true


func _resume_saved_expedition() -> bool:
    var restored: bool = super._resume_saved_expedition()
    if not restored:
        return false
    if region_model.is_active():
        var resume: Dictionary = campaign.world.resume_payload()
        var runtime_state: Dictionary = resume.get("runtime_state", {})
        var region_state: Variant = runtime_state.get("w18_region", {})
        if region_state is Dictionary and not region_state.is_empty():
            if not region_model.restore_snapshot(region_state, campaign.world.expedition_context()):
                status_label.text = "W18 지역 목표 상태 복원 차단"
                return false
            _w18_objective_gate_required = bool(runtime_state.get("w18_region_gate_required", true))
        else:
            _w18_objective_gate_required = false
    _apply_region_background()
    _show_expedition_status("중단 원정 재개")
    return true


func _checkpoint_runtime(reason: String) -> Dictionary:
    if shell_mode != MODE_EXPEDITION:
        return {"ok": false, "status": "NOT_IN_EXPEDITION"}
    var runtime_state := W18RuntimeStateCodecScript.capture_runtime(
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
    if region_model.is_active():
        runtime_state["w18_region"] = region_model.snapshot()
        runtime_state["w18_region_gate_required"] = _w18_objective_gate_required
    var result := campaign.checkpoint(reason, runtime_state)
    if not bool(result.get("ok", false)) and is_instance_valid(status_label):
        status_label.text = "W18 체크포인트 실패: %s" % str(result.get("status", "UNKNOWN"))
    return result


func continue_after_rest() -> bool:
    if region_model.is_active() and _w18_objective_gate_required:
        var ark_model: Variant = ark_preview.get("model") if is_instance_valid(ark_preview) else null
        if ark_model != null and str(ark_model.get("status")) == "RESTING" and not region_model.objective_complete():
            var objective := region_model.objective_snapshot()
            status_label.text = "W18 목표 미완료 · %s · 위상 %d/%d · 회로 %d/%d" % [
                str(objective.get("objective_label", "지역 목표")),
                int(objective.get("phase_count", 0)),
                int(objective.get("required_phase_count", 2)),
                int(objective.get("circuit_activation_count", 0)),
                int(objective.get("required_circuits", 1)),
            ]
            return false
    return super.continue_after_rest()


func _enter_hub() -> void:
    region_model.reset()
    _w18_objective_gate_required = true
    _w18_background_path = W18_DEFAULT_BACKGROUND
    _apply_background_path(_w18_background_path)
    super._enter_hub()


func _on_phase_changed(phase_id: String, immediate_threat_count: int) -> void:
    if region_model.is_active():
        region_model.record_phase_transition(phase_id)
    super._on_phase_changed(phase_id, immediate_threat_count)


func _on_circuit_activated(circuit_id: int, module_id: String, light_remaining: float) -> void:
    if region_model.is_active():
        region_model.record_circuit_activation()
    super._on_circuit_activated(circuit_id, module_id, light_remaining)


func _on_ark_state_changed(route_status: String, route_id: String) -> void:
    if region_model.is_active():
        region_model.record_route_state(route_status)
    super._on_ark_state_changed(route_status, route_id)


func _show_expedition_status(prefix: String) -> void:
    super._show_expedition_status(prefix)
    if not region_model.is_active():
        return
    var objective := region_model.objective_snapshot()
    var phase_model: Variant = phase_preview.get("model") if is_instance_valid(phase_preview) else null
    var phase_id := str(phase_model.get("current_phase")) if phase_model != null else "material"
    var phase_rule := region_model.phase_rule(phase_id)
    var migration_marker := " · 레거시 원정 목표게이트 우회" if not _w18_objective_gate_required else ""
    status_label.text += " · W18 %s · %s %d/%d · 위상규칙 %s%s" % [
        region_model.display_name(),
        str(objective.get("objective_label", "목표")),
        int(objective.get("circuit_activation_count", 0)),
        int(objective.get("required_circuits", 1)),
        str(phase_rule.get("hazard_id", "none")),
        migration_marker,
    ]


func region_expansion_snapshot() -> Dictionary:
    var counts := W18RegionCatalogScript.catalog_counts()
    var active := region_model.is_active()
    var behavior_ids: Array[String] = []
    if is_instance_valid(encounter_preview) and encounter_preview.has_method("region_behavior_ids"):
        var raw_behavior_ids: Variant = encounter_preview.call("region_behavior_ids")
        if raw_behavior_ids is Array:
            for raw_behavior_id: Variant in raw_behavior_ids:
                behavior_ids.append(str(raw_behavior_id))
    return {
        "active": active,
        "catalog_counts": counts,
        "region_id": region_model.region_id() if active else "",
        "parent_region_id": region_model.parent_region_id() if active else "",
        "display_name": region_model.display_name() if active else "",
        "background_asset": _w18_background_path,
        "route_override_id": str(ark_preview.call("active_region_route_id")) if is_instance_valid(ark_preview) and ark_preview.has_method("active_region_route_id") else "",
        "enemy_behavior_ids": behavior_ids,
        "objective_gate_required": _w18_objective_gate_required,
        "objective": region_model.objective_snapshot(),
        "material_rule": region_model.phase_rule(W18RegionCatalogScript.PHASE_MATERIAL) if active else {},
        "shadow_rule": region_model.phase_rule(W18RegionCatalogScript.PHASE_SHADOW) if active else {},
    }


func _apply_region_background() -> void:
    _w18_background_path = W18_DEFAULT_BACKGROUND
    if region_model.is_active():
        _w18_background_path = str(region_model.active_profile.get("background_asset", W18_DEFAULT_BACKGROUND))
    _apply_background_path(_w18_background_path)


func _apply_background_path(resource_path: String) -> void:
    var background := get_node_or_null("W13Environment") as TextureRect
    if background == null:
        return
    var loaded: Resource = load(resource_path)
    if loaded is Texture2D:
        background.texture = loaded
