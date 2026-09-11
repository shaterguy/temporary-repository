extends SceneTree

const EXPECTED_SLOT_MODE: String = "SLOT_SELECT"
const EXPECTED_HUB_MODE: String = "HUB"
const EXPECTED_EXPEDITION_MODE: String = "EXPEDITION"

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    root.size = Vector2i(1280, 720)
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed_resource is PackedScene, "main shell scene must load")
    if not packed_resource is PackedScene:
        _finish()
        return

    var shell: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(shell)
    for _frame in range(4):
        await process_frame

    var controls := shell.get_node_or_null("ScreenUI/SafeArea/Content/TouchChoices")
    _expect(controls != null and controls.has_method("readability_snapshot"), "menu readability controller must be mounted")
    if controls == null or not controls.has_method("readability_snapshot"):
        shell.queue_free()
        await process_frame
        _finish()
        return

    controls.call("force_refresh")
    var slot_snapshot: Dictionary = controls.call("readability_snapshot")
    _expect(str(slot_snapshot.get("mode", "")) == EXPECTED_SLOT_MODE, "initial menu mode must be slot selection")
    _expect(bool(slot_snapshot.get("menu_visible", false)), "slot menu must show dimmer, card, and content")
    _expect(float(slot_snapshot.get("dimmer_alpha", 0.0)) >= 0.72, "menu dimmer must visibly suppress world contrast")
    _expect(float(slot_snapshot.get("panel_alpha", 0.0)) >= 0.94, "menu card must be effectively opaque")
    _expect(float(slot_snapshot.get("touch_height", 0.0)) >= 72.0, "menu touch targets must be at least 72 px high")
    _expect(int(slot_snapshot.get("status_font_size", 0)) >= 20, "status text must be mobile-readable")
    _expect(int(slot_snapshot.get("button_font_size", 0)) >= 22, "choice text must be mobile-readable")
    _expect(bool(slot_snapshot.get("dimmer_blocks_input", false)), "menu dimmer must stop pointer/touch leakage")
    _expect(int(slot_snapshot.get("focus_border_width", 0)) >= 3, "keyboard/controller focus must have a visible border")
    _expect(slot_snapshot.get("normal_button_color", Color.TRANSPARENT) != slot_snapshot.get("pressed_button_color", Color.TRANSPARENT), "pressed state must be visually distinct from normal")
    var slot_labels: Array = slot_snapshot.get("choice_labels", [])
    _expect(slot_labels.size() == 3, "slot menu must expose three labels")
    for label in slot_labels:
        _expect(str(label).contains("새 여정") or str(label).contains("계속하기"), "slot labels must disclose action rather than only slot number")

    shell.set("shell_mode", EXPECTED_HUB_MODE)
    controls.call("force_refresh")
    await process_frame
    var hub_snapshot: Dictionary = controls.call("readability_snapshot")
    _expect(str(hub_snapshot.get("mode", "")) == EXPECTED_HUB_MODE, "hub menu mode mismatch")
    _expect(bool(hub_snapshot.get("menu_visible", false)), "hub menu must retain readability layers")
    var hub_labels: Array = hub_snapshot.get("choice_labels", [])
    var hub_visibility: Array = hub_snapshot.get("choice_visibility", [])
    _expect(hub_labels.size() == 3 and hub_visibility.size() == 3, "hub choice snapshot malformed")
    _expect(bool(hub_visibility[0]) and bool(hub_visibility[1]) and not bool(hub_visibility[2]), "hub must expose exactly two route choices")
    _expect(not str(hub_labels[0]).contains("선택 1") and not str(hub_labels[1]).contains("선택 2"), "hub buttons must disclose route content instead of generic selection labels")
    _expect(str(hub_labels[0]).contains("\n") and str(hub_labels[1]).contains("\n"), "hub buttons must separate destination and route for scanability")

    shell.set("shell_mode", EXPECTED_EXPEDITION_MODE)
    controls.call("force_refresh")
    await process_frame
    var expedition_snapshot: Dictionary = controls.call("readability_snapshot")
    _expect(not bool(expedition_snapshot.get("menu_visible", true)), "opaque menu layers must clear during active expedition")

    print("W06_CONTRACT=r06-medieval-ui-readability-v1")
    print("W06_DIMMER_ALPHA=%.2f" % float(slot_snapshot.get("dimmer_alpha", 0.0)))
    print("W06_PANEL_ALPHA=%.2f" % float(slot_snapshot.get("panel_alpha", 0.0)))
    print("W06_TOUCH_TARGET_PX=%d" % int(slot_snapshot.get("touch_height", 0.0)))
    print("W06_STATUS_FONT_PX=%d" % int(slot_snapshot.get("status_font_size", 0)))
    print("W06_BUTTON_FONT_PX=%d" % int(slot_snapshot.get("button_font_size", 0)))
    print("W06_INPUT_BLOCK=PASS" if bool(slot_snapshot.get("dimmer_blocks_input", false)) else "W06_INPUT_BLOCK=FAIL")
    print("W06_MENU_STATE_TRANSITION=PASS" if not bool(expedition_snapshot.get("menu_visible", true)) else "W06_MENU_STATE_TRANSITION=FAIL")

    shell.queue_free()
    await process_frame
    _finish()


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    if _failures.is_empty():
        print("W06_MEDIEVAL_UI=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W06_FAIL: %s" % failure)
    printerr("W06_MEDIEVAL_UI=FAIL")
    quit(1)
