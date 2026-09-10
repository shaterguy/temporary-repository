extends SceneTree

const MobileInputUnit = preload("res://tests/unit/test_w25_mobile_input.gd")
const SaveRecoveryUnit = preload("res://tests/unit/test_w25_save_recovery.gd")
const W24_SHELL_SCRIPT_PATH: String = "res://game/ui/main_shell_w24.gd"
const W25_OVERLAY_SCRIPT_PATH: String = "res://game/ui/mobile_input_overlay.gd"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _failures.append_array(MobileInputUnit.run())
    _failures.append_array(SaveRecoveryUnit.run())
    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "W25 main shell scene could not be loaded")
    if packed is PackedScene:
        var shell := (packed as PackedScene).instantiate()
        _expect(str(shell.get_script().resource_path) == W24_SHELL_SCRIPT_PATH, "W25 must preserve the verified W24 shell entry point")
        var overlay := shell.get_node_or_null("W25MobileControls")
        _expect(overlay != null, "W25 mobile control overlay is not mounted")
        if overlay != null:
            _expect(str(overlay.get_script().resource_path) == W25_OVERLAY_SCRIPT_PATH, "W25 overlay script path drifted")
        root.add_child(shell)
        await process_frame
        shell.set("shell_mode", "EXPEDITION")
        await process_frame
        overlay = shell.get_node_or_null("W25MobileControls")
        if overlay != null:
            var runtime: Dictionary = overlay.call("runtime_snapshot")
            _expect(bool(runtime.get("enabled", false)), "W25 overlay did not enable in expedition mode")
            var normalized: Dictionary = overlay.call("configure_accessibility", {"left_handed": true, "stick_mode": "floating", "control_scale": 1.20, "control_opacity": 0.60, "haptics_enabled": false, "reduced_flash": true, "reduced_motion": true})
            _expect(bool(normalized.get("left_handed", false)) and str(normalized.get("stick_mode", "")) == "floating", "W25 accessibility configuration did not reach runtime overlay")
            shell.call("set_transient_input", Vector2(0.8, 0.0), true, true)
            overlay.call("cancel_all_input")
            var shell_movement: Vector2 = shell.get("movement_input")
            _expect(shell_movement == Vector2.ZERO, "W25 lifecycle cancellation left movement latched")
            _expect(not bool(shell.get("dodge_pressed")) and not bool(shell.get("phase_pressed")), "W25 lifecycle cancellation left action input latched")
        shell.queue_free()
        await process_frame
    _finish()

func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _finish() -> void:
    print("W25_LAYOUT_MATRIX=1280x720,1600x720,1760x720,1024x768")
    if _failures.is_empty():
        print("W25_MULTITOUCH=PASS")
        print("W25_ACCESSIBILITY=PASS")
        print("W25_LIFECYCLE_INPUT_RESET=PASS")
        print("W25_SAVE_RECOVERY=PASS")
        print("W25_ANDROID_HARDENING=PASS")
        quit(0)
        return
    for failure in _failures:
        printerr("W25_FAIL: %s" % failure)
    printerr("W25_ANDROID_HARDENING=FAIL")
    quit(1)
