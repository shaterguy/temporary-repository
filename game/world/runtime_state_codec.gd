class_name RuntimeStateCodec
extends RefCounted

const RUNTIME_SCHEMA: String = "w12-runtime-state-v1"
const PLAYER_SCHEMA: String = "w12-player-runtime-v1"
const ENCOUNTER_SCHEMA: String = "w12-encounter-runtime-v1"
const DIRECTOR_SCHEMA: String = "w12-spawn-director-runtime-v1"


static func reset_player(player: Node2D, origin: Vector2) -> bool:
    if not is_instance_valid(player):
        return false
    var tree := player.get_tree()
    if tree != null:
        tree.paused = false
    var combat_model: Variant = player.get("model")
    var weapon_model: Variant = player.get("weapon_model")
    var echo_model: Variant = player.get("echo_model")
    if combat_model == null or weapon_model == null or echo_model == null:
        return false
    combat_model.call("reset", origin)
    weapon_model.call("reset")
    echo_model.call("reset")
    player.global_position = origin
    if player.has_method("clear_transient_input"):
        player.call("clear_transient_input")
    return true


static func reset_encounter(encounter: Node2D, seed: int, doctrine_plan: Dictionary) -> bool:
    if not is_instance_valid(encounter):
        return false
    var spatial: Variant = encounter.get("_spatial")
    var pool: Variant = encounter.get("_pool")
    var director: Variant = encounter.get("_director")
    if spatial == null or pool == null or director == null:
        return false
    spatial.call("clear")
    pool.call("reset")
    director.call("reset", seed)
    if not doctrine_plan.is_empty() and not bool(director.call("configure_doctrine", doctrine_plan)):
        return false
    encounter.set("_enemy_phases", {})
    encounter.set("_telegraphs", _dictionary_array([]))
    encounter.set("_cross_phase_attacks", _dictionary_array([]))
    encounter.set("_cross_phase_attack_cooldowns", {})
    encounter.set("_world_phase", "material")
    encounter.queue_redraw()
    return true


static func player_is_alive(player: Node2D) -> bool:
    if not is_instance_valid(player):
        return false
    var combat_model: Variant = player.get("model")
    return combat_model != null and bool(combat_model.call("is_alive"))


static func capture_runtime(
    player: Node2D,
    ark: Node2D,
    circuit: Node2D,
    phase: Node2D,
    encounter: Node2D,
    observation_summary: Dictionary
) -> Dictionary:
    if (
        not is_instance_valid(player)
        or not is_instance_valid(ark)
        or not is_instance_valid(circuit)
        or not is_instance_valid(phase)
        or not is_instance_valid(encounter)
    ):
        return {}
    var player_state := _capture_player(player)
    var encounter_state := _capture_encounter(encounter)
    if player_state.is_empty() or encounter_state.is_empty():
        return {}
    return {
        "schema": RUNTIME_SCHEMA,
        "player": player_state,
        "ark": ark.call("state_snapshot"),
        "circuit": circuit.call("state_snapshot"),
        "phase": phase.call("state_snapshot"),
        "encounter": encounter_state,
        "observation": observation_summary.duplicate(true),
    }


static func restore_runtime(
    runtime_state: Dictionary,
    player: Node2D,
    ark: Node2D,
    circuit: Node2D,
    phase: Node2D,
    encounter: Node2D
) -> Dictionary:
    if str(runtime_state.get("schema", "")) != RUNTIME_SCHEMA:
        return {"ok": false, "status": "RUNTIME_SCHEMA"}
    for key in ["player", "ark", "circuit", "phase", "encounter", "observation"]:
        if typeof(runtime_state.get(key, null)) != TYPE_DICTIONARY:
            return {"ok": false, "status": "RUNTIME_FIELD_%s" % key.to_upper()}

    var tree := player.get_tree() if is_instance_valid(player) else null
    if tree != null:
        tree.paused = false
    if not bool(ark.call("restore_state", runtime_state.get("ark", {}))):
        return {"ok": false, "status": "ARK_RESTORE"}
    if not bool(circuit.call("restore_state", runtime_state.get("circuit", {}))):
        return {"ok": false, "status": "CIRCUIT_RESTORE"}
    if not bool(phase.call("restore_state", runtime_state.get("phase", {}))):
        return {"ok": false, "status": "PHASE_RESTORE"}
    if not _restore_player(player, runtime_state.get("player", {})):
        return {"ok": false, "status": "PLAYER_RESTORE"}
    if not _restore_encounter(encounter, runtime_state.get("encounter", {})):
        return {"ok": false, "status": "ENCOUNTER_RESTORE"}

    var phase_snapshot: Dictionary = runtime_state.get("phase", {})
    var encounter_snapshot: Dictionary = runtime_state.get("encounter", {})
    if str(phase_snapshot.get("current_phase", "")) != str(encounter_snapshot.get("world_phase", "")):
        return {"ok": false, "status": "PHASE_ENCOUNTER_MISMATCH"}
    return {
        "ok": true,
        "status": "RESTORED",
        "observation": runtime_state.get("observation", {}).duplicate(true),
    }


