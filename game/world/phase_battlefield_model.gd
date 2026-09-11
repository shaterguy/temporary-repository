extends RefCounted

const MedievalWorldLayoutScript = preload("res://game/world/medieval_world_layout.gd")

const SNAPSHOT_SCHEMA: String = "phase-battlefield-v1"
const PHASE_MATERIAL: String = "material"
const PHASE_SHADOW: String = "shadow"
const SWITCH_COOLDOWN_SECONDS: float = 4.0
const WORLD_BOUNDS: Rect2 = MedievalWorldLayoutScript.WORLD_BOUNDS
const MATERIAL_BLOCKERS := [
    Rect2(500.0, 250.0, 120.0, 220.0),
    Rect2(860.0, 390.0, 170.0, 80.0),
]
const SHADOW_BLOCKERS := [
    Rect2(720.0, 240.0, 120.0, 220.0),
    Rect2(250.0, 420.0, 180.0, 90.0),
]
const MATERIAL_COVER := [
    Rect2(210.0, 250.0, 100.0, 36.0),
    Rect2(930.0, 235.0, 120.0, 36.0),
]
const SHADOW_COVER := [
    Rect2(430.0, 190.0, 120.0, 36.0),
    Rect2(900.0, 520.0, 120.0, 36.0),
]
const GEOMETRY_EPSILON: float = 0.0001

var current_phase: String = PHASE_MATERIAL
var cooldown_remaining: float = 0.0
var transition_generation: int = 0
var last_rejection_reason: String = ""
var last_transition_position: Vector2 = Vector2.ZERO
var last_preview_threat_count: int = 0


func reset() -> void:
    current_phase = PHASE_MATERIAL
    cooldown_remaining = 0.0
    transition_generation = 0
    last_rejection_reason = ""
    last_transition_position = Vector2.ZERO
    last_preview_threat_count = 0


func current_phase_id() -> String:
    return current_phase


func other_phase(phase_id: String = "") -> String:
    var source := current_phase if phase_id.is_empty() else phase_id
    if source == PHASE_MATERIAL:
        return PHASE_SHADOW
    if source == PHASE_SHADOW:
        return PHASE_MATERIAL
    return ""


func step(delta: float, paused: bool = false) -> void:
    if delta <= 0.0 or paused:
        return
    cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func transition_preview(world_position: Vector2, immediate_threat_count: int = 0) -> Dictionary:
    var target_phase := other_phase()
    var rejection_reason := _occupancy_rejection(target_phase, world_position)
    return {
        "from_phase": current_phase,
        "target_phase": target_phase,
        "position": world_position,
        "valid": rejection_reason.is_empty() and cooldown_remaining <= 0.0,
        "blocked_reason": rejection_reason if not rejection_reason.is_empty() else ("cooldown" if cooldown_remaining > 0.0 else ""),
        "cooldown_remaining": cooldown_remaining,
        "immediate_threat_count": maxi(0, immediate_threat_count),
    }


func request_transition(
    world_position: Vector2,
    immediate_threat_count: int = 0,
    paused: bool = false,
    cancelled: bool = false
) -> Dictionary:
    if cancelled:
        last_rejection_reason = "cancelled"
        return _rejected_transition(world_position, immediate_threat_count)
    if paused:
        last_rejection_reason = "paused"
        return _rejected_transition(world_position, immediate_threat_count)
    if cooldown_remaining > 0.0:
        last_rejection_reason = "cooldown"
        return _rejected_transition(world_position, immediate_threat_count)

    var target_phase := other_phase()
    var rejection_reason := _occupancy_rejection(target_phase, world_position)
    if not rejection_reason.is_empty():
        last_rejection_reason = rejection_reason
        return _rejected_transition(world_position, immediate_threat_count)

    var previous_phase := current_phase
    current_phase = target_phase
    cooldown_remaining = SWITCH_COOLDOWN_SECONDS
    transition_generation += 1
    last_rejection_reason = ""
    last_transition_position = world_position
    last_preview_threat_count = maxi(0, immediate_threat_count)
    return {
        "accepted": true,
        "from_phase": previous_phase,
        "phase": current_phase,
        "position": world_position,
        "cooldown_remaining": cooldown_remaining,
        "generation": transition_generation,
        "immediate_threat_count": last_preview_threat_count,
    }


