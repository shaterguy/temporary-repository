class_name WorldCampaignModel
extends RefCounted

const CampaignStoryEventCatalogScript = preload("res://game/data/campaign_story_event_catalog.gd")

const SCHEMA: String = "lanternfall-world-v2"
const PRE_W21_SCHEMA: String = "lanternfall-world-v1"
const LEGACY_SCHEMA: String = "lanternfall-world-v0"
const PAYLOAD_SCHEMA: String = "lanternfall-save-payload-v1"
const STATE_HUB: String = "HUB"
const STATE_EXPEDITION: String = "EXPEDITION"
const STATE_POST_FINAL: String = "POST_FINAL"
const PRE_W21_CAMPAIGN_SEGMENTS: int = 3
const FINAL_BRANCH_SEGMENT: int = 3
const CAMPAIGN_SEGMENTS: int = 4
const MAX_SETTLEMENT_IDS: int = 128
const MAX_EVENT_HISTORY: int = 128
const STARTING_SALVAGE: int = 40

var campaign_seed: int = 1
var segment_index: int = 0
var post_final_cycle: int = 0
var state: String = STATE_HUB
var active_choice_id: String = ""
var active_region_id: String = ""
var active_expedition_id: String = ""
var expedition_attempt: int = 0
var salvage: int = STARTING_SALVAGE
var failure_count: int = 0
var rescued_residents: int = 0
var repaired_lighthouses: int = 0
var preserved_routes: int = 0
var tension: Dictionary = {}
var access_rights: Array[String] = []
var horizontal_unlocks: Array[String] = []
var completed_choices: Array[String] = []
var applied_settlement_ids: Array[String] = []
var suspended_expedition: Dictionary = {}
var cross_run_state: Dictionary = {}
var event_sequence: int = 0
var pending_event_id: String = ""
var pending_event_parent_region_id: String = ""
var pending_event_region_id: String = ""
var pending_event_outcome: String = ""
var resolved_event_ids: Array[String] = []
var event_choice_history: Array[Dictionary] = []
var story_flags: Array[String] = []
var next_expedition_modifier: Dictionary = {}
var active_expedition_modifier: Dictionary = {}
var ending_id: String = ""
var ending_history: Array[String] = []


func _init() -> void:
    reset(1)


func reset(seed: int = 1) -> void:
    campaign_seed = maxi(1, absi(seed))
    segment_index = 0
    post_final_cycle = 0
    state = STATE_HUB
    active_choice_id = ""
    active_region_id = ""
    active_expedition_id = ""
    expedition_attempt = 0
    salvage = STARTING_SALVAGE
    failure_count = 0
    rescued_residents = 0
    repaired_lighthouses = 0
    preserved_routes = 0
    tension = {}
    access_rights = ["ark_berth"]
    horizontal_unlocks = []
    completed_choices = []
    applied_settlement_ids = []
    suspended_expedition = {}
    cross_run_state = {
        "tactical_echo_record": {},
        "doctrine_observation_summary": {},
        "doctrine_plan": {},
    }
    event_sequence = 0
    pending_event_id = ""
    pending_event_parent_region_id = ""
    pending_event_region_id = ""
    pending_event_outcome = ""
    resolved_event_ids = []
    event_choice_history = []
    story_flags = []
    next_expedition_modifier = {}
    active_expedition_modifier = {}
    ending_id = ""
    ending_history = []


static func campaign_parent_region_ids() -> Array[String]:
    return [
        "twilight_shipyard",
        "glass_garden",
        "flooded_archive",
        "ash_railway",
        "eclipse_fortress",
    ]


func campaign_topology_snapshot() -> Dictionary:
    var active_config := _choice_config(active_choice_id)
    return {
        "schema": "lanternfall-campaign-topology-v1",
        "campaign_segments": CAMPAIGN_SEGMENTS,
        "final_branch_segment": FINAL_BRANCH_SEGMENT,
        "parent_region_ids": campaign_parent_region_ids(),
        "segment_index": segment_index,
        "state": state,
        "active_choice_id": active_choice_id,
        "active_region_id": active_region_id,
        "active_parent_region_id": str(active_config.get("parent_region_id", "")),
        "post_final": segment_index >= CAMPAIGN_SEGMENTS,
        "pending_story_event_id": pending_event_id,
        "resolved_story_event_count": resolved_event_ids.size(),
        "ending_id": ending_id,
    }


