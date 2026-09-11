class_name MedievalCombatVisuals25D
extends Node3D

const WorldProjection25DScript = preload("res://game/presentation/world_projection_2_5d.gd")
const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")

const KNIGHT_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/characters/Knight.glb")
const BARBARIAN_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/characters/Barbarian.glb")
const MAGE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/characters/Mage.glb")
const ROGUE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/characters/Rogue_Hooded.glb")
const SWORD_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/weapons/sword_1handed.gltf")
const STAFF_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/weapons/staff.gltf")
const DAGGER_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/weapons/dagger.gltf")
const CROSSBOW_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/weapons/crossbow_1handed.gltf")
const ARROW_SCENE: PackedScene = preload("res://assets/third_party/kaykit_adventurers/weapons/arrow.gltf")

const TRAVEL_SECONDS: float = 0.38
const EFFECT_SECONDS: float = 0.82
const IMPACT_SECONDS: float = 0.18
const PLAYER_SCALE: float = 0.78
const ENEMY_SCALE: float = 0.72
const BOSS_SCALE: float = 1.05

var _player_root: Node3D
var _weapon_root: Node3D
var _enemy_root: Node3D
var _effect_root: Node3D
var _player_model: Node3D
var _weapon_model: Node3D
var _weapon_label: Label3D
var _weapon_visual_key: String = ""
var _enemy_visuals: Dictionary = {}
var _pending_by_target: Dictionary = {}
var _effects: Array[Dictionary] = []
var _runtime_enabled: bool = false


func _ready() -> void:
    _player_root = Node3D.new()
    _player_root.name = "PlayerVisual"
    add_child(_player_root)
    _weapon_root = Node3D.new()
    _weapon_root.name = "WeaponVisual"
    add_child(_weapon_root)
    _enemy_root = Node3D.new()
    _enemy_root.name = "EnemyVisuals"
    add_child(_enemy_root)
    _effect_root = Node3D.new()
    _effect_root.name = "CombatEffects"
    add_child(_effect_root)

    _player_model = _instantiate_scene(KNIGHT_SCENE, "KnightPlayer")
    if _player_model != null:
        _player_model.scale = Vector3.ONE * PLAYER_SCALE
        _player_root.add_child(_player_model)
        _play_idle(_player_model)

    _weapon_label = _make_label("", 34, 10)
    _weapon_label.position = Vector3(0.0, 2.18, 0.0)
    _player_root.add_child(_weapon_label)
    visible = false


func _process(delta: float) -> void:
    if not _runtime_enabled or delta <= 0.0:
        return
    _advance_effects(delta)


func sync_runtime(player: Node, encounter: Node, active: bool) -> void:
    _runtime_enabled = active
    visible = active
    if not active or not is_instance_valid(player) or not is_instance_valid(encounter):
        return

    var player_position: Vector2 = player.global_position
    _player_root.position = WorldProjection25DScript.gameplay_to_world3d(player_position, 0.03)
    _sync_player_facing(player)
    _sync_weapon(player)

    var raw_targets: Variant = encounter.call("combat_target_snapshot") if encounter.has_method("combat_target_snapshot") else []
    var seen: Dictionary = {}
    if raw_targets is Array:
        for raw_target: Variant in raw_targets:
            if not raw_target is Dictionary:
                continue
            var target: Dictionary = raw_target
            if not bool(target.get("active", false)):
                continue
            var entity_id := int(target.get("id", -1))
            if entity_id < 0:
                continue
            seen[entity_id] = true
            _sync_enemy(entity_id, target)

    var stale_ids: Array = []
    for raw_id: Variant in _enemy_visuals.keys():
        var entity_id := int(raw_id)
        if seen.has(entity_id) or int(_pending_by_target.get(entity_id, 0)) > 0:
            continue
        stale_ids.append(entity_id)
    for entity_id: int in stale_ids:
        _remove_enemy(entity_id)


