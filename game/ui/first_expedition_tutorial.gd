extends Control

const STEP_SLOT: String = "slot"
const STEP_DEPART: String = "depart"
const STEP_MOVE: String = "move"
const STEP_CIRCUIT: String = "circuit"
const STEP_PHASE: String = "phase"
const STEP_SETTLE: String = "settle"
const STEP_COMPLETE: String = "complete"

var _slot_opened: bool = false
var _departed: bool = false
var _moved: bool = false
var _circuit_activated: bool = false
var _phase_switched: bool = false
var _settled: bool = false
var _prompt_label: Label


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_prompt_label()
    call_deferred("_refresh_from_runtime")


func _process(_delta: float) -> void:
    _refresh_from_runtime()


func apply_observation(observation: Dictionary) -> void:
    _slot_opened = _slot_opened or bool(observation.get("slot_opened", false))
    _departed = _departed or bool(observation.get("departed", false))
    _moved = _moved or bool(observation.get("moved", false))
    _circuit_activated = _circuit_activated or bool(observation.get("circuit_activated", false))
    _phase_switched = _phase_switched or bool(observation.get("phase_switched", false))
    _settled = _settled or bool(observation.get("settled", false))
    _render_prompt()


func current_step() -> String:
    if _settled:
        return STEP_COMPLETE
    if not _slot_opened:
        return STEP_SLOT
    if not _departed:
        return STEP_DEPART
    if not _moved:
        return STEP_MOVE
    if not _circuit_activated:
        return STEP_CIRCUIT
    if not _phase_switched:
        return STEP_PHASE
    return STEP_SETTLE


static func prompt_for_step(step: String) -> String:
    match step:
        STEP_SLOT:
            return "첫 항해 · 저장 슬롯을 선택해 여정을 시작하세요."
        STEP_DEPART:
            return "거점 · 항로를 고르면 그 선택이 이번 여정의 세계 상태에 남습니다."
        STEP_MOVE:
            return "원정 · 왼쪽 패드로 이동하고 오른쪽 원형 버튼으로 회피하세요. 공격은 자동입니다."
        STEP_CIRCUIT:
            return "잔광 회로 · 회로 모듈을 고른 뒤 이동 경로를 닫아 회로를 완성하세요."
        STEP_PHASE:
            return "이중 위상 · 오른쪽 마름모 버튼으로 위상을 전환해 지형과 적 구성을 바꾸세요."
        STEP_SETTLE:
            return "항로 완주 · 휴식·복구·철수 선택 뒤 정산하면 이번 원정의 변화가 저장됩니다."
        _:
            return ""


func prompt_text() -> String:
    return prompt_for_step(current_step())


func status_snapshot() -> Dictionary:
    return {
        "step": current_step(),
        "prompt": prompt_text(),
        "complete": current_step() == STEP_COMPLETE,
        "slot_opened": _slot_opened,
        "departed": _departed,
        "moved": _moved,
        "circuit_activated": _circuit_activated,
        "phase_switched": _phase_switched,
        "settled": _settled,
    }


func _refresh_from_runtime() -> void:
    var host := get_parent()
    if host == null:
        return

    var observation := {
        "slot_opened": false,
        "departed": str(host.get("shell_mode")) == "EXPEDITION",
        "moved": false,
        "circuit_activated": false,
        "phase_switched": false,
        "settled": false,
    }

    var campaign: Variant = host.get("campaign")
    if campaign != null:
        observation["slot_opened"] = bool(campaign.get("loaded"))
        var world: Variant = campaign.get("world")
        if world != null:
            observation["departed"] = observation["departed"] or str(world.get("state")) == "EXPEDITION"
            observation["settled"] = int(world.get("segment_index")) > 0

    var movement: Variant = host.get("movement_input")
    if movement is Vector2:
        var movement_vector: Vector2 = movement
        observation["moved"] = not movement_vector.is_zero_approx()

    var circuit: Variant = host.get("circuit_preview")
    if is_instance_valid(circuit) and circuit.has_method("status_snapshot"):
        var circuit_status: Dictionary = circuit.call("status_snapshot")
        observation["circuit_activated"] = int(circuit_status.get("active_count", 0)) > 0

    var phase: Variant = host.get("phase_preview")
    if is_instance_valid(phase) and phase.has_method("status_snapshot"):
        var phase_status: Dictionary = phase.call("status_snapshot")
        observation["phase_switched"] = int(phase_status.get("transition_generation", 0)) > 0

    apply_observation(observation)


func _build_prompt_label() -> void:
    _prompt_label = Label.new()
    _prompt_label.name = "TutorialPrompt"
    _prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    _prompt_label.position = Vector2(-390.0, 82.0)
    _prompt_label.size = Vector2(780.0, 58.0)
    _prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _prompt_label.add_theme_font_size_override("font_size", 18)
    _prompt_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1.0))
    _prompt_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.92))
    _prompt_label.add_theme_constant_override("shadow_offset_x", 2)
    _prompt_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(_prompt_label)
    _render_prompt()


func _render_prompt() -> void:
    if not is_instance_valid(_prompt_label):
        return
    var prompt := prompt_text()
    _prompt_label.text = prompt
    _prompt_label.visible = not prompt.is_empty()
