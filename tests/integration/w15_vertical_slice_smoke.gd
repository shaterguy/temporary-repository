extends SceneTree

const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")
const TEST_ROOT: String = "user://ci_w15_vertical_slice"
const MAX_ACTION_MILLISECONDS: int = 2500

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run_vertical_slice")


func _run_vertical_slice() -> void:
    _clear_save()
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        _failures.append("main shell scene could not be loaded")
        _finish(null, 0)
        return

    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame

    shell.set("campaign", CampaignRuntimeScript.new(TEST_ROOT))
    shell.call("_show_slot_prompt")
    var tutorial: Node = shell.get_node_or_null("W15FirstExpeditionTutorial")
    if not is_instance_valid(tutorial):
        _failures.append("W15 first-expedition tutorial is not mounted in the main scene")
        _finish(shell, 0)
        return

    if shell.get_node_or_null("W13RepresentativeArt") == null or shell.get_node_or_null("W13RepresentativeHud") == null:
        _failures.append("W13 representative art/HUD is not mounted in the actual main scene")
    if str(ProjectSettings.get_setting("autoload/AudioDirector", "")) != "*res://game/audio/audio_director.gd":
        _failures.append("W14 AudioDirector is not configured as the actual runtime autoload")

    var action_started_ms := Time.get_ticks_msec()
    if not bool(shell.call("select_save_slot", 0)):
        _failures.append("main scene could not create/select the first persistent slot")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return
    tutorial.call("_refresh_from_runtime")
    if str(tutorial.call("current_step")) != "depart":
        _failures.append("tutorial did not bind to the real slot-selection state")

    if not bool(shell.call("select_world_choice", 0)):
        _failures.append("main scene could not enter the first expedition from the hub")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return
    tutorial.call("_refresh_from_runtime")

    var campaign: Variant = shell.get("campaign")
    var world: Variant = campaign.get("world")
    if str(world.get("state")) != "EXPEDITION":
        _failures.append("hub choice did not enter the persistent expedition state")

    var ark: Variant = shell.get("ark_preview")
    var circuit: Variant = shell.get("circuit_preview")
    var phase: Variant = shell.get("phase_preview")
    var combat: Variant = shell.get("combat_preview")
    var encounter: Variant = shell.get("encounter_preview")
    for runtime_node in [ark, circuit, phase, combat, encounter]:
        if not is_instance_valid(runtime_node):
            _failures.append("one or more W15 gameplay runtime nodes are missing from the main scene")
            break

    if is_instance_valid(ark) and ark.has_method("state_snapshot"):
        var ark_state: Dictionary = ark.call("state_snapshot")
        if str(ark_state.get("selected_route_id", "")).is_empty():
            _failures.append("N01 Ark route was not configured by the real hub departure choice")
    else:
        _failures.append("N01 Ark runtime bridge is unavailable")

    if is_instance_valid(combat) and combat.has_method("weapon_status_snapshot"):
        var weapon_state: Dictionary = combat.call("weapon_status_snapshot")
        var recipe: Dictionary = weapon_state.get("recipe", {})
        if str(weapon_state.get("weapon_id", "")).is_empty() or recipe.is_empty():
            _failures.append("N03 causal weapon is not equipped in the actual survivor runtime")
    else:
        _failures.append("N03 causal weapon runtime bridge is unavailable")

    shell.call("set_transient_input", Vector2.RIGHT, false, false)
    tutorial.call("_refresh_from_runtime")
    await process_frame
    await process_frame
    shell.call("set_transient_input", Vector2.ZERO, false, false)
    if str(tutorial.call("current_step")) != "circuit":
        _failures.append("tutorial did not observe movement from the actual expedition input bridge")

    if is_instance_valid(circuit):
        circuit.call("reset_for_expedition")
        circuit.call("select_module", LightCircuitModelScript.MODULE_SNARE)
        var circuit_model: Variant = circuit.get("model")
        var loop_points := PackedVector2Array([
            Vector2(-60.0, -60.0),
            Vector2(60.0, -60.0),
            Vector2(60.0, 60.0),
            Vector2(-60.0, 60.0),
            Vector2(-60.0, -60.0),
        ])
        for point in loop_points:
            circuit_model.call("step", 0.10, point, false)
        var circuit_status: Dictionary = circuit.call("status_snapshot")
        if int(circuit_status.get("active_count", 0)) < 1:
            _failures.append("N02 real circuit controller did not expose an activated movement loop")
        tutorial.call("_refresh_from_runtime")
        if str(tutorial.call("current_step")) != "phase":
            _failures.append("tutorial did not observe the actual N02 circuit state")
    else:
        _failures.append("N02 circuit runtime bridge is unavailable")

    var phase_switched := bool(shell.call("request_phase_switch"))
    if not phase_switched:
        _failures.append("N07 actual main-scene phase transition was rejected in the first-slice fixture")
    if is_instance_valid(phase) and phase.has_method("status_snapshot"):
        var phase_status: Dictionary = phase.call("status_snapshot")
        if int(phase_status.get("transition_generation", 0)) < 1:
            _failures.append("N07 phase transition generation did not advance")
    tutorial.call("_refresh_from_runtime")
    if str(tutorial.call("current_step")) != "settle":
        _failures.append("tutorial did not observe the actual N07 phase transition")

    shell.call("_settle_current", "success")
    await process_frame
    await process_frame
    tutorial.call("_refresh_from_runtime")

    if str(shell.get("shell_mode")) != "HUB" or int(world.get("segment_index")) != 1:
        _failures.append("first expedition did not settle back to hub with world progression")

    var echo_record: Dictionary = campaign.call("current_echo_record")
    if str(echo_record.get("record_id", "")).is_empty():
        _failures.append("N04 tactical echo from the completed expedition was not persisted")

    var doctrine_plan: Dictionary = campaign.call("current_doctrine_plan")
    if str(doctrine_plan.get("doctrine_id", "")).is_empty():
        _failures.append("N05 disclosed doctrine plan was not available after settlement")

    var next_options: Array[Dictionary] = world.call("departure_options")
    if next_options.size() != 2:
        _failures.append("N06 world graph did not expose the next mutually exclusive departure choices")

    var reloaded = CampaignRuntimeScript.new(TEST_ROOT)
    var load_result: Dictionary = reloaded.load_slot(0)
    if not bool(load_result.get("ok", false)) or reloaded.world.segment_index != 1 or reloaded.world.state != "HUB":
        _failures.append("W12 save boundary did not preserve the W15 settlement across reload")

    var tutorial_state: Dictionary = tutorial.call("status_snapshot")
    if not bool(tutorial_state.get("complete", false)) or str(tutorial_state.get("step", "")) != "complete":
        _failures.append("first-expedition tutorial did not complete from real runtime milestones")

    var action_ms := Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W15 vertical-slice actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])

    _finish(shell, action_ms)


func _finish(shell: Node, action_ms: int) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
        await process_frame
        await process_frame
        await process_frame
    _clear_save()

    print("W15_VERTICAL_ACTION_MS=%d" % action_ms)
    print("W15_VERTICAL_SYSTEMS=7")
    if _failures.is_empty():
        print("W15_TUTORIAL=COMPLETE")
        print("W15_SAVE_RELOAD=PASS")
        print("W15_PRESENTATION=W13+W14")
        print("W15_VERTICAL_SLICE=PASS")
        quit(0)
        return

    for failure in _failures:
        printerr("W15_FAIL: %s" % failure)
    printerr("W15_VERTICAL_SLICE=FAIL")
    quit(1)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