func record_weapon_action(action: Dictionary, player: Node, encounter: Node) -> void:
    if not _runtime_enabled or str(action.get("type", "")) != "weapon_damage":
        return
    if not is_instance_valid(player):
        return

    var target_id := int(action.get("target_id", -1))
    if target_id < 0:
        return
    var origin_2d: Vector2 = player.global_position
    var target_2d := origin_2d + Vector2(280.0, 0.0)
    var current_health := maxi(1, int(action.get("damage", 1)) * 2)
    var max_health := current_health
    var visual: Dictionary = _enemy_visuals.get(target_id, {})
    if not visual.is_empty():
        target_2d = visual.get("gameplay_position", target_2d)
        current_health = int(visual.get("scheduled_health", visual.get("display_health", current_health)))
        max_health = maxi(1, int(visual.get("max_health", max_health)))
    elif is_instance_valid(encounter) and encounter.has_method("combat_target_snapshot"):
        var raw_targets: Variant = encounter.call("combat_target_snapshot")
        if raw_targets is Array:
            for raw_target: Variant in raw_targets:
                if raw_target is Dictionary and int(raw_target.get("id", -1)) == target_id:
                    var target: Dictionary = raw_target
                    target_2d = target.get("position", target_2d)
                    current_health = int(target.get("health", current_health)) + maxi(0, int(action.get("damage", 0)))
                    max_health = maxi(1, int(target.get("max_health", max_health)))
                    break

    var damage := maxi(1, int(action.get("damage", 1)))
    var end_health := maxi(0, current_health - damage)
    if not visual.is_empty():
        visual["scheduled_health"] = end_health
        visual["max_health"] = max_health
        _enemy_visuals[target_id] = visual

    _pending_by_target[target_id] = int(_pending_by_target.get(target_id, 0)) + 1
    _queue_effect(action, origin_2d, target_2d, current_health, end_health)


func presentation_spec() -> Dictionary:
    return {
        "player_asset": "res://assets/third_party/kaykit_adventurers/characters/Knight.glb",
        "enemy_assets": [
            "res://assets/third_party/kaykit_adventurers/characters/Barbarian.glb",
            "res://assets/third_party/kaykit_adventurers/characters/Mage.glb",
            "res://assets/third_party/kaykit_adventurers/characters/Rogue_Hooded.glb",
        ],
        "weapon_assets": {
            "piercing_lance": "res://assets/third_party/kaykit_adventurers/weapons/sword_1handed.gltf",
            "lantern_bolt": "res://assets/third_party/kaykit_adventurers/weapons/crossbow_1handed.gltf",
            "halo_orbit": "res://assets/third_party/kaykit_adventurers/weapons/dagger.gltf",
            "radiant_pulse": "res://assets/third_party/kaykit_adventurers/weapons/staff.gltf",
            "chain_arc": "res://assets/third_party/kaykit_adventurers/weapons/staff.gltf",
            "fan_shards": "res://assets/third_party/kaykit_adventurers/weapons/dagger.gltf",
        },
        "projectile_asset": "res://assets/third_party/kaykit_adventurers/weapons/arrow.gltf",
        "causal_stages": ["trigger", "travel", "impact", "damage", "death"],
        "supplemental_vfx_only": true,
    }


func visual_debug_snapshot() -> Dictionary:
    return {
        "runtime_enabled": _runtime_enabled,
        "player_asset_backed": is_instance_valid(_player_model),
        "enemy_visual_count": _enemy_visuals.size(),
        "weapon_visual_key": _weapon_visual_key,
        "active_effects": _effects.size(),
        "pending_targets": _pending_by_target.size(),
        "stages": presentation_spec().get("causal_stages", []).duplicate(),
    }


