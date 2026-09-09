extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")

const RECORD_SCHEMA: String = "tactical-echo-record-v1"
const SNAPSHOT_SCHEMA: String = "tactical-echo-v1"
const MODULE_ECHO_BEACON: String = "echo_beacon"
const PHASE_MATERIAL: String = "material"
const PHASE_SHADOW: String = "shadow"
const MAX_RECORD_DURATION_SECONDS: float = 8.0
const MAX_RECORD_EVENTS: int = 128
const MAX_CONSUMED_CIRCUITS: int = 32
const MIN_CAPTURE_SAMPLE_SECONDS: float = 0.08
const ECHO_POWER_MULTIPLIER: float = 0.45
const EPSILON: float = 0.0001

var selected_record: Dictionary = {}
var last_rejection_reason: String = ""
var replay_active: bool = false
var replay_elapsed: float = 0.0
var replay_position: Vector2 = Vector2.ZERO
var replay_origin: Vector2 = Vector2.ZERO
var replay_phase: String = PHASE_MATERIAL
var replay_circuit_id: int = 0
var _replay_event_index: int = 0
var _consumed_circuit_ids: Array[int] = []

var capture_active: bool = false
var capture_elapsed: float = 0.0
var _capture_record_id: String = ""
var _capture_weapon_id: String = ""
var _capture_origin: Vector2 = Vector2.ZERO
var _capture_events: Array[Dictionary] = []
var _capture_last_move_time: float = -1.0
var _capture_seen_causes: Dictionary = {}


func reset() -> void:
    selected_record.clear()
    last_rejection_reason = ""
    replay_active = false
    replay_elapsed = 0.0
    replay_position = Vector2.ZERO
    replay_origin = Vector2.ZERO
    replay_phase = PHASE_MATERIAL
    replay_circuit_id = 0
    _replay_event_index = 0
    _consumed_circuit_ids.clear()
    _reset_capture()


static func make_record(
    record_id: String,
    weapon_id: String,
    duration: float,
    raw_events: Array,
    outcome: String
) -> Dictionary:
    var events: Array[Dictionary] = []
    for index in range(raw_events.size()):
        var raw_event: Variant = raw_events[index]
        if not raw_event is Dictionary:
            events.append({"order": index, "type": "invalid", "time": -1.0})
            continue
        var event: Dictionary = raw_event.duplicate(true)
        event["order"] = index
        events.append(event)
    return {
        "schema": RECORD_SCHEMA,
        "record_id": record_id,
        "weapon_id": weapon_id,
        "duration": duration,
        "outcome": outcome,
        "events": events,
    }


static func validate_record(record: Dictionary) -> Dictionary:
    if str(record.get("schema", "")) != RECORD_SCHEMA:
        return {"valid": false, "reason": "record_schema"}
    var record_id := str(record.get("record_id", ""))
    if record_id.is_empty():
        return {"valid": false, "reason": "record_id"}
    var weapon_id := str(record.get("weapon_id", ""))
    if not _is_known_weapon(weapon_id):
        return {"valid": false, "reason": "weapon_incompatible"}
    var duration := float(record.get("duration", -1.0))
    if duration <= 0.0 or duration > MAX_RECORD_DURATION_SECONDS + EPSILON:
        return {"valid": false, "reason": "duration_out_of_range"}
    var outcome := str(record.get("outcome", ""))
    if outcome not in ["completed", "failed", "abandoned"]:
        return {"valid": false, "reason": "outcome"}

    var raw_events: Variant = record.get("events", [])
    if not raw_events is Array:
        return {"valid": false, "reason": "events_type"}
    var events: Array = raw_events
    if events.is_empty():
        return {"valid": false, "reason": "events_empty"}
    if events.size() > MAX_RECORD_EVENTS:
        return {"valid": false, "reason": "events_capacity"}

    var previous_time := -EPSILON
    for index in range(events.size()):
        var raw_event: Variant = events[index]
        if not raw_event is Dictionary:
            return {"valid": false, "reason": "event_type"}
        var event: Dictionary = raw_event
        if int(event.get("order", -1)) != index:
            return {"valid": false, "reason": "event_order"}
        var event_time := float(event.get("time", -1.0))
        if event_time < 0.0 or event_time > duration + EPSILON:
            return {"valid": false, "reason": "event_time_range"}
        if event_time + EPSILON < previous_time:
            return {"valid": false, "reason": "event_time_order"}
        previous_time = event_time
        var phase_id := str(event.get("phase", ""))
        if not _is_valid_phase(phase_id):
            return {"valid": false, "reason": "event_phase"}

        var event_type := str(event.get("type", ""))
        if event_type == "move":
            if not _is_encoded_vector(event.get("offset", null), true):
                return {"valid": false, "reason": "move_offset"}
        elif event_type == "fire":
            if str(event.get("weapon_id", "")) != weapon_id:
                return {"valid": false, "reason": "event_weapon_mismatch"}
            if not _is_encoded_vector(event.get("direction", null), false):
                return {"valid": false, "reason": "fire_direction"}
            if int(event.get("base_damage", 0)) <= 0:
                return {"valid": false, "reason": "fire_damage"}
        else:
            return {"valid": false, "reason": "event_kind"}

    return {
        "valid": true,
        "reason": "",
        "record_id": record_id,
        "weapon_id": weapon_id,
        "duration": duration,
        "event_count": events.size(),
        "outcome": outcome,
    }


