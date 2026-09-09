extends RefCounted

const SpatialHashScript = preload("res://game/combat/spatial_hash.gd")
const EnemyPoolScript = preload("res://game/combat/enemy_pool.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var grid = SpatialHashScript.new(64.0)
    grid.insert(1, Vector2.ZERO)
    grid.insert(2, Vector2(50.0, 0.0))
    grid.insert(3, Vector2(140.0, 0.0))
    var nearby := grid.query_radius(Vector2.ZERO, 80.0)
    if not _contains_id(nearby, 1) or not _contains_id(nearby, 2):
        failures.append("spatial hash omitted an entity inside the query radius")
    if _contains_id(nearby, 3):
        failures.append("spatial hash returned an entity outside the query radius")
    grid.clear()
    if grid.cell_count() != 0:
        failures.append("spatial hash clear retained occupied cells")

    var pool = EnemyPoolScript.new()
    var first := pool.acquire("swarm", Vector2.ZERO, 24, 80.0, 13.0, 8)
    var second := pool.acquire("runner", Vector2(10.0, 0.0), 32, 120.0, 12.0, 10)
    if pool.capacity() != 2 or pool.active_count() != 2:
        failures.append("enemy pool did not allocate the initial active slots")
    var first_id := int(first.get("id", -1))
    if not pool.release(first_id):
        failures.append("enemy pool could not release an active slot")
    var third := pool.acquire("swarm", Vector2(20.0, 0.0), 24, 80.0, 13.0, 8)
    if pool.capacity() != 2:
        failures.append("enemy pool grew instead of reusing a released slot")
    if int(third.get("id", -1)) == first_id:
        failures.append("enemy pool reused a live-target identity across slot generations")
    if int(third.get("generation", 0)) <= int(first.get("generation", 0)):
        failures.append("enemy pool did not advance the reused slot generation")
    var lethal := pool.apply_damage(int(third.get("id", -1)), 999)
    if not bool(lethal.get("killed", false)) or pool.active_count() != 1:
        failures.append("lethal pooled-enemy damage did not recycle exactly one active slot")
    if pool.release(int(third.get("id", -1))):
        failures.append("enemy pool allowed a second release of an already recycled target")

    var cooldown_target := int(second.get("id", -1))
    pool.arm_contact_cooldown(cooldown_target, 0.8)
    var remaining := pool.advance_contact_timer(cooldown_target, 0.3)
    if absf(remaining - 0.5) > 0.001:
        failures.append("pooled enemy contact cooldown advanced by the wrong amount")

    var origin := Vector2(100.0, 120.0)
    var director = SpawnDirectorScript.new()
    director.reset(4242)
    var warning_events := director.step(SpawnDirectorScript.FIRST_SPAWN_TIME, origin)
    var first_warning := _first_event(warning_events, "telegraph")
    if first_warning.is_empty():
        failures.append("spawn director did not warn before the first regular spawn")
    else:
        var mirror = SpawnDirectorScript.new()
        mirror.reset(4242)
        var mirror_warning := _first_event(
            mirror.step(SpawnDirectorScript.FIRST_SPAWN_TIME, origin),
            "telegraph"
        )
        var mirror_position: Vector2 = mirror_warning.get("position", Vector2.ZERO)
        var first_position: Vector2 = first_warning.get("position", Vector2.ZERO)
        if (
            str(mirror_warning.get("spawn_id", "")) != str(first_warning.get("spawn_id", ""))
            or not mirror_position.is_equal_approx(first_position)
        ):
            failures.append("spawn director was not deterministic for the same seed and origin")

        var first_spawn_id := str(first_warning.get("spawn_id", ""))
        var spawn_events := director.step(SpawnDirectorScript.TELEGRAPH_LEAD, origin)
        if _event_with_id(spawn_events, "spawn", first_spawn_id).is_empty():
            failures.append("regular spawn did not follow its warning at the configured lead time")

    var boss_director = SpawnDirectorScript.new()
    boss_director.reset(99)
    var boss_warning_events := boss_director.step(
        SpawnDirectorScript.BOSS_TIME - SpawnDirectorScript.BOSS_WARNING_LEAD,
        origin
    )
    var boss_warning := _first_event(boss_warning_events, "telegraph", "boss")
    if boss_warning.is_empty():
        failures.append("base boss did not emit its dedicated advance warning")
    else:
        var boss_id := str(boss_warning.get("spawn_id", ""))
        var boss_spawn_events := boss_director.step(SpawnDirectorScript.BOSS_WARNING_LEAD, origin)
        var boss_spawn := _event_with_id(boss_spawn_events, "spawn", boss_id)
        if boss_spawn.is_empty() or str(boss_spawn.get("archetype", "")) != "boss":
            failures.append("base boss warning did not resolve into exactly the scheduled boss spawn")
        var duplicate_boss := _first_event(boss_director.step(5.0, origin), "spawn", "boss")
        if not duplicate_boss.is_empty():
            failures.append("base boss spawned more than once from the same director lifecycle")

    var encounter = SwarmEncounterScript.new()
    encounter._consume_director_event({
        "type": "spawn",
        "archetype": "swarm",
        "position": Vector2(40.0, 0.0),
    })
    var controller = SurvivorControllerScript.new()
    controller.set_target_provider(encounter)
    var provided_targets := controller._snapshot_targets()
    if provided_targets.size() != 1:
        failures.append("survivor controller did not consume the W05 target-provider snapshot")
    else:
        var provider_target_id := int(provided_targets[0].get("id", -1))
        controller._resolve_events([{
            "type": "auto_attack",
            "target_id": provider_target_id,
            "damage": 999,
            "direction": Vector2.RIGHT,
        }])
        if not encounter.combat_target_snapshot().is_empty():
            failures.append("W04 auto-attack damage was not routed into the W05 pooled target provider")
    controller.free()
    encounter.free()

    return failures


static func _contains_id(items: Array[Dictionary], entity_id: int) -> bool:
    for item in items:
        if int(item.get("id", -1)) == entity_id:
            return true
    return false


static func _first_event(
    events: Array[Dictionary],
    event_type: String,
    archetype: String = ""
) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) != event_type:
            continue
        if not archetype.is_empty() and str(event.get("archetype", "")) != archetype:
            continue
        return event
    return {}


static func _event_with_id(
    events: Array[Dictionary],
    event_type: String,
    spawn_id: String
) -> Dictionary:
    for event in events:
        if (
            str(event.get("type", "")) == event_type
            and str(event.get("spawn_id", "")) == spawn_id
        ):
            return event
    return {}
