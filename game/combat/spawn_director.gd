extends RefCounted

const DisclosedDoctrineModelScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")

const TIMER_EPSILON: float = 0.0001
const FIRST_SPAWN_TIME: float = 0.90
const TELEGRAPH_LEAD: float = 0.65
const BOSS_TIME: float = 24.0
const BOSS_WARNING_LEAD: float = 2.0
const DOCTRINE_WARNING_TIME: float = 0.15

var elapsed_time: float = 0.0
var _seed: int = 1
var _sequence: int = 0
var _next_regular_time: float = FIRST_SPAWN_TIME
var _pending: Array[Dictionary] = []
var _boss_scheduled: bool = false
var _entry_direction: Vector2 = Vector2.ZERO
var _threat_level: int = 1
var _doctrine_plan: Dictionary = DisclosedDoctrineModelScript.neutral_plan()
var _doctrine_warning_emitted: bool = false
var _world_provider: Object


func reset(seed: int = 1) -> void:
    elapsed_time = 0.0
    _seed = maxi(1, absi(seed))
    _sequence = 0
    _next_regular_time = FIRST_SPAWN_TIME
    _pending.clear()
    _boss_scheduled = false
    _entry_direction = Vector2.ZERO
    _threat_level = 1
    _doctrine_warning_emitted = false


func set_route_context(entry_direction: Vector2, threat_level: int) -> void:
    _entry_direction = Vector2.ZERO if entry_direction.is_zero_approx() else entry_direction.normalized()
    _threat_level = clampi(threat_level, 1, 3)


func configure_world_provider(provider: Object) -> void:
    _world_provider = provider


func configure_doctrine(plan: Dictionary) -> bool:
    if not DisclosedDoctrineModelScript.validate_plan(plan):
        return false
    _doctrine_plan = plan.duplicate(true)
    _doctrine_warning_emitted = false
    return true


func doctrine_disclosure() -> Dictionary:
    var disclosure = _doctrine_plan.get("disclosure", {})
    if disclosure is Dictionary:
        var result: Dictionary = disclosure.duplicate(true)
        result["active"] = bool(_doctrine_plan.get("active", false))
        result["doctrine_id"] = str(_doctrine_plan.get("doctrine_id", "none"))
        return result
    return {}


func step(delta: float, origin: Vector2) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if delta <= 0.0:
        return events

    elapsed_time += delta
    if (
        bool(_doctrine_plan.get("active", false))
        and not _doctrine_warning_emitted
        and elapsed_time + TIMER_EPSILON >= DOCTRINE_WARNING_TIME
    ):
        _doctrine_warning_emitted = true
        var disclosure := doctrine_disclosure()
        var counterplay = disclosure.get("counterplay", [])
        events.append({
            "type": "doctrine_warning",
            "doctrine_id": str(_doctrine_plan.get("doctrine_id", "none")),
            "title": str(disclosure.get("title", "")),
            "summary": str(disclosure.get("summary", "")),
            "formation": str(_doctrine_plan.get("formation", "baseline")),
            "response_cap": float(_doctrine_plan.get("response_cap", 0.0)),
            "counterplay": counterplay.duplicate(true) if counterplay is Array else [],
            "segment_index": int(_doctrine_plan.get("segment_index", 0)),
        })

    while elapsed_time + TIMER_EPSILON >= _next_regular_time:
        var scheduled_at := _next_regular_time
        var spawn_count := mini(4, 1 + int(floor(scheduled_at / 10.0)) + (_threat_level - 1))
        for _index in spawn_count:
            var doctrine_response := _is_doctrine_response(_sequence)
            var base_archetype := _regular_archetype(_sequence)
            _queue_spawn(
                _doctrine_archetype(base_archetype, doctrine_response),
                origin,
                scheduled_at,
                TELEGRAPH_LEAD,
                events,
                doctrine_response,
                _doctrine_formation(doctrine_response)
            )
        _next_regular_time += _regular_interval(scheduled_at)

    if (
        not _boss_scheduled
        and elapsed_time + TIMER_EPSILON >= BOSS_TIME - BOSS_WARNING_LEAD
    ):
        _boss_scheduled = true
        _queue_spawn(
            "boss",
            origin,
            BOSS_TIME - BOSS_WARNING_LEAD,
            BOSS_WARNING_LEAD,
            events
        )

    var remaining: Array[Dictionary] = []
    for pending in _pending:
        if elapsed_time + TIMER_EPSILON >= float(pending.get("spawn_at", INF)):
            var spawn_event := pending.duplicate(true)
            spawn_event["type"] = "spawn"
            events.append(spawn_event)
        else:
            remaining.append(pending)
    _pending = remaining

    return events


