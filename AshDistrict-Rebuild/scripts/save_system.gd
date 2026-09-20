extends RefCounted

const SAVE_VERSION := 7
const MAP_SCHEMA := "ash_district_slice_v1"
const Catalog = preload("res://scripts/item_catalog.gd")
const WeaponRules = preload("res://scripts/weapon_rules.gd")
const Survival = preload("res://scripts/survival_rules.gd")
const InjuryRules = preload("res://scripts/injury_rules.gd")
const Population = preload("res://scripts/zombie_population.gd")
const LootProfiles = preload("res://scripts/loot_profiles.gd")
const ClothingRules = preload("res://scripts/clothing_rules.gd")
const UtilityRules = preload("res://scripts/utility_rules.gd")
const SkillRules = preload("res://scripts/skill_rules.gd")

static func capture_state(game: Node2D) -> Dictionary:
	var buildings: Array[Dictionary] = []
	for building: Node2D in game.world_map.interactive_buildings:
		var containers: Array[Dictionary] = []
		for item: Dictionary in building.furniture:
			containers.append({
				"remaining": item.remaining.duplicate(true),
				"searched": bool(item.get("searched", false)),
				"weapon_durability": item.get("weapon_durability", {}).duplicate(true),
				"firearm_loaded": item.get("firearm_loaded", {}).duplicate(true),
				"clothing_durability": item.get("clothing_durability", {}).duplicate(true),
			})
		var doors := {"primary": door_state(building.door_component)}
		if has_property(building, "second_door") and is_instance_valid(building.second_door):
			doors["second"] = door_state(building.second_door)
		if has_property(building, "rear_door") and is_instance_valid(building.rear_door):
			doors["rear"] = door_state(building.rear_door)
		buildings.append({
			"id": str(building.name),
			"doors": doors,
			"containers": containers,
			"barricades": building.barricade_state(),
		})

	var ground: Array[Dictionary] = []
	for item: Dictionary in game.ground_items:
		var logical: Vector2 = game.world_map.world_to_map(item.position)
		var saved := {"key": str(item.key), "logical_position": [logical.x, logical.y]}
		if item.has("durability"):
			saved["durability"] = float(item.durability)
		if item.has("loaded_ammo"):
			saved["loaded_ammo"] = int(item.loaded_ammo)
		ground.append(saved)

	var zombies: Array[Dictionary] = []
	for zombie: Node2D in game.zombies:
		var logical: Vector2 = game.world_map.world_to_map(zombie.position)
		var investigate_logical: Vector2 = game.world_map.world_to_map(zombie.investigate_target)
		zombies.append({
			"logical_position": [logical.x, logical.y],
			"health": int(zombie.health),
			"state": int(zombie.state),
			"alerted": bool(zombie.alerted),
			"dormant": bool(zombie.dormant),
			"spawn_zone": str(zombie.spawn_zone),
			"home_building_id": str(zombie.home_building_id),
			"attack_cooldown": float(zombie.attack_cooldown),
			"investigate_logical_position": [investigate_logical.x, investigate_logical.y],
			"investigate_time": float(zombie.investigate_time),
			"corpse_inventory": zombie.corpse_inventory.duplicate(true),
			"corpse_searched": bool(zombie.corpse_searched),
		})

	var player_logical: Vector2 = game.world_map.world_to_map(game.player.position)
	var vehicles: Array[Dictionary]=[]
	for vehicle: Node2D in game.world_map.vehicles:
		var vehicle_logical: Vector2=game.world_map.world_to_map(vehicle.position)
		vehicles.append({
			"id":str(vehicle.vehicle_id),
			"logical_position":[vehicle_logical.x,vehicle_logical.y],
			"heading":[float(vehicle.heading_logical.x),float(vehicle.heading_logical.y)],
			"fuel_liters":float(vehicle.fuel_liters),
			"condition":float(vehicle.condition),
			"trunk":vehicle.trunk.duplicate(true),
		})
	return {
		"version": SAVE_VERSION,
		"map_schema": MAP_SCHEMA,
		"loot_revision": LootProfiles.REVISION,
		"saved_unix_time": int(Time.get_unix_time_from_system()),
		"player": {"logical_position": [player_logical.x, player_logical.y]},
		"world": {
			"game_time_minutes": float(game.game_time_minutes),
			"time_multiplier": float(game.time_multiplier),
			"fresh_food_expiry_minutes": float(game.fresh_food_expiry_minutes),
			"power_cutoff_minutes": float(game.power_cutoff_minutes),
			"water_cutoff_minutes": float(game.water_cutoff_minutes),
		},
		"needs": game.needs.duplicate(true),
		"injuries": game.injuries.duplicate(true),
		"skills": game.skills.duplicate(true),
		"vehicles":vehicles,
		"active_vehicle_id":str(game.active_vehicle.vehicle_id) if is_instance_valid(game.active_vehicle) else "",
		"inventory": game.inventory.duplicate(true),
		"equipment": game.equipment.duplicate(true),
		"clothing_equipment": game.clothing_equipment.duplicate(true),
		"clothing_durability": game.clothing_durability.duplicate(true),
		"active_weapon_slot": str(game.active_weapon_slot),
		"weapon_durability": game.weapon_durability.duplicate(true),
		"firearm_loaded": game.firearm_loaded.duplicate(true),
		"shot_sequence": int(game.shot_sequence),
		"ground_items": ground,
		"buildings": buildings,
		"zombies": zombies,
		"population": {
			"respawn_budget":int(game.population_respawn_budget),
			"timer":float(game.population_timer),
			"seed_cursor":int(game.population_seed_cursor),
			"next_id":int(game.population_next_id),
		},
		"safehouse": {
			"building_id":str(game.safehouse_building_id),
			"spawn_logical":[float(game.safehouse_spawn_logical.x),float(game.safehouse_spawn_logical.y)],
		},
	}