func configure_showcase() -> void:
    _runtime_enabled = true
    visible = true
    _player_root.position = WorldProjection25DScript.gameplay_to_world3d(Vector2.ZERO, 0.03)
    _set_weapon_visual("ember_bolt", "lantern_bolt")
    var showcase_targets := [
        {"id": 101, "position": Vector2(190.0, -55.0), "health": 48, "max_health": 48, "archetype": "swarm"},
        {"id": 102, "position": Vector2(365.0, 85.0), "health": 54, "max_health": 54, "archetype": "caster"},
        {"id": 103, "position": Vector2(510.0, -120.0), "health": 76, "max_health": 76, "archetype": "brute"},
    ]
    for target: Dictionary in showcase_targets:
        _sync_enemy(int(target["id"]), target)
    record_showcase_effect(
        {"type": "weapon_damage", "weapon_id": "ember_bolt", "delivery": "lantern_bolt", "trigger": "steady_fire", "transform": "ember_mark", "cause_id": "showcase-bolt", "chain_depth": 1, "damage": 18, "target_id": 101},
        Vector2.ZERO,
        Vector2(190.0, -55.0)
    )
    record_showcase_effect(
        {"type": "weapon_damage", "weapon_id": "arklight_arc", "delivery": "chain_arc", "trigger": "steady_fire", "transform": "ark_resonance", "cause_id": "showcase-chain", "chain_depth": 2, "damage": 14, "target_id": 102},
        Vector2.ZERO,
        Vector2(365.0, 85.0)
    )


func record_showcase_effect(action: Dictionary, origin: Vector2, target: Vector2) -> void:
    var target_id := int(action.get("target_id", -1))
    var visual: Dictionary = _enemy_visuals.get(target_id, {})
    var current_health := int(visual.get("display_health", maxi(1, int(action.get("damage", 1)) * 2)))
    var end_health := maxi(0, current_health - maxi(1, int(action.get("damage", 1))))
    if not visual.is_empty():
        visual["scheduled_health"] = end_health
        _enemy_visuals[target_id] = visual
    _pending_by_target[target_id] = int(_pending_by_target.get(target_id, 0)) + 1
    _queue_effect(action, origin, target, current_health, end_health)


func debug_step_effects(seconds: float) -> void:
    if seconds > 0.0:
        _advance_effects(seconds)


func _sync_player_facing(player: Node) -> void:
    if _player_model == null or not player is CharacterBody2D:
        return
    var velocity_2d := (player as CharacterBody2D).velocity
    if velocity_2d.length_squared() < 1.0:
        return
    _player_model.rotation.y = atan2(velocity_2d.x, velocity_2d.y)


func _sync_weapon(player: Node) -> void:
    if not player.has_method("weapon_status_snapshot"):
        return
    var status: Dictionary = player.call("weapon_status_snapshot")
    var weapon_id := str(status.get("weapon_id", ""))
    var recipe: Dictionary = status.get("recipe", {})
    var delivery := str(recipe.get("delivery", ""))
    _set_weapon_visual(weapon_id, delivery)


func _set_weapon_visual(weapon_id: String, delivery: String) -> void:
    var visual_key := "%s|%s" % [weapon_id, delivery]
    if visual_key == _weapon_visual_key and is_instance_valid(_weapon_model):
        return
    if is_instance_valid(_weapon_model):
        _weapon_model.queue_free()
        _weapon_model = null
    var weapon_scene := _weapon_scene_for_delivery(delivery)
    _weapon_model = _instantiate_scene(weapon_scene, "ActiveWeapon")
    if _weapon_model != null:
        _weapon_model.scale = Vector3.ONE * 0.52
        _weapon_model.rotation = Vector3(0.0, -0.5, -0.55)
        _weapon_model.position = Vector3(0.72, 0.92, 0.1)
        _player_root.add_child(_weapon_model)
    _weapon_visual_key = visual_key
    _weapon_label.text = "%s · %s" % [weapon_id, delivery]


func _sync_enemy(entity_id: int, target: Dictionary) -> void:
    var visual: Dictionary = _enemy_visuals.get(entity_id, {})
    if visual.is_empty():
        visual = _create_enemy_visual(entity_id, target)
        if visual.is_empty():
            return
        _enemy_visuals[entity_id] = visual

    var gameplay_position: Vector2 = target.get("position", visual.get("gameplay_position", Vector2.ZERO))
    visual["gameplay_position"] = gameplay_position
    var root_node := visual.get("root") as Node3D
    if is_instance_valid(root_node):
        root_node.position = WorldProjection25DScript.gameplay_to_world3d(gameplay_position, 0.03)

    var max_health := maxi(1, int(target.get("max_health", visual.get("max_health", 1))))
    visual["max_health"] = max_health
    if int(_pending_by_target.get(entity_id, 0)) <= 0:
        var health := maxi(0, int(target.get("health", visual.get("display_health", max_health))))
        visual["display_health"] = health
        visual["scheduled_health"] = health
    _refresh_enemy_label(visual)
    _enemy_visuals[entity_id] = visual


