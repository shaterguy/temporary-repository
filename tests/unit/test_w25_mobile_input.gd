extends RefCounted

const MobileInputModelScript = preload("res://game/ui/mobile_input_model.gd")

static func run() -> Array[String]:
    var failures: Array[String] = []
    var model = MobileInputModelScript.new()
    var matrix := [
        [Vector2(1280.0, 720.0), Vector4.ZERO],
        [Vector2(1600.0, 720.0), Vector4(36.0, 18.0, 36.0, 12.0)],
        [Vector2(1760.0, 720.0), Vector4(64.0, 18.0, 64.0, 12.0)],
        [Vector2(1024.0, 768.0), Vector4(24.0, 20.0, 24.0, 20.0)],
    ]
    for entry in matrix:
        var viewport_size: Vector2 = entry[0]
        var safe_margins: Vector4 = entry[1]
        model.configure_viewport(viewport_size, safe_margins)
        var layout := model.layout_snapshot()
        var safe_rect: Rect2 = layout.get("safe_rect", Rect2())
        var matrix_stick: Vector2 = layout.get("stick_center", Vector2.ZERO)
        var matrix_dodge: Vector2 = layout.get("dodge_center", Vector2.ZERO)
        var matrix_phase: Vector2 = layout.get("phase_center", Vector2.ZERO)
        _expect(safe_rect.has_point(matrix_stick), "stick center escaped safe area", failures)
        _expect(safe_rect.has_point(matrix_dodge), "dodge center escaped safe area", failures)
        _expect(safe_rect.has_point(matrix_phase), "phase center escaped safe area", failures)
        _expect(matrix_dodge.distance_to(matrix_phase) > float(layout.get("button_radius", 0.0)) * 2.0, "action buttons overlap", failures)

    model.configure_viewport(Vector2(1280.0, 720.0), Vector4.ZERO)
    var layout := model.layout_snapshot()
    var stick_center: Vector2 = layout.get("stick_center", Vector2.ZERO)
    var dodge_center: Vector2 = layout.get("dodge_center", Vector2.ZERO)
    var phase_center: Vector2 = layout.get("phase_center", Vector2.ZERO)
    var stick_radius := float(layout.get("stick_radius", 82.0))
    _expect(model.handle_touch(11, stick_center, true), "primary stick pointer was rejected", failures)
    _expect(not model.handle_touch(12, stick_center, true), "second stick pointer stole movement ownership", failures)
    _expect(model.handle_drag(11, stick_center + Vector2(stick_radius * 0.85, 0.0)), "owned stick drag was rejected", failures)
    _expect(model.movement_vector().x > 0.70, "stick drag did not produce normalized movement", failures)
    _expect(model.handle_touch(21, dodge_center, true), "dodge pointer was rejected", failures)
    _expect(model.handle_touch(31, phase_center, true), "phase pointer was rejected", failures)
    _expect(model.dodge_pressed() and model.phase_pressed(), "simultaneous dodge+phase pointers were not retained", failures)
    model.handle_touch(21, dodge_center, false)
    _expect(not model.dodge_pressed() and model.phase_pressed(), "releasing dodge incorrectly released phase", failures)
    var before_cancel := model.generation()
    model.cancel_all()
    _expect(model.movement_vector() == Vector2.ZERO, "cancel did not clear movement", failures)
    _expect(not model.dodge_pressed() and not model.phase_pressed(), "cancel did not clear action pointers", failures)
    _expect(model.generation() > before_cancel, "cancel did not advance transient generation", failures)

    var initial_stick: Vector2 = model.layout_snapshot().get("stick_center", Vector2.ZERO)
    var fixed_left_x := initial_stick.x
    var normalized := model.configure_accessibility({"left_handed": true, "stick_mode": "floating", "control_scale": 9.0, "control_opacity": 0.1, "haptics_enabled": false, "reduced_flash": true, "reduced_motion": true})
    _expect(float(normalized.get("control_scale", 0.0)) == MobileInputModelScript.MAX_CONTROL_SCALE, "control scale was not clamped", failures)
    _expect(float(normalized.get("control_opacity", 0.0)) == MobileInputModelScript.MIN_CONTROL_OPACITY, "control opacity was not clamped", failures)
    _expect(bool(normalized.get("left_handed", false)), "left-handed layout was not retained", failures)
    _expect(str(normalized.get("stick_mode", "")) == MobileInputModelScript.STICK_FLOATING, "floating stick mode was not retained", failures)
    _expect(not bool(normalized.get("haptics_enabled", true)) and bool(normalized.get("reduced_flash", false)) and bool(normalized.get("reduced_motion", false)), "accessibility toggles drifted", failures)
    var handed_layout := model.layout_snapshot()
    var handed_stick: Vector2 = handed_layout.get("stick_center", Vector2.ZERO)
    _expect(handed_stick.x > fixed_left_x, "left-handed layout did not move stick to the right", failures)
    var movement_rect: Rect2 = handed_layout.get("movement_rect", Rect2())
    var floating_start := movement_rect.position + movement_rect.size * 0.55
    _expect(model.handle_touch(41, floating_start, true), "floating stick pointer was rejected", failures)
    var floating_snapshot := model.input_snapshot()
    var floating_origin: Vector2 = floating_snapshot.get("stick_origin", Vector2.ZERO)
    _expect(floating_origin.distance_to(floating_start) < 0.1, "floating stick origin did not follow initial touch", failures)
    model.handle_touch(41, floating_start, false, true)
    _expect(int(model.input_snapshot().get("stick_pointer_id", -2)) == -1, "cancelled pointer remained owned", failures)
    return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
