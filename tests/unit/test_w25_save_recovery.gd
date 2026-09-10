extends RefCounted

const SaveStoreScript = preload("res://game/core/save_store.gd")
const TEST_ROOT: String = "user://ci_w25_save_recovery"
const BLOCKER_PATH: String = "user://ci_w25_save_blocker"

static func run() -> Array[String]:
    var failures: Array[String] = []
    SaveStoreScript.clear_slot(0, TEST_ROOT)
    _remove_file(BLOCKER_PATH)

    var sequence_7 := SaveStoreScript.make_envelope({"checkpoint": 7}, 7, "w25-7")
    var sequence_8 := SaveStoreScript.make_envelope({"checkpoint": 8}, 8, "w25-8")
    var sequence_9 := SaveStoreScript.make_envelope({"checkpoint": 9}, 9, "w25-9")
    var sequence_10 := SaveStoreScript.make_envelope({"checkpoint": 10}, 10, "w25-10")
    _expect(bool(SaveStoreScript.write_slot(0, sequence_7, TEST_ROOT).get("ok", false)), "initial W25 save failed", failures)
    _expect(bool(SaveStoreScript.write_slot(0, sequence_8, TEST_ROOT).get("ok", false)), "second W25 save failed", failures)

    var primary := "%s/slot_0.json" % TEST_ROOT
    var backup := primary + ".bak"
    var temporary := primary + ".tmp"
    _expect(_write_raw(temporary, JSON.stringify(SaveStoreScript.make_envelope({"stale_temp": true}, 99, "w25-temp"), "", true)), "could not create stale temp fixture", failures)
    var primary_read := SaveStoreScript.read_slot(0, TEST_ROOT)
    _expect(int(primary_read.get("envelope", {}).get("sequence", -1)) == 8, "stale temp file displaced committed primary", failures)

    _remove_file(backup)
    var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(primary), ProjectSettings.globalize_path(backup))
    _expect(rename_error == OK, "could not simulate interrupted promote", failures)
    var interrupted_read := SaveStoreScript.read_slot(0, TEST_ROOT)
    _expect(str(interrupted_read.get("status", "")) == "RECOVERED_FROM_BACKUP", "interrupted promote did not fall back to backup", failures)
    _expect(int(interrupted_read.get("envelope", {}).get("sequence", -1)) == 8, "interrupted promote recovered wrong sequence", failures)
    _expect(bool(SaveStoreScript.write_slot(0, sequence_9, TEST_ROOT).get("ok", false)), "save did not recover after interrupted promote", failures)
    _expect(int(SaveStoreScript.read_slot(0, TEST_ROOT).get("envelope", {}).get("sequence", -1)) == 9, "post-recovery save did not become primary", failures)

    _expect(_write_raw(primary, "{corrupt-primary"), "could not corrupt primary fixture", failures)
    var corrupt_read := SaveStoreScript.read_slot(0, TEST_ROOT)
    _expect(str(corrupt_read.get("status", "")) == "RECOVERED_FROM_BACKUP", "corrupt primary did not select last good backup", failures)
    _expect(bool(SaveStoreScript.write_slot(0, sequence_10, TEST_ROOT).get("ok", false)), "new save did not self-heal corrupt primary path", failures)
    _expect(int(SaveStoreScript.read_slot(0, TEST_ROOT).get("envelope", {}).get("sequence", -1)) == 10, "self-healed save did not commit newest sequence", failures)

    var blocker := FileAccess.open(BLOCKER_PATH, FileAccess.WRITE)
    if blocker == null:
        failures.append("could not create unwritable-parent fixture")
    else:
        blocker.store_string("not-a-directory")
        blocker.close()
        var blocked := SaveStoreScript.write_slot(1, SaveStoreScript.make_envelope({"checkpoint": 1}, 1, "w25-blocked"), BLOCKER_PATH + "/nested")
        _expect(not bool(blocked.get("ok", true)), "invalid storage parent unexpectedly reported success", failures)

    _expect(_write_raw(primary, "{broken-primary"), "could not create double-corrupt primary fixture", failures)
    _expect(_write_raw(backup, "{broken-backup"), "could not create double-corrupt backup fixture", failures)
    var no_valid := SaveStoreScript.read_slot(0, TEST_ROOT)
    _expect(not bool(no_valid.get("ok", true)) and str(no_valid.get("status", "")) == "NO_VALID_SAVE", "double corruption was not rejected explicitly", failures)

    SaveStoreScript.clear_slot(0, TEST_ROOT)
    _remove_file(BLOCKER_PATH)
    return failures

static func _write_raw(path: String, value: String) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(value)
    file.flush()
    file.close()
    return true

static func _remove_file(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
