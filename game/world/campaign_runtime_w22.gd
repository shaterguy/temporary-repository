class_name CampaignRuntimeW22
extends "res://game/world/campaign_runtime.gd"

const W22SaveStoreScript = preload("res://game/core/save_store.gd")
const W22WorldCampaignScript = preload("res://game/world/world_campaign_model_w22.gd")
const W22DoctrineScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")
const W26EndgameScript = preload("res://game/world/endgame_progression_model.gd")
const W26_MAX_SALVAGE_RESERVE: int = 160
const W26_ENDGAME_RECON_COST: int = 20
const W26_ENDGAME_RECON_ID: String = "variant_recon"
const W26_RECON_SHIFT: int = 1

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
    if not _apply_pending_recon(candidate):
        return {"ok": false, "status": "ENDGAME_RECON_APPLY_FAILED"}
    begin_result["context"] = candidate.expedition_context()
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
    var deferred_modifier := candidate.next_expedition_modifier.duplicate(true)
    candidate.next_expedition_modifier = {}
    var begin_result: Dictionary = candidate.begin_retry_expedition()
    candidate.next_expedition_modifier = deferred_modifier
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
    var salvage_before := int(candidate.salvage)
    var event_result: Dictionary = candidate.resolve_pending_story_event(option_index)
    if not bool(event_result.get("ok", false)):
        return event_result
    _bound_positive_salvage(candidate, salvage_before, event_result)
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

func settle_current(outcome: String, observation_summary: Dictionary, tactical_echo_record: Dictionary) -> Dictionary:
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
    var salvage_before := int(candidate.salvage)
    var settlement: Dictionary = candidate.settle_expedition(settlement_id, outcome, summary, tactical_echo_record, {})
    if not bool(settlement.get("ok", false)):
        return settlement
    _bound_positive_salvage(candidate, salvage_before, settlement)
    var next_plan: Dictionary = W22DoctrineScript.select_plan(summary, candidate.campaign_seed, candidate.segment_index)
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

func prepare_endgame_recon() -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED", "applied": false}
    var candidate = W22WorldCampaignScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED", "applied": false}
    if candidate.state != W22WorldCampaignScript.STATE_POST_FINAL or candidate.segment_index < W22WorldCampaignScript.CAMPAIGN_SEGMENTS:
        return {"ok": false, "status": "NOT_POST_FINAL", "applied": false}
    if candidate.has_pending_story_event():
        return {"ok": false, "status": "PENDING_STORY_EVENT", "applied": false}
    if not candidate.active_choice_id.is_empty():
        return {"ok": false, "status": "CHOICE_ALREADY_LOCKED", "applied": false}
    if str(candidate.next_expedition_modifier.get("endgame_recon_id", "")) == W26_ENDGAME_RECON_ID:
        return {"ok": true, "status": "RECON_ALREADY_PREPARED", "applied": false, "cost": 0, "salvage": candidate.salvage, "sequence": sequence}
    if int(candidate.salvage) < W26_ENDGAME_RECON_COST:
        return {"ok": false, "status": "INSUFFICIENT_SALVAGE", "applied": false, "required": W26_ENDGAME_RECON_COST, "salvage": candidate.salvage}
    candidate.salvage -= W26_ENDGAME_RECON_COST
    var modifier := candidate.next_expedition_modifier.duplicate(true)
    modifier["endgame_recon_id"] = W26_ENDGAME_RECON_ID
    modifier["endgame_recon_shift"] = W26_RECON_SHIFT
    candidate.next_expedition_modifier = modifier
    var save_result: Dictionary = _write_candidate(candidate, {}, "", "endgame_recon")
    if not bool(save_result.get("ok", false)):
        return save_result
    if not world.restore_snapshot(candidate.snapshot()):
        return {"ok": false, "status": "COMMITTED_STATE_RESTORE_FAILED"}
    return {"ok": true, "status": "RECON_PREPARED", "applied": true, "cost": W26_ENDGAME_RECON_COST, "salvage": world.salvage, "reserve_cap": W26_MAX_SALVAGE_RESERVE, "save_status": save_result.get("status", "SAVED"), "sequence": sequence}

func recon_snapshot() -> Dictionary:
    if world == null:
        return {}
    var prepared := str(world.next_expedition_modifier.get("endgame_recon_id", "")) == W26_ENDGAME_RECON_ID
    return {"prepared": prepared, "cost": W26_ENDGAME_RECON_COST, "salvage": world.salvage, "reserve_cap": W26_MAX_SALVAGE_RESERVE, "can_afford": int(world.salvage) >= W26_ENDGAME_RECON_COST, "available": world.state == W22WorldCampaignScript.STATE_POST_FINAL and int(world.segment_index) >= W22WorldCampaignScript.CAMPAIGN_SEGMENTS and not world.has_pending_story_event() and world.active_choice_id.is_empty(), "policy": "bounded_reserve_horizontal_recon"}

func endgame_snapshot() -> Dictionary:
    if world == null or not world.has_method("endgame_snapshot"):
        return {}
    var result: Dictionary = world.call("endgame_snapshot")
    result["recon"] = recon_snapshot()
    return result

func _bound_positive_salvage(candidate, previous_salvage: int, result: Dictionary) -> void:
    var current := int(candidate.salvage)
    if current <= previous_salvage:
        return
    if previous_salvage >= W26_MAX_SALVAGE_RESERVE:
        candidate.salvage = previous_salvage
    elif current > W26_MAX_SALVAGE_RESERVE:
        candidate.salvage = W26_MAX_SALVAGE_RESERVE
    result["salvage"] = candidate.salvage
    result["salvage_delta"] = int(candidate.salvage) - previous_salvage
    result["salvage_reserve_cap"] = W26_MAX_SALVAGE_RESERVE
    result["salvage_capped"] = int(candidate.salvage) >= W26_MAX_SALVAGE_RESERVE

func _apply_pending_recon(candidate) -> bool:
    if str(candidate.active_expedition_modifier.get("endgame_recon_id", "")) != W26_ENDGAME_RECON_ID:
        return true
    var next := W26EndgameScript.restore_state(candidate.endgame_state)
    if next.is_empty():
        return false
    var active: Dictionary = next.get("active_variant", {})
    if active.is_empty() or not W26EndgameScript.validate_variant(active):
        return false
    var shift := maxi(1, int(candidate.active_expedition_modifier.get("endgame_recon_shift", W26_RECON_SHIFT)))
    var variant_index := W26EndgameScript.VARIANT_IDS.find(str(active.get("variant_id", "")))
    var challenge_index := W26EndgameScript.CHALLENGE_IDS.find(str(active.get("challenge_id", "")))
    if variant_index < 0 or challenge_index < 0:
        return false
    variant_index = (variant_index + shift) % W26EndgameScript.VARIANT_IDS.size()
    challenge_index = (challenge_index + shift) % W26EndgameScript.CHALLENGE_IDS.size()
    var variant_id := str(W26EndgameScript.VARIANT_IDS[variant_index])
    var profile: Dictionary = W26EndgameScript.VARIANT_PROFILES.get(variant_id, {})
    active["variant_id"] = variant_id
    active["variant_label"] = str(profile.get("label", variant_id))
    active["pressure_profile"] = str(profile.get("pressure_profile", "standard"))
    active["reward_profile"] = str(profile.get("reward_profile", "standard"))
    active["challenge_id"] = str(W26EndgameScript.CHALLENGE_IDS[challenge_index])
    active["recon_applied"] = true
    active["recon_shift"] = shift
    if not W26EndgameScript.validate_variant(active):
        return false
    next["active_variant"] = active
    candidate.endgame_state = next
    return true