func is_position_walkable(phase_id: String, world_position: Vector2) -> bool:
    return _occupancy_rejection(phase_id, world_position).is_empty()


func resolve_player_position(from_position: Vector2, proposed_position: Vector2) -> Vector2:
    return _resolve_actor_position(from_position, proposed_position)


func resolve_enemy_position(from_position: Vector2, proposed_position: Vector2) -> Vector2:
    return _resolve_actor_position(from_position, proposed_position)


func is_spawn_position_allowed(world_position: Vector2) -> bool:
    return is_spawn_position_allowed_for_phase(current_phase, world_position)


func is_spawn_position_allowed_for_phase(phase_id: String, world_position: Vector2) -> bool:
    return (
        MedievalWorldLayoutScript.is_spawn_position_allowed(world_position)
        and _occupancy_rejection(phase_id, world_position).is_empty()
    )


func resolve_spawn_position(candidate: Vector2, origin: Vector2) -> Vector2:
    return resolve_spawn_position_for_phase(candidate, origin, current_phase)


func resolve_spawn_position_for_phase(
    candidate: Vector2,
    origin: Vector2,
    phase_id: String
) -> Vector2:
    var resolved: Vector2 = MedievalWorldLayoutScript.resolve_spawn_position(candidate, origin)
    if is_spawn_position_allowed_for_phase(phase_id, resolved):
        return resolved

    var radial := candidate - origin
    if radial.is_zero_approx():
        radial = Vector2.RIGHT
    var base_radius := maxf(360.0, radial.length())
    var base_angle := radial.angle()
    for ring_index in range(5):
        var radius := base_radius + float(ring_index) * 84.0
        for angle_index in range(24):
            var angle := base_angle + float(angle_index) * TAU / 24.0
            var probe := MedievalWorldLayoutScript.clamp_to_world(
                origin + Vector2.RIGHT.rotated(angle) * radius,
                MedievalWorldLayoutScript.WORLD_EDGE_MARGIN
            )
            if is_spawn_position_allowed_for_phase(phase_id, probe):
                return probe
    return resolved


func blocker_rects(phase_id: String) -> Array:
    var result: Array = MedievalWorldLayoutScript.shared_blocker_rects()
    if phase_id == PHASE_MATERIAL:
        result.append_array(MATERIAL_BLOCKERS)
    elif phase_id == PHASE_SHADOW:
        result.append_array(SHADOW_BLOCKERS)
    return result


func cover_rects(phase_id: String) -> Array:
    if phase_id == PHASE_MATERIAL:
        return MATERIAL_COVER.duplicate()
    if phase_id == PHASE_SHADOW:
        return SHADOW_COVER.duplicate()
    return []


func spawn_phase_for(archetype: String) -> String:
    if archetype == "runner" or archetype == "boss":
        return PHASE_SHADOW
    return PHASE_MATERIAL


func enemy_phase_for(_entity_id: int, archetype: String) -> String:
    return spawn_phase_for(archetype)


func is_enemy_targetable(enemy_phase: String) -> bool:
    return enemy_phase == current_phase


func is_attack_path_blocked(phase_id: String, start: Vector2, finish: Vector2) -> bool:
    if not _is_valid_phase(phase_id):
        return true
    if not WORLD_BOUNDS.has_point(start) or not WORLD_BOUNDS.has_point(finish):
        return true
    for blocker_value in blocker_rects(phase_id):
        var blocker: Rect2 = blocker_value
        if (
            blocker.has_point(start)
            or blocker.has_point(finish)
            or _segment_intersects_rect(start, finish, blocker)
        ):
            return true
    return false