func _create_enemy_visual(entity_id: int, target: Dictionary) -> Dictionary:
    var archetype := str(target.get("archetype", "swarm"))
    var scene: PackedScene = BARBARIAN_SCENE
    var asset_id := "Barbarian"
    if archetype != "boss":
        match posmod(entity_id, 3):
            1:
                scene = MAGE_SCENE
                asset_id = "Mage"
            2:
                scene = ROGUE_SCENE
                asset_id = "Rogue_Hooded"
    var root_node := _instantiate_scene(scene, "Enemy_%d_%s" % [entity_id, asset_id])
    if root_node == null:
        return {}
    var base_scale := BOSS_SCALE if archetype == "boss" else ENEMY_SCALE
    root_node.scale = Vector3.ONE * base_scale
    root_node.rotation.y = PI
    _enemy_root.add_child(root_node)
    _play_idle(root_node)

    var label := _make_label("", 30 if archetype != "boss" else 38, 9)
    label.position = Vector3(0.0, 2.02 if archetype != "boss" else 2.35, 0.0)
    root_node.add_child(label)
    var health := maxi(0, int(target.get("health", target.get("max_health", 1))))
    var max_health := maxi(1, int(target.get("max_health", maxi(1, health))))
    var visual := {
        "root": root_node,
        "label": label,
        "asset_id": asset_id,
        "base_scale": base_scale,
        "display_health": health,
        "scheduled_health": health,
        "max_health": max_health,
        "gameplay_position": target.get("position", Vector2.ZERO),
        "dead_after_effect": false,
    }
    _refresh_enemy_label(visual)
    return visual


func _refresh_enemy_label(visual: Dictionary) -> void:
    var label := visual.get("label") as Label3D
    if not is_instance_valid(label):
        return
    var health := maxi(0, int(visual.get("display_health", 0)))
    var max_health := maxi(1, int(visual.get("max_health", 1)))
    label.text = "%s  HP %d/%d" % [str(visual.get("asset_id", "Enemy")), health, max_health]


func _remove_enemy(entity_id: int) -> void:
    var visual: Dictionary = _enemy_visuals.get(entity_id, {})
    var root_node := visual.get("root") as Node3D
    if is_instance_valid(root_node):
        root_node.queue_free()
    _enemy_visuals.erase(entity_id)
    _pending_by_target.erase(entity_id)


func _queue_effect(action: Dictionary, origin_2d: Vector2, target_2d: Vector2, start_health: int, end_health: int) -> void:
    var delivery := str(action.get("delivery", "lantern_bolt"))
    var color := _delivery_color(delivery)
    var origin := WorldProjection25DScript.gameplay_to_world3d(origin_2d, 1.05)
    var target := WorldProjection25DScript.gameplay_to_world3d(target_2d, 1.05)
    var projectile := _create_projectile(delivery, origin, target)
    var trail := _create_trail(origin, target, color)
    var impact := _create_impact(target, color)
    impact.visible = false
    var damage_label := _make_label("-%d" % maxi(1, int(action.get("damage", 1))), 42, 12)
    damage_label.position = target + Vector3(0.0, 1.65, 0.0)
    damage_label.modulate = color
    damage_label.visible = false
    _effect_root.add_child(damage_label)
    var trigger_label := _make_label("TRIGGER  %s" % str(action.get("weapon_id", "weapon")), 28, 8)
    trigger_label.position = origin + Vector3(0.0, 1.05, 0.0)
    trigger_label.modulate = color
    _effect_root.add_child(trigger_label)

    _effects.append({
        "age": 0.0,
        "duration": EFFECT_SECONDS,
        "travel": TRAVEL_SECONDS,
        "projectile": projectile,
        "trail": trail,
        "impact": impact,
        "damage_label": damage_label,
        "trigger_label": trigger_label,
        "origin": origin,
        "target": target,
        "target_id": int(action.get("target_id", -1)),
        "damage": maxi(1, int(action.get("damage", 1))),
        "delivery": delivery,
        "cause_id": str(action.get("cause_id", "")),
        "chain_depth": int(action.get("chain_depth", 0)),
        "start_health": start_health,
        "end_health": end_health,
        "hit_applied": false,
    })


