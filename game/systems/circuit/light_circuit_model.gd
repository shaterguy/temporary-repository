extends RefCounted

const SNAPSHOT_SCHEMA: String = "light-circuit-v1"
const MODULE_ARK_WARD: String = "ark_ward"
const MODULE_SNARE: String = "snare"
const MODULE_ECHO_BEACON: String = "echo_beacon"

const TRAIL_WINDOW_SECONDS: float = 8.0
const MAX_ACTIVE_CIRCUITS: int = 2
const REACTIVATION_COOLDOWN_SECONDS: float = 3.0
const CIRCUIT_DURATION_SECONDS: float = 10.0
const MAX_LIGHT: float = 100.0
const LIGHT_COST: float = 35.0
const LIGHT_REGEN_PER_SECOND: float = 5.0
const MIN_SAMPLE_DISTANCE: float = 8.0
const CLOSE_DISTANCE: float = 28.0
const MIN_LOOP_PERIMETER: float = 180.0
const MIN_LOOP_AREA: float = 2400.0
const MAX_CONTIGUOUS_SEGMENT: float = 220.0
const ARK_WARD_DAMAGE_MULTIPLIER: float = 0.50
const SNARE_MOVEMENT_MULTIPLIER: float = 0.55
const GEOMETRY_EPSILON: float = 0.001

var elapsed_time: float = 0.0
var current_light: float = MAX_LIGHT
var cooldown_remaining: float = 0.0
var activation_generation: int = 0
var current_module: String = MODULE_ARK_WARD
var world_phase: String = "material"
var last_rejection_reason: String = ""

var _trail: Array[Dictionary] = []
var _active_circuits: Array[Dictionary] = []


func reset() -> void:
    elapsed_time = 0.0
    current_light = MAX_LIGHT
    cooldown_remaining = 0.0
    activation_generation = 0
    current_module = MODULE_ARK_WARD
    world_phase = "material"
    last_rejection_reason = ""
    _trail.clear()
    _active_circuits.clear()


func select_module(module_id: String) -> bool:
    if not _is_valid_module(module_id):
        return false
    current_module = module_id
    return true


func set_world_phase(phase_id: String) -> bool:
    if phase_id.is_empty():
        return false
    if phase_id == world_phase:
        return true
    world_phase = phase_id
    _trail.clear()
    last_rejection_reason = "phase_changed"
    return true


func step(delta: float, world_position: Vector2, paused: bool = false) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if delta <= 0.0 or paused:
        return events

    elapsed_time += delta
    current_light = minf(MAX_LIGHT, current_light + LIGHT_REGEN_PER_SECOND * delta)
    cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
    _advance_active_circuits(delta, events)
    _prune_trail()

    if _trail.is_empty():
        _append_sample(world_position)
        return events

    var previous_position: Vector2 = _trail[_trail.size() - 1].get("position", world_position)
    var segment_length := previous_position.distance_to(world_position)
    if segment_length > MAX_CONTIGUOUS_SEGMENT:
        _trail.clear()
        _append_sample(world_position)
        last_rejection_reason = "teleport_segment"
        events.append({"type": "circuit_rejected", "reason": last_rejection_reason})
        return events
    if segment_length < MIN_SAMPLE_DISTANCE:
        return events

    _append_sample(world_position)
    var candidate := _find_closed_candidate()
    if candidate.is_empty():
        return events

    var polygon: PackedVector2Array = candidate.get("polygon", PackedVector2Array())
    var rejection_reason := _validate_polygon(polygon)
    if rejection_reason.is_empty() and cooldown_remaining > 0.0:
        rejection_reason = "cooldown"
    if rejection_reason.is_empty() and _active_circuits.size() >= MAX_ACTIVE_CIRCUITS:
        rejection_reason = "capacity"
    if rejection_reason.is_empty() and current_light + GEOMETRY_EPSILON < LIGHT_COST:
        rejection_reason = "insufficient_light"

    if not rejection_reason.is_empty():
        last_rejection_reason = rejection_reason
        _trail.clear()
        _append_sample(world_position)
        events.append({
            "type": "circuit_rejected",
            "reason": rejection_reason,
            "light": current_light,
            "active_count": _active_circuits.size(),
        })
        return events

    activation_generation += 1
    current_light = maxf(0.0, current_light - LIGHT_COST)
    cooldown_remaining = REACTIVATION_COOLDOWN_SECONDS
    var circuit := {
        "id": activation_generation,
        "module": current_module,
        "phase": world_phase,
        "polygon": polygon,
        "remaining": CIRCUIT_DURATION_SECONDS,
    }
    _active_circuits.append(circuit)
    last_rejection_reason = ""
    _trail.clear()
    _append_sample(world_position)
    events.append({
        "type": "circuit_activated",
        "circuit_id": activation_generation,
        "module": current_module,
        "phase": world_phase,
        "polygon": polygon,
        "light": current_light,
        "active_count": _active_circuits.size(),
    })
    return events


