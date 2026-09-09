extends RefCounted

const BossCatalogScript = preload("res://game/data/boss_catalog.gd")
const BossEncounterModelScript = preload("res://game/combat/boss_encounter_model.gd")
const RegionSpawnDirectorScript = preload("res://game/combat/region_spawn_director.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var counts := BossCatalogScript.catalog_counts()
    if int(counts.get("bosses", 0)) != 10:
        failures.append("W20 catalog does not expose exactly 10 bosses")
    if int(counts.get("parent_regions", 0)) != 5:
        failures.append("W20 catalog does not expose exactly five parent regions")
    if int(counts.get("bosses_per_region", 0)) != 2:
        failures.append("W20 catalog does not expose two bosses per parent region")
    if int(counts.get("distinct_pattern_shapes", 0)) != 10:
        failures.append("W20 boss pattern families are not ten distinct shapes")

    var seen_ids: Array[String] = []
    var seen_signatures: Array[String] = []
    var seen_rewards: Array[String] = []
    var seen_unlocks: Array[String] = []
    for parent_region_id in BossCatalogScript.parent_region_ids():
        if BossCatalogScript.bosses_for_parent(parent_region_id).size() != 2:
            failures.append("parent region %s does not own exactly two bosses" % parent_region_id)

    for profile in BossCatalogScript.all_profiles():
        var boss_id := str(profile.get("boss_id", ""))
        if not BossCatalogScript.validate_profile(profile):
            failures.append("boss profile %s failed schema validation" % boss_id)
            continue
        if seen_ids.has(boss_id):
            failures.append("duplicate boss id %s" % boss_id)
        seen_ids.append(boss_id)
        var signature := BossCatalogScript.profile_signature(profile)
        if seen_signatures.has(signature):
            failures.append("boss %s reused an existing pattern/phase signature" % boss_id)
        seen_signatures.append(signature)
        var reward_id := str(profile.get("reward_id", ""))
        var unlock_id := str(profile.get("unlock_id", ""))
        if seen_rewards.has(reward_id) or seen_unlocks.has(unlock_id):
            failures.append("boss %s reused a reward or unlock identity" % boss_id)
        seen_rewards.append(reward_id)
        seen_unlocks.append(unlock_id)

        var model = BossEncounterModelScript.new()
        if not model.configure(profile):
            failures.append("boss model rejected valid profile %s" % boss_id)
            continue
        var begin_events := model.begin(17)
        if _first_event(begin_events, "boss_intro").is_empty() or _first_event(begin_events, "boss_phase_changed").is_empty():
            failures.append("boss %s did not expose intro and phase presentation" % boss_id)
        var warning_events := model.step(0.40)
        var warning := _first_event(warning_events, "boss_telegraph")
        if warning.is_empty():
            failures.append("boss %s did not warn before its first pattern" % boss_id)
        else:
            if str(warning.get("dodge_rule", "")).is_empty():
                failures.append("boss %s warning omitted dodge guidance" % boss_id)
            var attack_events := model.step(float(warning.get("telegraph_duration", 0.8)))
            if _first_event(attack_events, "boss_attack").is_empty():
                failures.append("boss %s warning did not resolve into an attack" % boss_id)
        var max_health := int(profile.get("max_health", 1))
        var phase_events := model.apply_health(int(float(max_health) * 0.20), max_health)
        if phase_events.size() != 2 or int(model.snapshot().get("phase_index", 0)) != 2:
            failures.append("boss %s did not advance through both health-gated phase transitions" % boss_id)
        if model.defeat().size() != 1 or not model.defeat().is_empty():
            failures.append("boss %s defeat reward was not exactly-once" % boss_id)

        var director = RegionSpawnDirectorScript.new()
        director.reset(20260910)
        if not director.configure_boss_id(boss_id):
            failures.append("region director could not select boss %s" % boss_id)
            continue
        var warning_batch := director.step(
            RegionSpawnDirectorScript.BOSS_TIME - RegionSpawnDirectorScript.BOSS_WARNING_LEAD,
            Vector2.ZERO
        )
        var spawn_warning := _boss_event(warning_batch, "telegraph", boss_id)
        if spawn_warning.is_empty():
            failures.append("region director did not schedule W20 boss warning for %s" % boss_id)
            continue
        if absf(float(spawn_warning.get("telegraph_duration", 0.0)) - RegionSpawnDirectorScript.BOSS_WARNING_LEAD) > 0.001:
            failures.append("W20 boss %s changed the retained W05 boss warning lead" % boss_id)
        var spawn_batch := director.step(RegionSpawnDirectorScript.BOSS_WARNING_LEAD, Vector2.ZERO)
        if _boss_event(spawn_batch, "spawn", boss_id).is_empty():
            failures.append("W20 boss %s did not resolve from warning to spawn" % boss_id)

    return failures


static func _first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) == event_type:
            return event
    return {}


static func _boss_event(events: Array[Dictionary], event_type: String, boss_id: String) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) == event_type and str(event.get("boss_id", "")) == boss_id:
            return event
    return {}
