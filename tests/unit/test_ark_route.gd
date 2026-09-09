extends RefCounted

const ArkRouteModelScript = preload("res://game/world/ark_route_model.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var preview_model = ArkRouteModelScript.new()
    preview_model.reset(4242)
    var risk_preview := preview_model.route_preview("risk_channel")
    var supply_preview := preview_model.route_preview("supply_causeway")
    if risk_preview.is_empty() or supply_preview.is_empty():
        failures.append("ark route previews were missing a selectable route")
    else:
        if int(risk_preview.get("threat_level", 0)) <= int(supply_preview.get("threat_level", 0)):
            failures.append("risk and supply routes did not expose distinct threat expectations")
        if int(risk_preview.get("estimated_supply_delta", 0)) == int(supply_preview.get("estimated_supply_delta", 0)):
            failures.append("route previews did not expose distinct supply outcomes")
        if str(risk_preview.get("defend_target", "")) == str(supply_preview.get("defend_target", "")):
            failures.append("route choice did not change the defended objective")
        var risk_entry: Vector2 = risk_preview.get("entry_direction", Vector2.ZERO)
        var supply_entry: Vector2 = supply_preview.get("entry_direction", Vector2.ZERO)
        if risk_entry.is_equal_approx(supply_entry):
            failures.append("route choice did not change the enemy entry direction")

    var idempotent = ArkRouteModelScript.new()
    idempotent.reset(4242)
    if not idempotent.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel"):
        failures.append("valid risk route could not be selected")
    var supply_after_choice: int = int(idempotent.supply)
    var generation_after_choice: int = int(idempotent.choice_generation)
    if not idempotent.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel"):
        failures.append("repeating the same junction choice was not idempotent")
    if idempotent.supply != supply_after_choice or idempotent.choice_generation != generation_after_choice:
        failures.append("repeating a route choice applied its cost or generation twice")
    if idempotent.choose_route(ArkRouteModelScript.JUNCTION_ID, "supply_causeway"):
        failures.append("a consumed junction allowed a conflicting second route")

    var risk = ArkRouteModelScript.new()
    var supply_route = ArkRouteModelScript.new()
    risk.reset(4242)
    supply_route.reset(4242)
    risk.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel")
    supply_route.choose_route(ArkRouteModelScript.JUNCTION_ID, "supply_causeway")
    risk.step(1.0)
    supply_route.step(1.0)
    if risk.position.is_equal_approx(supply_route.position):
        failures.append("different routes produced the same movement after equal simulated time")

    _advance_until_rest(risk)
    _advance_until_rest(supply_route)
    if risk.status != ArkRouteModelScript.STATUS_RESTING or supply_route.status != ArkRouteModelScript.STATUS_RESTING:
        failures.append("one or more routes did not reach their explicit rest destination")
    if risk.supply == supply_route.supply:
        failures.append("different routes did not record distinct supply outcomes")
    if not risk.resume_after_rest() or risk.status != ArkRouteModelScript.STATUS_ARRIVED:
        failures.append("risk route rest segment did not resolve into an arrived state")
    if not supply_route.resume_after_rest() or supply_route.status != ArkRouteModelScript.STATUS_ARRIVED:
        failures.append("supply route rest segment did not resolve into an arrived state")

    var risk_director = SpawnDirectorScript.new()
    risk_director.reset(4242)
    var risk_context := risk.route_combat_context()
    risk_director.set_route_context(
        risk_context.get("entry_direction", Vector2.ZERO),
        int(risk_context.get("threat_level", 1))
    )
    var supply_director = SpawnDirectorScript.new()
    supply_director.reset(4242)
    var supply_context := supply_route.route_combat_context()
    supply_director.set_route_context(
        supply_context.get("entry_direction", Vector2.ZERO),
        int(supply_context.get("threat_level", 1))
    )
    var risk_warning := _first_event(
        risk_director.step(SpawnDirectorScript.FIRST_SPAWN_TIME, Vector2.ZERO),
        "telegraph"
    )
    var supply_warning := _first_event(
        supply_director.step(SpawnDirectorScript.FIRST_SPAWN_TIME, Vector2.ZERO),
        "telegraph"
    )
    if risk_warning.is_empty() or supply_warning.is_empty():
        failures.append("route-aware spawn director did not emit the first warning")
    else:
        var risk_position: Vector2 = risk_warning.get("position", Vector2.ZERO)
        var supply_position: Vector2 = supply_warning.get("position", Vector2.ZERO)
        if risk_position.is_equal_approx(supply_position):
            failures.append("different routes produced the same deterministic enemy entry position")
    if risk_director.pending_count() <= supply_director.pending_count():
        failures.append("higher route threat did not increase the initial scheduled combat pressure")

    var hidden_damage = ArkRouteModelScript.new()
    hidden_damage.reset(99)
    hidden_damage.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel")
    var durability_before_hidden: int = int(hidden_damage.durability)
    if hidden_damage.apply_ark_damage(100, false):
        failures.append("ark accepted damage without a visible warning/objective exposure")
    if hidden_damage.durability != durability_before_hidden:
        failures.append("hidden ark damage changed durability")
    if not hidden_damage.apply_ark_damage(ArkRouteModelScript.MAX_DURABILITY, true):
        failures.append("visible ark damage was not applied")
    if hidden_damage.status != ArkRouteModelScript.STATUS_FAILED_RECOVERABLE:
        failures.append("destroyed ark did not enter the recoverable failure state")
    var recovery_supply_before: int = int(hidden_damage.supply)
    if not hidden_damage.recover_from_failure():
        failures.append("recoverable ark failure could not consume supplies to resume")
    if hidden_damage.durability <= 0 or hidden_damage.supply >= recovery_supply_before:
        failures.append("ark recovery did not restore durability and consume supplies")

    var pod = ArkRouteModelScript.new()
    pod.reset(77)
    pod.choose_route(ArkRouteModelScript.JUNCTION_ID, "supply_causeway")
    var pod_supply_before: int = int(pod.supply)
    if pod.apply_objective_damage(999, false):
        failures.append("supply pod accepted hidden objective damage")
    if pod.supply_pod_integrity != ArkRouteModelScript.MAX_SUPPLY_POD_INTEGRITY:
        failures.append("hidden objective damage changed supply pod integrity")
    pod.apply_objective_damage(999, true)
    var pod_supply_after_loss: int = int(pod.supply)
    pod.apply_objective_damage(999, true)
    if pod_supply_after_loss >= pod_supply_before:
        failures.append("losing the supply-route objective did not create its route-specific supply consequence")
    if pod.supply != pod_supply_after_loss:
        failures.append("supply pod loss penalty was applied more than once")

    var paused_route = ArkRouteModelScript.new()
    paused_route.reset(17)
    paused_route.choose_route(ArkRouteModelScript.JUNCTION_ID, "supply_causeway")
    var paused_position: Vector2 = paused_route.position
    paused_route.set_paused(true)
    paused_route.step(2.0)
    if not paused_route.position.is_equal_approx(paused_position):
        failures.append("paused route continued to advance the ark")

    var checkpoint = ArkRouteModelScript.new()
    checkpoint.reset(2026)
    checkpoint.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel")
    checkpoint.step(1.75)
    var snapshot := checkpoint.snapshot()
    var restored = ArkRouteModelScript.new()
    if not restored.restore_snapshot(snapshot):
        failures.append("valid ark route checkpoint could not be restored")
    else:
        if (
            restored.selected_route_id != checkpoint.selected_route_id
            or restored.status != checkpoint.status
            or restored.supply != checkpoint.supply
            or restored.choice_generation != checkpoint.choice_generation
            or not restored.position.is_equal_approx(checkpoint.position)
        ):
            failures.append("ark route checkpoint restore changed deterministic state")
        checkpoint.step(0.5)
        restored.step(0.5)
        if not restored.position.is_equal_approx(checkpoint.position):
            failures.append("restored ark route diverged from the original deterministic continuation")

    return failures


static func _advance_until_rest(model) -> void:
    for _index in range(300):
        if model.status != ArkRouteModelScript.STATUS_TRAVELING:
            return
        model.step(0.1)


static func _first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
    for event in events:
        if str(event.get("type", "")) == event_type:
            return event
    return {}
