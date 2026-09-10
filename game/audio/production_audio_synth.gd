extends RefCounted

const Catalog = preload("res://game/audio/production_audio_catalog.gd")
const Common = preload("res://game/audio/audio_music_synth.gd")

static func render_cue(cue_id: String) -> AudioStreamWAV:
    var spec := Catalog.cue_spec(cue_id)
    if spec.is_empty():
        return AudioStreamWAV.new()
    var sample_count := maxi(1, roundi(float(spec.get("duration", 0.1)) * Catalog.MIX_RATE))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    for index in range(sample_count):
        var t := float(index) / float(Catalog.MIX_RATE)
        _write_pcm16(data, index, _sample(spec, t, index))
    return _stream(data, sample_count, bool(spec.get("loop", false)))

static func render_review_mix(region_id: String, boss_id: String, weapon_ids: Array[String], low_volume: bool = false) -> AudioStreamWAV:
    var sample_count := roundi(Catalog.REVIEW_SECONDS * Catalog.MIX_RATE)
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    var bed_id := Catalog.region_music_cue(region_id, "bed")
    var tension_id := Catalog.region_music_cue(region_id, "tension")
    var boss_cue_id := Catalog.boss_music_cue(boss_id)
    var music_gain := Catalog.LOW_REVIEW_GAIN if low_volume else 1.0
    var sfx_gain := Catalog.LOW_REVIEW_GAIN if low_volume else 1.0
    var warning_gain := Catalog.LOW_WARNING_GAIN if low_volume else 1.0
    for index in range(sample_count):
        var time := float(index) / float(Catalog.MIX_RATE)
        var value := _sample_by_id(bed_id, fmod(time, Catalog.MUSIC_SECONDS), index) * 0.52 * music_gain
        value += _sample_by_id(tension_id, fmod(time, Catalog.MUSIC_SECONDS), index + 211) * 0.40 * _window(time, 2.6, 3.6, 7.2, 8.2) * music_gain
        value += _sample_by_id(boss_cue_id, fmod(time, Catalog.MUSIC_SECONDS), index + 733) * 0.50 * _window(time, 6.8, 7.6, 10.7, 11.5) * music_gain
        for weapon_index in range(weapon_ids.size()):
            var start := 1.35 + float(weapon_index) * 1.15
            value += _scheduled(Catalog.weapon_cue_id(weapon_ids[weapon_index]), time, start, index + weapon_index * 17) * 0.72 * sfx_gain
        value += _scheduled(Catalog.ui_cue_id("confirm"), time, 0.55, index + 991) * 0.70 * sfx_gain
        value += _scheduled(Catalog.ui_cue_id("focus"), time, 5.85, index + 1009) * 0.65 * sfx_gain
        value += _scheduled(Catalog.ui_cue_id("reject"), time, 6.42, index + 1049) * 0.88 * warning_gain
        value += _scheduled(Catalog.ui_cue_id("reward"), time, 11.05, index + 1093) * 0.82 * sfx_gain
        _write_pcm16(data, index, tanh(value * 0.90))
    return _stream(data, sample_count, false)

static func analyze(stream: AudioStreamWAV) -> Dictionary:
    var data := stream.data
    if data.is_empty() or data.size() % 2 != 0:
        return {"samples":0,"peak":0.0,"rms":0.0,"nonzero_ratio":0.0}
    var count := data.size() / 2
    var peak := 0.0
    var sum_squares := 0.0
    var nonzero := 0
    for index in range(count):
        var raw := int(data[index * 2]) | (int(data[index * 2 + 1]) << 8)
        if raw >= 32768:
            raw -= 65536
        var value := float(raw) / 32768.0
        peak = maxf(peak, absf(value))
        sum_squares += value * value
        if absf(value) > 0.0005:
            nonzero += 1
    return {
        "samples": count,
        "peak": peak,
        "rms": sqrt(sum_squares / maxf(1.0, float(count))),
        "nonzero_ratio": float(nonzero) / maxf(1.0, float(count)),
    }

static func _sample_by_id(cue_id: String, t: float, sample_index: int) -> float:
    var spec := Catalog.cue_spec(cue_id)
    if spec.is_empty():
        return 0.0
    return _sample(spec, t, sample_index)

static func _sample(spec: Dictionary, t: float, sample_index: int) -> float:
    match str(spec.get("category", "")):
        "region_music":
            return _region_music(spec, t, sample_index)
        "boss_music":
            return _boss_music(spec, t, sample_index)
        "weapon":
            return _weapon(spec, t, sample_index)
        "ui":
            return _ui(spec, t, sample_index)
    return 0.0

static func _region_music(spec: Dictionary, t: float, sample_index: int) -> float:
    var base_hz := float(spec.get("base_hz", 55.0))
    var accent_hz := float(spec.get("accent_hz", 293.66))
    var pulse_hz := float(spec.get("pulse_hz", 1.0))
    var overtone := float(spec.get("overtone", 2.0))
    var seed := int(spec.get("seed", 1))
    var beat := fmod(t * pulse_hz, 1.0)
    var pulse := exp(-5.5 * beat)
    var body := sin(TAU * base_hz * t) * 0.18 + sin(TAU * base_hz * 0.5 * t) * 0.10
    var glass := sin(TAU * accent_hz * t) * pulse * 0.13
    var harmonic := sin(TAU * base_hz * overtone * t + 0.35) * 0.08
    var texture := Common.noise(sample_index, seed) * 0.018
    if str(spec.get("layer", "bed")) == "tension":
        body *= 0.82 + pulse * 0.45
        harmonic += sin(TAU * (accent_hz * 1.5) * t) * pulse * 0.12
        texture *= 2.2
    return tanh((body + glass + harmonic + texture) * 1.45) * 0.62

