class_name MedievalWorldLayout
extends RefCounted

## Authoritative gameplay-space layout for the W04 medieval field alignment.
## Presentation remains non-authoritative, but its landmark coordinates are mirrored
## by tests against this model so visible structures cannot silently drift away from
## 2D collision/spawn semantics.

const WORLD_BOUNDS: Rect2 = Rect2(Vector2(-4608.0, -3072.0), Vector2(9216.0, 6144.0))
const CLEAR_CORRIDOR_WIDTH_GAMEPLAY: float = 300.0
const WORLD_EDGE_MARGIN: float = 24.0
const RIVER_SPAWN_HALF_WIDTH: float = 96.0
const RIVER_VISUAL_MIN_Y: float = -1460.0
const RIVER_VISUAL_MAX_Y: float = 1460.0
const FORD_HALF_HEIGHT: float = 220.0
const SPAWN_BLOCKER_PADDING: float = 48.0
const MIN_SPAWN_DISTANCE_FROM_ORIGIN: float = 280.0

const BRIDGE_GAMEPLAY_POSITION: Vector2 = Vector2.ZERO
const CHAPEL_GAMEPLAY_POSITION: Vector2 = Vector2(-760.0, -520.0)
const HAMLET_GAMEPLAY_POINTS := [
    Vector2(720.0, 520.0),
    Vector2(980.0, 660.0),
    Vector2(820.0, 880.0),
]
const HAMLET_WAYFINDING_CENTER: Vector2 = Vector2(840.0, 680.0)
const RIDGE_WAYFINDING_CENTER: Vector2 = Vector2(-900.0, 1750.0)
const WAYFINDING_LANDMARK_CENTERS := [
    BRIDGE_GAMEPLAY_POSITION,
    CHAPEL_GAMEPLAY_POSITION,
    HAMLET_WAYFINDING_CENTER,
    RIDGE_WAYFINDING_CENTER,
]

# Roads, the bridge/ford, river surface and distant ridge remain traversable
# presentation geometry. Buildings are the shared visual/gameplay blockers.
const SHARED_LANDMARK_BLOCKERS := [
    {
        "id": "moon_chapel",
        "rect": Rect2(Vector2(-850.0, -650.0), Vector2(180.0, 260.0)),
    },
    {
        "id": "east_hamlet_home_0",
        "rect": Rect2(Vector2(645.0, 450.0), Vector2(150.0, 140.0)),
    },
    {
        "id": "east_hamlet_home_1",
        "rect": Rect2(Vector2(900.0, 590.0), Vector2(160.0, 140.0)),
    },
    {
        "id": "east_hamlet_home_2",
        "rect": Rect2(Vector2(740.0, 810.0), Vector2(160.0, 140.0)),
    },
]


static func shared_blocker_rects() -> Array:
    var result: Array = []
    for blocker in SHARED_LANDMARK_BLOCKERS:
        result.append((blocker as Dictionary).get("rect", Rect2()))
    return result


static func is_inside_world(world_position: Vector2) -> bool:
    return WORLD_BOUNDS.has_point(world_position)


static func clamp_to_world(world_position: Vector2, margin: float = 0.0) -> Vector2:
    var safe_margin := clampf(margin, 0.0, minf(WORLD_BOUNDS.size.x, WORLD_BOUNDS.size.y) * 0.45)
    var minimum := WORLD_BOUNDS.position + Vector2.ONE * safe_margin
    var maximum := WORLD_BOUNDS.end - Vector2.ONE * safe_margin
    return Vector2(
        clampf(world_position.x, minimum.x, maximum.x),
        clampf(world_position.y, minimum.y, maximum.y)
    )


static func is_shared_landmark_blocked(world_position: Vector2) -> bool:
    for blocker_value in shared_blocker_rects():
        var blocker: Rect2 = blocker_value
        if blocker.has_point(world_position):
            return true
    return false


static func is_spawn_position_allowed(world_position: Vector2) -> bool:
    var inner_bounds := WORLD_BOUNDS.grow(-WORLD_EDGE_MARGIN)
    if not inner_bounds.has_point(world_position):
        return false
    for blocker_value in shared_blocker_rects():
        var blocker: Rect2 = blocker_value
        if blocker.grow(SPAWN_BLOCKER_PADDING).has_point(world_position):
            return false
    if _is_visual_river_spawn_exclusion(world_position):
        return false
    return true


static func resolve_spawn_position(candidate: Vector2, origin: Vector2) -> Vector2:
    var clamped_candidate := clamp_to_world(candidate, WORLD_EDGE_MARGIN)
    if (
        is_spawn_position_allowed(clamped_candidate)
        and clamped_candidate.distance_to(origin) >= MIN_SPAWN_DISTANCE_FROM_ORIGIN
    ):
        return clamped_candidate

    var radial := candidate - origin
    if radial.is_zero_approx():
        radial = Vector2.RIGHT
    var base_radius := maxf(360.0, radial.length())
    var base_angle := radial.angle()

    # Stable ring search: preserves deterministic spawn identity while nudging a
    # blocked visual spawn to nearby legal terrain without RNG or frame state.
    for ring_index in range(5):
        var radius := base_radius + float(ring_index) * 84.0
        for angle_index in range(24):
            var angle := base_angle + float(angle_index) * TAU / 24.0
            var probe := clamp_to_world(
                origin + Vector2.RIGHT.rotated(angle) * radius,
                WORLD_EDGE_MARGIN
            )
            if (
                probe.distance_to(origin) >= MIN_SPAWN_DISTANCE_FROM_ORIGIN
                and is_spawn_position_allowed(probe)
            ):
                return probe

    # The field is intentionally sparse enough that the search above should always
    # find a legal point. Keep a deterministic bounded fallback for malformed input.
    return clamp_to_world(origin + radial.normalized() * 420.0, WORLD_EDGE_MARGIN)


static func layout_spec() -> Dictionary:
    return {
        "world_bounds": WORLD_BOUNDS,
        "clear_corridor_width_gameplay": CLEAR_CORRIDOR_WIDTH_GAMEPLAY,
        "wayfinding_landmark_centers_gameplay": WAYFINDING_LANDMARK_CENTERS,
        "shared_blocker_count": SHARED_LANDMARK_BLOCKERS.size(),
        "spawn_excludes_visual_river": true,
        "ford_spawn_passage_half_height": FORD_HALF_HEIGHT,
        "presentation_authoritative": false,
        "gameplay_authority": "game/world/medieval_world_layout.gd",
    }


static func _is_visual_river_spawn_exclusion(world_position: Vector2) -> bool:
    if absf(world_position.x) > RIVER_SPAWN_HALF_WIDTH:
        return false
    if absf(world_position.y) <= FORD_HALF_HEIGHT:
        return false
    return (
        world_position.y >= RIVER_VISUAL_MIN_Y
        and world_position.y <= RIVER_VISUAL_MAX_Y
    )