func departure_options() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if state != STATE_HUB and state != STATE_POST_FINAL:
        return result
    if not active_choice_id.is_empty():
        return result
    for choice_id in _choice_ids_for_stage():
        var config := _choice_config(choice_id)
        if not config.is_empty():
            result.append(_public_choice(config))
    return result


func begin_expedition(choice_id: String) -> Dictionary:
    if not active_choice_id.is_empty():
        if active_choice_id == choice_id:
            return {"ok": true, "status": "ALREADY_SELECTED", "context": expedition_context()}
        return {"ok": false, "status": "CHOICE_ALREADY_LOCKED"}
    if state != STATE_HUB and state != STATE_POST_FINAL:
        return {"ok": false, "status": "NOT_IN_HUB"}
    var config := _choice_config(choice_id)
    if config.is_empty() or not _choice_available_for_stage(config):
        return {"ok": false, "status": "INVALID_CHOICE"}
    active_choice_id = choice_id
    active_region_id = str(config.get("next_region", ""))
    active_expedition_modifier = next_expedition_modifier.duplicate(true)
    next_expedition_modifier = {}
    expedition_attempt += 1
    active_expedition_id = "exp-%d-%d-%d-%s" % [
        campaign_seed,
        segment_index,
        expedition_attempt,
        active_choice_id,
    ]
    state = STATE_EXPEDITION
    suspended_expedition = {}
    return {"ok": true, "status": "STARTED", "context": expedition_context()}


func expedition_context() -> Dictionary:
    if state != STATE_EXPEDITION or active_choice_id.is_empty():
        return {}
    var config := _choice_config(active_choice_id)
    if config.is_empty():
        return {}
    var region_tension := int(tension.get(active_region_id, 0))
    var support_id := str(active_expedition_modifier.get("support_id", config.get("support_id", "")))
    var shop_modifier := str(active_expedition_modifier.get("shop_modifier", config.get("shop_modifier", "standard")))
    var threat_route := str(active_expedition_modifier.get("threat_route", config.get("threat_route", "standard")))
    var recovery_delta := int(active_expedition_modifier.get("recovery_assist_delta", 0))
    return {
        "expedition_id": active_expedition_id,
        "choice_id": active_choice_id,
        "region_id": active_region_id,
        "parent_region_id": str(config.get("parent_region_id", "")),
        "route_id": str(config.get("route_id", "risk_channel")),
        "support_id": support_id,
        "shop_modifier": shop_modifier,
        "threat_route": threat_route,
        "horizontal_unlock": str(config.get("horizontal_unlock", "")),
        "region_tension": region_tension,
        "recovery_assist": clampi(mini(failure_count, 3) + recovery_delta, 0, 5),
        "story_modifier_id": str(active_expedition_modifier.get("modifier_id", "")),
        "post_final": segment_index >= CAMPAIGN_SEGMENTS,
    }


func settle_expedition(
    settlement_id: String,
    outcome: String,
    observation_summary: Dictionary = {},
    tactical_echo_record: Dictionary = {},
    doctrine_plan: Dictionary = {}
) -> Dictionary:
    if settlement_id.is_empty():
        return {"ok": false, "status": "INVALID_SETTLEMENT_ID"}
    if applied_settlement_ids.has(settlement_id):
        return {
            "ok": true,
            "status": "ALREADY_APPLIED",
            "applied": false,
            "segment_index": segment_index,
            "salvage": salvage,
        }
    if state != STATE_EXPEDITION or active_choice_id.is_empty():
        return {"ok": false, "status": "NO_ACTIVE_EXPEDITION"}
    if outcome != "success" and outcome != "failed":
        return {"ok": false, "status": "INVALID_OUTCOME"}

    var config := _choice_config(active_choice_id)
    if config.is_empty():
        return {"ok": false, "status": "INVALID_ACTIVE_CHOICE"}
    var settled_choice := active_choice_id
    var settled_region := active_region_id
    var settled_parent_region := str(config.get("parent_region_id", ""))
    var before_salvage := salvage
    var before_segment := segment_index

    if outcome == "success":
        salvage += int(config.get("salvage_reward", 0))
        _apply_success_effect(config)
        _append_unique(completed_choices, settled_choice)
        if segment_index < CAMPAIGN_SEGMENTS:
            segment_index += 1
        else:
            post_final_cycle += 1
        tension[settled_region] = maxi(0, int(tension.get(settled_region, 0)) - 1)
    else:
        salvage = maxi(0, salvage - 8)
        failure_count += 1
        tension[settled_region] = int(tension.get(settled_region, 0)) + 2

    _remember_settlement(settlement_id)
    set_cross_run_state(tactical_echo_record, observation_summary, doctrine_plan)
    active_choice_id = ""
    active_region_id = ""
    active_expedition_id = ""
    active_expedition_modifier = {}
    suspended_expedition = {}
    state = STATE_POST_FINAL if segment_index >= CAMPAIGN_SEGMENTS else STATE_HUB
    _schedule_story_event(settled_parent_region, settled_region, outcome)

    return {
        "ok": true,
        "status": "SETTLED_SUCCESS" if outcome == "success" else "SETTLED_FAILED_RECOVERABLE",
        "applied": true,
        "choice_id": settled_choice,
        "region_id": settled_region,
        "parent_region_id": settled_parent_region,
        "segment_before": before_segment,
        "segment_index": segment_index,
        "salvage_delta": salvage - before_salvage,
        "salvage": salvage,
        "campaign_complete": is_campaign_complete(),
        "progress_path_available": has_progress_path(),
        "pending_story_event_id": pending_event_id,
        "ending_id": ending_id,
    }