func active_circuit_count() -> int:
    return _active_circuits.size()


func active_circuits() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for circuit in _active_circuits:
        result.append(circuit.duplicate(true))
    return result


func trail_points() -> PackedVector2Array:
    var points := PackedVector2Array()
    for sample in _trail:
        points.append(sample.get("position", Vector2.ZERO))
    return points


func movement_multiplier_at(world_position: Vector2) -> float:
    if _point_has_module(world_position, MODULE_SNARE):
        return SNARE_MOVEMENT_MULTIPLIER
    return 1.0


func ward_damage_multiplier_at(world_position: Vector2) -> float:
    if _point_has_module(world_position, MODULE_ARK_WARD):
        return ARK_WARD_DAMAGE_MULTIPLIER
    return 1.0


func mitigate_damage_at(world_position: Vector2, raw_damage: int) -> int:
    if raw_damage <= 0:
        return 0
    var multiplier := ward_damage_multiplier_at(world_position)
    return maxi(1, ceili(float(raw_damage) * multiplier))


func snapshot() -> Dictionary:
    var encoded_circuits: Array[Dictionary] = []
    for circuit in _active_circuits:
        var polygon: PackedVector2Array = circuit.get("polygon", PackedVector2Array())
        encoded_circuits.append({
            "id": int(circuit.get("id", 0)),
            "module": str(circuit.get("module", MODULE_ARK_WARD)),
            "phase": str(circuit.get("phase", world_phase)),
            "polygon": _encode_polygon(polygon),
            "remaining": float(circuit.get("remaining", 0.0)),
        })
    return {
        "schema": SNAPSHOT_SCHEMA,
        "elapsed_time": elapsed_time,
        "light": current_light,
        "cooldown_remaining": cooldown_remaining,
        "activation_generation": activation_generation,
        "current_module": current_module,
        "world_phase": world_phase,
        "active_circuits": encoded_circuits,
        "trail_policy": "reset_on_restore",
    }


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    if str(snapshot_state.get("schema", "")) != SNAPSHOT_SCHEMA:
        return false
    var restored_module := str(snapshot_state.get("current_module", MODULE_ARK_WARD))
    var restored_phase := str(snapshot_state.get("world_phase", "material"))
    var restored_elapsed := float(snapshot_state.get("elapsed_time", 0.0))
    var restored_light := float(snapshot_state.get("light", MAX_LIGHT))
    var restored_cooldown := float(snapshot_state.get("cooldown_remaining", 0.0))
    var restored_generation := int(snapshot_state.get("activation_generation", 0))
    if (
        not _is_valid_module(restored_module)
        or restored_phase.is_empty()
        or restored_elapsed < 0.0
        or restored_light < 0.0
        or restored_light > MAX_LIGHT + GEOMETRY_EPSILON
        or restored_cooldown < 0.0
        or restored_generation < 0
    ):
        return false

    var encoded_active: Variant = snapshot_state.get("active_circuits", [])
    if not encoded_active is Array:
        return false
    var raw_active: Array = encoded_active
    if raw_active.size() > MAX_ACTIVE_CIRCUITS:
        return false

    var rebuilt: Array[Dictionary] = []
    for raw_item in raw_active:
        if not raw_item is Dictionary:
            return false
        var item: Dictionary = raw_item
        var module_id := str(item.get("module", ""))
        var phase_id := str(item.get("phase", ""))
        var remaining := float(item.get("remaining", 0.0))
        var circuit_id := int(item.get("id", 0))
        var polygon := _decode_polygon(item.get("polygon", []))
        if (
            not _is_valid_module(module_id)
            or phase_id.is_empty()
            or remaining <= 0.0
            or circuit_id <= 0
            or not _validate_polygon(polygon).is_empty()
        ):
            return false
        rebuilt.append({
            "id": circuit_id,
            "module": module_id,
            "phase": phase_id,
            "polygon": polygon,
            "remaining": remaining,
        })

    elapsed_time = restored_elapsed
    current_light = restored_light
    cooldown_remaining = restored_cooldown
    activation_generation = restored_generation
    current_module = restored_module
    world_phase = restored_phase
    last_rejection_reason = ""
    _trail.clear()
    _active_circuits.clear()
    _active_circuits.append_array(rebuilt)
    return true


