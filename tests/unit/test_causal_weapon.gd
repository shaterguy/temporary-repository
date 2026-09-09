extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const CausalWeaponModelScript = preload("res://game/combat/causal_weapon_model.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var counts := WeaponPartCatalogScript.catalog_counts()
    if int(counts.get("triggers", 0)) != 6:
        failures.append("W09 trigger catalog does not contain exactly 6 base parts")
    if int(counts.get("deliveries", 0)) != 6:
        failures.append("W09 delivery catalog does not contain exactly 6 base parts")
    if int(counts.get("transforms", 0)) != 8:
        failures.append("W09 transform catalog does not contain exactly 8 base parts")
    if int(counts.get("curated_weapons", 0)) < 3:
        failures.append("W09 did not provide representative curated weapons")

    var valid_combinations := 0
    var rejected_combinations := 0
    var energy_budget_rejections := 0
    for trigger_id in WeaponPartCatalogScript.TRIGGERS.keys():
        for delivery_id in WeaponPartCatalogScript.DELIVERIES.keys():
            for transform_id in WeaponPartCatalogScript.TRANSFORMS.keys():
                var validation := WeaponPartCatalogScript.validate_recipe({
                    "trigger": str(trigger_id),
                    "delivery": str(delivery_id),
                    "transform": str(transform_id),
                })
                if bool(validation.get("valid", false)):
                    valid_combinations += 1
                    if int(validation.get("cost", 999)) > WeaponPartCatalogScript.MAX_ENERGY_BUDGET:
                        failures.append("allowed weapon combination exceeded the energy budget")
                    if int(validation.get("max_chain_depth", 0)) != WeaponPartCatalogScript.MAX_CHAIN_DEPTH:
                        failures.append("allowed weapon combination lost the finite chain-depth contract")
                else:
                    rejected_combinations += 1
                    if str(validation.get("reason", "")) == "energy_budget":
                        energy_budget_rejections += 1
    if valid_combinations <= 0 or rejected_combinations <= 0:
        failures.append("compatibility table did not distinguish allowed and rejected combinations")
    if energy_budget_rejections <= 0:
        failures.append("energy budget never rejected an otherwise compatible weapon combination")

    for weapon_id in WeaponPartCatalogScript.CURATED_WEAPONS.keys():
        var recipe := WeaponPartCatalogScript.recipe_for_weapon(str(weapon_id))
        var validation := WeaponPartCatalogScript.validate_recipe(recipe)
        if not bool(validation.get("valid", false)):
            failures.append("curated weapon %s violates its own compatibility contract" % str(weapon_id))

    var targets: Array[Dictionary] = [
        {"id": 10, "position": Vector2(100.0, 0.0), "active": true},
        {"id": 11, "position": Vector2(140.0, 0.0), "active": true},
        {"id": 12, "position": Vector2(180.0, 0.0), "active": true},
    ]
    var boundary_weapon = CausalWeaponModelScript.new()
    boundary_weapon.equip_curated_weapon("sunwake_lance")
    var no_boundary := boundary_weapon.resolve_event(
        {"type": "dodge_started", "cause_id": "dodge-no-boundary", "damage": 14, "chain_depth": 0},
        {"phase": "material", "targets": targets, "crosses_circuit_boundary": false}
    )
    var split_boundary := boundary_weapon.resolve_event(
        {"type": "dodge_started", "cause_id": "dodge-boundary", "damage": 14, "chain_depth": 0},
        {"phase": "material", "targets": targets, "crosses_circuit_boundary": true}
    )
    if no_boundary.size() != 2 or split_boundary.size() != 3:
        failures.append("circuit boundary transform did not deterministically add exactly one split target")
    if split_boundary.is_empty() or split_boundary[0].get("effect_order", []) != ["trigger", "delivery", "transform"]:
        failures.append("causal weapon resolution did not preserve trigger→delivery→transform order")

    var duplicate := boundary_weapon.resolve_event(
        {"type": "dodge_started", "cause_id": "dodge-boundary", "damage": 14, "chain_depth": 0},
        {"phase": "material", "targets": targets, "crosses_circuit_boundary": true}
    )
    if not duplicate.is_empty() or boundary_weapon.last_rejection_reason != "duplicate_cause":
        failures.append("same causal event recursively triggered the same weapon more than once")

    var depth_weapon = CausalWeaponModelScript.new()
    depth_weapon.equip_curated_weapon("sunwake_lance")
    var depth_blocked := depth_weapon.resolve_event(
        {"type": "dodge_started", "cause_id": "depth-limit", "damage": 14, "chain_depth": WeaponPartCatalogScript.MAX_CHAIN_DEPTH},
        {"phase": "material", "targets": targets, "crosses_circuit_boundary": true}
    )
    if not depth_blocked.is_empty() or depth_weapon.last_rejection_reason != "chain_limit":
        failures.append("causal chain depth limit did not stop a terminal event")

    var paused_weapon = CausalWeaponModelScript.new()
    var paused_actions := paused_weapon.resolve_event(
        {"type": "auto_attack", "cause_id": "paused", "target_id": 10, "damage": 12, "chain_depth": 0},
        {"phase": "shadow", "targets": targets, "paused": true}
    )
    if not paused_actions.is_empty() or paused_weapon.last_rejection_reason != "paused":
        failures.append("level-up/pause context allowed a weapon event to mutate combat")

    var material_weapon = CausalWeaponModelScript.new()
    var material_actions := material_weapon.resolve_event(
        {"type": "auto_attack", "cause_id": "material-hit", "target_id": 10, "damage": 12, "chain_depth": 0},
        {"phase": "material", "targets": targets}
    )
    var shadow_weapon = CausalWeaponModelScript.new()
    var shadow_actions := shadow_weapon.resolve_event(
        {"type": "auto_attack", "cause_id": "shadow-hit", "target_id": 10, "damage": 12, "chain_depth": 0},
        {"phase": "shadow", "targets": targets}
    )
    if material_actions.is_empty() or shadow_actions.is_empty():
        failures.append("representative phase weapon did not resolve in both phases")
    elif int(shadow_actions[0].get("damage", 0)) <= int(material_actions[0].get("damage", 0)):
        failures.append("shadow-phase transform did not change actual combat damage")
    elif int(shadow_actions[0].get("barrier_pressure", 0)) <= 0:
        failures.append("shadow-phase transform did not expose its visible barrier-pressure coefficient")

    var comparison_weapon = CausalWeaponModelScript.new()
    var comparison := comparison_weapon.upgrade_comparison("sunwake_lance")
    var changed_fields: Array = comparison.get("changed_fields", [])
    if (
        not bool(comparison.get("valid", false))
        or "trigger" not in changed_fields
        or "delivery" not in changed_fields
        or "transform" not in changed_fields
        or not comparison.has("energy_delta")
        or not comparison.has("condition")
    ):
        failures.append("upgrade comparison did not disclose changed condition/form/cost/limit fields")

    var saved_weapon = CausalWeaponModelScript.new()
    saved_weapon.equip_curated_weapon("sunwake_lance")
    saved_weapon.resolve_event(
        {"type": "dodge_started", "cause_id": "persisted-cause", "damage": 14, "chain_depth": 0},
        {"phase": "material", "targets": targets, "crosses_circuit_boundary": true}
    )
    var restored_weapon = CausalWeaponModelScript.new()
    if not restored_weapon.restore_snapshot(saved_weapon.snapshot()):
        failures.append("causal weapon snapshot could not restore")
    else:
        var replayed := restored_weapon.resolve_event(
            {"type": "dodge_started", "cause_id": "persisted-cause", "damage": 14, "chain_depth": 0},
            {"phase": "material", "targets": targets, "crosses_circuit_boundary": true}
        )
        if not replayed.is_empty() or restored_weapon.last_rejection_reason != "duplicate_cause":
            failures.append("snapshot restore replayed an already-consumed causal event")

    var migrated_weapon = CausalWeaponModelScript.new()
    if not migrated_weapon.restore_snapshot({"schema": "causal-weapon-v0", "weapon": "arklight_arc"}):
        failures.append("legacy causal weapon snapshot did not migrate")
    elif migrated_weapon.equipped_weapon_id != "arklight_arc":
        failures.append("legacy causal weapon migration changed the equipped weapon identity")

    var runtime_phase = PhaseBattlefieldModelScript.new()
    var runtime_player = SurvivorControllerScript.new()
    runtime_player.position = Vector2.ZERO
    runtime_player.model.reset(Vector2.ZERO)
    runtime_player.weapon_model.reset()
    runtime_player.set_phase_provider(runtime_phase)
    runtime_player.equip_curated_weapon("sunwake_lance")
    var runtime_encounter = SwarmEncounterScript.new()
    runtime_encounter.configure_player(runtime_player)
    runtime_encounter.configure_phase_provider(runtime_phase)
    runtime_encounter.set_world_phase("material")
    var runtime_ids: Array[int] = []
    for index in range(3):
        var state: Dictionary = runtime_encounter._pool.acquire(
            "swarm",
            Vector2(100.0 + float(index) * 40.0, 0.0),
            40,
            0.0,
            12.0,
            0
        )
        var entity_id := int(state.get("id", -1))
        runtime_encounter._enemy_phases[entity_id] = "material"
        runtime_ids.append(entity_id)
    var runtime_circuit = LightCircuitModelScript.new()
    _feed(runtime_circuit, _square(Vector2.ZERO, 60.0), 0.10)
    runtime_player.set_circuit_provider(runtime_circuit)
    var health_before: Array[int] = []
    for entity_id in runtime_ids:
        health_before.append(int(runtime_encounter._pool.state_for(entity_id).get("health", 0)))
    runtime_player._resolve_events([{"type": "dodge_started", "direction": Vector2.RIGHT}])
    for index in range(runtime_ids.size()):
        var health_after := int(runtime_encounter._pool.state_for(runtime_ids[index]).get("health", 0))
        if health_after >= health_before[index]:
            failures.append("runtime W04/W07/W08 integration did not apply circuit-split weapon damage to target %d" % index)
    runtime_encounter.free()
    runtime_player.free()

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
