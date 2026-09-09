extends SceneTree

const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_w17_weapon_relic_expansion"
const MAX_ACTION_MILLISECONDS: int = 2500

var _failures: Array[String] = []
var _persisted_build_ok: bool = false


func _initialize() -> void:
    call_deferred("_run_weapon_relic_expansion")


func _run_weapon_relic_expansion() -> void:
    _clear_save()
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        _failures.append("W17 main shell scene could not be loaded")
        _finish(null, 0)
        return
    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    await process_frame
    await process_frame
    shell.set("campaign", CampaignRuntimeScript.new(TEST_ROOT))
    shell.call("_show_slot_prompt")
    var action_started_ms: int = Time.get_ticks_msec()
    if not bool(shell.call("select_save_slot", 0)):
        _failures.append("W17 fixture could not create/select the persistent slot")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return

    var selection: Dictionary = shell.call("weapon_relic_selection_snapshot")
    if int(selection.get("weapon_count", 0)) != 18:
        _failures.append("W17 actual hub did not expose all 18 curated weapons")
    if int(selection.get("relic_count", 0)) != 48:
        _failures.append("W17 actual hub did not expose all 48 relics")
    if int(selection.get("representative_build_count", 0)) != 6:
        _failures.append("W17 actual hub did not expose all 6 representative builds")
    if (selection.get("weapon_choices", []) as Array).size() != 3 or (selection.get("relic_choices", []) as Array).size() != 3:
        _failures.append("W17 actual hub did not expose three-choice weapon/relic selection cards")

    if not bool(shell.call("select_representative_build", 0)):
        _failures.append("W17 actual hub could not select the boundary-runner representative build")
    var selected_after: Dictionary = shell.call("weapon_relic_selection_snapshot")
    if str(selected_after.get("selected_weapon_id", "")) != "sunwake_lance" or (selected_after.get("selected_relic_ids", []) as Array).size() != 4:
        _failures.append("W17 representative build did not set one curated weapon plus four relics")

    if not bool(shell.call("select_world_choice", 0)):
        _failures.append("W17 fixture could not depart with the selected build")
        _finish(shell, Time.get_ticks_msec() - action_started_ms)
        return
    var combat: Variant = shell.get("combat_preview")
    if not is_instance_valid(combat):
        _failures.append("W17 combat runtime is not mounted")
    else:
        var weapon_status: Dictionary = combat.call("weapon_status_snapshot")
        var weapon_snapshot: Dictionary = weapon_status.get("snapshot", {})
        if str(weapon_snapshot.get("equipped_weapon_id", "")) != "sunwake_lance":
            _failures.append("W17 expedition did not apply the selected curated weapon")
        if (weapon_snapshot.get("equipped_relic_ids", []) as Array).size() != 4:
            _failures.append("W17 expedition did not apply the selected relic loadout")

    var checkpoint: Dictionary = shell.call("_checkpoint_runtime", "w17_weapon_relic_build")
    if not bool(checkpoint.get("ok", false)):
        _failures.append("W17 active weapon/relic build could not be checkpointed")
    else:
        var campaign: Variant = shell.get("campaign")
        var world: Variant = campaign.get("world")
        var resume: Dictionary = world.call("resume_payload")
        var runtime_state: Dictionary = resume.get("runtime_state", {})
        var player_state: Dictionary = runtime_state.get("player", {})
        var weapon_state: Dictionary = player_state.get("weapon", {})
        if str(weapon_state.get("equipped_weapon_id", "")) != "sunwake_lance" or (weapon_state.get("equipped_relic_ids", []) as Array).size() != 4:
            _failures.append("W17 checkpoint did not carry the active weapon/relic build")
        var reloaded = CampaignRuntimeScript.new(TEST_ROOT)
        var load_result: Dictionary = reloaded.load_slot(0)
        if bool(load_result.get("ok", false)):
            var reloaded_resume: Dictionary = reloaded.world.resume_payload()
            var reloaded_runtime: Dictionary = reloaded_resume.get("runtime_state", {})
            var reloaded_player: Dictionary = reloaded_runtime.get("player", {})
            var reloaded_weapon: Dictionary = reloaded_player.get("weapon", {})
            _persisted_build_ok = str(reloaded_weapon.get("equipped_weapon_id", "")) == "sunwake_lance" and (reloaded_weapon.get("equipped_relic_ids", []) as Array).size() == 4
        if not _persisted_build_ok:
            _failures.append("W17 weapon/relic build did not survive persistent active-expedition reload")

    var action_ms: int = Time.get_ticks_msec() - action_started_ms
    if action_ms > MAX_ACTION_MILLISECONDS:
        _failures.append("W17 weapon/relic expansion actions exceeded the %dms CI sanity budget: %dms" % [MAX_ACTION_MILLISECONDS, action_ms])
    _finish(shell, action_ms)


func _finish(shell: Node, action_ms: int) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
        await process_frame
        await process_frame
        await process_frame
    _clear_save()
    print("W17_WEAPON_RELIC_ACTION_MS=%d" % action_ms)
    print("W17_CURATED_WEAPONS=18")
    print("W17_RELICS=48")
    print("W17_REPRESENTATIVE_BUILDS=6")
    print("W17_SELECTION_UI=PASS")
    if _persisted_build_ok:
        print("W17_PERSISTED_BUILD=PASS")
    if _failures.is_empty():
        print("W17_WEAPON_RELIC_EXPANSION=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W17_FAIL: %s" % failure)
    printerr("W17_WEAPON_RELIC_EXPANSION=FAIL")
    quit(1)


func _clear_save() -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
