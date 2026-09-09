class_name WorldCampaignModelW22
extends "res://game/world/world_campaign_model.gd"

const EndgameProgressionScript = preload("res://game/world/endgame_progression_model.gd")

var endgame_state: Dictionary = EndgameProgressionScript.default_state()


func reset(seed: int = 1) -> void:
    super.reset(seed)
    endgame_state = EndgameProgressionScript.default_state()


func snapshot() -> Dictionary:
    var value: Dictionary = super.snapshot()
    value["endgame_state"] = endgame_state.duplicate(true)
    return value


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    if not super.restore_snapshot(snapshot_state):
        return false
    var restored := EndgameProgressionScript.restore_state(snapshot_state.get("endgame_state", {}))
    if restored.is_empty():
        return false
    endgame_state = restored
    if state != STATE_EXPEDITION:
        endgame_state["active_variant"] = {}
    return true


func begin_expedition(choice_id: String) -> Dictionary:
    var was_post_final := segment_index >= CAMPAIGN_SEGMENTS
    var result: Dictionary = super.begin_expedition(choice_id)
    if not bool(result.get("ok", false)):
        return result
    if str(result.get("status", "")) == "STARTED" and was_post_final:
        var base_context: Dictionary = super.expedition_context()
        var next_state := EndgameProgressionScript.begin_run(
            endgame_state,
            campaign_seed,
            post_final_cycle,
            expedition_attempt,
            active_choice_id,
            str(base_context.get("route_id", "")),
            false
        )
        if next_state.is_empty():
            return {"ok": false, "status": "ENDGAME_VARIANT_START_FAILED"}
        endgame_state = next_state
    result["context"] = expedition_context()
    return result


func begin_retry_expedition() -> Dictionary:
    if state != STATE_POST_FINAL or segment_index < CAMPAIGN_SEGMENTS:
        return {"ok": false, "status": "NOT_POST_FINAL"}
    if has_pending_story_event():
        return {"ok": false, "status": "PENDING_STORY_EVENT"}
    if not active_choice_id.is_empty():
        return {"ok": false, "status": "CHOICE_ALREADY_LOCKED"}
    var failed_variant := EndgameProgressionScript.last_failed_variant(endgame_state)
    if failed_variant.is_empty():
        return {"ok": false, "status": "NO_RETRY_SEED"}
    var choice_id := str(failed_variant.get("choice_id", ""))
    var result: Dictionary = super.begin_expedition(choice_id)
    if not bool(result.get("ok", false)):
        return result
    var base_context: Dictionary = super.expedition_context()
    var next_state := EndgameProgressionScript.begin_run(
        endgame_state,
        campaign_seed,
        post_final_cycle,
        expedition_attempt,
        choice_id,
        str(base_context.get("route_id", "")),
        true
    )
    if next_state.is_empty():
        return {"ok": false, "status": "ENDGAME_RETRY_START_FAILED"}
    endgame_state = next_state
    result["status"] = "RETRY_STARTED"
    result["context"] = expedition_context()
    return result


func expedition_context() -> Dictionary:
    var context: Dictionary = super.expedition_context()
    if context.is_empty():
        return context
    var variant := EndgameProgressionScript.active_variant(endgame_state)
    if variant.is_empty():
        return context
    context["endgame_schema"] = EndgameProgressionScript.SCHEMA
    context["run_seed"] = int(variant.get("run_seed", 0))
    context["variant_id"] = str(variant.get("variant_id", ""))
    context["variant_label"] = str(variant.get("variant_label", ""))
    context["pressure_profile"] = str(variant.get("pressure_profile", "standard"))
    context["reward_profile"] = str(variant.get("reward_profile", "standard"))
    context["challenge_id"] = str(variant.get("challenge_id", ""))
    context["retry_count"] = maxi(0, int(variant.get("retry_count", 0)))
    return context


func settle_expedition(
    settlement_id: String,
    outcome: String,
    observation_summary: Dictionary = {},
    tactical_echo_record: Dictionary = {},
    doctrine_plan: Dictionary = {}
) -> Dictionary:
    var context_before: Dictionary = expedition_context()
    var endgame_before: Dictionary = endgame_state.duplicate(true)
    var result: Dictionary = super.settle_expedition(
        settlement_id,
        outcome,
        observation_summary,
        tactical_echo_record,
        doctrine_plan
    )
    if not bool(result.get("ok", false)) or not bool(result.get("applied", false)):
        return result
    if context_before.has("run_seed"):
        var next_state := EndgameProgressionScript.settle_run(
            endgame_before,
            outcome,
            context_before,
            observation_summary,
            settlement_id
        )
        if next_state.is_empty():
            return {"ok": false, "status": "ENDGAME_SETTLEMENT_FAILED"}
        endgame_state = next_state
        result["endgame"] = endgame_snapshot()
    return result


func endgame_snapshot() -> Dictionary:
    var result := EndgameProgressionScript.summary(endgame_state)
    if result.is_empty():
        return result
    result["retry_available"] = retry_available()
    return result


func retry_available() -> bool:
    return (
        state == STATE_POST_FINAL
        and segment_index >= CAMPAIGN_SEGMENTS
        and not has_pending_story_event()
        and active_choice_id.is_empty()
        and not EndgameProgressionScript.last_failed_variant(endgame_state).is_empty()
    )


static func endgame_manifest_snapshot() -> Dictionary:
    return EndgameProgressionScript.manifest_snapshot()
