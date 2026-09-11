extends Node2D

const SpatialHashScript = preload("res://game/combat/spatial_hash.gd")
const EnemyPoolScript = preload("res://game/combat/enemy_pool.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")

const SEPARATION_RADIUS: float = 54.0
const PLAYER_RADIUS: float = 17.0
const CONTACT_COOLDOWN: float = 0.75
const BOSS_CONTACT_COOLDOWN: float = 1.20
const CROSS_PHASE_RANGE: float = 360.0
const CROSS_PHASE_TELEGRAPH_SECONDS: float = 0.80
const CROSS_PHASE_ATTACK_COOLDOWN: float = 3.0
const CROSS_PHASE_ATTACK_RADIUS: float = 54.0

var _spatial = SpatialHashScript.new(96.0)
var _pool = EnemyPoolScript.new()
var _director = SpawnDirectorScript.new()
var _player: Node2D
var _escort_target: Node2D
var _area_effect_provider: Object
var _phase_provider: Object
var _world_phase: String = "material"
var _enemy_phases: Dictionary = {}
var _telegraphs: Array[Dictionary] = []
var _cross_phase_attacks: Array[Dictionary] = []
var _cross_phase_attack_cooldowns: Dictionary = {}


func _ready() -> void:
    _director.reset(20260909)
    queue_redraw()


func configure_player(controller: Node2D) -> void:
    _player = controller
    if is_instance_valid(_player) and _player.has_method("set_target_provider"):
        _player.call("set_target_provider", self)


func configure_escort_target(target: Node2D) -> void:
    _escort_target = target
    _sync_route_context()


func configure_area_effect_provider(provider: Object) -> void:
    _area_effect_provider = provider


func configure_phase_provider(provider: Object) -> void:
    _phase_provider = provider
    _director.configure_world_provider(provider)
    queue_redraw()


func set_world_phase(phase_id: String) -> bool:
    if phase_id.is_empty():
        return false
    _world_phase = phase_id
    queue_redraw()
    return true


func combat_target_snapshot() -> Array[Dictionary]:
    var targets: Array[Dictionary] = []
    for state in _pool.active_states():
        var enemy_phase := _phase_for_state(state)
        targets.append({
            "id": int(state.get("id", -1)),
            "position": state.get("position", Vector2.ZERO),
            "active": bool(state.get("active", false)) and _is_phase_targetable(enemy_phase),
            "phase": enemy_phase,
        })
    return targets


func apply_target_damage(entity_id: int, damage: int) -> bool:
    var state := _pool.state_for(entity_id)
    if state.is_empty():
        return false
    if not _is_phase_targetable(_phase_for_state(state)):
        return true
    var result := _pool.apply_damage(entity_id, damage)
    if bool(result.get("killed", false)):
        _enemy_phases.erase(entity_id)
        _cross_phase_attack_cooldowns.erase(entity_id)
    queue_redraw()
    return true


func active_enemy_count() -> int:
    return _pool.active_count()


func pool_capacity() -> int:
    return _pool.capacity()


func threat_count_for_phase(phase_id: String, world_position: Vector2, radius: float) -> int:
    var count := 0
    var radius_squared := maxf(0.0, radius) * maxf(0.0, radius)
    for state in _pool.active_states():
        if _phase_for_state(state) != phase_id:
            continue
        var enemy_position: Vector2 = state.get("position", Vector2.ZERO)
        if enemy_position.distance_squared_to(world_position) <= radius_squared:
            count += 1
    return count


func enemy_phase_for_id(entity_id: int) -> String:
    var state := _pool.state_for(entity_id)
    if state.is_empty():
        return ""
    return _phase_for_state(state)


func cross_phase_warning_snapshot() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for warning in _cross_phase_attacks:
        result.append(warning.duplicate(true))
    return result


func resolve_enemy_runtime_position(from_position: Vector2, proposed_position: Vector2) -> Vector2:
    if is_instance_valid(_phase_provider) and _phase_provider.has_method("resolve_enemy_position"):
        var resolved: Variant = _phase_provider.call(
            "resolve_enemy_position",
            from_position,
            proposed_position
        )
        if resolved is Vector2:
            return resolved
    return proposed_position