static func _capture_player(player: Node2D) -> Dictionary:
    var combat_model: Variant = player.get("model")
    if combat_model == null:
        return {}
    var weapon_status: Dictionary = player.call("weapon_status_snapshot")
    var echo_status: Dictionary = player.call("tactical_echo_status_snapshot")
    return {
        "schema": PLAYER_SCHEMA,
        "position": _encode_vector(combat_model.get("position")),
        "health": int(combat_model.get("health")),
        "dodge_direction": _encode_vector(combat_model.get("dodge_direction")),
        "dodge_remaining": float(combat_model.get("dodge_remaining")),
        "dodge_cooldown_remaining": float(combat_model.get("dodge_cooldown_remaining")),
        "attack_cooldown_remaining": float(combat_model.get("attack_cooldown_remaining")),
        "paused": bool(combat_model.get("paused")),
        "hit_feedback_generation": int(combat_model.get("hit_feedback_generation")),
        "weapon": weapon_status.get("snapshot", {}).duplicate(true),
        "echo": echo_status.get("snapshot", {}).duplicate(true),
    }


static func _restore_player(player: Node2D, snapshot: Dictionary) -> bool:
    if str(snapshot.get("schema", "")) != PLAYER_SCHEMA:
        return false
    if not _is_vector_pair(snapshot.get("position", null)) or not _is_vector_pair(snapshot.get("dodge_direction", null)):
        return false
    var health := int(snapshot.get("health", -1))
    var dodge_remaining := float(snapshot.get("dodge_remaining", -1.0))
    var dodge_cooldown := float(snapshot.get("dodge_cooldown_remaining", -1.0))
    var attack_cooldown := float(snapshot.get("attack_cooldown_remaining", -1.0))
    var hit_generation := int(snapshot.get("hit_feedback_generation", -1))
    if health < 0 or health > 100 or dodge_remaining < 0.0 or dodge_cooldown < 0.0 or attack_cooldown < 0.0 or hit_generation < 0:
        return false
    if typeof(snapshot.get("weapon", null)) != TYPE_DICTIONARY or typeof(snapshot.get("echo", null)) != TYPE_DICTIONARY:
        return false
    if not bool(player.call("restore_weapon_state", snapshot.get("weapon", {}))):
        return false
    if not bool(player.call("restore_tactical_echo_state", snapshot.get("echo", {}))):
        return false

    var combat_model: Variant = player.get("model")
    if combat_model == null:
        return false
    var restored_position := _decode_vector(snapshot.get("position", []))
    combat_model.set("position", restored_position)
    combat_model.set("health", health)
    combat_model.set("movement_input", Vector2.ZERO)
    combat_model.set("dodge_direction", _decode_vector(snapshot.get("dodge_direction", [])))
    combat_model.set("dodge_remaining", dodge_remaining)
    combat_model.set("dodge_cooldown_remaining", dodge_cooldown)
    combat_model.set("attack_cooldown_remaining", attack_cooldown)
    combat_model.set("paused", false)
    combat_model.set("hit_feedback_generation", hit_generation)
    player.global_position = restored_position
    if player.has_method("clear_transient_input"):
        player.call("clear_transient_input")
    player.call("set_paused", bool(snapshot.get("paused", false)))
    player.queue_redraw()
    return true


