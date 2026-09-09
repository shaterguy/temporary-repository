class_name CampaignRuntime
extends RefCounted

const SaveStoreScript = preload("res://game/core/save_store.gd")
const WorldCampaignModelScript = preload("res://game/world/world_campaign_model.gd")
const DisclosedDoctrineModelScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")

const CHECKPOINT_INTERVAL_SECONDS: float = 15.0

var world = WorldCampaignModelScript.new()
var active_slot: int = -1
var sequence: int = 0
var save_root: String = SaveStoreScript.SAVE_ROOT
var loaded: bool = false
var last_save_status: String = "NOT_LOADED"


func _init(root: String = SaveStoreScript.SAVE_ROOT) -> void:
    save_root = root


func slot_metadata_all() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for slot in range(SaveStoreScript.SLOT_COUNT):
        result.append(SaveStoreScript.slot_metadata(slot, save_root))
    return result


func start_new(slot: int, campaign_seed: int, overwrite: bool = false) -> Dictionary:
    if not _valid_slot(slot):
        return {"ok": false, "status": "INVALID_SLOT"}
    var metadata: Dictionary = SaveStoreScript.slot_metadata(slot, save_root)
    if bool(metadata.get("occupied", false)) and not overwrite:
        return {"ok": false, "status": "SLOT_OCCUPIED"}
    if overwrite:
        SaveStoreScript.clear_slot(slot, save_root)

    world.reset(campaign_seed)
    active_slot = slot
    sequence = 0
    loaded = true
    var save_result: Dictionary = _write_candidate(world, {}, "", "new_game")
    if not bool(save_result.get("ok", false)):
        loaded = false
        active_slot = -1
        sequence = 0
        return save_result
    return {
        "ok": true,
        "status": "NEW_GAME",
        "slot": active_slot,
        "sequence": sequence,
        "state": world.state,
    }


func load_slot(slot: int) -> Dictionary:
    if not _valid_slot(slot):
        return {"ok": false, "status": "INVALID_SLOT"}
    var read_result: Dictionary = SaveStoreScript.read_slot(slot, save_root)
    if not bool(read_result.get("ok", false)):
        return {
            "ok": false,
            "status": str(read_result.get("status", "NO_VALID_SAVE")),
            "slot": slot,
        }
    var envelope: Dictionary = read_result.get("envelope", {})
    var payload: Dictionary = envelope.get("payload", {})
    var restored: bool = world.restore_save_payload(payload)
    var legacy_payload: bool = false
    if not restored:
        legacy_payload = world.restore_snapshot(payload)
        restored = legacy_payload
    if not restored:
        return {"ok": false, "status": "PAYLOAD_RESTORE_FAILED", "slot": slot}

    active_slot = slot
    sequence = int(envelope.get("sequence", 0))
    loaded = true
    last_save_status = str(read_result.get("status", "PRIMARY"))
    return {
        "ok": true,
        "status": "LOADED_LEGACY" if legacy_payload else last_save_status,
        "slot": active_slot,
        "sequence": sequence,
        "state": world.state,
        "resume": world.resume_payload(),
    }


func begin_expedition(choice_id: String) -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED"}
    var candidate = WorldCampaignModelScript.new()
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


func current_story_event() -> Dictionary:
    return world.pending_story_event()


func resolve_story_event(option_index: int) -> Dictionary:
    if not loaded:
        return {"ok": false, "status": "NOT_LOADED"}
    if not world.has_pending_story_event():
        return {"ok": false, "status": "NO_PENDING_EVENT"}
    var candidate = WorldCampaignModelScript.new()
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


func checkpoint(reason: String, runtime_state: Dictionary) -> Dictionary:
    if not loaded or not _valid_slot(active_slot):
        return {"ok": false, "status": "NOT_LOADED"}
    if not _is_json_safe(runtime_state):
        return {"ok": false, "status": "RUNTIME_STATE_NOT_JSON_SAFE"}
    var before: Dictionary = world.snapshot()
    if world.state == WorldCampaignModelScript.STATE_EXPEDITION:
        if not world.suspend_current_expedition(runtime_state):
            return {"ok": false, "status": "SUSPEND_FAILED"}
    var result: Dictionary = _write_candidate(world, runtime_state, "", reason)
    if not bool(result.get("ok", false)):
        world.restore_snapshot(before)
    return result


