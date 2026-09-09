extends RefCounted

const DoctrineModelScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var low_sample := DoctrineModelScript.select_plan({
        "total_actions": 6,
        "ranged_actions": 5,
        "clustered_actions": 1,
        "failure_streak": 0,
    }, 20260909, 2)
    if bool(low_sample.get("active", true)) or str(low_sample.get("doctrine_id", "")) != "none":
        failures.append("low-sample observation created a major enemy doctrine")

    var ranged_summary := {
        "total_actions": 40,
        "ranged_actions": 31,
        "clustered_actions": 9,
        "failure_streak": 0,
    }
    var ranged_plan := DoctrineModelScript.select_plan(ranged_summary, 424242, 3)
    if str(ranged_plan.get("doctrine_id", "")) != "cover_advance":
        failures.append("ranged-dominant stored observation did not select cover advance")
    if not DoctrineModelScript.validate_plan(ranged_plan):
        failures.append("selected ranged doctrine failed its public plan contract")
    if float(ranged_plan.get("response_cap", 1.0)) > 0.3001:
        failures.append("enemy response formation exceeded the disclosed 30 percent cap")
    if ranged_plan.has("health_multiplier") or ranged_plan.has("damage_multiplier"):
        failures.append("enemy doctrine smuggled in a universal stat multiplier")
    if not _has_system_counterplay(ranged_plan):
        failures.append("enemy doctrine did not preserve at least two system-level counterplay paths")

    var retry_plan := DoctrineModelScript.select_plan(ranged_summary, 424242, 3)
    if (
        str(retry_plan.get("doctrine_id", "")) != str(ranged_plan.get("doctrine_id", ""))
        or int(retry_plan.get("source_summary_hash", -1)) != int(ranged_plan.get("source_summary_hash", -2))
        or int(retry_plan.get("selection_seed", -1)) != int(ranged_plan.get("selection_seed", -2))
    ):
        failures.append("same stored summary and seed did not reproduce the same doctrine")

    var failure_summary := ranged_summary.duplicate(true)
    failure_summary["failure_streak"] = 3
    var failure_plan := DoctrineModelScript.select_plan(failure_summary, 424242, 3)
    if float(failure_plan.get("response_cap", 1.0)) > 0.2001:
        failures.append("repeated-failure relief did not reduce the adaptive response cap")
    if not bool(failure_plan.get("beginner_relief", false)):
        failures.append("repeated-failure relief was not disclosed on the doctrine plan")

    var clustered_plan := DoctrineModelScript.select_plan({
        "total_actions": 40,
        "ranged_actions": 8,
        "clustered_actions": 32,
        "failure_streak": 0,
    }, 424242, 3)
    if str(clustered_plan.get("doctrine_id", "")) != "dispersed_ambush":
        failures.append("cluster-dominant stored observation did not select dispersed ambush")

    var snapshot := DoctrineModelScript.snapshot_plan(ranged_plan)
    var restored := DoctrineModelScript.restore_plan(snapshot)
    if str(restored.get("restore_status", "")) != "valid" or not bool(restored.get("active", false)):
        failures.append("valid doctrine snapshot did not restore as the same active plan")
    var tampered := snapshot.duplicate(true)
    tampered["response_cap"] = 0.80
    var rejected := DoctrineModelScript.restore_plan(tampered)
    if (
        str(rejected.get("restore_status", "")) != "tamper_rejected"
        or bool(rejected.get("active", true))
    ):
        failures.append("tampered doctrine snapshot was not rejected to a neutral plan")

    var origin := Vector2(160.0, 220.0)
    var director = SpawnDirectorScript.new()
    director.reset(777)
    director.set_route_context(Vector2.RIGHT, 2)
    if not director.configure_doctrine(ranged_plan):
        failures.append("spawn director rejected a valid disclosed doctrine")
    var early_events := director.step(SpawnDirectorScript.DOCTRINE_WARNING_TIME, origin)
    var warning := _first_event(early_events, "doctrine_warning")
    if warning.is_empty():
        failures.append("active doctrine did not emit a combat prewarning")
    elif (
        str(warning.get("doctrine_id", "")) != "cover_advance"
        or not _has_counterplay_array(warning.get("counterplay", []))
    ):
        failures.append("combat doctrine warning did not match its disclosed plan")

    var battle_events := director.step(30.0, origin)
    var regular_spawns := 0
    var response_spawns := 0
    var first_response: Dictionary = {}
    for event in battle_events:
        if str(event.get("type", "")) != "spawn" or str(event.get("archetype", "")) == "boss":
            continue
        regular_spawns += 1
        if bool(event.get("doctrine_response", false)):
            response_spawns += 1
            if first_response.is_empty():
                first_response = event
    if regular_spawns <= 0 or response_spawns <= 0:
        failures.append("disclosed doctrine did not reach the actual spawned composition")
    elif float(response_spawns) / float(regular_spawns) > float(ranged_plan.get("response_cap", 0.0)) + 0.0001:
        failures.append("actual doctrine response formation exceeded its disclosed cap")
    if not first_response.is_empty():
        if (
            str(first_response.get("formation", "")) != "cover_columns"
            or str(first_response.get("archetype", "")) != "runner"
        ):
            failures.append("cover doctrine did not alter the tagged response formation as disclosed")
        var encounter = SwarmEncounterScript.new()
        encounter._consume_director_event(first_response)
        var response_states := encounter._pool.active_states()
        if response_states.size() != 1 or int(response_states[0].get("max_health", 0)) != 32:
            failures.append("doctrine response changed runner health instead of only composition/formation")
        encounter.free()

    var mirror = SpawnDirectorScript.new()
    mirror.reset(777)
    mirror.set_route_context(Vector2.RIGHT, 2)
    mirror.configure_doctrine(ranged_plan)
    mirror.step(SpawnDirectorScript.DOCTRINE_WARNING_TIME, origin)
    var mirror_events := mirror.step(30.0, origin)
    var responses_a := _response_spawns(battle_events)
    var responses_b := _response_spawns(mirror_events)
    if responses_a.size() != responses_b.size():
        failures.append("same-seed retry changed the number of doctrine response spawns")
    else:
        for index in responses_a.size():
            var left: Dictionary = responses_a[index]
            var right: Dictionary = responses_b[index]
            var left_position: Vector2 = left.get("position", Vector2.ZERO)
            var right_position: Vector2 = right.get("position", Vector2.ZERO)
            if (
                str(left.get("spawn_id", "")) != str(right.get("spawn_id", ""))
                or not left_position.is_equal_approx(right_position)
            ):
                failures.append("same-seed retry changed doctrine formation placement")
                break

    return failures


static func _has_system_counterplay(plan: Dictionary) -> bool:
    return _has_counterplay_array(plan.get("counterplay", []))


static func _has_counterplay_array(value) -> bool:
    if not value is Array:
        return false
    var valid := 0
    for counter in value:
        if str(counter) in ["route_bypass", "light_circuit", "phase_shift"]:
            valid += 1
    return valid >= 2


static func _first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) == event_type:
            return event
    return {}


static func _response_spawns(events: Array[Dictionary]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for event in events:
        if str(event.get("type", "")) == "spawn" and bool(event.get("doctrine_response", false)):
            result.append(event)
    return result
