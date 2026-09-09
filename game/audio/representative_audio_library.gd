extends RefCounted

const Catalog = preload("res://game/audio/audio_catalog.gd")
const MusicSynth = preload("res://game/audio/audio_music_synth.gd")
const SfxSynth = preload("res://game/audio/audio_sfx_synth.gd")

static func cue_ids() -> PackedStringArray:
    return Catalog.cue_ids()

static func cue_spec(cue_id: String) -> Dictionary:
    return Catalog.cue_spec(cue_id)

static func render_cue(cue_id: String) -> AudioStreamWAV:
    var spec := cue_spec(cue_id)
    if spec.is_empty():
        return AudioStreamWAV.new()
    var sample_count := maxi(1, roundi(float(spec.get("duration", 0.1)) * Catalog.MIX_RATE))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    for index in range(sample_count):
        var time := float(index) / float(Catalog.MIX_RATE)
        _write_pcm16(data, index, _sample(cue_id, time, index))
    return _stream(data, sample_count, bool(spec.get("loop", false)))

static func render_review_mix(low_volume: bool = false) -> AudioStreamWAV:
    var sample_count := roundi(Catalog.REVIEW_SECONDS * Catalog.MIX_RATE)
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    var master := Catalog.LOW_REVIEW_GAIN if low_volume else 1.0
    for index in range(sample_count):
        var time := float(index) / float(Catalog.MIX_RATE)
        var value := _sample(Catalog.REGION, fmod(time, Catalog.MUSIC_SECONDS), index) * 0.52
        value += _sample(Catalog.TENSION, fmod(time, Catalog.MUSIC_SECONDS), index + 211) * 0.38 * _window(time, 3.2, 5.0, 10.0, 12.2)
        value += _sample(Catalog.BOSS, fmod(time, Catalog.MUSIC_SECONDS), index + 997) * 0.46 * _window(time, 9.0, 10.5, 14.8, 16.0)
        value += _scheduled(Catalog.COMBAT, time, 2.0, index) * 0.72
        value += _scheduled(Catalog.COMBAT, time, 3.15, index + 3) * 0.68
        value += _scheduled(Catalog.COMBAT, time, 4.35, index + 7) * 0.66
        value += _scheduled(Catalog.CIRCUIT, time, 6.05, index + 11) * 0.78
        value += _scheduled(Catalog.WARNING, time, 8.10, index + 13) * 0.92
        value += _scheduled(Catalog.WARNING, time, 10.25, index + 17) * 0.96
        value += _scheduled(Catalog.COMBAT, time, 11.15, index + 19) * 0.62
        value += _scheduled(Catalog.COMBAT, time, 11.75, index + 23) * 0.60
        value += _scheduled(Catalog.COMBAT, time, 12.35, index + 29) * 0.58
        value += _scheduled(Catalog.REWARD, time, 16.10, index + 31) * 0.88
        _write_pcm16(data, index, tanh(value * 0.92) * master)
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

static func _sample(cue_id: String, time: float, sample_index: int) -> float:
    match cue_id:
        Catalog.REGION: return MusicSynth.region(time, sample_index)
        Catalog.TENSION: return MusicSynth.tension(time, sample_index)
        Catalog.BOSS: return MusicSynth.boss(time, sample_index)
        Catalog.COMBAT: return SfxSynth.combat(time, sample_index)
        Catalog.CIRCUIT: return SfxSynth.circuit(time, sample_index)
        Catalog.WARNING: return SfxSynth.warning(time, sample_index)
        Catalog.REWARD: return SfxSynth.reward(time, sample_index)
    return 0.0

static func _scheduled(cue_id: String, time: float, start: float, sample_index: int) -> float:
    var local := time - start
    var duration := float(cue_spec(cue_id).get("duration", 0.0))
    if local < 0.0 or local >= duration:
        return 0.0
    return _sample(cue_id, local, sample_index)

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
