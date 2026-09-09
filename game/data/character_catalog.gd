class_name CharacterCatalog
extends RefCounted

const ID_AURORA: String = "aurora"
const ID_CINDER: String = "cinder"
const ID_RIVET: String = "rivet"
const ID_VEIL: String = "veil"
const ID_MNEME: String = "mneme"
const ID_VESPER: String = "vesper"

const ROLE_CIRCUIT_ARCHITECT: String = "circuit_architect"
const ROLE_CLOSE_ESCORT: String = "close_escort"
const ROLE_ARK_ENGINEER: String = "ark_engineer"
const ROLE_PHASE_SCOUT: String = "phase_scout"
const ROLE_ECHO_RECORDER: String = "echo_recorder"
const ROLE_RANGED_OBSERVER: String = "ranged_observer"


static func character_ids() -> Array[String]:
    var ids: Array[String] = []
    ids.append(ID_AURORA)
    ids.append(ID_CINDER)
    ids.append(ID_RIVET)
    ids.append(ID_VEIL)
    ids.append(ID_MNEME)
    ids.append(ID_VESPER)
    return ids


static func definition(character_id: String) -> Dictionary:
    match character_id:
        ID_AURORA:
            return {
                "id": ID_AURORA,
                "display_name": "오로라",
                "role_id": ROLE_CIRCUIT_ARCHITECT,
                "role_name": "회로 설계자",
                "summary": "완성한 잔광 회로를 다음 공격의 증폭 자원으로 전환합니다.",
                "unlock_text": "기본 해금",
                "tutorial": "회로 설계자 · 3/4/5로 회로를 완성하면 회로 전하를 얻습니다. 다음 공격 원인에 전하가 소모되어 피해가 증폭됩니다.",
                "mechanic_text": "회로 완성 시 최대 2 전하, 전하를 소비한 공격 원인 피해 +35%",
                "representative_art": "res://assets/runtime/w13/player_aurora.svg",
                "production_art_status": "w13-representative",
            }
        ID_CINDER:
            return {
                "id": ID_CINDER,
                "display_name": "신더",
                "role_id": ROLE_CLOSE_ESCORT,
                "role_name": "근접 호위자",
                "summary": "방주 곁을 지킬 때 공격과 방어가 동시에 강화됩니다.",
                "unlock_text": "기본 해금",
                "tutorial": "근접 호위자 · 방주 220px 안에서 싸우면 주 공격 피해가 증가하고 피격 방어가 붙습니다. 멀어지면 보너스가 사라집니다.",
                "mechanic_text": "방주 220px 이내 주 공격 +20%, 피격 방어 +3",
                "representative_art": "res://assets/runtime/w13/player_cinder.svg",
                "production_art_status": "w13-representative",
            }
        ID_RIVET:
            return {
                "id": ID_RIVET,
                "display_name": "리벳",
                "role_id": ROLE_ARK_ENGINEER,
                "role_name": "방주 정비사",
                "summary": "방주 근처에서 전투를 지속하면 전투 중 선체를 조금씩 복구합니다.",
                "unlock_text": "첫 성공 원정에서 현장 개조를 확보하거나 등대를 수리하면 해금",
                "tutorial": "방주 정비사 · 방주 300px 안에서 서로 다른 공격 원인을 4회 처리할 때마다 선체 내구도를 8 복구합니다. 파손 상태 자체를 무효화하지는 않습니다.",
                "mechanic_text": "방주 300px 이내 4번째 공격 원인마다 내구도 +8",
                "representative_art": "",
                "production_art_status": "w23-required",
            }
        ID_VEIL:
            return {
                "id": ID_VEIL,
                "display_name": "베일",
                "role_id": ROLE_PHASE_SCOUT,
                "role_name": "위상 정찰자",
                "summary": "위상 전환 직후의 짧은 공격 창을 적극적으로 활용합니다.",
                "unlock_text": "위상 닻 또는 보존 항로 확보 시 해금, 세그먼트 2 도달 시 안전 해금",
                "tutorial": "위상 정찰자 · Q로 유효한 위상 전환을 완료하면 위상 전하 2개를 얻습니다. 이후 서로 다른 공격 원인 2회가 각각 강화됩니다.",
                "mechanic_text": "유효 위상 전환 시 2 전하, 전하를 소비한 공격 원인 피해 +30%",
                "representative_art": "",
                "production_art_status": "w23-required",
            }
        ID_MNEME:
            return {
                "id": ID_MNEME,
                "display_name": "므네메",
                "role_id": ROLE_ECHO_RECORDER,
                "role_name": "잔상 기록자",
                "summary": "이전 원정의 전술 잔상이 현재 전투에 더 강하게 개입하도록 조정합니다.",
                "unlock_text": "첫 정산으로 전술 잔상을 기록하면 해금",
                "tutorial": "잔상 기록자 · 이전 원정 기록을 echo_beacon 회로로 재생할 때 잔상 사격 피해가 기본 제한 피해의 1.5배가 됩니다. 인과 무기 재귀는 발생하지 않습니다.",
                "mechanic_text": "N04 잔상 사격 피해 ×1.50, 인과 체인·보상 경로는 그대로 차단",
                "representative_art": "",
                "production_art_status": "w23-required",
            }
        ID_VESPER:
            return {
                "id": ID_VESPER,
                "display_name": "베스퍼",
                "role_id": ROLE_RANGED_OBSERVER,
                "role_name": "원거리 관측자",
                "summary": "주 공격 원인마다 먼 보조 표적을 하나 더 추적합니다.",
                "unlock_text": "부두 주민 4명 구조 또는 세그먼트 2 도달 시 해금",
                "tutorial": "원거리 관측자 · 주 공격 원인마다 720px 안의 다른 표적 하나를 추가 관측해 55% 피해의 비재귀 보조타를 발사합니다.",
                "mechanic_text": "서로 다른 공격 원인당 최대 1회, 720px 보조 표적에 주 공격 피해의 55%",
                "representative_art": "",
                "production_art_status": "w23-required",
            }
    return {}