static func apply_state(game: Node2D, data: Dictionary) -> bool:
	if not validate(data):
		return false
	if is_instance_valid(game.backpack):
		game.close_backpack()
	if is_instance_valid(game.loot_overlay):
		game.close_loot()
	if is_instance_valid(game.corpse_overlay):
		game.close_corpse_loot()
	if is_instance_valid(game.health_overlay):
		game.close_health_panel()
	if is_instance_valid(game.crafting_overlay):
		game.close_crafting()
	if is_instance_valid(game.skills_overlay):
		game.close_skills_panel(false)
	if is_instance_valid(game.vehicle_overlay):
		game.close_vehicle_panel()
	game.clear_vehicle_occupancy()
	if is_instance_valid(game.game_over_overlay):
		game.game_over_overlay.queue_free()
		game.game_over_overlay = null
	game.searching = -1
	game.search_time = 0.0
	game.search_building = null
	game.simulation_paused = false
	game.player_invulnerability = 0.0

	var player_position: Array = data.player.logical_position
	game.player.position = game.world_map.map_to_world(Vector2(float(player_position[0]), float(player_position[1])))
	game.game_time_minutes = float(data.world.game_time_minutes)
	game.time_multiplier = clampf(float(data.world.time_multiplier), 1.0, 4.0)
	game.fresh_food_expiry_minutes = float(data.world.get("fresh_food_expiry_minutes", game.game_time_minutes + 3600.0))
	game.power_cutoff_minutes = float(data.world.get("power_cutoff_minutes", UtilityRules.DEFAULT_POWER_CUTOFF_MINUTES))
	game.water_cutoff_minutes = float(data.world.get("water_cutoff_minutes", UtilityRules.DEFAULT_WATER_CUTOFF_MINUTES))
	var need_defaults := {"health":100.0, "food":100.0, "water":100.0, "stamina":100.0, "fatigue":0.0, "pain":0.0, "infection":0.0, "pain_relief":0.0}
	for key: String in need_defaults:
		var maximum := 180.0 if key == "pain_relief" else 100.0
		game.needs[key] = clampf(float(data.needs.get(key, need_defaults[key])), 0.0, maximum)
	game.needs["bleeding"] = maxf(0.0, float(data.needs.get("bleeding", 0.0)))
	game.injuries = InjuryRules.sanitize(data.get("injuries", {})) if data.has("injuries") else InjuryRules.migrate_legacy_bleeding(float(game.needs.bleeding))
	game.skills = SkillRules.sanitize(data.get("skills",{}))
	game.fitness_xp_seconds = 0.0
	InjuryRules.sync_needs(game.injuries, game.needs)

	var restored_inventory := {}
	for item_id in Catalog.ITEMS.keys():
		restored_inventory[item_id] = maxi(0, int(data.inventory.get(item_id, 0)))
	game.inventory = restored_inventory
	game.equipment = {
		"primary": valid_owned_weapon(game, str(data.equipment.get("primary", ""))),
		"secondary": valid_owned_weapon(game, str(data.equipment.get("secondary", ""))),
	}
	game.active_weapon_slot = str(data.active_weapon_slot) if str(data.active_weapon_slot) in ["primary", "secondary"] else "primary"
	game.weapon_durability = restore_weapon_durability(game, data.weapon_durability)
	game.clothing_durability = restore_clothing_durability(game, data.clothing_durability)
	game.clothing_equipment = restore_clothing_equipment(game, data.clothing_equipment)
	game.firearm_loaded = restore_firearm_loaded(game, data.get("firearm_loaded", {}))
	game.shot_sequence = maxi(0, int(data.get("shot_sequence", 0)))
	game.cancel_reload()
	var vehicle_lookup:={}
	for vehicle: Node2D in game.world_map.vehicles:
		vehicle.reset_default()
		vehicle_lookup[str(vehicle.vehicle_id)]=vehicle
	for saved_vehicle: Dictionary in data.get("vehicles",[]):
		var vehicle: Node2D=vehicle_lookup.get(str(saved_vehicle.get("id","")))
		if vehicle==null or not valid_pair(saved_vehicle.get("logical_position",[])):
			continue
		var position: Array=saved_vehicle.logical_position
		var heading: Array=saved_vehicle.get("heading",[1.0,0.0])
		vehicle.position=game.world_map.map_to_world(Vector2(float(position[0]),float(position[1])))
		vehicle.heading_logical=Vector2(float(heading[0]),float(heading[1])).normalized() if valid_pair(heading) else Vector2.RIGHT
		vehicle.fuel_liters=clampf(float(saved_vehicle.get("fuel_liters",18.0)),0.0,45.0)
		vehicle.condition=clampf(float(saved_vehicle.get("condition",82.0)),0.0,100.0)
		vehicle.trunk=sanitize_item_counts(saved_vehicle.get("trunk",{}))
		vehicle.speed_mps=0.0
		vehicle.update_pose()

	game.ground_items.clear()
	for item: Dictionary in data.ground_items:
		var position: Array = item.logical_position
		var restored := {
			"key": str(item.key),
			"position": game.world_map.map_to_world(Vector2(float(position[0]), float(position[1]))),
		}
		if item.has("durability"):
			restored["durability"] = float(item.durability)
		if item.has("loaded_ammo"):
			restored["loaded_ammo"] = maxi(0, int(item.loaded_ammo))
		game.ground_items.append(restored)

	var building_lookup := {}
	for building: Node2D in game.world_map.interactive_buildings:
		building_lookup[str(building.name)] = building
	var saved_safehouse: Dictionary = data.get("safehouse", {})
	var safehouse_id := str(saved_safehouse.get("building_id", ""))
	var safehouse_position: Array = saved_safehouse.get("spawn_logical", [0.0,0.0])
	if not safehouse_id.is_empty() and building_lookup.has(safehouse_id) and valid_pair(safehouse_position):
		game.safehouse_building_id = safehouse_id
		game.safehouse_spawn_logical = Vector2(float(safehouse_position[0]),float(safehouse_position[1]))
	else:
		game.safehouse_building_id = ""
		game.safehouse_spawn_logical = Vector2.ZERO
	var saved_loot_revision := int(data.get("loot_revision", 0))
	for saved_building: Dictionary in data.buildings:
		var building: Node2D = building_lookup.get(str(saved_building.id))
		if building == null:
			continue
		var containers: Array = saved_building.containers
		for index in mini(containers.size(), building.furniture.size()):
			var searched := bool(containers[index].get("searched", false))
			var restored_remaining := sanitize_item_counts(containers[index].remaining)
			if saved_loot_revision < LootProfiles.REVISION and not searched:
				var seeded_remaining: Dictionary = building.furniture[index].remaining
				for item_id: String in Catalog.LOOT_EXPANSION_IDS:
					var seeded_count := int(seeded_remaining.get(item_id, 0))
					if seeded_count > 0:
						restored_remaining[item_id] = seeded_count
			building.furniture[index].remaining = restored_remaining
			building.furniture[index]["searched"] = searched
			building.furniture[index]["weapon_durability"] = containers[index].get("weapon_durability", {}).duplicate(true)
			building.furniture[index]["firearm_loaded"] = containers[index].get("firearm_loaded", {}).duplicate(true)
			building.furniture[index]["clothing_durability"] = containers[index].get("clothing_durability", {}).duplicate(true)
		var doors: Dictionary = saved_building.doors
		apply_door_state(building.door_component, doors.get("primary", {}))
		if doors.has("second") and has_property(building, "second_door") and is_instance_valid(building.second_door):
			apply_door_state(building.second_door, doors.second)
		if doors.has("rear") and has_property(building, "rear_door") and is_instance_valid(building.rear_door):
			apply_door_state(building.rear_door, doors.rear)
		building.apply_barricade_state(saved_building.get("barricades", []))
		building.update_player(game.player.position, 0.0)

	game.clear_zombies()
	game.population_next_id = 0
	for index: int in data.zombies.size():
		var saved_zombie: Dictionary = data.zombies[index]
		var position: Array = saved_zombie.logical_position
		var logical_position := Vector2(float(position[0]), float(position[1]))
		var spawn_profile := {
			"zone":str(saved_zombie.get("spawn_zone", "road")),
			"home_building_id":str(saved_zombie.get("home_building_id", "")),
			"sleeping":bool(saved_zombie.get("dormant", false)),
			"corpse_loot":sanitize_item_counts(saved_zombie.get("corpse_inventory", {})),
		}
		var zombie: Node2D = game.spawn_zombie(logical_position, spawn_profile)
		zombie.health = maxi(0, int(saved_zombie.health))
		zombie.state = int(saved_zombie.state)
		zombie.alerted = bool(saved_zombie.alerted)
		zombie.dormant = bool(saved_zombie.get("dormant", zombie.state == zombie.State.SLEEPING))
		zombie.corpse_searched = bool(saved_zombie.get("corpse_searched", false))
		zombie.attack_cooldown = maxf(0.0, float(saved_zombie.attack_cooldown))
		var investigate_position: Array = saved_zombie.get("investigate_logical_position", position)
		zombie.investigate_target = game.world_map.map_to_world(Vector2(float(investigate_position[0]), float(investigate_position[1])))
		zombie.investigate_time = maxf(0.0, float(saved_zombie.get("investigate_time", 0.0)))
		zombie.queue_redraw()
	var population: Dictionary = data.get("population", {})
	game.population_respawn_budget = maxi(0, int(population.get("respawn_budget", Population.RESPAWN_BUDGET)))
	game.population_timer = maxf(0.0, float(population.get("timer", Population.RESPAWN_INTERVAL_SECONDS)))
	game.population_seed_cursor = maxi(0, int(population.get("seed_cursor", 0))) % Population.MIGRATION_CANDIDATES.size()
	game.population_next_id = maxi(game.population_next_id, int(population.get("next_id", game.population_next_id)))
	game.population_enabled = not data.zombies.is_empty()
	game.restore_vehicle_occupancy(str(data.get("active_vehicle_id","")))

	game.validate_equipment()
	game.stamina_recovery_delay = 0.0
	game.update_player_condition_effects()
	game.update_world_lighting()
	game.last_player_building_id = game.current_player_building_id()
	game.refresh_player_control()
	game.update_survival_hud()
	return true

