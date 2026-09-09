extends RefCounted

const PARENT_TWILIGHT_SHIPYARD: String = "twilight_shipyard"
const PARENT_GLASS_GARDEN: String = "glass_garden"
const PARENT_FLOODED_ARCHIVE: String = "flooded_archive"
const PARENT_ASH_RAILWAY: String = "ash_railway"
const PARENT_ECLIPSE_FORTRESS: String = "eclipse_fortress"

const PATTERN_SHAPES := [
    "line",
    "ring",
    "cone",
    "cross",
    "lanes",
    "orbit",
    "sweep",
    "pillars",
    "spiral",
    "collapse",
]


static func parent_region_ids() -> Array[String]:
    return [
        PARENT_TWILIGHT_SHIPYARD,
        PARENT_GLASS_GARDEN,
        PARENT_FLOODED_ARCHIVE,
        PARENT_ASH_RAILWAY,
        PARENT_ECLIPSE_FORTRESS,
    ]


static func all_profiles() -> Array[Dictionary]:
    return [
        _profile(
            "drowned_navigator",
            PARENT_TWILIGHT_SHIPYARD,
            "익사한 항해사",
            "line",
            "dead_reckoning",
            "navigator_lens",
            "unlock_dead_reckoning_chart",
            660,
            48.0,
            38.0,
            20,
            0.70,
            0.34,
            0.95,
            2.45,
            300.0,
            26.0,
            16,
            0.46,
            "선수의 침로광이 닫히기 전에 직각으로 이탈",
            "nav_lamp"
        ),
        _profile(
            "keel_bell_matron",
            PARENT_TWILIGHT_SHIPYARD,
            "용골 종의 모후",
            "ring",
            "keel_toll",
            "keel_bell_core",
            "unlock_keel_resonance",
            720,
            42.0,
            42.0,
            22,
            0.66,
            0.30,
            1.10,
            2.70,
            250.0,
            30.0,
            17,
            0.58,
            "종파의 안쪽 안전 원으로 파고든 뒤 외곽 파동을 통과",
            "bell_wake"
        ),
        _profile(
            "prism_ossuary",
            PARENT_GLASS_GARDEN,
            "프리즘 납골성자",
            "cone",
            "prism_fan",
            "ossuary_prism",
            "unlock_prismatic_breach",
            700,
            54.0,
            37.0,
            21,
            0.72,
            0.38,
            0.82,
            2.20,
            320.0,
            24.0,
            18,
            0.67,
            "부채꼴 굴절선의 열린 측면으로 이동하고 위상 전환을 늦춤",
            "prism_bloom"
        ),
        _profile(
            "rootglass_colossus",
            PARENT_GLASS_GARDEN,
            "뿌리유리 거상",
            "cross",
            "root_fracture",
            "rootglass_heart",
            "unlock_glassroot_bulwark",
            820,
            36.0,
            46.0,
            25,
            0.62,
            0.28,
            1.20,
            2.90,
            285.0,
            32.0,
            20,
            0.39,
            "십자 균열 축 사이의 사분면으로 빠져나가고 중심에 머물지 않음",
            "root_crack"
        ),
        _profile(
            "mnemonic_leviathan",
            PARENT_FLOODED_ARCHIVE,
            "기억의 리바이어던",
            "lanes",
            "memory_current",
            "sealed_leviathan_index",
            "unlock_memory_current",
            780,
            46.0,
            44.0,
            23,
            0.69,
            0.31,
            1.00,
            2.50,
            330.0,
            25.0,
            19,
            0.52,
            "세 기억 수로 중 비어 있는 수로를 읽고 평행 이동",
            "memory_tide"
        ),
        _profile(
            "index_regent",
            PARENT_FLOODED_ARCHIVE,
            "색인 섭정",
            "orbit",
            "index_orbit",
            "regent_cipher",
            "unlock_archive_cipher",
            740,
            50.0,
            40.0,
            22,
            0.64,
            0.26,
            0.90,
            2.35,
            265.0,
            28.0,
            18,
            0.61,
            "회전 색인환의 끊긴 구간을 따라 돌고 환을 가로지르지 않음",
            "cipher_halo"
        ),
        _profile(
            "furnace_conductor",
            PARENT_ASH_RAILWAY,
            "노심 차장",
            "sweep",
            "furnace_signal",
            "conductor_flame_key",
            "unlock_rail_overdrive",
            760,
            58.0,
            39.0,
            23,
            0.71,
            0.36,
            0.78,
            2.10,
            340.0,
            24.0,
            19,
            0.73,
            "회전 신호팔의 진행 방향 반대로 한 번만 횡단",
            "signal_flare"
        ),
        _profile(
            "trestle_widow",
            PARENT_ASH_RAILWAY,
            "가대의 과부",
            "pillars",
            "trestle_spindle",
            "widow_spindle",
            "unlock_trestle_thread",
            690,
            62.0,
            35.0,
            19,
            0.67,
            0.29,
            0.88,
            2.25,
            255.0,
            27.0,
            17,
            0.44,
            "예고된 네 지주 사이 대각선 공백으로 이동하고 같은 지주에 재진입하지 않음",
            "spindle_flash"
        ),
        _profile(
            "corona_castellan",
            PARENT_ECLIPSE_FORTRESS,
            "코로나 성주",
            "spiral",
            "corona_spiral",
            "corona_keep_sigil",
            "unlock_solar_bastion",
            840,
            40.0,
            45.0,
            26,
            0.74,
            0.40,
            1.15,
            2.80,
            310.0,
            26.0,
            21,
            0.55,
            "나선의 감기는 방향과 반대로 반경을 바꾸며 한 바퀴 안에 탈출",
            "corona_helix"
        ),
        _profile(
            "black_sun_reliquary",
            PARENT_ECLIPSE_FORTRESS,
            "흑일 성유함",
            "collapse",
            "black_sun_collapse",
            "occluded_reliquary",
            "unlock_black_sun_resonance",
            900,
            34.0,
            48.0,
            28,
            0.60,
            0.24,
            1.30,
            3.00,
            300.0,
            34.0,
            22,
            0.35,
            "외곽 암막이 닫히기 전에 표시된 내부 안전권으로 진입",
            "eclipse_collapse"
        ),
    ]


