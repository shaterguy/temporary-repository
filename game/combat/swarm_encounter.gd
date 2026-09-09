extends Node2D

const SpatialHashScript = preload("res://game/combat/spatial_hash.gd")
const EnemyPoolScript = preload("res://game/combat/enemy_pool.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")

const SEPARATION_RADIUS: float = 54.0
const PLAYER_RADIUS: float = 17.0
const CONTACT_COOLDOWN: float = 0.75
const BOSS_CONTACT_COOLDOWN: float = 1.20

var _spatial = SpatialHashScript.new(96.0)
var _pool = EnemyPoolScript.new()
var _director = SpawnDirectorScript.new()
var _player: Node2D
var _telegraphs: Array[Dictionary] = []


func _ready() -> void:
    _director.reset(20260909)
    queue_redraw()


func configure_player(controller: Node2D) -> void:
    _player = controller
    if is_instance_valid(_player) and _player.has_method("set_target_provider"):
        _player.call("set_target_provider", self)


func combat_target_snapshot() -> Array[Dictionary]:
    var targets: Array[Dictionary] = []
    for state in _pool.active_states():
        targets.append({
            "id": int(state.get("id", -1)),
            "position": state.get("position", Vector2.ZERO),
            "active": bool(state.get("active", false)),
        })
    return targets


func apply_target_damage(entity_id: int, damage: int) -> bool:
    if _pool.state_for(entity_id).is_empty():
        return false
    _pool.apply_damage(entity_id, damage)
    queue_redraw()
    return true


func active_enemy_count() -> int:
    return _pool.active_count()


func pool_capacity() -> int:
    return _pool.capacity()


func _physics_process(delta: float) -> void:
    if delta <= 0.0 or not is_instance_valid(_player):
        return

    var director_events := _director.step(delta, _player.global_position)
    for event in director_events:
        _consume_director_event(event)

    _advance_telegraphs(delta)
    _rebuild_spatial()
    _advance_swarm(delta)
    queue_redraw()


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

    _pool.acquire(
        archetype,
        spawn_position,
        max_health,
        speed,
        radius,
        contact_damage
    )


func _rebuild_spatial() -> void:
    _spatial.clear()
    for state in _pool.active_states():
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
        var to_player := player_position - enemy_position
        var pursuit := Vector2.ZERO if to_player.is_zero_approx() else to_player.normalized()
        var separation := _separation_vector(entity_id, enemy_position)
        var velocity := pursuit * speed + separation * speed * 0.95

        if archetype == "boss":
            var tangent := Vector2(-pursuit.y, pursuit.x)
            velocity += tangent * sin(_director.elapsed_time * 1.2) * speed * 0.28

        velocity = velocity.limit_length(speed * 1.35)
        var next_position := enemy_position + velocity * delta
        _pool.set_position(entity_id, next_position)

        var contact_remaining := _pool.advance_contact_timer(entity_id, delta)
        var collision_radius := float(state.get("radius", 12.0)) + PLAYER_RADIUS
        if (
            next_position.distance_squared_to(player_position) <= collision_radius * collision_radius
            and contact_remaining <= 0.0
        ):
            if _player.has_method("take_damage"):
                _player.call("take_damage", int(state.get("contact_damage", 0)))
            _pool.arm_contact_cooldown(
                entity_id,
                BOSS_CONTACT_COOLDOWN if archetype == "boss" else CONTACT_COOLDOWN
            )


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

    for state in _pool.active_states():
        var enemy_position: Vector2 = state.get("position", Vector2.ZERO)
        var radius := float(state.get("radius", 12.0))
        var is_boss := str(state.get("archetype", "")) == "boss"
        var body_color := Color(0.72, 0.24, 0.28, 0.96) if is_boss else Color(0.30, 0.48, 0.68, 0.94)
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