func settle_current(
    outcome: String,
    observation_summary: Dictionary,
    tactical_echo_record: Dictionary
) -> Dictionary:
    if not loaded or world.state != WorldCampaignModelScript.STATE_EXPEDITION:
        return {"ok": false, "status": "NO_ACTIVE_EXPEDITION"}
    if outcome != "success" and outcome != "failed":
        return {"ok": false, "status": "INVALID_OUTCOME"}
    if not _is_json_safe(observation_summary) or not _is_json_safe(tactical_echo_record):
        return {"ok": false, "status": "CROSS_RUN_STATE_NOT_JSON_SAFE"}

    var candidate = WorldCampaignModelScript.new()
    if not candidate.restore_snapshot(world.snapshot()):
        return {"ok": false, "status": "CANDIDATE_RESTORE_FAILED"}
    var expedition_id: String = str(candidate.active_expedition_id)
    if expedition_id.is_empty():
        return {"ok": false, "status": "MISSING_EXPEDITION_ID"}
    var settlement_id: String = "settlement:%s" % expedition_id

    var summary: Dictionary = observation_summary.duplicate(true)
    var previous_summary: Dictionary = candidate.cross_run_state.get(
        "doctrine_observation_summary",
        {}
    )
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

    var next_plan: Dictionary = DisclosedDoctrineModelScript.select_plan(
        summary,
        candidate.campaign_seed,
        candidate.segment_index
    )
    var persisted_plan: Dictionary = DisclosedDoctrineModelScript.snapshot_plan(next_plan)
    if persisted_plan.is_empty():
        return {"ok": false, "status": "DOCTRINE_PLAN_SNAPSHOT_FAILED"}
    candidate.set_cross_run_state(tactical_echo_record, summary, persisted_plan)

    var save_result: Dictionary = _write_candidate(
        candidate,
        {},
        settlement_id,
        "settlement_%s" % outcome
    )
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


func current_doctrine_plan() -> Dictionary:
    var stored: Variant = world.cross_run_state.get("doctrine_plan", {})
    if not stored is Dictionary or stored.is_empty():
        return DisclosedDoctrineModelScript.neutral_plan(world.segment_index)
    var stored_plan: Dictionary = stored
    if stored_plan.has("checksum"):
        return DisclosedDoctrineModelScript.restore_plan(stored_plan)
    if DisclosedDoctrineModelScript.validate_plan(stored_plan):
        return stored_plan.duplicate(true)
    return DisclosedDoctrineModelScript.neutral_plan(world.segment_index, "invalid_saved_plan")


func current_echo_record() -> Dictionary:
    var value: Variant = world.cross_run_state.get("tactical_echo_record", {})
    if value is Dictionary:
        return value.duplicate(true)
    return {}


func current_observation_summary() -> Dictionary:
    var value: Variant = world.cross_run_state.get("doctrine_observation_summary", {})
    if value is Dictionary:
        return value.duplicate(true)
    return {}


func _write_candidate(
    candidate,
    runtime_state: Dictionary,
    settlement_id: String,
    reason: String
) -> Dictionary:
    if not _valid_slot(active_slot):
        return {"ok": false, "status": "INVALID_ACTIVE_SLOT"}
    var payload: Dictionary = candidate.make_save_payload(
        {},
        {
            "last_checkpoint_reason": reason,
            "runtime_schema": str(runtime_state.get("schema", "")),
        }
    )
    var next_sequence: int = sequence + 1
    var envelope: Dictionary = SaveStoreScript.make_envelope(payload, next_sequence, settlement_id)
    if not _is_json_safe(envelope):
        return {"ok": false, "status": "SAVE_PAYLOAD_NOT_JSON_SAFE"}
    var write_result: Dictionary = SaveStoreScript.write_slot(active_slot, envelope, save_root)
    last_save_status = str(write_result.get("status", "UNKNOWN"))
    if bool(write_result.get("ok", false)):
        sequence = int(write_result.get("sequence", next_sequence))
    var result: Dictionary = write_result.duplicate(true)
    result["slot"] = active_slot
    result["reason"] = reason
    return result


static func _valid_slot(slot: int) -> bool:
    return slot >= 0 and slot < SaveStoreScript.SLOT_COUNT


static func _is_json_safe(value: Variant) -> bool:
    match typeof(value):
        TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
            return true
        TYPE_ARRAY:
            for item in value:
                if not _is_json_safe(item):
                    return false
            return true
        TYPE_DICTIONARY:
            for key in value.keys():
                if typeof(key) != TYPE_STRING or not _is_json_safe(value[key]):
                    return false
            return true
        _:
            return false