func select_record(record: Dictionary) -> bool:
    var validation := validate_record(record)
    if not bool(validation.get("valid", false)):
        selected_record.clear()
        last_rejection_reason = "record_unequipped:%s" % str(validation.get("reason", "invalid"))
        return false
    selected_record = record.duplicate(true)
    last_rejection_reason = ""
    return true


func clear_selected_record(reason: String = "cleared") -> void:
    selected_record.clear()
    last_rejection_reason = reason
    cancel_replay(reason)


func selection_status() -> Dictionary:
    return {
        "selected": not selected_record.is_empty(),
        "record_id": str(selected_record.get("record_id", "")),
        "weapon_id": str(selected_record.get("weapon_id", "")),
        "reason": last_rejection_reason,
    }


func begin_capture(record_id: String, weapon_id: String, origin: Vector2) -> bool:
    if record_id.is_empty():
        last_rejection_reason = "capture_record_id"
        return false
    if not _is_known_weapon(weapon_id):
        last_rejection_reason = "capture_weapon_incompatible"
        return false
    _reset_capture()
    capture_active = true
    _capture_record_id = record_id
    _capture_weapon_id = weapon_id
    _capture_origin = origin
    last_rejection_reason = ""
    return true


func capture_step(delta: float, world_position: Vector2, phase_id: String) -> bool:
    if not capture_active or delta <= 0.0 or not _is_valid_phase(phase_id):
        return false
    if capture_elapsed >= MAX_RECORD_DURATION_SECONDS - EPSILON:
        return false
    capture_elapsed = minf(MAX_RECORD_DURATION_SECONDS, capture_elapsed + delta)
    if _capture_events.size() >= MAX_RECORD_EVENTS:
        return false
    if (
        _capture_last_move_time >= 0.0
        and capture_elapsed - _capture_last_move_time + EPSILON < MIN_CAPTURE_SAMPLE_SECONDS
    ):
        return false
    _capture_events.append({
        "order": _capture_events.size(),
        "time": capture_elapsed,
        "type": "move",
        "offset": _encode_vector(world_position - _capture_origin),
        "phase": phase_id,
    })
    _capture_last_move_time = capture_elapsed
    return true


func capture_fire(
    direction: Vector2,
    base_damage: int,
    phase_id: String,
    cause_id: String = ""
) -> bool:
    if (
        not capture_active
        or capture_elapsed > MAX_RECORD_DURATION_SECONDS + EPSILON
        or _capture_events.size() >= MAX_RECORD_EVENTS
        or direction.is_zero_approx()
        or base_damage <= 0
        or not _is_valid_phase(phase_id)
    ):
        return false
    if not cause_id.is_empty():
        if _capture_seen_causes.has(cause_id):
            return false
        _capture_seen_causes[cause_id] = true
    _capture_events.append({
        "order": _capture_events.size(),
        "time": capture_elapsed,
        "type": "fire",
        "weapon_id": _capture_weapon_id,
        "direction": _encode_vector(direction.normalized()),
        "base_damage": base_damage,
        "phase": phase_id,
    })
    return true


func finish_capture(outcome: String) -> Dictionary:
    if not capture_active:
        last_rejection_reason = "capture_inactive"
        return {}
    capture_active = false
    var duration := maxf(EPSILON, minf(capture_elapsed, MAX_RECORD_DURATION_SECONDS))
    var record := make_record(
        _capture_record_id,
        _capture_weapon_id,
        duration,
        _capture_events,
        outcome
    )
    var validation := validate_record(record)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = "capture_invalid:%s" % str(validation.get("reason", "invalid"))
        return {}
    last_rejection_reason = ""
    return record


func cancel_capture() -> void:
    _reset_capture()


