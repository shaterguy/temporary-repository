class_name SaveStore
extends RefCounted

const BuildIdentityScript = preload("res://game/core/build_identity.gd")
const SAVE_ROOT: String = "user://saves"
const SLOT_COUNT: int = 3


static func checksum_for(envelope: Dictionary) -> String:
    var normalized := envelope.duplicate(true)
    normalized.erase("checksum")
    var canonicalized = JSON.parse_string(JSON.stringify(normalized, "", true))
    if typeof(canonicalized) != TYPE_DICTIONARY:
        return ""
    var context := HashingContext.new()
    var start_error := context.start(HashingContext.HASH_SHA256)
    if start_error != OK:
        return ""
    context.update(JSON.stringify(canonicalized, "", true).to_utf8_buffer())
    return context.finish().hex_encode()


static func checksum_matches(envelope: Dictionary) -> bool:
    var expected_checksum := str(envelope.get("checksum", ""))
    if expected_checksum.is_empty():
        return false
    return checksum_for(envelope) == expected_checksum


static func make_envelope(payload: Dictionary, sequence: int, settlement_id: String = "") -> Dictionary:
    var envelope := {
        "schema_version": BuildIdentityScript.SAVE_SCHEMA_VERSION,
        "sequence": maxi(sequence, 0),
        "settlement_id": settlement_id,
        "payload": payload.duplicate(true),
    }
    envelope["checksum"] = checksum_for(envelope)
    return envelope


static func validate_envelope(envelope: Dictionary) -> bool:
    if int(envelope.get("schema_version", -1)) != BuildIdentityScript.SAVE_SCHEMA_VERSION:
        return false
    if int(envelope.get("sequence", -1)) < 0:
        return false
    if typeof(envelope.get("settlement_id", "")) != TYPE_STRING:
        return false
    if typeof(envelope.get("payload", null)) != TYPE_DICTIONARY:
        return false
    return checksum_matches(envelope)


static func migrate_envelope(envelope: Dictionary) -> Dictionary:
    if envelope.is_empty():
        return {"ok": false, "status": "NO_SAVE", "envelope": {}}
    var schema_version := int(envelope.get("schema_version", -1))
    if schema_version == BuildIdentityScript.SAVE_SCHEMA_VERSION:
        if validate_envelope(envelope):
            return {"ok": true, "status": "CURRENT", "envelope": envelope.duplicate(true)}
        return {"ok": false, "status": "INVALID_CURRENT", "envelope": {}}
    if schema_version > BuildIdentityScript.SAVE_SCHEMA_VERSION:
        return {"ok": false, "status": "UNSUPPORTED_NEWER_SCHEMA", "envelope": {}}
    if schema_version != 0:
        return {"ok": false, "status": "UNSUPPORTED_OLDER_SCHEMA", "envelope": {}}
    if int(envelope.get("sequence", -1)) < 0:
        return {"ok": false, "status": "INVALID_LEGACY_SEQUENCE", "envelope": {}}
    if typeof(envelope.get("settlement_id", "")) != TYPE_STRING:
        return {"ok": false, "status": "INVALID_LEGACY_SETTLEMENT", "envelope": {}}
    if typeof(envelope.get("payload", null)) != TYPE_DICTIONARY or not checksum_matches(envelope):
        return {"ok": false, "status": "INVALID_LEGACY_CHECKSUM", "envelope": {}}
    var migrated := make_envelope(
        envelope.get("payload", {}).duplicate(true),
        int(envelope.get("sequence", 0)),
        str(envelope.get("settlement_id", ""))
    )
    return {"ok": true, "status": "MIGRATED_V0_TO_V1", "envelope": migrated}


static func choose_valid(primary: Dictionary, backup: Dictionary) -> Dictionary:
    if validate_envelope(primary):
        return {"ok": true, "status": "PRIMARY", "envelope": primary.duplicate(true)}
    if validate_envelope(backup):
        return {"ok": true, "status": "RECOVERED_FROM_BACKUP", "envelope": backup.duplicate(true)}
    return {"ok": false, "status": "NO_VALID_SAVE", "envelope": {}}


static func choose_loadable(primary: Dictionary, backup: Dictionary) -> Dictionary:
    var primary_result := migrate_envelope(primary)
    if bool(primary_result.get("ok", false)):
        var primary_status := "PRIMARY"
        if primary_result.get("status", "") == "MIGRATED_V0_TO_V1":
            primary_status = "MIGRATED_PRIMARY"
        return {
            "ok": true,
            "status": primary_status,
            "envelope": primary_result.get("envelope", {}).duplicate(true),
        }
    var backup_result := migrate_envelope(backup)
    if bool(backup_result.get("ok", false)):
        var backup_status := "RECOVERED_FROM_BACKUP"
        if backup_result.get("status", "") == "MIGRATED_V0_TO_V1":
            backup_status = "RECOVERED_MIGRATED_BACKUP"
        return {
            "ok": true,
            "status": backup_status,
            "envelope": backup_result.get("envelope", {}).duplicate(true),
        }
    var status := "NO_VALID_SAVE"
    if primary_result.get("status", "") == "UNSUPPORTED_NEWER_SCHEMA":
        status = "UNSUPPORTED_NEWER_SCHEMA"
    elif backup_result.get("status", "") == "UNSUPPORTED_NEWER_SCHEMA":
        status = "UNSUPPORTED_NEWER_SCHEMA"
    return {"ok": false, "status": status, "envelope": {}}


