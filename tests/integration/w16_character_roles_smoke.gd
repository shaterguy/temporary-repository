extends SceneTree

const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const TEST_ROOT: String = "user://ci_w16_character_expansion"
const MAX_ACTION_MILLISECONDS: int = 2500

var _failures: Array[String] = []
var _initial_unlock_count: int = 0
var _post_first_unlock_count: int = 0
var _persisted_selection_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_character_expansion")


func _run_character_expansion() -> void:
    _clear_save()
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        _failures.append("W16 main shell scene could not be loaded")
        _finish(null, 0)
        return

    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame
    shell.set("campaign", CampaignRuntimeScript.new(TEST_ROOT))
    shell.call("_show_slot_prompt")

    var tutorial: Node = shell.get_node_or_null("W16CharacterTutorial")
    if not is_instance_valid(tutorial):
        _failures.append("W16 character tutorial is not mounted in the actual main scene")
        _finish(shell, 0)
        return

    var action_started_ms := Time.get_ticks_msec()
    if not bool(shell.call("select_save_slot", 0)):
        _failures.append("W16 fixture could not create/select the persistent slot")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    var initial_selection: Dictionary = shell.call("character_selection_snapshot")
    var initial_entries: Array = initial_selection.get("entries", [])
    _initial_unlock_count = int(initial_selection.get("unlocked_count", 0))
    if initial_entries.size() != 6:
        _failures.append("W16 actual hub did not expose all 6 character role entries")
    if _initial_unlock_count != 2:
        _failures.append("W16 actual fresh hub must expose exactly 2 initially unlocked characters")
    if bool(shell.call("select_character", CharacterCatalogScript.ID_VEIL)):
        _failures.append("W16 actual hub selected a locked character before its progression condition")
    if not bool(shell.call("select_character", CharacterCatalogScript.ID_CINDER)):
        _failures.append("W16 actual hub could not select the second default character")

    tutorial.call("_refresh_from_runtime")
    var tutorial_state: Dictionary = tutorial.call("status_snapshot")
    if str(tutorial_state.get("selected_character_id", "")) != CharacterCatalogScript.ID_CINDER:
        _failures.append("W16 character tutorial did not follow the selected character")
    if str(tutorial_state.get("prompt", "")).find("근접 호위자") < 0:
        _failures.append("W16 character tutorial did not expose the selected role explanation")

    if not bool(shell.call("select_world_choice", 0)):
        _failures.append("W16 fixture could not depart with Cinder")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    var combat: Variant = shell.get("combat_preview")
    var ark: Variant = shell.get("ark_preview")
    if not is_instance_valid(combat) or not combat.has_method("character_status_snapshot"):
        _failures.append("W16 character-aware survivor runtime is not mounted")
    else:
        var combat_status: Dictionary = combat.call("character_status_snapshot")
        if str(combat_status.get("character_id", "")) != CharacterCatalogScript.ID_CINDER or str(combat_status.get("role_id", "")) != CharacterCatalogScript.ROLE_CLOSE_ESCORT:
            _failures.append("W16 expedition did not apply the selected close-escort role")

    if is_instance_valid(combat) and is_instance_valid(ark):
        var near_position: Vector2 = ark.global_position + Vector2(40.0, 0.0)
        combat.global_position = near_position
        var combat_model: Variant = combat.get("model")
        combat_model.set("position", near_position)
        var damage_result: Dictionary = combat.call("take_damage", 10, 0)
        if int(damage_result.get("applied_damage", -1)) != 7:
            _failures.append("W16 close-escort integration did not reduce a near-Ark 10-damage hit to 7")

    shell.call("_settle_current", "success")
    await process_frame
    await process_frame
    var campaign: Variant = shell.get("campaign")
    var world: Variant = campaign.get("world")
    if str(shell.get("shell_mode")) != "HUB" or int(world.get("segment_index")) != 1:
        _failures.append("W16 first character expedition did not settle into progression hub state")

    var post_first: Dictionary = shell.call("character_selection_snapshot")
    _post_first_unlock_count = int(post_first.get("unlocked_count", 0))
    if _post_first_unlock_count != 5:
        _failures.append("W16 first rescue settlement should expose 5 unlocked characters on its branch")
    if not bool(shell.call("select_character", CharacterCatalogScript.ID_RIVET)):
        _failures.append("W16 newly unlocked Ark engineer could not be selected in the actual hub")
    if not bool(shell.call("select_world_choice", 0)):
        _failures.append("W16 fixture could not depart with the newly unlocked Ark engineer")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    var rivet_status: Dictionary = combat.call("character_status_snapshot")
    if str(rivet_status.get("character_id", "")) != CharacterCatalogScript.ID_RIVET or str(rivet_status.get("role_id", "")) != CharacterCatalogScript.ROLE_ARK_ENGINEER:
        _failures.append("W16 second expedition did not apply the newly unlocked Ark engineer role")

    var checkpoint: Dictionary = shell.call("_checkpoint_runtime", "w16_character_selection")
    if not bool(checkpoint.get("ok", false)):
        _failures.append("W16 selected character could not be checkpointed with the active expedition")
    else:
        var resume: Dictionary = world.call("resume_payload")
        var runtime_state: Dictionary = resume.get("runtime_state", {})
        if str(runtime_state.get("character_id", "")) != CharacterCatalogScript.ID_RIVET:
            _failures.append("W16 active runtime checkpoint did not carry the selected character id")

        var reloaded = CampaignRuntimeScript.new(TEST_ROOT)
        var load_result: Dictionary = reloaded.load_slot(0)
        if bool(load_result.get("ok", false)):
            var reloaded_resume: Dictionary = reloaded.world.resume_payload()
            var reloaded_runtime: Dictionary = reloaded_resume.get("runtime_state", {})
            _persisted_selection_ok = str(reloaded_runtime.get("character_id", "")) == CharacterCatalogScript.ID_RIVET
        if not _persisted_selection_ok:
            _failures.append("W16 selected character did not survive persistent active-expedition reload")

    var action_ms := Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W16 character expansion actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    _finish(shell, action_ms)


func _finish(shell: Node, action_ms: int) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
        await process_frame
        await process_frame
        await process_frame
    _clear_save()

    print("W16_CHARACTER_ACTION_MS=%d" % action_ms)
    print("W16_CHARACTER_COUNT=6")
    print("W16_INITIAL_UNLOCKS=%d" % _initial_unlock_count)
    print("W16_POST_FIRST_UNLOCKS=%d" % _post_first_unlock_count)
    if _persisted_selection_ok:
        print("W16_PERSISTED_SELECTION=PASS")
    if _failures.is_empty():
        print("W16_CHARACTER_EXPANSION=PASS")
        quit(0)
        return

    for failure in _failures:
        printerr("W16_FAIL: %s" % failure)
    printerr("W16_CHARACTER_EXPANSION=FAIL")
    quit(1)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