static func _capture_encounter(encounter: Node2D) -> Dictionary:
    var pool: Variant = encounter.get("_pool")
    var director: Variant = encounter.get("_director")
    if pool == null or director == null:
        return {}
    var enemy_phases: Dictionary = encounter.get("_enemy_phases")
    var enemies: Array[Dictionary] = []
    for state in pool.call("active_states"):
        var entity_id := int(state.get("id", -1))
        enemies.append({
            "id": entity_id,
            "archetype": str(state.get("archetype", "swarm")),
            "position": _encode_vector(state.get("position", Vector2.ZERO)),
            "health": int(state.get("health", 0)),
            "max_health": int(state.get("max_health", 0)),
            "speed": float(state.get("speed", 0.0)),
            "radius": float(state.get("radius", 1.0)),
            "contact_damage": int(state.get("contact_damage", 0)),
            "contact_cooldown": float(state.get("contact_cooldown", 0.0)),
            "phase": str(enemy_phases.get(entity_id, encounter.get("_world_phase"))),
        })

    var cooldowns: Array[Dictionary] = []
    var raw_cooldowns: Dictionary = encounter.get("_cross_phase_attack_cooldowns")
    for raw_id in raw_cooldowns.keys():
        cooldowns.append({"id": int(raw_id), "remaining": float(raw_cooldowns[raw_id])})

    return {
        "schema": ENCOUNTER_SCHEMA,
        "world_phase": str(encounter.get("_world_phase")),
        "enemies": enemies,
        "director": _capture_director(director),
        "telegraphs": _encode_event_array(encounter.get("_telegraphs")),
        "cross_phase_attacks": _encode_event_array(encounter.get("_cross_phase_attacks")),
        "cross_phase_cooldowns": cooldowns,
    }


static func _restore_encounter(encounter: Node2D, snapshot: Dictionary) -> bool:
    if str(snapshot.get("schema", "")) != ENCOUNTER_SCHEMA:
        return false
    if typeof(snapshot.get("enemies", null)) != TYPE_ARRAY:
        return false
    var world_phase := str(snapshot.get("world_phase", ""))
    if world_phase.is_empty():
        return false
    var pool: Variant = encounter.get("_pool")
    var spatial: Variant = encounter.get("_spatial")
    var director: Variant = encounter.get("_director")
    if pool == null or spatial == null or director == null:
        return false
    pool.call("reset")
    spatial.call("clear")
    if not _restore_director(director, snapshot.get("director", {})):
        return false

    var id_map: Dictionary = {}
    var phases: Dictionary = {}
    for raw_enemy in snapshot.get("enemies", []):
        if not raw_enemy is Dictionary:
            return false
        var enemy: Dictionary = raw_enemy
        if not _is_vector_pair(enemy.get("position", null)):
            return false
        var max_health := int(enemy.get("max_health", 0))
        var health := int(enemy.get("health", -1))
        if max_health <= 0 or health <= 0 or health > max_health:
            return false
        var acquired: Dictionary = pool.call(
            "acquire",
            str(enemy.get("archetype", "swarm")),
            _decode_vector(enemy.get("position", [])),
            max_health,
            float(enemy.get("speed", 0.0)),
            float(enemy.get("radius", 1.0)),
            int(enemy.get("contact_damage", 0))
        )
        if acquired.is_empty():
            return false
        var new_id := int(acquired.get("id", -1))
        var old_id := int(enemy.get("id", -1))
        var damage_to_apply := max_health - health
        if damage_to_apply > 0:
            pool.call("apply_damage", new_id, damage_to_apply)
        pool.call("arm_contact_cooldown", new_id, maxf(0.0, float(enemy.get("contact_cooldown", 0.0))))
        id_map[old_id] = new_id
        phases[new_id] = str(enemy.get("phase", world_phase))

    var telegraphs := _decode_event_array(snapshot.get("telegraphs", []), {})
    if telegraphs == null:
        return false
    var cross_attacks := _decode_event_array(snapshot.get("cross_phase_attacks", []), id_map)
    if cross_attacks == null:
        return false
    var rebuilt_cooldowns: Dictionary = {}
    var raw_cooldowns: Variant = snapshot.get("cross_phase_cooldowns", [])
    if not raw_cooldowns is Array:
        return false
    for raw_item in raw_cooldowns:
        if not raw_item is Dictionary:
            return false
        var old_id := int(raw_item.get("id", -1))
        if id_map.has(old_id):
            rebuilt_cooldowns[int(id_map[old_id])] = maxf(0.0, float(raw_item.get("remaining", 0.0)))

    encounter.set("_enemy_phases", phases)
    encounter.set("_telegraphs", telegraphs)
    encounter.set("_cross_phase_attacks", cross_attacks)
    encounter.set("_cross_phase_attack_cooldowns", rebuilt_cooldowns)
    encounter.set("_world_phase", world_phase)
    encounter.queue_redraw()
    return true