static func write_slot(slot: int, envelope: Dictionary, root: String = SAVE_ROOT) -> Dictionary:
    if slot < 0 or slot >= SLOT_COUNT:
        return {"ok": false, "status": "INVALID_SLOT"}
    if not validate_envelope(envelope):
        return {"ok": false, "status": "INVALID_ENVELOPE"}

    var root_absolute := ProjectSettings.globalize_path(root)
    var mkdir_error := DirAccess.make_dir_recursive_absolute(root_absolute)
    if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
        return {"ok": false, "status": "CREATE_DIRECTORY_FAILED", "error": mkdir_error}

    var primary := _slot_path(root, slot)
    var backup := primary + ".bak"
    var temporary := primary + ".tmp"
    var existing := read_slot(slot, root)
    if bool(existing.get("ok", false)):
        var existing_envelope: Dictionary = existing.get("envelope", {})
        var existing_sequence := int(existing_envelope.get("sequence", -1))
        var incoming_sequence := int(envelope.get("sequence", -1))
        if incoming_sequence < existing_sequence:
            return {"ok": false, "status": "STALE_SEQUENCE", "current_sequence": existing_sequence}
        if incoming_sequence == existing_sequence:
            if str(existing_envelope.get("checksum", "")) == str(envelope.get("checksum", "")):
                return {"ok": true, "status": "ALREADY_SAVED", "sequence": existing_sequence}
            return {"ok": false, "status": "SEQUENCE_CONFLICT", "current_sequence": existing_sequence}
        if str(existing.get("status", "")).begins_with("RECOVERED_"):
            if FileAccess.file_exists(primary):
                var remove_corrupt_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(primary))
                if remove_corrupt_error != OK:
                    return {"ok": false, "status": "REMOVE_CORRUPT_PRIMARY_FAILED", "error": remove_corrupt_error}
            if FileAccess.file_exists(backup):
                var restore_backup_error := DirAccess.rename_absolute(
                    ProjectSettings.globalize_path(backup),
                    ProjectSettings.globalize_path(primary)
                )
                if restore_backup_error != OK:
                    return {"ok": false, "status": "RESTORE_BACKUP_FAILED", "error": restore_backup_error}

    var temporary_file := FileAccess.open(temporary, FileAccess.WRITE)
    if temporary_file == null:
        return {"ok": false, "status": "OPEN_TEMP_FAILED", "error": FileAccess.get_open_error()}
    temporary_file.store_string(JSON.stringify(envelope, "  ", true))
    temporary_file.flush()
    temporary_file.close()

    var temporary_readback := _read_json(temporary)
    if (
        not validate_envelope(temporary_readback)
        or str(temporary_readback.get("checksum", "")) != str(envelope.get("checksum", ""))
    ):
        _remove_if_exists(temporary)
        return {"ok": false, "status": "TEMP_READBACK_FAILED"}

    if FileAccess.file_exists(backup):
        var remove_backup_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
        if remove_backup_error != OK:
            _remove_if_exists(temporary)
            return {"ok": false, "status": "REMOVE_OLD_BACKUP_FAILED", "error": remove_backup_error}

    var had_primary := FileAccess.file_exists(primary)
    if had_primary:
        var backup_error := DirAccess.rename_absolute(
            ProjectSettings.globalize_path(primary),
            ProjectSettings.globalize_path(backup)
        )
        if backup_error != OK:
            _remove_if_exists(temporary)
            return {"ok": false, "status": "BACKUP_PRIMARY_FAILED", "error": backup_error}

    var promote_error := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temporary),
        ProjectSettings.globalize_path(primary)
    )
    if promote_error != OK:
        if had_primary and FileAccess.file_exists(backup):
            DirAccess.rename_absolute(
                ProjectSettings.globalize_path(backup),
                ProjectSettings.globalize_path(primary)
            )
        _remove_if_exists(temporary)
        return {"ok": false, "status": "PROMOTE_TEMP_FAILED", "error": promote_error}

    var promoted := _read_json(primary)
    if (
        not validate_envelope(promoted)
        or str(promoted.get("checksum", "")) != str(envelope.get("checksum", ""))
    ):
        if FileAccess.file_exists(backup):
            _remove_if_exists(primary)
            DirAccess.rename_absolute(
                ProjectSettings.globalize_path(backup),
                ProjectSettings.globalize_path(primary)
            )
        return {"ok": false, "status": "PROMOTED_READBACK_FAILED"}
    return {"ok": true, "status": "SAVED", "sequence": int(envelope.get("sequence", 0))}


static func read_slot(slot: int, root: String = SAVE_ROOT) -> Dictionary:
    if slot < 0 or slot >= SLOT_COUNT:
        return {"ok": false, "status": "INVALID_SLOT", "envelope": {}}
    var primary := _slot_path(root, slot)
    return choose_loadable(_read_json(primary), _read_json(primary + ".bak"))


static func slot_metadata(slot: int, root: String = SAVE_ROOT) -> Dictionary:
    var result := read_slot(slot, root)
    if not bool(result.get("ok", false)):
        return {"slot": slot, "occupied": false, "status": result.get("status", "NO_VALID_SAVE")}
    var envelope: Dictionary = result.get("envelope", {})
    return {
        "slot": slot,
        "occupied": true,
        "status": result.get("status", "PRIMARY"),
        "sequence": int(envelope.get("sequence", 0)),
        "settlement_id": str(envelope.get("settlement_id", "")),
    }


static func clear_slot(slot: int, root: String = SAVE_ROOT) -> void:
    if slot < 0 or slot >= SLOT_COUNT:
        return
    var primary := _slot_path(root, slot)
    _remove_if_exists(primary)
    _remove_if_exists(primary + ".bak")
    _remove_if_exists(primary + ".tmp")


static func _slot_path(root: String, slot: int) -> String:
    return "%s/slot_%d.json" % [root.trim_suffix("/"), slot]


static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var json := JSON.new()
    var parse_error := json.parse(file.get_as_text())
    file.close()
    if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
        return {}
    return json.data


static func _remove_if_exists(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