func has_pending_story_event() -> bool:
    return not pending_event_id.is_empty()


func pending_story_event() -> Dictionary:
    if pending_event_id.is_empty():
        return {}
    var event := CampaignStoryEventCatalogScript.event_by_id(pending_event_id)
    if event.is_empty():
        return {}
    event["source_region_id"] = pending_event_region_id
    event["source_outcome"] = pending_event_outcome
    event["sequence"] = event_sequence
    return event


func resolve_pending_story_event(option_index: int) -> Dictionary:
    if pending_event_id.is_empty():
        return {"ok": false, "status": "NO_PENDING_EVENT"}
    var event := CampaignStoryEventCatalogScript.event_by_id(pending_event_id)
    if event.is_empty():
        return {"ok": false, "status": "INVALID_PENDING_EVENT"}
    var options: Array = event.get("options", [])
    if option_index < 0 or option_index >= options.size():
        return {"ok": false, "status": "INVALID_EVENT_OPTION"}
    var option: Dictionary = options[option_index]
    var resolved_id := pending_event_id
    var resolved_parent := pending_event_parent_region_id
    var resolved_region := pending_event_region_id
    var source_outcome := pending_event_outcome
    var before_salvage := salvage

    salvage = maxi(0, salvage + int(option.get("salvage_delta", 0)))
    if not resolved_region.is_empty():
        tension[resolved_region] = maxi(0, int(tension.get(resolved_region, 0)) + int(option.get("tension_delta", 0)))
    _apply_story_world_axis(str(option.get("world_axis", "")), int(option.get("world_amount", 0)))
    _append_unique(story_flags, str(option.get("story_flag", "")))
    _append_unique(horizontal_unlocks, "event_path:%s" % str(option.get("profile_id", "")))
    _append_unique(resolved_event_ids, resolved_id)
    event_choice_history.append({
        "event_id": resolved_id,
        "option_id": str(option.get("option_id", "")),
        "profile_id": str(option.get("profile_id", "")),
        "parent_region_id": resolved_parent,
        "source_region_id": resolved_region,
        "source_outcome": source_outcome,
        "sequence": event_sequence,
    })
    while event_choice_history.size() > MAX_EVENT_HISTORY:
        event_choice_history.pop_front()
    next_expedition_modifier = option.get("next_modifier", {}).duplicate(true)

    var ending_bias := str(option.get("ending_bias", "witness"))
    pending_event_id = ""
    pending_event_parent_region_id = ""
    pending_event_region_id = ""
    pending_event_outcome = ""
    if is_campaign_complete() and ending_id.is_empty() and source_outcome == "success":
        ending_id = _ending_for_bias(ending_bias, resolved_parent)
        _append_unique(ending_history, ending_id)

    return {
        "ok": true,
        "status": "EVENT_RESOLVED",
        "event_id": resolved_id,
        "option_id": str(option.get("option_id", "")),
        "profile_id": str(option.get("profile_id", "")),
        "salvage_delta": salvage - before_salvage,
        "salvage": salvage,
        "next_modifier": next_expedition_modifier.duplicate(true),
        "ending_id": ending_id,
        "progress_path_available": has_progress_path(),
    }