func advance_cross_phase_attacks(delta: float) -> void:
    if delta <= 0.0:
        return
    for index in range(_cross_phase_attacks.size() - 1, -1, -1):
        var warning: Dictionary = _cross_phase_attacks[index]
        var remaining := maxf(0.0, float(warning.get("remaining", 0.0)) - delta)
        if remaining > 0.0:
            warning["remaining"] = remaining
            _cross_phase_attacks[index] = warning
            continue

        if (
            is_instance_valid(_player)
            and _current_phase() == str(warning.get("target_phase", ""))
            and _player.global_position.distance_squared_to(warning.get("position", Vector2.ZERO))
                <= pow(float(warning.get("radius", CROSS_PHASE_ATTACK_RADIUS)), 2.0)
            and _player.has_method("take_damage")
        ):
            _player.call("take_damage", int(warning.get("damage", 0)))
        _cross_phase_attacks.remove_at(index)
    queue_redraw()


func _physics_process(delta: float) -> void:
    if delta <= 0.0 or not is_instance_valid(_player):
        return

    _sync_route_context()
    var director_events := _director.step(delta, _player.global_position)
    for event in director_events:
        _consume_director_event(event)

    _advance_telegraphs(delta)
    _advance_cross_phase_cooldowns(delta)
    advance_cross_phase_attacks(delta)
    _rebuild_spatial()
    _advance_swarm(delta)
    queue_redraw()


func _sync_route_context() -> void:
    if not is_instance_valid(_escort_target) or not _escort_target.has_method("route_combat_context"):
        _director.set_route_context(Vector2.ZERO, 1)
        return
    var context: Dictionary = _escort_target.call("route_combat_context")
    _director.set_route_context(
        context.get("entry_direction", Vector2.ZERO),
        int(context.get("threat_level", 1))
    )


func _consume_director_event(event: Dictionary) -> void:
    var event_type := str(event.get("type", ""))
    if event_type == "telegraph":
        var duration := maxf(0.05, float(event.get("telegraph_duration", 0.5)))
        _telegraphs.append({
            "position": event.get("position", Vector2.ZERO),
            "duration": duration,
            "remaining": duration,
            "radius": 72.0 if str(event.get("archetype", "")) == "boss" else 30.0,
            "archetype": str(event.get("archetype", "swarm")),
        })
    elif event_type == "spawn":
        _spawn_enemy(event)


func _spawn_enemy(event: Dictionary) -> void:
    var archetype := str(event.get("archetype", "swarm"))
    var spawn_position: Vector2 = event.get("position", Vector2.ZERO)
    var max_health := 24
    var speed := 82.0
    var radius := 13.0
    var contact_damage := 8

    match archetype:
        "runner":
            max_health = 32
            speed = 122.0
            radius = 12.0
            contact_damage = 10
        "boss":
            max_health = 540
            speed = 52.0
            radius = 36.0
            contact_damage = 18

    var state := _pool.acquire(
        archetype,
        spawn_position,
        max_health,
        speed,
        radius,
        contact_damage
    )
    if not state.is_empty():
        var entity_id := int(state.get("id", -1))
        _enemy_phases[entity_id] = _phase_for_state(state)


func _rebuild_spatial() -> void:
    _spatial.clear()
    for state in _pool.active_states():
        if not _is_phase_targetable(_phase_for_state(state)):
            continue
        _spatial.insert(
            int(state.get("id", -1)),
            state.get("position", Vector2.ZERO)
        )


