extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const Metrics = preload("res://scripts/player_metrics.gd")

static func capacity(item_id: String) -> int:
	return int(Catalog.item(item_id).get("mag_capacity", 0)) if Catalog.is_firearm(item_id) else 0

static func ammo_item(item_id: String) -> String:
	return str(Catalog.item(item_id).get("ammo_item", ""))

static func magazine_item(item_id: String) -> String:
	return str(Catalog.item(item_id).get("magazine_item", ""))

static func spread_radians(moving: bool, crouching: bool) -> float:
	if crouching and not moving:
		return 0.012
	if moving:
		return 0.095
	return 0.038

static func resolved_direction(world_map: Node2D, screen_direction: Vector2, shot_index: int, moving: bool, crouching: bool) -> Vector2:
	var logical: Vector2 = world_map.world_to_map(screen_direction).normalized()
	var pattern: Array[float] = [0.0, -0.55, 0.38, -0.22, 0.72, -0.78, 0.18]
	var offset := pattern[shot_index % pattern.size()] * spread_radians(moving, crouching)
	return logical.rotated(offset)

static func first_target(world_map: Node2D, origin: Vector2, logical_direction: Vector2, zombies: Array[Node2D], range_meters: float) -> Node2D:
	var nearest: Node2D
	var nearest_along := INF
	for zombie: Node2D in zombies:
		if zombie.is_dead():
			continue
		var offset_meters: Vector2 = world_map.world_to_map(zombie.position - origin) * Metrics.CELL_METERS
		var along := offset_meters.dot(logical_direction)
		if along <= 0.0 or along > range_meters:
			continue
		var lateral := absf(offset_meters.cross(logical_direction))
		if lateral > 0.42:
			continue
		if along < nearest_along and clear_line(world_map, origin, zombie.position):
			nearest = zombie
			nearest_along = along
	return nearest

static func clear_line(world_map: Node2D, origin: Vector2, target: Vector2) -> bool:
	var samples := maxi(2, ceili(origin.distance_to(target) / 14.0))
	for index: int in range(1, samples):
		if not world_map.is_walkable_world(origin.lerp(target, float(index) / float(samples))):
			return false
	return true
