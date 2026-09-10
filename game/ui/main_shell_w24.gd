extends "res://game/ui/main_shell_w23.gd"

const PresentationWeaponCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const W24_DEFAULT_REGION_ID: String = "twilight_shipyard"

const PRESENTATION_REPLACEMENTS := {
    "W12 ": "",
    "W16 ": "",
    "W17 ": "",
    "W18 ": "",
    "W22 ": "",
    "W26 ": "",
    "supply_causeway": "보급 둑길",
    "risk_channel": "위험 수로",
    "saltglass_reach": "소금유리 여울",
    "stormglass_channel": "폭풍유리 수로",
    "brine_veins": "염수맥",
    "blackglass_spires": "흑유리 첨탑",
    "drowned_archive": "침수 기록고",
    "storm_crown": "폭풍 왕관",
    "afterglow_frontier": "잔광 변경",
    "far_lantern_chain": "먼 등불 사슬",
    "twilight_shipyard": "황혼 조선소",
    "glass_garden": "유리 정원",
    "flooded_archive": "침수 기록원",
    "ash_railway": "재의 철로",
    "eclipse_fortress": "일식 요새",
    "ark_ward": "방주 방벽",
    "echo_beacon": "잔향 표지",
    "snare": "구속 회로",
    "위상 material": "위상 물질",
    "위상 shadow": "위상 그림자",
    "교리 none": "교리 없음",
}


func _ready() -> void:
    super._ready()
    _set_audio_region(W24_DEFAULT_REGION_ID)
    _play_ui_action("open")
    _polish_visible_status()


func _process(delta: float) -> void:
    super._process(delta)
    _polish_visible_status()


func select_save_slot(slot: int) -> bool:
    var resolved := super.select_save_slot(slot)
    _play_ui_action("confirm" if resolved else "reject")
    _polish_visible_status()
    return resolved


func select_world_choice(option_index: int) -> bool:
    var resolved := super.select_world_choice(option_index)
    _play_ui_action("confirm" if resolved else "reject")
    _polish_visible_status()
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
    _polish_visible_status()
    return resolved


func _enter_hub() -> void:
    super._enter_hub()
    _set_audio_region(W24_DEFAULT_REGION_ID)
    var audio := _audio_director()
    if audio != null and audio.has_method("clear_boss_music"):
        audio.call("clear_boss_music")
    _polish_visible_status()


func audio_runtime_snapshot() -> Dictionary:
    var audio := _audio_director()
    if audio == null or not audio.has_method("production_snapshot"):
        return {}
    return audio.call("production_snapshot")


static func polish_status_text(value: String) -> String:
    var polished := value
    for raw: String in PRESENTATION_REPLACEMENTS.keys():
        polished = polished.replace(raw, str(PRESENTATION_REPLACEMENTS[raw]))
    return polished


func _polish_visible_status() -> void:
    if is_instance_valid(status_label):
        status_label.text = polish_status_text(status_label.text)


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
