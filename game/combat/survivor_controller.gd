extends CharacterBody2D

const CombatModelScript = preload("res://game/combat/combat_model.gd")
const CausalWeaponModelScript = preload("res://game/combat/causal_weapon_model.gd")
const TacticalEchoModelScript = preload("res://game/systems/echo/tactical_echo_model.gd")

signal auto_attack(target_id: int, damage: int, direction: Vector2)
signal weapon_action(action: Dictionary)
signal tactical_echo_event(event: Dictionary)
signal hit_feedback(applied_damage: int, remaining_health: int, generation: int)
signal pause_changed(paused: bool)

@export var camera_enabled: bool = true

var model = CombatModelScript.new()
var weapon_model = CausalWeaponModelScript.new()
var echo_model = TacticalEchoModelScript.new()
var _virtual_movement: Vector2 = Vector2.ZERO
var _virtual_dodge_queued: bool = false
var _keyboard_dodge_down: bool = false
var _feedback_remaining: float = 0.0
var _camera: Camera2D
var _target_provider: Node
var _phase_provider: Object
var _circuit_provider: Object
var _combat_event_generation: int = 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    model.reset(global_position)
    weapon_model.reset()
    echo_model.reset()
    _camera = Camera2D.new()
    _camera.name = "CombatCamera"
    _camera.enabled = camera_enabled
    _camera.position_smoothing_enabled = true
    _camera.position_smoothing_speed = 8.0
    add_child(_camera)
    queue_redraw()


func _exit_tree() -> void:
    var tree := get_tree()
    if tree != null and tree.paused:
        tree.paused = false


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        clear_transient_input()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
            set_paused(not model.paused)
            get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
    if model.paused:
        velocity = Vector2.ZERO
        _consume_keyboard_dodge_edge()
        return

    var requested_movement := _keyboard_movement()
    if not _virtual_movement.is_zero_approx():
        requested_movement = _virtual_movement

    var dodge_requested := _virtual_dodge_queued or _consume_keyboard_dodge_edge()
    _virtual_dodge_queued = false
    var previous_position := global_position
    var events := model.step(delta, requested_movement, dodge_requested, _snapshot_targets())

    if is_instance_valid(_phase_provider) and _phase_provider.has_method("resolve_player_position"):
        model.position = _phase_provider.call(
            "resolve_player_position",
            previous_position,
            model.position
        )

    velocity = Vector2.ZERO if delta <= 0.0 else (model.position - global_position) / delta
    global_position = model.position
    _resolve_events(events)
    echo_model.capture_step(delta, model.position, _current_phase_id())
    _advance_tactical_echo(delta)
    queue_redraw()


func _process(delta: float) -> void:
    if _feedback_remaining <= 0.0:
        return
    _feedback_remaining = maxf(0.0, _feedback_remaining - delta)
    if _feedback_remaining <= 0.0:
        modulate = Color.WHITE


func set_target_provider(provider: Node) -> void:
    _target_provider = provider


func set_phase_provider(provider: Object) -> void:
    _phase_provider = provider


func set_circuit_provider(provider: Object) -> void:
    _circuit_provider = provider


func equip_curated_weapon(weapon_id: String) -> bool:
    return weapon_model.equip_curated_weapon(weapon_id)


func weapon_status_snapshot() -> Dictionary:
    return {
        "weapon_id": weapon_model.equipped_weapon_id,
        "recipe": weapon_model.equipped_recipe(),
        "snapshot": weapon_model.snapshot(),
    }


func weapon_upgrade_comparison(candidate_weapon_id: String) -> Dictionary:
    return weapon_model.upgrade_comparison(candidate_weapon_id)


func restore_weapon_state(snapshot_state: Dictionary) -> bool:
    return weapon_model.restore_snapshot(snapshot_state)


func begin_tactical_echo_capture(record_id: String) -> bool:
    return echo_model.begin_capture(
        record_id,
        weapon_model.equipped_weapon_id,
        model.position
    )


func finish_tactical_echo_capture(outcome: String) -> Dictionary:
    return echo_model.finish_capture(outcome)