static func boss_ids() -> Array[String]:
    var result: Array[String] = []
    for profile in all_profiles():
        result.append(str(profile.get("boss_id", "")))
    return result


static func bosses_for_parent(parent_region_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for profile in all_profiles():
        if str(profile.get("parent_region_id", "")) == parent_region_id:
            result.append(profile.duplicate(true))
    return result


static func profile_for_boss(boss_id: String) -> Dictionary:
    for profile in all_profiles():
        if str(profile.get("boss_id", "")) == boss_id:
            return profile.duplicate(true)
    return {}


static func default_boss_for_parent(parent_region_id: String, variant: int = 0) -> Dictionary:
    var candidates := bosses_for_parent(parent_region_id)
    if candidates.is_empty():
        return {}
    return candidates[posmod(variant, candidates.size())].duplicate(true)


static func default_variant_for_region(region_id: String) -> int:
    match region_id:
        "blackglass_spires", "storm_crown":
            return 1
    return 0


static func catalog_counts() -> Dictionary:
    var per_parent: Dictionary = {}
    for parent_region_id in parent_region_ids():
        per_parent[parent_region_id] = bosses_for_parent(parent_region_id).size()
    return {
        "bosses": boss_ids().size(),
        "parent_regions": parent_region_ids().size(),
        "bosses_per_region": 2,
        "distinct_pattern_shapes": PATTERN_SHAPES.size(),
        "per_parent": per_parent,
    }


static func validate_profile(profile: Dictionary) -> bool:
    if str(profile.get("boss_id", "")).is_empty():
        return false
    if not parent_region_ids().has(str(profile.get("parent_region_id", ""))):
        return false
    if not PATTERN_SHAPES.has(str(profile.get("pattern_shape", ""))):
        return false
    if int(profile.get("max_health", 0)) <= 0 or float(profile.get("move_speed", 0.0)) <= 0.0:
        return false
    if str(profile.get("reward_id", "")).is_empty() or str(profile.get("unlock_id", "")).is_empty():
        return false
    var thresholds: Variant = profile.get("phase_thresholds", null)
    var phases: Variant = profile.get("phases", null)
    if not thresholds is Array or thresholds.size() != 2:
        return false
    if not phases is Array or phases.size() != 3:
        return false
    if float(thresholds[0]) <= float(thresholds[1]) or float(thresholds[0]) >= 1.0 or float(thresholds[1]) <= 0.0:
        return false
    var attack_ids: Array[String] = []
    for raw_phase: Variant in phases:
        if not raw_phase is Dictionary:
            return false
        var phase: Dictionary = raw_phase
        var attack_id := str(phase.get("attack_id", ""))
        if attack_id.is_empty() or attack_ids.has(attack_id):
            return false
        if str(phase.get("telegraph_shape", "")) != str(profile.get("pattern_shape", "")):
            return false
        if float(phase.get("telegraph_duration", 0.0)) <= 0.0 or float(phase.get("attack_interval", 0.0)) <= 0.0:
            return false
        if str(phase.get("dodge_rule", "")).is_empty() or str(phase.get("presentation_cue", "")).is_empty():
            return false
        attack_ids.append(attack_id)
    return true


static func profile_signature(profile: Dictionary) -> String:
    var phase_ids: Array[String] = []
    var phases: Variant = profile.get("phases", [])
    if phases is Array:
        for raw_phase: Variant in phases:
            if raw_phase is Dictionary:
                phase_ids.append(str(raw_phase.get("attack_id", "")))
    return "%s|%s|%s" % [
        str(profile.get("pattern_shape", "")),
        ",".join(phase_ids),
        str(profile.get("phase_thresholds", [])),
    ]


static func _profile(
    boss_id: String,
    parent_region_id: String,
    display_name: String,
    pattern_shape: String,
    attack_stem: String,
    reward_id: String,
    unlock_id: String,
    max_health: int,
    move_speed: float,
    radius: float,
    contact_damage: int,
    first_threshold: float,
    second_threshold: float,
    telegraph_duration: float,
    attack_interval: float,
    attack_radius: float,
    attack_width: float,
    attack_damage: int,
    angle_step: float,
    dodge_rule: String,
    presentation_stem: String
) -> Dictionary:
    return {
        "boss_id": boss_id,
        "parent_region_id": parent_region_id,
        "display_name": display_name,
        "pattern_shape": pattern_shape,
        "reward_id": reward_id,
        "unlock_id": unlock_id,
        "max_health": max_health,
        "move_speed": move_speed,
        "radius": radius,
        "contact_damage": contact_damage,
        "phase_thresholds": [first_threshold, second_threshold],
        "intro_cue": "%s_intro" % presentation_stem,
        "defeat_cue": "%s_break" % presentation_stem,
        "phases": [
            _phase(
                "opening",
                "%s_opening" % attack_stem,
                pattern_shape,
                telegraph_duration + 0.18,
                attack_interval + 0.42,
                attack_radius * 0.88,
                attack_width,
                attack_damage,
                angle_step,
                "material",
                "%s · 첫 예고는 넓고 느리게 읽음" % dodge_rule,
                "%s_opening" % presentation_stem
            ),
            _phase(
                "pressure",
                "%s_pressure" % attack_stem,
                pattern_shape,
                telegraph_duration,
                attack_interval,
                attack_radius,
                attack_width * 1.08,
                attack_damage + 4,
                angle_step * 1.35,
                "shadow",
                "%s · 두 번째 단계는 위상 이동 후 재진입 각도를 확인" % dodge_rule,
                "%s_pressure" % presentation_stem
            ),
            _phase(
                "finale",
                "%s_finale" % attack_stem,
                pattern_shape,
                maxf(0.45, telegraph_duration - 0.20),
                maxf(1.25, attack_interval - 0.38),
                attack_radius * 1.12,
                attack_width * 1.18,
                attack_damage + 8,
                angle_step * 1.72,
                "material",
                "%s · 종결 단계는 짧은 예고를 보고 한 번만 확정 회피" % dodge_rule,
                "%s_finale" % presentation_stem
            ),
        ],
    }


static func _phase(
    phase_id: String,
    attack_id: String,
    telegraph_shape: String,
    telegraph_duration: float,
    attack_interval: float,
    attack_radius: float,
    attack_width: float,
    damage: int,
    angle_step: float,
    body_phase: String,
    dodge_rule: String,
    presentation_cue: String
) -> Dictionary:
    return {
        "phase_id": phase_id,
        "attack_id": attack_id,
        "telegraph_shape": telegraph_shape,
        "telegraph_duration": telegraph_duration,
        "attack_interval": attack_interval,
        "radius": attack_radius,
        "width": attack_width,
        "damage": damage,
        "angle_step": angle_step,
        "body_phase": body_phase,
        "active_phase": "any",
        "dodge_rule": dodge_rule,
        "presentation_cue": presentation_cue,
    }
