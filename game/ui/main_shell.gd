extends Control

const BuildIdentityScript = preload("res://game/core/build_identity.gd")
const SafeAreaScript = preload("res://platform/android/safe_area.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const ArkConvoyScript = preload("res://game/world/ark_convoy.gd")
const LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")
const PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")
const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const RuntimeStateCodecScript = preload("res://game/world/runtime_state_codec.gd")
const WorldCampaignModelScript = preload("res://game/world/world_campaign_model.gd")

const BASE_MARGIN: int = 48
const MODE_SLOT_SELECT: String = "SLOT_SELECT"
const MODE_HUB: String = "HUB"
const MODE_EXPEDITION: String = "EXPEDITION"
const MODE_RECOVERY_BLOCKED: String = "RECOVERY_BLOCKED"
const PLAYER_ORIGIN: Vector2 = Vector2(640.0, 360.0)
const ARK_ORIGIN: Vector2 = Vector2(280.0, 360.0)

@onready var safe_area: MarginContainer = %SafeArea
@onready var status_label: Label = %Status

var movement_input: Vector2 = Vector2.ZERO
var dodge_pressed: bool = false
var phase_pressed: bool = false
var transient_input_generation: int = 0
var combat_preview: Node2D
var encounter_preview: Node2D
var ark_preview: Node2D
var circuit_preview: Node2D
var phase_preview: Node2D
var campaign = CampaignRuntimeScript.new()
var shell_mode: String = MODE_SLOT_SELECT
var _checkpoint_elapsed: float = 0.0
var _settlement_in_progress: bool = false
var _observation_total_actions: int = 0
var _observation_ranged_actions: int = 0
var _observation_clustered_actions: int = 0


func _ready() -> void:
    get_viewport().size_changed.connect(_apply_safe_area)
    _apply_safe_area()
    _mount_runtime_preview()
    _set_expedition_processing(false)
    _show_slot_prompt()


func _process(delta: float) -> void:
    if shell_mode != MODE_EXPEDITION or _settlement_in_progress:
        return
    _checkpoint_elapsed += maxf(0.0, delta)
    if _checkpoint_elapsed >= CampaignRuntimeScript.CHECKPOINT_INTERVAL_SECONDS:
        _checkpoint_elapsed = 0.0
        _checkpoint_runtime("periodic_15s")
    if not RuntimeStateCodecScript.player_is_alive(combat_preview):
        call_deferred("_settle_current", "failed")


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        if shell_mode == MODE_EXPEDITION:
            _checkpoint_runtime("background")
        _clear_transient_input()
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
        call_deferred("_apply_safe_area")


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    if shell_mode == MODE_SLOT_SELECT:
        if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_3:
            select_save_slot(int(key_event.keycode - KEY_1))
            get_viewport().set_input_as_handled()
        return
    if shell_mode == MODE_HUB:
        if key_event.keycode == KEY_1:
            select_world_choice(0)
            get_viewport().set_input_as_handled()
        elif key_event.keycode == KEY_2:
            select_world_choice(1)
            get_viewport().set_input_as_handled()
        return
    if shell_mode != MODE_EXPEDITION:
        return

    if key_event.keycode == KEY_3:
        select_circuit_module(LightCircuitModelScript.MODULE_SNARE)
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_4:
        select_circuit_module(LightCircuitModelScript.MODULE_ARK_WARD)
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_5:
        select_circuit_module(LightCircuitModelScript.MODULE_ECHO_BEACON)
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_Q:
        request_phase_switch()
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
        continue_after_rest()
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_R:
        recover_expedition()
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_F:
        _settle_current("failed")
        get_viewport().set_input_as_handled()


func set_transient_input(movement: Vector2, dodge: bool, phase: bool) -> void:
    var phase_edge := phase and not phase_pressed
    movement_input = movement.limit_length(1.0)
    dodge_pressed = dodge
    phase_pressed = phase
    if is_instance_valid(combat_preview) and combat_preview.has_method("set_virtual_input"):
        combat_preview.call("set_virtual_input", movement_input, dodge_pressed)
    if phase_edge:
        request_phase_switch()


func select_save_slot(slot: int) -> bool:
    if shell_mode != MODE_SLOT_SELECT or slot < 0 or slot >= 3:
        return false
    var metadata_all := campaign.slot_metadata_all()
    var metadata: Dictionary = metadata_all[slot]
    var result: Dictionary
    if bool(metadata.get("occupied", false)):
        result = campaign.load_slot(slot)
    else:
        result = campaign.start_new(slot, 20260909 + slot)
    if not bool(result.get("ok", false)):
        status_label.text = "W12 슬롯 %d 열기 실패: %s" % [slot + 1, str(result.get("status", "UNKNOWN"))]
        return false

    if campaign.world.state == WorldCampaignModelScript.STATE_EXPEDITION:
        return _resume_saved_expedition()
    _enter_hub()
    return true


func select_world_choice(option_index: int) -> bool:
    if shell_mode != MODE_HUB:
        return false
    var options: Array[Dictionary] = campaign.world.departure_options()
    if option_index < 0 or option_index >= options.size():
        return false
    var choice: Dictionary = options[option_index]
    var begin_result := campaign.begin_expedition(str(choice.get("choice_id", "")))
    if not bool(begin_result.get("ok", false)):
        status_label.text = "W12 출항 실패: %s" % str(begin_result.get("status", "UNKNOWN"))
        return false

    shell_mode = MODE_EXPEDITION
    var context := campaign.world.expedition_context()
    if not _prepare_expedition(context):
        shell_mode = MODE_RECOVERY_BLOCKED
        _set_expedition_processing(false)
        status_label.text = "W12 원정 런타임 초기화 실패 · 저장 슬롯은 출항 직전 상태로 보존됨"
        return false
    _start_echo_capture()
    _checkpoint_elapsed = 0.0
    var checkpoint := _checkpoint_runtime("departure_initialized")
    if not bool(checkpoint.get("ok", false)):
        status_label.text = "W12 원정 시작 · 초기 체크포인트 실패: %s" % str(checkpoint.get("status", "UNKNOWN"))
    else:
        _show_expedition_status("원정 시작")
    return true


func request_phase_switch(cancelled: bool = false) -> bool:
    if shell_mode != MODE_EXPEDITION:
        return false
    if not is_instance_valid(phase_preview) or not phase_preview.has_method("request_phase_switch"):
        return false
    return bool(phase_preview.call("request_phase_switch", cancelled))


func continue_after_rest() -> bool:
    if shell_mode != MODE_EXPEDITION or not is_instance_valid(ark_preview):
        return false
    if not ark_preview.has_method("resume_after_rest"):
        return false
    return bool(ark_preview.call("resume_after_rest"))


func recover_expedition() -> bool:
    if shell_mode != MODE_EXPEDITION or not is_instance_valid(ark_preview):
        return false
    var recovered := bool(ark_preview.call("recover_from_failure"))
    if recovered:
        _checkpoint_runtime("recoverable_failure_recovered")
        _show_expedition_status("방주 복구")
    return recovered


func select_circuit_module(module_id: String) -> bool:
    if shell_mode != MODE_EXPEDITION:
        return false
    if not is_instance_valid(circuit_preview) or not circuit_preview.has_method("select_module"):
        return false
    var selected := bool(circuit_preview.call("select_module", module_id))
    if selected:
        var circuit_status: Dictionary = circuit_preview.call("status_snapshot")
        status_label.text = "W12 회로 모듈 %s · 광량 %d · 위상 %s" % [
            module_id,
            roundi(float(circuit_status.get("light", 0.0))),
            str(circuit_status.get("phase", "material")),
        ]
    return selected


func _mount_runtime_preview() -> void:
    combat_preview = SurvivorControllerScript.new()
    combat_preview.name = "W12SurvivorRuntime"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = PLAYER_ORIGIN
    add_child(combat_preview)
    move_child(combat_preview, 1)
    combat_preview.connect("weapon_action", Callable(self, "_on_weapon_action"))

    ark_preview = ArkConvoyScript.new()
    ark_preview.name = "W12ArkRuntime"
    ark_preview.position = ARK_ORIGIN
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))

    encounter_preview = SwarmEncounterScript.new()
    encounter_preview.name = "W12SwarmRuntime"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    encounter_preview.call("configure_player", combat_preview)
    encounter_preview.call("configure_escort_target", ark_preview)

    circuit_preview = LightCircuitControllerScript.new()
    circuit_preview.name = "W12LightCircuitRuntime"
    add_child(circuit_preview)
    move_child(circuit_preview, 1)
    circuit_preview.call("configure", combat_preview, ark_preview)
    encounter_preview.call("configure_area_effect_provider", circuit_preview.call("effect_provider"))
    circuit_preview.connect("circuit_activated", Callable(self, "_on_circuit_activated"))
    circuit_preview.connect("circuit_rejected", Callable(self, "_on_circuit_rejected"))

    phase_preview = PhaseBattlefieldControllerScript.new()
    phase_preview.name = "W12PhaseBattlefieldRuntime"
    add_child(phase_preview)
    move_child(phase_preview, 1)
    phase_preview.call("configure", combat_preview, encounter_preview, circuit_preview)
    phase_preview.connect("phase_changed", Callable(self, "_on_phase_changed"))
    phase_preview.connect("phase_rejected", Callable(self, "_on_phase_rejected"))