static func write_atomic(path: String, data: Dictionary) -> Dictionary:
	if not validate(data):
		return {"ok": false, "error": "存档数据校验失败"}
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "无法创建临时存档"}
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(path):
		var copy_error := DirAccess.copy_absolute(absolute_path, absolute_backup)
		if copy_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return {"ok": false, "error": "无法创建存档备份"}
		DirAccess.remove_absolute(absolute_path)
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_path)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(absolute_backup, absolute_path)
		return {"ok": false, "error": "无法提交存档"}
	return {"ok": true, "path": path}

static func load_file(path: String) -> Dictionary:
	var data := read_valid(path)
	if not data.is_empty():
		return {"ok": true, "data": data, "recovered": false}
	var backup := read_valid(path + ".bak")
	if not backup.is_empty():
		return {"ok": true, "data": backup, "recovered": true}
	return {"ok": false, "error": "没有可用存档"}

static func read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	parsed = migrate(parsed)
	if not validate(parsed):
		return {}
	return parsed

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version := int(data.get("version", -1))
	if version == 1:
		data["safehouse"] = {"building_id":"", "spawn_logical":[0.0,0.0]}
		data["version"] = 2
		version = 2
	if version == 2:
		data["loot_revision"] = 0
		if typeof(data.get("world", {})) == TYPE_DICTIONARY and not data.world.has("fresh_food_expiry_minutes"):
			data.world["fresh_food_expiry_minutes"] = float(data.world.get("game_time_minutes", 3380.0)) + 3600.0
		data["version"] = 3
		version = 3
	if version == 3:
		data["clothing_equipment"] = {"head":"", "torso":"", "legs":"", "feet":""}
		data["clothing_durability"] = {}
		data["version"] = 4
		version = 4
	if version == 4:
		if typeof(data.get("world",{})) == TYPE_DICTIONARY:
			data.world["power_cutoff_minutes"] = UtilityRules.DEFAULT_POWER_CUTOFF_MINUTES
			data.world["water_cutoff_minutes"] = UtilityRules.DEFAULT_WATER_CUTOFF_MINUTES
		data["version"] = 5
		version = 5
	if version == 5:
		data["skills"] = SkillRules.fresh_state()
		data["version"] = 6
		version = 6
	if version == 6:
		data["vehicles"] = []
		data["active_vehicle_id"] = ""
		data["version"] = 7
	return data

