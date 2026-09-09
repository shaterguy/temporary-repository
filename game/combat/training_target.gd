extends Node2D

const MAX_HEALTH: int = 36

var health: int = MAX_HEALTH


func _ready() -> void:
    add_to_group("combat_targets")
    queue_redraw()


func is_targetable() -> bool:
    return health > 0


func take_damage(amount: int) -> void:
    if amount <= 0 or health <= 0:
        return
    health = maxi(0, health - amount)
    visible = health > 0
    queue_redraw()


func _draw() -> void:
    if health <= 0:
        return
    var health_ratio := float(health) / float(MAX_HEALTH)
    draw_circle(Vector2.ZERO, 14.0, Color(0.38, 0.50, 0.68, 0.95))
    draw_arc(
        Vector2.ZERO,
        19.0,
        -PI * 0.5,
        -PI * 0.5 + TAU * health_ratio,
        24,
        Color(0.72, 0.84, 1.0, 0.9),
        3.0,
        true
    )
