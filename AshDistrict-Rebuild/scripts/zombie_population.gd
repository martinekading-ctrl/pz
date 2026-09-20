extends RefCounted

const INITIAL_TARGET := 16
const MIN_ALIVE := 10
const RESPAWN_BUDGET := 4
const RESPAWN_INTERVAL_SECONDS := 55.0
const MIN_RESPAWN_DISTANCE_METERS := 18.0

const OUTDOOR_CANDIDATES := [
	{"position":Vector2(42,55), "zone":"residential"},
	{"position":Vector2(34,35), "zone":"road"},
	{"position":Vector2(56,44), "zone":"road"},
	{"position":Vector2(25,59), "zone":"residential"},
	{"position":Vector2(39,26), "zone":"residential"},
	{"position":Vector2(55,34), "zone":"commercial"},
	{"position":Vector2(76,31), "zone":"commercial"},
	{"position":Vector2(82,55), "zone":"industrial"},
	{"position":Vector2(13,28), "zone":"residential"},
	{"position":Vector2(34,14), "zone":"residential"},
	{"position":Vector2(61,57), "zone":"residential"},
	{"position":Vector2(89,39), "zone":"road"},
	{"position":Vector2(9,43), "zone":"residential"},
	{"position":Vector2(78,10), "zone":"commercial"},
	{"position":Vector2(47,9), "zone":"road"},
	{"position":Vector2(91,61), "zone":"industrial"},
	{"position":Vector2(5,18), "zone":"residential"},
	{"position":Vector2(68,36), "zone":"commercial"},
]

const MIGRATION_CANDIDATES := [
	Vector2(118,82), Vector2(146,96), Vector2(92,112), Vector2(174,72),
	Vector2(207,124), Vector2(73,167), Vector2(245,92), Vector2(301,151),
	Vector2(121,211), Vector2(352,116), Vector2(192,248), Vector2(411,183),
]

static func build_initial_plan(world_map: Node2D) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for candidate: Dictionary in OUTDOOR_CANDIDATES:
		if plan.size() >= 12:
			break
		var logical: Vector2 = candidate.position
		if not valid_spawn(world_map, logical, plan, 1.5):
			continue
		plan.append(profile(logical, str(candidate.zone), "", false, plan.size()))

	for building: Node2D in [world_map.blue_house, world_map.store_building]:
		var points := interior_points(world_map, building, 2)
		for logical: Vector2 in points:
			plan.append(profile(logical, "interior", str(building.name), true, plan.size()))

	for candidate: Dictionary in OUTDOOR_CANDIDATES:
		if plan.size() >= INITIAL_TARGET:
			break
		var logical: Vector2 = candidate.position
		if valid_spawn(world_map, logical, plan, 1.2):
			plan.append(profile(logical, str(candidate.zone), "", false, plan.size()))
	return plan

static func interior_points(world_map: Node2D, building: Node2D, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var area: Rect2 = building.get_search_area()
	var candidates: Array[Vector2] = []
	var y := area.position.y + 0.8
	while y < area.end.y - 0.8:
		var x := area.position.x + 0.8
		while x < area.end.x - 0.8:
			var point := Vector2(x, y)
			if world_map.is_walkable_world(world_map.map_to_world(point)):
				candidates.append(point)
			x += 1.4
		y += 1.4
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(world_map.world_to_map(building.door_midpoint())) > b.distance_squared_to(world_map.world_to_map(building.door_midpoint()))
	)
	for point: Vector2 in candidates:
		var separated := true
		for existing: Vector2 in result:
			if existing.distance_to(point) < 3.0:
				separated = false
				break
		if separated:
			result.append(point)
		if result.size() >= count:
			break
	return result

static func profile(logical: Vector2, zone: String, building_id: String, sleeping: bool, index: int) -> Dictionary:
	return {
		"logical_position":logical,
		"zone":zone,
		"home_building_id":building_id,
		"sleeping":sleeping,
		"corpse_loot":corpse_loot(index, zone),
	}

static func corpse_loot(index: int, zone: String) -> Dictionary:
	var loot := {}
	match index % 7:
		0: loot = {"energy_bar":1}
		1: loot = {"parts":1}
		2: loot = {"bandage":1}
		3: loot = {"soda":1}
		4: loot = {"painkillers":1, "disinfectant":1} if zone == "commercial" else {"painkillers":1}
		5: loot = {"pistol_ammo":2} if zone in ["commercial", "road"] else {"food":1}
		_: loot = {"duct_tape":1, "bandage":1} if zone == "commercial" else {}
	return loot

static func valid_spawn(world_map: Node2D, logical: Vector2, plan: Array[Dictionary], separation_cells: float) -> bool:
	if not Rect2(Vector2.ZERO, Vector2(world_map.MAP_SIZE)).has_point(logical):
		return false
	if not world_map.is_walkable_world(world_map.map_to_world(logical)):
		return false
	for entry: Dictionary in plan:
		if logical.distance_to(Vector2(entry.logical_position)) < separation_cells:
			return false
	return true

static func zone_label(zone: String) -> String:
	return {
		"residential":"住宅区",
		"commercial":"商业区",
		"industrial":"工业边缘",
		"road":"道路",
		"interior":"建筑内部",
		"migration":"迁入者",
	}.get(zone, "未知区域")