func _advance_active_circuits(delta: float, events: Array[Dictionary]) -> void:
    for index in range(_active_circuits.size() - 1, -1, -1):
        var circuit: Dictionary = _active_circuits[index]
        var remaining := maxf(0.0, float(circuit.get("remaining", 0.0)) - delta)
        if remaining <= 0.0:
            events.append({
                "type": "circuit_expired",
                "circuit_id": int(circuit.get("id", 0)),
                "module": str(circuit.get("module", "")),
            })
            _active_circuits.remove_at(index)
        else:
            circuit["remaining"] = remaining
            _active_circuits[index] = circuit


func _append_sample(world_position: Vector2) -> void:
    _trail.append({
        "position": world_position,
        "time": elapsed_time,
        "phase": world_phase,
    })


func _prune_trail() -> void:
    var cutoff := elapsed_time - TRAIL_WINDOW_SECONDS
    while not _trail.is_empty() and float(_trail[0].get("time", 0.0)) < cutoff:
        _trail.remove_at(0)


func _find_closed_candidate() -> Dictionary:
    if _trail.size() < 4:
        return {}
    var current_position: Vector2 = _trail[_trail.size() - 1].get("position", Vector2.ZERO)
    for start_index in range(0, _trail.size() - 3):
        var start_position: Vector2 = _trail[start_index].get("position", Vector2.ZERO)
        if current_position.distance_to(start_position) > CLOSE_DISTANCE:
            continue
        if _path_length_from(start_index) < MIN_LOOP_PERIMETER:
            continue
        var polygon := PackedVector2Array()
        for sample_index in range(start_index, _trail.size() - 1):
            polygon.append(_trail[sample_index].get("position", Vector2.ZERO))
        if polygon.size() >= 3:
            return {"polygon": polygon}
    return {}


func _path_length_from(start_index: int) -> float:
    var total := 0.0
    for index in range(start_index + 1, _trail.size()):
        var previous: Vector2 = _trail[index - 1].get("position", Vector2.ZERO)
        var current: Vector2 = _trail[index].get("position", Vector2.ZERO)
        total += previous.distance_to(current)
    return total


func _validate_polygon(polygon: PackedVector2Array) -> String:
    if polygon.size() < 3:
        return "too_few_points"
    if _polygon_perimeter(polygon) < MIN_LOOP_PERIMETER:
        return "insufficient_length"
    if _polygon_area(polygon) < MIN_LOOP_AREA:
        return "insufficient_area"
    if _has_self_intersection(polygon):
        return "self_intersection"
    return ""


func _polygon_perimeter(polygon: PackedVector2Array) -> float:
    var total := 0.0
    for index in range(polygon.size()):
        total += polygon[index].distance_to(polygon[(index + 1) % polygon.size()])
    return total


func _polygon_area(polygon: PackedVector2Array) -> float:
    var twice_area := 0.0
    for index in range(polygon.size()):
        var current := polygon[index]
        var next := polygon[(index + 1) % polygon.size()]
        twice_area += current.x * next.y - next.x * current.y
    return absf(twice_area) * 0.5


