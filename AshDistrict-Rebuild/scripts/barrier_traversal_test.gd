extends RefCounted

static func run(game: Node2D) -> void:
	var building: Node2D=game.world_map.blue_house
	var index:=2
	building.set_barricade_layers(index,0)
	building.windows[index].state="closed"
	building.windows[index].glass_hp=building.WINDOW_GLASS_HP
	var midpoint: Vector2=(building.windows[index].a+building.windows[index].b)*0.5
	game.player.position=game.world_map.map_to_world(midpoint+Vector2(0,0.65))
	building.update_player(game.player.position,0.0)
	var opened: Dictionary=game.toggle_target_window(building,index)
	assert(bool(opened.ok) and building.window_state(index)=="open")
	var crossing: Dictionary=building.window_crossing(index,game.player.position)
	assert(not crossing.is_empty() and crossing.destination!=game.player.position)
	building.toggle_window(index)
	assert(building.window_crossing(index,game.player.position).is_empty())
	var glass: Dictionary=building.damage_window(index,building.WINDOW_GLASS_HP)
	assert(str(glass.event)=="glass_broken" and building.window_state(index)=="broken")
	assert(not building.window_crossing(index,game.player.position).is_empty())
	building.add_barricade_layer(index)
	var board: Dictionary=building.damage_window(index,building.BARRICADE_LAYER_HP)
	assert(str(board.event)=="board_broken" and building.barricade_layers(index)==0)
	# An alerted zombie must select this nearby window, destroy the board and glass,
	# then use the same controlled crossing instead of walking through the wall.
	building.windows[index].state="closed"
	building.windows[index].glass_hp=building.WINDOW_GLASS_HP
	building.set_barricade_layers(index,1)
	game.player.position=game.world_map.map_to_world(midpoint-Vector2(0,1.0))
	var zombie:=preload("res://scripts/zombie.gd").new()
	game.add_child(zombie)
	zombie.setup(game,game.world_map,game.player,midpoint+Vector2(0,1.0),999)
	zombie.alerted=true
	game.zombies.append(zombie)
	for step in 180:
		zombie._process(0.1)
	assert(building.barricade_layers(index)==0 and building.window_state(index)=="broken")
	assert(game.world_map.building_containing(zombie.position)==building,"Zombie should finish its window crossing")
	game.zombies.erase(zombie)
	zombie.queue_free()
	var door: Node2D=building.door_component
	var door_result: Dictionary=door.damage(door.max_health)
	assert(bool(door_result.just_broken) and door.broken and not door.blocks(door.hinge+door.closed_vector*0.5))
	var captured: Dictionary=preload("res://scripts/save_system.gd").capture_state(game)
	assert(bool(captured.buildings[0].doors.primary.broken))
	assert(str(captured.buildings[0].barricades[index].state)=="broken")
	print("BARRIER PASS: open/close, controlled crossing, zombie breach AI, glass, boards, doors, rich save state")
	game.get_tree().quit()
