extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const InjuryRules = preload("res://scripts/injury_rules.gd")
const SaveSystem = preload("res://scripts/save_system.gd")
const LootProfiles = preload("res://scripts/loot_profiles.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = true
	game.player.set_physics_process(false)
	for item_id: String in Catalog.LOOT_EXPANSION_IDS:
		assert(Catalog.has(item_id), "Expanded loot item must exist: " + item_id)

	var expanded_container_count := 0
	for building: Node2D in game.world_map.interactive_buildings:
		for container: Dictionary in building.furniture:
			for item_id: String in Catalog.LOOT_EXPANSION_IDS:
				if int(container.remaining.get(item_id, 0)) > 0:
					expanded_container_count += 1
	assert(expanded_container_count >= 6, "Loot profiles must seed several real containers")

	for item_id: String in Catalog.ITEMS.keys():
		game.inventory[item_id] = 0
	game.needs = {"health":100.0,"food":30.0,"water":35.0,"stamina":25.0,"fatigue":60.0,"bleeding":0.0,"pain":0.0,"infection":0.0,"pain_relief":0.0}
	game.inventory.canned_soup = 1
	var soup: Dictionary = game.use_inventory_item("canned_soup")
	assert(soup.consumed and int(game.needs.food) == 50 and int(game.needs.water) == 45 and int(game.inventory.canned_soup) == 0, "Soup must restore food and water")

	game.inventory.fresh_food = 1
	game.fresh_food_expiry_minutes = game.game_time_minutes - 1.0
	var health_before := float(game.needs.health)
	var spoiled: Dictionary = game.use_inventory_item("fresh_food")
	assert(spoiled.consumed and float(game.needs.health) == health_before - 6.0 and int(game.inventory.fresh_food) == 0, "Spoiled food must carry a health cost")

	game.injuries = InjuryRules.fresh_state()
	game.injuries.torso = InjuryRules.make_wound("laceration", true, true, 30.0)
	game.inventory.disinfectant = 1
	var disinfected: Dictionary = game.use_inventory_item("disinfectant", "torso")
	assert(disinfected.consumed and is_equal_approx(float(game.injuries.torso.infection), 12.0) and int(game.inventory.disinfectant) == 0, "Disinfectant must treat the selected wound")
	game.inventory.antibiotics = 1
	var antibiotic: Dictionary = game.use_inventory_item("antibiotics")
	assert(antibiotic.consumed and not bool(game.injuries.torso.infected) and int(game.inventory.antibiotics) == 0, "Antibiotics must clear a low non-bite infection")

	game.inventory.crowbar = 1
	game.inventory.duct_tape = 1
	game.weapon_durability.crowbar = [40.0]
	game.equipment.primary = "crowbar"
	game.active_weapon_slot = "primary"
	var repair: Dictionary = game.use_inventory_item("duct_tape")
	assert(repair.consumed and is_equal_approx(float(game.weapon_durability.crowbar[0]), 60.0) and int(game.inventory.duct_tape) == 0, "Duct tape must restore 20 percent weapon durability")

	game.fresh_food_expiry_minutes = game.game_time_minutes + 777.0
	var state := SaveSystem.capture_state(game)
	assert(int(state.loot_revision) == LootProfiles.REVISION and is_equal_approx(float(state.world.fresh_food_expiry_minutes), game.fresh_food_expiry_minutes), "Loot revision and perishability deadline must save")
	var legacy := state.duplicate(true)
	legacy.version = 2
	legacy.erase("loot_revision")
	legacy.world.erase("fresh_food_expiry_minutes")
	var migrated := SaveSystem.migrate(legacy)
	assert(int(migrated.version) == SaveSystem.SAVE_VERSION and int(migrated.loot_revision) == 0 and migrated.world.has("fresh_food_expiry_minutes"), "Version 2 saves must migrate to the loot schema")
	print("LOOT PASS: 8 functional items, contextual containers, perishability, medicine, weapon repair and save migration")
	game.get_tree().quit()