func campaign_epilogue_snapshot() -> Dictionary:
    return {
        "campaign_complete": is_campaign_complete(),
        "ending_id": ending_id,
        "ending_history": ending_history.duplicate(),
        "story_flags": story_flags.duplicate(),
        "resolved_event_count": resolved_event_ids.size(),
        "event_choice_count": event_choice_history.size(),
        "rescued_residents": rescued_residents,
        "repaired_lighthouses": repaired_lighthouses,
        "preserved_routes": preserved_routes,
    }


func suspend_current_expedition(runtime_state: Dictionary) -> bool:
    if state != STATE_EXPEDITION or active_expedition_id.is_empty():
        return false
    suspended_expedition = {
        "schema": "suspended-expedition-v1",
        "expedition_id": active_expedition_id,
        "choice_id": active_choice_id,
        "region_id": active_region_id,
        "runtime_state": runtime_state.duplicate(true),
    }
    return true


func resume_payload() -> Dictionary:
    if state != STATE_EXPEDITION:
        return {}
    if str(suspended_expedition.get("expedition_id", "")) != active_expedition_id:
        return {}
    return suspended_expedition.duplicate(true)


func set_cross_run_state(
    tactical_echo_record: Dictionary,
    doctrine_observation_summary: Dictionary,
    doctrine_plan: Dictionary = {}
) -> void:
    cross_run_state = {
        "tactical_echo_record": tactical_echo_record.duplicate(true),
        "doctrine_observation_summary": doctrine_observation_summary.duplicate(true),
        "doctrine_plan": doctrine_plan.duplicate(true),
    }


func is_campaign_complete() -> bool:
    return segment_index >= CAMPAIGN_SEGMENTS


func has_progress_path() -> bool:
    if state == STATE_EXPEDITION:
        return not active_choice_id.is_empty() and not active_region_id.is_empty()
    if state == STATE_HUB or state == STATE_POST_FINAL:
        return departure_options().size() >= 2
    return false


func snapshot() -> Dictionary:
    return {
        "schema": SCHEMA,
        "campaign_seed": campaign_seed,
        "segment_index": segment_index,
        "post_final_cycle": post_final_cycle,
        "state": state,
        "active_choice_id": active_choice_id,
        "active_region_id": active_region_id,
        "active_expedition_id": active_expedition_id,
        "expedition_attempt": expedition_attempt,
        "salvage": salvage,
        "failure_count": failure_count,
        "rescued_residents": rescued_residents,
        "repaired_lighthouses": repaired_lighthouses,
        "preserved_routes": preserved_routes,
        "tension": tension.duplicate(true),
        "access_rights": access_rights.duplicate(),
        "horizontal_unlocks": horizontal_unlocks.duplicate(),
        "completed_choices": completed_choices.duplicate(),
        "applied_settlement_ids": applied_settlement_ids.duplicate(),
        "suspended_expedition": suspended_expedition.duplicate(true),
        "cross_run_state": cross_run_state.duplicate(true),
        "event_sequence": event_sequence,
        "pending_event_id": pending_event_id,
        "pending_event_parent_region_id": pending_event_parent_region_id,
        "pending_event_region_id": pending_event_region_id,
        "pending_event_outcome": pending_event_outcome,
        "resolved_event_ids": resolved_event_ids.duplicate(),
        "event_choice_history": event_choice_history.duplicate(true),
        "story_flags": story_flags.duplicate(),
        "next_expedition_modifier": next_expedition_modifier.duplicate(true),
        "active_expedition_modifier": active_expedition_modifier.duplicate(true),
        "ending_id": ending_id,
        "ending_history": ending_history.duplicate(),
    }


func make_save_payload(settings: Dictionary = {}, profile_extra: Dictionary = {}) -> Dictionary:
    var world_state := snapshot()
    world_state.erase("salvage")
    world_state.erase("failure_count")
    world_state.erase("suspended_expedition")
    world_state.erase("cross_run_state")
    var profile := profile_extra.duplicate(true)
    profile["salvage"] = salvage
    profile["failure_count"] = failure_count
    return {
        "payload_schema": PAYLOAD_SCHEMA,
        "settings": settings.duplicate(true),
        "profile": profile,
        "world": world_state,
        "suspended_expedition": suspended_expedition.duplicate(true),
        "cross_run": cross_run_state.duplicate(true),
    }


