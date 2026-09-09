extends Node2D

const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")

signal phase_changed(phase_id: String, immediate_threat_count: int)
signal phase_rejected(reason: String)

var model = PhaseBattlefieldModelScript.new()
var _player: Node2D
var _encounter: Node2D
var _circuit: Node2D


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    queue_redraw()


func configure(player: Node2D, encounter: Node2D, circuit: Node2D) -> void:
    _player = player
    _encounter = encounter
    _circuit = circuit
    if is_instance_valid(_player) and _player.has_method("set_phase_provider"):
        _player.call("set_phase_provider", model)
    if (
        is_instance_valid(_player)
        and is_instance_valid(_circuit)
        and _player.has_method("set_circuit_provider")
        and _circuit.has_method("effect_provider")
    ):
        _player.call("set_circuit_provider", _circuit.call("effect_provider"))
    if is_instance_valid(_encounter) and _encounter.has_method("configure_phase_provider"):
        _encounter.call("configure_phase_provider", model)
    _sync_runtime_phase()
    queue_redraw()


func reset_for_expedition() -> void:
    model.reset()
    _sync_runtime_phase()
    queue_redraw()


func request_phase_switch(cancelled: bool = false) -> bool:
    if not is_instance_valid(_player):
        phase_rejected.emit("missing_player")
        return false
    var threat_count := _target_phase_threat_count()
    var tree := get_tree()
    var paused := tree != null and tree.paused
    var result := model.request_transition(
        _player.global_position,
        threat_count,
        paused,
        cancelled
    )
    if bool(result.get("accepted", false)):
        _sync_runtime_phase()
        phase_changed.emit(model.current_phase, threat_count)
        queue_redraw()
        return true
    phase_rejected.emit(str(result.get("reason", "unknown")))
    queue_redraw()
    return false


func transition_preview() -> Dictionary:
    if not is_instance_valid(_player):
        return {
            "valid": false,
            "blocked_reason": "missing_player",
            "target_phase": model.other_phase(),
            "immediate_threat_count": 0,
        }
    return model.transition_preview(_player.global_position, _target_phase_threat_count())


func state_snapshot() -> Dictionary:
    var snapshot := model.snapshot()
    snapshot["current_phase"] = model.current_phase
    return snapshot


func restore_state(snapshot_state: Dictionary) -> bool:
    var restored := model.restore_snapshot(snapshot_state)
    if restored:
        _sync_runtime_phase()
        queue_redraw()
    return restored


func status_snapshot() -> Dictionary:
    var preview := transition_preview()
    return {
        "phase": model.current_phase,
        "target_phase": str(preview.get("target_phase", model.other_phase())),
        "target_valid": bool(preview.get("valid", false)),
        "target_blocked_reason": str(preview.get("blocked_reason", "")),
        "immediate_threat_count": int(preview.get("immediate_threat_count", 0)),
        "cooldown_remaining": model.cooldown_remaining,
        "transition_generation": model.transition_generation,
    }


func _process(delta: float) -> void:
    var tree := get_tree()
    var paused := tree != null and tree.paused
    model.step(delta, paused)
    queue_redraw()


func _sync_runtime_phase() -> void:
    if is_instance_valid(_encounter) and _encounter.has_method("set_world_phase"):
        _encounter.call("set_world_phase", model.current_phase)
    if is_instance_valid(_circuit) and _circuit.has_method("set_world_phase"):
        _circuit.call("set_world_phase", model.current_phase)


func _target_phase_threat_count() -> int:
    if (
        not is_instance_valid(_player)
        or not is_instance_valid(_encounter)
        or not _encounter.has_method("threat_count_for_phase")
    ):
        return 0
    return int(_encounter.call(
        "threat_count_for_phase",
        model.other_phase(),
        _player.global_position,
        260.0
    ))


func _draw() -> void:
    var current_color := Color(0.94, 0.62, 0.24, 0.20)
    var cover_color := Color(1.0, 0.82, 0.45, 0.36)
    var target_color := Color(0.64, 0.46, 0.92, 0.34)
    if model.current_phase == PhaseBattlefieldModelScript.PHASE_SHADOW:
        current_color = Color(0.44, 0.30, 0.72, 0.24)
        cover_color = Color(0.74, 0.58, 1.0, 0.38)
        target_color = Color(0.96, 0.66, 0.30, 0.34)

    for blocker_value in model.blocker_rects(model.current_phase):
        draw_rect(blocker_value, current_color, true)
    for cover_value in model.cover_rects(model.current_phase):
        draw_rect(cover_value, cover_color, true)

    var target_phase := model.other_phase()
    for target_blocker_value in model.blocker_rects(target_phase):
        draw_rect(target_blocker_value, target_color, false, 2.0)
