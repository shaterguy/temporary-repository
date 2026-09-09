class_name CampaignStoryEventCatalog
extends RefCounted

const TRIGGER_SUCCESS: String = "success"
const TRIGGER_FAILED: String = "failed"
const EXPECTED_EVENT_COUNT: int = 40
const EXPECTED_EVENTS_PER_PARENT: int = 8


static func parent_region_ids() -> Array[String]:
    return [
        "twilight_shipyard",
        "glass_garden",
        "flooded_archive",
        "ash_railway",
        "eclipse_fortress",
    ]


static func all_events() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for row: Array in _event_rows():
        var event_id := str(row[0])
        result.append({
            "event_id": event_id,
            "parent_region_id": str(row[1]),
            "trigger": str(row[2]),
            "speaker_id": str(row[3]),
            "arc_id": str(row[4]),
            "title": str(row[5]),
            "body": str(row[6]),
            "options": [
                _option(event_id, "a", str(row[7]), str(row[8])),
                _option(event_id, "b", str(row[9]), str(row[10])),
            ],
        })
    return result


static func event_by_id(event_id: String) -> Dictionary:
    for event: Dictionary in all_events():
        if str(event.get("event_id", "")) == event_id:
            return event.duplicate(true)
    return {}


static func event_ids_for(parent_region_id: String, trigger: String) -> Array[String]:
    var result: Array[String] = []
    for event: Dictionary in all_events():
        if str(event.get("parent_region_id", "")) != parent_region_id:
            continue
        if str(event.get("trigger", "")) != trigger:
            continue
        result.append(str(event.get("event_id", "")))
    return result


static func select_event_id(
    parent_region_id: String,
    trigger: String,
    campaign_seed: int,
    event_sequence: int,
    resolved_event_ids: Array[String]
) -> String:
    var matching := event_ids_for(parent_region_id, trigger)
    if matching.is_empty():
        return ""
    var unresolved: Array[String] = []
    for event_id: String in matching:
        if not resolved_event_ids.has(event_id):
            unresolved.append(event_id)
    var pool := unresolved if not unresolved.is_empty() else matching
    var seed_mix := absi(campaign_seed * 31 + event_sequence * 131 + parent_region_id.hash() + trigger.hash())
    return pool[seed_mix % pool.size()]


static func catalog_counts() -> Dictionary:
    var success_count := 0
    var failed_count := 0
    var parent_counts: Dictionary = {}
    for parent_region_id: String in parent_region_ids():
        parent_counts[parent_region_id] = 0
    for event: Dictionary in all_events():
        var parent_region_id := str(event.get("parent_region_id", ""))
        parent_counts[parent_region_id] = int(parent_counts.get(parent_region_id, 0)) + 1
        if str(event.get("trigger", "")) == TRIGGER_SUCCESS:
            success_count += 1
        elif str(event.get("trigger", "")) == TRIGGER_FAILED:
            failed_count += 1
    return {
        "events": all_events().size(),
        "options": all_events().size() * 2,
        "success_events": success_count,
        "failed_events": failed_count,
        "parent_regions": parent_region_ids().size(),
        "per_parent": parent_counts,
    }


static func _option(event_id: String, suffix: String, label: String, profile_id: String) -> Dictionary:
    var profile := _profile_config(profile_id)
    profile["option_id"] = "%s:%s" % [event_id, suffix]
    profile["label"] = label
    profile["profile_id"] = profile_id
    profile["story_flag"] = "story:%s:%s" % [event_id, profile_id]
    return profile


