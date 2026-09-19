extends RefCounted

const Rules = preload("res://scripts/crafting_rules.gd")
const Catalog = preload("res://scripts/item_catalog.gd")

static func run(game: Node2D) -> void:
	var missing := {"bed_sheet":0,"ripped_cloth":0,"bandage":0}
	var before := missing.duplicate(true)
	var rejected: Dictionary = Rules.craft(missing,"rip_cloth")
	assert(not bool(rejected.ok))
	assert(missing == before,"Failed craft must not consume partial inputs")

	var sample := {"bed_sheet":1,"ripped_cloth":0,"bandage":0}
	var ripped: Dictionary = Rules.craft(sample,"rip_cloth")
	assert(bool(ripped.ok) and sample.bed_sheet == 0 and sample.ripped_cloth == 4)
	var bandage: Dictionary = Rules.craft(sample,"improvised_bandage")
	assert(bool(bandage.ok) and sample.ripped_cloth == 2 and sample.bandage == 1)

	for item_id: String in Catalog.ITEMS:
		game.inventory[item_id] = 0
	game.inventory.hammer = 1
	game.inventory.plank = 2
	game.inventory.nails = 4
	var building: Node2D = game.world_map.blue_house
	assert(building.windows.size() == 4)
	var index := 2
	var midpoint: Vector2 = (building.windows[index].a + building.windows[index].b)*0.5
	game.player.position = game.world_map.map_to_world(midpoint+Vector2(0,0.65))
	game.player.update_depth()
	building.update_player(game.player.position,1.0)
	assert(building.nearest_window(game.player.position) == index)

	var first: Dictionary = game.build_window_barricade(building,index)
	assert(bool(first.ok))
	assert(building.barricade_layers(index) == 1)
	assert(game.inventory.hammer == 1 and game.inventory.plank == 1 and game.inventory.nails == 2)
	var second: Dictionary = game.build_window_barricade(building,index)
	assert(bool(second.ok) and building.barricade_layers(index) == Rules.MAX_BARRICADE_LAYERS)
	var full_counts: Dictionary = game.inventory.duplicate(true)
	assert(not bool(game.build_window_barricade(building,index).ok))
	assert(game.inventory == full_counts,"Max-layer rejection must be atomic")

	game.inventory.hammer = 0
	game.inventory.crowbar = 0
	assert(not bool(game.remove_window_barricade(building,index).ok))
	assert(building.barricade_layers(index) == 2)
	game.inventory.hammer = 1
	var removed: Dictionary = game.remove_window_barricade(building,index)
	assert(bool(removed.ok))
	assert(building.barricade_layers(index) == 1)
	assert(game.inventory.plank == 1 and game.inventory.nails == 1)

	var captured: Dictionary = preload("res://scripts/save_system.gd").capture_state(game)
	assert(preload("res://scripts/save_system.gd").validate(captured))
	var saved_building: Dictionary = captured.buildings[0]
	assert(saved_building.has("barricades") and saved_building.barricades[index].layer_hp.size() == 1)
	building.set_barricade_layers(index,0)
	building.apply_barricade_state(saved_building.barricades)
	assert(building.barricade_layers(index) == 1)

	game.open_crafting(building,index)
	assert(is_instance_valid(game.crafting_overlay))
	assert(not game.player.is_physics_processing())
	assert(not game.simulation_paused,"Crafting UI must keep world simulation live")
	assert(game.mobile_controls.buttons.has("crafting"))
	game.close_crafting()
	assert(game.player.is_physics_processing())
	print("CRAFTING PASS: atomic recipes, tools, 2-layer barricades, recovery, live UI, save state")
	game.get_tree().quit()