func _prepare_expedition(context: Dictionary) -> bool:
    var tree := get_tree()
    if tree != null:
        tree.paused = false
    var seed := _expedition_seed()
    if not RuntimeStateCodecScript.reset_player(combat_preview, PLAYER_ORIGIN):
        return false
    circuit_preview.call("reset_for_expedition")
    if not RuntimeStateCodecScript.reset_encounter(
        encounter_preview,
        seed,
        campaign.current_doctrine_plan()
    ):
        return false
    phase_preview.call("reset_for_expedition")
    if not bool(ark_preview.call("configure_expedition", seed, str(context.get("route_id", "")))):
        return false

    var previous_record := campaign.current_echo_record()
    if not previous_record.is_empty():
        combat_preview.call("select_tactical_echo_record", previous_record)
    _observation_total_actions = 0
    _observation_ranged_actions = 0
    _observation_clustered_actions = 0
    _set_expedition_processing(true)
    return true


func _resume_saved_expedition() -> bool:
    shell_mode = MODE_EXPEDITION
    var context := campaign.world.expedition_context()
    if context.is_empty() or not _prepare_expedition(context):
        shell_mode = MODE_RECOVERY_BLOCKED
        _set_expedition_processing(false)
        status_label.text = "W12 저장 원정 기본 런타임 복원 실패"
        return false

    var resume := campaign.world.resume_payload()
    var runtime_state: Dictionary = resume.get("runtime_state", {})
    if not runtime_state.is_empty():
        var restored := RuntimeStateCodecScript.restore_runtime(
            runtime_state,
            combat_preview,
            ark_preview,
            circuit_preview,
            phase_preview,
            encounter_preview
        )
        if not bool(restored.get("ok", false)):
            shell_mode = MODE_RECOVERY_BLOCKED
            _set_expedition_processing(false)
            status_label.text = "W12 중단 원정 복원 차단: %s" % str(restored.get("status", "UNKNOWN"))
            return false
        _restore_observation(restored.get("observation", {}))
    _start_echo_capture()
    _checkpoint_elapsed = 0.0
    _show_expedition_status("중단 원정 재개")
    return true


