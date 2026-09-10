extends SceneTree

const EnemyPoolScript = preload("res://game/combat/enemy_pool.gd")
const SpatialHashScript = preload("res://game/combat/spatial_hash.gd")
const RuntimeScript = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")

const SAVE_ROOT: String = "user://ci_w27_performance_soak"
const POOL_LIVE_SET: int = 384
const POOL_WAVES: int = 80
const SHELL_WARMUP_CYCLES: int = 4
const SHELL_SOAK_CYCLES: int = 24
const SAVE_CHECKPOINTS: int = 96
const SAVE_RELOAD_INTERVAL: int = 12
const MAX_POOL_SPATIAL_MS: int = 8000
const MAX_SAVE_SOAK_MS: int = 12000
const MAX_TOTAL_MS: int = 25000
const MAX_STATIC_MEMORY_GROWTH_BYTES: int = 64 * 1024 * 1024
const MAX_OBJECT_GROWTH: int = 24
const MAX_NODE_GROWTH: int = 8

var _failures: Array[String] = []
var _pool_spatial_ms: int = 0
var _save_soak_ms: int = 0
var _total_ms: int = 0
var _memory_growth_bytes: int = 0
var _object_growth: int = 0
var _node_growth: int = 0
var _orphan_growth: int = 0


func _initialize() -> void:
    call_deferred("_run_w27")


func _run_w27() -> void:
    _clear_save_root()
    await process_frame
    var total_started := Time.get_ticks_msec()
    _test_pool_and_spatial_pressure()
    await _test_shell_lifecycle_soak()
    _test_save_checkpoint_soak()
    _total_ms = Time.get_ticks_msec() - total_started
    if _total_ms > MAX_TOTAL_MS:
        _failures.append("W27 total automated soak exceeded %dms: %dms" % [MAX_TOTAL_MS, _total_ms])
    _clear_save_root()

    print("W27_POOL_LIVE_SET=%d" % POOL_LIVE_SET)
    print("W27_POOL_WAVES=%d" % POOL_WAVES)
    print("W27_POOL_SPATIAL_MS=%d" % _pool_spatial_ms)
    print("W27_SHELL_SOAK_CYCLES=%d" % SHELL_SOAK_CYCLES)
    print("W27_STATIC_MEMORY_GROWTH_BYTES=%d" % _memory_growth_bytes)
    print("W27_OBJECT_GROWTH=%d" % _object_growth)
    print("W27_NODE_GROWTH=%d" % _node_growth)
    print("W27_ORPHAN_GROWTH=%d" % _orphan_growth)
    print("W27_SAVE_CHECKPOINTS=%d" % SAVE_CHECKPOINTS)
    print("W27_SAVE_SOAK_MS=%d" % _save_soak_ms)
    print("W27_TOTAL_MS=%d" % _total_ms)
    print("W27_REAL_DEVICE_FRAME_PACING=PENDING")
    print("W27_REAL_DEVICE_THERMAL_LMK=PENDING")

    if _failures.is_empty():
        print("W27_POOL_REUSE=PASS")
        print("W27_SPATIAL_PRESSURE=PASS")
        print("W27_SCENE_LIFECYCLE=PASS")
        print("W27_MEMORY_GROWTH=PASS")
        print("W27_SAVE_SOAK=PASS")
        print("W27_PERFORMANCE_SOAK=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W27_FAIL: %s" % failure)
    printerr("W27_PERFORMANCE_SOAK=FAIL")
    quit(1)


func _test_pool_and_spatial_pressure() -> void:
    var started := Time.get_ticks_msec()
    var pool = EnemyPoolScript.new()
    var spatial = SpatialHashScript.new(64.0)
    var total_queries := 0
    for wave: int in range(POOL_WAVES):
        spatial.clear()
        var ids: Array[int] = []
        for index: int in range(POOL_LIVE_SET):
            var position := Vector2(float((index % 32) * 22), float((index / 32) * 22))
            var state: Dictionary = pool.acquire("w27_pressure", position, 12, 84.0, 8.0, 1)
            var entity_id := int(state.get("id", -1))
            if entity_id < 0:
                _failures.append("W27 pool acquire failed at wave %d index %d" % [wave, index])
                return
            ids.append(entity_id)
            spatial.insert(entity_id, position)
        if pool.active_count() != POOL_LIVE_SET:
            _failures.append("W27 pool active count drifted at wave %d: %d" % [wave, pool.active_count()])
            return
        if pool.capacity() != POOL_LIVE_SET:
            _failures.append("W27 pool capacity grew beyond reusable live set at wave %d: %d" % [wave, pool.capacity()])
            return
        for query_index: int in range(8):
            var origin := Vector2(float(((wave + query_index) % 32) * 22), float(((wave * 3 + query_index) % 12) * 22))
            var nearby: Array[Dictionary] = spatial.query_radius(origin, 96.0)
            if nearby.is_empty():
                _failures.append("W27 spatial query unexpectedly returned no local entities")
                return
            total_queries += 1
        for entity_id: int in ids:
            var result: Dictionary = pool.apply_damage(entity_id, 12)
            if not bool(result.get("found", false)) or not bool(result.get("killed", false)):
                _failures.append("W27 pooled entity did not recycle deterministically: %d" % entity_id)
                return
        if pool.active_count() != 0:
            _failures.append("W27 pool retained live entities after recycle wave %d" % wave)
            return
    _pool_spatial_ms = Time.get_ticks_msec() - started
    if pool.capacity() != POOL_LIVE_SET:
        _failures.append("W27 pool capacity changed after churn: %d" % pool.capacity())
    if total_queries != POOL_WAVES * 8:
        _failures.append("W27 spatial query count drifted: %d" % total_queries)
    if _pool_spatial_ms > MAX_POOL_SPATIAL_MS:
        _failures.append("W27 pool/spatial pressure exceeded %dms: %dms" % [MAX_POOL_SPATIAL_MS, _pool_spatial_ms])


