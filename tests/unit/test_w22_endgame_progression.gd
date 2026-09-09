extends RefCounted

const EndgameScript = preload("res://game/world/endgame_progression_model.gd")
const WorldScript = preload("res://game/world/world_campaign_model_w22.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    _verify_manifest_and_horizontal_policy(failures)
    _verify_post_final_variant_retry_and_idempotency(failures)
    _verify_save_compatibility(failures)
    _verify_authored_challenge_completion(failures)
    return failures


static func _verify_manifest_and_horizontal_policy(failures: Array[String]) -> void:
    var manifest := EndgameScript.manifest_snapshot()
    if int(manifest.get("variant_profile_count", 0)) != 4:
        failures.append("W22 endgame variant manifest did not expose exactly four authored profiles")
    if int(manifest.get("challenge_definition_count", 0)) != 6:
        failures.append("W22 endgame manifest did not expose exactly six authored challenges")
    if str(manifest.get("mastery_policy", "")) != "horizontal_only":
        failures.append("W22 mastery policy drifted away from horizontal-only progression")
    var state := EndgameScript.default_state()
    for forbidden_key: String in ["damage_bonus", "health_bonus", "speed_bonus", "stat_multiplier"]:
        if state.has(forbidden_key):
            failures.append("W22 horizontal mastery introduced permanent combat stat inflation: %s" % forbidden_key)


static func _verify_post_final_variant_retry_and_idempotency(failures: Array[String]) -> void:
    var world = WorldScript.new()
    world.reset(220922)
    world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
    world.state = WorldScript.STATE_POST_FINAL
    var started := world.begin_expedition("deep_rescue_patrol")
    if not bool(started.get("ok", false)):
        failures.append("W22 post-final variant expedition could not start")
        return
    var first_context: Dictionary = world.expedition_context()
    var first_seed := int(first_context.get("run_seed", 0))
    var first_variant := str(first_context.get("variant_id", ""))
    var first_challenge := str(first_context.get("challenge_id", ""))
    var first_expedition_id := str(first_context.get("expedition_id", ""))
    if first_seed <= 0 or first_variant.is_empty() or first_challenge.is_empty():
        failures.append("W22 post-final expedition omitted deterministic variant metadata")
        return

    var observation := _complete_observation()
    var failed := world.settle_expedition("settlement:w22-failed", "failed", observation, {}, {})
    if not bool(failed.get("ok", false)) or str(failed.get("status", "")) != "SETTLED_FAILED_RECOVERABLE":
        failures.append("W22 failed variant expedition was not recoverable")
        return
    var after_failure := world.endgame_snapshot()
    var last_failed: Dictionary = after_failure.get("last_failed_variant", {})
    if int(last_failed.get("run_seed", 0)) != first_seed or int(after_failure.get("failed_runs", 0)) != 1:
        failures.append("W22 failed run did not retain its same-seed retry record")

    var failure_snapshot := world.snapshot()
    var duplicate := world.settle_expedition("settlement:w22-failed", "failed", observation, {}, {})
    if str(duplicate.get("status", "")) != "ALREADY_APPLIED" or world.snapshot() != failure_snapshot:
        failures.append("W22 endgame progression advanced on a duplicate settlement ID")

    if world.has_pending_story_event():
        var story_result := world.resolve_pending_story_event(0)
        if not bool(story_result.get("ok", false)):
            failures.append("W22 retry fixture could not resolve the retained W21 story gate")
            return
    var retried := world.begin_retry_expedition()
    if not bool(retried.get("ok", false)):
        failures.append("W22 same-seed retry could not start after resolving the story gate")
        return
    var retry_context: Dictionary = world.expedition_context()
    if int(retry_context.get("run_seed", 0)) != first_seed:
        failures.append("W22 same-seed retry changed the actual deterministic run seed")
    if str(retry_context.get("variant_id", "")) != first_variant or str(retry_context.get("challenge_id", "")) != first_challenge:
        failures.append("W22 same-seed retry changed its authored world variant or challenge")
    if str(retry_context.get("expedition_id", "")) == first_expedition_id:
        failures.append("W22 same-seed retry reused the original expedition/settlement identity")

    var succeeded := world.settle_expedition("settlement:w22-retry-success", "success", observation, {}, {})
    if not bool(succeeded.get("ok", false)):
        failures.append("W22 same-seed retry could not settle successfully")
        return
    var summary := world.endgame_snapshot()
    if int(summary.get("successful_runs", 0)) != 1 or int(summary.get("failed_runs", 0)) != 1:
        failures.append("W22 success/failure long-run counters did not advance exactly once")
    if int(summary.get("mastery_marks", 0)) != 1:
        failures.append("W22 successful post-final run did not grant exactly one horizontal mastery mark")
    if not (summary.get("last_failed_variant", {}) as Dictionary).is_empty():
        failures.append("W22 successful retry left a stale retry seed armed")


static func _verify_save_compatibility(failures: Array[String]) -> void:
    var world = WorldScript.new()
    world.reset(220923)
    world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
    world.state = WorldScript.STATE_POST_FINAL
    if not bool(world.begin_expedition("lighthouse_survey").get("ok", false)):
        failures.append("W22 save fixture could not start")
        return
    var active_context := world.expedition_context()
    var payload := world.make_save_payload({}, {"w22_test": true})
    if str(payload.get("payload_schema", "")) != WorldScript.PAYLOAD_SCHEMA:
        failures.append("W22 changed the retained W12 save payload schema")
        return
    var restored = WorldScript.new()
    if not restored.restore_save_payload(payload):
        failures.append("W22 save payload could not restore")
        return
    var restored_context := restored.expedition_context()
    if int(restored_context.get("run_seed", 0)) != int(active_context.get("run_seed", 0)):
        failures.append("W22 active variant seed did not survive payload restore")

    var old_w21_snapshot := world.snapshot()
    old_w21_snapshot.erase("endgame_state")
    var migrated = WorldScript.new()
    if not migrated.restore_snapshot(old_w21_snapshot):
        failures.append("W22 rejected a valid W21 world snapshot without endgame_state")
    elif int(migrated.endgame_snapshot().get("mastery_marks", -1)) != 0:
        failures.append("W22 W21-compatible restore invented mastery progress")


static func _verify_authored_challenge_completion(failures: Array[String]) -> void:
    var state := EndgameScript.default_state()
    state = EndgameScript.begin_run(state, 99173, 0, 1, "challenge_fixture", "risk_channel", false)
    if state.is_empty():
        failures.append("W22 challenge fixture could not generate an authored variant")
        return
    var active := EndgameScript.active_variant(state)
    var challenge_id := str(active.get("challenge_id", ""))
    var context := {"route_id": "risk_channel"}
    if challenge_id == "supply_path":
        context["route_id"] = "supply_causeway"
    var settled := EndgameScript.settle_run(state, "success", context, _complete_observation(), "settlement:challenge")
    if settled.is_empty():
        failures.append("W22 authored challenge settlement failed")
        return
    var summary := EndgameScript.summary(settled)
    if not (summary.get("completed_challenges", []) as Array).has(challenge_id):
        failures.append("W22 generated challenge could not be completed by its disclosed condition")


static func _complete_observation() -> Dictionary:
    return {
        "total_actions": 6,
        "ranged_actions": 6,
        "clustered_actions": 3,
        "phase_count": 2,
        "circuit_activation_count": 3,
        "weapon_id": "shade_halo",
        "relic_ids": ["fixture_relic_a", "fixture_relic_b"],
    }
