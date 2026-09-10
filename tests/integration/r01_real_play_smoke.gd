extends SceneTree

const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_r01_real_play"

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _clear_save()
    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "R01 main shell scene could not be loaded")
    if not packed is PackedScene:
        _finish(null)
        return

    var shell: Node = (packed as PackedScene).instantiate()
    shell.set("campaign", CampaignRuntimeW22Script.new(TEST_ROOT))
    root.add_child(shell)
    await process_frame
    await process_frame

    _expect(str(shell.get("shell_mode")) == "SLOT_SELECT", "R01 main scene did not enter real slot selection")
    _expect(shell.get_node_or_null("W13RepresentativeHud") != null, "R01 representative HUD is not mounted")
    _expect(shell.get_node_or_null("W23WeaponRelicHud") != null, "R01 weapon/relic HUD is not mounted")
    var overlay := shell.get_node_or_null("W25MobileControls")
    _expect(overlay != null, "R01 W25 mobile controls are not mounted")

    _expect(bool(shell.call("select_save_slot", 0)), "R01 could not create/select the real persistent slot")
    await process_frame
    _expect(str(shell.get("shell_mode")) == "HUB", "R01 real slot selection did not enter HUB")
    var campaign: Variant = shell.get("campaign")
    var world: Variant = campaign.get("world")
    _expect(str(world.get("state")) == "HUB", "R01 campaign state diverged from real HUB shell state")

    _expect(bool(shell.call("select_world_choice", 0)), "R01 real hub choice could not begin first expedition")
    await process_frame
    await physics_frame
    _expect(str(shell.get("shell_mode")) == "EXPEDITION", "R01 hub choice did not enter EXPEDITION")
    _expect(str(world.get("state")) == "EXPEDITION", "R01 persistent world did not enter EXPEDITION")
    var first_expedition_id := str(world.get("active_expedition_id"))
    _expect(not first_expedition_id.is_empty(), "R01 first expedition id is missing")

    overlay = shell.get_node_or_null("W25MobileControls")
    _expect(overlay != null and bool(overlay.call("runtime_snapshot").get("enabled", false)), "R01 mobile overlay did not enable from the real expedition state")
    var combat: Variant = shell.get("combat_preview")
    _expect(is_instance_valid(combat), "R01 combat runtime is missing")
    if overlay != null and is_instance_valid(combat):
        var input_model: Variant = overlay.get("model")
        var layout: Dictionary = input_model.call("layout_snapshot")
        var stick_center: Vector2 = layout.get("stick_center", Vector2.ZERO)
        var stick_radius := float(layout.get("stick_radius", 82.0))
        var dodge_center: Vector2 = layout.get("dodge_center", Vector2.ZERO)
        var start_position: Vector2 = combat.global_position

        _push_touch(root, 101, stick_center, true)
        _push_drag(root, 101, stick_center + Vector2(stick_radius * 0.9, 0.0), Vector2(stick_radius * 0.9, 0.0))
        await process_frame
        var touch_snapshot: Dictionary = overlay.call("runtime_snapshot")
        var overlay_movement: Vector2 = touch_snapshot.get("movement", Vector2.ZERO)
        var shell_movement: Vector2 = shell.get("movement_input")
        var combat_movement: Vector2 = combat.get("_virtual_movement")
        _expect(overlay_movement.x > 0.70, "R01 real touch drag did not produce overlay movement")
        _expect(shell_movement.x > 0.70, "R01 touch movement did not reach the real shell bridge")
        _expect(combat_movement.x > 0.70, "R01 touch movement did not reach the combat runtime")

        _push_touch(root, 202, dodge_center, true)
        await process_frame
        touch_snapshot = overlay.call("runtime_snapshot")
        _expect(bool(touch_snapshot.get("dodge", false)), "R01 real dodge touch was not retained by the overlay")
        _expect(bool(shell.get("dodge_pressed")), "R01 real dodge touch did not reach the shell bridge")

        for _index in range(4):
            await physics_frame
        _expect(combat.global_position.x > start_position.x, "R01 touch-driven combat runtime did not move the player")

        _push_touch(root, 202, dodge_center, false)
        _push_touch(root, 101, stick_center, false)
        await process_frame
        touch_snapshot = overlay.call("runtime_snapshot")
        _expect(Vector2(touch_snapshot.get("movement", Vector2.ZERO)).is_zero_approx(), "R01 released touch left movement latched")
        _expect(not bool(touch_snapshot.get("dodge", false)), "R01 released touch left dodge latched")

    var checkpoint: Dictionary = shell.call("_checkpoint_runtime", "r01_active_restore")
    _expect(bool(checkpoint.get("ok", false)), "R01 active expedition checkpoint failed")
    var checkpoint_sequence := int(campaign.get("sequence"))
    _expect(checkpoint_sequence > 0, "R01 active expedition checkpoint did not advance save sequence")

    shell.queue_free()
    await process_frame
    await process_frame
    await process_frame

    var restored_shell: Node = (packed as PackedScene).instantiate()
    restored_shell.set("campaign", CampaignRuntimeW22Script.new(TEST_ROOT))
    root.add_child(restored_shell)
    await process_frame
    await process_frame
    _expect(bool(restored_shell.call("select_save_slot", 0)), "R01 saved active expedition could not be selected after scene reload")
    await process_frame
    await physics_frame

    var restored_campaign: Variant = restored_shell.get("campaign")
    var restored_world: Variant = restored_campaign.get("world")
    _expect(str(restored_shell.get("shell_mode")) == "EXPEDITION", "R01 active save reload did not resume EXPEDITION")
    _expect(str(restored_world.get("state")) == "EXPEDITION", "R01 restored world is not EXPEDITION")
    _expect(str(restored_world.get("active_expedition_id")) == first_expedition_id, "R01 restored expedition identity drifted")
    _expect(int(restored_campaign.get("sequence")) >= checkpoint_sequence, "R01 restored save sequence regressed")
    var restored_overlay := restored_shell.get_node_or_null("W25MobileControls")
    _expect(restored_overlay != null and bool(restored_overlay.call("runtime_snapshot").get("enabled", false)), "R01 restored expedition did not reactivate touch controls")

    restored_shell.call("_settle_current", "success")
    await process_frame
    await process_frame
    _expect(str(restored_shell.get("shell_mode")) == "HUB", "R01 real settlement did not return to HUB")
    _expect(str(restored_world.get("state")) == "HUB", "R01 persistent world did not return to HUB after settlement")
    _expect(int(restored_world.get("segment_index")) == 1, "R01 real settlement did not advance the campaign segment")
    _expect(bool(restored_world.call("has_pending_story_event")), "R01 settlement did not schedule the real W21 story event")

    var event: Dictionary = restored_campaign.call("current_story_event")
    var event_id := str(event.get("event_id", ""))
    var event_hud := restored_shell.get_node_or_null("W23WorldEventHud")
    _expect(not event_id.is_empty(), "R01 real story event id is missing")
    _expect(event_hud != null, "R01 story event HUD is not mounted")
    if event_hud != null:
        var event_snapshot: Dictionary = event_hud.call("event_snapshot")
        _expect(str(event_snapshot.get("event_id", "")) == event_id, "R01 story event HUD is not bound to the real pending event")

    _expect(bool(restored_shell.call("select_world_choice", 0)), "R01 could not resolve the real story event through the shell choice path")
    await process_frame
    _expect(not bool(restored_world.call("has_pending_story_event")), "R01 story event remained pending after real choice resolution")
    _expect(str(restored_shell.get("shell_mode")) == "HUB", "R01 story resolution unexpectedly left HUB")

    _expect(bool(restored_shell.call("select_world_choice", 0)), "R01 could not begin the next expedition after settlement/story resolution")
    await process_frame
    await physics_frame
    _expect(str(restored_shell.get("shell_mode")) == "EXPEDITION", "R01 next-run hub choice did not re-enter EXPEDITION")
    _expect(str(restored_world.get("state")) == "EXPEDITION", "R01 next-run persistent state did not re-enter EXPEDITION")
    _expect(str(restored_world.get("active_expedition_id")) != first_expedition_id, "R01 next expedition reused the prior expedition identity")

    _finish(restored_shell)


func _push_touch(viewport: Viewport, pointer_id: int, position: Vector2, pressed: bool, cancelled: bool = false) -> void:
    var event := InputEventScreenTouch.new()
    event.index = pointer_id
    event.position = position
    event.pressed = pressed
    event.canceled = cancelled
    viewport.push_input(event, true)


func _push_drag(viewport: Viewport, pointer_id: int, position: Vector2, relative: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = pointer_id
    event.position = position
    event.relative = relative
    viewport.push_input(event, true)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish(shell: Node) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
        await process_frame
        await process_frame
    _clear_save()
    if _failures.is_empty():
        print("R01_REAL_SLOT_TO_HUB=PASS")
        print("R01_REAL_HUB_TO_EXPEDITION=PASS")
        print("R01_REAL_TOUCH_TO_COMBAT=PASS")
        print("R01_ACTIVE_SAVE_RELOAD=PASS")
        print("R01_SETTLEMENT_STORY_NEXT_RUN=PASS")
        print("R01_REAL_PLAY_SMOKE=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("R01_FAIL: %s" % failure)
    printerr("R01_REAL_PLAY_SMOKE=FAIL")
    quit(1)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
