extends SceneTree

const Catalog = preload("res://game/audio/audio_catalog.gd")
const AudioLibrary = preload("res://game/audio/representative_audio_library.gd")

func _initialize() -> void:
    call_deferred("_render")

func _render() -> void:
    var normal := AudioLibrary.render_review_mix(false)
    var low := AudioLibrary.render_review_mix(true)
    var warning := AudioLibrary.render_cue(Catalog.WARNING)
    var normal_error := normal.save_to_wav("res://artifacts/w14/representative-mix.wav")
    var low_error := low.save_to_wav("res://artifacts/w14/representative-mix-low.wav")
    var warning_error := warning.save_to_wav("res://artifacts/w14/warning-cue.wav")
    if normal_error != OK or low_error != OK or warning_error != OK:
        printerr("W14_AUDIO_RENDER=FAIL")
        quit(1)
        return
    var normal_metrics := AudioLibrary.analyze(normal)
    var low_metrics := AudioLibrary.analyze(low)
    var warning_metrics := AudioLibrary.analyze(warning)
    if float(normal_metrics.get("peak", 0.0)) < 0.10 or float(low_metrics.get("peak", 0.0)) < 0.01 or float(warning_metrics.get("peak", 0.0)) < 0.10:
        printerr("W14_AUDIO_RENDER=FAIL_METRICS")
        quit(2)
        return
    print("W14_AUDIO_RENDER=PASS")
    print("W14_AUDIO_RATE=%d" % Catalog.MIX_RATE)
    print("W14_AUDIO_FORMAT=PCM16_MONO")
    print("W14_AUDIO_DURATION=%.1f" % Catalog.REVIEW_SECONDS)
    print("W14_AUDIO_LOW_GAIN_DB=-18")
    print("W14_AUDIO_NORMAL_PEAK=%.6f" % float(normal_metrics.peak))
    print("W14_AUDIO_LOW_PEAK=%.6f" % float(low_metrics.peak))
    print("W14_AUDIO_WARNING_PEAK=%.6f" % float(warning_metrics.peak))
    quit(0)
