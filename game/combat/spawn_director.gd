extends RefCounted

const TIMER_EPSILON: float = 0.0001
const FIRST_SPAWN_TIME: float = 0.90
const TELEGRAPH_LEAD: float = 0.65
const BOSS_TIME: float = 24.0
const BOSS_WARNING_LEAD: float = 2.0

var elapsed_time: float = 0.0
var _seed: int = 1
var _sequence: int = 0
var _next_regular_time: float = FIRST_SPAWN_TIME
var _pending: Array[Dictionary] = []
var _boss_scheduled: bool = false
var _entry_direction: Vector2 = Vector2.ZERO
var _threat_level: int = 1


func reset(seed: int = 1) -> void:
    elapsed_time = 0.0
    _seed = maxi(1, absi(seed))
    _sequence = 0
    _next_regular_time = FIRST_SPAWN_TIME
    _pending.clear()
    _boss_scheduled = false
    _entry_direction = Vector2.ZERO
    _threat_level = 1


func set_route_context(entry_direction: Vector2, threat_level: int) -> void:
    _entry_direction = Vector2.ZERO if entry_direction.is_zero_approx() else entry_direction.normalized()
    _threat_level = clampi(threat_level, 1, 3)


func step(delta: float, origin: Vector2) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if delta <= 0.0:
        return events

    elapsed_time += delta

    while elapsed_time + TIMER_EPSILON >= _next_regular_time:
        var scheduled_at := _next_regular_time
        var spawn_count := mini(4, 1 + int(floor(scheduled_at / 10.0)) + (_threat_level - 1))
        for _index in spawn_count:
            _queue_spawn(
                _regular_archetype(_sequence),
                origin,
                scheduled_at,
                TELEGRAPH_LEAD,
                events
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
    events: Array[Dictionary]
) -> void:
    var spawn_id := "w05-%06d" % _sequence
    var spawn_position := _spawn_position(_sequence, origin)
    var pending := {
        "spawn_id": spawn_id,
        "archetype": archetype,
        "position": spawn_position,
        "scheduled_at": scheduled_at,
        "spawn_at": scheduled_at + warning_lead,
        "telegraph_duration": warning_lead,
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


func _sample01(sequence: int, salt: int) -> float:
    var modulus: int = 2147483647
    var value := (_seed * 48271 + (sequence + 1) * 69621 + salt * 104729) % modulus
    return float(absi(value)) / float(modulus)
