class_name CampaignRuntimeW22
extends "res://game/world/campaign_runtime.gd"

const W22SaveStoreScript = preload("res://game/core/save_store.gd")
const W22WorldCampaignScript = preload("res://game/world/world_campaign_model_w22.gd")
const W22DoctrineScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")


func _init(root: String = W22SaveStoreScript.SAVE_ROOT) -> void:
    save_root = root
    world = W22WorldCampaignScript.new()


func begin_expedition(choice_id: String) -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED"}
    var candidate = W22WorldCampaignScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED"}
    var begin_result: Dictionary = candidate.begin_expedition(choice_id)
    if not bool(begin_result.get("ok", false)):
        return begin_result
    if not candidate.suspend_current_expedition({}):
        return {"ok": false, "status": "INITIAL_SUSPEND_FAILED"}
    var save_result: Dictionary = _write_candidate(candidate, {}, "", "departure_choice")
    if not bool(save_result.get("ok", false)):
        return save_result
    if not world.restore_snapshot(candidate.snapshot()):
        return {"ok": false, "status": "COMMITTED_STATE_RESTORE_FAILED"}
    var result: Dictionary = begin_result.duplicate(true)
    result["save_status"] = save_result.get("status", "SAVED")
    result["sequence"] = sequence
    return result


func begin_endgame_retry() -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED"}
    var candidate = W22WorldCampaignScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED"}
    var begin_result: Dictionary = candidate.begin_retry_expedition()
    if not bool(begin_result.get("ok", false)):
        return begin_result
    if not candidate.suspend_current_expedition({}):
        return {"ok": false, "status": "INITIAL_SUSPEND_FAILED"}
    var save_result: Dictionary = _write_candidate(candidate, {}, "", "same_seed_retry")
    if not bool(save_result.get("ok", false)):
        return save_result
    if not world.restore_snapshot(candidate.snapshot()):
        return {"ok": false, "status": "COMMITTED_STATE_RESTORE_FAILED"}
    var result: Dictionary = begin_result.duplicate(true)
    result["save_status"] = save_result.get("status", "SAVED")
    result["sequence"] = sequence
    return result


func resolve_story_event(option_index: int) -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED"}
    if not world.has_pending_story_event():
        return {"ok": false, "status": "NO_PENDING_EVENT"}
    var candidate = W22WorldCampaignScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED"}
    var event_result: Dictionary = candidate.resolve_pending_story_event(option_index)
    if not bool(event_result.get("ok", false)):
        return event_result
    var event_id := str(event_result.get("event_id", ""))
    var save_result: Dictionary = _write_candidate(candidate, {}, "event:%s" % event_id, "story_event_choice")
    if not bool(save_result.get("ok", false)):
        return save_result
    if not world.restore_snapshot(candidate.snapshot()):
        return {"ok": false, "status": "COMMITTED_STATE_RESTORE_FAILED"}
    var result: Dictionary = event_result.duplicate(true)
    result["save_status"] = save_result.get("status", "SAVED")
    result["sequence"] = sequence
    return result


func settle_current(
    outcome: String,
    observation_summary: Dictionary,
    tactical_echo_record: Dictionary
) -> Dictionary:
    if not loaded or world.state != W22WorldCampaignScript.STATE_EXPEDITION:
        return {"ok": false, "status": "NO_ACTIVE_EXPEDITION"}
    if outcome != "success" and outcome != "failed":
        return {"ok": false, "status": "INVALID_OUTCOME"}
    if not _is_json_safe(observation_summary) or not _is_json_safe(tactical_echo_record):
        return {"ok": false, "status": "CROSS_RUN_STATE_NOT_JSON_SAFE"}

    var candidate = W22WorldCampaignScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED"}
    var expedition_id: String = str(candidate.active_expedition_id)
    if expedition_id.is_empty():
        return {"ok": false, "status": "MISSING_EXPEDITION_ID"}
    var settlement_id: String = "settlement:%s" % expedition_id

    var summary: Dictionary = observation_summary.duplicate(true)
    var previous_summary: Dictionary = candidate.cross_run_state.get("doctrine_observation_summary", {})
    var previous_failure_streak: int = maxi(0, int(previous_summary.get("failure_streak", 0)))
    summary["failure_streak"] = previous_failure_streak + 1 if outcome == "failed" else 0

    var settlement: Dictionary = candidate.settle_expedition(
        settlement_id,
        outcome,
        summary,
        tactical_echo_record,
        {}
    )
    if not bool(settlement.get("ok", false)):
        return settlement

    var next_plan: Dictionary = W22DoctrineScript.select_plan(
        summary,
        candidate.campaign_seed,
        candidate.segment_index
    )
    var persisted_plan: Dictionary = W22DoctrineScript.snapshot_plan(next_plan)
    if persisted_plan.is_empty():
        return {"ok": false, "status": "DOCTRINE_PLAN_SNAPSHOT_FAILED"}
    candidate.set_cross_run_state(tactical_echo_record, summary, persisted_plan)

    var save_result: Dictionary = _write_candidate(candidate, {}, settlement_id, "settlement_%s" % outcome)
    if not bool(save_result.get("ok", false)):
        return save_result
    if not world.restore_snapshot(candidate.snapshot()):
        return {"ok": false, "status": "COMMITTED_STATE_RESTORE_FAILED"}

    var result: Dictionary = settlement.duplicate(true)
    result["settlement_id"] = settlement_id
    result["save_status"] = save_result.get("status", "SAVED")
    result["sequence"] = sequence
    result["next_doctrine_id"] = str(next_plan.get("doctrine_id", "none"))
    return result


func endgame_snapshot() -> Dictionary:
    if world == null or not world.has_method("endgame_snapshot"):
        return {}
    return world.call("endgame_snapshot")
