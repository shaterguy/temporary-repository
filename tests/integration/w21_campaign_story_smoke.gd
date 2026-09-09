extends SceneTree

const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const WorldCampaignScript = preload("res://game/world/world_campaign_model.gd")
const StoryUnitTestScript = preload("res://tests/unit/test_w21_campaign_story.gd")
const SAVE_ROOT: String = "user://ci_w21_campaign_story"
const MAX_ACTION_MILLISECONDS: int = 4000

var _failures: Array[String] = []
var _story_unit_ok: bool = false
var _pending_save_reload_ok: bool = false
var _hub_story_choice_ok: bool = false
var _ending_reload_ok: bool = false
var _next_expedition_modifier_ok: bool = false
var _progress_marker: String = "initialize"


func _initialize() -> void:
    call_deferred("_run_story_smoke")


func _run_story_smoke() -> void:
    _clear_save_root()
    _progress("unit_contract")
    var unit_failures: Array[String] = StoryUnitTestScript.run()
    _story_unit_ok = unit_failures.is_empty()
    _failures.append_array(unit_failures)

    _progress("create_shell")
    var action_started_ms: int = Time.get_ticks_msec()
    var shell: Node = await _create_shell()
    if shell == null:
        _failures.append("W21 story main shell could not be created")
        await _finish(null, Time.get_ticks_msec() - action_started_ms)
        return

    _progress("final_branch_departure")
    var campaign: Variant = shell.get("campaign")
    campaign.world.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
    campaign.world.state = WorldCampaignScript.STATE_HUB
    shell.call("_show_hub_prompt")
    if not bool(shell.call("select_world_choice", 1)):
        _failures.append("W21 story fixture could not start Eclipse Fortress through the actual shell")
        await _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    _progress("actual_shell_settlement")
    shell.call("_settle_current", "success")
    await process_frame
    await process_frame
    campaign = shell.get("campaign")
    if not campaign.world.has_pending_story_event():
        _failures.append("W21 actual shell settlement did not persist a pending final event")
        await _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return
    var pending_id: String = str(campaign.world.pending_event_id)
    var pending_sequence: int = int(campaign.sequence)

    _progress("pending_reload")
    var pending_reload = CampaignRuntimeScript.new(SAVE_ROOT)
    var pending_loaded: Dictionary = pending_reload.load_slot(0)
    _pending_save_reload_ok = (
        bool(pending_loaded.get("ok", false))
        and pending_reload.world.pending_event_id == pending_id
        and pending_reload.world.has_pending_story_event()
        and pending_reload.world.ending_id.is_empty()
        and pending_reload.sequence == pending_sequence
    )
    if not _pending_save_reload_ok:
        _failures.append("W21 pending final story event did not survive transactional save/reload without premature ending")
        await _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    _progress("hub_story_choice")
    shell.set("campaign", pending_reload)
    shell.call("_enter_hub")
    var story_before: Dictionary = shell.call("campaign_story_snapshot")
    var pending_event: Dictionary = story_before.get("pending_event", {})
    if str(pending_event.get("event_id", "")) != pending_id or str(pending_event.get("parent_region_id", "")) != "eclipse_fortress":
        _failures.append("W21 actual hub did not surface the restored Eclipse Fortress story event")
    elif not bool(shell.call("select_world_choice", 0)):
        _failures.append("W21 actual hub could not consume story option 1")
    else:
        var story_after: Dictionary = shell.call("campaign_story_snapshot")
        var epilogue: Dictionary = story_after.get("epilogue", {})
        _hub_story_choice_ok = (
            (story_after.get("pending_event", {}) as Dictionary).is_empty()
            and int(epilogue.get("event_choice_count", 0)) == 1
            and not str(epilogue.get("ending_id", "")).is_empty()
            and pending_reload.world.state == WorldCampaignScript.STATE_POST_FINAL
        )
        if not _hub_story_choice_ok:
            _failures.append("W21 actual hub story choice did not finalize the campaign epilogue")

    _progress("ending_reload")
    var ending_id: String = str(pending_reload.world.ending_id)
    var event_sequence: int = int(pending_reload.sequence)
    var ending_reload = CampaignRuntimeScript.new(SAVE_ROOT)
    var ending_loaded: Dictionary = ending_reload.load_slot(0)
    _ending_reload_ok = (
        bool(ending_loaded.get("ok", false))
        and ending_reload.world.ending_id == ending_id
        and ending_reload.world.event_choice_history.size() == 1
        and ending_reload.world.resolved_event_ids.size() == 1
        and not ending_reload.world.next_expedition_modifier.is_empty()
        and ending_reload.sequence == event_sequence
    )
    if not _ending_reload_ok:
        _failures.append("W21 resolved ending/story consequence did not survive save/reload")
    else:
        _progress("post_final_departure")
        shell.set("campaign", ending_reload)
        shell.call("_enter_hub")
        if not bool(shell.call("select_world_choice", 0)):
            _failures.append("W21 post-final departure could not start after resolving the ending")
        else:
            var context: Dictionary = ending_reload.world.expedition_context()
            _next_expedition_modifier_ok = (
                not str(context.get("story_modifier_id", "")).is_empty()
                and not str(context.get("support_id", "")).is_empty()
                and ending_reload.world.next_expedition_modifier.is_empty()
            )
            if not _next_expedition_modifier_ok:
                _failures.append("W21 resolved story consequence did not alter the actual next expedition")

    _progress("finish")
    var action_ms: int = Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W21 campaign-story actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    await _finish(shell, action_ms)


func _create_shell() -> Node:
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        return null
    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame
    shell.set("campaign", CampaignRuntimeScript.new(SAVE_ROOT))
    shell.call("_show_slot_prompt")
    if not bool(shell.call("select_save_slot", 0)):
        shell.queue_free()
        await process_frame
        return null
    return shell


func _progress(marker: String) -> void:
    _progress_marker = marker
    print("W21_STORY_PROGRESS=%s" % marker)


func _finish(shell: Node, action_ms: int) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
    await process_frame
    await process_frame
    await process_frame
    _clear_save_root()
    print("W21_STORY_ACTION_MS=%d" % action_ms)
    if _story_unit_ok:
        print("W21_STORY_UNIT=PASS")
    if _pending_save_reload_ok:
        print("W21_PENDING_EVENT_RELOAD=PASS")
    if _hub_story_choice_ok:
        print("W21_HUB_STORY_CHOICE=PASS")
    if _ending_reload_ok:
        print("W21_ENDING_RELOAD=PASS")
    if _next_expedition_modifier_ok:
        print("W21_NEXT_EXPEDITION_MODIFIER=PASS")
    if _failures.is_empty():
        print("W21_CAMPAIGN_STORY=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W21_STORY_FAIL: %s" % failure)
    printerr("W21_CAMPAIGN_STORY=FAIL")
    quit(1)


func _clear_save_root() -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, SAVE_ROOT)
