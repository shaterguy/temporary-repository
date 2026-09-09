extends RefCounted

const MIX_RATE: int = 32000
const MUSIC_SECONDS: float = 4.0
const REVIEW_SECONDS: float = 18.0
const LOW_REVIEW_GAIN: float = 0.12589254

const REGION: String = "shipyard_region_bed"
const TENSION: String = "shipyard_tension_layer"
const BOSS: String = "drowned_navigator_boss_layer"
const COMBAT: String = "arc_lance_combat_strike"
const CIRCUIT: String = "light_circuit_activation"
const WARNING: String = "cross_phase_warning"
const REWARD: String = "salvage_reward"

const IDS := PackedStringArray([REGION, TENSION, BOSS, COMBAT, CIRCUIT, WARNING, REWARD])
const SPECS := {
    REGION: {"category":"region","bus":"Music","duration":4.0,"loop":true,"priority":10,"cooldown":0.0,"gain_db":-7.0},
    TENSION: {"category":"combat_music","bus":"Music","duration":4.0,"loop":true,"priority":20,"cooldown":0.0,"gain_db":-9.0},
    BOSS: {"category":"boss_music","bus":"Music","duration":4.0,"loop":true,"priority":30,"cooldown":0.0,"gain_db":-8.0},
    COMBAT: {"category":"combat","bus":"SFX","duration":0.42,"loop":false,"priority":35,"cooldown":0.055,"gain_db":-8.0},
    CIRCUIT: {"category":"circuit","bus":"SFX","duration":0.82,"loop":false,"priority":70,"cooldown":0.20,"gain_db":-5.0},
    WARNING: {"category":"warning","bus":"Warning","duration":1.0,"loop":false,"priority":100,"cooldown":0.30,"gain_db":-2.0},
    REWARD: {"category":"reward","bus":"SFX","duration":1.18,"loop":false,"priority":82,"cooldown":0.25,"gain_db":-5.0},
}

static func cue_ids() -> PackedStringArray:
    return IDS

static func cue_spec(cue_id: String) -> Dictionary:
    var value = SPECS.get(cue_id, {})
    return value.duplicate(true) if value is Dictionary else {}
