extends Node

const Catalog = preload("res://game/audio/audio_catalog.gd")
const AudioLibrary = preload("res://game/audio/representative_audio_library.gd")
const MAX_SFX_VOICES: int = 8
const POLL_SECONDS: float = 0.25

var music_volume: float = 0.82
var sfx_volume: float = 0.88
var vibration_enabled: bool = true
var _stream_cache: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _voice_state: Array[Dictionary] = []
var _cooldowns: Dictionary = {}
var _region_player: AudioStreamPlayer
var _tension_player: AudioStreamPlayer
var _boss_player: AudioStreamPlayer
var _tension_target: float = 0.0
var _boss_target: float = 0.0
var _clock: float = 0.0
var _poll_elapsed: float = 0.0
var _encounter: Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_bus(&"Music")
    _ensure_bus(&"SFX")
    _ensure_bus(&"Warning")
    _create_music_players()
    _create_sfx_pool()
    set_music_volume(music_volume)
    set_sfx_volume(sfx_volume)
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_bind_existing_nodes")

func _process(delta: float) -> void:
    _clock += maxf(0.0, delta)
    for key in _cooldowns.keys():
        _cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)
    _poll_elapsed += maxf(0.0, delta)
    if _poll_elapsed >= POLL_SECONDS:
        _poll_elapsed = 0.0
        _poll_encounter()
    if is_instance_valid(_tension_player):
        _tension_player.volume_db = lerpf(_tension_player.volume_db, lerpf(-42.0, -7.0, _tension_target), clampf(delta * 3.2, 0.0, 1.0))
    if is_instance_valid(_boss_player):
        _boss_player.volume_db = lerpf(_boss_player.volume_db, lerpf(-48.0, -5.0, _boss_target), clampf(delta * 2.4, 0.0, 1.0))

func set_music_volume(linear: float) -> void:
    music_volume = clampf(linear, 0.0, 1.0)
    _set_bus_linear(&"Music", music_volume)

func set_sfx_volume(linear: float) -> void:
    sfx_volume = clampf(linear, 0.0, 1.0)
    _set_bus_linear(&"SFX", sfx_volume)
    _set_bus_linear(&"Warning", sfx_volume)

func set_vibration_enabled(enabled: bool) -> void:
    vibration_enabled = enabled

func settings_snapshot() -> Dictionary:
    return {"music":music_volume,"sfx":sfx_volume,"vibration":vibration_enabled}

func policy_snapshot() -> Dictionary:
    return {"max_sfx_voices":MAX_SFX_VOICES,"combat_priority":int(Catalog.cue_spec(Catalog.COMBAT).priority),"warning_priority":int(Catalog.cue_spec(Catalog.WARNING).priority)}

func play_cue(cue_id: String) -> bool:
    var spec := Catalog.cue_spec(cue_id)
    if spec.is_empty() or str(spec.get("bus", "")) == "Music":
        return false
    if float(_cooldowns.get(cue_id, 0.0)) > 0.0:
        return false
    var index := _select_voice(int(spec.get("priority", 0)))
    if index < 0:
        return false
    var player := _sfx_players[index]
    player.stop()
    player.bus = StringName(str(spec.get("bus", "SFX")))
    player.stream = _stream_for(cue_id)
    player.volume_db = float(spec.get("gain_db", -6.0))
    player.play()
    _voice_state[index] = {"priority":int(spec.get("priority",0)),"started_at":_clock,"cue_id":cue_id}
    _cooldowns[cue_id] = float(spec.get("cooldown", 0.0))
    return true

func _create_music_players() -> void:
    _region_player = _new_music_player("RegionMusic", Catalog.REGION, -7.0)
    _tension_player = _new_music_player("TensionMusic", Catalog.TENSION, -42.0)
    _boss_player = _new_music_player("BossMusic", Catalog.BOSS, -48.0)

func _new_music_player(node_name: String, cue_id: String, volume_db: float) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.name = node_name
    player.bus = &"Music"
    player.stream = _stream_for(cue_id)
    player.volume_db = volume_db
    add_child(player)
    player.play()
    return player

func _create_sfx_pool() -> void:
    for index in range(MAX_SFX_VOICES):
        var player := AudioStreamPlayer.new()
        player.name = "SfxVoice%02d" % index
        add_child(player)
        _sfx_players.append(player)
        _voice_state.append({})

