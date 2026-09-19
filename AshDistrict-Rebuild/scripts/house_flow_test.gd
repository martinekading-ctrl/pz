extends RefCounted

# Walk through the same movement and interaction functions used by keyboard input.
static func run(game: Node2D, capture_frames: bool = false) -> void:
	var house = game.world_map.blue_house
	var actor = game.player
	actor.set_physics_process(false)
	actor.position = game.world_map.map_to_world(Vector2(36,49))
	house.update_player(actor.position,1.0)
	assert(not house.inside)
	if capture_frames: await shot(game,"01-exterior")
	await walk(game,Vector2(30.2,49),capture_frames)
	assert(not house.door_open)
	var before: Vector2 = actor.position
	for i in 30: actor.move_world(Vector2(-1,-0.5).normalized()*4.0)
	assert(game.world_map.world_to_map(actor.position).x > 29.0,"Closed door must block entry")
	actor.position = before
	game.interact()
	assert(house.door_open)
	for i in 30: house.update_player(actor.position,1.0/60.0)
	await walk(game,Vector2(27.2,49),capture_frames)
	for i in 40: house.update_player(actor.position,1.0/60.0)
	assert(house.inside and not house.roof.visible,"Entering must reveal the room")
	if capture_frames: await shot(game,"02-interior")
	await walk(game,Vector2(26,49),capture_frames)
	await walk(game,Vector2(26,47),capture_frames)
	# The fridge search face ends at y=46.4 after the furniture was rescaled to
	# its real-world footprint. Stand in the aisle inside that interaction zone.
	await walk(game,Vector2(28,46),capture_frames)
	house.update_player(actor.position,0.1)
	assert(house.nearest_furniture(actor.position) == 1,"Fridge must be searchable from the aisle")
	game.interact()
	assert(game.searching == 1)
	# The fridge uses the 1.5 second cold-storage search profile.
	game._process(1.6)
	assert(game.loot_overlay != null)
	assert(house.available_loot(1).food == 2)
	if capture_frames: await shot(game,"03-search")
	# Leaving a row does not destroy the container's contents.
	game.leave_loot(1,"water")
	assert(house.available_loot(1).water == 1)
	game.take_loot(1,"food")
	assert(game.inventory.food == 2 and house.available_loot(1).food == 0)
	game.close_loot()
	actor.set_physics_process(false)
	game.open_loot(1)
	assert(house.available_loot(1).water == 1)
	assert(house.take_item(1,"food") == 0,"Taken items must not respawn")
	game.close_loot()
	actor.set_physics_process(false)
	# Every furniture item has a reachable search position from the doorway.
	var seen := reachable(game,Vector2(27.2,49))
	for index in house.furniture.size():
		var reachable_item := false
		for point in seen:
			if house.nearest_furniture(game.world_map.map_to_world(Vector2(point)*0.25)) == index:
				reachable_item = true
				break
		assert(reachable_item,"Unreachable furniture: "+house.item_title(index))
	await walk(game,Vector2(26,47),capture_frames)
	await walk(game,Vector2(26,49),capture_frames)
	await walk(game,Vector2(27.3,49),capture_frames)
	await walk(game,Vector2(30.5,49),capture_frames)
	assert(house.try_toggle_door(actor.position))
	for i in 60: house.update_player(actor.position,1.0/60.0)
	assert(not house.inside and house.roof.visible and not house.door_open)
	if capture_frames: await shot(game,"04-exit")
	assert(house.nearest_furniture(actor.position) == -1,"No searching from outside")
	print("HOUSE FLOW PASS: walk through gate, closed-door collision, open and enter, roof cutaway, search UI, leave/take/reopen, all containers reachable, exit and close")
	game.get_tree().quit()

static func walk(game: Node2D, target: Vector2, animated: bool) -> void:
	var destination: Vector2 = game.world_map.map_to_world(target)
	for step in 2000:
		var delta: Vector2 = destination-game.player.position
		if delta.length() < 1.0: break
		var previous: Vector2 = game.player.position
		game.player.move_world(delta.limit_length(3.0))
		game.world_map.blue_house.update_player(game.player.position,1.0/60.0)
		assert(game.player.position.distance_to(previous)>0.01,"Path blocked while walking to "+str(target))
		if animated and step % 3 == 0: await game.get_tree().process_frame
	assert(game.player.position.distance_to(destination)<1.0)

static func reachable(game: Node2D, seed: Vector2) -> Array[Vector2i]:
	var start := Vector2i((seed*4.0).round())
	var queue: Array[Vector2i] = [start]
	var visited := {start:true}
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = current+direction
			var logical := Vector2(next)*0.25
			if logical.x<16.5 or logical.x>28.5 or logical.y<43.5 or logical.y>52.5: continue
			if visited.has(next): continue
			if game.player.can_stand(game.world_map.map_to_world(logical)):
				visited[next]=true
				queue.append(next)
	return queue

static func shot(game: Node2D, label: String) -> void:
	await game.get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://build/flow-"+label+"-v05.png")
