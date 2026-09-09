extends RefCounted

const CampaignRuntimeScript = preload("res://game/world/campaign_runtime.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const TacticalEchoModelScript = preload("res://game/systems/echo/tactical_echo_model.gd")
const TEST_ROOT: String = "user://ci_w12_campaign_runtime"


static func run() -> Array[String]:
    var failures: Array[String] = []
    _clear_all()

    var runtime = CampaignRuntimeScript.new(TEST_ROOT)
    var created := runtime.start_new(0, 424242)
    if not bool(created.get("ok", false)):
        failures.append("campaign runtime could not create a new save slot")
        _clear_all()
        return failures
    if int(created.get("sequence", 0)) != 1:
        failures.append("new campaign did not persist its initial checkpoint")
    var metadata := runtime.slot_metadata_all()
    if metadata.size() != SaveStoreScript.SLOT_COUNT:
        failures.append("campaign runtime did not expose exactly three slots")
    elif not bool(metadata[0].get("occupied", false)) or bool(metadata[1].get("occupied", true)):
        failures.append("three-slot metadata did not distinguish occupied and empty slots")

    var options: Array[Dictionary] = runtime.world.departure_options()
    if options.size() != 2:
        failures.append("hub did not expose two meaningful departure choices")
    else:
        var begin := runtime.begin_expedition(str(options[0].get("choice_id", "")))
        if not bool(begin.get("ok", false)):
            failures.append("hub choice did not enter an expedition transactionally")
        else:
            var runtime_state := {
                "schema": "w12-runtime-state-v1",
                "tick": 1,
                "position": [640.0, 360.0],
                "nested": {"phase": "material", "enemy_count": 3},
            }
            var checkpoint := runtime.checkpoint("fixture", runtime_state)
            if not bool(checkpoint.get("ok", false)):
                failures.append("active expedition checkpoint was not persisted")

            var mirror = CampaignRuntimeScript.new(TEST_ROOT)
            var loaded := mirror.load_slot(0)
            if not bool(loaded.get("ok", false)):
                failures.append("saved active expedition did not reload")
            else:
                var resume: Dictionary = loaded.get("resume", {})
                var resumed_state: Dictionary = resume.get("runtime_state", {})
                if int(resumed_state.get("tick", -1)) != 1:
                    failures.append("suspended expedition runtime state did not survive a disk reload")

                var echo_record := TacticalEchoModelScript.make_record(
                    "w12-runtime-echo",
                    "shade_halo",
                    1.0,
                    [{
                        "time": 0.25,
                        "type": "move",
                        "offset": [16.0, 0.0],
                        "phase": "material",
                    }],
                    "completed"
                )
                if not bool(TacticalEchoModelScript.validate_record(echo_record).get("valid", false)):
                    failures.append("runtime bridge fixture did not produce a valid tactical echo")
                var settlement := mirror.settle_current(
                    "success",
                    {
                        "total_actions": 20,
                        "ranged_actions": 16,
                        "clustered_actions": 4,
                    },
                    echo_record
                )
                if not bool(settlement.get("ok", false)):
                    failures.append("expedition settlement was not atomically saved")
                else:
                    if mirror.world.segment_index != 1 or mirror.world.state != "HUB":
                        failures.append("successful settlement did not return to hub with world progression")
                    if str(mirror.current_doctrine_plan().get("doctrine_id", "")) != "cover_advance":
                        failures.append("W11 doctrine bridge did not derive the next expedition plan")
                    if str(mirror.current_echo_record().get("record_id", "")) != "w12-runtime-echo":
                        failures.append("W10 tactical echo bridge did not persist the prior expedition record")

                    var settled_read := SaveStoreScript.read_slot(0, TEST_ROOT)
                    var settled_envelope: Dictionary = settled_read.get("envelope", {})
                    if str(settled_envelope.get("settlement_id", "")).is_empty():
                        failures.append("settlement save did not carry an idempotency key")
                    var settled_salvage: int = int(mirror.world.salvage)
                    var settled_segment: int = int(mirror.world.segment_index)
                    var reloaded = CampaignRuntimeScript.new(TEST_ROOT)
                    if not bool(reloaded.load_slot(0).get("ok", false)):
                        failures.append("committed settlement did not reload")
                    elif reloaded.world.salvage != settled_salvage or reloaded.world.segment_index != settled_segment:
                        failures.append("settlement reward/progression changed after restart")

                    var next_options: Array[Dictionary] = mirror.world.departure_options()
                    var next_begin := mirror.begin_expedition(str(next_options[0].get("choice_id", "")))
                    if not bool(next_begin.get("ok", false)):
                        failures.append("campaign could not continue into the next expedition")
                    else:
                        var unsafe_checkpoint := mirror.checkpoint(
                            "unsafe_fixture",
                            {"position": Vector2(1.0, 2.0)}
                        )
                        if str(unsafe_checkpoint.get("status", "")) != "RUNTIME_STATE_NOT_JSON_SAFE":
                            failures.append("non-JSON runtime state was allowed into the save envelope")

                        var first_backup_checkpoint := mirror.checkpoint(
                            "backup_a",
                            {"schema": "w12-runtime-state-v1", "tick": 10}
                        )
                        var second_backup_checkpoint := mirror.checkpoint(
                            "backup_b",
                            {"schema": "w12-runtime-state-v1", "tick": 11}
                        )
                        if not bool(first_backup_checkpoint.get("ok", false)) or not bool(second_backup_checkpoint.get("ok", false)):
                            failures.append("backup recovery fixture could not create consecutive checkpoints")
                        else:
                            var primary_path := "%s/slot_0.json" % TEST_ROOT
                            var corrupt := FileAccess.open(primary_path, FileAccess.WRITE)
                            if corrupt == null:
                                failures.append("runtime backup recovery fixture could not corrupt primary")
                            else:
                                corrupt.store_string("{corrupt")
                                corrupt.close()
                                var recovered_runtime = CampaignRuntimeScript.new(TEST_ROOT)
                                var recovered := recovered_runtime.load_slot(0)
                                if not bool(recovered.get("ok", false)):
                                    failures.append("runtime campaign did not recover the prior atomic backup")
                                elif str(recovered.get("status", "")) != "RECOVERED_FROM_BACKUP":
                                    failures.append("runtime backup recovery status was not explicit")
                                else:
                                    var recovered_resume: Dictionary = recovered.get("resume", {})
                                    var recovered_state: Dictionary = recovered_resume.get("runtime_state", {})
                                    if int(recovered_state.get("tick", -1)) != 10:
                                        failures.append("runtime backup recovery did not restore the prior valid checkpoint")

    var legacy_payload := {
        "schema": "lanternfall-world-v0",
        "seed": 99,
        "chapter": 1,
        "credits": 18,
        "failures": 0,
        "rescued": 2,
        "lighthouses": 1,
        "routes": 0,
    }
    var legacy_envelope := {
        "schema_version": 0,
        "sequence": 2,
        "settlement_id": "legacy-world",
        "payload": legacy_payload,
    }
    legacy_envelope["checksum"] = SaveStoreScript.checksum_for(legacy_envelope)
    var legacy_path := "%s/slot_1.json" % TEST_ROOT
    var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
    if legacy_file == null:
        failures.append("legacy campaign fixture could not be written")
    else:
        legacy_file.store_string(JSON.stringify(legacy_envelope, "  ", true))
        legacy_file.close()
        var migrated_runtime = CampaignRuntimeScript.new(TEST_ROOT)
        var migrated := migrated_runtime.load_slot(1)
        if not bool(migrated.get("ok", false)):
            failures.append("legacy campaign payload did not migrate through the runtime loader")
        elif migrated_runtime.world.segment_index != 1 or migrated_runtime.world.salvage != 18:
            failures.append("legacy campaign migration changed progression or salvage")

    _clear_all()
    return failures


static func _clear_all() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)
