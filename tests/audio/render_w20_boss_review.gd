extends SceneTree

const BossAudioCatalog = preload("res://game/audio/boss_audio_catalog.gd")
const BossCatalog = preload("res://game/data/boss_catalog.gd")
const OUTPUT_DIR := "res://artifacts/w20"
const MIX_PATH := "res://artifacts/w20/boss-review-mix.wav"
const METRICS_PATH := "res://artifacts/w20/boss-review-metrics.json"
const SILENCE_SECONDS := 0.16


func _initialize() -> void:
    call_deferred("_render")


func _render() -> void:
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W20_REVIEW_EVIDENCE=FAIL_DIRECTORY")
        quit(2)
        return

    var mixed_data := PackedByteArray()
    var audio_rows: Array = []
    var min_peak := 1.0
    var min_rms := 1.0
    var silence := PackedByteArray()
    silence.resize(int(round(float(BossAudioCatalog.MIX_RATE) * SILENCE_SECONDS)) * 2)

    var boss_ids := BossAudioCatalog.boss_ids()
    if boss_ids.size() != 10:
        printerr("W20_REVIEW_EVIDENCE=FAIL_BOSS_COUNT")
        quit(3)
        return

    for boss_id in boss_ids:
        var cue_rows: Array = []
        var cue_ids := BossAudioCatalog.cue_ids_for_boss(boss_id)
        if cue_ids.size() != 5:
            printerr("W20_REVIEW_EVIDENCE=FAIL_CUE_COUNT_%s" % boss_id)
            quit(4)
            return
        for cue_id in cue_ids:
            var stream := BossAudioCatalog.render_cue(cue_id)
            var metrics := BossAudioCatalog.analyze_cue(cue_id)
            var peak := float(metrics.get("peak", 0.0))
            var rms := float(metrics.get("rms", 0.0))
            if peak < 0.04 or rms < 0.01:
                printerr("W20_REVIEW_EVIDENCE=FAIL_AUDIO_METRICS_%s" % cue_id)
                quit(5)
                return
            min_peak = minf(min_peak, peak)
            min_rms = minf(min_rms, rms)
            mixed_data.append_array(stream.data)
            mixed_data.append_array(silence)
            cue_rows.append({"cue_id":str(cue_id),"peak":peak,"rms":rms,"nonzero_ratio":float(metrics.get("nonzero_ratio", 0.0))})
        var spec := BossAudioCatalog.cue_spec(str(cue_ids[0]))
        audio_rows.append({"boss_id":str(boss_id),"base_hz":float(spec.get("base_hz", 0.0)),"overtone":float(spec.get("overtone", 0.0)),"cues":cue_rows})

    var mix := AudioStreamWAV.new()
    mix.format = AudioStreamWAV.FORMAT_16_BITS
    mix.mix_rate = BossAudioCatalog.MIX_RATE
    mix.stereo = false
    mix.data = mixed_data
    if mix.save_to_wav(MIX_PATH) != OK:
        printerr("W20_REVIEW_EVIDENCE=FAIL_WAV_SAVE")
        quit(6)
        return

    var balance_rows: Array = []
    var global_min_telegraph := 99.0
    var global_max_pressure := 0.0
    for profile in BossCatalog.all_profiles():
        var boss_id := str(profile.get("boss_id", ""))
        var max_health := int(profile.get("max_health", 0))
        var contact_damage := int(profile.get("contact_damage", 0))
        if max_health < 600 or max_health > 950 or contact_damage <= 0 or contact_damage > 30:
            printerr("W20_REVIEW_EVIDENCE=FAIL_BALANCE_ENVELOPE_%s" % boss_id)
            quit(7)
            return
        var phase_rows: Array = []
        var phases: Array = profile.get("phases", [])
        if phases.size() != 3:
            printerr("W20_REVIEW_EVIDENCE=FAIL_PHASE_COUNT_%s" % boss_id)
            quit(8)
            return
        for phase in phases:
            var telegraph := float(phase.get("telegraph_duration", 0.0))
            var interval := float(phase.get("attack_interval", 0.0))
            var damage := int(phase.get("attack_damage", 0))
            var radius := float(phase.get("attack_radius", 0.0))
            var pressure := float(damage) / maxf(interval, 0.001)
            if telegraph < 0.45 or interval < 1.25 or damage <= 0 or damage > 40 or radius <= 0.0 or pressure > 26.0:
                printerr("W20_REVIEW_EVIDENCE=FAIL_PHASE_ENVELOPE_%s_%s" % [boss_id, str(phase.get("phase_id", ""))])
                quit(9)
                return
            global_min_telegraph = minf(global_min_telegraph, telegraph)
            global_max_pressure = maxf(global_max_pressure, pressure)
            phase_rows.append({"phase_id":str(phase.get("phase_id", "")),"telegraph_seconds":telegraph,"attack_interval_seconds":interval,"attack_damage":damage,"attack_radius":radius,"damage_per_second_pressure":pressure})
        balance_rows.append({"boss_id":boss_id,"max_health":max_health,"contact_damage":contact_damage,"phase_thresholds":profile.get("phase_thresholds", []),"phases":phase_rows})

    var report := {
        "schema":"w20-boss-review-evidence-v1",
        "boss_count":boss_ids.size(),
        "audio":{"mix_rate":BossAudioCatalog.MIX_RATE,"cue_count":boss_ids.size() * 5,"min_peak":min_peak,"min_rms":min_rms,"bosses":audio_rows,"human_listening_review":"PENDING"},
        "balance":{"minimum_telegraph_seconds":global_min_telegraph,"maximum_damage_per_second_pressure":global_max_pressure,"bosses":balance_rows,"automated_envelope":"PASS_SANITY_ONLY","human_gameplay_balance_review":"PENDING"}
    }
    var file := FileAccess.open(METRICS_PATH, FileAccess.WRITE)
    if file == null:
        printerr("W20_REVIEW_EVIDENCE=FAIL_METRICS_OPEN")
        quit(10)
        return
    file.store_string(JSON.stringify(report, "  "))
    file.close()

    print("W20_AUDIO_REVIEW_MIX=PASS")
    print("W20_AUDIO_REVIEW_RATE=%d" % BossAudioCatalog.MIX_RATE)
    print("W20_AUDIO_REVIEW_CUES=%d" % (boss_ids.size() * 5))
    print("W20_BALANCE_MEASURED=PASS_SANITY_ONLY")
    print("W20_BALANCE_MIN_TELEGRAPH=%.3f" % global_min_telegraph)
    print("W20_BALANCE_MAX_PRESSURE=%.3f" % global_max_pressure)
    print("W20_HUMAN_LISTENING=PENDING")
    print("W20_HUMAN_BALANCE=PENDING")
    quit(0)
