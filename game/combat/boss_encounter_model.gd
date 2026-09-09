extends RefCounted

const BossCatalogScript = preload("res://game/data/boss_catalog.gd")

var _profile: Dictionary = {}
var _active: bool = false
var _defeated: bool = false
var _entity_id: int = -1
var _phase_index: int = 0
var _health_ratio: float = 1.0
var _attack_sequence: int = 0
var _attack_cooldown: float = 0.0
var _pending_attack: Dictionary = {}
var _pending_remaining: float = 0.0


func configure(profile: Dictionary) -> bool:
    if not BossCatalogScript.validate_profile(profile):
        return false
    _profile = profile.duplicate(true)
    reset_runtime()
    return true


func reset_runtime() -> void:
    _active = false
    _defeated = false
    _entity_id = -1
    _phase_index = 0
    _health_ratio = 1.0
    _attack_sequence = 0
    _attack_cooldown = 0.35
    _pending_attack = {}
    _pending_remaining = 0.0


func begin(entity_id: int) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if _profile.is_empty() or entity_id < 0:
        return events
    reset_runtime()
    _active = true
    _entity_id = entity_id
    events.append({
        "type": "boss_intro",
        "boss_id": str(_profile.get("boss_id", "")),
        "display_name": str(_profile.get("display_name", "")),
        "presentation_cue": str(_profile.get("intro_cue", "")),
    })
    events.append(_phase_event())
    return events


func step(delta: float) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if not _active or _defeated or delta <= 0.0:
        return events

    if not _pending_attack.is_empty():
        _pending_remaining = maxf(0.0, _pending_remaining - delta)
        if _pending_remaining <= 0.0:
            var attack := _pending_attack.duplicate(true)
            attack["type"] = "boss_attack"
            events.append(attack)
            _pending_attack = {}
            _attack_cooldown = float(_current_phase().get("attack_interval", 2.0))
        return events

    _attack_cooldown = maxf(0.0, _attack_cooldown - delta)
    if _attack_cooldown > 0.0:
        return events

    var phase := _current_phase()
    if phase.is_empty():
        return events
    var angle_step := float(phase.get("angle_step", 0.5))
    var angle := fposmod(float(_attack_sequence) * angle_step + float(_phase_index) * 0.37, TAU)
    _pending_attack = {
        "boss_id": str(_profile.get("boss_id", "")),
        "entity_id": _entity_id,
        "phase_id": str(phase.get("phase_id", "")),
        "phase_index": _phase_index,
        "attack_id": str(phase.get("attack_id", "")),
        "telegraph_shape": str(phase.get("telegraph_shape", "circle")),
        "telegraph_duration": float(phase.get("telegraph_duration", 0.8)),
        "radius": float(phase.get("radius", 220.0)),
        "width": float(phase.get("width", 24.0)),
        "damage": int(phase.get("damage", 10)),
        "angle": angle,
        "safe_angle": fposmod(angle + PI, TAU),
        "active_phase": str(phase.get("active_phase", "any")),
        "dodge_rule": str(phase.get("dodge_rule", "")),
        "presentation_cue": str(phase.get("presentation_cue", "")),
        "sequence": _attack_sequence,
    }
    _pending_remaining = float(_pending_attack.get("telegraph_duration", 0.8))
    var warning := _pending_attack.duplicate(true)
    warning["type"] = "boss_telegraph"
    events.append(warning)
    _attack_sequence += 1
    return events


func apply_health(current_health: int, max_health: int) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if not _active or _defeated or max_health <= 0 or current_health <= 0:
        return events
    _health_ratio = clampf(float(current_health) / float(max_health), 0.0, 1.0)
    var thresholds: Variant = _profile.get("phase_thresholds", [])
    if not thresholds is Array:
        return events
    while _phase_index < thresholds.size() and _health_ratio <= float(thresholds[_phase_index]):
        _phase_index += 1
        _pending_attack = {}
        _pending_remaining = 0.0
        _attack_cooldown = 0.24
        events.append(_phase_event())
    return events


