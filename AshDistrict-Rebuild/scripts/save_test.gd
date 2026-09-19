extends RefCounted

const SaveSystem = preload("res://scripts/save_system.gd")
const InjuryRules = preload("res://scripts/injury_rules.gd")

static func run(game: Node2D) -> void:
	var path := "user://ash_district_save_test.json"
	cleanup(path)
	game.player.set_physics_process(false)
	if game.zombies.is_empty():
		game.spawn_zombies()
	game.player.position = game.world_map.map_to_world(Vector2(27.25, 48.75))
	game.game_time_minutes = 4123.5
	game.time_multiplier = 2.0
	game.needs = {"health": 64.0, "food": 51.0, "water": 43.0, "stamina":37.0, "fatigue":62.0, "bleeding":0.0, "pain":0.0, "infection":0.0, "pain_relief":75.0}
	game.injuries = InjuryRules.fresh_state()
	game.injuries.torso = InjuryRules.make_wound("laceration", true, true, 27.0)
	InjuryRules.sync_needs(game.injuries, game.needs)
	game.inventory = {"food": 3, "water": 2, "bandage": 1, "painkillers":2, "parts": 4, "pistol_ammo":19, "pistol_magazine":1, "crowbar": 1, "baseball_bat": 1, "kitchen_knife": 0, "hand_axe": 0, "pistol":1}
	game.weapon_durability = {"crowbar": [72.0], "baseball_bat": [41.0], "kitchen_knife": [], "hand_axe": [], "pistol":[88.0]}
	game.firearm_loaded = {"pistol":7}
	game.shot_sequence = 4
	game.equipment = {"primary": "crowbar", "secondary": "baseball_bat"}
	game.active_weapon_slot = "secondary"
	var house: Node2D = game.world_map.blue_house
	house.door_component.opened = true
	house.door_component.amount = 1.0
	house.furniture[1].remaining = {"food": 1, "water": 0}
	house.furniture[1]["searched"] = true
	game.ground_items.clear()
	game.ground_items.append({"key": "kitchen_knife", "position": game.world_map.map_to_world(Vector2(28, 49)), "durability": 17.0})
	game.zombies[0].position = game.world_map.map_to_world(Vector2(31, 50))
	game.zombies[0].health = 19
	game.zombies[0].alerted = false
	game.zombies[0].investigate_target = game.world_map.map_to_world(Vector2(33, 51))
	game.zombies[0].investigate_time = 5.0
	game.zombies[0].change_state(game.zombies[0].State.INVESTIGATE)
	game.zombies[1].health = 0
	game.zombies[1].corpse_inventory = {"painkillers":2}
	game.zombies[1].corpse_searched = true
	game.zombies[1].change_state(game.zombies[1].State.DEAD)
	game.population_respawn_budget = 2
	game.population_timer = 31.0
	game.safehouse_building_id = str(house.name)
	game.safehouse_spawn_logical = Vector2(21.5,47.5)

	var first_state := SaveSystem.capture_state(game)
	var legacy_state: Dictionary = first_state.duplicate(true)
	legacy_state.version = 1
	legacy_state.erase("safehouse")
	var migrated: Dictionary = SaveSystem.migrate(legacy_state)
	assert(int(migrated.version) == SaveSystem.SAVE_VERSION and str(migrated.safehouse.building_id).is_empty(), "Version 1 saves must migrate to the safehouse schema")
	assert(SaveSystem.write_atomic(path, first_state).ok, "Initial save must succeed")
	game.player.position = Vector2.ZERO
	game.needs.health = 1.0
	game.injuries = InjuryRules.fresh_state()
	game.inventory.food = 0
	game.weapon_durability.crowbar[0] = 1.0
	game.firearm_loaded.pistol = 0
	game.shot_sequence = 0
	house.door_component.opened = false
	house.door_component.amount = 0.0
	house.furniture[1].remaining.clear()
	game.ground_items.clear()
	game.zombies[0].health = 68
	game.zombies[0].alerted = false
	game.safehouse_building_id = ""
	game.safehouse_spawn_logical = Vector2.ZERO

	var loaded := SaveSystem.load_file(path)
	assert(loaded.ok and not loaded.recovered and SaveSystem.apply_state(game, loaded.data), "Primary save must load")
	assert(game.world_map.world_to_map(game.player.position).distance_to(Vector2(27.25, 48.75)) < 0.01)
	assert(is_equal_approx(float(game.needs.health), 64.0) and is_equal_approx(float(game.needs.stamina),37.0) and is_equal_approx(float(game.needs.fatigue),62.0) and int(game.inventory.food) == 3)
	assert(game.injuries.torso.wound == "laceration" and game.injuries.torso.bandaged and game.injuries.torso.infected and is_equal_approx(float(game.injuries.torso.infection),27.0), "Body-part injuries must survive a save round trip")
	assert(int(game.inventory.painkillers) == 2 and is_equal_approx(float(game.needs.pain_relief),75.0), "Medical items and timed relief must restore")
	assert(is_equal_approx(float(game.weapon_durability.crowbar[0]), 72.0) and game.active_weapon_slot == "secondary")
	assert(int(game.firearm_loaded.pistol) == 7 and game.shot_sequence == 4 and int(game.inventory.pistol_ammo) == 19, "Loaded magazine, loose ammunition and shot sequence must restore")
	assert(house.door_component.opened and int(house.furniture[1].remaining.food) == 1 and bool(house.furniture[1].searched))
	assert(game.ground_items.size() == 1 and is_equal_approx(float(game.ground_items[0].durability), 17.0))
	assert(game.zombies[0].health == 19 and game.zombies[0].state == game.zombies[0].State.INVESTIGATE and is_equal_approx(game.zombies[0].investigate_time,5.0))
	assert(game.zombies.size() == first_state.zombies.size() and game.zombies[1].is_dead() and int(game.zombies[1].corpse_inventory.painkillers) == 2 and game.zombies[1].corpse_searched, "Corpses and their remaining loot must restore")
	assert(game.population_respawn_budget == 2 and is_equal_approx(game.population_timer,31.0), "Population migration limits must restore")
	assert(game.safehouse_building_id == str(house.name) and game.safehouse_spawn_logical.distance_to(Vector2(21.5,47.5)) < 0.01, "Safehouse identity and bed position must restore")

	game.needs.health = 77.0
	assert(SaveSystem.write_atomic(path, SaveSystem.capture_state(game)).ok, "Second save must create a backup")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovered := SaveSystem.load_file(path)
	assert(recovered.ok and recovered.recovered and SaveSystem.apply_state(game, recovered.data), "Corrupt primary must recover from backup")
	assert(is_equal_approx(float(game.needs.health), 64.0), "Backup must contain the previous good snapshot")
	cleanup(path)
	print("SAVE PASS: schema migration, safehouse, firearm magazine state, injuries, population/corpses, player/world/inventory/weapons/containers/doors/ground/zombies, atomic backup recovery")
	game.get_tree().quit()

static func cleanup(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var candidate: String = path + str(suffix)
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