func _test_shell_lifecycle_soak() -> void:
    var packed: Resource = load("res://game/ui/main_shell.tscn")
    if not packed is PackedScene:
        _failures.append("W27 main shell scene could not be loaded")
        return
    for warmup: int in range(SHELL_WARMUP_CYCLES):
        await _cycle_shell(packed as PackedScene, warmup)
    await process_frame
    var baseline_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
    var baseline_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
    var baseline_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    var baseline_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

    for cycle: int in range(SHELL_SOAK_CYCLES):
        await _cycle_shell(packed as PackedScene, SHELL_WARMUP_CYCLES + cycle)
    await process_frame
    await process_frame

    var after_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
    var after_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
    var after_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    var after_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
    _memory_growth_bytes = maxi(0, after_memory - baseline_memory)
    _object_growth = maxi(0, after_objects - baseline_objects)
    _node_growth = maxi(0, after_nodes - baseline_nodes)
    _orphan_growth = maxi(0, after_orphans - baseline_orphans)

    if _memory_growth_bytes > MAX_STATIC_MEMORY_GROWTH_BYTES:
        _failures.append("W27 static memory grew by %d bytes after scene soak" % _memory_growth_bytes)
    if _object_growth > MAX_OBJECT_GROWTH:
        _failures.append("W27 object count grew by %d after scene soak" % _object_growth)
    if _node_growth > MAX_NODE_GROWTH:
        _failures.append("W27 node count grew by %d after scene soak" % _node_growth)
    if _orphan_growth > 0:
        _failures.append("W27 orphan node count grew by %d after scene soak" % _orphan_growth)


func _cycle_shell(packed: PackedScene, cycle: int) -> void:
    var shell := packed.instantiate()
    root.add_child(shell)
    await process_frame
    shell.set("shell_mode", "EXPEDITION")
    if shell.has_method("set_transient_input"):
        shell.call("set_transient_input", Vector2(0.65 if cycle % 2 == 0 else -0.65, 0.2), cycle % 3 == 0, cycle % 5 == 0)
    await process_frame
    var overlay := shell.get_node_or_null("W25MobileControls")
    if overlay != null and overlay.has_method("cancel_all_input"):
        overlay.call("cancel_all_input")
    shell.queue_free()
    await process_frame


func _test_save_checkpoint_soak() -> void:
    var started := Time.get_ticks_msec()
    SaveStoreScript.clear_slot(0, SAVE_ROOT)
    var runtime = RuntimeScript.new(SAVE_ROOT)
    var started_game: Dictionary = runtime.start_new(0, 270001, true)
    if not bool(started_game.get("ok", false)):
        _failures.append("W27 save soak could not create slot: %s" % str(started_game.get("status", "UNKNOWN")))
        return
    var expected_sequence := int(runtime.sequence)
    for index: int in range(SAVE_CHECKPOINTS):
        var payload := {
            "schema": "w27-soak-v1",
            "tick": index,
            "position": [index % 17, index % 11],
            "flags": {"paused": index % 2 == 0, "phase": "material" if index % 3 else "shadow"},
        }
        var checkpoint: Dictionary = runtime.checkpoint("w27_soak_%03d" % index, payload)
        if not bool(checkpoint.get("ok", false)):
            _failures.append("W27 checkpoint failed at %d: %s" % [index, str(checkpoint.get("status", "UNKNOWN"))])
            return
        expected_sequence += 1
        if runtime.sequence != expected_sequence:
            _failures.append("W27 save sequence drifted at %d: expected %d got %d" % [index, expected_sequence, runtime.sequence])
            return
        if (index + 1) % SAVE_RELOAD_INTERVAL == 0:
            var reloaded = RuntimeScript.new(SAVE_ROOT)
            var load_result: Dictionary = reloaded.load_slot(0)
            if not bool(load_result.get("ok", false)):
                _failures.append("W27 reload failed after checkpoint %d: %s" % [index, str(load_result.get("status", "UNKNOWN"))])
                return
            if reloaded.sequence != expected_sequence:
                _failures.append("W27 reload sequence drifted after checkpoint %d" % index)
                return
            runtime = reloaded
    var final_read: Dictionary = SaveStoreScript.read_slot(0, SAVE_ROOT)
    if not bool(final_read.get("ok", false)):
        _failures.append("W27 final save readback failed")
    else:
        var envelope: Dictionary = final_read.get("envelope", {})
        if int(envelope.get("sequence", -1)) != expected_sequence:
            _failures.append("W27 final save envelope sequence mismatch")
    _save_soak_ms = Time.get_ticks_msec() - started
    if _save_soak_ms > MAX_SAVE_SOAK_MS:
        _failures.append("W27 save soak exceeded %dms: %dms" % [MAX_SAVE_SOAK_MS, _save_soak_ms])


func _clear_save_root() -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, SAVE_ROOT)