func pending_count() -> int:
    return _pending.size()


func _queue_spawn(
    archetype: String,
    origin: Vector2,
    scheduled_at: float,
    warning_lead: float,
    events: Array[Dictionary],
    doctrine_response: bool = false,
    formation: String = "baseline"
) -> void:
    var spawn_id := "w05-%06d" % _sequence
    var spawn_position := _spawn_position(_sequence, origin)
    if doctrine_response:
        spawn_position = _doctrine_spawn_position(_sequence, origin)
    spawn_position = _resolve_spawn_position(spawn_position, origin)
    var pending := {
        "spawn_id": spawn_id,
        "archetype": archetype,
        "position": spawn_position,
        "scheduled_at": scheduled_at,
        "spawn_at": scheduled_at + warning_lead,
        "telegraph_duration": warning_lead,
        "doctrine_response": doctrine_response,
        "doctrine_id": str(_doctrine_plan.get("doctrine_id", "none")) if doctrine_response else "",
        "formation": formation,
    }
    _pending.append(pending)

    var telegraph := pending.duplicate(true)
    telegraph["type"] = "telegraph"
    events.append(telegraph)
    _sequence += 1


func _regular_archetype(sequence: int) -> String:
    return "runner" if sequence % 5 == 4 else "swarm"


func _regular_interval(scheduled_at: float) -> float:
    var baseline := maxf(0.55, 1.15 - minf(0.45, scheduled_at * 0.012))
    return baseline / (1.0 + float(_threat_level - 1) * 0.16)


func _spawn_position(sequence: int, origin: Vector2) -> Vector2:
    var distance := 360.0 + _sample01(sequence, 43) * 160.0
    if _entry_direction.is_zero_approx():
        var angle := _sample01(sequence, 17) * TAU
        return origin + Vector2.RIGHT.rotated(angle) * distance
    var spread := (_sample01(sequence, 73) - 0.5) * PI * 0.70
    return origin + _entry_direction.rotated(spread) * distance


func _is_doctrine_response(sequence: int) -> bool:
    if not bool(_doctrine_plan.get("active", false)):
        return false
    var stride := int(_doctrine_plan.get("response_stride", 0))
    return stride > 0 and (sequence + 1) % stride == 0


func _doctrine_archetype(base_archetype: String, doctrine_response: bool) -> String:
    if not doctrine_response:
        return base_archetype
    var response_archetype := str(_doctrine_plan.get("response_archetype", ""))
    return base_archetype if response_archetype.is_empty() else response_archetype


func _doctrine_formation(doctrine_response: bool) -> String:
    if not doctrine_response:
        return "baseline"
    return str(_doctrine_plan.get("formation", "baseline"))


func _doctrine_spawn_position(sequence: int, origin: Vector2) -> Vector2:
    var axis := _entry_direction
    if axis.is_zero_approx():
        axis = Vector2.RIGHT.rotated(_sample01(sequence, 157) * TAU)
    var distance := 390.0 + _sample01(sequence, 181) * 90.0
    match str(_doctrine_plan.get("doctrine_id", "")):
        "cover_advance":
            var tangent := Vector2(-axis.y, axis.x)
            var side := -1.0 if _sample01(sequence, 211) < 0.5 else 1.0
            var lateral := 58.0 + _sample01(sequence, 227) * 52.0
            return origin + axis * distance + tangent * lateral * side
        "dispersed_ambush":
            var side := -1.0 if _sample01(sequence, 233) < 0.5 else 1.0
            var angle := side * (0.90 + _sample01(sequence, 251) * 0.45)
            return origin + axis.rotated(angle) * distance
    return _spawn_position(sequence, origin)


func _resolve_spawn_position(candidate: Vector2, origin: Vector2) -> Vector2:
    if is_instance_valid(_world_provider) and _world_provider.has_method("resolve_spawn_position"):
        var resolved: Variant = _world_provider.call("resolve_spawn_position", candidate, origin)
        if resolved is Vector2:
            return resolved
    return candidate


func _sample01(sequence: int, salt: int) -> float:
    var modulus: int = 2147483647
    var value := (_seed * 48271 + (sequence + 1) * 69621 + salt * 104729) % modulus
    return float(absi(value)) / float(modulus)
