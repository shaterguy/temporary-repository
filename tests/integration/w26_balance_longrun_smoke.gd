extends SceneTree

const EndgameScript = preload("res://game/world/endgame_progression_model.gd")
const RuntimeScript = preload("res://game/world/campaign_runtime_w22.gd")
const WorldScript = preload("res://game/world/world_campaign_model_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const CausalWeaponScript = preload("res://game/combat/causal_weapon_model.gd")
const CharacterTestScript = preload("res://tests/unit/test_character_expansion.gd")
const WeaponTestScript = preload("res://tests/unit/test_weapon_relic_expansion.gd")
const DoctrineTestScript = preload("res://tests/unit/test_disclosed_doctrine.gd")
const W22TestScript = preload("res://tests/unit/test_w22_endgame_progression.gd")
const SAVE_ROOT: String = "user://ci_w26_balance_longrun"
const MAX_ACTION_MILLISECONDS: int = 5000

var _failures: Array[String] = []
var _baseline_ok: bool = false
var _longrun_ok: bool = false
var _economy_ok: bool = false
var _recon_save_ok: bool = false
var _retry_ok: bool = false
var _weapon_ok: bool = false

func _initialize() -> void:
    call_deferred("_run_w26")

func _run_w26() -> void:
    _clear_save_root()
    var started := Time.get_ticks_msec()
    _test_retained_contracts()
    _test_longrun_variant_coverage()
    _test_weapon_bounds()
    _test_economy_and_recon()
    var elapsed := Time.get_ticks_msec() - started
    if elapsed > MAX_ACTION_MILLISECONDS:
        _failures.append("W26 balance/long-run actions exceeded %dms: %dms" % [MAX_ACTION_MILLISECONDS, elapsed])
    _clear_save_root()
    print("W26_BALANCE_ACTION_MS=%d" % elapsed)
    if _baseline_ok:
        print("W26_RETAINED_CONTRACTS=PASS")
    if _longrun_ok:
        print("W26_LONGRUN_VARIANTS=PASS")
    if _weapon_ok:
        print("W26_WEAPON_BALANCE=PASS")
    if _economy_ok:
        print("W26_ECONOMY=PASS")
    if _recon_save_ok:
        print("W26_RECON_SAVE=PASS")
    if _retry_ok:
        print("W26_SAME_SEED_RETRY=PASS")
    print("W26_HUMAN_FUN=PENDING")
    if _failures.is_empty():
        print("W26_BALANCE_LONGRUN=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W26_FAIL: %s" % failure)
    printerr("W26_BALANCE_LONGRUN=FAIL")
    quit(1)

func _test_retained_contracts() -> void:
    var before := _failures.size()
    _failures.append_array(CharacterTestScript.run())
    _failures.append_array(WeaponTestScript.run())
    _failures.append_array(DoctrineTestScript.run())
    _failures.append_array(W22TestScript.run())
    _baseline_ok = _failures.size() == before

func _test_longrun_variant_coverage() -> void:
    var before := _failures.size()
    var state: Dictionary = EndgameScript.default_state()
    var variants: Dictionary = {}
    var challenges: Dictionary = {}
    var pairs: Dictionary = {}
    for cycle: int in range(96):
        var choice_id := "deep_rescue_patrol" if cycle % 2 == 0 else "lighthouse_survey"
        var route_id := "risk_channel" if cycle % 2 == 0 else "supply_causeway"
        state = EndgameScript.begin_run(state, 260926, cycle, cycle + 1, choice_id, route_id, false)
        if state.is_empty():
            _failures.append("W26 long-run endgame generator failed at cycle %d" % cycle)
            break
        var active := EndgameScript.active_variant(state)
        var variant_id := str(active.get("variant_id", ""))
        var challenge_id := str(active.get("challenge_id", ""))
        variants[variant_id] = true
        challenges[challenge_id] = true
        pairs["%s|%s" % [variant_id, challenge_id]] = true
        state = EndgameScript.settle_run(state, "success", {"route_id": route_id}, _complete_observation(), "w26-longrun-%d" % cycle)
        if state.is_empty():
            _failures.append("W26 long-run endgame settlement failed at cycle %d" % cycle)
            break
    if variants.size() != EndgameScript.VARIANT_IDS.size():
        _failures.append("W26 96-run simulation did not cover all authored variants: %d/%d" % [variants.size(), EndgameScript.VARIANT_IDS.size()])
    if challenges.size() != EndgameScript.CHALLENGE_IDS.size():
        _failures.append("W26 96-run simulation did not cover all authored challenges: %d/%d" % [challenges.size(), EndgameScript.CHALLENGE_IDS.size()])
    if pairs.size() < 12:
        _failures.append("W26 96-run simulation exposed fewer than 12 distinct variant/challenge pairs: %d" % pairs.size())
    var summary := EndgameScript.summary(state)
    if int(summary.get("mastery_marks", 0)) != 96 or (summary.get("seed_history", []) as Array).size() != EndgameScript.MAX_SEED_HISTORY:
        _failures.append("W26 long-run horizontal mastery/history bounds drifted")
    _longrun_ok = _failures.size() == before

func _test_weapon_bounds() -> void:
    var before := _failures.size()
    var ids: Array[String] = WeaponPartCatalogScript.weapon_ids()
    if ids.size() != 18:
        _failures.append("W26 weapon audit expected 18 curated weapons, got %d" % ids.size())
    for weapon_id: String in ids:
        var recipe: Dictionary = WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
        var model = CausalWeaponScript.new()
        if not model.equip_curated_weapon(weapon_id):
            _failures.append("W26 weapon audit could not equip %s" % weapon_id)
            continue
        var trigger: Dictionary = WeaponPartCatalogScript.TRIGGERS.get(str(recipe.get("trigger", "")), {})
        var event := {"type": str(trigger.get("event", "")), "cause_id": "w26-%s" % weapon_id, "chain_depth": 0}
        var actions: Array[Dictionary] = model.resolve_event(event, _broad_weapon_context())
        if actions.is_empty():
            _failures.append("W26 weapon audit produced no causal action for %s" % weapon_id)
            continue
        if actions.size() > 4:
            _failures.append("W26 weapon %s exceeded bounded target count: %d" % [weapon_id, actions.size()])
        for action: Dictionary in actions:
            if int(action.get("damage", 0)) <= 0 or int(action.get("damage", 0)) > 32:
                _failures.append("W26 weapon %s left the audited damage band: %d" % [weapon_id, int(action.get("damage", 0))])
            if int(action.get("barrier_pressure", 0)) > 6:
                _failures.append("W26 weapon %s exceeded barrier pressure bound" % weapon_id)
    var dodge = CausalWeaponScript.new()
    dodge.equip_curated_weapon("dodge_fan")
    var dodge_actions: Array[Dictionary] = dodge.resolve_event({"type": "dodge_started", "cause_id": "w26-dodge-fan", "chain_depth": 0}, _broad_weapon_context())
    if dodge_actions.size() != 4:
        _failures.append("W26 phase_afterglow did not create the intended four-target dodge-fan tradeoff")
    var ward = CausalWeaponScript.new()
    ward.equip_curated_weapon("ward_halo")
    var ward_actions: Array[Dictionary] = ward.resolve_event({"type": "circuit_activated", "cause_id": "w26-ward-halo", "chain_depth": 0}, _broad_weapon_context())
    if ward_actions.is_empty() or int(ward_actions[0].get("damage", 0)) < 15:
        _failures.append("W26 ark_resonance did not reach the intended focused-hit floor")
    _weapon_ok = _failures.size() == before

func _test_economy_and_recon() -> void:
    var economy_before := _failures.size()
    var capped = RuntimeScript.new(SAVE_ROOT)
    if not bool(capped.start_new(1, 260927).get("ok", false)):
        _failures.append("W26 cap fixture could not start")
    else:
        capped.world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
        capped.world.state = WorldScript.STATE_POST_FINAL
        capped.world.salvage = 159
        if not bool(capped.begin_expedition("deep_rescue_patrol").get("ok", false)):
            _failures.append("W26 cap fixture could not depart")
        else:
            var cap_result: Dictionary = capped.settle_current("success", _complete_observation(), {})
            if not bool(cap_result.get("ok", false)) or int(capped.world.salvage) != RuntimeScript.W26_MAX_SALVAGE_RESERVE:
                _failures.append("W26 salvage reserve did not cap positive settlement growth at %d" % RuntimeScript.W26_MAX_SALVAGE_RESERVE)
    SaveStoreScript.clear_slot(1, SAVE_ROOT)
    var legacy = RuntimeScript.new(SAVE_ROOT)
    if bool(legacy.start_new(1, 260928).get("ok", false)):
        legacy.world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
        legacy.world.state = WorldScript.STATE_POST_FINAL
        legacy.world.salvage = 220
        if bool(legacy.begin_expedition("deep_rescue_patrol").get("ok", false)):
            var legacy_result: Dictionary = legacy.settle_current("success", _complete_observation(), {})
            if not bool(legacy_result.get("ok", false)) or int(legacy.world.salvage) != 220:
                _failures.append("W26 reserve migration destructively clamped an existing over-cap save")
    _economy_ok = _failures.size() == economy_before

    var recon_before := _failures.size()
    var runtime = RuntimeScript.new(SAVE_ROOT)
    if not bool(runtime.start_new(0, 260929).get("ok", false)):
        _failures.append("W26 recon fixture could not start")
    else:
        runtime.world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
        runtime.world.state = WorldScript.STATE_POST_FINAL
        runtime.world.salvage = 100
        var control = WorldScript.new()
        control.restore_snapshot(runtime.world.snapshot())
        var control_begin: Dictionary = control.begin_expedition("deep_rescue_patrol")
        var control_context: Dictionary = control.expedition_context()
        if not bool(control_begin.get("ok", false)):
            _failures.append("W26 recon control could not depart")
        var sequence_before := runtime.sequence
        var prepared: Dictionary = runtime.prepare_endgame_recon()
        if not bool(prepared.get("ok", false)) or not bool(prepared.get("applied", false)) or int(runtime.world.salvage) != 80 or runtime.sequence != sequence_before + 1:
            _failures.append("W26 recon preparation did not charge exactly 20 salvage and persist once")
        var after_prepare_sequence := runtime.sequence
        var duplicate: Dictionary = runtime.prepare_endgame_recon()
        if not bool(duplicate.get("ok", false)) or bool(duplicate.get("applied", true)) or int(runtime.world.salvage) != 80 or runtime.sequence != after_prepare_sequence:
            _failures.append("W26 duplicate recon preparation charged or saved twice")
        var reloaded = RuntimeScript.new(SAVE_ROOT)
        var loaded: Dictionary = reloaded.load_slot(0)
        if not bool(loaded.get("ok", false)) or int(reloaded.world.salvage) != 80 or not bool(reloaded.recon_snapshot().get("prepared", false)):
            _failures.append("W26 recon preparation did not survive a fresh runtime reload")
        elif bool(reloaded.begin_expedition("deep_rescue_patrol").get("ok", false)):
            var recon_context: Dictionary = reloaded.world.expedition_context()
            if int(recon_context.get("run_seed", 0)) != int(control_context.get("run_seed", -1)):
                _failures.append("W26 recon changed the deterministic run seed")
            if str(recon_context.get("variant_id", "")) == str(control_context.get("variant_id", "")) or str(recon_context.get("challenge_id", "")) == str(control_context.get("challenge_id", "")):
                _failures.append("W26 recon did not rotate both the next variant and challenge")
            if str(reloaded.world.active_expedition_modifier.get("endgame_recon_id", "")) != RuntimeScript.W26_ENDGAME_RECON_ID:
                _failures.append("W26 active recon marker was not preserved for runtime disclosure")
        else:
            _failures.append("W26 prepared recon could not start the next post-final expedition")
    _recon_save_ok = _failures.size() == recon_before

    var retry_before := _failures.size()
    var retry_runtime = RuntimeScript.new(SAVE_ROOT)
    if not bool(retry_runtime.start_new(2, 260930).get("ok", false)):
        _failures.append("W26 retry fixture could not start")
    else:
        retry_runtime.world.segment_index = WorldScript.CAMPAIGN_SEGMENTS
        retry_runtime.world.state = WorldScript.STATE_POST_FINAL
        retry_runtime.world.salvage = 100
        if not bool(retry_runtime.begin_expedition("deep_rescue_patrol").get("ok", false)):
            _failures.append("W26 retry fixture could not depart")
        else:
            var failed_context := retry_runtime.world.expedition_context()
            var failed: Dictionary = retry_runtime.settle_current("failed", _complete_observation(), {})
            if not bool(failed.get("ok", false)):
                _failures.append("W26 retry fixture could not settle failure")
            else:
                if retry_runtime.world.has_pending_story_event():
                    var story: Dictionary = retry_runtime.resolve_story_event(0)
                    if not bool(story.get("ok", false)):
                        _failures.append("W26 retry fixture could not resolve story gate")
                var recon_for_later: Dictionary = retry_runtime.prepare_endgame_recon()
                if not bool(recon_for_later.get("ok", false)):
                    _failures.append("W26 retry fixture could not prepare defensive deferred recon")
                var retry_result: Dictionary = retry_runtime.begin_endgame_retry()
                if not bool(retry_result.get("ok", false)):
                    _failures.append("W26 same-seed retry could not start with deferred recon")
                else:
                    var retry_context := retry_runtime.world.expedition_context()
                    for key: String in ["run_seed", "variant_id", "challenge_id"]:
                        if retry_context.get(key) != failed_context.get(key):
                            _failures.append("W26 deferred recon changed same-seed retry field %s" % key)
                    if not bool(retry_runtime.recon_snapshot().get("prepared", false)):
                        _failures.append("W26 same-seed retry consumed the defensive deferred recon at retry start")
    _retry_ok = _failures.size() == retry_before

func _complete_observation() -> Dictionary:
    return {"total_actions": 6, "ranged_actions": 6, "clustered_actions": 3, "phase_count": 2, "circuit_activation_count": 3, "weapon_id": "shade_halo", "relic_ids": ["fixture_relic_a", "fixture_relic_b"]}

func _broad_weapon_context() -> Dictionary:
    var targets: Array[Dictionary] = []
    for target_id: int in range(1, 9):
        targets.append({"id": target_id, "active": true})
    return {"phase": "shadow", "targets": targets, "crosses_circuit_boundary": true, "phase_transition_recent": true, "active_circuit_modules": ["snare"], "ark_pressure_active": true}

func _clear_save_root() -> void:
    for slot: int in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, SAVE_ROOT)
