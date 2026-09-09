extends RefCounted

static func region(t: float, sample_index: int) -> float:
    var beat := fmod(t, 1.0)
    var notes := [293.66, 349.23, 440.0, 349.23]
    var note := float(notes[int(floor(t)) % notes.size()])
    var motor := sin(TAU * 55.0 * t) * 0.13 + sin(TAU * 110.0 * t) * 0.10
    var pad := sin(TAU * 146.83 * t) * 0.12 + sin(TAU * 174.61 * t) * 0.08
    var bell := sin(TAU * note * t) * exp(-5.5 * beat) * 0.16
    return tanh((motor + pad + bell + noise(sample_index, 17) * 0.018) * 1.25) * 0.58

static func tension(t: float, sample_index: int) -> float:
    var pulse := exp(-7.0 * fmod(t * 2.0, 1.0))
    var low := sin(TAU * 73.42 * t) * 0.22 + sin(TAU * 146.83 * t) * 0.08
    var metal := sin(TAU * (660.0 + 50.0 * sin(TAU * 0.5 * t)) * t) * pulse * 0.11
    return tanh((low * (0.55 + pulse * 0.45) + metal + noise(sample_index, 41) * pulse * 0.06) * 1.45) * 0.55

static func boss(t: float, sample_index: int) -> float:
    var hit := exp(-3.2 * fmod(t, 2.0))
    var body := sin(TAU * 49.0 * t) * 0.25 + sin(TAU * 73.42 * t) * 0.12
    body += sin(TAU * 98.0 * t + sin(TAU * 1.5 * t) * 0.35) * 0.15
    var strike := (sin(TAU * 196.0 * t) + sin(TAU * 294.0 * t) * 0.55) * hit * 0.13
    return tanh((body + strike + noise(sample_index, 73) * hit * 0.045) * 1.35) * 0.60

static func attack_release(t: float, duration: float, attack: float, release: float) -> float:
    return clampf(t / maxf(0.001, attack), 0.0, 1.0) * clampf((duration - t) / maxf(0.001, release), 0.0, 1.0)

static func pulse(t: float, start: float, finish: float) -> float:
    if t < start or t > finish:
        return 0.0
    return attack_release(t - start, finish - start, 0.008, 0.08)

static func noise(sample_index: int, salt: int) -> float:
    var value := (sample_index * 1103515245 + salt * 12345 + 1013904223) & 0x7fffffff
    value = ((value >> 11) ^ value) & 0x7fffffff
    return float(value % 65536) / 32767.5 - 1.0