func restore_save_payload(payload: Dictionary) -> bool:
    if str(payload.get("payload_schema", "")) != PAYLOAD_SCHEMA:
        return false
    if typeof(payload.get("profile", null)) != TYPE_DICTIONARY:
        return false
    if typeof(payload.get("world", null)) != TYPE_DICTIONARY:
        return false
    if typeof(payload.get("suspended_expedition", null)) != TYPE_DICTIONARY:
        return false
    if typeof(payload.get("cross_run", null)) != TYPE_DICTIONARY:
        return false
    var profile: Dictionary = payload.get("profile", {})
    var world_state: Dictionary = payload.get("world", {}).duplicate(true)
    world_state["salvage"] = int(profile.get("salvage", STARTING_SALVAGE))
    world_state["failure_count"] = int(profile.get("failure_count", 0))
    world_state["suspended_expedition"] = payload.get("suspended_expedition", {}).duplicate(true)
    world_state["cross_run_state"] = payload.get("cross_run", {}).duplicate(true)
    return restore_snapshot(world_state)


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    var candidate := migrate_snapshot(snapshot_state)
    if candidate.is_empty() or str(candidate.get("schema", "")) != SCHEMA:
        return false
    var restored_segment := int(candidate.get("segment_index", -1))
    if restored_segment < 0 or restored_segment > CAMPAIGN_SEGMENTS:
        return false
    var restored_state := str(candidate.get("state", ""))
    if restored_state != STATE_HUB and restored_state != STATE_EXPEDITION and restored_state != STATE_POST_FINAL:
        return false
    var restored_choice := str(candidate.get("active_choice_id", ""))
    if restored_state == STATE_EXPEDITION:
        var restored_config := _choice_config(restored_choice)
        if restored_choice.is_empty() or restored_config.is_empty():
            return false
        if str(candidate.get("active_region_id", "")) != str(restored_config.get("next_region", "")):
            return false
    elif not restored_choice.is_empty():
        return false
    if restored_state == STATE_POST_FINAL and restored_segment < CAMPAIGN_SEGMENTS:
        return false
    var restored_pending_event_id := str(candidate.get("pending_event_id", ""))
    if not restored_pending_event_id.is_empty():
        var restored_event := CampaignStoryEventCatalogScript.event_by_id(restored_pending_event_id)
        if restored_event.is_empty():
            return false
        if str(restored_event.get("parent_region_id", "")) != str(candidate.get("pending_event_parent_region_id", "")):
            return false

    campaign_seed = maxi(1, absi(int(candidate.get("campaign_seed", 1))))
    segment_index = restored_segment
    post_final_cycle = maxi(0, int(candidate.get("post_final_cycle", 0)))
    state = restored_state
    active_choice_id = restored_choice
    active_region_id = str(candidate.get("active_region_id", ""))
    active_expedition_id = str(candidate.get("active_expedition_id", ""))
    expedition_attempt = maxi(0, int(candidate.get("expedition_attempt", 0)))
    salvage = maxi(0, int(candidate.get("salvage", STARTING_SALVAGE)))
    failure_count = maxi(0, int(candidate.get("failure_count", 0)))
    rescued_residents = maxi(0, int(candidate.get("rescued_residents", 0)))
    repaired_lighthouses = maxi(0, int(candidate.get("repaired_lighthouses", 0)))
    preserved_routes = maxi(0, int(candidate.get("preserved_routes", 0)))
    tension = candidate.get("tension", {}).duplicate(true)
    access_rights = _string_array(candidate.get("access_rights", []))
    horizontal_unlocks = _string_array(candidate.get("horizontal_unlocks", []))
    completed_choices = _string_array(candidate.get("completed_choices", []))
    applied_settlement_ids = _string_array(candidate.get("applied_settlement_ids", []))
    suspended_expedition = candidate.get("suspended_expedition", {}).duplicate(true)
    cross_run_state = candidate.get("cross_run_state", {}).duplicate(true)
    event_sequence = maxi(0, int(candidate.get("event_sequence", 0)))
    pending_event_id = restored_pending_event_id
    pending_event_parent_region_id = str(candidate.get("pending_event_parent_region_id", ""))
    pending_event_region_id = str(candidate.get("pending_event_region_id", ""))
    pending_event_outcome = str(candidate.get("pending_event_outcome", ""))
    resolved_event_ids = _string_array(candidate.get("resolved_event_ids", []))
    event_choice_history = _dictionary_array(candidate.get("event_choice_history", []))
    story_flags = _string_array(candidate.get("story_flags", []))
    next_expedition_modifier = candidate.get("next_expedition_modifier", {}).duplicate(true)
    active_expedition_modifier = candidate.get("active_expedition_modifier", {}).duplicate(true)
    ending_id = str(candidate.get("ending_id", ""))
    ending_history = _string_array(candidate.get("ending_history", []))
    if not access_rights.has("ark_berth"):
        access_rights.append("ark_berth")
    if state == STATE_EXPEDITION and active_expedition_id.is_empty():
        return false
    if ending_id.is_empty() and segment_index >= CAMPAIGN_SEGMENTS:
        ending_id = _legacy_ending_id()
        _append_unique(ending_history, ending_id)
    return true


