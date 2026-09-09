extends RefCounted

const VERSION: int = 1
const MIN_OBSERVED_ACTIONS: int = 12
const DEFAULT_RESPONSE_CAP: float = 0.30
const FAILURE_RELIEF_CAP: float = 0.20
const FAILURE_RELIEF_THRESHOLD: int = 3
const DOMINANCE_THRESHOLD: float = 0.55
const FAILURE_DOMINANCE_THRESHOLD: float = 0.62
const CHECKSUM_MODULUS: int = 2147483647
const COUNTERPLAY := ["route_bypass", "light_circuit", "phase_shift"]
const DOCTRINES := {
    "cover_advance": {
        "title": "Cover Advance",
        "formation": "cover_columns",
        "response_archetype": "runner",
        "rationale": "Prior expedition favored ranged pressure; a limited response formation approaches in covered columns.",
    },
    "dispersed_ambush": {
        "title": "Dispersed Ambush",
        "formation": "split_ambush",
        "response_archetype": "swarm",
        "rationale": "Prior expedition clustered its pressure; a limited response formation attacks from separated arcs.",
    },
}


static func neutral_plan(segment_index: int = 0, reason: String = "insufficient_observation") -> Dictionary:
    return {
        "version": VERSION,
        "active": false,
        "doctrine_id": "none",
        "title": "No major counter-doctrine",
        "formation": "baseline",
        "response_archetype": "",
        "response_cap": 0.0,
        "response_stride": 0,
        "counterplay": COUNTERPLAY.duplicate(),
        "rationale": reason,
        "segment_index": maxi(0, segment_index),
        "selection_seed": 0,
        "source_summary_hash": 0,
        "source_total_actions": 0,
        "failure_streak": 0,
        "ranged_share": 0.0,
        "clustered_share": 0.0,
        "beginner_relief": false,
        "disclosure": {
            "title": "No major counter-doctrine",
            "summary": reason,
            "counterplay": COUNTERPLAY.duplicate(),
            "response_cap": 0.0,
        },
    }


static func select_plan(
    observation_summary: Dictionary,
    campaign_seed: int,
    segment_index: int
) -> Dictionary:
    var total_actions := maxi(0, int(observation_summary.get("total_actions", 0)))
    var ranged_actions := clampi(
        int(observation_summary.get("ranged_actions", 0)),
        0,
        total_actions
    )
    var clustered_actions := clampi(
        int(observation_summary.get("clustered_actions", 0)),
        0,
        total_actions
    )
    var failure_streak := maxi(0, int(observation_summary.get("failure_streak", 0)))
    var safe_segment := maxi(0, segment_index)
    var beginner_relief := failure_streak >= FAILURE_RELIEF_THRESHOLD

    if total_actions < MIN_OBSERVED_ACTIONS:
        var low_sample := neutral_plan(safe_segment, "low_sample_no_adaptation")
        low_sample["source_total_actions"] = total_actions
        low_sample["failure_streak"] = failure_streak
        low_sample["beginner_relief"] = beginner_relief
        low_sample["source_summary_hash"] = _summary_fingerprint(
            total_actions,
            ranged_actions,
            clustered_actions,
            failure_streak
        )
        return low_sample

    var ranged_share := float(ranged_actions) / float(total_actions)
    var clustered_share := float(clustered_actions) / float(total_actions)
    var threshold := FAILURE_DOMINANCE_THRESHOLD if beginner_relief else DOMINANCE_THRESHOLD
    if ranged_share < threshold and clustered_share < threshold:
        var mixed_plan := neutral_plan(safe_segment, "mixed_tactics_no_major_doctrine")
        mixed_plan["source_total_actions"] = total_actions
        mixed_plan["failure_streak"] = failure_streak
        mixed_plan["ranged_share"] = ranged_share
        mixed_plan["clustered_share"] = clustered_share
        mixed_plan["beginner_relief"] = beginner_relief
        mixed_plan["source_summary_hash"] = _summary_fingerprint(
            total_actions,
            ranged_actions,
            clustered_actions,
            failure_streak
        )
        return mixed_plan

    var selection_seed := _selection_seed(campaign_seed, safe_segment)
    var doctrine_id := "cover_advance"
    if clustered_share > ranged_share:
        doctrine_id = "dispersed_ambush"
    elif is_equal_approx(clustered_share, ranged_share):
        doctrine_id = "cover_advance" if selection_seed % 2 == 0 else "dispersed_ambush"

    var definition: Dictionary = DOCTRINES[doctrine_id]
    var response_cap := FAILURE_RELIEF_CAP if beginner_relief else DEFAULT_RESPONSE_CAP
    var response_stride := int(ceil(1.0 / response_cap))
    var plan := {
        "version": VERSION,
        "active": true,
        "doctrine_id": doctrine_id,
        "title": str(definition.get("title", doctrine_id)),
        "formation": str(definition.get("formation", "baseline")),
        "response_archetype": str(definition.get("response_archetype", "")),
        "response_cap": response_cap,
        "response_stride": response_stride,
        "counterplay": COUNTERPLAY.duplicate(),
        "rationale": str(definition.get("rationale", "")),
        "segment_index": safe_segment,
        "selection_seed": selection_seed,
        "source_summary_hash": _summary_fingerprint(
            total_actions,
            ranged_actions,
            clustered_actions,
            failure_streak
        ),
        "source_total_actions": total_actions,
        "failure_streak": failure_streak,
        "ranged_share": ranged_share,
        "clustered_share": clustered_share,
        "beginner_relief": beginner_relief,
    }
    plan["disclosure"] = {
        "title": plan["title"],
        "summary": plan["rationale"],
        "counterplay": COUNTERPLAY.duplicate(),
        "response_cap": response_cap,
        "formation": plan["formation"],
        "segment_index": safe_segment,
    }
    return plan


