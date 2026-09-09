extends RefCounted

const MOVE_SPEED: float = 260.0
const DODGE_SPEED: float = 720.0
const DODGE_DURATION: float = 0.16
const DODGE_COOLDOWN: float = 0.90
const ATTACK_INTERVAL: float = 0.55
const ATTACK_RANGE: float = 460.0
const ATTACK_DAMAGE: int = 12
const MAX_HEALTH: int = 100
const TIMER_EPSILON: float = 0.0001

var position: Vector2 = Vector2.ZERO
var health: int = MAX_HEALTH
var movement_input: Vector2 = Vector2.ZERO
var dodge_direction: Vector2 = Vector2.ZERO
var dodge_remaining: float = 0.0
var dodge_cooldown_remaining: float = 0.0
var attack_cooldown_remaining: float = 0.0
var paused: bool = false
var hit_feedback_generation: int = 0


func reset(origin: Vector2 = Vector2.ZERO) -> void:
    position = origin
    health = MAX_HEALTH
    movement_input = Vector2.ZERO
    dodge_direction = Vector2.ZERO
    dodge_remaining = 0.0
    dodge_cooldown_remaining = 0.0
    attack_cooldown_remaining = 0.0
    paused = false
    hit_feedback_generation = 0


func set_paused(value: bool) -> void:
    paused = value
    if paused:
        movement_input = Vector2.ZERO


func step(
    delta: float,
    requested_movement: Vector2,
    dodge_requested: bool,
    targets: Array[Dictionary]
) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if delta <= 0.0 or paused or health <= 0:
        return events

    movement_input = requested_movement.limit_length(1.0)
    dodge_cooldown_remaining = _advance_timer(dodge_cooldown_remaining, delta)
    attack_cooldown_remaining = _advance_timer(attack_cooldown_remaining, delta)

    if (
        dodge_requested
        and dodge_remaining <= 0.0
        and dodge_cooldown_remaining <= 0.0
        and not movement_input.is_zero_approx()
    ):
        dodge_direction = movement_input.normalized()
        dodge_remaining = DODGE_DURATION
        dodge_cooldown_remaining = DODGE_COOLDOWN
        events.append({
            "type": "dodge_started",
            "direction": dodge_direction,
        })

    var movement_velocity := movement_input * MOVE_SPEED
    if dodge_remaining > 0.0:
        movement_velocity = dodge_direction * DODGE_SPEED
        dodge_remaining = _advance_timer(dodge_remaining, delta)
    position += movement_velocity * delta

    if attack_cooldown_remaining <= 0.0:
        var target := select_nearest_target(position, targets, ATTACK_RANGE)
        if not target.is_empty():
            var target_position: Vector2 = target.get("position", position)
            attack_cooldown_remaining = ATTACK_INTERVAL
            events.append({
                "type": "auto_attack",
                "target_id": int(target.get("id", -1)),
                "damage": ATTACK_DAMAGE,
                "direction": position.direction_to(target_position),
            })

    return events


func take_damage(raw_damage: int, armor: int = 0) -> Dictionary:
    if raw_damage <= 0 or health <= 0:
        return _damage_result(0, false)
    if is_invulnerable():
        return _damage_result(0, true)

    var applied_damage := maxi(1, raw_damage - maxi(0, armor))
    applied_damage = mini(applied_damage, health)
    health -= applied_damage
    hit_feedback_generation += 1
    return _damage_result(applied_damage, false)


func is_invulnerable() -> bool:
    return dodge_remaining > 0.0


func is_alive() -> bool:
    return health > 0


func _damage_result(applied_damage: int, blocked: bool) -> Dictionary:
    return {
        "applied_damage": applied_damage,
        "blocked": blocked,
        "health": health,
        "killed": health <= 0,
        "feedback_generation": hit_feedback_generation,
    }


static func _advance_timer(value: float, delta: float) -> float:
    var remaining := maxf(0.0, value - delta)
    return 0.0 if remaining <= TIMER_EPSILON else remaining


static func select_nearest_target(
    origin: Vector2,
    candidates: Array[Dictionary],
    max_range: float
) -> Dictionary:
    if max_range < 0.0:
        return {}

    var best_target: Dictionary = {}
    var best_distance_squared := max_range * max_range
    var best_id: int = 9223372036854775807

    for candidate in candidates:
        if not bool(candidate.get("active", true)):
            continue
        if not candidate.has("id") or not candidate.has("position"):
            continue

        var position_value: Variant = candidate.get("position")
        if typeof(position_value) != TYPE_VECTOR2:
            continue

        var candidate_id := int(candidate.get("id", -1))
        if candidate_id < 0:
            continue

        var candidate_position: Vector2 = position_value
        var distance_squared := origin.distance_squared_to(candidate_position)
        if distance_squared > best_distance_squared + TIMER_EPSILON:
            continue

        if (
            best_target.is_empty()
            or distance_squared < best_distance_squared - TIMER_EPSILON
            or (is_equal_approx(distance_squared, best_distance_squared) and candidate_id < best_id)
        ):
            best_target = candidate
            best_distance_squared = distance_squared
            best_id = candidate_id

    return best_target
