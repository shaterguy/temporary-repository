extends SceneTree

const TEST_SUITES := [
    preload("res://tests/unit/test_save_store.gd"),
    preload("res://tests/unit/test_safe_area.gd"),
]

func _initialize() -> void:
    call_deferred("_run_tests")


func _run_tests() -> void:
    var failures: Array[String] = []
    for suite in TEST_SUITES:
        failures.append_array(suite.run())

    print("TEST_CONTRACT=foundation-v1")
    print("SUITES=%d" % TEST_SUITES.size())
    if failures.is_empty():
        print("RESULT=PASS")
        quit(0)
        return

    for failure in failures:
        printerr("FAIL: %s" % failure)
    printerr("RESULT=FAIL")
    quit(1)