func _advance_effects(delta: float) -> void:
    var retained: Array[Dictionary] = []
    for effect: Dictionary in _effects:
        var age := float(effect.get("age", 0.0)) + delta
        effect["age"] = age
        var travel := maxf(0.01, float(effect.get("travel", TRAVEL_SECONDS)))
        var t := clampf(age / travel, 0.0, 1.0)
        var origin: Vector3 = effect.get("origin", Vector3.ZERO)
        var target: Vector3 = effect.get("target", origin)
        var projectile := effect.get("projectile") as Node3D
        if is_instance_valid(projectile):
            projectile.position = origin.lerp(target, t)
            if projectile.position.distance_squared_to(target) > 0.0001:
                projectile.look_at(target, Vector3.UP)

        var trigger_label := effect.get("trigger_label") as Label3D
        if is_instance_valid(trigger_label):
            trigger_label.visible = age <= 0.20

        if age >= travel and not bool(effect.get("hit_applied", false)):
            effect["hit_applied"] = true
            _apply_display_hit(effect)
        if bool(effect.get("hit_applied", false)):
            var hit_age := age - travel
            var impact := effect.get("impact") as MeshInstance3D
            if is_instance_valid(impact):
                impact.visible = hit_age <= IMPACT_SECONDS
                var pulse := 1.0 + clampf(hit_age / IMPACT_SECONDS, 0.0, 1.0) * 2.5
                impact.scale = Vector3.ONE * pulse
            var damage_label := effect.get("damage_label") as Label3D
            if is_instance_valid(damage_label):
                damage_label.visible = hit_age <= 0.34
                damage_label.position = target + Vector3(0.0, 1.65 + hit_age * 1.4, 0.0)

        if age >= float(effect.get("duration", EFFECT_SECONDS)):
            _finish_effect(effect)
        else:
            retained.append(effect)
    _effects = retained


func _apply_display_hit(effect: Dictionary) -> void:
    var target_id := int(effect.get("target_id", -1))
    var visual: Dictionary = _enemy_visuals.get(target_id, {})
    if visual.is_empty():
        return
    visual["display_health"] = maxi(0, int(effect.get("end_health", 0)))
    visual["dead_after_effect"] = int(visual.get("display_health", 0)) <= 0
    var root_node := visual.get("root") as Node3D
    if is_instance_valid(root_node):
        var base_scale := float(visual.get("base_scale", ENEMY_SCALE))
        root_node.scale = Vector3.ONE * base_scale * (0.55 if bool(visual.get("dead_after_effect", false)) else 1.12)
    _refresh_enemy_label(visual)
    _enemy_visuals[target_id] = visual


func _finish_effect(effect: Dictionary) -> void:
    for key in ["projectile", "trail", "impact", "damage_label", "trigger_label"]:
        var node := effect.get(key) as Node
        if is_instance_valid(node):
            node.queue_free()
    var target_id := int(effect.get("target_id", -1))
    if target_id < 0:
        return
    var pending := maxi(0, int(_pending_by_target.get(target_id, 0)) - 1)
    if pending <= 0:
        _pending_by_target.erase(target_id)
        var visual: Dictionary = _enemy_visuals.get(target_id, {})
        if bool(visual.get("dead_after_effect", false)):
            _remove_enemy(target_id)
        else:
            var root_node := visual.get("root") as Node3D
            if is_instance_valid(root_node):
                root_node.scale = Vector3.ONE * float(visual.get("base_scale", ENEMY_SCALE))
    else:
        _pending_by_target[target_id] = pending


