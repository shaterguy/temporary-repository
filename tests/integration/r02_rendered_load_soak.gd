extends SceneTree

const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_r02_rendered_load_soak"
const OUTPUT_DIR: String = "res://artifacts/r02"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const ENEMY_TARGET: int = 600
const PROJECTILE_ACTION_TARGET: int = 1000
const DECORATIVE_EFFECT_TARGET: int = 300
const EFFECT_HEAVY_FRAMES: int = 30
const SUSTAINED_FRAMES: int = 300
const MAX_EVENT_ITERATIONS: int = 5000

var _failures: Array[String] = []
var _observed_weapon_actions: int = 0
var _enemy_peak: int = 0
var _projectile_action_peak: int = 0
var _effect_peak: int = 0
var _weapon_burst_ms: float = 0.0
var _frame_samples_ms: Array[float] = []
var _memory_before_bytes: int = 0
var _memory_after_bytes: int = 0
var _baseline_checkpoint_status: String = "NOT_RUN"
var _final_checkpoint_status: String = "NOT_RUN"


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _clear_save()
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    _expect(DirAccess.make_dir_recursive_absolute(output_dir_absolute) == OK, "R02 artifact directory could not be created")

    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "R02 main shell scene could not be loaded")
    if not packed is PackedScene:
        _finish(null, null)
        return

    var viewport := SubViewport.new()
    viewport.name = "R02RenderedLoadViewport"
    viewport.size = VIEWPORT_SIZE
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)

    var shell: Node = (packed as PackedScene).instantiate()
    shell.set("campaign", CampaignRuntimeW22Script.new(TEST_ROOT))
    viewport.add_child(shell)
    await process_frame
    await process_frame
    await process_frame

    _expect(bool(shell.call("select_save_slot", 0)), "R02 could not create/select the real persistent slot")
    await process_frame
    _expect(bool(shell.call("select_world_choice", 0)), "R02 could not enter the real expedition")
    await process_frame
    await physics_frame
    await process_frame
    _expect(str(shell.get("shell_mode")) == "EXPEDITION", "R02 main shell did not enter EXPEDITION")

    var encounter: Variant = shell.get("encounter_preview")
    var combat: Variant = shell.get("combat_preview")
    var phase: Variant = shell.get("phase_preview")
    var art := shell.get_node_or_null("W13RepresentativeArt")
    _expect(is_instance_valid(encounter), "R02 encounter runtime is missing")
    _expect(is_instance_valid(combat), "R02 combat runtime is missing")
    _expect(is_instance_valid(art), "R02 representative art runtime is missing")
    if not is_instance_valid(encounter) or not is_instance_valid(combat) or not is_instance_valid(art):
        _finish(shell, viewport)
        return

    if combat.has_signal("weapon_action"):
        combat.connect("weapon_action", Callable(self, "_on_weapon_action_observed"))

    # The host render environment can run far slower than device real time. Freeze
    # only MainShell's wall-clock policy loop so a 300-frame render soak cannot
    # accidentally trigger periodic checkpoints or deferred settlement merely because
    # llvmpipe took >15 seconds. Child production runtimes and rendering stay alive.
    shell.set_process(false)
    var baseline_checkpoint: Dictionary = shell.call("_checkpoint_runtime", "r02_baseline_before_load")
    _baseline_checkpoint_status = str(baseline_checkpoint.get("status", "UNKNOWN"))
    _expect(
        bool(baseline_checkpoint.get("ok", false)),
        "R02 baseline checkpoint failed before load: %s" % _baseline_checkpoint_status
    )

    var load_ids := _inject_enemy_load(encounter, phase)
    _enemy_peak = int(encounter.call("active_enemy_count"))
    _expect(load_ids.size() == ENEMY_TARGET, "R02 could not inject 600 production EnemyPool entities")
    _expect(_enemy_peak >= ENEMY_TARGET, "R02 active enemy count did not reach 600")

    # combat_target_snapshot includes every runtime entity but marks phase/path-blocked
    # enemies inactive for targeting. Keep the 600-entity stress contract separate from
    # the legitimate attackable subset used by the weapon resolver.
    var runtime_targets := _runtime_targets(encounter)
    _expect(runtime_targets.size() >= ENEMY_TARGET, "R02 target provider did not expose 600 runtime enemies")
    var target_snapshot := _active_targets(runtime_targets)
    _expect(not target_snapshot.is_empty(), "R02 target provider exposed no currently attackable runtime enemies")
    if target_snapshot.is_empty():
        shell.set_process(true)
        _finish(shell, viewport)
        return

    _memory_before_bytes = int(Performance.get_monitor(Performance.MEMORY_STATIC))

    # Keep automatic player attacks from adding fresh effects while the harness
    # establishes exact concurrent loads. Manual calls still use the production
    # resolver/application path. Enemy/ark/phase child runtimes remain active.
    combat.set_physics_process(false)

    # The product has no projectile node/model: weapon delivery resolves as real
    # weapon_damage actions. Stress that production resolver/application path instead
    # of inventing test-only projectile objects. VFX aging is paused only while the
    # simultaneous queue is being established.
    art.call("set_low_vfx_mode", true)
    art.set_process(false)
    var burst_started := Time.get_ticks_usec()
    var event_iterations := 0
    while _observed_weapon_actions < PROJECTILE_ACTION_TARGET and event_iterations < MAX_EVENT_ITERATIONS:
        var target: Dictionary = target_snapshot[event_iterations % target_snapshot.size()]
        var event_batch: Array[Dictionary] = [{
            "type": "auto_attack",
            "target_id": int(target.get("id", -1)),
        }]
        combat.call("_resolve_events", event_batch)
        event_iterations += 1
    _weapon_burst_ms = float(Time.get_ticks_usec() - burst_started) / 1000.0
    _projectile_action_peak = _observed_weapon_actions
    _expect(_projectile_action_peak >= PROJECTILE_ACTION_TARGET, "R02 production weapon-action load did not reach 1000")
    _expect(_effect_count(art) >= PROJECTILE_ACTION_TARGET, "R02 weapon_action signal did not populate the production VFX queue")

    # Advance the production VFX lifetime routine directly while regular processing
    # is paused. Waiting 90 host-render frames here previously allowed unrelated
    # MainShell wall-clock policy to overtake the load test on llvmpipe.
    art.call("_process", 1.0)
    _expect(_effect_count(art) == 0, "R02 production VFX queue did not expire after its bounded lifetime")

    # Establish the separate 300-effect rendered load using the same real weapon
    # resolver and real representative-art queue. Aging is frozen for 30 rendered
    # frames so host render timing can be measured at a stable simultaneous load.
    art.call("set_low_vfx_mode", false)
    art.set_process(false)
    var effect_iterations := 0
    while _effect_count(art) < DECORATIVE_EFFECT_TARGET and effect_iterations < MAX_EVENT_ITERATIONS:
        var target: Dictionary = target_snapshot[effect_iterations % target_snapshot.size()]
        var event_batch: Array[Dictionary] = [{
            "type": "auto_attack",
            "target_id": int(target.get("id", -1)),
        }]
        combat.call("_resolve_events", event_batch)
        effect_iterations += 1
    _effect_peak = _effect_count(art)
    _expect(_effect_peak >= DECORATIVE_EFFECT_TARGET, "R02 production decorative VFX load did not reach 300")
    _expect(int(encounter.call("active_enemy_count")) >= ENEMY_TARGET, "R02 enemy load fell below 600 before rendered soak")

    art.queue_redraw()
    encounter.queue_redraw()
    await process_frame
    _save_capture(viewport, "%s/peak-600-1000-300-1280x720.png" % OUTPUT_DIR)

    for frame_index in range(SUSTAINED_FRAMES):
        var frame_started := Time.get_ticks_usec()
        await process_frame
        _frame_samples_ms.append(float(Time.get_ticks_usec() - frame_started) / 1000.0)
        if frame_index + 1 == EFFECT_HEAVY_FRAMES:
            art.set_process(true)
        if (frame_index + 1) % 60 == 0:
            _expect(int(encounter.call("active_enemy_count")) >= ENEMY_TARGET, "R02 enemy load fell below 600 during sustained rendered soak")

    art.set_process(true)
    _memory_after_bytes = int(Performance.get_monitor(Performance.MEMORY_STATIC))
    var checkpoint: Dictionary = shell.call("_checkpoint_runtime", "r02_rendered_load_soak")
    _final_checkpoint_status = str(checkpoint.get("status", "UNKNOWN"))
    _expect(
        bool(checkpoint.get("ok", false)),
        "R02 600-enemy runtime could not checkpoint after sustained soak: %s" % _final_checkpoint_status
    )
    shell.set_process(true)
    combat.set_physics_process(true)

    _finish(shell, viewport)