func _select_voice(priority: int) -> int:
    for index in range(_sfx_players.size()):
        if not _sfx_players[index].playing:
            return index
    var candidate := -1
    var oldest := INF
    for index in range(_voice_state.size()):
        var state := _voice_state[index]
        if int(state.get("priority", 0)) >= priority:
            continue
        var started := float(state.get("started_at", INF))
        if started < oldest:
            oldest = started
            candidate = index
    return candidate

func _stream_for(cue_id: String) -> AudioStreamWAV:
    if not _stream_cache.has(cue_id):
        _stream_cache[cue_id] = AudioLibrary.render_cue(cue_id)
    return _stream_cache[cue_id]

func _ensure_bus(bus_name: StringName) -> void:
    if AudioServer.get_bus_index(bus_name) >= 0:
        return
    AudioServer.add_bus()
    AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _set_bus_linear(bus_name: StringName, value: float) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index >= 0:
        AudioServer.set_bus_volume_linear(index, maxf(0.0001, value))
        AudioServer.set_bus_mute(index, value <= 0.0001)

func _bind_existing_nodes() -> void:
    var root := get_tree().current_scene
    if root == null:
        return
    for node in root.find_children("*", "", true, false):
        _bind_runtime_node(node)

func _on_node_added(node: Node) -> void:
    call_deferred("_bind_runtime_node", node)

func _bind_runtime_node(node: Node) -> void:
    if not is_instance_valid(node):
        return
    match String(node.name):
        "W12SurvivorRuntime":
            _connect_once(node, &"weapon_action", Callable(self, "_on_weapon_action"))
            _connect_once(node, &"hit_feedback", Callable(self, "_on_hit_feedback"))
        "W12ArkRuntime":
            _connect_once(node, &"route_state_changed", Callable(self, "_on_route_state_changed"))
        "W12LightCircuitRuntime":
            _connect_once(node, &"circuit_activated", Callable(self, "_on_circuit_activated"))
            _connect_once(node, &"circuit_rejected", Callable(self, "_on_circuit_rejected"))
        "W12PhaseBattlefieldRuntime":
            _connect_once(node, &"phase_changed", Callable(self, "_on_phase_changed"))
            _connect_once(node, &"phase_rejected", Callable(self, "_on_phase_rejected"))
        "W12SwarmRuntime":
            _encounter = node

func _connect_once(node: Node, signal_name: StringName, callable: Callable) -> void:
    if node.has_signal(signal_name) and not node.is_connected(signal_name, callable):
        node.connect(signal_name, callable)

func _poll_encounter() -> void:
    if not is_instance_valid(_encounter):
        _tension_target = 0.0; _boss_target = 0.0; return
    if _encounter.has_method("active_enemy_count"):
        _tension_target = clampf(float(_encounter.call("active_enemy_count")) / 12.0, 0.0, 1.0)
    var pool = _encounter.get("_pool")
    var boss_active := false
    if pool != null and pool.has_method("active_states"):
        for state in pool.call("active_states"):
            if str(state.get("archetype", "")) == "boss": boss_active = true; break
    _boss_target = 1.0 if boss_active else 0.0

func _on_weapon_action(action: Dictionary) -> void:
    if str(action.get("type", "")) == "weapon_damage": play_cue(Catalog.COMBAT)

func _on_hit_feedback(_damage: int, remaining_health: int, _generation: int) -> void:
    if remaining_health <= 35: play_cue(Catalog.WARNING)

func _on_route_state_changed(status: String, _route_id: String) -> void:
    if status == "ARRIVED": play_cue(Catalog.REWARD)
    elif status == "FAILED_RECOVERABLE": play_cue(Catalog.WARNING)

func _on_circuit_activated(_id: int, _module_id: String, _light: float) -> void:
    play_cue(Catalog.CIRCUIT)

func _on_circuit_rejected(_reason: String) -> void:
    play_cue(Catalog.WARNING)

func _on_phase_changed(_phase_id: String, threat_count: int) -> void:
    play_cue(Catalog.CIRCUIT)
    if threat_count > 0: play_cue(Catalog.WARNING)

func _on_phase_rejected(_reason: String) -> void:
    play_cue(Catalog.WARNING)
