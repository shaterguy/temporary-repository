extends RefCounted

const STATUS_AWAITING_ROUTE: String = "AWAITING_ROUTE"
const STATUS_TRAVELING: String = "TRAVELING"
const STATUS_RESTING: String = "RESTING"
const STATUS_ARRIVED: String = "ARRIVED"
const STATUS_FAILED_RECOVERABLE: String = "FAILED_RECOVERABLE"
const JUNCTION_ID: String = "dockyard-crossing"
const MAX_DURABILITY: int = 1000
const MAX_SUPPLY_POD_INTEGRITY: int = 220
const STARTING_SUPPLY: int = 60
const RECOVERY_SUPPLY_COST: int = 20
const POD_LOSS_SUPPLY_PENALTY: int = 12
const DISTANCE_EPSILON: float = 0.001

var run_seed: int = 1
var status: String = STATUS_AWAITING_ROUTE
var selected_route_id: String = ""
var position: Vector2 = Vector2.ZERO
var distance_travelled: float = 0.0
var route_distance: float = 0.0
var durability: int = MAX_DURABILITY
var supply: int = STARTING_SUPPLY
var supply_pod_integrity: int = MAX_SUPPLY_POD_INTEGRITY
var paused: bool = false
var choice_generation: int = 0
var completion_generation: int = 0
var recovery_count: int = 0
var failure_reason: String = ""
var _arrival_reward_applied: bool = false
var _pod_loss_penalty_applied: bool = false


func _init() -> void:
    reset(1)


func reset(seed: int = 1) -> void:
    run_seed = maxi(1, absi(seed))
    status = STATUS_AWAITING_ROUTE
    selected_route_id = ""
    position = Vector2.ZERO
    distance_travelled = 0.0
    route_distance = 0.0
    durability = MAX_DURABILITY
    supply = STARTING_SUPPLY
    supply_pod_integrity = MAX_SUPPLY_POD_INTEGRITY
    paused = false
    choice_generation = 0
    completion_generation = 0
    recovery_count = 0
    failure_reason = ""
    _arrival_reward_applied = false
    _pod_loss_penalty_applied = false


func route_ids() -> PackedStringArray:
    return PackedStringArray(["risk_channel", "supply_causeway"])


func route_preview(route_id: String) -> Dictionary:
    var config := _route_config(route_id)
    if config.is_empty():
        return {}
    var distance := _route_distance(config)
    var speed := maxf(1.0, float(config.get("travel_speed", 1.0)))
    var supply_cost := int(config.get("supply_cost", 0))
    var supply_reward := int(config.get("supply_reward", 0))
    return {
        "junction_id": JUNCTION_ID,
        "route_id": route_id,
        "threat_level": int(config.get("threat_level", 1)),
        "reward_id": str(config.get("reward_id", "")),
        "supply_cost": supply_cost,
        "supply_reward": supply_reward,
        "estimated_supply_delta": supply_reward - supply_cost,
        "travel_speed": speed,
        "distance": distance,
        "estimated_time": distance / speed,
        "entry_direction": config.get("entry_direction", Vector2.ZERO),
        "defend_target": str(config.get("defend_target", "ark_core")),
        "rest_at_destination": true,
        "destination": _route_destination(config),
    }


func choose_route(junction_id: String, route_id: String) -> bool:
    if junction_id != JUNCTION_ID:
        return false
    if not selected_route_id.is_empty():
        return selected_route_id == route_id
    if status != STATUS_AWAITING_ROUTE:
        return false

    var config := _route_config(route_id)
    if config.is_empty():
        return false
    var supply_cost := int(config.get("supply_cost", 0))
    if supply < supply_cost:
        return false

    selected_route_id = route_id
    supply -= supply_cost
    choice_generation += 1
    route_distance = _route_distance(config)
    distance_travelled = 0.0
    position = _position_at_distance(config, 0.0)
    status = STATUS_TRAVELING
    return true


func set_paused(value: bool) -> void:
    paused = value