func cancel_tactical_echo_capture() -> void:
    echo_model.cancel_capture()


func select_tactical_echo_record(record: Dictionary) -> bool:
    return echo_model.select_record(record)


func tactical_echo_status_snapshot() -> Dictionary:
    return {
        "selection": echo_model.selection_status(),
        "replay": echo_model.replay_status_snapshot(),
        "snapshot": echo_model.snapshot(),
    }


func restore_tactical_echo_state(snapshot_state: Dictionary) -> bool:
    return echo_model.restore_snapshot(snapshot_state)


func cancel_tactical_echo(reason: String = "cancelled") -> bool:
    return echo_model.cancel_replay(reason)


func set_virtual_input(movement: Vector2, dodge_pressed: bool) -> void:
    _virtual_movement = movement.limit_length(1.0)
    if dodge_pressed:
        _virtual_dodge_queued = true


func clear_transient_input() -> void:
    _virtual_movement = Vector2.ZERO
    _virtual_dodge_queued = false
    _keyboard_dodge_down = false
    model.movement_input = Vector2.ZERO


func set_paused(value: bool) -> void:
    model.set_paused(value)
    if value:
        clear_transient_input()
    var tree := get_tree()
    if tree != null:
        tree.paused = value
    pause_changed.emit(value)


func take_damage(raw_damage: int, armor: int = 0) -> Dictionary:
    var result: Dictionary = model.take_damage(raw_damage, armor)
    var applied_damage := int(result.get("applied_damage", 0))
    if applied_damage > 0:
        _feedback_remaining = 0.10
        modulate = Color(1.0, 0.55, 0.45, 1.0)
        hit_feedback.emit(
            applied_damage,
            int(result.get("health", model.health)),
            int(result.get("feedback_generation", model.hit_feedback_generation))
        )
        queue_redraw()
    return result


func _keyboard_movement() -> Vector2:
    var x := 0.0
    var y := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        y += 1.0
    return Vector2(x, y).limit_length(1.0)


func _consume_keyboard_dodge_edge() -> bool:
    var currently_down := Input.is_key_pressed(KEY_SPACE)
    var just_pressed := currently_down and not _keyboard_dodge_down
    _keyboard_dodge_down = currently_down
    return just_pressed


func _snapshot_targets() -> Array[Dictionary]:
    var targets: Array[Dictionary] = []
    if is_instance_valid(_target_provider) and _target_provider.has_method("combat_target_snapshot"):
        var provided: Variant = _target_provider.call("combat_target_snapshot")
        if provided is Array:
            for item in provided:
                if item is Dictionary:
                    targets.append(item)
            return targets

    var tree := get_tree()
    if tree == null:
        return targets

    for candidate in tree.get_nodes_in_group("combat_targets"):
        if not candidate is Node2D or candidate == self:
            continue
        var target_node := candidate as Node2D
        var active := true
        if target_node.has_method("is_targetable"):
            active = bool(target_node.call("is_targetable"))
        targets.append({
            "id": target_node.get_instance_id(),
            "position": target_node.global_position,
            "active": active,
        })
    return targets


func _resolve_events(events: Array[Dictionary]) -> void:
    for event in events:
        var event_type := str(event.get("type", ""))
        if event_type != "auto_attack" and event_type != "dodge_started":
            continue
        _combat_event_generation += 1
        var causal_event := event.duplicate(true)
        causal_event["cause_id"] = "combat-%d-%d" % [
            weapon_model.resolution_generation,
            _combat_event_generation,
        ]
        causal_event["chain_depth"] = 0
        var target_snapshot := _snapshot_targets()
        var context := _weapon_context(causal_event, target_snapshot)
        var actions := weapon_model.resolve_event(causal_event, context)
        for action in actions:
            _apply_weapon_action(action, target_snapshot)


