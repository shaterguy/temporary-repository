extends RefCounted

const MIX_RATE: int = 32000
const STAGE_ORDER := ["intro", "opening", "pressure", "finale", "break"]
const STAGE_SPECS := {
    "intro": {"duration":0.86,"priority":86,"cooldown":0.10,"gain_db":-4.5},
    "opening": {"duration":0.54,"priority":74,"cooldown":0.08,"gain_db":-6.0},
    "pressure": {"duration":0.62,"priority":78,"cooldown":0.08,"gain_db":-5.5},
    "finale": {"duration":0.78,"priority":92,"cooldown":0.10,"gain_db":-3.5},
    "break": {"duration":1.02,"priority":96,"cooldown":0.12,"gain_db":-3.0},
}
const PROFILES := {
    "drowned_navigator": {"stem":"nav_lamp","base_hz":73.42,"overtone":2.01,"seed":101,"phase_bias":0.12},
    "keel_bell_matron": {"stem":"bell_wake","base_hz":82.41,"overtone":1.50,"seed":131,"phase_bias":0.38},
    "prism_ossuary": {"stem":"prism_bloom","base_hz":110.0,"overtone":2.73,"seed":157,"phase_bias":0.71},
    "rootglass_colossus": {"stem":"root_crack","base_hz":65.41,"overtone":1.33,"seed":181,"phase_bias":0.22},
    "mnemonic_leviathan": {"stem":"memory_tide","base_hz":92.50,"overtone":2.21,"seed":211,"phase_bias":0.84},
    "index_regent": {"stem":"cipher_halo","base_hz":123.47,"overtone":1.76,"seed":241,"phase_bias":0.53},
    "furnace_conductor": {"stem":"signal_flare","base_hz":98.0,"overtone":2.46,"seed":271,"phase_bias":0.31},
    "trestle_widow": {"stem":"spindle_flash","base_hz":69.30,"overtone":1.91,"seed":307,"phase_bias":0.66},
    "corona_castellan": {"stem":"corona_helix","base_hz":138.59,"overtone":2.63,"seed":337,"phase_bias":0.47},
    "black_sun_reliquary": {"stem":"eclipse_collapse","base_hz":55.0,"overtone":1.618,"seed":373,"phase_bias":0.95},
}

static func boss_ids() -> Array[String]:
    var result: Array[String] = []
    for raw_id in PROFILES.keys():
        result.append(str(raw_id))
    result.sort()
    return result

static func cue_ids_for_boss(boss_id: String) -> PackedStringArray:
    var profile: Dictionary = PROFILES.get(boss_id, {})
    if profile.is_empty():
        return PackedStringArray()
    var stem := str(profile.get("stem", ""))
    var result := PackedStringArray()
    for stage in STAGE_ORDER:
        result.append("%s_%s" % [stem, str(stage)])
    return result

static func cue_spec(cue_id: String) -> Dictionary:
    for raw_boss_id in PROFILES.keys():
        var boss_id := str(raw_boss_id)
        var profile: Dictionary = PROFILES[boss_id]
        var stem := str(profile.get("stem", ""))
        for stage_index in STAGE_ORDER.size():
            var stage := str(STAGE_ORDER[stage_index])
            if cue_id != "%s_%s" % [stem, stage]:
                continue
            var stage_spec: Dictionary = STAGE_SPECS[stage]
            return {
                "cue_id": cue_id,
                "boss_id": boss_id,
                "stage": stage,
                "stage_index": stage_index,
                "category": "boss_event",
                "bus": "Warning" if stage == "finale" else "SFX",
                "duration": float(stage_spec.get("duration", 0.5)),
                "priority": int(stage_spec.get("priority", 70)),
                "cooldown": float(stage_spec.get("cooldown", 0.08)),
                "gain_db": float(stage_spec.get("gain_db", -5.0)),
                "base_hz": float(profile.get("base_hz", 82.0)),
                "overtone": float(profile.get("overtone", 2.0)),
                "seed": int(profile.get("seed", 1)),
                "phase_bias": float(profile.get("phase_bias", 0.0)),
            }
    return {}

static func is_boss_cue(cue_id: String) -> bool:
    return not cue_spec(cue_id).is_empty()

static func render_cue(cue_id: String) -> AudioStreamWAV:
    var spec := cue_spec(cue_id)
    if spec.is_empty():
        return AudioStreamWAV.new()
    var sample_count := maxi(1, roundi(float(spec.get("duration", 0.1)) * MIX_RATE))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    for index in range(sample_count):
        var t := float(index) / float(MIX_RATE)
        _write_pcm16(data, index, _sample(spec, t, index))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = MIX_RATE
    stream.stereo = false
    stream.data = data
    return stream

static func analyze_cue(cue_id: String) -> Dictionary:
    var stream := render_cue(cue_id)
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

static func _sample(spec: Dictionary, t: float, sample_index: int) -> float:
    var duration := maxf(0.01, float(spec.get("duration", 0.5)))
    if t < 0.0 or t >= duration:
        return 0.0
    var progress := clampf(t / duration, 0.0, 1.0)
    var stage_index := int(spec.get("stage_index", 0))
    var base_hz := float(spec.get("base_hz", 82.0)) * (1.0 + float(stage_index) * 0.10)
    if str(spec.get("stage", "")) == "break":
        base_hz = lerpf(base_hz * 1.75, base_hz * 0.68, progress)
    var overtone := float(spec.get("overtone", 2.0))
    var phase_bias := float(spec.get("phase_bias", 0.0))
    var attack := clampf(progress / 0.06, 0.0, 1.0)
    var release := clampf((1.0 - progress) / 0.22, 0.0, 1.0)
    var envelope := sin(PI * progress) * minf(attack, release)
    var pulse_rate := 2.2 + float(stage_index) * 0.65
    var pulse := 0.78 + sin(TAU * pulse_rate * t + phase_bias * PI) * 0.22
    var body := sin(TAU * base_hz * t + phase_bias) * 0.38
    var harmonic := sin(TAU * base_hz * overtone * t + phase_bias * 2.0) * 0.18
    var sub := sin(TAU * base_hz * 0.5 * t) * 0.11
    var transient := _noise(sample_index, int(spec.get("seed", 1)) + stage_index * 37) * exp(-18.0 * t) * (0.09 + float(stage_index) * 0.012)
    return tanh((body + harmonic + sub + transient) * 1.55) * envelope * pulse * 0.82

static func _noise(sample_index: int, seed: int) -> float:
    var value := int((sample_index * 1664525 + seed * 1013904223) & 0x7fffffff)
    return float(value % 65536) / 32767.5 - 1.0

static func _write_pcm16(data: PackedByteArray, index: int, sample: float) -> void:
    var signed := clampi(roundi(clampf(sample, -0.98, 0.98) * 32767.0), -32768, 32767)
    var encoded := signed if signed >= 0 else signed + 65536
    data[index * 2] = encoded & 255
    data[index * 2 + 1] = (encoded >> 8) & 255
