class_name EndgameProgressionModel
extends RefCounted

const SCHEMA: String = "lanternfall-endgame-v1"
const VARIANT_SCHEMA: String = "lanternfall-endgame-variant-v1"
const MAX_SEED_HISTORY: int = 16

const VARIANT_IDS := [
    "stormglass_flux",
    "scarcity_front",
    "echo_monsoon",
    "lantern_surge",
]
const CHALLENGE_IDS := [
    "risk_path",
    "supply_path",
    "phase_weaver",
    "circuit_scholar",
    "relic_matrix",
    "ranged_discipline",
]
const VARIANT_PROFILES := {
    "stormglass_flux": {
        "label": "폭풍유리 변형",
        "pressure_profile": "phase_pressure",
        "reward_profile": "phase_archive",
    },
    "scarcity_front": {
        "label": "결핍 전선 변형",
        "pressure_profile": "attrition_pressure",
        "reward_profile": "route_cache",
    },
    "echo_monsoon": {
        "label": "잔향 몬순 변형",
        "pressure_profile": "echo_pressure",
        "reward_profile": "echo_archive",
    },
    "lantern_surge": {
        "label": "등화 급류 변형",
        "pressure_profile": "formation_pressure",
        "reward_profile": "lantern_cache",
    },
}


static func default_state() -> Dictionary:
    return {
        "schema": SCHEMA,
        "successful_runs": 0,
        "failed_runs": 0,
        "mastery_marks": 0,
        "weapon_mastery": {},
        "route_mastery": {},
        "completed_challenges": [],
        "mastery_badges": [],
        "active_variant": {},
        "last_failed_variant": {},
        "last_completed_variant": {},
        "seed_history": [],
    }


static func manifest_snapshot() -> Dictionary:
    return {
        "schema": "lanternfall-endgame-manifest-v1",
        "variant_profile_count": VARIANT_IDS.size(),
        "challenge_definition_count": CHALLENGE_IDS.size(),
        "mastery_policy": "horizontal_only",
        "same_seed_retry": true,
        "failure_world_rollback": false,
        "save_payload_schema": "lanternfall-save-payload-v1",
    }


static func restore_state(raw_value: Variant) -> Dictionary:
    if not raw_value is Dictionary or raw_value.is_empty():
        return default_state()
    var raw: Dictionary = raw_value
    if str(raw.get("schema", "")) != SCHEMA:
        return {}
    var restored := default_state()
    restored["successful_runs"] = maxi(0, int(raw.get("successful_runs", 0)))
    restored["failed_runs"] = maxi(0, int(raw.get("failed_runs", 0)))
    restored["mastery_marks"] = maxi(0, int(raw.get("mastery_marks", 0)))
    restored["weapon_mastery"] = _nonnegative_int_dictionary(raw.get("weapon_mastery", {}))
    restored["route_mastery"] = _nonnegative_int_dictionary(raw.get("route_mastery", {}))
    restored["completed_challenges"] = _known_string_array(raw.get("completed_challenges", []), CHALLENGE_IDS)
    restored["mastery_badges"] = _string_array(raw.get("mastery_badges", []))

    for key: String in ["active_variant", "last_failed_variant", "last_completed_variant"]:
        var variant_value: Variant = raw.get(key, {})
        if variant_value is Dictionary and not variant_value.is_empty():
            var variant: Dictionary = variant_value
            if not validate_variant(variant):
                return {}
            restored[key] = variant.duplicate(true)

    var history: Array = []
    var raw_history: Variant = raw.get("seed_history", [])
    if raw_history is Array:
        for raw_item: Variant in raw_history:
            if raw_item is Dictionary:
                var item: Dictionary = raw_item
                var outcome := str(item.get("outcome", ""))
                if int(item.get("run_seed", 0)) > 0 and (outcome == "success" or outcome == "failed"):
                    history.append(item.duplicate(true))
    while history.size() > MAX_SEED_HISTORY:
        history.pop_front()
    restored["seed_history"] = history
    _refresh_mastery_badges(restored)
    return restored


static func begin_run(
    raw_state: Dictionary,
    campaign_seed: int,
    post_final_cycle: int,
    expedition_attempt: int,
    choice_id: String,
    route_id: String,
    same_seed_retry: bool = false
) -> Dictionary:
    var next := restore_state(raw_state)
    if next.is_empty() or choice_id.is_empty() or route_id.is_empty():
        return {}

    var active_variant: Dictionary
    var previous_failed: Dictionary = next.get("last_failed_variant", {})
    if same_seed_retry:
        if previous_failed.is_empty() or not validate_variant(previous_failed):
            return {}
        if str(previous_failed.get("choice_id", "")) != choice_id:
            return {}
        active_variant = previous_failed.duplicate(true)
        active_variant["retry_count"] = maxi(0, int(previous_failed.get("retry_count", 0))) + 1
    else:
        active_variant = _make_variant(
            campaign_seed,
            post_final_cycle,
            expedition_attempt,
            choice_id,
            route_id
        )
    if not validate_variant(active_variant):
        return {}
    next["active_variant"] = active_variant
    return next