func _start_echo_capture() -> void:
    if not is_instance_valid(combat_preview):
        return
    var record_id := "%s-capture-%d" % [campaign.world.active_expedition_id, campaign.sequence]
    combat_preview.call("begin_tactical_echo_capture", record_id)


func _finish_echo_capture(outcome: String) -> Dictionary:
    var record: Dictionary = combat_preview.call("finish_tactical_echo_capture", outcome)
    if record.is_empty():
        return campaign.current_echo_record()
    return record


func _settle_current(outcome: String) -> void:
    if shell_mode != MODE_EXPEDITION or _settlement_in_progress:
        return
    _settlement_in_progress = true
    _clear_transient_input()
    var echo_record := _finish_echo_capture("completed" if outcome == "success" else "failed")
    var result := campaign.settle_current(outcome, _observation_summary(), echo_record)
    if not bool(result.get("ok", false)):
        _settlement_in_progress = false
        status_label.text = "W12 정산 실패 · 재시도 가능: %s" % str(result.get("status", "UNKNOWN"))
        return
    _checkpoint_elapsed = 0.0
    _settlement_in_progress = false
    _enter_hub()
    status_label.text = "W12 정산 완료 · %s · 보급자원 %+d · 세그먼트 %d · 다음 교리 %s" % [
        outcome,
        int(result.get("salvage_delta", 0)),
        int(result.get("segment_index", campaign.world.segment_index)),
        str(result.get("next_doctrine_id", "none")),
    ]


