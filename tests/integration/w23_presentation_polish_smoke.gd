extends SceneTree

const RepresentativeHudScript = preload("res://game/presentation/representative_hud.gd")
const WeaponRelicHudScript = preload("res://game/presentation/w23_weapon_relic_hud.gd")
const WorldEventHudScript = preload("res://game/presentation/w23_world_event_hud.gd")
const CharacterTutorialScript = preload("res://game/ui/character_role_tutorial.gd")
const FirstExpeditionTutorialScript = preload("res://game/ui/first_expedition_tutorial.gd")
const MainShellW24Script = preload("res://game/ui/main_shell_w24.gd")

const VIEWPORT_MATRIX := [
    Vector2(1280.0, 720.0),
    Vector2(1920.0, 1080.0),
    Vector2(2340.0, 1080.0),
    Vector2(2640.0, 1080.0),
]

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    for viewport_size: Vector2 in VIEWPORT_MATRIX:
        var label := "%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
        var base: Dictionary = RepresentativeHudScript.layout_for(viewport_size)
        var combat_layout: Dictionary = WeaponRelicHudScript.layout_for(viewport_size, true)
        var combat_panel: Rect2 = combat_layout.get("panel", Rect2())
        var touch_band := Rect2(
            Vector2(0.0, viewport_size.y * 0.55),
            Vector2(viewport_size.x, viewport_size.y * 0.45)
        )
        _expect(_rect_inside(combat_panel, viewport_size), "%s combat W23 panel must stay inside viewport" % label)
        _expect(str(combat_layout.get("placement", "")) == "combat-upper-right-rail", "%s loadout must use upper-right expedition rail" % label)
        _expect(not combat_panel.intersects(touch_band), "%s loadout panel must stay clear of bottom touch band" % label)
        for key: String in ["player", "ark", "pause", "weapon", "notice"]:
            var base_rect: Rect2 = base.get(key, Rect2())
            _expect(_rect_inside(base_rect, viewport_size), "%s representative HUD %s must stay inside viewport" % [label, key])
            _expect(not combat_panel.intersects(base_rect), "%s W23 panel overlaps representative HUD %s" % [label, key])
            _expect(not base_rect.intersects(touch_band), "%s representative HUD %s must stay clear of bottom touch band" % [label, key])

        var hub_layout: Dictionary = WeaponRelicHudScript.layout_for(viewport_size, false)
        var hub_panel: Rect2 = hub_layout.get("panel", Rect2())
        var event_layout: Dictionary = WorldEventHudScript.layout_for(viewport_size)
        var event_outer: Rect2 = event_layout.get("outer", Rect2())
        var event_card: Rect2 = event_layout.get("card", Rect2())
        _expect(_rect_inside(hub_panel, viewport_size), "%s hub W23 panel must stay inside viewport" % label)
        _expect(_rect_inside(event_outer, viewport_size), "%s story outer frame must stay inside viewport" % label)
        _expect(_rect_inside(event_card, viewport_size), "%s story art card must stay inside viewport" % label)
        _expect(not hub_panel.intersects(event_outer), "%s hub W23 panel overlaps story card" % label)

    var transition: Dictionary = WorldEventHudScript.transition_profile()
    var duration := float(transition.get("duration_seconds", 0.0))
    var max_slide := float(transition.get("max_slide_px", 999.0))
    _expect(duration > 0.0 and duration <= 0.20, "W23D story reveal must be a short presentation transition")
    _expect(max_slide <= 16.0, "W23D story reveal motion must stay below readability threshold")
    _expect(bool(transition.get("presentation_only", false)), "W23D story reveal must be presentation-only")
    _expect(not bool(transition.get("hitbox_motion", true)), "W23D story reveal may not move gameplay hitboxes")

    _expect(RepresentativeHudScript.localize_route_id("supply_causeway") == "보급 둑길", "route id must map to localized player label")
    _expect(RepresentativeHudScript.localize_route_status("TRAVELING") == "항해 중", "route status must map to localized player label")
    _expect(RepresentativeHudScript.localize_module_id("ark_ward") == "방주 방벽", "module id must map to localized player label")
    _expect(RepresentativeHudScript.localize_phase_id("material") == "물질", "phase id must map to localized player label")
    _expect(WeaponRelicHudScript.weapon_label_for("shade_halo") == "그늘 고리", "weapon HUD must use catalog label")
    _expect(WeaponRelicHudScript.relic_label_for("shadow_edge") == "그림자의 날", "relic HUD must use catalog label")
    _expect(WorldEventHudScript.event_label_for("ts_s01") != "ts_s01", "story HUD must not expose raw event id")
    var polished := MainShellW24Script.polish_status_text("W12 회로 ark_ward · 위상 material · supply_causeway")
    _expect(not polished.contains("W12"), "visible status must remove milestone prefix")
    _expect(not polished.contains("ark_ward") and not polished.contains("material") and not polished.contains("supply_causeway"), "visible status must remove raw route/module/phase ids")

    _expect(CharacterTutorialScript.visible_for_mode("HUB"), "character-role tutorial must remain visible in hub")
    _expect(not CharacterTutorialScript.visible_for_mode("EXPEDITION"), "character-role tutorial must be hidden during expedition")
    var move_prompt := FirstExpeditionTutorialScript.prompt_for_step(FirstExpeditionTutorialScript.STEP_MOVE)
    var phase_prompt := FirstExpeditionTutorialScript.prompt_for_step(FirstExpeditionTutorialScript.STEP_PHASE)
    var settle_prompt := FirstExpeditionTutorialScript.prompt_for_step(FirstExpeditionTutorialScript.STEP_SETTLE)
    _expect(move_prompt.contains("왼쪽 패드") and move_prompt.contains("원형 버튼"), "movement tutorial must describe touch controls")
    _expect(not move_prompt.contains("WASD") and not move_prompt.contains("Space"), "movement tutorial must not lead with desktop keys")
    _expect(phase_prompt.contains("마름모 버튼") and not phase_prompt.contains("Q"), "phase tutorial must describe touch control")
    _expect(not settle_prompt.contains("Enter") and not settle_prompt.contains(" R ") and not settle_prompt.contains(" F "), "settlement tutorial must not expose desktop debug-key copy")

    var main_scene: Resource = load("res://game/ui/main_shell.tscn")
    _expect(main_scene is PackedScene, "W23D main scene must load")
    if main_scene is PackedScene:
        var shell: Node = (main_scene as PackedScene).instantiate()
        var weapon_hud := shell.get_node_or_null("W23WeaponRelicHud")
        var event_hud := shell.get_node_or_null("W23WorldEventHud")
        var character_tutorial := shell.get_node_or_null("W16CharacterTutorial")
        var foundation := shell.get_node_or_null("SafeArea/Content/Foundation") as Label
        var status := shell.get_node_or_null("SafeArea/Content/Status") as Label
        _expect(weapon_hud != null, "W23D main scene must mount W23 weapon/relic HUD")
        _expect(event_hud != null, "W23D main scene must mount W23 story event HUD")
        _expect(character_tutorial != null, "W23D main scene must mount character-role tutorial")
        _expect(foundation != null and not foundation.text.contains("구축"), "main shell must not expose development foundation copy")
        _expect(status != null and not status.text.contains("Foundation"), "main shell default status must be player-facing")
        if event_hud != null:
            _expect(bool(event_hud.call("show_event", "ts_s01")), "W23D story HUD must accept canonical W23C event art")
            var snapshot: Dictionary = event_hud.call("event_snapshot")
            _expect(str(snapshot.get("event_id", "")) == "ts_s01", "W23D story HUD event snapshot mismatch")
            _expect(str(snapshot.get("layout_version", "")) == "w23d-responsive-v2", "W23D story HUD responsive layout version missing")
            _expect(str(snapshot.get("event_label", "")) != "ts_s01", "W23D story HUD must expose localized label")
        shell.free()

    _finish()


func _rect_inside(rect: Rect2, viewport_size: Vector2) -> bool:
    const EPSILON := 0.05
    return (
        rect.size.x > 0.0
        and rect.size.y > 0.0
        and rect.position.x >= -EPSILON
        and rect.position.y >= -EPSILON
        and rect.position.x + rect.size.x <= viewport_size.x + EPSILON
        and rect.position.y + rect.size.y <= viewport_size.y + EPSILON
    )


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    print("W23D_READABILITY_MATRIX=1280x720,1920x1080,2340x1080,2640x1080")
    print("W23D_ANIMATION_PROFILE=PRESENTATION_ONLY")
    if _failures.is_empty():
        print("W23D_HUD_COLLISION=PASS")
        print("W23D_STORY_CARD_BOUNDS=PASS")
        print("W23D_TOUCH_CLEARANCE=PASS")
        print("W23D_LOCALIZATION=PASS")
        print("W23D_TUTORIAL_SCOPE=PASS")
        print("W23D_PRESENTATION_POLISH=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W23D_FAIL: %s" % failure)
    printerr("W23D_PRESENTATION_POLISH=FAIL")
    quit(1)