func step(delta: float) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if delta <= 0.0 or paused or status != STATUS_TRAVELING:
        return events

    var config := _route_config(selected_route_id)
    if config.is_empty():
        return events

    var speed := maxf(1.0, float(config.get("travel_speed", 1.0)))
    distance_travelled = minf(route_distance, distance_travelled + speed * delta)
    position = _position_at_distance(config, distance_travelled)

    if distance_travelled + DISTANCE_EPSILON >= route_distance:
        if not _arrival_reward_applied:
            supply += int(config.get("supply_reward", 0))
            _arrival_reward_applied = true
            completion_generation += 1
        status = STATUS_RESTING
        events.append({
            "type": "route_reached_rest",
            "route_id": selected_route_id,
            "destination": position,
            "supply": supply,
            "completion_generation": completion_generation,
        })
    return events


func resume_after_rest() -> bool:
    if status != STATUS_RESTING:
        return false
    if distance_travelled + DISTANCE_EPSILON < route_distance:
        status = STATUS_TRAVELING
    else:
        status = STATUS_ARRIVED
    return true


func apply_ark_damage(raw_damage: int, warning_visible: bool = true) -> bool:
    if raw_damage <= 0 or not warning_visible or status == STATUS_FAILED_RECOVERABLE:
        return false
    durability = maxi(0, durability - raw_damage)
    if durability == 0:
        status = STATUS_FAILED_RECOVERABLE
        failure_reason = "ark_breached"
    return true


func apply_objective_damage(raw_damage: int, warning_visible: bool = true) -> bool:
    if raw_damage <= 0 or not warning_visible or selected_route_id.is_empty():
        return false
    var context := route_combat_context()
    if str(context.get("defend_target", "ark_core")) == "supply_pod":
        supply_pod_integrity = maxi(0, supply_pod_integrity - raw_damage)
        if supply_pod_integrity == 0 and not _pod_loss_penalty_applied:
            supply = maxi(0, supply - POD_LOSS_SUPPLY_PENALTY)
            _pod_loss_penalty_applied = true
        return true
    return apply_ark_damage(raw_damage, true)


func recover_from_failure() -> bool:
    if status != STATUS_FAILED_RECOVERABLE or supply < RECOVERY_SUPPLY_COST:
        return false
    supply -= RECOVERY_SUPPLY_COST
    durability = maxi(1, int(MAX_DURABILITY / 2))
    recovery_count += 1
    failure_reason = ""
    if distance_travelled + DISTANCE_EPSILON < route_distance:
        status = STATUS_TRAVELING
    else:
        status = STATUS_RESTING
    return true


func route_progress() -> float:
    if route_distance <= DISTANCE_EPSILON:
        return 0.0
    return clampf(distance_travelled / route_distance, 0.0, 1.0)


func route_combat_context() -> Dictionary:
    var config := _route_config(selected_route_id)
    if config.is_empty():
        return {
            "entry_direction": Vector2.ZERO,
            "threat_level": 1,
            "defend_target": "ark_core",
        }
    return {
        "entry_direction": config.get("entry_direction", Vector2.ZERO),
        "threat_level": int(config.get("threat_level", 1)),
        "defend_target": str(config.get("defend_target", "ark_core")),
    }


func objective_offset() -> Vector2:
    if str(route_combat_context().get("defend_target", "ark_core")) == "supply_pod":
        return Vector2(-72.0, 34.0)
    return Vector2.ZERO


