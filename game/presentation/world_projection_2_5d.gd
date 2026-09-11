class_name WorldProjection25D
extends RefCounted

## Non-authoritative coordinate adapter for the medieval rebuild presentation layer.
## Gameplay remains Vector2/X-Y. Presentation maps that plane onto 3D/X-Z.

const DEFAULT_WORLD_TO_METERS: float = 0.01

static func gameplay_to_world3d(position_2d: Vector2, height: float = 0.0, world_to_meters: float = DEFAULT_WORLD_TO_METERS) -> Vector3:
	assert(world_to_meters > 0.0)
	return Vector3(position_2d.x * world_to_meters, height, position_2d.y * world_to_meters)


static func world3d_to_gameplay(position_3d: Vector3, world_to_meters: float = DEFAULT_WORLD_TO_METERS) -> Vector2:
	assert(world_to_meters > 0.0)
	return Vector2(position_3d.x / world_to_meters, position_3d.z / world_to_meters)


static func gameplay_size_to_world(size_2d: Vector2, world_to_meters: float = DEFAULT_WORLD_TO_METERS) -> Vector2:
	assert(world_to_meters > 0.0)
	return size_2d * world_to_meters