static func migrate_snapshot(snapshot_state: Dictionary) -> Dictionary:
    var schema := str(snapshot_state.get("schema", ""))
    if schema == SCHEMA:
        return snapshot_state.duplicate(true)
    if schema == PRE_W21_SCHEMA:
        return _migrate_pre_w21_snapshot(snapshot_state)
    if schema != LEGACY_SCHEMA:
        return {}
    var pre_w21 := {
        "schema": PRE_W21_SCHEMA,
        "campaign_seed": maxi(1, absi(int(snapshot_state.get("seed", 1)))),
        "segment_index": clampi(int(snapshot_state.get("chapter", 0)), 0, PRE_W21_CAMPAIGN_SEGMENTS),
        "post_final_cycle": 0,
        "state": STATE_HUB,
        "active_choice_id": "",
        "active_region_id": "",
        "active_expedition_id": "",
        "expedition_attempt": maxi(0, int(snapshot_state.get("attempt", 0))),
        "salvage": maxi(0, int(snapshot_state.get("credits", STARTING_SALVAGE))),
        "failure_count": maxi(0, int(snapshot_state.get("failures", 0))),
        "rescued_residents": maxi(0, int(snapshot_state.get("rescued", 0))),
        "repaired_lighthouses": maxi(0, int(snapshot_state.get("lighthouses", 0))),
        "preserved_routes": maxi(0, int(snapshot_state.get("routes", 0))),
        "tension": snapshot_state.get("tension", {}).duplicate(true),
        "access_rights": _string_array_static(snapshot_state.get("access", ["ark_berth"])),
        "horizontal_unlocks": _string_array_static(snapshot_state.get("unlocks", [])),
        "completed_choices": [],
        "applied_settlement_ids": _string_array_static(snapshot_state.get("settlements", [])),
        "suspended_expedition": {},
        "cross_run_state": {
            "tactical_echo_record": snapshot_state.get("echo", {}).duplicate(true),
            "doctrine_observation_summary": snapshot_state.get("doctrine_observations", {}).duplicate(true),
            "doctrine_plan": snapshot_state.get("doctrine_plan", {}).duplicate(true),
        },
    }
    if int(pre_w21.get("segment_index", 0)) >= PRE_W21_CAMPAIGN_SEGMENTS:
        pre_w21["state"] = STATE_POST_FINAL
    var migrated_access: Array[String] = pre_w21.get("access_rights", [])
    if not migrated_access.has("ark_berth"):
        migrated_access.append("ark_berth")
        pre_w21["access_rights"] = migrated_access
    return _migrate_pre_w21_snapshot(pre_w21)


static func _migrate_pre_w21_snapshot(snapshot_state: Dictionary) -> Dictionary:
    var pre_w21_segment := int(snapshot_state.get("segment_index", -1))
    if pre_w21_segment < 0 or pre_w21_segment > PRE_W21_CAMPAIGN_SEGMENTS:
        return {}
    var migrated := snapshot_state.duplicate(true)
    migrated["schema"] = SCHEMA
    migrated["segment_index"] = pre_w21_segment
    if pre_w21_segment < PRE_W21_CAMPAIGN_SEGMENTS:
        return migrated

    var migrated_state := str(migrated.get("state", ""))
    if _has_pre_w21_final_success(migrated):
        migrated["segment_index"] = CAMPAIGN_SEGMENTS
        if migrated_state == STATE_HUB:
            migrated["state"] = STATE_POST_FINAL
    else:
        migrated["segment_index"] = FINAL_BRANCH_SEGMENT
        if migrated_state == STATE_POST_FINAL:
            migrated["state"] = STATE_HUB
    return migrated


