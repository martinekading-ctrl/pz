extends RefCounted

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	var building: Node2D = game.world_map.residential_b01
	var front_threshold := Vector2(65.3,140.9)
	var rear_threshold := Vector2(69.9,133.0)

	building.door_component.opened = false
	building.door_component.amount = 0.0
	building.rear_door.opened = false
	building.rear_door.amount = 0.0
	assert(not building.is_walkable_logical(front_threshold),"B01 closed front door does not block")
	assert(not building.is_walkable_logical(rear_threshold),"B01 closed rear door does not block")

	building.door_component.opened = true
	building.door_component.amount = 1.0
	building.rear_door.opened = true
	building.rear_door.amount = 1.0
	assert(building.is_walkable_logical(front_threshold),"B01 open front door is not passable")
	assert(building.is_walkable_logical(rear_threshold),"B01 open rear door is not passable")

	game.player.position = game.world_map.map_to_world(Vector2(58.7,137.4))
	game.player.update_depth()
	building.update_player(game.player.position,1.0)
	var table_index: int = building.nearest_furniture(game.player.position)
	assert(table_index >= 0 and building.item_title(table_index)=="餐桌","B01 table search face is misplaced")
	game.open_loot(table_index,building)
	assert(game.active_building==building and game.active_loot==table_index,"B01 loot panel did not bind to the house")
	game.close_loot()
	print("B01 PASS: front/rear doors, interior collision and take/leave search panel")
	game.get_tree().quit()
