extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")

const REPRESENTATIVE_BUILDS := {
    "boundary_runner": {
        "label": "경계 질주자",
        "weapon_id": "sunwake_lance",
        "relic_ids": ["wake_edge", "circuit_fork", "navigation_nail", "phase_ward"],
        "purpose": "회피와 회로 경계 교차를 함께 설계해 이동 경로 자체를 공격 루프로 만든다",
    },
    "shadow_escort": {
        "label": "그림자 호위자",
        "weapon_id": "shade_halo",
        "relic_ids": ["shadow_edge", "ark_ward", "phase_nail", "navigation_lens"],
        "purpose": "그림자 위상 화력과 방주 압박 대응을 함께 유지하는 안정형 호위 빌드",
    },
    "chain_keeper": {
        "label": "연쇄 수문장",
        "weapon_id": "snare_chain",
        "relic_ids": ["circuit_edge", "chain_fork", "ark_nail", "shadow_ward"],
        "purpose": "구속 회로 안의 군집을 연쇄 타격으로 묶어 방주 접근을 늦춘다",
    },
    "phase_duelist": {
        "label": "위상 결투가",
        "weapon_id": "dusk_bolt",
        "relic_ids": ["phase_edge", "shadow_lens", "wake_nail", "navigation_ward"],
        "purpose": "위상 진입 직후 단일 정예를 빠르게 제거하는 고집중 빌드",
    },
    "ark_breakwater": {
        "label": "방주 방파제",
        "weapon_id": "pressure_fan",
        "relic_ids": ["ark_edge", "navigation_fork", "circuit_ward", "mark_nail"],
        "purpose": "방주 압박 시 전면 다중 타격으로 접근선을 넓게 지우는 구조 대응 빌드",
    },
    "ember_hunter": {
        "label": "잔화 사냥꾼",
        "weapon_id": "confirmed_fan",
        "relic_ids": ["mark_edge", "chain_nail", "shadow_fork", "phase_ward"],
        "purpose": "명중 후 잔화 표식을 넓혀 다음 선택의 우선 표적을 만드는 추격 빌드",
    },
}


static func build_ids() -> Array[String]:
    var ids: Array[String] = []
    for raw_id: Variant in REPRESENTATIVE_BUILDS.keys():
        ids.append(str(raw_id))
    return ids


static func definition(build_id: String) -> Dictionary:
    if not REPRESENTATIVE_BUILDS.has(build_id):
        return {}
    return REPRESENTATIVE_BUILDS[build_id].duplicate(true)


static func validate_build(build_id: String) -> Dictionary:
    var build: Dictionary = definition(build_id)
    if build.is_empty():
        return {"valid": false, "reason": "unknown_build"}
    var weapon_id: String = str(build.get("weapon_id", ""))
    var recipe: Dictionary = WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
    var weapon_validation: Dictionary = WeaponPartCatalogScript.validate_recipe(recipe)
    if not bool(weapon_validation.get("valid", false)):
        return {"valid": false, "reason": "invalid_weapon", "weapon_id": weapon_id}
    var relic_ids_value: Array[String] = []
    var raw_relics: Variant = build.get("relic_ids", [])
    if not raw_relics is Array:
        return {"valid": false, "reason": "invalid_relic_array"}
    for raw_relic: Variant in raw_relics:
        relic_ids_value.append(str(raw_relic))
    var relic_validation: Dictionary = RelicCatalogScript.validate_loadout(relic_ids_value)
    if not bool(relic_validation.get("valid", false)):
        return {"valid": false, "reason": str(relic_validation.get("reason", "invalid_relic_loadout"))}
    return {
        "valid": true,
        "reason": "",
        "build_id": build_id,
        "weapon_id": weapon_id,
        "relic_ids": relic_ids_value,
        "weapon_card": WeaponPartCatalogScript.choice_card(weapon_id),
        "relic_cards": _relic_cards(relic_ids_value),
        "purpose": str(build.get("purpose", "")),
    }


static func _relic_cards(relic_ids_value: Array[String]) -> Array[Dictionary]:
    var cards: Array[Dictionary] = []
    for relic_id: String in relic_ids_value:
        cards.append(RelicCatalogScript.selection_card(relic_id))
    return cards
