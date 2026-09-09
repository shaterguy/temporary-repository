extends RefCounted

const CombatModelScript = preload("res://game/combat/combat_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var no_targets: Array[Dictionary] = []

    var movement_model = CombatModelScript.new()
    movement_model.reset(Vector2.ZERO)
    movement_model.step(0.5, Vector2(2.0, 0.0), false, no_targets)
    if absf(movement_model.position.x - 130.0) > 0.001 or absf(movement_model.position.y) > 0.001:
        failures.append("movement input was not normalized to the configured move speed")

    var pause_model = CombatModelScript.new()
    pause_model.reset(Vector2(10.0, 20.0))
    pause_model.attack_cooldown_remaining = 0.4
    pause_model.set_paused(true)
    var paused_events := pause_model.step(1.0, Vector2.RIGHT, true, no_targets)
    if pause_model.position != Vector2(10.0, 20.0):
        failures.append("paused combat changed player position")
    if not is_equal_approx(pause_model.attack_cooldown_remaining, 0.4):
        failures.append("paused combat advanced attack cooldown")
    if not paused_events.is_empty():
        failures.append("paused combat emitted gameplay events")
    pause_model.set_paused(false)

    var dodge_model = CombatModelScript.new()
    dodge_model.reset(Vector2.ZERO)
    var dodge_events := dodge_model.step(0.01, Vector2.RIGHT, true, no_targets)
    if _first_event(dodge_events, "dodge_started").is_empty():
        failures.append("valid directional dodge did not start")
    if not dodge_model.is_invulnerable():
        failures.append("active dodge did not grant invulnerability")
    var blocked_hit := dodge_model.take_damage(50, 0)
    if int(blocked_hit.get("applied_damage", -1)) != 0 or not bool(blocked_hit.get("blocked", false)):
        failures.append("dodge invulnerability did not block damage")
    dodge_model.step(0.20, Vector2.ZERO, false, no_targets)
    if dodge_model.is_invulnerable():
        failures.append("dodge invulnerability did not expire")

    var damage_model = CombatModelScript.new()
    damage_model.reset(Vector2.ZERO)
    var damage_result := damage_model.take_damage(30, 8)
    if int(damage_result.get("applied_damage", -1)) != 22 or damage_model.health != 78:
        failures.append("armor-adjusted damage result was incorrect")
    if damage_model.hit_feedback_generation != 1:
        failures.append("applied damage did not advance hit-feedback generation exactly once")

    var candidates: Array[Dictionary] = []
    candidates.append({"id": 8, "position": Vector2(10.0, 0.0), "active": true})
    candidates.append({"id": 3, "position": Vector2(-10.0, 0.0), "active": true})
    candidates.append({"id": 1, "position": Vector2(2.0, 0.0), "active": false})
    candidates.append({"id": 2, "position": Vector2(600.0, 0.0), "active": true})
    var selected := CombatModelScript.select_nearest_target(Vector2.ZERO, candidates, 100.0)
    if int(selected.get("id", -1)) != 3:
        failures.append("nearest-target tie break was not stable by target id")

    var attack_model = CombatModelScript.new()
    attack_model.reset(Vector2.ZERO)
    var attack_targets: Array[Dictionary] = []
    attack_targets.append({"id": 42, "position": Vector2(100.0, 0.0), "active": true})
    var first_attack := _first_event(attack_model.step(0.01, Vector2.ZERO, false, attack_targets), "auto_attack")
    if int(first_attack.get("target_id", -1)) != 42 or int(first_attack.get("damage", -1)) != CombatModelScript.ATTACK_DAMAGE:
        failures.append("auto attack did not acquire the in-range target with configured damage")
    var early_attack := _first_event(attack_model.step(0.10, Vector2.ZERO, false, attack_targets), "auto_attack")
    if not early_attack.is_empty():
        failures.append("auto attack fired before its cooldown elapsed")
    var next_attack := _first_event(attack_model.step(0.45, Vector2.ZERO, false, attack_targets), "auto_attack")
    if next_attack.is_empty():
        failures.append("auto attack did not resume when its cooldown elapsed")

    return failures


static func _first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) == event_type:
            return event
    return {}
