extends RefCounted

const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_foundation_saves"

static func run() -> Array[String]:
    var failures: Array[String] = []
    var envelope := SaveStoreScript.make_envelope(
        {"credits": 12, "route": "shipyard_a"},
        7,
        "settlement-0007"
    )
    if not SaveStoreScript.validate_envelope(envelope):
        failures.append("valid save envelope was rejected")

    var serialized := JSON.stringify(envelope, "", true)
    var round_trip_variant = JSON.parse_string(serialized)
    if typeof(round_trip_variant) != TYPE_DICTIONARY:
        failures.append("serialized envelope did not parse as a dictionary")
    else:
        var round_tripped: Dictionary = round_trip_variant
        if not SaveStoreScript.validate_envelope(round_tripped):
            failures.append("JSON round-trip changed checksum validation")

    var tampered := envelope.duplicate(true)
    var tampered_payload: Dictionary = tampered["payload"]
    tampered_payload["credits"] = 99
    if SaveStoreScript.validate_envelope(tampered):
        failures.append("tampered payload retained a valid checksum")

    var recovered := SaveStoreScript.choose_valid(tampered, envelope)
    if not bool(recovered.get("ok", false)):
        failures.append("valid backup was not selected")
    elif recovered.get("status", "") != "RECOVERED_FROM_BACKUP":
        failures.append("backup recovery status was not explicit")

    SaveStoreScript.clear_slot(2, TEST_ROOT)
    var write_result := SaveStoreScript.write_slot(2, envelope, TEST_ROOT)
    if not bool(write_result.get("ok", false)):
        failures.append("slot write failed: %s" % write_result.get("status", "UNKNOWN"))
    else:
        var read_result := SaveStoreScript.read_slot(2, TEST_ROOT)
        if not bool(read_result.get("ok", false)):
            failures.append("slot readback failed: %s" % read_result.get("status", "UNKNOWN"))
        elif read_result.get("envelope", {}) != envelope:
            failures.append("slot readback did not match the written envelope")
    SaveStoreScript.clear_slot(2, TEST_ROOT)

    var clamped := SaveStoreScript.make_envelope({}, -3)
    if clamped.get("sequence", -1) != 0:
        failures.append("negative sequence was not normalized")
    return failures