static func settle_run(
    raw_state: Dictionary,
    outcome: String,
    context: Dictionary,
    observation_summary: Dictionary,
    settlement_id: String
) -> Dictionary:
    var next := restore_state(raw_state)
    if next.is_empty() or (outcome != "success" and outcome != "failed"):
        return {}
    var active: Dictionary = next.get("active_variant", {})
    if active.is_empty() or not validate_variant(active):
        return next

    var challenge_id := str(active.get("challenge_id", ""))
    var challenge_completed := false
    if outcome == "success":
        next["successful_runs"] = int(next.get("successful_runs", 0)) + 1
        next["mastery_marks"] = int(next.get("mastery_marks", 0)) + 1
        _increment_mastery(next, "route_mastery", str(context.get("route_id", active.get("route_id", ""))))
        _increment_mastery(next, "weapon_mastery", str(observation_summary.get("weapon_id", "")))
        if _challenge_met(challenge_id, context, observation_summary):
            var completed: Array = next.get("completed_challenges", [])
            if not completed.has(challenge_id):
                completed.append(challenge_id)
                challenge_completed = true
            next["completed_challenges"] = completed
        next["last_completed_variant"] = active.duplicate(true)
        next["last_failed_variant"] = {}
    else:
        next["failed_runs"] = int(next.get("failed_runs", 0)) + 1
        next["last_failed_variant"] = active.duplicate(true)

    var history: Array = next.get("seed_history", [])
    history.append({
        "settlement_id": settlement_id,
        "outcome": outcome,
        "run_seed": int(active.get("run_seed", 0)),
        "variant_id": str(active.get("variant_id", "")),
        "challenge_id": challenge_id,
        "challenge_completed": challenge_completed,
        "choice_id": str(active.get("choice_id", "")),
        "route_id": str(context.get("route_id", active.get("route_id", ""))),
        "weapon_id": str(observation_summary.get("weapon_id", "")),
        "retry_count": maxi(0, int(active.get("retry_count", 0))),
    })
    while history.size() > MAX_SEED_HISTORY:
        history.pop_front()
    next["seed_history"] = history
    next["active_variant"] = {}
    _refresh_mastery_badges(next)
    return next


static func active_variant(raw_state: Dictionary) -> Dictionary:
    var restored := restore_state(raw_state)
    if restored.is_empty():
        return {}
    var value: Variant = restored.get("active_variant", {})
    return value.duplicate(true) if value is Dictionary else {}


static func last_failed_variant(raw_state: Dictionary) -> Dictionary:
    var restored := restore_state(raw_state)
    if restored.is_empty():
        return {}
    var value: Variant = restored.get("last_failed_variant", {})
    return value.duplicate(true) if value is Dictionary else {}


static func summary(raw_state: Dictionary) -> Dictionary:
    var restored := restore_state(raw_state)
    if restored.is_empty():
        return {}
    var marks := int(restored.get("mastery_marks", 0))
    return {
        "schema": SCHEMA,
        "successful_runs": int(restored.get("successful_runs", 0)),
        "failed_runs": int(restored.get("failed_runs", 0)),
        "mastery_marks": marks,
        "mastery_rank": _mastery_rank(marks),
        "weapon_mastery": (restored.get("weapon_mastery", {}) as Dictionary).duplicate(true),
        "route_mastery": (restored.get("route_mastery", {}) as Dictionary).duplicate(true),
        "completed_challenges": (restored.get("completed_challenges", []) as Array).duplicate(),
        "mastery_badges": (restored.get("mastery_badges", []) as Array).duplicate(),
        "active_variant": (restored.get("active_variant", {}) as Dictionary).duplicate(true),
        "last_failed_variant": (restored.get("last_failed_variant", {}) as Dictionary).duplicate(true),
        "last_completed_variant": (restored.get("last_completed_variant", {}) as Dictionary).duplicate(true),
        "seed_history": (restored.get("seed_history", []) as Array).duplicate(true),
    }