static func _has_pre_w21_final_success(snapshot_state: Dictionary) -> bool:
    if int(snapshot_state.get("post_final_cycle", 0)) > 0:
        return true
    var completed := _string_array_static(snapshot_state.get("completed_choices", []))
    if completed.has("deep_rescue_patrol") or completed.has("lighthouse_survey"):
        return true
    var unlocks := _string_array_static(snapshot_state.get("horizontal_unlocks", []))
    if unlocks.has("rescue_network") or unlocks.has("survey_beacon"):
        return true
    var rights := _string_array_static(snapshot_state.get("access_rights", []))
    return rights.has("post_final_patrol") or rights.has("post_final_survey")


func _choice_ids_for_stage() -> Array[String]:
    if segment_index >= CAMPAIGN_SEGMENTS:
        return ["deep_rescue_patrol", "lighthouse_survey"]
    match segment_index:
        0:
            return ["rescue_dockhands", "restore_lighthouse"]
        1:
            return ["preserve_smuggler_route", "stabilize_beacon_grid"]
        2:
            return ["evacuate_archive", "seal_storm_channel"]
        FINAL_BRANCH_SEGMENT:
            return ["deep_rescue_patrol", "lighthouse_survey"]
    return []


func _choice_available_for_stage(config: Dictionary) -> bool:
    var config_stage := int(config.get("stage", -99))
    if config_stage == FINAL_BRANCH_SEGMENT:
        return segment_index >= FINAL_BRANCH_SEGMENT
    if segment_index >= CAMPAIGN_SEGMENTS:
        return false
    return config_stage == segment_index


func _choice_config(choice_id: String) -> Dictionary:
    match choice_id:
        "rescue_dockhands":
            return _config(0, choice_id, "saltglass_reach", "twilight_shipyard", "supply_causeway", "dockhands", "refit_discount", "raider_pressure", "field_refit", "harbor_key", "residents", 4, 12)
        "restore_lighthouse":
            return _config(0, choice_id, "stormglass_channel", "twilight_shipyard", "risk_channel", "beacon_watch", "phase_stock", "shade_pressure", "phase_anchor", "beacon_key", "lighthouse", 1, 16)
        "preserve_smuggler_route":
            return _config(1, choice_id, "brine_veins", "glass_garden", "supply_causeway", "route_guides", "salvage_exchange", "flank_pressure", "route_feint", "brine_pass", "route", 1, 14)
        "stabilize_beacon_grid":
            return _config(1, choice_id, "blackglass_spires", "glass_garden", "risk_channel", "lampwrights", "circuit_stock", "doctrine_pressure", "circuit_overcharge", "grid_access", "lighthouse", 1, 18)
        "evacuate_archive":
            return _config(2, choice_id, "drowned_archive", "flooded_archive", "supply_causeway", "archivists", "echo_catalog", "pursuit_pressure", "echo_archive", "archive_access", "residents", 5, 20)
        "seal_storm_channel":
            return _config(2, choice_id, "storm_crown", "flooded_archive", "risk_channel", "stormwardens", "weapon_exchange", "boss_pressure", "storm_gate", "crown_access", "route", 1, 24)
        "deep_rescue_patrol":
            return _config(FINAL_BRANCH_SEGMENT, choice_id, "afterglow_frontier", "ash_railway", "supply_causeway", "veteran_rescuers", "legacy_exchange", "frontier_pressure", "rescue_network", "post_final_patrol", "residents", 2, 18)
        "lighthouse_survey":
            return _config(FINAL_BRANCH_SEGMENT, choice_id, "far_lantern_chain", "eclipse_fortress", "risk_channel", "survey_fleet", "rare_circuit_stock", "anomaly_pressure", "survey_beacon", "post_final_survey", "lighthouse", 1, 22)
    return {}