func try_activate_from_circuit(
    circuit_id: int,
    module_id: String,
    origin: Vector2,
    current_phase: String
) -> Dictionary:
    if module_id != MODULE_ECHO_BEACON:
        return {"accepted": false, "reason": "not_echo_beacon"}
    if circuit_id <= 0:
        last_rejection_reason = "circuit_id"
        return {"accepted": false, "reason": last_rejection_reason}
    if circuit_id in _consumed_circuit_ids:
        last_rejection_reason = "circuit_already_consumed"
        return {"accepted": false, "reason": last_rejection_reason}

    _remember_consumed_circuit(circuit_id)
    if replay_active:
        last_rejection_reason = "echo_active"
        return {"accepted": false, "reason": last_rejection_reason}
    if not _is_valid_phase(current_phase):
        last_rejection_reason = "activation_phase"
        return {"accepted": false, "reason": last_rejection_reason}
    var validation := validate_record(selected_record)
    if not bool(validation.get("valid", false)):
        selected_record.clear()
        last_rejection_reason = "record_unequipped:%s" % str(validation.get("reason", "missing"))
        return {"accepted": false, "reason": last_rejection_reason}

    replay_active = true
    replay_elapsed = 0.0
    replay_origin = origin
    replay_position = origin
    replay_phase = current_phase
    replay_circuit_id = circuit_id
    _replay_event_index = 0
    last_rejection_reason = ""
    return {
        "accepted": true,
        "circuit_id": circuit_id,
        "record_id": str(selected_record.get("record_id", "")),
        "weapon_id": str(selected_record.get("weapon_id", "")),
        "phase": replay_phase,
        "position": replay_position,
    }


func step_replay(
    delta: float,
    current_phase: String,
    position_resolver: Object = null,
    paused: bool = false
) -> Array[Dictionary]:
    var actions: Array[Dictionary] = []
    if not replay_active or delta <= 0.0 or paused:
        return actions
    if not _is_valid_phase(current_phase):
        var cancelled_id := replay_circuit_id
        cancel_replay("invalid_current_phase")
        actions.append({
            "type": "echo_cancelled",
            "reason": "invalid_current_phase",
            "circuit_id": cancelled_id,
        })
        return actions

    replay_elapsed = minf(
        float(selected_record.get("duration", MAX_RECORD_DURATION_SECONDS)),
        replay_elapsed + delta
    )
    var events: Array = selected_record.get("events", [])
    while _replay_event_index < events.size():
        var event: Dictionary = events[_replay_event_index]
        if float(event.get("time", 0.0)) > replay_elapsed + EPSILON:
            break
        var event_order := _replay_event_index
        _replay_event_index += 1
        var event_type := str(event.get("type", ""))
        if event_type == "move":
            var requested_position := replay_origin + _decode_vector(event.get("offset", []))
            var resolved_position := requested_position
            if (
                position_resolver != null
                and is_instance_valid(position_resolver)
                and position_resolver.has_method("resolve_player_position")
            ):
                resolved_position = position_resolver.call(
                    "resolve_player_position",
                    replay_position,
                    requested_position
                )
            replay_position = resolved_position
            actions.append({
                "type": "echo_move",
                "order": event_order,
                "position": replay_position,
                "requested_position": requested_position,
                "collision_blocked": not replay_position.is_equal_approx(requested_position),
                "recorded_phase": str(event.get("phase", "")),
                "current_phase": current_phase,
                "phase_changed": str(event.get("phase", "")) != current_phase,
                "source": "tactical_echo",
            })
        elif event_type == "fire":
            var recorded_phase := str(event.get("phase", ""))
            if recorded_phase != current_phase:
                actions.append({
                    "type": "echo_fire_blocked",
                    "order": event_order,
                    "reason": "phase_mismatch",
                    "recorded_phase": recorded_phase,
                    "current_phase": current_phase,
                    "source": "tactical_echo",
                })
                continue
            var base_damage := maxi(1, int(event.get("base_damage", 1)))
            actions.append({
                "type": "echo_fire",
                "order": event_order,
                "origin": replay_position,
                "direction": _decode_vector(event.get("direction", [])).normalized(),
                "weapon_id": str(event.get("weapon_id", "")),
                "damage": maxi(1, roundi(float(base_damage) * ECHO_POWER_MULTIPLIER)),
                "power_multiplier": ECHO_POWER_MULTIPLIER,
                "recorded_phase": recorded_phase,
                "current_phase": current_phase,
                "source": "tactical_echo",
                "allow_echo_spawn": false,
                "allow_rewards": false,
                "allow_achievements": false,
                "allow_circuit_charge": false,
                "allow_causal_chain": false,
            })

    var duration := float(selected_record.get("duration", 0.0))
    if _replay_event_index >= events.size() and replay_elapsed + EPSILON >= duration:
        var finished_id := replay_circuit_id
        var finished_record := str(selected_record.get("record_id", ""))
        replay_active = false
        actions.append({
            "type": "echo_finished",
            "circuit_id": finished_id,
            "record_id": finished_record,
            "position": replay_position,
            "source": "tactical_echo",
        })
    return actions


