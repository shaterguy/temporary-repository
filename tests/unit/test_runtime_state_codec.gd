extends RefCounted

const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const ArkConvoyScript = preload("res://game/world/ark_convoy.gd")
const LightCircuitControllerScript = preload("res://game/systems/circuit/light_circuit_controller.gd")
const PhaseBattlefieldControllerScript = preload("res://game/world/phase_battlefield_controller.gd")
const DoctrineModelScript = preload("res://game/systems/doctrine/disclosed_doctrine_model.gd")
const RuntimeStateCodecScript = preload("res://game/world/runtime_state_codec.gd")
const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var tree := Engine.get_main_loop() as SceneTree
    var holder := Node2D.new()
    tree.root.add_child(holder)

    var player := SurvivorControllerScript.new()
    player.set("camera_enabled", false)
    player.position = Vector2(640.0, 360.0)
    holder.add_child(player)

    var ark := ArkConvoyScript.new()
    ark.position = Vector2(280.0, 360.0)
    holder.add_child(ark)

    var encounter := SwarmEncounterScript.new()
    holder.add_child(encounter)
    encounter.call("configure_player", player)
    encounter.call("configure_escort_target", ark)

    var circuit := LightCircuitControllerScript.new()
    holder.add_child(circuit)
    circuit.call("configure", player, ark)
    encounter.call("configure_area_effect_provider", circuit.call("effect_provider"))

    var phase := PhaseBattlefieldControllerScript.new()
    holder.add_child(phase)
    phase.call("configure", player, encounter, circuit)

    var neutral := DoctrineModelScript.neutral_plan(0)
    if not RuntimeStateCodecScript.reset_player(player, Vector2(640.0, 360.0)):
        failures.append("runtime codec could not reset player state")
    if not RuntimeStateCodecScript.reset_encounter(encounter, 777, neutral):
        failures.append("runtime codec could not reset encounter state")
    circuit.call("reset_for_expedition")
    phase.call("reset_for_expedition")
    if not bool(ark.call("configure_expedition", 777, "risk_channel")):
        failures.append("runtime codec fixture could not configure ark expedition")

    var combat_model: Variant = player.get("model")
    combat_model.set("health", 73)
    combat_model.set("position", Vector2(668.0, 352.0))
    combat_model.set("attack_cooldown_remaining", 0.31)
    player.global_position = Vector2(668.0, 352.0)
    encounter.call("_consume_director_event", {
        "type": "spawn",
        "archetype": "runner",
        "position": Vector2(760.0, 360.0),
    })

    var snapshot := RuntimeStateCodecScript.capture_runtime(
        player,
        ark,
        circuit,
        phase,
        encounter,
        {"total_actions": 7, "ranged_actions": 6, "clustered_actions": 1}
    )
    if snapshot.is_empty():
        failures.append("runtime state codec returned an empty checkpoint")
    elif not CampaignRuntimeScript._is_json_safe(snapshot):
        failures.append("runtime state codec emitted a non-JSON-safe checkpoint")
    else:
        var encoded := JSON.stringify(snapshot, "", true)
        var decoded: Variant = JSON.parse_string(encoded)
        if not decoded is Dictionary:
            failures.append("runtime checkpoint did not survive JSON serialization")
        else:
            RuntimeStateCodecScript.reset_player(player, Vector2(640.0, 360.0))
            RuntimeStateCodecScript.reset_encounter(encounter, 999, neutral)
            ark.call("configure_expedition", 999, "supply_causeway")
            var restored := RuntimeStateCodecScript.restore_runtime(
                decoded,
                player,
                ark,
                circuit,
                phase,
                encounter
            )
            if not bool(restored.get("ok", false)):
                failures.append("runtime checkpoint did not restore: %s" % str(restored.get("status", "UNKNOWN")))
            else:
                if int(player.get("model").get("health")) != 73:
                    failures.append("player health did not restore from runtime checkpoint")
                if not player.global_position.is_equal_approx(Vector2(668.0, 352.0)):
                    failures.append("player position did not restore from runtime checkpoint")
                var ark_state: Dictionary = ark.call("state_snapshot")
                if str(ark_state.get("selected_route_id", "")) != "risk_channel":
                    failures.append("ark route did not restore from runtime checkpoint")
                if int(encounter.call("active_enemy_count")) != 1:
                    failures.append("active encounter population did not restore from runtime checkpoint")
                var observation: Dictionary = restored.get("observation", {})
                if int(observation.get("total_actions", 0)) != 7:
                    failures.append("doctrine observation counters did not restore with runtime checkpoint")

    holder.free()
    return failures
