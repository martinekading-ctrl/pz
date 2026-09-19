extends RefCounted

static func state_test(game: Node2D) -> void:
	game.start_game()
	for e in game.enemies: e.frozen = true
	for c in game.containers:
		var target: Vector2 = game.closest_walkable(c.node.position)
		assert(not game.find_route(game.safe_point,target).is_empty(),"Disconnected container: "+c.title)
		assert(game.clear_line(target,c.node.position),"Blocked interaction: "+c.title)
	for road in game.District.ROADS:
		for p in road.points:
			assert(game.can_walk(p),"Road blocked at "+str(p))
			assert(not game.find_route(game.safe_point,p).is_empty(),"Road disconnected: "+str(p))
	game.player.position = game.closest_walkable(game.containers[9].node.position)
	game.loot(9)
	game.take_item("food")
	game.leave_item("water")
	game.close_loot()
	game.visited.store = true
	game.visited.alley = true
	assert(game.save_game("user://iso-seamless-test.json"))
	game.containers[9].remaining.water = 0
	assert(game.load_game("user://iso-seamless-test.json"))
	assert(game.current_zone == "store" and game.containers[9].remaining.water == 1)
	var legacy: Dictionary = game.capture_state()
	legacy.version = 4
	legacy.pos = [4724,413]
	for i in legacy.enemies.size():
		var e = game.enemies[i]
		var zone: String = game.District.zone_of(e.position)
		var old: Vector2 = e.position-game.District.ORIGINS[zone]+Vector2(game.District.ZONES.find(zone)*1792,0)
		legacy.enemies[i].pos = [old.x,old.y]
	var file := FileAccess.open("user://iso-seamless-v4.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	assert(game.load_game("user://iso-seamless-v4.json"))
	assert(game.player.position.distance_to(game.District.ORIGINS.store+Vector2(1140,413))<20,"Old regional position must migrate")
	assert(game.containers[9].remaining.water == 1)
	print("SEAMLESS STATE PASS: all 14 containers and four connecting roads reachable in ONE navigation grid; leftovers and v4 coordinate migration preserved")
	game.get_tree().quit()

static func walk_test(game: Node2D) -> void:
	game.start_game()
	for e in game.enemies:
		e.frozen = true
		e.collision_layer = 0
	var max_step := 0.0
	var max_camera_step := 0.0
	# Include both sides and the middle of every road; never inject E or assign player position.
	var targets: Array = []
	for road in game.District.ROADS:
		for point in road.points: targets.append(point)
	targets.append(game.safe_point)
	for target in targets:
		var route: PackedVector2Array = game.find_route(game.player.position,game.closest_walkable(target))
		assert(not route.is_empty(),"No continuous route")
		var count := 0
		for point in route:
			while game.player.position.distance_to(point)>10 and count<10000:
				var delta: Vector2 = point-game.player.position
				for pair in [[KEY_D,delta.x>3],[KEY_A,delta.x< -3],[KEY_S,delta.y>3],[KEY_W,delta.y< -3]]:
					var event := InputEventKey.new()
					event.physical_keycode = pair[0]
					event.pressed = pair[1]
					Input.parse_input_event(event)
				var before: Vector2 = game.player.position
				var camera_before: Vector2 = game.camera.position
				await game.get_tree().physics_frame
				max_step = maxf(max_step,before.distance_to(game.player.position))
				if game.elapsed>3: max_camera_step = maxf(max_camera_step,camera_before.distance_to(game.camera.position))
				count += 1
		assert(game.player.position.distance_to(target)<30,"Walk stalled at "+str(game.player.position))
		print("CONTINUOUS WAYPOINT: ",target," ticks=",count)
	for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		Input.parse_input_event(event)
	assert(max_step < 4,"Unexpected player teleport")
	assert(max_camera_step < 8,"Unexpected camera snap")
	assert(game.visited.values().all(func(v): return v))
	print("SEAMLESS WASD PASS: entire road loop without E, maximum movement step=",max_step," camera step=",max_camera_step)
	game.get_tree().quit()