static func validate(data: Dictionary) -> bool:
	if int(data.get("version", -1)) != SAVE_VERSION or str(data.get("map_schema", "")) != MAP_SCHEMA:
		return false
	for key in ["player", "world", "needs", "skills", "vehicles", "inventory", "equipment", "weapon_durability", "clothing_equipment", "clothing_durability", "ground_items", "buildings", "zombies"]:
		if not data.has(key):
			return false
	if typeof(data.player) != TYPE_DICTIONARY or typeof(data.world) != TYPE_DICTIONARY:
		return false
	if data.has("injuries") and typeof(data.injuries) != TYPE_DICTIONARY:
		return false
	if typeof(data.skills) != TYPE_DICTIONARY:
		return false
	if typeof(data.vehicles) != TYPE_ARRAY:
		return false
	for vehicle: Dictionary in data.vehicles:
		if not valid_pair(vehicle.get("logical_position",[])) or typeof(vehicle.get("trunk",{}))!=TYPE_DICTIONARY:
			return false
	if data.has("population") and typeof(data.population) != TYPE_DICTIONARY:
		return false
	if data.has("firearm_loaded") and typeof(data.firearm_loaded) != TYPE_DICTIONARY:
		return false
	if typeof(data.clothing_equipment) != TYPE_DICTIONARY or typeof(data.clothing_durability) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("safehouse", {})) != TYPE_DICTIONARY:
		return false
	var safehouse: Dictionary = data.get("safehouse", {})
	if not str(safehouse.get("building_id", "")).is_empty() and not valid_pair(safehouse.get("spawn_logical", [])):
		return false
	if not valid_pair(data.player.get("logical_position", [])):
		return false
	if not data.world.has("game_time_minutes") or not data.world.has("time_multiplier") or not data.world.has("power_cutoff_minutes") or not data.world.has("water_cutoff_minutes"):
		return false
	if typeof(data.buildings) != TYPE_ARRAY or typeof(data.zombies) != TYPE_ARRAY or typeof(data.ground_items) != TYPE_ARRAY:
		return false
	for item_id in data.inventory.keys():
		if not Catalog.has(str(item_id)) or int(data.inventory[item_id]) < 0:
			return false
	for item: Dictionary in data.ground_items:
		if not Catalog.has(str(item.get("key", ""))) or not valid_pair(item.get("logical_position", [])):
			return false
		if item.has("loaded_ammo") and int(item.loaded_ammo) < 0:
			return false
	for zombie: Dictionary in data.zombies:
		if not valid_pair(zombie.get("logical_position", [])):
			return false
		var corpse_items: Variant = zombie.get("corpse_inventory", {})
		if typeof(corpse_items) != TYPE_DICTIONARY:
			return false
		for item_id in corpse_items.keys():
			if not Catalog.has(str(item_id)) or int(corpse_items[item_id]) < 0:
				return false
	return true

