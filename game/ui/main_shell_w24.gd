extends "res://game/ui/main_shell_w23.gd"

const W24_DEFAULT_REGION_ID: String = "twilight_shipyard"

func _ready() -> void:
    super._ready()
    _set_audio_region(W24_DEFAULT_REGION_ID)
    _play_ui_action("open")

func select_save_slot(slot: int) -> bool:
    var resolved := super.select_save_slot(slot)
    _play_ui_action("confirm" if resolved else "reject")
    return resolved

func select_world_choice(option_index: int) -> bool:
    var resolved := super.select_world_choice(option_index)
    _play_ui_action("confirm" if resolved else "reject")
    return resolved

func _prepare_expedition(context: Dictionary) -> bool:
    var resolved := super._prepare_expedition(context)
    if not resolved:
        _play_ui_action("reject")
        return false
    _set_audio_region(_region_id_for_audio(context))
    var audio := _audio_director()
    if audio != null and audio.has_method("clear_boss_music"):
        audio.call("clear_boss_music")
    return true

func _resume_saved_expedition() -> bool:
    var resolved := super._resume_saved_expedition()
    if resolved:
        var context: Dictionary = campaign.world.expedition_context() if campaign != null else {}
        _set_audio_region(_region_id_for_audio(context))
    return resolved

func _enter_hub() -> void:
    super._enter_hub()
    _set_audio_region(W24_DEFAULT_REGION_ID)
    var audio := _audio_director()
    if audio != null and audio.has_method("clear_boss_music"):
        audio.call("clear_boss_music")

func audio_runtime_snapshot() -> Dictionary:
    var audio := _audio_director()
    if audio == null or not audio.has_method("production_snapshot"):
        return {}
    return audio.call("production_snapshot")

func _region_id_for_audio(context: Dictionary) -> String:
    if region_model != null and region_model.has_method("is_active") and bool(region_model.call("is_active")):
        var active_region := str(region_model.call("region_id"))
        if not active_region.is_empty():
            return active_region
    var context_region := str(context.get("region_id", ""))
    if not context_region.is_empty():
        return context_region
    var parent_region := str(context.get("parent_region_id", ""))
    if not parent_region.is_empty():
        return parent_region
    return W24_DEFAULT_REGION_ID

func _set_audio_region(region_id: String) -> void:
    var audio := _audio_director()
    if audio != null and audio.has_method("set_region"):
        if not bool(audio.call("set_region", region_id)):
            audio.call("set_region", W24_DEFAULT_REGION_ID)

func _play_ui_action(action_id: String) -> void:
    var audio := _audio_director()
    if audio != null and audio.has_method("play_ui_action"):
        audio.call("play_ui_action", action_id)

func _audio_director() -> Node:
    return get_node_or_null("/root/AudioDirector")