static func validate_variant(value: Dictionary) -> bool:
    if str(value.get("schema", "")) != VARIANT_SCHEMA:
        return false
    if int(value.get("run_seed", 0)) <= 0:
        return false
    if not VARIANT_IDS.has(str(value.get("variant_id", ""))):
        return false
    if not CHALLENGE_IDS.has(str(value.get("challenge_id", ""))):
        return false
    if str(value.get("choice_id", "")).is_empty() or str(value.get("route_id", "")).is_empty():
        return false
    return int(value.get("retry_count", 0)) >= 0


static func _make_variant(
    campaign_seed: int,
    post_final_cycle: int,
    expedition_attempt: int,
    choice_id: String,
    route_id: String
) -> Dictionary:
    var run_seed := _mix_seed(campaign_seed, post_final_cycle, expedition_attempt, choice_id)
    var variant_index := int(run_seed / 97) % VARIANT_IDS.size()
    var variant_id := str(VARIANT_IDS[variant_index])
    var challenge_index := (int(run_seed / 7) + expedition_attempt) % CHALLENGE_IDS.size()
    var challenge_id := str(CHALLENGE_IDS[challenge_index])
    var profile: Dictionary = VARIANT_PROFILES.get(variant_id, {})
    return {
        "schema": VARIANT_SCHEMA,
        "run_seed": run_seed,
        "variant_id": variant_id,
        "variant_label": str(profile.get("label", variant_id)),
        "pressure_profile": str(profile.get("pressure_profile", "standard")),
        "reward_profile": str(profile.get("reward_profile", "standard")),
        "challenge_id": challenge_id,
        "choice_id": choice_id,
        "route_id": route_id,
        "retry_count": 0,
    }


static func _mix_seed(campaign_seed: int, post_final_cycle: int, expedition_attempt: int, choice_id: String) -> int:
    var value: int = maxi(1, absi(campaign_seed))
    value = int((value * 48271 + maxi(0, post_final_cycle) * 69621 + maxi(1, expedition_attempt) * 104729 + _string_code(choice_id) * 8191) % 2147483647)
    return maxi(1, value)


static func _string_code(value: String) -> int:
    var total: int = 0
    for index: int in range(value.length()):
        total = int((total + (index + 1) * value.unicode_at(index)) % 104729)
    return total


static func _challenge_met(challenge_id: String, context: Dictionary, observation: Dictionary) -> bool:
    match challenge_id:
        "risk_path":
            return str(context.get("route_id", "")) == "risk_channel"
        "supply_path":
            return str(context.get("route_id", "")) == "supply_causeway"
        "phase_weaver":
            return int(observation.get("phase_count", 0)) >= 2
        "circuit_scholar":
            return int(observation.get("circuit_activation_count", 0)) >= 2
        "relic_matrix":
            var relics: Variant = observation.get("relic_ids", [])
            return not str(observation.get("weapon_id", "")).is_empty() and relics is Array and relics.size() >= 2
        "ranged_discipline":
            var total := maxi(0, int(observation.get("total_actions", 0)))
            return total >= 3 and int(observation.get("ranged_actions", 0)) == total
        _:
            return false


static func _increment_mastery(state: Dictionary, key: String, item_id: String) -> void:
    if item_id.is_empty():
        return
    var table: Dictionary = state.get(key, {})
    table[item_id] = maxi(0, int(table.get(item_id, 0))) + 1
    state[key] = table


static func _refresh_mastery_badges(state: Dictionary) -> void:
    var marks := maxi(0, int(state.get("mastery_marks", 0)))
    var badges: Array = state.get("mastery_badges", [])
    if marks >= 3 and not badges.has("charted_wake"):
        badges.append("charted_wake")
    if marks >= 7 and not badges.has("variant_veteran"):
        badges.append("variant_veteran")
    if marks >= 12 and not badges.has("lantern_master"):
        badges.append("lantern_master")
    state["mastery_badges"] = badges


static func _mastery_rank(marks: int) -> String:
    if marks >= 12:
        return "lantern_master"
    if marks >= 7:
        return "variant_veteran"
    if marks >= 3:
        return "charted_wake"
    return "wayfinder"


static func _nonnegative_int_dictionary(raw_value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if not raw_value is Dictionary:
        return result
    for raw_key: Variant in raw_value.keys():
        var key := str(raw_key)
        if not key.is_empty():
            result[key] = maxi(0, int(raw_value[raw_key]))
    return result


static func _string_array(raw_value: Variant) -> Array:
    var result: Array = []
    if not raw_value is Array:
        return result
    for raw_item: Variant in raw_value:
        var item := str(raw_item)
        if not item.is_empty() and not result.has(item):
            result.append(item)
    return result


static func _known_string_array(raw_value: Variant, known_ids: Array) -> Array:
    var result: Array = []
    for item: Variant in _string_array(raw_value):
        if known_ids.has(item):
            result.append(item)
    return result