func _create_projectile(delivery: String, origin: Vector3, target: Vector3) -> Node3D:
    var scene: PackedScene = ARROW_SCENE
    var scale_factor := 0.42
    match delivery:
        "piercing_lance":
            scene = SWORD_SCENE
            scale_factor = 0.30
        "halo_orbit", "fan_shards":
            scene = DAGGER_SCENE
            scale_factor = 0.34
        "radiant_pulse", "chain_arc":
            scene = STAFF_SCENE
            scale_factor = 0.26
        _:
            scene = ARROW_SCENE
    var projectile := _instantiate_scene(scene, "Projectile_%s" % delivery)
    if projectile == null:
        return null
    projectile.scale = Vector3.ONE * scale_factor
    projectile.position = origin
    if origin.distance_squared_to(target) > 0.0001:
        projectile.look_at(target, Vector3.UP)
    _effect_root.add_child(projectile)
    return projectile


func _create_trail(origin: Vector3, target: Vector3, color: Color) -> MeshInstance3D:
    var distance := origin.distance_to(target)
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.035
    mesh.bottom_radius = 0.035
    mesh.height = maxf(0.05, distance)
    mesh.radial_segments = 8
    var trail := MeshInstance3D.new()
    trail.name = "CausalTrail"
    trail.mesh = mesh
    trail.material_override = _emissive_material(color)
    trail.position = (origin + target) * 0.5
    if distance > 0.001:
        trail.look_at_from_position(trail.position, target, Vector3.UP)
        trail.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    _effect_root.add_child(trail)
    return trail


func _create_impact(position_3d: Vector3, color: Color) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.14
    mesh.height = 0.28
    var impact := MeshInstance3D.new()
    impact.name = "ImpactPulse"
    impact.mesh = mesh
    impact.material_override = _emissive_material(color)
    impact.position = position_3d
    _effect_root.add_child(impact)
    return impact


func _emissive_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 2.8
    return material


func _delivery_color(delivery: String) -> Color:
    match delivery:
        "piercing_lance": return Color(1.0, 0.80, 0.34, 1.0)
        "lantern_bolt": return Color(1.0, 0.55, 0.20, 1.0)
        "halo_orbit": return Color(0.76, 0.46, 1.0, 1.0)
        "radiant_pulse": return Color(0.45, 0.84, 1.0, 1.0)
        "chain_arc": return Color(0.48, 0.68, 1.0, 1.0)
        "fan_shards": return Color(0.94, 0.42, 0.66, 1.0)
        _: return Color(1.0, 0.78, 0.34, 1.0)


func _weapon_scene_for_delivery(delivery: String) -> PackedScene:
    match delivery:
        "piercing_lance": return SWORD_SCENE
        "lantern_bolt": return CROSSBOW_SCENE
        "halo_orbit", "fan_shards": return DAGGER_SCENE
        "radiant_pulse", "chain_arc": return STAFF_SCENE
        _: return SWORD_SCENE


func _instantiate_scene(scene: PackedScene, node_name: String) -> Node3D:
    if scene == null:
        return null
    var instance := scene.instantiate()
    if not instance is Node3D:
        instance.queue_free()
        return null
    var node := instance as Node3D
    node.name = node_name
    return node


func _play_idle(root_node: Node) -> void:
    var players := root_node.find_children("*", "AnimationPlayer", true, false)
    for candidate: Node in players:
        if not candidate is AnimationPlayer:
            continue
        var player := candidate as AnimationPlayer
        var names := player.get_animation_list()
        if names.is_empty():
            continue
        var selected := ""
        for raw_name: StringName in names:
            var animation_name := str(raw_name)
            if "idle" in animation_name.to_lower():
                selected = animation_name
                break
        if selected.is_empty():
            selected = str(names[0])
        player.play(selected)
        return


func _make_label(value: String, font_size_value: int, outline_size_value: int) -> Label3D:
    var label := Label3D.new()
    label.text = value
    label.font_size = font_size_value
    label.outline_size = outline_size_value
    label.pixel_size = 0.0034
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    return label
