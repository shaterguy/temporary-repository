extends SceneTree

const RegionUnitTestScript = preload("res://tests/unit/test_region_expansion.gd")
const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const GLASS_ROOT: String = "user://ci_w18_glass_garden"
const ARCHIVE_ROOT: String = "user://ci_w18_flooded_archive"
const MAX_ACTION_MILLISECONDS: int = 3500

var _failures: Array[String] = []
var _route_override_ok: bool = false
var _phase_objective_ok: bool = false
var _persisted_region_ok: bool = false
var _archive_runtime_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_region_expansion")


func _run_region_expansion() -> void:
    _clear_save_root(GLASS_ROOT)
    _clear_save_root(ARCHIVE_ROOT)
    _failures.append_array(RegionUnitTestScript.run())
    var action_started_ms := Time.get_ticks_msec()

    var glass_shell := await _create_shell(GLASS_ROOT)
    if glass_shell == null:
        _failures.append("W18 Glass Garden main shell could not be created")
        await _finish(null, null, Time.get_ticks_msec() - action_started_ms)
        return
    var glass_campaign: Variant = glass_shell.get("campaign")
    glass_campaign.world.segment_index = 1
    glass_shell.call("_show_hub_prompt")
    if not bool(glass_shell.call("select_world_choice", 0)):
        _failures.append("W18 Glass Garden departure could not start through the actual shell")
    else:
        var snapshot: Dictionary = glass_shell.call("region_expansion_snapshot")
        _route_override_ok = (
            bool(snapshot.get("active", false))
            and str(snapshot.get("parent_region_id", "")) == "glass_garden"
            and str(snapshot.get("route_override_id", "")) == "supply_causeway"
            and str(snapshot.get("background_asset", "")).ends_with("environment_glass_garden.svg")
            and (snapshot.get("enemy_behavior_ids", []) as Array).size() == 6
        )
        if not _route_override_ok:
            _failures.append("W18 Glass Garden runtime did not mount route/spawn/background overrides")

        if not bool(glass_shell.call("request_phase_switch")):
            _failures.append("W18 actual shell could not enter the Glass Garden shadow phase")
        glass_shell.call("_on_circuit_activated", 18001, "snare", 65.0)
        var ark: Variant = glass_shell.get("ark_preview")
        var ark_model: Variant = ark.get("model") if is_instance_valid(ark) else null
        if ark_model == null:
            _failures.append("W18 Glass Garden Ark model was not mounted")
        else:
            for _index: int in range(40):
                if str(ark_model.get("status")) != "TRAVELING":
                    break
                ark_model.call("step", 1.0)
            glass_shell.call("_on_ark_state_changed", str(ark_model.get("status")), str(ark_model.get("selected_route_id")))
            var objective_snapshot: Dictionary = glass_shell.call("region_expansion_snapshot").get("objective", {})
            _phase_objective_ok = (
                str(ark_model.get("status")) == "RESTING"
                and int(objective_snapshot.get("phase_count", 0)) == 2
                and int(objective_snapshot.get("circuit_activation_count", 0)) >= 1
                and bool(objective_snapshot.get("rest_reached", false))
                and bool(objective_snapshot.get("complete", false))
            )
            if not _phase_objective_ok:
                _failures.append("W18 Glass Garden phase/circuit/rest objective did not complete through shell bridges")

        var checkpoint: Dictionary = glass_shell.call("_checkpoint_runtime", "w18_region_persistence")
        if not bool(checkpoint.get("ok", false)):
            _failures.append("W18 region checkpoint could not be persisted")
        else:
            var reloaded = CampaignRuntimeScript.new(GLASS_ROOT)
            var load_result: Dictionary = reloaded.load_slot(0)
            if bool(load_result.get("ok", false)):
                var resume: Dictionary = reloaded.world.resume_payload()
                var runtime_state: Dictionary = resume.get("runtime_state", {})
                var region_state: Dictionary = runtime_state.get("w18_region", {})
                _persisted_region_ok = (
                    str(region_state.get("schema", "")) == "w18-region-expedition-v1"
                    and str(region_state.get("region_id", "")) == "brine_veins"
                    and bool(region_state.get("rest_reached", false))
                    and int(region_state.get("circuit_activation_count", 0)) >= 1
                )
            if not _persisted_region_ok:
                _failures.append("W18 active region state did not survive persistent checkpoint reload")

    var archive_shell := await _create_shell(ARCHIVE_ROOT)
    if archive_shell == null:
        _failures.append("W18 Flooded Archive main shell could not be created")
    else:
        var archive_campaign: Variant = archive_shell.get("campaign")
        archive_campaign.world.segment_index = 2
        archive_shell.call("_show_hub_prompt")
        if not bool(archive_shell.call("select_world_choice", 0)):
            _failures.append("W18 Flooded Archive departure could not start through the actual shell")
        else:
            var archive_snapshot: Dictionary = archive_shell.call("region_expansion_snapshot")
            _archive_runtime_ok = (
                bool(archive_snapshot.get("active", false))
                and str(archive_snapshot.get("parent_region_id", "")) == "flooded_archive"
                and str(archive_snapshot.get("route_override_id", "")) == "supply_causeway"
                and str(archive_snapshot.get("background_asset", "")).ends_with("environment_flooded_archive.svg")
                and (archive_snapshot.get("enemy_behavior_ids", []) as Array).size() == 6
                and str((archive_snapshot.get("material_rule", {}) as Dictionary).get("hazard_id", "")) != str((archive_snapshot.get("shadow_rule", {}) as Dictionary).get("hazard_id", ""))
            )
            if not _archive_runtime_ok:
                _failures.append("W18 Flooded Archive runtime did not mount distinct route/spawn/background/phase rules")

    var action_ms := Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W18 region expansion actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    await _finish(glass_shell, archive_shell, action_ms)


func _create_shell(save_root: String) -> Node:
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        return null
    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame
    shell.set("campaign", CampaignRuntimeScript.new(save_root))
    shell.call("_show_slot_prompt")
    if not bool(shell.call("select_save_slot", 0)):
        shell.queue_free()
        await process_frame
        return null
    return shell


func _finish(glass_shell: Node, archive_shell: Node, action_ms: int) -> void:
    for shell: Node in [glass_shell, archive_shell]:
        if is_instance_valid(shell):
            shell.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save_root(GLASS_ROOT)
    _clear_save_root(ARCHIVE_ROOT)
    print("W18_REGION_ACTION_MS=%d" % action_ms)
    print("W18_PARENT_REGIONS=2")
    print("W18_ROUTE_PROFILES=4")
    print("W18_ENEMY_BEHAVIOR_DEFS=12")
    if _route_override_ok:
        print("W18_ROUTE_OVERRIDE=PASS")
    if _phase_objective_ok:
        print("W18_PHASE_OBJECTIVES=PASS")
    if _persisted_region_ok:
        print("W18_PERSISTED_REGION=PASS")
    if _archive_runtime_ok:
        print("W18_FLOODED_ARCHIVE_RUNTIME=PASS")
    if _failures.is_empty():
        print("W18_REGION_EXPANSION=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W18_FAIL: %s" % failure)
    printerr("W18_REGION_EXPANSION=FAIL")
    quit(1)


func _clear_save_root(save_root: String) -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, save_root)
