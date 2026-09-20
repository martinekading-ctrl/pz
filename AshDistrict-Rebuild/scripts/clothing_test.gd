extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const ClothingRules = preload("res://scripts/clothing_rules.gd")
const SaveSystem = preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = true
	game.player.set_physics_process(false)
	assert(Catalog.CLOTHING_IDS.size() == 8, "The first clothing set must contain 8 items")
	for item_id: String in Catalog.CLOTHING_IDS:
		assert(Catalog.is_clothing(item_id) and ClothingRules.slot(item_id) in ClothingRules.SLOTS, "Every clothing item needs a valid slot")

	var wardrobe_items := 0
	for building: Node2D in game.world_map.interactive_buildings:
		for container: Dictionary in building.furniture:
			if "衣柜" not in str(container.title):
				continue
			for item_id: String in Catalog.CLOTHING_IDS:
				wardrobe_items += int(container.remaining.get(item_id, 0))
	assert(wardrobe_items >= 3, "Wardrobes must contain contextual clothing loot")

	for item_id: String in Catalog.CLOTHING_IDS:
		game.inventory[item_id] = 0
		game.clothing_durability[item_id] = []
	game.clothing_equipment = {"head":"","torso":"","legs":"","feet":""}
	game.inventory.leather_jacket = 1
	game.inventory.cargo_pants = 1
	game.inventory.work_boots = 1
	game.add_clothing_instances("leather_jacket", 1)
	game.add_clothing_instances("cargo_pants", 1)
	game.add_clothing_instances("work_boots", 1)
	assert(game.equip_clothing("leather_jacket") and game.equip_clothing("cargo_pants") and game.equip_clothing("work_boots"), "Clothing must equip into its own body slots")
	assert(game.clothing_equipment.torso == "leather_jacket" and game.clothing_equipment.legs == "cargo_pants" and game.clothing_equipment.feet == "work_boots")
	var torso_bite := ClothingRules.combined_protection("torso", "bite", game.clothing_equipment, game.clothing_durability)
	var leg_scratch := ClothingRules.combined_protection("legs", "scratch", game.clothing_equipment, game.clothing_durability)
	assert(is_equal_approx(torso_bite, 0.17) and leg_scratch > 0.50, "Pants and boots must combine for leg protection")

	var before: float = game.clothing_condition_value("leather_jacket")
	game.injury_rng.seed = 27
	var expected_block: bool = game.injury_rng.randf() < torso_bite
	game.injury_rng.seed = 27
	var protected: Dictionary = game.apply_clothing_protection("torso", "bite")
	assert(bool(protected.blocked) == expected_block and game.clothing_condition_value("leather_jacket") < before, "A hit must roll protection and wear the covering item")

	game.inventory.baseball_cap = 1
	game.clothing_durability.baseball_cap = [1.0]
	assert(game.equip_clothing("baseball_cap"))
	game.injury_rng.seed = 1
	game.apply_clothing_protection("head", "bite")
	assert(int(game.inventory.baseball_cap) == 0 and str(game.clothing_equipment.head).is_empty(), "Zero-durability clothing must break and unequip")

	game.clothing_durability.leather_jacket = [51.0]
	var state := SaveSystem.capture_state(game)
	assert(state.clothing_equipment.torso == "leather_jacket" and is_equal_approx(float(state.clothing_durability.leather_jacket[0]), 51.0), "Clothing equipment and durability must save")
	game.clothing_equipment.torso = ""
	game.clothing_durability.leather_jacket = [1.0]
	assert(SaveSystem.apply_state(game, state), "Clothing save state must load")
	assert(game.clothing_equipment.torso == "leather_jacket" and is_equal_approx(float(game.clothing_durability.leather_jacket[0]), 51.0), "Clothing equipment and durability must restore")
	var legacy := state.duplicate(true)
	legacy.version = 3
	legacy.erase("clothing_equipment")
	legacy.erase("clothing_durability")
	var migrated := SaveSystem.migrate(legacy)
	assert(int(migrated.version) == SaveSystem.SAVE_VERSION and migrated.clothing_equipment.has("head"), "Version 3 saves must migrate to the clothing schema")
	print("CLOTHING PASS: 8 items, 4 slots, contextual loot, layered protection, wear, breakage and save migration")
	game.get_tree().quit()
