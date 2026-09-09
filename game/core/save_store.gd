class_name SaveStore
extends RefCounted

const BuildIdentityScript = preload("res://game/core/build_identity.gd")
const SAVE_ROOT: String = "user://saves"
const SLOT_COUNT: int = 3

static func checksum_for(envelope: Dictionary) -> String:
    var normalized := envelope.duplicate(true)
    normalized.erase("checksum")
    var context := HashingContext.new()
    var start_error := context.start(HashingContext.HASH_SHA256)
    if start_error != OK:
        return ""
    context.update(JSON.stringify(normalized, "", true).to_utf8_buffer())
    return context.finish().hex_encode()


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
    if envelope.get("schema_version", -1) != BuildIdentityScript.SAVE_SCHEMA_VERSION:
        return false
    if int(envelope.get("sequence", -1)) < 0:
        return false
    if typeof(envelope.get("settlement_id", "")) != TYPE_STRING:
        return false
    if typeof(envelope.get("payload", null)) != TYPE_DICTIONARY:
        return false
    var expected_checksum := str(envelope.get("checksum", ""))
    if expected_checksum.is_empty():
        return false
    return checksum_for(envelope) == expected_checksum


static func choose_valid(primary: Dictionary, backup: Dictionary) -> Dictionary:
    if validate_envelope(primary):
        return {"ok": true, "status": "PRIMARY", "envelope": primary.duplicate(true)}
    if validate_envelope(backup):
        return {"ok": true, "status": "RECOVERED_FROM_BACKUP", "envelope": backup.duplicate(true)}
    return {"ok": false, "status": "NO_VALID_SAVE", "envelope": {}}


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
    var temporary_file := FileAccess.open(temporary, FileAccess.WRITE)
    if temporary_file == null:
        return {"ok": false, "status": "OPEN_TEMP_FAILED", "error": FileAccess.get_open_error()}
    temporary_file.store_string(JSON.stringify(envelope, "  ", true))
    temporary_file.flush()
    temporary_file.close()

    var temporary_readback := _read_json(temporary)
    if not validate_envelope(temporary_readback):
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

    return {"ok": true, "status": "SAVED"}


static func read_slot(slot: int, root: String = SAVE_ROOT) -> Dictionary:
    if slot < 0 or slot >= SLOT_COUNT:
        return {"ok": false, "status": "INVALID_SLOT", "envelope": {}}
    var primary := _slot_path(root, slot)
    return choose_valid(_read_json(primary), _read_json(primary + ".bak"))


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
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed


static func _remove_if_exists(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
