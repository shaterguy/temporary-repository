extends RefCounted

const SafeAreaScript = preload("res://platform/android/safe_area.gd")

static func run() -> Array[String]:
    var failures: Array[String] = []
    var margins := SafeAreaScript.margins_for(
        Vector2i(2400, 1080),
        Vector2i(1200, 540),
        Rect2i(80, 40, 2240, 1000)
    )
    if margins != Vector4i(40, 20, 40, 20):
        failures.append("safe-area scaling produced %s" % margins)

    var zero := SafeAreaScript.margins_for(
        Vector2i(0, 1080),
        Vector2i(1200, 540),
        Rect2i(0, 0, 2400, 1080)
    )
    if zero != Vector4i.ZERO:
        failures.append("invalid window size did not return zero margins")
    return failures