static func door_state(door: Node2D) -> Dictionary:
	return {"opened": bool(door.opened), "amount": float(door.amount), "health":float(door.health), "broken":bool(door.broken)}

static func apply_door_state(door: Node2D, data: Dictionary) -> void:
	door.opened = bool(data.get("opened", false))
	door.amount = clampf(float(data.get("amount", 1.0 if door.opened else 0.0)), 0.0, 1.0)
	door.health = clampf(float(data.get("health",door.max_health)),0.0,door.max_health)
	door.broken = bool(data.get("broken",false)) or door.health<=0.0
	door.step(0.0)

static func has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if str(property.name) == property_name:
			return true
	return false

static func valid_pair(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]

static func sanitize_item_counts(value: Dictionary) -> Dictionary:
	var result := {}
	for item_id in value.keys():
		if Catalog.has(str(item_id)):
			result[str(item_id)] = maxi(0, int(value[item_id]))
	return result

static func valid_owned_weapon(game: Node2D, item_id: String) -> String:
	return item_id if Catalog.is_weapon(item_id) and int(game.inventory.get(item_id, 0)) > 0 else ""

static func restore_weapon_durability(game: Node2D, saved: Dictionary) -> Dictionary:
	var restored := {}
	for item_id in Catalog.ITEMS.keys():
		if not Catalog.is_weapon(str(item_id)):
			continue
		var states: Array = saved.get(item_id, [])
		var valid_states: Array[float] = []
		for value in states:
			valid_states.append(clampf(float(value), 0.0, WeaponRules.max_durability(str(item_id))))
		while valid_states.size() < int(game.inventory.get(item_id, 0)):
			valid_states.append(WeaponRules.max_durability(str(item_id)))
		while valid_states.size() > int(game.inventory.get(item_id, 0)):
			valid_states.pop_back()
		restored[item_id] = valid_states
	return restored

