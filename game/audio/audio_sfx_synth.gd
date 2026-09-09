extends RefCounted

const Common = preload("res://game/audio/audio_music_synth.gd")

static func combat(t: float, sample_index: int) -> float:
    if t < 0.0 or t >= 0.42:
        return 0.0
    var env := Common.attack_release(t, 0.42, 0.008, 0.24)
    var sweep := lerpf(920.0, 135.0, clampf(t / 0.42, 0.0, 1.0))
    var body := sin(TAU * sweep * t) * 0.34
    var metal := sin(TAU * 1760.0 * t) * exp(-18.0 * t) * 0.20
    var transient := Common.noise(sample_index, 103) * exp(-28.0 * t) * 0.24
    return tanh((body + metal + transient) * 1.65) * env * 0.72

static func circuit(t: float, sample_index: int) -> float:
    if t < 0.0 or t >= 0.82:
        return 0.0
    var notes := [220.0, 329.63, 440.0, 659.25]
    var step := mini(3, int(floor(t / 0.18)))
    var note := float(notes[step])
    var local := fmod(t, 0.18)
    var sparkle := (sin(TAU * note * t) * 0.27 + sin(TAU * note * 2.01 * t) * 0.11) * exp(-2.0 * local)
    var bloom := sin(TAU * 110.0 * t) * sin(PI * clampf(t / 0.82, 0.0, 1.0)) * 0.12
    var shimmer := Common.noise(sample_index, 131) * exp(-6.0 * local) * 0.025
    return tanh((sparkle + bloom + shimmer) * 1.55) * Common.attack_release(t, 0.82, 0.018, 0.22) * 0.68

static func warning(t: float, sample_index: int) -> float:
    if t < 0.0 or t >= 1.0:
        return 0.0
    var env := maxf(Common.pulse(t, 0.02, 0.28), Common.pulse(t, 0.43, 0.72))
    var carrier := sin(TAU * 880.0 * t) * 0.24 + sin(TAU * 660.0 * t) * 0.18
    var anchor := sin(TAU * 110.0 * t) * 0.16
    return tanh((carrier + anchor + Common.noise(sample_index, 179) * 0.045) * 1.9) * env * 0.78

static func reward(t: float, sample_index: int) -> float:
    if t < 0.0 or t >= 1.18:
        return 0.0
    var notes := [392.0, 523.25, 659.25, 783.99]
    var step := mini(3, int(floor(t / 0.24)))
    var local := fmod(t, 0.24)
    var note := float(notes[step])
    var chime := sin(TAU * note * t) * 0.28 + sin(TAU * note * 2.0 * t) * 0.09
    var air := Common.noise(sample_index, 223) * exp(-10.0 * local) * 0.025
    var env := exp(-4.2 * local) * Common.attack_release(t, 1.18, 0.01, 0.20)
    return tanh((chime + air) * 1.45) * env * 0.68