static func _profile_config(profile_id: String) -> Dictionary:
    match profile_id:
        "crew_rescue":
            return _profile(-4, -1, "residents", 2, "crew_guides", "community_stores", "screened_approach", 1, "shelter")
        "beacon_repair":
            return _profile(-3, -1, "lighthouse", 1, "beacon_watch", "phase_stock", "lit_corridor", 0, "signal")
        "route_preserve":
            return _profile(-2, 0, "route", 1, "route_guides", "salvage_exchange", "mapped_flank", 0, "frontier")
        "salvage_cache":
            return _profile(8, 1, "", 0, "scavenger_cell", "surplus_exchange", "contested_cache", 0, "frontier")
        "quiet_passage":
            return _profile(0, -2, "route", 1, "quiet_pilots", "standard", "quiet_passage", 1, "shelter")
        "open_records":
            return _profile(0, 0, "residents", 1, "archivist_circle", "echo_catalog", "documented_pursuit", 0, "witness")
        "seal_hazard":
            return _profile(-5, -2, "lighthouse", 1, "stormwardens", "weapon_exchange", "contained_pressure", 0, "signal")
        "veteran_patrol":
            return _profile(4, 0, "residents", 1, "veteran_rescuers", "legacy_exchange", "frontier_patrol", 1, "shelter")
        "rare_circuit":
            return _profile(-5, -1, "lighthouse", 1, "survey_fleet", "rare_circuit_stock", "charted_anomaly", 0, "signal")
        "mutual_aid":
            return _profile(-2, -1, "residents", 1, "mutual_aid_watch", "community_stores", "shared_watch", 2, "shelter")
        "controlled_risk":
            return _profile(6, 1, "route", 1, "pathfinder_cell", "high_risk_exchange", "escalated_route", 0, "frontier")
        "memory_vigil":
            return _profile(0, -1, "", 0, "witness_choir", "echo_catalog", "observed_pressure", 1, "witness")
    return _profile(0, 0, "", 0, "standard", "standard", "standard", 0, "witness")


static func _profile(
    salvage_delta: int,
    tension_delta: int,
    world_axis: String,
    world_amount: int,
    support_id: String,
    shop_modifier: String,
    threat_route: String,
    recovery_assist_delta: int,
    ending_bias: String
) -> Dictionary:
    return {
        "salvage_delta": salvage_delta,
        "tension_delta": tension_delta,
        "world_axis": world_axis,
        "world_amount": world_amount,
        "ending_bias": ending_bias,
        "next_modifier": {
            "modifier_id": "event:%s:%s" % [support_id, threat_route],
            "support_id": support_id,
            "shop_modifier": shop_modifier,
            "threat_route": threat_route,
            "recovery_assist_delta": recovery_assist_delta,
        },
    }