static func _capture_director(director: Variant) -> Dictionary:
    return {
        "schema": DIRECTOR_SCHEMA,
        "elapsed_time": float(director.get("elapsed_time")),
        "seed": int(director.get("_seed")),
        "sequence": int(director.get("_sequence")),
        "next_regular_time": float(director.get("_next_regular_time")),
        "pending": _encode_event_array(director.get("_pending")),
        "boss_scheduled": bool(director.get("_boss_scheduled")),
        "entry_direction": _encode_vector(director.get("_entry_direction")),
        "threat_level": int(director.get("_threat_level")),
        "doctrine_plan": director.get("_doctrine_plan").duplicate(true),
        "doctrine_warning_emitted": bool(director.get("_doctrine_warning_emitted")),
    }


static func _restore_director(director: Variant, snapshot: Dictionary) -> bool:
    if str(snapshot.get("schema", "")) != DIRECTOR_SCHEMA:
        return false
    if not _is_vector_pair(snapshot.get("entry_direction", null)):
        return false
    var seed := int(snapshot.get("seed", 0))
    var elapsed := float(snapshot.get("elapsed_time", -1.0))
    var sequence := int(snapshot.get("sequence", -1))
    var next_regular := float(snapshot.get("next_regular_time", -1.0))
    var threat := int(snapshot.get("threat_level", 0))
    var plan: Variant = snapshot.get("doctrine_plan", null)
    if seed <= 0 or elapsed < 0.0 or sequence < 0 or next_regular < 0.0 or threat < 1 or threat > 3 or not plan is Dictionary:
        return false
    var pending := _decode_event_array(snapshot.get("pending", []), {})
    if pending == null:
        return false
    director.call("reset", seed)
    director.call("set_route_context", _decode_vector(snapshot.get("entry_direction", [])), threat)
    if not bool(director.call("configure_doctrine", plan)):
        return false
    director.set("elapsed_time", elapsed)
    director.set("_sequence", sequence)
    director.set("_next_regular_time", next_regular)
    director.set("_pending", pending)
    director.set("_boss_scheduled", bool(snapshot.get("boss_scheduled", false)))
    director.set("_doctrine_warning_emitted", bool(snapshot.get("doctrine_warning_emitted", false)))
    return true


static func _encode_event_array(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not value is Array:
        return result
    for raw_event in value:
        if not raw_event is Dictionary:
            continue
        var event: Dictionary = raw_event.duplicate(true)
        if event.has("position") and typeof(event["position"]) == TYPE_VECTOR2:
            event["position"] = _encode_vector(event["position"])
        result.append(event)
    return result


static func _decode_event_array(value: Variant, id_map: Dictionary) -> Variant:
    if not value is Array:
        return null
    var result: Array[Dictionary] = []
    for raw_event in value:
        if not raw_event is Dictionary:
            return null
        var event: Dictionary = raw_event.duplicate(true)
        if event.has("position"):
            if not _is_vector_pair(event["position"]):
                return null
            event["position"] = _decode_vector(event["position"])
        if event.has("source_id") and not id_map.is_empty():
            var old_id := int(event.get("source_id", -1))
            if not id_map.has(old_id):
                continue
            event["source_id"] = int(id_map[old_id])
        result.append(event)
    return result


static func _dictionary_array(source: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for item in source:
        if item is Dictionary:
            result.append(item)
    return result


static func _encode_vector(value: Variant) -> Array[float]:
    if typeof(value) != TYPE_VECTOR2:
        return [0.0, 0.0]
    var vector: Vector2 = value
    return [vector.x, vector.y]


static func _decode_vector(value: Variant) -> Vector2:
    if not _is_vector_pair(value):
        return Vector2.ZERO
    return Vector2(float(value[0]), float(value[1]))


static func _is_vector_pair(value: Variant) -> bool:
    if not value is Array or value.size() != 2:
        return false
    return (
        typeof(value[0]) in [TYPE_INT, TYPE_FLOAT]
        and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]
    )
