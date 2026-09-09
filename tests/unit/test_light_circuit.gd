extends RefCounted

const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")
const ArkConvoyScript = preload("res://game/world/ark_convoy.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var open_line = LightCircuitModelScript.new()
    _feed(open_line, PackedVector2Array([
        Vector2(0.0, 0.0),
        Vector2(80.0, 0.0),
        Vector2(160.0, 0.0),
        Vector2(210.0, 40.0),
    ]), 0.10)
    if open_line.activation_generation != 0:
        failures.append("open movement trail activated a light circuit")

    var valid = LightCircuitModelScript.new()
    _feed(valid, _square(Vector2.ZERO, 60.0), 0.10)
    if valid.activation_generation != 1 or valid.active_circuit_count() != 1:
        failures.append("valid closed movement loop did not activate exactly one circuit")
    if absf(valid.current_light - (LightCircuitModelScript.MAX_LIGHT - LightCircuitModelScript.LIGHT_COST)) > 0.01:
        failures.append("valid circuit did not charge light exactly once")
    var generation_after_activation: int = int(valid.activation_generation)
    valid.step(0.10, Vector2(-60.0, -60.0), false)
    if valid.activation_generation != generation_after_activation:
        failures.append("same-point re-entry duplicated an already activated circuit")

    var jitter = LightCircuitModelScript.new()
    _feed(jitter, PackedVector2Array([
        Vector2(0.0, 0.0),
        Vector2(12.0, 3.0),
        Vector2(-10.0, 5.0),
        Vector2(9.0, -4.0),
        Vector2(-8.0, -6.0),
        Vector2(0.0, 0.0),
    ]), 0.10)
    if jitter.activation_generation != 0:
        failures.append("stationary jitter produced a false circuit")

    var backtrack = LightCircuitModelScript.new()
    _feed(backtrack, PackedVector2Array([
        Vector2(0.0, 0.0),
        Vector2(60.0, 0.0),
        Vector2(120.0, 0.0),
        Vector2(60.0, 0.0),
        Vector2(0.0, 0.0),
    ]), 0.10)
    if backtrack.activation_generation != 0:
        failures.append("short back-and-forth movement produced a false circuit")

    var self_cross = LightCircuitModelScript.new()
    _feed(self_cross, PackedVector2Array([
        Vector2(0.0, 0.0),
        Vector2(100.0, 100.0),
        Vector2(0.0, 100.0),
        Vector2(100.0, 0.0),
        Vector2(0.0, 0.0),
    ]), 0.10)
    if self_cross.activation_generation != 0:
        failures.append("self-intersecting movement loop activated a circuit")

    var teleported = LightCircuitModelScript.new()
    _feed(teleported, PackedVector2Array([
        Vector2(0.0, 0.0),
        Vector2(420.0, 0.0),
        Vector2(0.0, 0.0),
    ]), 0.10)
    if teleported.activation_generation != 0 or teleported.last_rejection_reason != "teleport_segment":
        failures.append("teleport-sized segments were not separated from contiguous trail geometry")

    var low_light = LightCircuitModelScript.new()
    var low_snapshot := low_light.snapshot()
    low_snapshot["light"] = 5.0
    if not low_light.restore_snapshot(low_snapshot):
        failures.append("valid low-light snapshot could not be restored")
    _feed(low_light, _square(Vector2.ZERO, 60.0), 0.10)
    if low_light.activation_generation != 0:
        failures.append("circuit activated without enough light")
    if low_light.last_rejection_reason != "insufficient_light":
        failures.append("insufficient light did not expose its rejection reason")

    var phase_model = LightCircuitModelScript.new()
    _feed(phase_model, PackedVector2Array([
        Vector2(-60.0, -60.0),
        Vector2(60.0, -60.0),
        Vector2(60.0, 60.0),
    ]), 0.10)
    phase_model.set_world_phase("shadow")
    _feed(phase_model, PackedVector2Array([
        Vector2(-60.0, 60.0),
        Vector2(-60.0, -60.0),
    ]), 0.10)
    if phase_model.activation_generation != 0:
        failures.append("phase transition incorrectly joined trail segments across phases")
    _feed(phase_model, _square(Vector2(320.0, 0.0), 60.0), 0.10)
    if phase_model.activation_generation != 1:
        failures.append("new phase could not create a fresh valid circuit")

    var paused = LightCircuitModelScript.new()
    paused.step(0.10, Vector2(-60.0, -60.0), false)
    var elapsed_before_pause: float = float(paused.elapsed_time)
    paused.step(5.0, Vector2(500.0, 500.0), true)
    if absf(paused.elapsed_time - elapsed_before_pause) > 0.001:
        failures.append("paused circuit model advanced trail time or timers")
    _feed(paused, PackedVector2Array([
        Vector2(60.0, -60.0),
        Vector2(60.0, 60.0),
        Vector2(-60.0, 60.0),
        Vector2(-60.0, -60.0),
    ]), 0.10)
    if paused.activation_generation != 1:
        failures.append("paused movement polluted the resumed contiguous trail")

    var coarse = LightCircuitModelScript.new()
    var dense = LightCircuitModelScript.new()
    _feed(coarse, _square(Vector2.ZERO, 60.0), 0.10)
    _feed(dense, PackedVector2Array([
        Vector2(-60.0, -60.0), Vector2(-20.0, -60.0), Vector2(20.0, -60.0), Vector2(60.0, -60.0),
        Vector2(60.0, -20.0), Vector2(60.0, 20.0), Vector2(60.0, 60.0),
        Vector2(20.0, 60.0), Vector2(-20.0, 60.0), Vector2(-60.0, 60.0),
        Vector2(-60.0, 20.0), Vector2(-60.0, -20.0), Vector2(-60.0, -60.0),
    ]), 1.0 / 60.0)
    if coarse.activation_generation != 1 or dense.activation_generation != 1:
        failures.append("equivalent loop geometry diverged across coarse and 60fps sampling")

    var offscreen = LightCircuitModelScript.new()
    _feed(offscreen, _square(Vector2(-1000.0, -700.0), 60.0), 0.10)
    if offscreen.activation_generation != 1:
        failures.append("off-screen world-space trail was incorrectly discarded")

    var snare = LightCircuitModelScript.new()
    snare.select_module(LightCircuitModelScript.MODULE_SNARE)
    _feed(snare, _square(Vector2.ZERO, 60.0), 0.10)
    if absf(snare.movement_multiplier_at(Vector2(60.0, 0.0)) - LightCircuitModelScript.SNARE_MOVEMENT_MULTIPLIER) > 0.001:
        failures.append("circuit boundary did not apply the selected snare area effect")

    var capacity = LightCircuitModelScript.new()
    _feed(capacity, _square(Vector2.ZERO, 60.0), 0.05)
    capacity.step(3.10, Vector2(-60.0, -60.0), false)
    _feed(capacity, _square(Vector2(320.0, 0.0), 60.0), 0.05)
    capacity.step(3.10, Vector2(260.0, -60.0), false)
    _feed(capacity, _square(Vector2(640.0, 0.0), 60.0), 0.05)
    if capacity.activation_generation != 2 or capacity.active_circuit_count() != 2:
        failures.append("simultaneous circuit cap allowed a third active circuit")
    if capacity.last_rejection_reason != "capacity":
        failures.append("simultaneous circuit cap did not expose a capacity rejection")

    var checkpoint = LightCircuitModelScript.new()
    _feed(checkpoint, _square(Vector2.ZERO, 60.0), 0.10)
    var snapshot := checkpoint.snapshot()
    var restored = LightCircuitModelScript.new()
    if not restored.restore_snapshot(snapshot):
        failures.append("valid active-circuit snapshot could not be restored")
    else:
        restored.step(0.25, Vector2(-60.0, -60.0), false)
        if restored.activation_generation != checkpoint.activation_generation:
            failures.append("restore duplicated an already committed circuit activation")
        if restored.active_circuit_count() != checkpoint.active_circuit_count():
            failures.append("restore changed active circuit count")
        if absf(restored.current_light - checkpoint.current_light) > 2.0:
            failures.append("restore changed circuit light budget outside timer regeneration")

    var expiry = LightCircuitModelScript.new()
    _feed(expiry, _square(Vector2.ZERO, 60.0), 0.10)
    expiry.step(LightCircuitModelScript.CIRCUIT_DURATION_SECONDS + 0.25, Vector2(-60.0, -60.0), false)
    if expiry.active_circuit_count() != 0:
        failures.append("expired circuit remained active past its duration")

    var ward = LightCircuitModelScript.new()
    _feed(ward, _square(Vector2.ZERO, 60.0), 0.10)
    if ward.mitigate_damage_at(Vector2.ZERO, 100) != 50:
        failures.append("ark ward did not expose deterministic area damage mitigation")
    var ark = ArkConvoyScript.new()
    ark.configure_seed(44)
    ark.choose_route("risk_channel")
    ark.position = Vector2.ZERO
    ark.set_circuit_provider(ward)
    var durability_before: int = int(ark.model.durability)
    if not ark.apply_ark_damage(100, true):
        failures.append("ark rejected visible damage while testing circuit protection")
    elif durability_before - int(ark.model.durability) != 50:
        failures.append("ark did not consume the active ward mitigation from N02")
    ark.free()

    return failures


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