static func _event_rows() -> Array[Array]:
    return [
        ["ts_s01", "twilight_shipyard", TRIGGER_SUCCESS, "mira", "mira_dockmaster", "마지막 호각", "구조된 조선공들이 폐선의 호각을 울려 아직 살아 있는 작업반의 위치를 알립니다.", "사람부터 모은다", "crew_rescue", "호각을 등대 신호로 바꾼다", "beacon_repair"],
        ["ts_s02", "twilight_shipyard", TRIGGER_SUCCESS, "dojin", "dojin_rigger", "쇠사슬의 값", "리거 도진은 끊어진 계류 사슬을 수리하면 안전해지지만 귀한 부품을 소모한다고 보고합니다.", "계류로를 복구한다", "route_preserve", "부품을 회수해 다음 원정에 쓴다", "salvage_cache"],
        ["ts_s03", "twilight_shipyard", TRIGGER_SUCCESS, "mira", "mira_dockmaster", "불 꺼진 7번 선대", "7번 선대의 대피등 아래에서 떠나지 못한 가족 명부와 예비 전력함이 함께 발견됩니다.", "명부를 따라 가족을 찾는다", "crew_rescue", "예비 전력을 등대망에 연결한다", "beacon_repair"],
        ["ts_s04", "twilight_shipyard", TRIGGER_SUCCESS, "sori", "sori_cartographer", "조수표 없는 길", "지도사 소리는 조수표가 사라진 수로를 직접 측량하면 앞으로의 항로를 조용히 열 수 있다고 말합니다.", "새 항로를 표기한다", "quiet_passage", "위험 구역의 잔해부터 회수한다", "controlled_risk"],
        ["ts_f01", "twilight_shipyard", TRIGGER_FAILED, "mira", "mira_dockmaster", "후퇴선의 등불", "철수 중 남겨진 작업등이 추격자를 끌고 있습니다. 누군가는 등을 끄고 사람들을 돌아가야 합니다.", "사람을 데리고 우회한다", "mutual_aid", "등불을 미끼로 안전로를 만든다", "quiet_passage"],
        ["ts_f02", "twilight_shipyard", TRIGGER_FAILED, "dojin", "dojin_rigger", "무너진 크레인", "크레인이 항로를 막았지만 하부 창고에는 다음 수리에 쓸 수 있는 재료가 남아 있습니다.", "잔해를 고정해 길을 연다", "route_preserve", "창고 재료를 먼저 회수한다", "salvage_cache"],
        ["ts_f03", "twilight_shipyard", TRIGGER_FAILED, "sori", "sori_cartographer", "검은 파도의 간격", "패배 뒤에도 파도 사이에는 반복되는 빈틈이 보입니다. 소리는 그 틈을 기록할지 즉시 봉쇄할지 묻습니다.", "빈틈을 항로로 기록한다", "controlled_risk", "위험 표식을 촘촘히 세운다", "seal_hazard"],
        ["ts_f04", "twilight_shipyard", TRIGGER_FAILED, "mira", "mira_dockmaster", "남은 자의 식탁", "거점으로 돌아온 인원들이 보급을 나누자는 쪽과 다음 출항을 위해 비축하자는 쪽으로 갈립니다.", "부상자와 정비반에 나눈다", "mutual_aid", "필수 부품만 비축한다", "memory_vigil"],

        ["gg_s01", "glass_garden", TRIGGER_SUCCESS, "nara", "nara_lampwright", "유리꽃의 그림자", "램프라이트 나라가 빛을 반사하는 꽃잎을 등대 렌즈로 쓸 수 있지만 정원의 생태가 바뀔 수 있다고 경고합니다.", "낙화한 조각만 수리재로 쓴다", "beacon_repair", "정원을 피해 새 길을 만든다", "quiet_passage"],
        ["gg_s02", "glass_garden", TRIGGER_SUCCESS, "yeonhwa", "yeonhwa_gardener", "씨앗 금고", "정원사 연화는 피난민의 식량이 될 씨앗 금고와 값비싼 결정 수액 중 하나를 먼저 옮겨야 한다고 말합니다.", "씨앗 금고를 사람들에게 보낸다", "crew_rescue", "결정 수액을 회수한다", "salvage_cache"],
        ["gg_s03", "glass_garden", TRIGGER_SUCCESS, "nara", "nara_lampwright", "빛을 나누는 법", "복구한 프리즘은 한 구역을 밝게 비추거나 여러 길에 약한 표식을 뿌릴 수 있습니다.", "한 줄기 신호를 강화한다", "rare_circuit", "여러 갈림길에 표식을 나눈다", "route_preserve"],
        ["gg_s04", "glass_garden", TRIGGER_SUCCESS, "sori", "sori_cartographer", "온실의 비밀문", "폐온실 아래 오래된 밀수 통로가 드러났습니다. 빠르지만 불안정하고 주민들은 공개를 꺼립니다.", "주민과 규칙을 정해 보존한다", "quiet_passage", "위험을 감수하고 즉시 탐사한다", "controlled_risk"],
        ["gg_f01", "glass_garden", TRIGGER_FAILED, "yeonhwa", "yeonhwa_gardener", "깨진 수분망", "후퇴 충격으로 수분망이 깨져 피난민 구역과 등대 냉각로가 동시에 물을 요구합니다.", "피난민 급수를 먼저 복구한다", "mutual_aid", "등대 냉각로를 살린다", "beacon_repair"],
        ["gg_f02", "glass_garden", TRIGGER_FAILED, "nara", "nara_lampwright", "과열된 프리즘", "프리즘 폭주 흔적을 조사하면 다음 위협을 읽을 수 있지만 접근 자체가 위험합니다.", "폭주 패턴을 기록한다", "memory_vigil", "프리즘을 봉인한다", "seal_hazard"],
        ["gg_f03", "glass_garden", TRIGGER_FAILED, "sori", "sori_cartographer", "되돌아가는 길", "기존 길은 적에게 읽혔고 새 길은 아직 검증되지 않았습니다. 다음 출항의 방식부터 바꿔야 합니다.", "낯선 우회로를 개척한다", "controlled_risk", "기존 길에 감시조를 배치한다", "veteran_patrol"],
        ["gg_f04", "glass_garden", TRIGGER_FAILED, "yeonhwa", "yeonhwa_gardener", "유리비 뒤의 쉼터", "폭우 뒤 숨겨진 쉼터에서 낯선 생존자들과 잃어버린 원정대 표식이 함께 발견됩니다.", "생존자를 거점으로 인도한다", "crew_rescue", "원정대 표식을 추적한다", "memory_vigil"],

        ["fa_s01", "flooded_archive", TRIGGER_SUCCESS, "sion", "sion_archivist", "젖은 이름들", "기록관 시온은 물에 젖은 피난 명부와 전투 항로 기록 중 무엇을 먼저 복원할지 결정해 달라고 합니다.", "피난 명부를 복원한다", "open_records", "항로 기록을 복원한다", "route_preserve"],
        ["fa_s02", "flooded_archive", TRIGGER_SUCCESS, "hae", "hae_diver", "침수층의 숨", "잠수사 해가 봉인된 공기실에서 생존 신호와 희귀 회로 부품을 동시에 포착합니다.", "생존 신호를 따라간다", "crew_rescue", "회로 부품을 확보한다", "rare_circuit"],
        ["fa_s03", "flooded_archive", TRIGGER_SUCCESS, "sion", "sion_archivist", "거짓으로 남은 지도", "옛 지도는 안전로를 일부러 감춰 침략자를 속였습니다. 지금 공개하면 모두가 쓰지만 적도 배웁니다.", "전체 기록을 공개한다", "open_records", "거점 안내선만 남긴다", "quiet_passage"],
        ["fa_s04", "flooded_archive", TRIGGER_SUCCESS, "hae", "hae_diver", "수문 아래의 선택", "오래된 수문을 열면 잔해가 쓸려 나가지만 다른 기록층이 영구 침수될 수 있습니다.", "수문을 열어 항로를 확보한다", "controlled_risk", "기록층을 지키며 우회한다", "memory_vigil"],
        ["fa_f01", "flooded_archive", TRIGGER_FAILED, "sion", "sion_archivist", "패배 기록의 보존", "시온은 실패를 숨기면 사기는 지키지만 같은 실수를 반복할 것이라고 말합니다.", "실패 원인을 공개 기록한다", "memory_vigil", "대응 절차만 추려 배포한다", "veteran_patrol"],
        ["fa_f02", "flooded_archive", TRIGGER_FAILED, "hae", "hae_diver", "끊어진 생명줄", "철수 중 끊어진 잠수 생명줄을 다시 잇거나 남은 산소를 다음 구조 시도에 비축해야 합니다.", "생명줄을 복구한다", "mutual_aid", "산소를 비축하고 새 경로를 찾는다", "quiet_passage"],
        ["fa_f03", "flooded_archive", TRIGGER_FAILED, "sion", "sion_archivist", "추격자의 각주", "적이 남긴 표식에서 우리 기록 습관을 학습하고 있다는 단서가 나왔습니다.", "표식을 역추적해 관찰한다", "open_records", "기록 체계를 바꾸고 봉쇄한다", "seal_hazard"],
        ["fa_f04", "flooded_archive", TRIGGER_FAILED, "hae", "hae_diver", "빈 금고의 울림", "보급 금고는 비었지만 그 뒤 벽에서 다른 수로의 진동이 들립니다.", "수로를 뚫어 위험을 감수한다", "controlled_risk", "벽을 보강하고 구조대를 기다린다", "mutual_aid"],

        ["ar_s01", "ash_railway", TRIGGER_SUCCESS, "bora", "bora_railcaptain", "재를 가르는 기적", "철도대장 보라는 살아난 선로를 피난 열차에 줄지 전투 보급선에 줄지 결정해야 한다고 말합니다.", "피난 열차를 먼저 보낸다", "crew_rescue", "보급선을 먼저 안정화한다", "route_preserve"],
        ["ar_s02", "ash_railway", TRIGGER_SUCCESS, "gyeom", "gyeom_engineer", "기관차의 두 심장", "기관사 겸은 오래된 기관 하나를 살릴 부품과 이동 등대용 발전기를 동시에 완성할 수 없다고 보고합니다.", "기관차를 살린다", "veteran_patrol", "이동 등대 발전기를 만든다", "beacon_repair"],
        ["ar_s03", "ash_railway", TRIGGER_SUCCESS, "bora", "bora_railcaptain", "종착역 없는 표", "피난민들은 정착지를 원하지만 일부 철도대는 계속 전진해 바깥 세계와 연결하자고 주장합니다.", "안전한 중간 거점을 만든다", "mutual_aid", "외곽 정찰선을 연다", "controlled_risk"],
        ["ar_s04", "ash_railway", TRIGGER_SUCCESS, "gyeom", "gyeom_engineer", "불씨 운반차", "꺼지지 않는 불씨를 실은 화차는 등대망을 되살리거나 위험한 밤길을 단번에 통과하는 데 쓸 수 있습니다.", "불씨를 등대망에 나눈다", "rare_circuit", "화차를 선도차로 투입한다", "quiet_passage"],
        ["ar_f01", "ash_railway", TRIGGER_FAILED, "bora", "bora_railcaptain", "뒤집힌 객차", "후퇴로를 막은 객차 안에서 구조 신호가 들리지만 적의 추격도 가까워지고 있습니다.", "객차를 열고 구조한다", "mutual_aid", "우회선을 만들어 추격을 끊는다", "route_preserve"],
        ["ar_f02", "ash_railway", TRIGGER_FAILED, "gyeom", "gyeom_engineer", "식어가는 보일러", "보일러를 급히 살리면 다음 출항은 빠르지만 고장 위험이 남고, 완전 정비에는 보급이 듭니다.", "완전 정비한다", "seal_hazard", "위험을 감수하고 임시 수리한다", "controlled_risk"],
        ["ar_f03", "ash_railway", TRIGGER_FAILED, "bora", "bora_railcaptain", "철도대의 맹세", "연속된 실패로 대원들이 흔들립니다. 보라는 패배를 기억하는 의식을 치르거나 즉시 순찰을 재개하자고 제안합니다.", "희생자의 이름을 기록한다", "memory_vigil", "숙련 순찰대를 재편한다", "veteran_patrol"],
        ["ar_f04", "ash_railway", TRIGGER_FAILED, "gyeom", "gyeom_engineer", "재폭풍의 틈", "재폭풍이 선로를 덮었지만 그 안쪽의 열류가 적의 추적을 잠시 끊습니다.", "열류를 이용해 조용히 이동한다", "quiet_passage", "폭풍 속 잔해를 회수한다", "salvage_cache"],

        ["ef_s01", "eclipse_fortress", TRIGGER_SUCCESS, "yeon", "yeon_observer", "식의 가장자리", "관측관 연은 성채 정상에서 멀리 남은 불빛들을 발견합니다. 기록할지 즉시 신호를 보낼지 선택해야 합니다.", "관측 기록을 모두 남긴다", "memory_vigil", "등대 신호를 즉시 보낸다", "rare_circuit"],
        ["ef_s02", "eclipse_fortress", TRIGGER_SUCCESS, "tari", "tari_gatekeeper", "성문을 누구에게", "문지기 타리는 복구한 성문을 난민 통로로 열거나 위험 지역 조사대의 전진 기지로 만들 수 있다고 말합니다.", "난민 통로로 연다", "crew_rescue", "전진 기지로 쓴다", "veteran_patrol"],
        ["ef_s03", "eclipse_fortress", TRIGGER_SUCCESS, "yeon", "yeon_observer", "별 없는 지도", "별이 보이지 않는 하늘에서도 등대 간 시간차를 재면 새로운 항로를 만들 수 있습니다.", "신호망을 촘촘히 잇는다", "beacon_repair", "미지의 외곽 항로를 계산한다", "controlled_risk"],
        ["ef_s04", "eclipse_fortress", TRIGGER_SUCCESS, "tari", "tari_gatekeeper", "마지막 문서고", "성채 문서고에는 피난처 좌표와 적의 경계 교대 기록이 함께 남아 있습니다.", "피난처 좌표를 공개한다", "open_records", "경계 교대를 이용해 조용히 빠진다", "quiet_passage"],
        ["ef_f01", "eclipse_fortress", TRIGGER_FAILED, "yeon", "yeon_observer", "관측창의 금", "철수 충격으로 관측창에 금이 갔습니다. 수리하면 보급을 쓰지만 다음 변칙을 더 빨리 볼 수 있습니다.", "관측창을 완전 수리한다", "beacon_repair", "금의 패턴만 기록하고 철수한다", "memory_vigil"],
        ["ef_f02", "eclipse_fortress", TRIGGER_FAILED, "tari", "tari_gatekeeper", "닫히는 성문", "성문이 다시 닫히기 전에 뒤처진 인원을 기다리거나 다음 출항 장비를 먼저 옮겨야 합니다.", "뒤처진 인원을 기다린다", "mutual_aid", "장비를 옮겨 재도전을 준비한다", "salvage_cache"],
        ["ef_f03", "eclipse_fortress", TRIGGER_FAILED, "yeon", "yeon_observer", "식의 반복", "같은 패배 징후가 관측 기록에 반복됩니다. 연은 위험을 피해 순환 경로를 만들거나 원인을 직접 확인하자고 합니다.", "안전한 순환 경로를 만든다", "quiet_passage", "원인을 향해 다시 들어간다", "controlled_risk"],
        ["ef_f04", "eclipse_fortress", TRIGGER_FAILED, "tari", "tari_gatekeeper", "문밖의 합창", "철수 뒤 성문 밖 생존자들이 서로 다른 신호를 보내고 있습니다. 모두 들이거나 검증된 신호만 받을 수 있습니다.", "공동 감시 아래 모두 들인다", "crew_rescue", "신호 규칙을 정하고 단계적으로 연다", "open_records"],
    ]