static func is_unlocked(character_id: String, world: Variant) -> bool:
    match character_id:
        ID_AURORA, ID_CINDER:
            return true
        ID_RIVET:
            return (
                _has_horizontal_unlock(world, "field_refit")
                or _world_int(world, "repaired_lighthouses") >= 1
                or _world_int(world, "segment_index") >= 2
            )
        ID_VEIL:
            return (
                _has_horizontal_unlock(world, "phase_anchor")
                or _world_int(world, "preserved_routes") >= 1
                or _world_int(world, "segment_index") >= 2
            )
        ID_MNEME:
            var cross_run := _world_dictionary(world, "cross_run_state")
            var record_value: Variant = cross_run.get("tactical_echo_record", {})
            if record_value is Dictionary:
                var record: Dictionary = record_value
                if not str(record.get("record_id", "")).is_empty():
                    return true
            return _world_int(world, "segment_index") >= 1
        ID_VESPER:
            return (
                _world_int(world, "rescued_residents") >= 4
                or _world_int(world, "segment_index") >= 2
            )
    return false


static func unlocked_character_ids(world: Variant) -> Array[String]:
    var result: Array[String] = []
    for character_id in character_ids():
        if is_unlocked(character_id, world):
            result.append(character_id)
    return result


static func first_unlocked_character_id(world: Variant) -> String:
    var unlocked := unlocked_character_ids(world)
    return ID_AURORA if unlocked.is_empty() else unlocked[0]


static func _has_horizontal_unlock(world: Variant, unlock_id: String) -> bool:
    var unlocks_value := _world_value(world, "horizontal_unlocks", [])
    if not unlocks_value is Array:
        return false
    for raw_value in unlocks_value:
        if str(raw_value) == unlock_id:
            return true
    return false


static func _world_int(world: Variant, key: String) -> int:
    return int(_world_value(world, key, 0))


static func _world_dictionary(world: Variant, key: String) -> Dictionary:
    var value := _world_value(world, key, {})
    if value is Dictionary:
        var dictionary_value: Dictionary = value
        return dictionary_value.duplicate(true)
    return {}


static func _world_value(world: Variant, key: String, default_value: Variant) -> Variant:
    if typeof(world) == TYPE_DICTIONARY:
        var world_dictionary: Dictionary = world
        return world_dictionary.get(key, default_value)
    if typeof(world) == TYPE_OBJECT and world != null:
        var world_object: Object = world
        var value: Variant = world_object.get(key)
        return default_value if value == null else value
    return default_value
