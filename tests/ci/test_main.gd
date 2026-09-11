extends SceneTree

const TEST_SUITES := [
    preload("res://tests/unit/test_save_store.gd"),
    preload("res://tests/unit/test_safe_area.gd"),
    preload("res://tests/unit/test_combat_model.gd"),
    preload("res://tests/unit/test_swarm_foundation.gd"),
    preload("res://tests/unit/test_ark_route.gd"),
    preload("res://tests/unit/test_light_circuit.gd"),
    preload("res://tests/unit/test_phase_battlefield.gd"),
    preload("res://tests/unit/test_causal_weapon.gd"),
    preload("res://tests/unit/test_tactical_echo.gd"),
    preload("res://tests/unit/test_disclosed_doctrine.gd"),
    preload("res://tests/unit/test_world_campaign.gd"),
    preload("res://tests/unit/test_campaign_runtime.gd"),
    preload("res://tests/unit/test_runtime_state_codec.gd"),
    preload("res://tests/unit/test_representative_art.gd"),
    preload("res://tests/unit/test_representative_audio.gd"),
    preload("res://tests/unit/test_vertical_slice_tutorial.gd"),
    preload("res://tests/unit/test_character_expansion.gd"),
    preload("res://tests/unit/test_weapon_relic_expansion.gd"),
    preload("res://tests/unit/test_medieval_rebuild_world.gd"),
    preload("res://tests/unit/test_medieval_rebuild_runtime.gd"),
]
const TEST_SUITE_NAMES := [
    "save_store",
    "safe_area",
    "combat_model",
    "swarm_foundation",
    "ark_route",
    "light_circuit",
    "phase_battlefield",
    "causal_weapon",
    "tactical_echo",
    "disclosed_doctrine",
    "world_campaign",
    "campaign_runtime",
    "runtime_state_codec",
    "representative_art",
    "representative_audio",
    "vertical_slice_tutorial",
    "character_expansion",
    "weapon_relic_expansion",
    "medieval_rebuild_world",
    "medieval_rebuild_runtime",
]
const FAST_TEST_WATCHDOG_SECONDS: float = 30.0

func _initialize() -> void:
    var watchdog := create_timer(FAST_TEST_WATCHDOG_SECONDS, true)
    watchdog.timeout.connect(_on_watchdog_timeout)
    call_deferred("_run_tests")

func _run_tests() -> void:
    var failures: Array[String] = []
    for index in range(TEST_SUITES.size()):
        var suite = TEST_SUITES[index]
        var suite_name := str(TEST_SUITE_NAMES[index])
        print("SUITE_START=%s" % suite_name)
        failures.append_array(suite.run())
        print("SUITE_DONE=%s" % suite_name)
    print("TEST_CONTRACT=r04-medieval-rebuild-field-v4")
    print("SUITES=%d" % TEST_SUITES.size())
    if failures.is_empty():
        print("RESULT=PASS")
        quit(0)
        return
    for failure in failures:
        printerr("FAIL: %s" % failure)
    printerr("RESULT=FAIL")
    quit(1)

func _on_watchdog_timeout() -> void:
    printerr("RESULT=FAIL_FAST_TEST_WATCHDOG")
    quit(2)
