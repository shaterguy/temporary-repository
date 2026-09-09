class_name AndroidSafeArea
extends RefCounted

static func margins_for(window_size: Vector2i, viewport_size: Vector2i, safe_rect: Rect2i) -> Vector4i:
    if window_size.x <= 0 or window_size.y <= 0 or viewport_size.x <= 0 or viewport_size.y <= 0:
        return Vector4i.ZERO
    if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
        return Vector4i.ZERO

    var physical_left := clampi(safe_rect.position.x, 0, window_size.x)
    var physical_top := clampi(safe_rect.position.y, 0, window_size.y)
    var physical_right := clampi(
        window_size.x - (safe_rect.position.x + safe_rect.size.x),
        0,
        window_size.x
    )
    var physical_bottom := clampi(
        window_size.y - (safe_rect.position.y + safe_rect.size.y),
        0,
        window_size.y
    )
    var scale_x := float(viewport_size.x) / float(window_size.x)
    var scale_y := float(viewport_size.y) / float(window_size.y)
    return Vector4i(
        roundi(float(physical_left) * scale_x),
        roundi(float(physical_top) * scale_y),
        roundi(float(physical_right) * scale_x),
        roundi(float(physical_bottom) * scale_y)
    )