func _advance_swarm(delta: float) -> void:
    var player_position := _player.global_position
    var active_states := _pool.active_states()
    for state in active_states:
        var entity_id := int(state.get("id", -1))
        var enemy_position: Vector2 = state.get("position", Vector2.ZERO)
        var speed := float(state.get("speed", 0.0))
        var archetype := str(state.get("archetype", "swarm"))
        var enemy_phase := _phase_for_state(state)

        if not _is_phase_targetable(enemy_phase):
            _pool.advance_contact_timer(entity_id, delta)
            _maybe_schedule_cross_phase_attack(state, enemy_phase)
            continue

        var pursue_escort := (
            is_instance_valid(_escort_target)
            and (archetype == "boss" or entity_id % 3 == 0)
            and _escort_target.has_method("objective_global_position")
        )
        var pursuit_target := player_position
        if pursue_escort:
            pursuit_target = _escort_target.call("objective_global_position")
        var to_target := pursuit_target - enemy_position
        var pursuit := Vector2.ZERO if to_target.is_zero_approx() else to_target.normalized()
        var separation := _separation_vector(entity_id, enemy_position)
        var velocity := pursuit * speed + separation * speed * 0.95

        if archetype == "boss":
            var tangent := Vector2(-pursuit.y, pursuit.x)
            velocity += tangent * sin(_director.elapsed_time * 1.2) * speed * 0.28

        velocity = velocity.limit_length(speed * 1.35) * _movement_multiplier_at(enemy_position)
        var proposed_position := enemy_position + velocity * delta
        var next_position := resolve_enemy_runtime_position(enemy_position, proposed_position)
        _pool.set_position(entity_id, next_position)

        var contact_remaining := _pool.advance_contact_timer(entity_id, delta)
        var target_radius := PLAYER_RADIUS
        if pursue_escort and _escort_target.has_method("objective_radius"):
            target_radius = float(_escort_target.call("objective_radius"))
        var collision_radius := float(state.get("radius", 12.0)) + target_radius
        if (
            next_position.distance_squared_to(pursuit_target) <= collision_radius * collision_radius
            and contact_remaining <= 0.0
        ):
            if pursue_escort and _escort_target.has_method("apply_objective_damage"):
                var warning_visible := true
                if _escort_target.has_method("is_objective_visible"):
                    warning_visible = bool(_escort_target.call("is_objective_visible"))
                _escort_target.call("apply_objective_damage", int(state.get("contact_damage", 0)), warning_visible)
            elif _player.has_method("take_damage"):
                _player.call("take_damage", int(state.get("contact_damage", 0)))
            _pool.arm_contact_cooldown(
                entity_id,
                BOSS_CONTACT_COOLDOWN if archetype == "boss" else CONTACT_COOLDOWN
            )


func _movement_multiplier_at(world_position: Vector2) -> float:
    if is_instance_valid(_area_effect_provider) and _area_effect_provider.has_method("movement_multiplier_at"):
        return clampf(float(_area_effect_provider.call("movement_multiplier_at", world_position)), 0.0, 1.0)
    return 1.0


func _phase_for_state(state: Dictionary) -> String:
    var entity_id := int(state.get("id", -1))
    if _enemy_phases.has(entity_id):
        return str(_enemy_phases[entity_id])
    var phase_id := _current_phase()
    if is_instance_valid(_phase_provider) and _phase_provider.has_method("enemy_phase_for"):
        phase_id = str(_phase_provider.call(
            "enemy_phase_for",
            entity_id,
            str(state.get("archetype", "swarm"))
        ))
    _enemy_phases[entity_id] = phase_id
    return phase_id


func _current_phase() -> String:
    if is_instance_valid(_phase_provider) and _phase_provider.has_method("current_phase_id"):
        return str(_phase_provider.call("current_phase_id"))
    return _world_phase


func _is_phase_targetable(enemy_phase: String) -> bool:
    if is_instance_valid(_phase_provider) and _phase_provider.has_method("is_enemy_targetable"):
        return bool(_phase_provider.call("is_enemy_targetable", enemy_phase))
    return enemy_phase == _world_phase


func _maybe_schedule_cross_phase_attack(state: Dictionary, enemy_phase: String) -> void:
    if str(state.get("archetype", "")) != "boss" or enemy_phase == _current_phase():
        return
    var entity_id := int(state.get("id", -1))
    if float(_cross_phase_attack_cooldowns.get(entity_id, 0.0)) > 0.0:
        return
    var enemy_position: Vector2 = state.get("position", Vector2.ZERO)
    if enemy_position.distance_squared_to(_player.global_position) > CROSS_PHASE_RANGE * CROSS_PHASE_RANGE:
        return
    for warning in _cross_phase_attacks:
        if int(warning.get("source_id", -1)) == entity_id:
            return

    _cross_phase_attacks.append({
        "source_id": entity_id,
        "source_phase": enemy_phase,
        "target_phase": _current_phase(),
        "position": _player.global_position,
        "duration": CROSS_PHASE_TELEGRAPH_SECONDS,
        "remaining": CROSS_PHASE_TELEGRAPH_SECONDS,
        "radius": CROSS_PHASE_ATTACK_RADIUS,
        "damage": int(state.get("contact_damage", 0)),
    })
    _cross_phase_attack_cooldowns[entity_id] = CROSS_PHASE_ATTACK_COOLDOWN