func snapshot() -> Dictionary:
    return {
        "schema": "ark-route-v1",
        "run_seed": run_seed,
        "status": status,
        "selected_route_id": selected_route_id,
        "distance_travelled": distance_travelled,
        "route_distance": route_distance,
        "durability": durability,
        "supply": supply,
        "supply_pod_integrity": supply_pod_integrity,
        "paused": paused,
        "choice_generation": choice_generation,
        "completion_generation": completion_generation,
        "recovery_count": recovery_count,
        "failure_reason": failure_reason,
        "arrival_reward_applied": _arrival_reward_applied,
        "pod_loss_penalty_applied": _pod_loss_penalty_applied,
    }


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    if str(snapshot_state.get("schema", "")) != "ark-route-v1":
        return false
    var route_id := str(snapshot_state.get("selected_route_id", ""))
    if not route_id.is_empty() and _route_config(route_id).is_empty():
        return false
    var restored_status := str(snapshot_state.get("status", STATUS_AWAITING_ROUTE))
    if restored_status == STATUS_TRAVELING and route_id.is_empty():
        return false

    run_seed = maxi(1, absi(int(snapshot_state.get("run_seed", 1))))
    selected_route_id = route_id
    status = restored_status
    durability = clampi(int(snapshot_state.get("durability", MAX_DURABILITY)), 0, MAX_DURABILITY)
    supply = maxi(0, int(snapshot_state.get("supply", STARTING_SUPPLY)))
    supply_pod_integrity = clampi(
        int(snapshot_state.get("supply_pod_integrity", MAX_SUPPLY_POD_INTEGRITY)),
        0,
        MAX_SUPPLY_POD_INTEGRITY
    )
    paused = bool(snapshot_state.get("paused", false))
    choice_generation = maxi(0, int(snapshot_state.get("choice_generation", 0)))
    completion_generation = maxi(0, int(snapshot_state.get("completion_generation", 0)))
    recovery_count = maxi(0, int(snapshot_state.get("recovery_count", 0)))
    failure_reason = str(snapshot_state.get("failure_reason", ""))
    _arrival_reward_applied = bool(snapshot_state.get("arrival_reward_applied", false))
    _pod_loss_penalty_applied = bool(snapshot_state.get("pod_loss_penalty_applied", false))

    if selected_route_id.is_empty():
        route_distance = 0.0
        distance_travelled = 0.0
        position = Vector2.ZERO
    else:
        var config := _route_config(selected_route_id)
        route_distance = _route_distance(config)
        distance_travelled = clampf(
            float(snapshot_state.get("distance_travelled", 0.0)),
            0.0,
            route_distance
        )
        position = _position_at_distance(config, distance_travelled)
    return true


func _route_config(route_id: String) -> Dictionary:
    match route_id:
        "risk_channel":
            return {
                "points": PackedVector2Array([
                    Vector2.ZERO,
                    Vector2(150.0, -112.0),
                    Vector2(360.0, -92.0),
                    Vector2(520.0, 0.0),
                ]),
                "travel_speed": 92.0,
                "threat_level": 3,
                "supply_cost": 12,
                "supply_reward": 4,
                "reward_id": "volatile_salvage",
                "entry_direction": Vector2(1.0, -0.35).normalized(),
                "defend_target": "ark_core",
            }
        "supply_causeway":
            return {
                "points": PackedVector2Array([
                    Vector2.ZERO,
                    Vector2(112.0, 96.0),
                    Vector2(252.0, 154.0),
                    Vector2(414.0, 74.0),
                    Vector2(520.0, 0.0),
                ]),
                "travel_speed": 58.0,
                "threat_level": 1,
                "supply_cost": 8,
                "supply_reward": 24,
                "reward_id": "lantern_provisions",
                "entry_direction": Vector2(-1.0, 0.25).normalized(),
                "defend_target": "supply_pod",
            }
    return {}


func _route_distance(config: Dictionary) -> float:
    var points: PackedVector2Array = config.get("points", PackedVector2Array())
    var total := 0.0
    for index in range(maxi(0, points.size() - 1)):
        total += points[index].distance_to(points[index + 1])
    return total


func _route_destination(config: Dictionary) -> Vector2:
    var points: PackedVector2Array = config.get("points", PackedVector2Array())
    if points.is_empty():
        return Vector2.ZERO
    return points[points.size() - 1]


func _position_at_distance(config: Dictionary, target_distance: float) -> Vector2:
    var points: PackedVector2Array = config.get("points", PackedVector2Array())
    if points.is_empty():
        return Vector2.ZERO
    var remaining := maxf(0.0, target_distance)
    for index in range(maxi(0, points.size() - 1)):
        var start := points[index]
        var finish := points[index + 1]
        var segment_length := start.distance_to(finish)
        if remaining <= segment_length or segment_length <= DISTANCE_EPSILON:
            var weight := 0.0 if segment_length <= DISTANCE_EPSILON else remaining / segment_length
            return start.lerp(finish, clampf(weight, 0.0, 1.0))
        remaining -= segment_length
    return points[points.size() - 1]
