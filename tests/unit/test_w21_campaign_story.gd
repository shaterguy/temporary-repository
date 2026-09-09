extends RefCounted

const StoryCatalogScript = preload("res://game/data/campaign_story_event_catalog.gd")
const WorldCampaignScript = preload("res://game/world/world_campaign_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    print("W21_STORY_UNIT_PROGRESS=catalog")
    _verify_catalog(failures)
    print("W21_STORY_UNIT_PROGRESS=no_repeat")
    _verify_no_repeat_selection(failures)
    print("W21_STORY_UNIT_PROGRESS=success_consequence")
    _verify_success_choice_changes_next_expedition(failures)
    print("W21_STORY_UNIT_PROGRESS=failure_recovery")
    _verify_failure_recovery_choice(failures)
    print("W21_STORY_UNIT_PROGRESS=save_restore")
    _verify_story_save_restore(failures)
    print("W21_STORY_UNIT_PROGRESS=endings")
    _verify_multiple_endings(failures)
    print("W21_STORY_UNIT_PROGRESS=complete")
    return failures


static func _verify_catalog(failures: Array[String]) -> void:
    var events: Array[Dictionary] = StoryCatalogScript.all_events()
    var counts: Dictionary = StoryCatalogScript.catalog_counts()
    if events.size() != StoryCatalogScript.EXPECTED_EVENT_COUNT or int(counts.get("events", 0)) != 40:
        failures.append("W21 story catalog did not expose exactly 40 authored events")
    if int(counts.get("options", 0)) != 80:
        failures.append("W21 story catalog did not expose two choices for every authored event")
    if int(counts.get("success_events", 0)) != 20 or int(counts.get("failed_events", 0)) != 20:
        failures.append("W21 story catalog did not balance 20 success and 20 failure-recovery events")

    var event_ids: Array[String] = []
    var option_ids: Array[String] = []
    var titles: Array[String] = []
    var ending_biases: Array[String] = []
    var parent_counts: Dictionary = counts.get("per_parent", {})
    for parent_region_id: String in StoryCatalogScript.parent_region_ids():
        if int(parent_counts.get(parent_region_id, 0)) != StoryCatalogScript.EXPECTED_EVENTS_PER_PARENT:
            failures.append("W21 parent region %s did not contain exactly eight story events" % parent_region_id)

    for event: Dictionary in events:
        var event_id := str(event.get("event_id", ""))
        var title := str(event.get("title", ""))
        if event_id.is_empty() or event_ids.has(event_id):
            failures.append("W21 story event identity was empty or duplicated: %s" % event_id)
        else:
            event_ids.append(event_id)
        if title.is_empty() or titles.has(title):
            failures.append("W21 story event title was empty or duplicated: %s" % title)
        else:
            titles.append(title)
        if str(event.get("speaker_id", "")).is_empty() or str(event.get("arc_id", "")).is_empty() or str(event.get("body", "")).is_empty():
            failures.append("W21 story event %s omitted speaker/arc/body authorship" % event_id)
        var trigger := str(event.get("trigger", ""))
        if trigger != StoryCatalogScript.TRIGGER_SUCCESS and trigger != StoryCatalogScript.TRIGGER_FAILED:
            failures.append("W21 story event %s used an unsupported trigger" % event_id)
        var options: Array = event.get("options", [])
        if options.size() != 2:
            failures.append("W21 story event %s did not expose exactly two choices" % event_id)
            continue
        for raw_option: Variant in options:
            if not raw_option is Dictionary:
                failures.append("W21 story event %s contained a non-dictionary option" % event_id)
                continue
            var option: Dictionary = raw_option
            var option_id := str(option.get("option_id", ""))
            if option_id.is_empty() or option_ids.has(option_id):
                failures.append("W21 story option identity was empty or duplicated: %s" % option_id)
            else:
                option_ids.append(option_id)
            if str(option.get("label", "")).is_empty() or str(option.get("story_flag", "")).is_empty():
                failures.append("W21 story option %s omitted a visible label or persistent story flag" % option_id)
            var modifier: Variant = option.get("next_modifier", {})
            if not modifier is Dictionary or str((modifier as Dictionary).get("modifier_id", "")).is_empty():
                failures.append("W21 story option %s omitted a next-expedition modifier" % option_id)
            if option.has("remove_access") or option.has("remove_unlock"):
                failures.append("W21 story option %s could delete core access and create a dead end" % option_id)
            var ending_bias := str(option.get("ending_bias", ""))
            if not ending_bias.is_empty() and not ending_biases.has(ending_bias):
                ending_biases.append(ending_bias)
    ending_biases.sort()
    if ending_biases != ["frontier", "shelter", "signal", "witness"]:
        failures.append("W21 story catalog did not expose all four persistent ending biases")


static func _verify_no_repeat_selection(failures: Array[String]) -> void:
    for parent_region_id: String in StoryCatalogScript.parent_region_ids():
        for trigger: String in [StoryCatalogScript.TRIGGER_SUCCESS, StoryCatalogScript.TRIGGER_FAILED]:
            var resolved: Array[String] = []
            for sequence: int in range(4):
                var selected: String = StoryCatalogScript.select_event_id(parent_region_id, trigger, 210930, sequence, resolved)
                if selected.is_empty() or resolved.has(selected):
                    failures.append("W21 story selector repeated an event before exhausting %s/%s" % [parent_region_id, trigger])
                    break
                resolved.append(selected)
            if resolved.size() != 4:
                failures.append("W21 story selector did not expose four distinct %s events for %s" % [trigger, parent_region_id])


static func _verify_success_choice_changes_next_expedition(failures: Array[String]) -> void:
    var model = WorldCampaignScript.new()
    model.reset(210931)
    var start := model.begin_expedition("rescue_dockhands")
    if not bool(start.get("ok", false)):
        failures.append("W21 success-story fixture could not begin the first expedition")
        return
    var settled := model.settle_expedition("w21-story-success", "success")
    if not bool(settled.get("ok", false)) or not model.has_pending_story_event():
        failures.append("W21 successful settlement did not schedule a story choice")
        return
    var pending: Dictionary = model.pending_story_event()
    if str(pending.get("parent_region_id", "")) != "twilight_shipyard" or str(pending.get("source_outcome", "")) != "success":
        failures.append("W21 successful story event lost its source region/outcome")
    var resolved := model.resolve_pending_story_event(0)
    if not bool(resolved.get("ok", false)) or model.has_pending_story_event():
        failures.append("W21 successful story choice could not resolve exactly once")
        return
    var modifier: Dictionary = resolved.get("next_modifier", {})
    if str(modifier.get("modifier_id", "")).is_empty() or model.story_flags.is_empty() or model.resolved_event_ids.size() != 1:
        failures.append("W21 successful story choice did not persist its horizontal consequence")
    var next_options := model.departure_options()
    if next_options.size() != 2:
        failures.append("W21 story resolution removed the next campaign departure pair")
        return
    var next_start := model.begin_expedition(str(next_options[0].get("choice_id", "")))
    var context: Dictionary = next_start.get("context", {})
    if not bool(next_start.get("ok", false)) or str(context.get("story_modifier_id", "")).is_empty():
        failures.append("W21 story choice did not alter the actual next expedition context")
    if str(context.get("support_id", "")) != str(modifier.get("support_id", "")):
        failures.append("W21 story support consequence was descriptive only and did not reach expedition runtime")
    if not model.next_expedition_modifier.is_empty():
        failures.append("W21 one-run story modifier was not consumed when the next expedition began")


static func _verify_failure_recovery_choice(failures: Array[String]) -> void:
    var model = WorldCampaignScript.new()
    model.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
    model.state = WorldCampaignScript.STATE_HUB
    var start := model.begin_expedition("lighthouse_survey")
    if not bool(start.get("ok", false)):
        failures.append("W21 failure-story fixture could not enter the final branch")
        return
    var failed := model.settle_expedition("w21-story-failed", "failed")
    if str(failed.get("status", "")) != "SETTLED_FAILED_RECOVERABLE" or not model.has_pending_story_event():
        failures.append("W21 failed expedition did not expose a recoverable story choice")
        return
    var pending: Dictionary = model.pending_story_event()
    if str(pending.get("source_outcome", "")) != "failed" or str(pending.get("parent_region_id", "")) != "eclipse_fortress":
        failures.append("W21 failure story did not retain the failed regional branch identity")
    var resolved := model.resolve_pending_story_event(1)
    if not bool(resolved.get("ok", false)):
        failures.append("W21 failure-recovery story choice could not resolve")
        return
    if model.segment_index != WorldCampaignScript.FINAL_BRANCH_SEGMENT or model.state != WorldCampaignScript.STATE_HUB:
        failures.append("W21 failure-recovery story choice advanced campaign progression")
    if not model.has_progress_path() or model.departure_options().size() != 2:
        failures.append("W21 failure-recovery story choice created a world-graph dead end")


static func _verify_story_save_restore(failures: Array[String]) -> void:
    var model = WorldCampaignScript.new()
    model.reset(210932)
    model.begin_expedition("restore_lighthouse")
    model.settle_expedition("w21-story-save", "failed")
    var pending_id := model.pending_event_id
    var snapshot_before := model.snapshot()
    var restored = WorldCampaignScript.new()
    if not restored.restore_snapshot(snapshot_before):
        failures.append("W21 pending story event could not survive world snapshot restore")
        return
    if restored.pending_event_id != pending_id or str(restored.pending_story_event().get("source_outcome", "")) != "failed":
        failures.append("W21 pending story event changed identity across snapshot restore")
        return
    var first_resolve := restored.resolve_pending_story_event(0)
    if not bool(first_resolve.get("ok", false)):
        failures.append("W21 restored pending story event could not resolve")
        return
    var after_once := restored.snapshot()
    var duplicate := restored.resolve_pending_story_event(0)
    if str(duplicate.get("status", "")) != "NO_PENDING_EVENT" or restored.snapshot() != after_once:
        failures.append("W21 story choice was not idempotent after the pending event was consumed")
    var second_restore = WorldCampaignScript.new()
    if not second_restore.restore_snapshot(after_once):
        failures.append("W21 resolved story consequence could not survive a second restore")
    elif second_restore.resolved_event_ids.size() != 1 or second_restore.next_expedition_modifier.is_empty():
        failures.append("W21 resolved story consequence was lost across save/reload")


static func _verify_multiple_endings(failures: Array[String]) -> void:
    var mapping_model = WorldCampaignScript.new()
    var mapped_endings: Array[String] = []
    for bias: String in ["shelter", "frontier", "signal", "witness"]:
        var mapped := str(mapping_model._ending_for_bias(bias, "eclipse_fortress"))
        if not mapped_endings.has(mapped):
            mapped_endings.append(mapped)
    if mapped_endings.size() != 4:
        failures.append("W21 four authored ending biases did not map to four distinct ending identities")

    var model = WorldCampaignScript.new()
    model.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
    model.state = WorldCampaignScript.STATE_HUB
    var start := model.begin_expedition("lighthouse_survey")
    if not bool(start.get("ok", false)):
        failures.append("W21 ending fixture could not begin the final branch")
        return
    var settled := model.settle_expedition("w21-ending-final", "success")
    if not bool(settled.get("ok", false)) or not model.is_campaign_complete() or not model.has_pending_story_event():
        failures.append("W21 final branch did not reach a pending epilogue choice")
        return
    if not model.ending_id.is_empty():
        failures.append("W21 ending was finalized before the player resolved the final story choice")

    var pending_snapshot := model.snapshot()
    var restored_pending = WorldCampaignScript.new()
    if not restored_pending.restore_snapshot(pending_snapshot):
        failures.append("W21 pending final story choice could not survive save/reload")
        return
    if not restored_pending.ending_id.is_empty():
        failures.append("W21 save migration finalized a legacy ending while a final story choice was still pending")
    var resolved := restored_pending.resolve_pending_story_event(0)
    if not bool(resolved.get("ok", false)) or restored_pending.ending_id.is_empty():
        failures.append("W21 final story choice did not produce a persistent ending")
        return
    if not mapped_endings.has(restored_pending.ending_id):
        failures.append("W21 final story choice produced an unregistered ending identity")
    if restored_pending.departure_options().size() != 2 or not restored_pending.has_progress_path():
        failures.append("W21 ending removed the post-final continuation paths")
