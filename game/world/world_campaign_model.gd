class_name WorldCampaignModel
extends RefCounted

const SCHEMA: String = "lanternfall-world-v1"
const LEGACY_SCHEMA: String = "lanternfall-world-v0"
const PAYLOAD_SCHEMA: String = "lanternfall-save-payload-v1"
const STATE_HUB: String = "HUB"
const STATE_EXPEDITION: String = "EXPEDITION"
const STATE_POST_FINAL: String = "POST_FINAL"
const CAMPAIGN_SEGMENTS: int = 3
const MAX_SETTLEMENT_IDS: int = 128
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
    if state != STATE_HUB and state != STATE_POST_FINAL:
        return {"ok": false, "status": "NOT_IN_HUB"}
    if not active_choice_id.is_empty():
        if active_choice_id == choice_id:
            return {"ok": true, "status": "ALREADY_SELECTED", "context": expedition_context()}
        return {"ok": false, "status": "CHOICE_ALREADY_LOCKED"}
    var config := _choice_config(choice_id)
    if config.is_empty() or not _choice_available_for_stage(config):
        return {"ok": false, "status": "INVALID_CHOICE"}
    active_choice_id = choice_id
    active_region_id = str(config.get("next_region", ""))
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
    return {
        "expedition_id": active_expedition_id,
        "choice_id": active_choice_id,
        "region_id": active_region_id,
        "route_id": str(config.get("route_id", "risk_channel")),
        "support_id": str(config.get("support_id", "")),
        "shop_modifier": str(config.get("shop_modifier", "standard")),
        "threat_route": str(config.get("threat_route", "standard")),
        "horizontal_unlock": str(config.get("horizontal_unlock", "")),
        "region_tension": region_tension,
        "recovery_assist": mini(failure_count, 3),
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
    suspended_expedition = {}
    state = STATE_POST_FINAL if segment_index >= CAMPAIGN_SEGMENTS else STATE_HUB

    return {
        "ok": true,
        "status": "SETTLED_SUCCESS" if outcome == "success" else "SETTLED_FAILED_RECOVERABLE",
        "applied": true,
        "choice_id": settled_choice,
        "region_id": settled_region,
        "segment_before": before_segment,
        "segment_index": segment_index,
        "salvage_delta": salvage - before_salvage,
        "salvage": salvage,
        "campaign_complete": is_campaign_complete(),
        "progress_path_available": has_progress_path(),
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
    if not access_rights.has("ark_berth"):
        access_rights.append("ark_berth")
    if state == STATE_EXPEDITION and active_expedition_id.is_empty():
        return false
    return true


static func migrate_snapshot(snapshot_state: Dictionary) -> Dictionary:
    var schema := str(snapshot_state.get("schema", ""))
    if schema == SCHEMA:
        return snapshot_state.duplicate(true)
    if schema != LEGACY_SCHEMA:
        return {}
    var migrated := {
        "schema": SCHEMA,
        "campaign_seed": maxi(1, absi(int(snapshot_state.get("seed", 1)))),
        "segment_index": clampi(int(snapshot_state.get("chapter", 0)), 0, CAMPAIGN_SEGMENTS),
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
    if int(migrated.get("segment_index", 0)) >= CAMPAIGN_SEGMENTS:
        migrated["state"] = STATE_POST_FINAL
    var migrated_access: Array[String] = migrated.get("access_rights", [])
    if not migrated_access.has("ark_berth"):
        migrated_access.append("ark_berth")
        migrated["access_rights"] = migrated_access
    return migrated


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
    return []


func _choice_available_for_stage(config: Dictionary) -> bool:
    var config_stage := int(config.get("stage", -99))
    if segment_index >= CAMPAIGN_SEGMENTS:
        return config_stage == -1
    return config_stage == segment_index


func _choice_config(choice_id: String) -> Dictionary:
    match choice_id:
        "rescue_dockhands":
            return _config(0, choice_id, "saltglass_reach", "supply_causeway", "dockhands", "refit_discount", "raider_pressure", "field_refit", "harbor_key", "residents", 4, 12)
        "restore_lighthouse":
            return _config(0, choice_id, "stormglass_channel", "risk_channel", "beacon_watch", "phase_stock", "shade_pressure", "phase_anchor", "beacon_key", "lighthouse", 1, 16)
        "preserve_smuggler_route":
            return _config(1, choice_id, "brine_veins", "supply_causeway", "route_guides", "salvage_exchange", "flank_pressure", "route_feint", "brine_pass", "route", 1, 14)
        "stabilize_beacon_grid":
            return _config(1, choice_id, "blackglass_spires", "risk_channel", "lampwrights", "circuit_stock", "doctrine_pressure", "circuit_overcharge", "grid_access", "lighthouse", 1, 18)
        "evacuate_archive":
            return _config(2, choice_id, "drowned_archive", "supply_causeway", "archivists", "echo_catalog", "pursuit_pressure", "echo_archive", "archive_access", "residents", 5, 20)
        "seal_storm_channel":
            return _config(2, choice_id, "storm_crown", "risk_channel", "stormwardens", "weapon_exchange", "boss_pressure", "storm_gate", "crown_access", "route", 1, 24)
        "deep_rescue_patrol":
            return _config(-1, choice_id, "afterglow_frontier", "supply_causeway", "veteran_rescuers", "legacy_exchange", "frontier_pressure", "rescue_network", "post_final_patrol", "residents", 2, 18)
        "lighthouse_survey":
            return _config(-1, choice_id, "far_lantern_chain", "risk_channel", "survey_fleet", "rare_circuit_stock", "anomaly_pressure", "survey_beacon", "post_final_survey", "lighthouse", 1, 22)
    return {}


func _config(
    stage: int,
    choice_id: String,
    next_region: String,
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