func _config(
    stage: int,
    choice_id: String,
    next_region: String,
    parent_region_id: String,
    route_id: String,
    support_id: String,
    shop_modifier: String,
    threat_route: String,
    horizontal_unlock: String,
    access_right: String,
    world_axis: String,
    world_amount: int,
    salvage_reward: int
) -> Dictionary:
    return {
        "stage": stage,
        "choice_id": choice_id,
        "next_region": next_region,
        "parent_region_id": parent_region_id,
        "route_id": route_id,
        "support_id": support_id,
        "shop_modifier": shop_modifier,
        "threat_route": threat_route,
        "horizontal_unlock": horizontal_unlock,
        "access_right": access_right,
        "world_axis": world_axis,
        "world_amount": world_amount,
        "salvage_reward": salvage_reward,
    }


func _public_choice(config: Dictionary) -> Dictionary:
    return {
        "choice_id": str(config.get("choice_id", "")),
        "next_region": str(config.get("next_region", "")),
        "parent_region_id": str(config.get("parent_region_id", "")),
        "route_id": str(config.get("route_id", "")),
        "support_id": str(config.get("support_id", "")),
        "shop_modifier": str(config.get("shop_modifier", "")),
        "threat_route": str(config.get("threat_route", "")),
        "horizontal_unlock": str(config.get("horizontal_unlock", "")),
        "salvage_reward": int(config.get("salvage_reward", 0)),
    }


func _apply_success_effect(config: Dictionary) -> void:
    var amount := maxi(0, int(config.get("world_amount", 0)))
    match str(config.get("world_axis", "")):
        "residents":
            rescued_residents += amount
        "lighthouse":
            repaired_lighthouses += amount
        "route":
            preserved_routes += amount
    _append_unique(horizontal_unlocks, str(config.get("horizontal_unlock", "")))
    _append_unique(access_rights, str(config.get("access_right", "")))


func _schedule_story_event(parent_region_id: String, region_id: String, outcome: String) -> void:
    if not pending_event_id.is_empty():
        return
    var event_id: String = CampaignStoryEventCatalogScript.select_event_id(
        parent_region_id,
        outcome,
        campaign_seed,
        event_sequence,
        resolved_event_ids
    )
    if event_id.is_empty():
        return
    event_sequence += 1
    pending_event_id = event_id
    pending_event_parent_region_id = parent_region_id
    pending_event_region_id = region_id
    pending_event_outcome = outcome


func _apply_story_world_axis(world_axis: String, amount: int) -> void:
    var safe_amount := maxi(0, amount)
    match world_axis:
        "residents":
            rescued_residents += safe_amount
        "lighthouse":
            repaired_lighthouses += safe_amount
        "route":
            preserved_routes += safe_amount


func _ending_for_bias(ending_bias: String, parent_region_id: String) -> String:
    match ending_bias:
        "shelter":
            return "harbor_of_many"
        "frontier":
            return "road_beyond_eclipse"
        "signal":
            return "constellation_compact"
        "witness":
            return "archive_of_dawn"
    if parent_region_id == "ash_railway":
        return "harbor_of_many"
    if parent_region_id == "eclipse_fortress":
        return "constellation_compact"
    return "archive_of_dawn"


func _legacy_ending_id() -> String:
    if completed_choices.has("deep_rescue_patrol") or horizontal_unlocks.has("rescue_network"):
        return "harbor_of_many"
    if completed_choices.has("lighthouse_survey") or horizontal_unlocks.has("survey_beacon"):
        return "constellation_compact"
    return "archive_of_dawn"


func _remember_settlement(settlement_id: String) -> void:
    _append_unique(applied_settlement_ids, settlement_id)
    while applied_settlement_ids.size() > MAX_SETTLEMENT_IDS:
        applied_settlement_ids.pop_front()


static func _append_unique(values: Array[String], value: String) -> void:
    if value.is_empty() or values.has(value):
        return
    values.append(value)


func _string_array(source: Variant) -> Array[String]:
    return _string_array_static(source)


static func _string_array_static(source: Variant) -> Array[String]:
    var result: Array[String] = []
    if typeof(source) != TYPE_ARRAY:
        return result
    for value in source:
        var normalized := str(value)
        if not normalized.is_empty() and not result.has(normalized):
            result.append(normalized)
    return result


static func _dictionary_array(source: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if typeof(source) != TYPE_ARRAY:
        return result
    for value in source:
        if value is Dictionary:
            result.append(value.duplicate(true))
    return result