func _advance_cross_phase_cooldowns(delta: float) -> void:
    for key in _cross_phase_attack_cooldowns.keys():
        var remaining := maxf(0.0, float(_cross_phase_attack_cooldowns.get(key, 0.0)) - delta)
        if remaining <= 0.0:
            _cross_phase_attack_cooldowns.erase(key)
        else:
            _cross_phase_attack_cooldowns[key] = remaining


func _separation_vector(entity_id: int, position: Vector2) -> Vector2:
    var separation := Vector2.ZERO
    for neighbor in _spatial.query_radius(position, SEPARATION_RADIUS):
        if int(neighbor.get("id", -1)) == entity_id:
            continue
        var neighbor_position: Vector2 = neighbor.get("position", position)
        var offset := position - neighbor_position
        var distance := offset.length()
        if distance <= 0.001 or distance >= SEPARATION_RADIUS:
            continue
        var weight := 1.0 - distance / SEPARATION_RADIUS
        separation += offset / distance * weight
    return separation.limit_length(1.0)


func _advance_telegraphs(delta: float) -> void:
    for index in range(_telegraphs.size() - 1, -1, -1):
        var warning: Dictionary = _telegraphs[index]
        var remaining := maxf(0.0, float(warning.get("remaining", 0.0)) - delta)
        if remaining <= 0.0:
            _telegraphs.remove_at(index)
        else:
            warning["remaining"] = remaining
            _telegraphs[index] = warning


func _draw() -> void:
    for warning in _telegraphs:
        var warning_position: Vector2 = warning.get("position", Vector2.ZERO)
        var radius := float(warning.get("radius", 30.0))
        var duration := maxf(0.001, float(warning.get("duration", 1.0)))
        var remaining := clampf(float(warning.get("remaining", 0.0)) / duration, 0.0, 1.0)
        var progress := 1.0 - remaining
        draw_arc(
            warning_position,
            radius,
            0.0,
            TAU,
            48,
            Color(1.0, 0.45, 0.24, 0.34),
            2.0,
            true
        )
        draw_arc(
            warning_position,
            radius,
            -PI * 0.5,
            -PI * 0.5 + TAU * progress,
            48,
            Color(1.0, 0.72, 0.30, 0.92),
            4.0,
            true
        )

    for warning in _cross_phase_attacks:
        var warning_position: Vector2 = warning.get("position", Vector2.ZERO)
        var radius := float(warning.get("radius", CROSS_PHASE_ATTACK_RADIUS))
        var duration := maxf(0.001, float(warning.get("duration", CROSS_PHASE_TELEGRAPH_SECONDS)))
        var remaining := clampf(float(warning.get("remaining", 0.0)) / duration, 0.0, 1.0)
        var progress := 1.0 - remaining
        draw_circle(warning_position, radius, Color(0.72, 0.38, 1.0, 0.10))
        draw_arc(
            warning_position,
            radius,
            -PI * 0.5,
            -PI * 0.5 + TAU * progress,
            48,
            Color(0.88, 0.62, 1.0, 0.96),
            5.0,
            true
        )

    for state in _pool.active_states():
        var enemy_phase := _phase_for_state(state)
        if not _is_phase_targetable(enemy_phase):
            continue
        var enemy_position: Vector2 = state.get("position", Vector2.ZERO)
        var radius := float(state.get("radius", 12.0))
        var is_boss := str(state.get("archetype", "")) == "boss"
        var body_color := Color(0.72, 0.24, 0.28, 0.96) if is_boss else Color(0.30, 0.48, 0.68, 0.94)
        if enemy_phase == "shadow" and not is_boss:
            body_color = Color(0.48, 0.32, 0.72, 0.94)
        draw_circle(enemy_position, radius, body_color)

        var health := float(state.get("health", 0))
        var max_health := maxf(1.0, float(state.get("max_health", 1)))
        draw_arc(
            enemy_position,
            radius + 5.0,
            -PI * 0.5,
            -PI * 0.5 + TAU * clampf(health / max_health, 0.0, 1.0),
            28,
            Color(1.0, 0.86, 0.64, 0.90),
            2.5,
            true
        )