func _inject_enemy_load(encounter: Node, phase: Variant) -> Array[int]:
    var result: Array[int] = []
    var pool: Variant = encounter.get("_pool")
    if pool == null or not pool.has_method("acquire"):
        _failures.append("R02 production EnemyPool is unavailable")
        return result

    var phase_id := "material"
    if is_instance_valid(phase) and phase.has_method("current_phase_id"):
        phase_id = str(phase.call("current_phase_id"))
    var phase_map: Dictionary = encounter.get("_enemy_phases")

    for index in range(ENEMY_TARGET):
        var column := index % 30
        var row := int(index / 30)
        var position := Vector2(36.0 + float(column) * 40.0, 48.0 + float(row) * 31.0)
        var state: Dictionary = pool.call("acquire", "swarm", position, 100000, 0.0, 8.0, 0)
        if state.is_empty():
            break
        var entity_id := int(state.get("id", -1))
        result.append(entity_id)
        phase_map[entity_id] = phase_id
    encounter.set("_enemy_phases", phase_map)
    encounter.queue_redraw()
    return result


func _runtime_targets(encounter: Node) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var raw: Variant = encounter.call("combat_target_snapshot")
    if not raw is Array:
        return result
    for value in raw:
        if value is Dictionary:
            result.append((value as Dictionary).duplicate(true))
    return result


