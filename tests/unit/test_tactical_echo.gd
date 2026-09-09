extends RefCounted

const TacticalEchoModelScript = preload("res://game/systems/echo/tactical_echo_model.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var failed_record := TacticalEchoModelScript.make_record(
        "failed-run-segment",
        "shade_halo",
        0.40,
        [
            {"time": 0.10, "type": "move", "offset": [80.0, 0.0], "phase": "material"},
            {
                "time": 0.20,
                "type": "fire",
                "weapon_id": "shade_halo",
                "direction": [1.0, 0.0],
                "base_damage": 20,
                "phase": "material",
            },
            {"time": 0.30, "type": "move", "offset": [120.0, 20.0], "phase": "material"},
        ],
        "failed"
    )
    var failed_validation := TacticalEchoModelScript.validate_record(failed_record)
    if not bool(failed_validation.get("valid", false)):
        failures.append("W10 rejected a valid tactical record solely because its source expedition failed")

    var too_long_record := failed_record.duplicate(true)
    too_long_record["duration"] = TacticalEchoModelScript.MAX_RECORD_DURATION_SECONDS + 0.1
    if bool(TacticalEchoModelScript.validate_record(too_long_record).get("valid", false)):
        failures.append("W10 accepted a tactical record longer than the 8-second contract")

    var out_of_order := TacticalEchoModelScript.make_record(
        "out-of-order",
        "shade_halo",
        0.5,
        [
            {"time": 0.30, "type": "move", "offset": [40.0, 0.0], "phase": "material"},
            {"time": 0.20, "type": "move", "offset": [80.0, 0.0], "phase": "material"},
        ],
        "completed"
    )
    if bool(TacticalEchoModelScript.validate_record(out_of_order).get("valid", false)):
        failures.append("W10 accepted a record whose input timestamps are not ordered")

    var invalid_weapon := failed_record.duplicate(true)
    invalid_weapon["weapon_id"] = "removed_weapon"
    var selection_model = TacticalEchoModelScript.new()
    selection_model.select_record(failed_record)
    if selection_model.select_record(invalid_weapon):
        failures.append("W10 kept an incompatible weapon record equipped")
    var invalid_selection := selection_model.selection_status()
    if bool(invalid_selection.get("selected", true)):
        failures.append("W10 did not safely unequip the incompatible record")
    if not str(invalid_selection.get("reason", "")).begins_with("record_unequipped:weapon_incompatible"):
        failures.append("W10 did not expose the incompatible-record reason")

    var capture_model = TacticalEchoModelScript.new()
    if not capture_model.begin_capture("capture-failed", "sunwake_lance", Vector2(100.0, 100.0)):
        failures.append("W10 could not begin a compatible short action capture")
    else:
        capture_model.capture_step(0.10, Vector2(120.0, 100.0), "material")
        capture_model.capture_fire(Vector2.RIGHT, 24, "material", "cause-a")
        capture_model.capture_fire(Vector2.RIGHT, 24, "material", "cause-a")
        capture_model.capture_step(0.10, Vector2(140.0, 100.0), "material")
        var captured := capture_model.finish_capture("failed")
        var captured_validation := TacticalEchoModelScript.validate_record(captured)
        if not bool(captured_validation.get("valid", false)):
            failures.append("W10 failed to finalize a valid failed-expedition capture")
        elif int(captured_validation.get("event_count", 0)) != 3:
            failures.append("W10 recorded a multi-target cause more than once instead of preserving one fire input")

    var first = TacticalEchoModelScript.new()
    var second = TacticalEchoModelScript.new()
    first.select_record(failed_record)
    second.select_record(failed_record)
    var first_activation := first.try_activate_from_circuit(1, "echo_beacon", Vector2(200.0, 200.0), "material")
    var second_activation := second.try_activate_from_circuit(1, "echo_beacon", Vector2(200.0, 200.0), "material")
    if not bool(first_activation.get("accepted", false)) or not bool(second_activation.get("accepted", false)):
        failures.append("W10 compatible record did not activate from an echo-beacon circuit")
    else:
        var first_actions: Array[Dictionary] = []
        var second_actions: Array[Dictionary] = []
        for delta in [0.10, 0.10, 0.10, 0.10]:
            first_actions.append_array(first.step_replay(delta, "material"))
            second_actions.append_array(second.step_replay(delta, "material"))
        if _action_signature(first_actions) != _action_signature(second_actions):
            failures.append("W10 same compatible record did not preserve the same replay input order")
        var echo_fire := _first_type(first_actions, "echo_fire")
        if echo_fire.is_empty():
            failures.append("W10 compatible replay did not emit its recorded fire input")
        elif (
            bool(echo_fire.get("allow_echo_spawn", true))
            or bool(echo_fire.get("allow_rewards", true))
            or bool(echo_fire.get("allow_achievements", true))
            or bool(echo_fire.get("allow_circuit_charge", true))
            or bool(echo_fire.get("allow_causal_chain", true))
        ):
            failures.append("W10 echo fire did not hard-disable recursive echo/reward/circuit side effects")
        elif float(echo_fire.get("power_multiplier", 1.0)) >= 1.0:
            failures.append("W10 tactical echo replay is not power-limited")

    var concurrent = TacticalEchoModelScript.new()
    concurrent.select_record(failed_record)
    concurrent.try_activate_from_circuit(10, "echo_beacon", Vector2.ZERO, "material")
    var overlapping := concurrent.try_activate_from_circuit(11, "echo_beacon", Vector2.ZERO, "material")
    if bool(overlapping.get("accepted", false)) or str(overlapping.get("reason", "")) != "echo_active":
        failures.append("W10 allowed more than one tactical echo at the same time")
    concurrent.cancel_replay("test_cancel")
    var delayed_overlap := concurrent.try_activate_from_circuit(11, "echo_beacon", Vector2.ZERO, "material")
    if bool(delayed_overlap.get("accepted", false)) or str(delayed_overlap.get("reason", "")) != "circuit_already_consumed":
        failures.append("W10 retroactively activated a circuit that was already consumed while another echo was active")
    if not concurrent.step_replay(1.0, "material").is_empty():
        failures.append("W10 mid-replay cancellation continued emitting actions")

    var phase_record := TacticalEchoModelScript.make_record(
        "phase-record",
        "shade_halo",
        0.20,
        [
            {
                "time": 0.05,
                "type": "fire",
                "weapon_id": "shade_halo",
                "direction": [1.0, 0.0],
                "base_damage": 20,
                "phase": "material",
            },
        ],
        "completed"
    )
    var phase_echo = TacticalEchoModelScript.new()
    phase_echo.select_record(phase_record)
    phase_echo.try_activate_from_circuit(20, "echo_beacon", Vector2(300.0, 300.0), "material")
    var phase_actions := phase_echo.step_replay(0.10, "shadow")
    if not _has_type_with_reason(phase_actions, "echo_fire_blocked", "phase_mismatch"):
        failures.append("W10 phase difference did not safely suppress an incompatible recorded shot")
    if not _first_type(phase_actions, "echo_fire").is_empty():
        failures.append("W10 phase-mismatched shot still damaged the current battlefield")

    var collision_record := TacticalEchoModelScript.make_record(
        "collision-record",
        "shade_halo",
        0.20,
        [
            {"time": 0.05, "type": "move", "offset": [170.0, 0.0], "phase": "material"},
        ],
        "completed"
    )
    var collision_phase = PhaseBattlefieldModelScript.new()
    var collision_echo = TacticalEchoModelScript.new()
    collision_echo.select_record(collision_record)
    collision_echo.try_activate_from_circuit(30, "echo_beacon", Vector2(480.0, 300.0), "material")
    var collision_actions := collision_echo.step_replay(0.10, "material", collision_phase)
    var move_action := _first_type(collision_actions, "echo_move")
    if move_action.is_empty() or not bool(move_action.get("collision_blocked", false)):
        failures.append("W10 replay ignored current-world material collision")
    elif not (move_action.get("position", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(480.0, 300.0)):
        failures.append("W10 collision resolver teleported the echo through current terrain")

    var persisted = TacticalEchoModelScript.new()
    persisted.select_record(failed_record)
    persisted.try_activate_from_circuit(40, "echo_beacon", Vector2(200.0, 200.0), "material")
    persisted.step_replay(0.10, "material")
    var envelope := SaveStoreScript.make_envelope({"tactical_echo": persisted.snapshot()}, 4, "")
    if not SaveStoreScript.validate_envelope(envelope):
        failures.append("W10 tactical-echo snapshot is not compatible with the versioned save envelope")
    var restored = TacticalEchoModelScript.new()
    if not restored.restore_snapshot(persisted.snapshot()):
        failures.append("W10 tactical-echo snapshot could not restore")
    else:
        if restored.replay_active:
            failures.append("W10 restore resumed a partially replayed echo and could duplicate side effects")
        if not bool(restored.selection_status().get("selected", false)):
            failures.append("W10 restore lost the selected compatible record")
        var duplicate_circuit := restored.try_activate_from_circuit(40, "echo_beacon", Vector2.ZERO, "material")
        if bool(duplicate_circuit.get("accepted", false)):
            failures.append("W10 restore replayed an already-consumed circuit activation")

    var runtime_origin := Vector2(200.0, 200.0)
    var runtime_player = SurvivorControllerScript.new()
    runtime_player.model.reset(runtime_origin)
    runtime_player.weapon_model.reset()
    runtime_player.echo_model.reset()
    var runtime_phase = PhaseBattlefieldModelScript.new()
    runtime_player.set_phase_provider(runtime_phase)
    var runtime_encounter = SwarmEncounterScript.new()
    runtime_encounter.configure_player(runtime_player)
    runtime_encounter.configure_phase_provider(runtime_phase)
    runtime_encounter.set_world_phase("material")
    var target_state: Dictionary = runtime_encounter._pool.acquire(
        "swarm",
        runtime_origin + Vector2(100.0, 0.0),
        60,
        0.0,
        12.0,
        0
    )
    var target_id := int(target_state.get("id", -1))
    runtime_encounter._enemy_phases[target_id] = "material"
    var runtime_circuit = LightCircuitModelScript.new()
    runtime_circuit.select_module(LightCircuitModelScript.MODULE_ECHO_BEACON)
    _feed(runtime_circuit, _square(runtime_origin, 60.0), 0.10)
    runtime_player.set_circuit_provider(runtime_circuit)
    var runtime_record := TacticalEchoModelScript.make_record(
        "runtime-record",
        "shade_halo",
        0.10,
        [
            {
                "time": 0.05,
                "type": "fire",
                "weapon_id": "shade_halo",
                "direction": [1.0, 0.0],
                "base_damage": 30,
                "phase": "material",
            },
        ],
        "failed"
    )
    runtime_player.select_tactical_echo_record(runtime_record)
    var health_before := int(runtime_encounter._pool.state_for(target_id).get("health", 0))
    var weapon_generation_before: int = int(runtime_player.weapon_model.resolution_generation)
    runtime_player._advance_tactical_echo(0.06)
    var health_after := int(runtime_encounter._pool.state_for(target_id).get("health", 0))
    if health_after >= health_before:
        failures.append("W10 runtime W07/W08 integration did not apply limited echo damage to a current-world target")
    if runtime_player.weapon_model.resolution_generation != weapon_generation_before:
        failures.append("W10 replay re-entered W09 causal weapon resolution instead of using the non-recursive echo path")
    runtime_encounter.free()
    runtime_player.free()

    return failures


static func _action_signature(actions: Array[Dictionary]) -> Array[String]:
    var signature: Array[String] = []
    for action in actions:
        signature.append("%s:%d" % [str(action.get("type", "")), int(action.get("order", -1))])
    return signature


static func _first_type(actions: Array[Dictionary], event_type: String) -> Dictionary:
    for action in actions:
        if str(action.get("type", "")) == event_type:
            return action
    return {}


static func _has_type_with_reason(actions: Array[Dictionary], event_type: String, reason: String) -> bool:
    for action in actions:
        if str(action.get("type", "")) == event_type and str(action.get("reason", "")) == reason:
            return true
    return false


static func _feed(model, points: PackedVector2Array, delta: float) -> void:
    for point in points:
        model.step(delta, point, false)


static func _square(center: Vector2, radius: float) -> PackedVector2Array:
    return PackedVector2Array([
        center + Vector2(-radius, -radius),
        center + Vector2(radius, -radius),
        center + Vector2(radius, radius),
        center + Vector2(-radius, radius),
        center + Vector2(-radius, -radius),
    ])