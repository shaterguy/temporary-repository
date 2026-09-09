extends SceneTree

const W22UnitTestScript = preload("res://tests/unit/test_w22_endgame_progression.gd")
const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const WorldScript = preload("res://game/world/world_campaign_model_w22.gd")
const SAVE_ROOT: String = "user://ci_w22_endgame_progression"
const MAX_ACTION_MILLISECONDS: int = 4000

var _failures: Array[String] = []
var _unit_ok: bool = false
var _variant_seed_ok: bool = false
var _retry_ok: bool = false
var _reload_ok: bool = false
var _mastery_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_w22")


func _run_w22() -> void:
    _clear_save_root()
    var unit_failures: Array[String] = W22UnitTestScript.run()
    _failures.append_array(unit_failures)
    _unit_ok = unit_failures.is_empty()
    var action_started_ms := Time.get_ticks_msec()

    var shell: Node = await _create_shell()
    if shell == null:
        _failures.append("W22 main shell could not be created")
        await _finish(null, Time.get_ticks_msec() - action_started_ms)
        return
    var campaign: Variant = shell.get("campaign")
    campaign.world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
    campaign.world.state = WorldScript.STATE_POST_FINAL
    shell.call("_show_hub_prompt")

    if not bool(shell.call("select_world_choice", 0)):
        _failures.append("W22 actual shell could not start a post-final variant expedition")
    else:
        var first_context: Dictionary = campaign.world.expedition_context()
        var first_seed := int(first_context.get("run_seed", 0))
        var first_expedition_id := str(first_context.get("expedition_id", ""))
        _variant_seed_ok = (
            first_seed > 0
            and not str(first_context.get("variant_id", "")).is_empty()
            and not str(first_context.get("challenge_id", "")).is_empty()
            and int(shell.call("_expedition_seed")) == first_seed
        )
        if not _variant_seed_ok:
            _failures.append("W22 actual shell did not route the variant seed into the expedition runtime seed")
        var failed: Dictionary = campaign.settle_current("failed", shell.call("_observation_summary"), {})
        if not bool(failed.get("ok", false)):
            _failures.append("W22 runtime could not settle a failed variant expedition")
        else:
            shell.call("_enter_hub")
            if campaign.world.has_pending_story_event():
                var story_result: Dictionary = campaign.resolve_story_event(0)
                if not bool(story_result.get("ok", false)):
                    _failures.append("W22 runtime could not resolve the retained W21 story event before retry")
            shell.call("_show_hub_prompt")
            if not bool(shell.call("retry_last_endgame_seed")):
                _failures.append("W22 actual shell could not invoke same-seed retry")
            else:
                var retry_context: Dictionary = campaign.world.expedition_context()
                _retry_ok = (
                    int(retry_context.get("run_seed", 0)) == first_seed
                    and str(retry_context.get("expedition_id", "")) != first_expedition_id
                    and int(retry_context.get("retry_count", 0)) >= 1
                    and int(shell.call("_expedition_seed")) == first_seed
                )
                if not _retry_ok:
                    _failures.append("W22 actual retry did not preserve seed while issuing a fresh expedition identity")
                var success: Dictionary = campaign.settle_current("success", shell.call("_observation_summary"), {})
                if not bool(success.get("ok", false)):
                    _failures.append("W22 retry could not settle successfully")
                else:
                    shell.call("_enter_hub")
                    var endgame: Dictionary = shell.call("endgame_progression_snapshot")
                    _mastery_ok = (
                        int(endgame.get("successful_runs", 0)) == 1
                        and int(endgame.get("failed_runs", 0)) == 1
                        and int(endgame.get("mastery_marks", 0)) == 1
                        and not endgame.has("damage_bonus")
                        and not bool(endgame.get("retry_available", true))
                    )
                    if not _mastery_ok:
                        _failures.append("W22 actual runtime did not persist horizontal-only mastery after retry success")

                    var reloaded = CampaignRuntimeW22Script.new(SAVE_ROOT)
                    var loaded: Dictionary = reloaded.load_slot(0)
                    if bool(loaded.get("ok", false)):
                        var reloaded_endgame: Dictionary = reloaded.endgame_snapshot()
                        _reload_ok = (
                            int(reloaded_endgame.get("successful_runs", 0)) == 1
                            and int(reloaded_endgame.get("failed_runs", 0)) == 1
                            and int(reloaded_endgame.get("mastery_marks", 0)) == 1
                            and WorldScript.SCHEMA == "lanternfall-world-v2"
                            and WorldScript.PAYLOAD_SCHEMA == "lanternfall-save-payload-v1"
                        )
                    if not _reload_ok:
                        _failures.append("W22 long-run progression did not survive a fresh runtime reload")

    var action_ms := Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W22 actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    await _finish(shell, action_ms)


func _create_shell() -> Node:
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        return null
    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame
    shell.set("campaign", CampaignRuntimeW22Script.new(SAVE_ROOT))
    shell.call("_show_slot_prompt")
    if not bool(shell.call("select_save_slot", 0)):
        shell.queue_free()
        await process_frame
        return null
    return shell


func _finish(shell: Node, action_ms: int) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save_root()
    print("W22_ENDGAME_ACTION_MS=%d" % action_ms)
    if _unit_ok:
        print("W22_UNIT=PASS")
    if _variant_seed_ok:
        print("W22_VARIANT_SEED=PASS")
    if _retry_ok:
        print("W22_SAME_SEED_RETRY=PASS")
    if _mastery_ok:
        print("W22_MASTERY_HORIZONTAL=PASS")
    if _reload_ok:
        print("W22_SAVE_RELOAD=PASS")
    if _failures.is_empty():
        print("W22_ENDGAME_PROGRESSION=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W22_FAIL: %s" % failure)
    printerr("W22_ENDGAME_PROGRESSION=FAIL")
    quit(1)


func _clear_save_root() -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, SAVE_ROOT)
