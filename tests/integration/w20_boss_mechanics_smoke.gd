extends SceneTree

const BossCatalogScript = preload("res://game/data/boss_catalog.gd")
const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const RegionSpawnDirectorScript = preload("res://game/combat/region_spawn_director.gd")
const RegionSwarmEncounterScript = preload("res://game/combat/region_swarm_encounter.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const BossUnitScript = preload("res://tests/unit/test_boss_expansion.gd")


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var started_ms := Time.get_ticks_msec()
    var failures := BossUnitScript.run()
    for failure in failures:
        printerr("W20_FAIL: %s" % failure)
    if not failures.is_empty():
        printerr("W20_BOSS_MECHANICS=FAIL")
        quit(1)
        return

    var player = SurvivorControllerScript.new()
    player.name = "W20BossSmokePlayer"
    root.add_child(player)
    player.global_position = Vector2.ZERO

    var encounter = RegionSwarmEncounterScript.new()
    encounter.name = "W20BossSmokeEncounter"
    root.add_child(encounter)
    encounter.configure_player(player)

    var glass_profile := RegionCatalogScript.profile_for_region("brine_veins")
    if glass_profile.is_empty() or not encounter.configure_region_profile(glass_profile):
        _fail_and_free("Glass Garden profile did not configure on actual encounter", encounter, player)
        return
    if not encounter.configure_boss_id("rootglass_colossus"):
        _fail_and_free("second Glass Garden boss could not be selected", encounter, player)
        return

    var director: Variant = encounter.get("_director")
    director.call("reset", 424242)
    var warning_events: Variant = director.call(
        "step",
        RegionSpawnDirectorScript.BOSS_TIME - RegionSpawnDirectorScript.BOSS_WARNING_LEAD,
        player.global_position
    )
    if warning_events is Array:
        for event in warning_events:
            if event is Dictionary and str(event.get("archetype", "")) == "boss":
                encounter.call("_consume_director_event", event)
    var spawn_events: Variant = director.call("step", RegionSpawnDirectorScript.BOSS_WARNING_LEAD, player.global_position)
    if spawn_events is Array:
        for event in spawn_events:
            if event is Dictionary and str(event.get("archetype", "")) == "boss":
                encounter.call("_consume_director_event", event)

    var runtime := encounter.boss_runtime_snapshot()
    var boss_entity_id := int(runtime.get("active_entity_id", -1))
    if boss_entity_id < 0 or str(runtime.get("profile", {}).get("boss_id", "")) != "rootglass_colossus":
        _fail_and_free("W20 boss was not mounted into the actual pooled encounter", encounter, player)
        return

    encounter.call("_physics_process", 0.40)
    var log_after_warning := encounter.boss_event_log()
    if _event_index(log_after_warning, "boss_telegraph") < 0:
        _fail_and_free("actual encounter emitted no boss attack telegraph", encounter, player)
        return
    encounter.call("_physics_process", 1.60)
    var log_after_attack := encounter.boss_event_log()
    var warning_index := _event_index(log_after_attack, "boss_telegraph")
    var attack_index := _event_index(log_after_attack, "boss_attack")
    if warning_index < 0 or attack_index <= warning_index:
        _fail_and_free("actual encounter attack did not follow its telegraph", encounter, player)
        return

    encounter.apply_target_damage(boss_entity_id, 999999)
    var phase_one: Dictionary = encounter.boss_runtime_snapshot().get("model", {})
    if int(phase_one.get("phase_index", 0)) != 1:
        _fail_and_free("first lethal burst skipped the first boss phase gate", encounter, player)
        return

    encounter.set_world_phase("shadow")
    encounter.apply_target_damage(boss_entity_id, 999999)
    var phase_two: Dictionary = encounter.boss_runtime_snapshot().get("model", {})
    if int(phase_two.get("phase_index", 0)) != 2:
        _fail_and_free("second lethal burst skipped the final boss phase gate", encounter, player)
        return

    encounter.set_world_phase("material")
    encounter.apply_target_damage(boss_entity_id, 999999)
    var rewards := encounter.claim_boss_rewards()
    if rewards.size() != 1 or str(rewards[0].get("reward_id", "")).is_empty() or str(rewards[0].get("unlock_id", "")).is_empty():
        _fail_and_free("actual boss defeat did not queue one reward/unlock", encounter, player)
        return
    if not encounter.claim_boss_rewards().is_empty():
        _fail_and_free("boss reward queue was claimable more than once", encounter, player)
        return

    print("W20_BOSS_COUNT=%d" % int(BossCatalogScript.catalog_counts().get("bosses", 0)))
    print("W20_PARENT_REGIONS=%d" % int(BossCatalogScript.catalog_counts().get("parent_regions", 0)))
    print("W20_BOSSES_PER_REGION=%d" % int(BossCatalogScript.catalog_counts().get("bosses_per_region", 0)))
    print("W20_DISTINCT_PATTERN_SHAPES=%d" % int(BossCatalogScript.catalog_counts().get("distinct_pattern_shapes", 0)))
    print("W20_RUNTIME_TELEGRAPH=PASS")
    print("W20_PHASE_TRANSITION=PASS")
    print("W20_REWARD_ONCE=PASS")
    print("W20_BOSS_MECHANICS=PASS")
    print("W20_BOSS_ACTION_MS=%d" % (Time.get_ticks_msec() - started_ms))
    encounter.free()
    player.free()
    quit(0)


func _event_index(events: Array[Dictionary], event_type: String) -> int:
    for index in events.size():
        if str(events[index].get("type", "")) == event_type:
            return index
    return -1


func _fail_and_free(message: String, encounter: Node, player: Node) -> void:
    printerr("W20_FAIL: %s" % message)
    printerr("W20_BOSS_MECHANICS=FAIL")
    encounter.free()
    player.free()
    quit(1)
