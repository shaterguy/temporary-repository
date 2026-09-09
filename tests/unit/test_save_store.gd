extends RefCounted

const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_foundation_saves"


static func run() -> Array[String]:
    var failures: Array[String] = []
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)

    var envelope := SaveStoreScript.make_envelope(
        {"credits": 12, "route": "shipyard_a"},
        7,
        "settlement-0007"
    )
    if not SaveStoreScript.validate_envelope(envelope):
        failures.append("valid save envelope was rejected")

    var serialized := JSON.stringify(envelope, "", true)
    var round_trip_variant = JSON.parse_string(serialized)
    var persisted_envelope: Dictionary = {}
    if typeof(round_trip_variant) != TYPE_DICTIONARY:
        failures.append("serialized envelope did not parse as a dictionary")
    else:
        persisted_envelope = round_trip_variant
        if not SaveStoreScript.validate_envelope(persisted_envelope):
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

    var legacy := {
        "schema_version": 0,
        "sequence": 3,
        "settlement_id": "legacy-settlement",
        "payload": {"schema": "lanternfall-world-v0", "credits": 18},
    }
    legacy["checksum"] = SaveStoreScript.checksum_for(legacy)
    var migrated := SaveStoreScript.migrate_envelope(legacy)
    if not bool(migrated.get("ok", false)):
        failures.append("legacy v0 envelope did not migrate")
    elif migrated.get("status", "") != "MIGRATED_V0_TO_V1":
        failures.append("legacy migration status was not explicit")
    elif not SaveStoreScript.validate_envelope(migrated.get("envelope", {})):
        failures.append("migrated envelope did not validate as current schema")

    var future := envelope.duplicate(true)
    future["schema_version"] = 999
    future["checksum"] = SaveStoreScript.checksum_for(future)
    if SaveStoreScript.migrate_envelope(future).get("status", "") != "UNSUPPORTED_NEWER_SCHEMA":
        failures.append("future save schema was not rejected explicitly")

    var write_result := SaveStoreScript.write_slot(2, envelope, TEST_ROOT)
    if not bool(write_result.get("ok", false)):
        failures.append("slot write failed: %s" % write_result.get("status", "UNKNOWN"))
    else:
        var duplicate_write := SaveStoreScript.write_slot(2, envelope, TEST_ROOT)
        if duplicate_write.get("status", "") != "ALREADY_SAVED":
            failures.append("identical sequence/checksum was not idempotent")
        var conflict := SaveStoreScript.make_envelope({"credits": 13}, 7, "settlement-conflict")
        if SaveStoreScript.write_slot(2, conflict, TEST_ROOT).get("status", "") != "SEQUENCE_CONFLICT":
            failures.append("same sequence with different payload did not conflict")
        var stale := SaveStoreScript.make_envelope({"credits": 1}, 6, "settlement-stale")
        if SaveStoreScript.write_slot(2, stale, TEST_ROOT).get("status", "") != "STALE_SEQUENCE":
            failures.append("older sequence was allowed to overwrite newer save")

        var next_envelope := SaveStoreScript.make_envelope({"credits": 24}, 8, "settlement-0008")
        var next_write := SaveStoreScript.write_slot(2, next_envelope, TEST_ROOT)
        if not bool(next_write.get("ok", false)):
            failures.append("newer sequence failed to save")
        else:
            var primary_path := "%s/slot_2.json" % TEST_ROOT
            var primary_file := FileAccess.open(primary_path, FileAccess.WRITE)
            if primary_file == null:
                failures.append("could not create corruption fixture")
            else:
                primary_file.store_string("{corrupt")
                primary_file.close()
                var backup_read := SaveStoreScript.read_slot(2, TEST_ROOT)
                if not bool(backup_read.get("ok", false)):
                    failures.append("corrupt primary did not recover from backup")
                elif backup_read.get("status", "") != "RECOVERED_FROM_BACKUP":
                    failures.append("backup recovery did not report recovered status")
                elif int(backup_read.get("envelope", {}).get("sequence", -1)) != 7:
                    failures.append("backup recovery did not return prior valid sequence")

    var metadata := SaveStoreScript.slot_metadata(2, TEST_ROOT)
    if not bool(metadata.get("occupied", false)):
        failures.append("occupied slot metadata was not exposed")
    if SaveStoreScript.slot_metadata(0, TEST_ROOT).get("occupied", true):
        failures.append("empty slot metadata reported occupied")

    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)

    var clamped := SaveStoreScript.make_envelope({}, -3)
    if clamped.get("sequence", -1) != 0:
        failures.append("negative sequence was not normalized")
    return failures
