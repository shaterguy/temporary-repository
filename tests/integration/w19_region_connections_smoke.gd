extends SceneTree

const RegionUnitTestScript = preload("res://tests/unit/test_w19_region_connections.gd")
const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const ASH_ROOT: String = "user://ci_w19_ash_railway"
const FORTRESS_ROOT: String = "user://ci_w19_eclipse_fortress"
const MAX_ACTION_MILLISECONDS: int = 4000

var _failures: Array[String] = []
var _ash_runtime_ok: bool = false
var _ash_objective_ok: bool = false
var _ash_checkpoint_ok: bool = false
var _fortress_runtime_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_w19")


func _run_w19() -> void:
    _clear_save_root(ASH_ROOT)
    _clear_save_root(FORTRESS_ROOT)
    _failures.append_array(RegionUnitTestScript.run())
    var action_started_ms := Time.get_ticks_msec()

    var ash_shell := await _create_shell(ASH_ROOT)
    if ash_shell == null:
        _failures.append("W19 Ash Railway main shell could not be created")
        await _finish(null, null, Time.get_ticks_msec() - action_started_ms)
        return
    var ash_campaign: Variant = ash_shell.get("campaign")
    ash_campaign.world.segment_index = 3
    ash_campaign.world.state = "POST_FINAL"
    ash_shell.call("_show_hub_prompt")
    if not bool(ash_shell.call("select_world_choice", 0)):
        _failures.append("W19 Ash Railway world connection could not start through the actual shell")
    else:
        var ash_snapshot: Dictionary = ash_shell.call("region_expansion_snapshot")
        var ash_region_model: Variant = ash_shell.get("region_model")
        var ash_profile: Dictionary = ash_region_model.get("active_profile") if ash_region_model != null else {}
        var ash_connection: Dictionary = ash_profile.get("world_connection", {})
        _ash_runtime_ok = (
            bool(ash_snapshot.get("active", false))
            and str(ash_snapshot.get("region_id", "")) == "afterglow_frontier"
            and str(ash_snapshot.get("parent_region_id", "")) == "ash_railway"
            and str(ash_snapshot.get("route_override_id", "")) == "supply_causeway"
            and str(ash_snapshot.get("background_asset", "")).ends_with("environment_ash_railway.svg")
            and (ash_snapshot.get("enemy_behavior_ids", []) as Array).size() == 6
            and str(ash_connection.get("choice_id", "")) == "deep_rescue_patrol"
        )
        if not _ash_runtime_ok:
            _failures.append("W19 Ash Railway runtime did not mount its route/spawn/background/world-connection contract")

        if not bool(ash_shell.call("request_phase_switch")):
            _failures.append("W19 Ash Railway could not enter shadow phase through the actual shell")
        ash_shell.call("_on_circuit_activated", 19001, "snare", 62.0)
        ash_shell.call("_on_circuit_activated", 19002, "ward", 54.0)
        var ash_ark: Variant = ash_shell.get("ark_preview")
        var ash_ark_model: Variant = ash_ark.get("model") if is_instance_valid(ash_ark) else null
        if ash_ark_model == null:
            _failures.append("W19 Ash Railway Ark model was not mounted")
        else:
            for _index: int in range(48):
                if str(ash_ark_model.get("status")) != "TRAVELING":
                    break
                ash_ark_model.call("step", 1.0)
            ash_shell.call("_on_ark_state_changed", str(ash_ark_model.get("status")), str(ash_ark_model.get("selected_route_id")))
            var objective: Dictionary = ash_shell.call("region_expansion_snapshot").get("objective", {})
            _ash_objective_ok = (
                str(ash_ark_model.get("status")) == "RESTING"
                and int(objective.get("phase_count", 0)) == 2
                and int(objective.get("circuit_activation_count", 0)) >= 2
                and bool(objective.get("complete", false))
            )
            if not _ash_objective_ok:
                _failures.append("W19 Ash Railway phase/circuit/rest objective did not complete")

        var checkpoint: Dictionary = ash_shell.call("_checkpoint_runtime", "w19_ash_persistence")
        if not bool(checkpoint.get("ok", false)):
            _failures.append("W19 Ash Railway checkpoint could not be persisted")
        else:
            var reloaded = CampaignRuntimeScript.new(ASH_ROOT)
            var load_result: Dictionary = reloaded.load_slot(0)
            if bool(load_result.get("ok", false)):
                var resume: Dictionary = reloaded.world.resume_payload()
                var runtime_state: Dictionary = resume.get("runtime_state", {})
                var region_state: Dictionary = runtime_state.get("w18_region", {})
                _ash_checkpoint_ok = (
                    not str(runtime_state.get("character_id", "")).is_empty()
                    and str(region_state.get("schema", "")) == "w18-region-expedition-v1"
                    and str(region_state.get("region_id", "")) == "afterglow_frontier"
                    and int(region_state.get("circuit_activation_count", 0)) >= 2
                )
            if not _ash_checkpoint_ok:
                _failures.append("W19 Ash Railway checkpoint lost inherited character or regional state")

    var fortress_shell := await _create_shell(FORTRESS_ROOT)
    if fortress_shell == null:
        _failures.append("W19 Eclipse Fortress main shell could not be created")
    else:
        var fortress_campaign: Variant = fortress_shell.get("campaign")
        fortress_campaign.world.segment_index = 3
        fortress_campaign.world.state = "POST_FINAL"
        fortress_shell.call("_show_hub_prompt")
        if not bool(fortress_shell.call("select_world_choice", 1)):
            _failures.append("W19 Eclipse Fortress world connection could not start through the actual shell")
        else:
            var fortress_snapshot: Dictionary = fortress_shell.call("region_expansion_snapshot")
            var fortress_region_model: Variant = fortress_shell.get("region_model")
            var fortress_profile: Dictionary = fortress_region_model.get("active_profile") if fortress_region_model != null else {}
            var fortress_connection: Dictionary = fortress_profile.get("world_connection", {})
            _fortress_runtime_ok = (
                bool(fortress_snapshot.get("active", false))
                and str(fortress_snapshot.get("region_id", "")) == "far_lantern_chain"
                and str(fortress_snapshot.get("parent_region_id", "")) == "eclipse_fortress"
                and str(fortress_snapshot.get("route_override_id", "")) == "risk_channel"
                and str(fortress_snapshot.get("background_asset", "")).ends_with("environment_eclipse_fortress.svg")
                and (fortress_snapshot.get("enemy_behavior_ids", []) as Array).size() == 6
                and str(fortress_connection.get("choice_id", "")) == "lighthouse_survey"
                and str((fortress_snapshot.get("material_rule", {}) as Dictionary).get("hazard_id", "")) != str((fortress_snapshot.get("shadow_rule", {}) as Dictionary).get("hazard_id", ""))
            )
            if not _fortress_runtime_ok:
                _failures.append("W19 Eclipse Fortress runtime did not mount distinct route/spawn/background/phase/world-connection rules")

    var action_ms := Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W19 region-connection actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    await _finish(ash_shell, fortress_shell, action_ms)


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


func _finish(ash_shell: Node, fortress_shell: Node, action_ms: int) -> void:
    for shell: Node in [ash_shell, fortress_shell]:
        if is_instance_valid(shell):
            shell.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save_root(ASH_ROOT)
    _clear_save_root(FORTRESS_ROOT)
    print("W19_REGION_ACTION_MS=%d" % action_ms)
    print("W19_PARENT_REGIONS=2")
    print("W19_ROUTE_PROFILES=2")
    print("W19_ENEMY_BEHAVIOR_DEFS=12")
    print("W19_WORLD_CONNECTIONS=2")
    if _ash_runtime_ok:
        print("W19_ASH_RAILWAY_RUNTIME=PASS")
    if _ash_objective_ok:
        print("W19_ASH_OBJECTIVE=PASS")
    if _ash_checkpoint_ok:
        print("W19_INHERITED_CHECKPOINT=PASS")
    if _fortress_runtime_ok:
        print("W19_ECLIPSE_FORTRESS_RUNTIME=PASS")
    if _failures.is_empty():
        print("W19_REGION_CONNECTIONS=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W19_FAIL: %s" % failure)
    printerr("W19_REGION_CONNECTIONS=FAIL")
    quit(1)


func _clear_save_root(save_root: String) -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, save_root)
