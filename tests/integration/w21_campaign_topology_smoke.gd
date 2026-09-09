extends SceneTree

const W21UnitTestScript = preload("res://tests/unit/test_w21_campaign_topology.gd")
const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const WorldCampaignScript = preload("res://game/world/world_campaign_model.gd")
const ASH_ROOT: String = "user://ci_w21_ash_final_branch"
const ECLIPSE_ROOT: String = "user://ci_w21_eclipse_final_branch"
const MAX_ACTION_MILLISECONDS: int = 4000

var _failures: Array[String] = []
var _migration_ok: bool = false
var _ash_final_branch_ok: bool = false
var _eclipse_final_branch_ok: bool = false
var _checkpoint_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_w21")


func _run_w21() -> void:
    _clear_save_root(ASH_ROOT)
    _clear_save_root(ECLIPSE_ROOT)
    var unit_failures: Array[String] = W21UnitTestScript.run()
    _failures.append_array(unit_failures)
    _migration_ok = unit_failures.is_empty()
    var action_started_ms: int = Time.get_ticks_msec()

    var ash_shell: Node = await _create_shell(ASH_ROOT)
    if ash_shell == null:
        _failures.append("W21 Ash Railway main shell could not be created")
        await _finish(null, null, Time.get_ticks_msec() - action_started_ms)
        return
    var ash_campaign: Variant = ash_shell.get("campaign")
    ash_campaign.world.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
    ash_campaign.world.state = WorldCampaignScript.STATE_HUB
    ash_shell.call("_show_hub_prompt")
    if not bool(ash_shell.call("select_world_choice", 0)):
        _failures.append("W21 Ash Railway final branch could not start through the actual shell")
    else:
        var topology: Dictionary = ash_shell.call("campaign_topology_snapshot")
        _ash_final_branch_ok = (
            int(topology.get("campaign_segments", 0)) == 4
            and (topology.get("parent_region_ids", []) as Array).size() == 5
            and int(topology.get("segment_index", -1)) == WorldCampaignScript.FINAL_BRANCH_SEGMENT
            and not bool(topology.get("post_final", true))
            and str(topology.get("active_parent_region_id", "")) == "ash_railway"
            and bool(topology.get("runtime_region_active", false))
            and str(topology.get("runtime_region_id", "")) == "afterglow_frontier"
            and str(topology.get("runtime_parent_region_id", "")) == "ash_railway"
            and str(topology.get("runtime_background_asset", "")).ends_with("environment_ash_railway.svg")
        )
        if not _ash_final_branch_ok:
            _failures.append("W21 Ash Railway final branch did not align world topology with the actual regional runtime")

        var checkpoint: Dictionary = ash_shell.call("_checkpoint_runtime", "w21_final_branch_checkpoint")
        if not bool(checkpoint.get("ok", false)):
            _failures.append("W21 final-branch checkpoint could not be persisted")
        else:
            var reloaded: Variant = CampaignRuntimeScript.new(ASH_ROOT)
            var loaded: Dictionary = reloaded.load_slot(0)
            if bool(loaded.get("ok", false)):
                var resume: Dictionary = reloaded.world.resume_payload()
                var runtime_state: Dictionary = resume.get("runtime_state", {})
                var region_state: Dictionary = runtime_state.get("w18_region", {})
                _checkpoint_ok = (
                    reloaded.world.segment_index == WorldCampaignScript.FINAL_BRANCH_SEGMENT
                    and reloaded.world.state == WorldCampaignScript.STATE_EXPEDITION
                    and str(reloaded.world.expedition_context().get("parent_region_id", "")) == "ash_railway"
                    and str(region_state.get("region_id", "")) == "afterglow_frontier"
                )
            if not _checkpoint_ok:
                _failures.append("W21 final-branch checkpoint did not retain world/region alignment after reload")

    var eclipse_shell: Node = await _create_shell(ECLIPSE_ROOT)
    if eclipse_shell == null:
        _failures.append("W21 Eclipse Fortress main shell could not be created")
    else:
        var eclipse_campaign: Variant = eclipse_shell.get("campaign")
        eclipse_campaign.world.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
        eclipse_campaign.world.state = WorldCampaignScript.STATE_HUB
        eclipse_shell.call("_show_hub_prompt")
        if not bool(eclipse_shell.call("select_world_choice", 1)):
            _failures.append("W21 Eclipse Fortress final branch could not start through the actual shell")
        else:
            var eclipse_topology: Dictionary = eclipse_shell.call("campaign_topology_snapshot")
            _eclipse_final_branch_ok = (
                not bool(eclipse_topology.get("post_final", true))
                and str(eclipse_topology.get("active_parent_region_id", "")) == "eclipse_fortress"
                and bool(eclipse_topology.get("runtime_region_active", false))
                and str(eclipse_topology.get("runtime_region_id", "")) == "far_lantern_chain"
                and str(eclipse_topology.get("runtime_parent_region_id", "")) == "eclipse_fortress"
                and str(eclipse_topology.get("runtime_background_asset", "")).ends_with("environment_eclipse_fortress.svg")
            )
            if not _eclipse_final_branch_ok:
                _failures.append("W21 Eclipse Fortress final branch did not align world topology with the actual regional runtime")

    var action_ms: int = Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W21 campaign-topology actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    await _finish(ash_shell, eclipse_shell, action_ms)


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


func _finish(ash_shell: Node, eclipse_shell: Node, action_ms: int) -> void:
    for shell: Node in [ash_shell, eclipse_shell]:
        if is_instance_valid(shell):
            shell.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save_root(ASH_ROOT)
    _clear_save_root(ECLIPSE_ROOT)
    print("W21_CAMPAIGN_ACTION_MS=%d" % action_ms)
    print("W21_CAMPAIGN_SEGMENTS=%d" % WorldCampaignScript.CAMPAIGN_SEGMENTS)
    print("W21_PARENT_REGIONS=%d" % WorldCampaignScript.campaign_parent_region_ids().size())
    if _migration_ok:
        print("W21_PRE_W21_MIGRATION=PASS")
    if _ash_final_branch_ok:
        print("W21_ASH_FINAL_BRANCH=PASS")
    if _eclipse_final_branch_ok:
        print("W21_ECLIPSE_FINAL_BRANCH=PASS")
    if _checkpoint_ok:
        print("W21_FINAL_BRANCH_CHECKPOINT=PASS")
    if _failures.is_empty():
        print("W21_CAMPAIGN_TOPOLOGY=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W21_FAIL: %s" % failure)
    printerr("W21_CAMPAIGN_TOPOLOGY=FAIL")
    quit(1)


func _clear_save_root(save_root: String) -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, save_root)