func _weapon_context(event: Dictionary, targets: Array[Dictionary]) -> Dictionary:
    var phase_id := _current_phase_id()
    var primary_position: Vector2 = model.position
    var primary_id := int(event.get("target_id", -1))
    var nearest_distance_squared: float = 1.0e30
    var nearest_target_id: int = 9223372036854775807
    for target in targets:
        if not bool(target.get("active", true)):
            continue
        var target_id := int(target.get("id", -1))
        var target_position: Vector2 = target.get("position", model.position)
        if target_id == primary_id:
            primary_position = target_position
            break
        if primary_id < 0:
            var distance_squared: float = model.position.distance_squared_to(target_position)
            if (
                distance_squared < nearest_distance_squared
                or (
                    is_equal_approx(distance_squared, nearest_distance_squared)
                    and target_id >= 0
                    and target_id < nearest_target_id
                )
            ):
                nearest_distance_squared = distance_squared
                nearest_target_id = target_id
                primary_position = target_position

    var active_modules: Array[String] = []
    var crosses_boundary := false
    if is_instance_valid(_circuit_provider) and _circuit_provider.has_method("active_circuits"):
        var active_value: Variant = _circuit_provider.call("active_circuits")
        if active_value is Array:
            for raw_circuit in active_value:
                if not raw_circuit is Dictionary:
                    continue
                var circuit: Dictionary = raw_circuit
                if str(circuit.get("phase", "")) != phase_id:
                    continue
                var module_id := str(circuit.get("module", ""))
                if not module_id.is_empty() and module_id not in active_modules:
                    active_modules.append(module_id)
                var polygon: PackedVector2Array = circuit.get("polygon", PackedVector2Array())
                if _segment_crosses_polygon_boundary(model.position, primary_position, polygon):
                    crosses_boundary = true

    return {
        "phase": phase_id,
        "targets": targets,
        "crosses_circuit_boundary": crosses_boundary,
        "active_circuit_modules": active_modules,
        "paused": model.paused,
        "ark_pressure_active": false,
        "phase_transition_recent": false,
    }


func _apply_weapon_action(action: Dictionary, targets: Array[Dictionary]) -> void:
    if str(action.get("type", "")) != "weapon_damage":
        return
    var target_id := int(action.get("target_id", -1))
    var damage := maxi(0, int(action.get("damage", 0)))
    if target_id < 0 or damage <= 0:
        return
    var handled := false
    if is_instance_valid(_target_provider) and _target_provider.has_method("apply_target_damage"):
        handled = bool(_target_provider.call("apply_target_damage", target_id, damage))
    if not handled:
        var target_object := instance_from_id(target_id)
        if target_object != null and is_instance_valid(target_object) and target_object.has_method("take_damage"):
            target_object.call("take_damage", damage)

    var direction := Vector2.ZERO
    for target in targets:
        if int(target.get("id", -1)) == target_id:
            var target_position: Vector2 = target.get("position", model.position)
            direction = model.position.direction_to(target_position)
            break
    echo_model.capture_fire(
        direction,
        damage,
        _current_phase_id(),
        str(action.get("cause_id", ""))
    )
    weapon_action.emit(action.duplicate(true))
    auto_attack.emit(target_id, damage, direction)


func _advance_tactical_echo(delta: float) -> void:
    if delta <= 0.0:
        return
    var phase_id := _current_phase_id()
    if is_instance_valid(_circuit_provider) and _circuit_provider.has_method("active_circuits"):
        var active_value: Variant = _circuit_provider.call("active_circuits")
        if active_value is Array:
            for raw_circuit in active_value:
                if not raw_circuit is Dictionary:
                    continue
                var circuit: Dictionary = raw_circuit
                if str(circuit.get("module", "")) != TacticalEchoModelScript.MODULE_ECHO_BEACON:
                    continue
                var activation := echo_model.try_activate_from_circuit(
                    int(circuit.get("id", 0)),
                    str(circuit.get("module", "")),
                    model.position,
                    phase_id
                )
                if bool(activation.get("accepted", false)):
                    var started_event := activation.duplicate(true)
                    started_event["type"] = "echo_started"
                    started_event["source"] = "tactical_echo"
                    tactical_echo_event.emit(started_event)

    var replay_events := echo_model.step_replay(
        delta,
        phase_id,
        _phase_provider,
        model.paused
    )
    for replay_event in replay_events:
        var event := replay_event.duplicate(true)
        if str(event.get("type", "")) == "echo_fire":
            event = _apply_tactical_echo_fire(event)
        tactical_echo_event.emit(event)