static func validate_plan(plan: Dictionary) -> bool:
    if int(plan.get("version", -1)) != VERSION:
        return false
    var doctrine_id := str(plan.get("doctrine_id", ""))
    var active := bool(plan.get("active", false))
    if not active:
        return doctrine_id == "none" and float(plan.get("response_cap", -1.0)) == 0.0
    if not DOCTRINES.has(doctrine_id):
        return false
    var response_cap := float(plan.get("response_cap", 1.0))
    if response_cap <= 0.0 or response_cap > DEFAULT_RESPONSE_CAP + 0.0001:
        return false
    var response_stride := int(plan.get("response_stride", 0))
    if response_stride < int(ceil(1.0 / response_cap)):
        return false
    var counterplay = plan.get("counterplay", [])
    if not counterplay is Array or counterplay.size() < 2:
        return false
    var seen: Dictionary = {}
    for item in counterplay:
        var counter_id := str(item)
        if not COUNTERPLAY.has(counter_id) or seen.has(counter_id):
            return false
        seen[counter_id] = true
    if plan.has("health_multiplier") or plan.has("damage_multiplier"):
        return false
    return true


static func snapshot_plan(plan: Dictionary) -> Dictionary:
    if not validate_plan(plan):
        return {}
    var snapshot := plan.duplicate(true)
    snapshot["checksum"] = _plan_checksum(snapshot)
    return snapshot


static func restore_plan(snapshot: Dictionary) -> Dictionary:
    var payload := snapshot.duplicate(true)
    var expected_checksum := int(payload.get("checksum", -1))
    payload.erase("checksum")
    if expected_checksum < 0 or expected_checksum != _plan_checksum(payload) or not validate_plan(payload):
        var rejected := neutral_plan(int(payload.get("segment_index", 0)), "tamper_rejected")
        rejected["restore_status"] = "tamper_rejected"
        return rejected
    payload["restore_status"] = "valid"
    return payload


static func _selection_seed(campaign_seed: int, segment_index: int) -> int:
    var base_seed := maxi(1, absi(campaign_seed))
    return int((base_seed + (segment_index + 1) * 7919) % CHECKSUM_MODULUS)


static func _summary_fingerprint(
    total_actions: int,
    ranged_actions: int,
    clustered_actions: int,
    failure_streak: int
) -> int:
    var result := 17
    for value in [total_actions, ranged_actions, clustered_actions, failure_streak]:
        result = int((result * 65599 + maxi(0, int(value))) % CHECKSUM_MODULUS)
    return result


static func _plan_checksum(plan: Dictionary) -> int:
    var counterplay_code := 0
    var counterplay = plan.get("counterplay", [])
    if counterplay is Array:
        for item in counterplay:
            counterplay_code = int(
                (counterplay_code * 131 + _text_code(str(item))) % CHECKSUM_MODULUS
            )
    var values := [
        int(plan.get("version", -1)),
        1 if bool(plan.get("active", false)) else 0,
        _text_code(str(plan.get("doctrine_id", ""))),
        _text_code(str(plan.get("formation", ""))),
        _text_code(str(plan.get("response_archetype", ""))),
        int(round(float(plan.get("response_cap", 0.0)) * 10000.0)),
        int(plan.get("response_stride", 0)),
        int(plan.get("segment_index", 0)),
        int(plan.get("selection_seed", 0)),
        int(plan.get("source_summary_hash", 0)),
        int(plan.get("source_total_actions", 0)),
        int(plan.get("failure_streak", 0)),
        counterplay_code,
    ]
    var result := 23
    for value in values:
        result = int((result * 65599 + absi(int(value))) % CHECKSUM_MODULUS)
    return result


static func _text_code(value: String) -> int:
    var result := 0
    for index in value.length():
        result = int((result * 131 + value.unicode_at(index)) % CHECKSUM_MODULUS)
    return result