func defeat() -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if not _active or _defeated:
        return events
    _defeated = true
    _active = false
    _pending_attack = {}
    _pending_remaining = 0.0
    events.append({
        "type": "boss_defeated",
        "boss_id": str(_profile.get("boss_id", "")),
        "reward_id": str(_profile.get("reward_id", "")),
        "unlock_id": str(_profile.get("unlock_id", "")),
        "presentation_cue": str(_profile.get("defeat_cue", "")),
    })
    return events


func snapshot() -> Dictionary:
    return {
        "active": _active,
        "defeated": _defeated,
        "boss_id": str(_profile.get("boss_id", "")),
        "entity_id": _entity_id,
        "phase_index": _phase_index,
        "phase_id": str(_current_phase().get("phase_id", "")),
        "health_ratio": _health_ratio,
        "attack_sequence": _attack_sequence,
        "pending_attack": _pending_attack.duplicate(true),
        "pending_remaining": _pending_remaining,
    }


func current_phase() -> Dictionary:
    return _current_phase().duplicate(true)


func is_active() -> bool:
    return _active and not _defeated


func boss_id() -> String:
    return str(_profile.get("boss_id", ""))


static func attack_hits_position(event: Dictionary, origin: Vector2, target: Vector2) -> bool:
    var offset := target - origin
    var distance := offset.length()
    var radius := maxf(1.0, float(event.get("radius", 220.0)))
    var width := maxf(4.0, float(event.get("width", 24.0)))
    var angle := float(event.get("angle", 0.0))
    var direction := Vector2.RIGHT.rotated(angle)
    var tangent := Vector2(-direction.y, direction.x)
    var forward := offset.dot(direction)
    var lateral := offset.dot(tangent)
    match str(event.get("telegraph_shape", "circle")):
        "line":
            return absf(lateral) <= width and absf(forward) <= radius
        "ring":
            return absf(distance - radius * 0.68) <= width
        "cone":
            if distance > radius or distance <= 0.001:
                return false
            return offset.normalized().dot(direction) >= cos(0.58)
        "cross":
            return (absf(lateral) <= width or absf(forward) <= width) and distance <= radius
        "lanes":
            if absf(forward) > radius:
                return false
            var lane_gap := width * 2.8
            return minf(absf(lateral), minf(absf(lateral - lane_gap), absf(lateral + lane_gap))) <= width
        "orbit":
            if absf(distance - radius * 0.66) > width:
                return false
            var safe_angle := float(event.get("safe_angle", angle + PI))
            var target_angle := offset.angle()
            return absf(wrapf(target_angle - safe_angle, -PI, PI)) > 0.48
        "sweep":
            return absf(lateral) <= width and forward >= -width and forward <= radius
        "pillars":
            for index in 4:
                var center := Vector2.RIGHT.rotated(angle + TAU * float(index) / 4.0) * radius * 0.62
                if target.distance_to(origin + center) <= width * 1.45:
                    return true
            return false
        "spiral":
            if distance > radius:
                return false
            var normalized_angle := fposmod(offset.angle() - angle, TAU) / TAU
            var expected_radius := radius * (0.24 + normalized_angle * 0.68)
            return absf(distance - expected_radius) <= width
        "collapse":
            return distance >= radius * 0.50 and distance <= radius
    return distance <= radius


func _current_phase() -> Dictionary:
    var phases: Variant = _profile.get("phases", [])
    if not phases is Array or phases.is_empty():
        return {}
    var resolved_index := clampi(_phase_index, 0, phases.size() - 1)
    var raw_phase: Variant = phases[resolved_index]
    return raw_phase.duplicate(true) if raw_phase is Dictionary else {}


func _phase_event() -> Dictionary:
    var phase := _current_phase()
    return {
        "type": "boss_phase_changed",
        "boss_id": str(_profile.get("boss_id", "")),
        "phase_index": _phase_index,
        "phase_id": str(phase.get("phase_id", "")),
        "body_phase": str(phase.get("body_phase", "material")),
        "attack_id": str(phase.get("attack_id", "")),
        "telegraph_shape": str(phase.get("telegraph_shape", "")),
        "dodge_rule": str(phase.get("dodge_rule", "")),
        "presentation_cue": str(phase.get("presentation_cue", "")),
    }
