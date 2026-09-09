extends RefCounted

const TutorialScript = preload("res://game/ui/first_expedition_tutorial.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var tutorial = TutorialScript.new()

    if tutorial.current_step() != TutorialScript.STEP_SLOT:
        failures.append("W15 tutorial did not start at save-slot guidance")

    tutorial.apply_observation({"slot_opened": true})
    if tutorial.current_step() != TutorialScript.STEP_DEPART:
        failures.append("W15 tutorial did not advance from slot to route choice")

    tutorial.apply_observation({"departed": true, "phase_switched": true})
    if tutorial.current_step() != TutorialScript.STEP_MOVE:
        failures.append("W15 tutorial skipped movement when a later milestone occurred early")

    tutorial.apply_observation({"moved": true})
    if tutorial.current_step() != TutorialScript.STEP_CIRCUIT:
        failures.append("W15 tutorial did not advance from movement to circuit guidance")

    tutorial.apply_observation({"circuit_activated": true})
    if tutorial.current_step() != TutorialScript.STEP_SETTLE:
        failures.append("W15 tutorial did not preserve an already observed phase switch")

    tutorial.apply_observation({
        "slot_opened": false,
        "departed": false,
        "moved": false,
        "circuit_activated": false,
        "phase_switched": false,
    })
    if tutorial.current_step() != TutorialScript.STEP_SETTLE:
        failures.append("W15 tutorial milestone latches regressed on later false observations")

    tutorial.apply_observation({"settled": true})
    var complete: Dictionary = tutorial.status_snapshot()
    if tutorial.current_step() != TutorialScript.STEP_COMPLETE or not bool(complete.get("complete", false)):
        failures.append("W15 tutorial did not complete after first expedition settlement")
    if not str(tutorial.prompt_text()).is_empty():
        failures.append("completed W15 tutorial continued to emit onboarding copy")

    tutorial.free()
    return failures