func snapshot() -> Dictionary:
    return {
        "schema": SNAPSHOT_SCHEMA,
        "phase": current_phase,
        "cooldown_remaining": cooldown_remaining,
        "transition_generation": transition_generation,
        "last_transition_position": [last_transition_position.x, last_transition_position.y],
    }


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    if str(snapshot_state.get("schema", "")) != SNAPSHOT_SCHEMA:
        return false
    var restored_phase := str(snapshot_state.get("phase", ""))
    var restored_cooldown := float(snapshot_state.get("cooldown_remaining", -1.0))
    var restored_generation := int(snapshot_state.get("transition_generation", -1))
    var encoded_position: Variant = snapshot_state.get("last_transition_position", [])
    if (
        not _is_valid_phase(restored_phase)
        or restored_cooldown < 0.0
        or restored_cooldown > SWITCH_COOLDOWN_SECONDS + GEOMETRY_EPSILON
        or restored_generation < 0
        or not encoded_position is Array
        or encoded_position.size() != 2
    ):
        return false

    current_phase = restored_phase
    cooldown_remaining = restored_cooldown
    transition_generation = restored_generation
    last_transition_position = Vector2(float(encoded_position[0]), float(encoded_position[1]))
    last_rejection_reason = ""
    last_preview_threat_count = 0
    return true


func _resolve_actor_position(from_position: Vector2, proposed_position: Vector2) -> Vector2:
    if from_position.is_equal_approx(proposed_position):
        return proposed_position
    if not WORLD_BOUNDS.has_point(proposed_position):
        return from_position
    for blocker_value in blocker_rects(current_phase):
        var blocker: Rect2 = blocker_value
        if blocker.has_point(proposed_position) or _segment_intersects_rect(from_position, proposed_position, blocker):
            return from_position
    return proposed_position


func _rejected_transition(world_position: Vector2, immediate_threat_count: int) -> Dictionary:
    return {
        "accepted": false,
        "from_phase": current_phase,
        "phase": current_phase,
        "position": world_position,
        "reason": last_rejection_reason,
        "cooldown_remaining": cooldown_remaining,
        "generation": transition_generation,
        "immediate_threat_count": maxi(0, immediate_threat_count),
    }


func _occupancy_rejection(phase_id: String, world_position: Vector2) -> String:
    if not _is_valid_phase(phase_id):
        return "invalid_phase"
    if not WORLD_BOUNDS.has_point(world_position):
        return "map_edge"
    for blocker_value in blocker_rects(phase_id):
        var blocker: Rect2 = blocker_value
        if blocker.has_point(world_position):
            return "blocked_destination"
    return ""


func _is_valid_phase(phase_id: String) -> bool:
    return phase_id == PHASE_MATERIAL or phase_id == PHASE_SHADOW


func _segment_intersects_rect(start: Vector2, finish: Vector2, rect: Rect2) -> bool:
    var top_left := rect.position
    var top_right := Vector2(rect.end.x, rect.position.y)
    var bottom_right := rect.end
    var bottom_left := Vector2(rect.position.x, rect.end.y)
    return (
        _segments_intersect(start, finish, top_left, top_right)
        or _segments_intersect(start, finish, top_right, bottom_right)
        or _segments_intersect(start, finish, bottom_right, bottom_left)
        or _segments_intersect(start, finish, bottom_left, top_left)
    )


func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
    var r := a2 - a1
    var s := b2 - b1
    var denominator := r.cross(s)
    if absf(denominator) <= GEOMETRY_EPSILON:
        return false
    var offset := b1 - a1
    var t := offset.cross(s) / denominator
    var u := offset.cross(r) / denominator
    return (
        t >= -GEOMETRY_EPSILON
        and t <= 1.0 + GEOMETRY_EPSILON
        and u >= -GEOMETRY_EPSILON
        and u <= 1.0 + GEOMETRY_EPSILON
    )
