extends RefCounted

var _slots: Array[Dictionary] = []
var _free_indices: Array[int] = []
var _index_by_id: Dictionary = {}
var _next_entity_id: int = 1


func reset() -> void:
    _slots.clear()
    _free_indices.clear()
    _index_by_id.clear()
    _next_entity_id = 1


func acquire(
    archetype: String,
    position: Vector2,
    max_health: int,
    speed: float,
    radius: float,
    contact_damage: int
) -> Dictionary:
    if max_health <= 0:
        return {}

    var slot_index: int
    if _free_indices.is_empty():
        slot_index = _slots.size()
        _slots.append({})
    else:
        slot_index = _free_indices.pop_back()

    var previous_state: Dictionary = _slots[slot_index]
    var generation := int(previous_state.get("generation", 0)) + 1
    var entity_id := _next_entity_id
    _next_entity_id += 1

    var state := {
        "id": entity_id,
        "slot_index": slot_index,
        "generation": generation,
        "archetype": archetype,
        "position": position,
        "health": max_health,
        "max_health": max_health,
        "speed": maxf(0.0, speed),
        "radius": maxf(1.0, radius),
        "contact_damage": maxi(0, contact_damage),
        "contact_cooldown": 0.0,
        "active": true,
    }
    _slots[slot_index] = state
    _index_by_id[entity_id] = slot_index
    return state.duplicate(true)


func release(entity_id: int) -> bool:
    if not _index_by_id.has(entity_id):
        return false
    var slot_index := int(_index_by_id[entity_id])
    var state: Dictionary = _slots[slot_index]
    if not bool(state.get("active", false)):
        return false

    state["active"] = false
    _slots[slot_index] = state
    _index_by_id.erase(entity_id)
    _free_indices.append(slot_index)
    return true


func apply_damage(entity_id: int, amount: int) -> Dictionary:
    if not _index_by_id.has(entity_id):
        return {
            "found": false,
            "applied_damage": 0,
            "health": 0,
            "killed": false,
        }

    var slot_index := int(_index_by_id[entity_id])
    var state: Dictionary = _slots[slot_index]
    var current_health := int(state.get("health", 0))
    var applied_damage := mini(maxi(0, amount), current_health)
    var next_health := current_health - applied_damage
    state["health"] = next_health
    var killed := next_health <= 0

    if killed:
        state["active"] = false
        _index_by_id.erase(entity_id)
        _free_indices.append(slot_index)
    _slots[slot_index] = state

    return {
        "found": true,
        "applied_damage": applied_damage,
        "health": next_health,
        "killed": killed,
        "generation": int(state.get("generation", 0)),
    }


func set_position(entity_id: int, position: Vector2) -> bool:
    if not _index_by_id.has(entity_id):
        return false
    var slot_index := int(_index_by_id[entity_id])
    var state: Dictionary = _slots[slot_index]
    state["position"] = position
    _slots[slot_index] = state
    return true


func advance_contact_timer(entity_id: int, delta: float) -> float:
    if not _index_by_id.has(entity_id):
        return 0.0
    var slot_index := int(_index_by_id[entity_id])
    var state: Dictionary = _slots[slot_index]
    var remaining := maxf(0.0, float(state.get("contact_cooldown", 0.0)) - maxf(0.0, delta))
    state["contact_cooldown"] = remaining
    _slots[slot_index] = state
    return remaining


func arm_contact_cooldown(entity_id: int, duration: float) -> bool:
    if not _index_by_id.has(entity_id):
        return false
    var slot_index := int(_index_by_id[entity_id])
    var state: Dictionary = _slots[slot_index]
    state["contact_cooldown"] = maxf(0.0, duration)
    _slots[slot_index] = state
    return true


func state_for(entity_id: int) -> Dictionary:
    if not _index_by_id.has(entity_id):
        return {}
    return _slots[int(_index_by_id[entity_id])].duplicate(true)


func active_states() -> Array[Dictionary]:
    var states: Array[Dictionary] = []
    for state in _slots:
        if bool(state.get("active", false)):
            states.append(state.duplicate(true))
    return states


func active_count() -> int:
    return _index_by_id.size()


func capacity() -> int:
    return _slots.size()
