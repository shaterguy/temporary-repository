extends RefCounted

const MANIFEST_PATH: String = "res://assets/runtime/w23/world_event_art_manifest.json"
const TWILIGHT_ENEMY_IDS: Array[String] = [
    "dusk_mite", "rivet_hound", "glasswing", "chain_wraith", "ballast_guard", "hull_reaver"
]

static var _manifest_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}


static func manifest() -> Dictionary:
    if not _manifest_cache.is_empty():
        return _manifest_cache.duplicate(true)
    if not FileAccess.file_exists(MANIFEST_PATH):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if parsed is Dictionary:
        _manifest_cache = parsed.duplicate(true)
    return _manifest_cache.duplicate(true)


static func enemy_ids() -> Array[String]:
    return _ids_for("enemies")


static func event_ids() -> Array[String]:
    return _ids_for("events")


static func region_ids() -> Array[String]:
    return _ids_for("regions")


static func enemy_entries() -> Array[Dictionary]:
    return _entries_for("enemies")


static func event_entries() -> Array[Dictionary]:
    return _entries_for("events")


static func region_entries() -> Array[Dictionary]:
    return _entries_for("regions")


static func enemy_entry(enemy_id: String) -> Dictionary:
    return _entry_for("enemies", enemy_id)


static func event_entry(event_id: String) -> Dictionary:
    return _entry_for("events", event_id)


static func region_entry(region_id: String) -> Dictionary:
    return _entry_for("regions", region_id)


static func enemy_texture(enemy_id: String) -> Texture2D:
    return _texture_for("enemy", enemy_entry(enemy_id))


static func event_texture(event_id: String) -> Texture2D:
    return _texture_for("event", event_entry(event_id))


static func region_texture(region_id: String) -> Texture2D:
    return _texture_for("region", region_entry(region_id))


static func event_art_snapshot(event_id: String) -> Dictionary:
    var entry := event_entry(event_id)
    if entry.is_empty():
        return {}
    return {
        "event_id": event_id,
        "parent_region_id": str(entry.get("parent_region", "")),
        "path": str(entry.get("path", "")),
        "atlas_rect": (entry.get("atlas_rect", []) as Array).duplicate(),
        "placeholder": bool(entry.get("placeholder", true)),
    }


static func counts() -> Dictionary:
    var data := manifest()
    return {
        "enemies": int(data.get("enemy_behavior_count", 0)),
        "events": int(data.get("choice_event_count", 0)),
        "regions": int(data.get("region_count", 0)),
        "placeholders": int(data.get("placeholder_count", -1)),
    }


static func _ids_for(group: String) -> Array[String]:
    var result: Array[String] = []
    for entry: Dictionary in _entries_for(group):
        result.append(str(entry.get("id", "")))
    return result


static func _entries_for(group: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var data := manifest()
    var raw_entries: Variant = data.get(group, [])
    if not raw_entries is Array:
        return result
    for raw_entry: Variant in raw_entries:
        if raw_entry is Dictionary:
            result.append((raw_entry as Dictionary).duplicate(true))
    return result


static func _entry_for(group: String, target_id: String) -> Dictionary:
    for entry: Dictionary in _entries_for(group):
        if str(entry.get("id", "")) == target_id:
            return entry
    return {}


static func _texture_for(kind: String, entry: Dictionary) -> Texture2D:
    if entry.is_empty():
        return null
    var target_id := str(entry.get("id", ""))
    var cache_key := "%s:%s" % [kind, target_id]
    if _texture_cache.has(cache_key):
        var cached: Variant = _texture_cache[cache_key]
        return cached if cached is Texture2D else null
    var path := str(entry.get("path", ""))
    if path.is_empty():
        return null
    var loaded: Resource = load(path)
    if not loaded is Texture2D:
        return null
    var rect_data: Variant = entry.get("atlas_rect", [])
    if rect_data is Array and rect_data.size() == 4:
        var atlas := AtlasTexture.new()
        atlas.atlas = loaded as Texture2D
        atlas.region = Rect2(
            float(rect_data[0]), float(rect_data[1]), float(rect_data[2]), float(rect_data[3])
        )
        _texture_cache[cache_key] = atlas
        return atlas
    _texture_cache[cache_key] = loaded
    return loaded as Texture2D
