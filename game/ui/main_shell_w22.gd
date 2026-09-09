extends "res://game/ui/main_shell_w18.gd"

const W22CampaignRuntimeScript = preload("res://game/world/campaign_runtime_w22.gd")


func _init() -> void:
    campaign = W22CampaignRuntimeScript.new()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if shell_mode == MODE_HUB and key_event.pressed and not key_event.echo and key_event.keycode == KEY_Y:
            retry_last_endgame_seed()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)


func retry_last_endgame_seed() -> bool:
    if shell_mode != MODE_HUB or campaign == null or not campaign.has_method("begin_endgame_retry"):
        return false
    var begin_result: Dictionary = campaign.call("begin_endgame_retry")
    if not bool(begin_result.get("ok", false)):
        status_label.text = "W22 동일 시드 재도전 불가: %s" % str(begin_result.get("status", "UNKNOWN"))
        return false

    shell_mode = MODE_EXPEDITION
    var context: Dictionary = campaign.world.expedition_context()
    if not _prepare_expedition(context):
        shell_mode = MODE_RECOVERY_BLOCKED
        _set_expedition_processing(false)
        status_label.text = "W22 재도전 런타임 초기화 실패 · 저장된 출항 상태는 유지됨"
        return false
    _start_echo_capture()
    _checkpoint_elapsed = 0.0
    var checkpoint := _checkpoint_runtime("same_seed_retry_initialized")
    if not bool(checkpoint.get("ok", false)):
        status_label.text = "W22 동일 시드 재도전 시작 · 초기 체크포인트 실패: %s" % str(checkpoint.get("status", "UNKNOWN"))
    else:
        _show_expedition_status("동일 시드 재도전")
    return true


func _expedition_seed() -> int:
    if campaign != null and campaign.world != null:
        var context: Dictionary = campaign.world.expedition_context()
        var run_seed := int(context.get("run_seed", 0))
        if run_seed > 0:
            return run_seed
    return super._expedition_seed()


func _observation_summary() -> Dictionary:
    var summary: Dictionary = super._observation_summary()
    summary["weapon_id"] = selected_weapon_id
    var relic_copy: Array[String] = []
    for relic_id: String in selected_relic_ids:
        relic_copy.append(relic_id)
    summary["relic_ids"] = relic_copy
    if region_model.is_active():
        var objective: Dictionary = region_model.objective_snapshot()
        summary["phase_count"] = maxi(0, int(objective.get("phase_count", 0)))
        summary["circuit_activation_count"] = maxi(0, int(objective.get("circuit_activation_count", 0)))
    else:
        summary["phase_count"] = 0
        summary["circuit_activation_count"] = 0
    return summary


func _show_hub_prompt() -> void:
    super._show_hub_prompt()
    if campaign == null or campaign.world == null:
        return
    if campaign.world.has_pending_story_event():
        return
    if int(campaign.world.get("segment_index")) < 4:
        return
    var summary := endgame_progression_snapshot()
    if summary.is_empty():
        return
    var retry_text := " · Y:동일시드 재도전" if bool(summary.get("retry_available", false)) else ""
    status_label.text += " · W22 숙련 %d(%s) · 과제 %d/%d%s" % [
        int(summary.get("mastery_marks", 0)),
        str(summary.get("mastery_rank", "wayfinder")),
        (summary.get("completed_challenges", []) as Array).size(),
        6,
        retry_text,
    ]


func _show_expedition_status(prefix: String) -> void:
    super._show_expedition_status(prefix)
    if campaign == null or campaign.world == null:
        return
    var context: Dictionary = campaign.world.expedition_context()
    if not context.has("run_seed"):
        return
    status_label.text += " · W22 %s · 시드 %d · 과제 %s · 재도전%d" % [
        str(context.get("variant_label", context.get("variant_id", "variant"))),
        int(context.get("run_seed", 0)),
        str(context.get("challenge_id", "none")),
        int(context.get("retry_count", 0)),
    ]


func endgame_progression_snapshot() -> Dictionary:
    if campaign == null or not campaign.has_method("endgame_snapshot"):
        return {}
    var value: Variant = campaign.call("endgame_snapshot")
    return value.duplicate(true) if value is Dictionary else {}