func _has_self_intersection(polygon: PackedVector2Array) -> bool:
    var segment_count := polygon.size()
    for first_index in range(segment_count):
        var first_next := (first_index + 1) % segment_count
        for second_index in range(first_index + 1, segment_count):
            var second_next := (second_index + 1) % segment_count
            if first_next == second_index or second_next == first_index:
                continue
            if first_index == 0 and second_next == 0:
                continue
            if _segments_intersect(
                polygon[first_index],
                polygon[first_next],
                polygon[second_index],
                polygon[second_next]
            ):
                return true
    return false


func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
    var o1 := (a2 - a1).cross(b1 - a1)
    var o2 := (a2 - a1).cross(b2 - a1)
    var o3 := (b2 - b1).cross(a1 - b1)
    var o4 := (b2 - b1).cross(a2 - b1)
    if (
        ((o1 > GEOMETRY_EPSILON and o2 < -GEOMETRY_EPSILON) or (o1 < -GEOMETRY_EPSILON and o2 > GEOMETRY_EPSILON))
        and ((o3 > GEOMETRY_EPSILON and o4 < -GEOMETRY_EPSILON) or (o3 < -GEOMETRY_EPSILON and o4 > GEOMETRY_EPSILON))
    ):
        return true
    if absf(o1) <= GEOMETRY_EPSILON and _point_on_segment(b1, a1, a2):
        return true
    if absf(o2) <= GEOMETRY_EPSILON and _point_on_segment(b2, a1, a2):
        return true
    if absf(o3) <= GEOMETRY_EPSILON and _point_on_segment(a1, b1, b2):
        return true
    if absf(o4) <= GEOMETRY_EPSILON and _point_on_segment(a2, b1, b2):
        return true
    return false


func _point_on_segment(point: Vector2, start: Vector2, finish: Vector2) -> bool:
    return (
        point.x >= minf(start.x, finish.x) - GEOMETRY_EPSILON
        and point.x <= maxf(start.x, finish.x) + GEOMETRY_EPSILON
        and point.y >= minf(start.y, finish.y) - GEOMETRY_EPSILON
        and point.y <= maxf(start.y, finish.y) + GEOMETRY_EPSILON
    )


func _point_has_module(world_position: Vector2, module_id: String) -> bool:
    for circuit in _active_circuits:
        if str(circuit.get("module", "")) != module_id:
            continue
        if str(circuit.get("phase", "")) != world_phase:
            continue
        var polygon: PackedVector2Array = circuit.get("polygon", PackedVector2Array())
        if _point_in_polygon_or_boundary(world_position, polygon):
            return true
    return false


func _point_in_polygon_or_boundary(point: Vector2, polygon: PackedVector2Array) -> bool:
    if polygon.size() < 3:
        return false
    for index in range(polygon.size()):
        if _point_on_segment(point, polygon[index], polygon[(index + 1) % polygon.size()]):
            return true

    var inside := false
    var previous_index := polygon.size() - 1
    for index in range(polygon.size()):
        var current := polygon[index]
        var previous := polygon[previous_index]
        var crosses := (current.y > point.y) != (previous.y > point.y)
        if crosses:
            var denominator := previous.y - current.y
            if absf(denominator) > GEOMETRY_EPSILON:
                var intersect_x := (previous.x - current.x) * (point.y - current.y) / denominator + current.x
                if point.x < intersect_x:
                    inside = not inside
        previous_index = index
    return inside


func _encode_polygon(polygon: PackedVector2Array) -> Array:
    var encoded: Array = []
    for point in polygon:
        encoded.append([point.x, point.y])
    return encoded


func _decode_polygon(encoded: Variant) -> PackedVector2Array:
    var polygon := PackedVector2Array()
    if not encoded is Array:
        return polygon
    var values: Array = encoded
    for value in values:
        if not value is Array:
            return PackedVector2Array()
        var pair: Array = value
        if pair.size() < 2:
            return PackedVector2Array()
        polygon.append(Vector2(float(pair[0]), float(pair[1])))
    return polygon


func _is_valid_module(module_id: String) -> bool:
    return (
        module_id == MODULE_ARK_WARD
        or module_id == MODULE_SNARE
        or module_id == MODULE_ECHO_BEACON
    )