static func _boss_music(spec: Dictionary, t: float, sample_index: int) -> float:
    var base_hz := float(spec.get("base_hz", 73.42))
    var overtone := float(spec.get("overtone", 2.0))
    var phase_bias := float(spec.get("phase_bias", 0.0))
    var seed := int(spec.get("seed", 1))
    var pulse := exp(-4.0 * fmod(t * 0.75, 1.0))
    var body := sin(TAU * base_hz * t + phase_bias) * 0.24
    body += sin(TAU * base_hz * 0.5 * t) * 0.14
    body += sin(TAU * base_hz * overtone * t + phase_bias * 2.0) * 0.13
    var strike := sin(TAU * base_hz * 3.0 * t) * pulse * 0.09
    var undertow := Common.noise(sample_index, seed + 97) * pulse * 0.035
    return tanh((body + strike + undertow) * 1.55) * 0.66

static func _weapon(spec: Dictionary, t: float, sample_index: int) -> float:
    var duration := float(spec.get("duration", 0.42))
    if t < 0.0 or t >= duration:
        return 0.0
    var progress := clampf(t / duration, 0.0, 1.0)
    var env := Common.attack_release(t, duration, 0.006, minf(0.24, duration * 0.48))
    var base_hz := float(spec.get("base_hz", 620.0))
    var accent_hz := float(spec.get("accent_hz", 1200.0))
    var sweep := lerpf(base_hz * 1.30, base_hz * 0.42, progress)
    var body := sin(TAU * sweep * t) * 0.33
    var edge := sin(TAU * accent_hz * t) * exp(-15.0 * t) * 0.17
    var transform_color := 0.0
    match str(spec.get("transform", "")):
        "shadow_fracture": transform_color = sin(TAU * base_hz * 0.50 * t) * 0.12
        "circuit_split": transform_color = sin(TAU * base_hz * 2.02 * t) * 0.10
        "ark_resonance": transform_color = sin(TAU * base_hz * 0.75 * t) * 0.11
        "phase_afterglow": transform_color = sin(TAU * base_hz * 1.50 * t) * 0.10
        "snare_resonance": transform_color = sin(TAU * base_hz * 0.66 * t) * 0.10
        "ember_mark": transform_color = sin(TAU * base_hz * 1.25 * t) * 0.08
        "ricochet_once": transform_color = sin(TAU * base_hz * 2.50 * t) * 0.08
        "material_anchor": transform_color = sin(TAU * base_hz * 0.80 * t) * 0.09
    var transient := Common.noise(sample_index, int(spec.get("seed", 1))) * exp(-25.0 * t) * 0.22
    return tanh((body + edge + transform_color + transient) * 1.70) * env * 0.72

static func _ui(spec: Dictionary, t: float, sample_index: int) -> float:
    var duration := float(spec.get("duration", 0.2))
    if t < 0.0 or t >= duration:
        return 0.0
    var style := int(spec.get("style", 0))
    var progress := clampf(t / duration, 0.0, 1.0)
    var env := Common.attack_release(t, duration, 0.004, minf(0.16, duration * 0.5))
    var base_hz := 420.0 + float(style) * 72.0
    if style == 2:
        base_hz = lerpf(620.0, 360.0, progress)
    elif style == 4:
        base_hz = 760.0
    elif style == 5:
        base_hz = 520.0 + floor(progress * 4.0) * 105.0
    var chime := sin(TAU * base_hz * t) * 0.28 + sin(TAU * base_hz * 2.01 * t) * 0.10
    var anchor := sin(TAU * 110.0 * t) * (0.14 if style == 4 else 0.04)
    var click := Common.noise(sample_index, int(spec.get("seed", 1))) * exp(-30.0 * t) * 0.09
    if style == 4:
        var double_pulse := maxf(Common.pulse(t, 0.01, 0.18), Common.pulse(t, 0.25, 0.44))
        return tanh((chime + anchor + click) * 1.75) * double_pulse * 0.82
    return tanh((chime + anchor + click) * 1.45) * env * 0.68

static func _scheduled(cue_id: String, time: float, start: float, sample_index: int) -> float:
    var local := time - start
    var spec := Catalog.cue_spec(cue_id)
    var duration := float(spec.get("duration", 0.0))
    if spec.is_empty() or local < 0.0 or local >= duration:
        return 0.0
    return _sample(spec, local, sample_index)

static func _window(time: float, a: float, b: float, c: float, d: float) -> float:
    if time <= a or time >= d:
        return 0.0
    if time < b:
        return _smooth((time - a) / maxf(0.001, b - a))
    if time <= c:
        return 1.0
    return 1.0 - _smooth((time - c) / maxf(0.001, d - c))

static func _smooth(value: float) -> float:
    var x := clampf(value, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)

static func _stream(data: PackedByteArray, sample_count: int, looped: bool) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = Catalog.MIX_RATE
    stream.stereo = false
    stream.data = data
    if looped:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_begin = 0
        stream.loop_end = sample_count
    return stream

static func _write_pcm16(data: PackedByteArray, index: int, sample: float) -> void:
    var signed := clampi(roundi(clampf(sample, -0.98, 0.98) * 32767.0), -32768, 32767)
    var encoded := signed if signed >= 0 else signed + 65536
    data[index * 2] = encoded & 255
    data[index * 2 + 1] = (encoded >> 8) & 255