func _active_targets(runtime_targets: Array[Dictionary]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value: Dictionary in runtime_targets:
        if bool(value.get("active", false)):
            result.append(value.duplicate(true))
    return result


func _effect_count(art: Node) -> int:
    var raw: Variant = art.get("_bursts")
    return raw.size() if raw is Array else -1


func _on_weapon_action_observed(_action: Dictionary) -> void:
    _observed_weapon_actions += 1


func _save_capture(viewport: SubViewport, path: String) -> void:
    var image := viewport.get_texture().get_image()
    _expect(not image.is_empty(), "R02 rendered load capture is empty")
    if image.is_empty():
        return
    _expect(image.get_width() == VIEWPORT_SIZE.x and image.get_height() == VIEWPORT_SIZE.y, "R02 rendered load capture dimensions drifted")
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    _expect(save_error == OK, "R02 rendered load capture could not be saved")


func _percentile(values: Array[float], quantile: float) -> float:
    if values.is_empty():
        return 0.0
    var sorted := values.duplicate()
    sorted.sort()
    var index := clampi(int(round(float(sorted.size() - 1) * clampf(quantile, 0.0, 1.0))), 0, sorted.size() - 1)
    return float(sorted[index])


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish(shell: Node, viewport: SubViewport) -> void:
    if is_instance_valid(shell):
        shell.set_process(true)
        shell.queue_free()
    if is_instance_valid(viewport):
        viewport.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save()

    if _failures.is_empty():
        print("R02_REAL_MAIN_SCENE=PASS")
        print("R02_BASELINE_CHECKPOINT_STATUS=%s" % _baseline_checkpoint_status)
        print("R02_ENEMY_LOAD_TARGET=600")
        print("R02_ENEMY_LOAD_ACTUAL=%d" % _enemy_peak)
        print("R02_PROJECTILE_LOAD_TARGET=1000")
        print("R02_PROJECTILE_LOAD_SEMANTICS=weapon_action")
        print("R02_PROJECTILE_NODE_MODEL=ABSENT_BY_DESIGN")
        print("R02_WEAPON_ACTIONS_ACTUAL=%d" % _projectile_action_peak)
        print("R02_DECORATIVE_EFFECT_TARGET=300")
        print("R02_DECORATIVE_EFFECT_ACTUAL=%d" % _effect_peak)
        print("R02_WEAPON_BURST_MS=%.3f" % _weapon_burst_ms)
        print("R02_RENDER_FRAME_P50_MS=%.3f" % _percentile(_frame_samples_ms, 0.50))
        print("R02_RENDER_FRAME_P95_MS=%.3f" % _percentile(_frame_samples_ms, 0.95))
        print("R02_RENDER_FRAME_P99_MS=%.3f" % _percentile(_frame_samples_ms, 0.99))
        print("R02_MEMORY_BEFORE_BYTES=%d" % _memory_before_bytes)
        print("R02_MEMORY_AFTER_BYTES=%d" % _memory_after_bytes)
        print("R02_EFFECT_HEAVY_FRAMES=%d" % EFFECT_HEAVY_FRAMES)
        print("R02_SUSTAINED_FRAMES=%d" % SUSTAINED_FRAMES)
        print("R02_FINAL_CHECKPOINT_STATUS=%s" % _final_checkpoint_status)
        print("R02_SAVE_CHECKPOINT=PASS")
        print("R02_HOST_PERF_ENV=ubuntu-xvfb-gl_compatibility")
        print("R02_ANDROID_DEVICE_PERF=PENDING_R04")
        print("R02_HUMAN_VISUAL_AUDIO=PENDING")
        print("R02_RENDERED_LOAD_SOAK=PASS")
        quit(0)
        return

    for failure: String in _failures:
        printerr("R02_FAIL: %s" % failure)
    printerr("R02_BASELINE_CHECKPOINT_STATUS=%s" % _baseline_checkpoint_status)
    printerr("R02_FINAL_CHECKPOINT_STATUS=%s" % _final_checkpoint_status)
    printerr("R02_RENDERED_LOAD_SOAK=FAIL")
    quit(1)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