func cancel_replay(reason: String = "cancelled") -> bool:
    if not replay_active:
        return false
    replay_active = false
    replay_elapsed = 0.0
    _replay_event_index = 0
    replay_circuit_id = 0
    last_rejection_reason = reason
    return true


func replay_status_snapshot() -> Dictionary:
    return {
        "active": replay_active,
        "elapsed": replay_elapsed,
        "position": replay_position,
        "origin": replay_origin,
        "phase": replay_phase,
        "circuit_id": replay_circuit_id,
        "record_id": str(selected_record.get("record_id", "")),
        "weapon_id": str(selected_record.get("weapon_id", "")),
        "next_event_index": _replay_event_index,
        "reason": last_rejection_reason,
    }


func snapshot() -> Dictionary:
    return {
        "schema": SNAPSHOT_SCHEMA,
        "selected_record": selected_record.duplicate(true),
        "consumed_circuit_ids": _consumed_circuit_ids.duplicate(),
        "replay_policy": "cancel_on_restore",
        "capture_policy": "discard_on_restore",
    }


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    if str(snapshot_state.get("schema", "")) != SNAPSHOT_SCHEMA:
        return false
    var raw_consumed: Variant = snapshot_state.get("consumed_circuit_ids", [])
    if not raw_consumed is Array:
        return false

    _consumed_circuit_ids.clear()
    for raw_id in raw_consumed:
        var circuit_id := int(raw_id)
        if circuit_id <= 0 or circuit_id in _consumed_circuit_ids:
            continue
        _consumed_circuit_ids.append(circuit_id)
        if _consumed_circuit_ids.size() >= MAX_CONSUMED_CIRCUITS:
            break

    selected_record.clear()
    var raw_record: Variant = snapshot_state.get("selected_record", {})
    if raw_record is Dictionary and not raw_record.is_empty():
        var validation := validate_record(raw_record)
        if bool(validation.get("valid", false)):
            selected_record = raw_record.duplicate(true)
            last_rejection_reason = ""
        else:
            last_rejection_reason = "record_unequipped:%s" % str(validation.get("reason", "invalid"))
    else:
        last_rejection_reason = ""

    replay_active = false
    replay_elapsed = 0.0
    replay_position = Vector2.ZERO
    replay_origin = Vector2.ZERO
    replay_phase = PHASE_MATERIAL
    replay_circuit_id = 0
    _replay_event_index = 0
    _reset_capture()
    return true


func _remember_consumed_circuit(circuit_id: int) -> void:
    _consumed_circuit_ids.append(circuit_id)
    while _consumed_circuit_ids.size() > MAX_CONSUMED_CIRCUITS:
        _consumed_circuit_ids.pop_front()


func _reset_capture() -> void:
    capture_active = false
    capture_elapsed = 0.0
    _capture_record_id = ""
    _capture_weapon_id = ""
    _capture_origin = Vector2.ZERO
    _capture_events.clear()
    _capture_last_move_time = -1.0
    _capture_seen_causes.clear()


static func _is_known_weapon(weapon_id: String) -> bool:
    if weapon_id.is_empty():
        return false
    var recipe := WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
    if recipe.is_empty():
        return false
    return bool(WeaponPartCatalogScript.validate_recipe(recipe).get("valid", false))


static func _is_valid_phase(phase_id: String) -> bool:
    return phase_id == PHASE_MATERIAL or phase_id == PHASE_SHADOW


static func _is_encoded_vector(value: Variant, allow_zero: bool) -> bool:
    if not value is Array or value.size() != 2:
        return false
    var first_type := typeof(value[0])
    var second_type := typeof(value[1])
    if (
        first_type != TYPE_INT and first_type != TYPE_FLOAT
    ) or (
        second_type != TYPE_INT and second_type != TYPE_FLOAT
    ):
        return false
    if allow_zero:
        return true
    return not Vector2(float(value[0]), float(value[1])).is_zero_approx()


static func _encode_vector(value: Vector2) -> Array[float]:
    return [value.x, value.y]


static func _decode_vector(value: Variant) -> Vector2:
    if not value is Array or value.size() != 2:
        return Vector2.ZERO
    return Vector2(float(value[0]), float(value[1]))