static func restore_firearm_loaded(game: Node2D, saved: Dictionary) -> Dictionary:
	var restored := {}
	for item_id: String in Catalog.ITEMS.keys():
		if not Catalog.is_firearm(item_id):
			continue
		var amount := int(saved.get(item_id, 0)) if int(game.inventory.get(item_id, 0)) > 0 else 0
		restored[item_id] = clampi(amount, 0, int(Catalog.item(item_id).mag_capacity))
	return restored

static func restore_clothing_durability(game: Node2D, saved: Dictionary) -> Dictionary:
	var restored := {}
	for item_id: String in Catalog.CLOTHING_IDS:
		var states: Array = saved.get(item_id, [])
		var valid_states: Array[float] = []
		for value in states:
			valid_states.append(clampf(float(value), 0.0, ClothingRules.max_durability(item_id)))
		while valid_states.size() < int(game.inventory.get(item_id, 0)):
			valid_states.append(ClothingRules.max_durability(item_id))
		while valid_states.size() > int(game.inventory.get(item_id, 0)):
			valid_states.pop_back()
		restored[item_id] = valid_states
	return restored

static func restore_clothing_equipment(game: Node2D, saved: Dictionary) -> Dictionary:
	var restored := {"head":"", "torso":"", "legs":"", "feet":""}
	for slot: String in ClothingRules.SLOTS:
		var item_id := str(saved.get(slot, ""))
		if Catalog.is_clothing(item_id) and ClothingRules.slot(item_id) == slot and int(game.inventory.get(item_id, 0)) > 0:
			restored[slot] = item_id
	return restored
