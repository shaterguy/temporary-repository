extends RefCounted

const Catalog = preload("res://game/audio/audio_catalog.gd")
const AudioLibrary = preload("res://game/audio/representative_audio_library.gd")
const AudioDirectorScript = preload("res://game/audio/audio_director.gd")

func run() -> Array[String]:
    var failures: Array[String] = []
    _expect(Catalog.cue_ids().size() == 7, "W14 must expose seven representative audio identities", failures)
    _expect(int(Catalog.cue_spec(Catalog.WARNING).priority) > int(Catalog.cue_spec(Catalog.COMBAT).priority), "warning priority must exceed combat priority", failures)
    _expect(float(Catalog.cue_spec(Catalog.WARNING).gain_db) > float(Catalog.cue_spec(Catalog.COMBAT).gain_db), "warning gain must retain salience over combat", failures)
    _expect(AudioDirectorScript.MAX_SFX_VOICES == 8, "SFX voice pool must remain bounded", failures)

    for cue_id in Catalog.cue_ids():
        var spec := Catalog.cue_spec(cue_id)
        _expect(not spec.is_empty(), "missing cue spec: %s" % cue_id, failures)
        var stream := AudioLibrary.render_cue(cue_id)
        _expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s must render PCM16" % cue_id, failures)
        _expect(stream.mix_rate == Catalog.MIX_RATE, "%s sample rate mismatch" % cue_id, failures)
        _expect(not stream.stereo, "%s W14 runtime stream must be mono" % cue_id, failures)
        var metrics := AudioLibrary.analyze(stream)
        _expect(int(metrics.samples) >= roundi(float(spec.duration) * Catalog.MIX_RATE) - 1, "%s duration is too short" % cue_id, failures)
        _expect(float(metrics.peak) >= 0.08, "%s peak is effectively silent" % cue_id, failures)
        _expect(float(metrics.rms) >= 0.01, "%s RMS is effectively silent" % cue_id, failures)
        _expect(float(metrics.nonzero_ratio) >= 0.20, "%s contains too much silence for its identity" % cue_id, failures)
        if bool(spec.loop):
            _expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s music layer must loop" % cue_id, failures)

    var director = AudioDirectorScript.new()
    var settings: Dictionary = director.settings_snapshot()
    _expect(settings.has("music") and settings.has("sfx") and settings.has("vibration"), "music/SFX/vibration controls must remain independent", failures)
    director.free()
    return failures

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
