extends RefCounted

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	for trunk in game.world_map.vegetation.trunks:
		assert(game.world_map.vegetation.allowed(trunk,4.0),"Tree in reserved space")
		assert(not game.player.can_stand(game.world_map.map_to_world(trunk)),"Tree trunk has no collision")
	var test_crown: Sprite2D = game.world_map.vegetation.crowns[0]
	game.player.position=test_crown.position-Vector2(0,30)
	game.world_map.vegetation._process(1.0)
	assert(test_crown.modulate.a<0.4,"Canopy fails to reveal player")
	print("NATURE PASS: tree exclusions, trunk collision and canopy fade")
	for plant in game.world_map.vegetation.low_plants:
		var meters: float=plant.get_meta("height_m")
		assert(meters>=0.1 and meters<=1.2)
		assert(game.world_map.vegetation.allowed(game.world_map.world_to_map(plant.position),0.9))
	print("LOW PLANTS PASS: meter-scale range and entry exclusions")
	var capture := "--standard-capture" in OS.get_cmdline_user_args()
	for building in game.world_map.interactive_buildings:
		for item in building.furniture:
			var expected_anchor: Vector2 = game.world_map.map_to_world(item.bounds.end)
			assert(item.sprite.position.distance_to(expected_anchor)<0.01,"Furniture sprite anchor diverges from collision footprint: "+item.title)
		building.door_component.opened = true
		building.update_player(building.door_midpoint(),1.0)
		var area: Rect2 = building.get_search_area()
		var queue: Array[Vector2] = []
		var visited := {}
		var found := {}
		var start: Vector2 = game.world_map.world_to_map(building.door_midpoint())
		start = start.clamp(area.position+Vector2.ONE*0.4,area.end-Vector2.ONE*0.4)
		queue.append(start)
		visited[str(start)] = true
		var cursor := 0
		while cursor < queue.size():
			var point := queue[cursor]
			cursor += 1
			var world: Vector2 = game.world_map.map_to_world(point)
			var index: int = building.nearest_furniture(world)
			if index >= 0: found[index] = point
			for offset in [Vector2(0.25,0),Vector2(-0.25,0),Vector2(0,0.25),Vector2(0,-0.25)]:
				var next: Vector2 = point+offset
				var key := str(next)
				if visited.has(key) or not area.has_point(next): continue
				if not game.player.can_stand(game.world_map.map_to_world(next)): continue
				visited[key] = true
				queue.append(next)
		for i in building.furniture.size():
			if not found.has(i):
				push_error("Unreachable furniture: "+building.furniture[i].title)
				game.get_tree().quit(1)
				return
			game.player.position = game.world_map.map_to_world(found[i])
			building.update_player(game.player.position,1.0)
			game.open_loot(i,building)
			if game.active_loot != i:
				push_error("Search UI failed")
				game.get_tree().quit(1)
				return
			game.close_loot()
			game.player.set_physics_process(false)
		print("STANDARD PASS: ",building.furniture.size()," front interaction zones reachable from entrance")
		if capture:
			game.player.position = game.world_map.map_to_world(area.get_center())
			game.camera.position_smoothing_enabled = false
			game.camera.zoom = Vector2(0.85,0.85)
			game.camera.position = Vector2(0,-90)
			building.update_player(game.player.position,1.0)
			await game.get_tree().create_timer(0.5).timeout
			game.get_viewport().get_texture().get_image().save_png("res://build/layout-"+str(building.furniture.size())+"-v08.png")
	if capture:
		var house: Node2D = game.world_map.blue_house
		game.player.position = game.world_map.map_to_world(Vector2(29.8,51.8))
		game.player.update_depth()
		house.update_player(game.player.position,1.0)
		for item in house.furniture:
			assert(not item.sprite.visible,"Interior prop leaked into exterior")
		assert(not game.player.can_stand(game.world_map.map_to_world(Vector2(29.1,51.8))),"Player radius intersects wall")
		game.camera.zoom = Vector2(0.7,0.7)
		await game.get_tree().create_timer(0.5).timeout
		game.get_viewport().get_texture().get_image().save_png("res://build/grass-exterior-v092.png")
		print("OCCLUSION PASS: exterior furniture hidden and wall contact rejected")
	game.get_tree().quit()