func _checkpoint_runtime(reason: String) -> Dictionary:
    if shell_mode != MODE_EXPEDITION:
        return {"ok": false, "status": "NOT_IN_EXPEDITION"}
    var runtime_state := RuntimeStateCodecScript.capture_runtime(
        combat_preview,
        ark_preview,
        circuit_preview,
        phase_preview,
        encounter_preview,
        _observation_summary()
    )
    if runtime_state.is_empty():
        return {"ok": false, "status": "RUNTIME_CAPTURE_FAILED"}
    var result := campaign.checkpoint(reason, runtime_state)
    if not bool(result.get("ok", false)) and is_instance_valid(status_label):
        status_label.text = "W12 체크포인트 실패: %s" % str(result.get("status", "UNKNOWN"))
    return result


func _enter_hub() -> void:
    var tree := get_tree()
    if tree != null:
        tree.paused = false
    shell_mode = MODE_HUB
    _set_expedition_processing(false)
    _clear_transient_input()
    _show_hub_prompt()


func _show_slot_prompt() -> void:
    shell_mode = MODE_SLOT_SELECT
    var parts: Array[String] = []
    for metadata in campaign.slot_metadata_all():
        var slot_number := int(metadata.get("slot", 0)) + 1
        if bool(metadata.get("occupied", false)):
            parts.append("%d:저장#%d" % [slot_number, int(metadata.get("sequence", 0))])
        else:
            parts.append("%d:새게임" % slot_number)
    status_label.text = "W12 저장 슬롯 선택 · %s · %s" % [" / ".join(parts), BuildIdentityScript.VERSION_NAME]


func _show_hub_prompt() -> void:
    var options: Array[Dictionary] = campaign.world.departure_options()
    var parts: Array[String] = []
    for index in range(options.size()):
        var option: Dictionary = options[index]
        parts.append("%d %s→%s" % [
            index + 1,
            str(option.get("choice_id", "choice")),
            str(option.get("next_region", "region")),
        ])
    status_label.text = "W12 거점 · 세그먼트 %d · 보급자원 %d · %s" % [
        campaign.world.segment_index,
        campaign.world.salvage,
        " / ".join(parts),
    ]


func _show_expedition_status(prefix: String) -> void:
    var context := campaign.world.expedition_context()
    var doctrine := campaign.current_doctrine_plan()
    status_label.text = "W12 %s · %s · %s · 교리 %s · 3/4/5 회로 · Q 위상 · Enter 휴식종료 · R 복구/F 철수" % [
        prefix,
        str(context.get("region_id", "region")),
        str(context.get("route_id", "route")),
        str(doctrine.get("doctrine_id", "none")),
    ]


func _observation_summary() -> Dictionary:
    return {
        "total_actions": _observation_total_actions,
        "ranged_actions": _observation_ranged_actions,
        "clustered_actions": _observation_clustered_actions,
    }


func _restore_observation(value: Variant) -> void:
    if not value is Dictionary:
        return
    _observation_total_actions = maxi(0, int(value.get("total_actions", 0)))
    _observation_ranged_actions = clampi(int(value.get("ranged_actions", 0)), 0, _observation_total_actions)
    _observation_clustered_actions = clampi(int(value.get("clustered_actions", 0)), 0, _observation_total_actions)


func _expedition_seed() -> int:
    return maxi(1, campaign.world.campaign_seed + campaign.world.segment_index * 1009 + campaign.world.expedition_attempt * 7919)


func _set_expedition_processing(enabled: bool) -> void:
    if is_instance_valid(combat_preview):
        combat_preview.process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
    if is_instance_valid(phase_preview):
        phase_preview.process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
    for node in [ark_preview, encounter_preview, circuit_preview]:
        if is_instance_valid(node):
            node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


