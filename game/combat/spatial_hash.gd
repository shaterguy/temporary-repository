extends RefCounted

const MIN_CELL_SIZE: float = 16.0

var cell_size: float = 96.0
var _cells: Dictionary = {}


func _init(configured_cell_size: float = 96.0) -> void:
    cell_size = maxf(MIN_CELL_SIZE, configured_cell_size)


func clear() -> void:
    _cells.clear()


func insert(entity_id: int, position: Vector2) -> void:
    if entity_id < 0:
        return
    var key := _cell_key(position)
    var bucket: Array = _cells.get(key, [])
    bucket.append({
        "id": entity_id,
        "position": position,
    })
    _cells[key] = bucket


func query_radius(origin: Vector2, radius: float) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    if radius < 0.0:
        return results

    var extent := Vector2(radius, radius)
    var min_cell := _cell_key(origin - extent)
    var max_cell := _cell_key(origin + extent)
    var radius_squared := radius * radius

    for cell_y in range(min_cell.y, max_cell.y + 1):
        for cell_x in range(min_cell.x, max_cell.x + 1):
            var bucket: Array = _cells.get(Vector2i(cell_x, cell_y), [])
            for item in bucket:
                if not item is Dictionary:
                    continue
                var candidate: Dictionary = item
                var position_value: Variant = candidate.get("position")
                if typeof(position_value) != TYPE_VECTOR2:
                    continue
                var candidate_position: Vector2 = position_value
                if origin.distance_squared_to(candidate_position) <= radius_squared:
                    results.append(candidate.duplicate(true))

    return results


func cell_count() -> int:
    return _cells.size()


func _cell_key(position: Vector2) -> Vector2i:
    return Vector2i(
        floori(position.x / cell_size),
        floori(position.y / cell_size)
    )