func _apply_tactical_echo_fire(action: Dictionary) -> Dictionary:
    var result := action.duplicate(true)
    var origin: Vector2 = action.get("origin", echo_model.replay_position)
    var direction: Vector2 = action.get("direction", Vector2.ZERO)
    if direction.is_zero_approx():
        result["hit"] = false
        result["reason"] = "direction"
        return result
    direction = direction.normalized()

    var best_id := -1
    var best_alignment := -1.0
    var best_distance := 1.0e30
    for target in _snapshot_targets():
        if not bool(target.get("active", true)):
            continue
        var target_id := int(target.get("id", -1))
        if target_id < 0:
            continue
        var target_position: Vector2 = target.get("position", origin)
        var offset := target_position - origin
        var distance := offset.length()
        if distance <= 0.001 or distance > 520.0:
            continue
        var alignment := direction.dot(offset / distance)
        if alignment < 0.45:
            continue
        if (
            alignment > best_alignment + 0.0001
            or (
                is_equal_approx(alignment, best_alignment)
                and (
                    distance < best_distance - 0.0001
                    or (is_equal_approx(distance, best_distance) and target_id < best_id)
                )
            )
        ):
            best_id = target_id
            best_alignment = alignment
            best_distance = distance

    if best_id < 0:
        result["hit"] = false
        result["reason"] = "no_target"
        return result

    var damage := maxi(1, int(action.get("damage", 1)))
    var handled := false
    if is_instance_valid(_target_provider) and _target_provider.has_method("apply_target_damage"):
        handled = bool(_target_provider.call("apply_target_damage", best_id, damage))
    if not handled:
        var target_object := instance_from_id(best_id)
        if target_object != null and is_instance_valid(target_object) and target_object.has_method("take_damage"):
            target_object.call("take_damage", damage)
            handled = true

    result["target_id"] = best_id
    result["hit"] = handled
    result["reason"] = "" if handled else "damage_unhandled"
    return result


func _current_phase_id() -> String:
    if is_instance_valid(_phase_provider):
        if _phase_provider.has_method("current_phase_id"):
            var phase_method_value := str(_phase_provider.call("current_phase_id"))
            if not phase_method_value.is_empty():
                return phase_method_value
        var phase_value: Variant = _phase_provider.get("current_phase")
        if phase_value != null and not str(phase_value).is_empty():
            return str(phase_value)
    return "material"


static func _segment_crosses_polygon_boundary(
    start: Vector2,
    finish: Vector2,
    polygon: PackedVector2Array
) -> bool:
    if polygon.size() < 3 or start.is_equal_approx(finish):
        return false
    for index in range(polygon.size()):
        var edge_start := polygon[index]
        var edge_finish := polygon[(index + 1) % polygon.size()]
        if _segments_intersect(start, finish, edge_start, edge_finish):
            return true
    return false


static func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
    var r := a2 - a1
    var s := b2 - b1
    var denominator := r.cross(s)
    if is_zero_approx(denominator):
        return false
    var offset := b1 - a1
    var t := offset.cross(s) / denominator
    var u := offset.cross(r) / denominator
    return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0


func _draw() -> void:
    var health_ratio := float(model.health) / float(CombatModelScript.MAX_HEALTH)
    draw_circle(Vector2.ZERO, 17.0, Color(0.96, 0.75, 0.31, 1.0))
    draw_arc(
        Vector2.ZERO,
        23.0,
        -PI * 0.5,
        -PI * 0.5 + TAU * health_ratio,
        32,
        Color(1.0, 0.93, 0.70, 0.95),
        4.0,
        true
    )
    if echo_model.replay_active:
        var echo_local := to_local(echo_model.replay_position)
        draw_circle(echo_local, 14.0, Color(0.68, 0.46, 0.96, 0.34))
        draw_arc(
            echo_local,
            19.0,
            0.0,
            TAU,
            28,
            Color(0.88, 0.72, 1.0, 0.72),
            2.0,
            true
        )