func _clear_transient_input() -> void:
    movement_input = Vector2.ZERO
    dodge_pressed = false
    phase_pressed = false
    transient_input_generation += 1
    if is_instance_valid(combat_preview) and combat_preview.has_method("clear_transient_input"):
        combat_preview.call("clear_transient_input")


func _on_weapon_action(action: Dictionary) -> void:
    if shell_mode != MODE_EXPEDITION or str(action.get("type", "")) != "weapon_damage":
        return
    _observation_total_actions += 1
    _observation_ranged_actions += 1


func _on_ark_state_changed(route_status: String, route_id: String) -> void:
    if shell_mode != MODE_EXPEDITION:
        return
    if route_status == "RESTING":
        _checkpoint_runtime("route_rest")
        status_label.text = "W12 %s 휴식 지점 · Enter로 원정 정산 구간 진입" % route_id
    elif route_status == "ARRIVED":
        call_deferred("_settle_current", "success")
    elif route_status == "FAILED_RECOVERABLE":
        _checkpoint_runtime("ark_failed_recoverable")
        status_label.text = "W12 방주 파손 · R 보급 복구 / F 회수 후 거점 복귀"


func _on_circuit_activated(circuit_id: int, module_id: String, light_remaining: float) -> void:
    if shell_mode != MODE_EXPEDITION:
        return
    _observation_total_actions += 1
    _observation_clustered_actions += 1
    var circuit_status: Dictionary = circuit_preview.call("status_snapshot")
    status_label.text = "W12 회로 #%d %s · 위상 %s · 광량 %d · 활성 %d/%d" % [
        circuit_id,
        module_id,
        str(circuit_status.get("phase", "material")),
        roundi(light_remaining),
        int(circuit_status.get("active_count", 0)),
        LightCircuitModelScript.MAX_ACTIVE_CIRCUITS,
    ]


func _on_circuit_rejected(reason: String) -> void:
    if shell_mode != MODE_EXPEDITION or reason == "teleport_segment" or reason == "phase_changed":
        return
    var circuit_status: Dictionary = circuit_preview.call("status_snapshot")
    status_label.text = "W12 회로 미발동: %s · 광량 %d · %.1fs" % [
        reason,
        roundi(float(circuit_status.get("light", 0.0))),
        float(circuit_status.get("cooldown_remaining", 0.0)),
    ]


func _on_phase_changed(phase_id: String, immediate_threat_count: int) -> void:
    if shell_mode != MODE_EXPEDITION:
        return
    var phase_status: Dictionary = phase_preview.call("status_snapshot")
    status_label.text = "W12 %s 위상 · 반대위상 위협 %d · 재전환 %.1fs" % [
        phase_id,
        immediate_threat_count,
        float(phase_status.get("cooldown_remaining", 0.0)),
    ]


func _on_phase_rejected(reason: String) -> void:
    if shell_mode != MODE_EXPEDITION:
        return
    var phase_status: Dictionary = phase_preview.call("status_snapshot")
    status_label.text = "W12 위상전환 불가: %s · 목표 %s · 위협 %d · %.1fs" % [
        reason,
        str(phase_status.get("target_phase", "unknown")),
        int(phase_status.get("immediate_threat_count", 0)),
        float(phase_status.get("cooldown_remaining", 0.0)),
    ]


func _apply_safe_area() -> void:
    if not is_instance_valid(safe_area):
        return
    var window_size := get_window().size
    var visible_size := get_viewport_rect().size
    var viewport_size := Vector2i(roundi(visible_size.x), roundi(visible_size.y))
    var margins := SafeAreaScript.margins_for(
        window_size,
        viewport_size,
        DisplayServer.get_display_safe_area()
    )
    safe_area.add_theme_constant_override("margin_left", BASE_MARGIN + margins.x)
    safe_area.add_theme_constant_override("margin_top", BASE_MARGIN + margins.y)
    safe_area.add_theme_constant_override("margin_right", BASE_MARGIN + margins.z)
    safe_area.add_theme_constant_override("margin_bottom", BASE_MARGIN + margins.w)
