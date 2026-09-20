extends RefCounted

const PLAYER_MELEE_RANGE_METERS := 1.35
const PLAYER_MELEE_DAMAGE := 34
const PLAYER_MELEE_ARC_DOT := 0.20
const ZOMBIE_ATTACK_RANGE_METERS := 0.82
const ZOMBIE_ATTACK_DAMAGE := 9
const ZOMBIE_ATTACK_SECONDS := 1.3
const ZOMBIE_CONTACT_SECONDS := 0.62

static func distance_meters(world_map: Node2D, a: Vector2, b: Vector2) -> float:
	return world_map.world_to_map(b - a).length() * preload("res://scripts/player_metrics.gd").CELL_METERS

static func in_melee_arc(world_map: Node2D, origin: Vector2, facing: Vector2, target: Vector2, range_meters: float=PLAYER_MELEE_RANGE_METERS) -> bool:
	if distance_meters(world_map, origin, target) > range_meters:
		return false
	var offset := target - origin
	if offset.length_squared() < 0.001:
		return true
	return facing.normalized().dot(offset.normalized()) >= PLAYER_MELEE_ARC_DOT
