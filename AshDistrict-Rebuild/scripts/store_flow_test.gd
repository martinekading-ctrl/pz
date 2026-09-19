extends RefCounted

static func run(game: Node2D, pictures: bool=false) -> void:
	var world=game.world_map
	var house=world.blue_house
	var store=world.store_building
	var actor=game.player
	actor.set_physics_process(false)
	# Initial test setup only. All movement after this is through the real movement function.
	actor.position=world.map_to_world(Vector2(27.2,49))
	house.door_component.opened=true
	game._process(1.0)
	for target in [Vector2(30.5,49),Vector2(36,49),Vector2(48,49),Vector2(48,36),Vector2(64,36),Vector2(64,28.2)]:
		await walk(game,target,pictures)
	assert(not store.door_open)
	if pictures: await shot(game,"01-exterior")
	var before: Vector2=actor.position
	for i in 40: actor.move_world(Vector2(1,-0.5).normalized()*3)
	assert(world.world_to_map(actor.position).y>27.0,"Closed glass door must block entry")
	# Walk back along the same short collision probe, no teleport/reset.
	await walk(game,world.world_to_map(before),pictures)
	game.interact()
	assert(store.door_open)
	game._process(0.4)
	await walk(game,Vector2(64,25),pictures)
	game._process(0.5)
	assert(store.inside and not store.roof.visible)
	if pictures: await shot(game,"02-interior")
	# Use the centre aisle instead of walking a straight line through the canned
	# goods shelf, then turn toward the north-wall coolers.
	await walk(game,Vector2(62.5,25),pictures)
	await walk(game,Vector2(62.5,18.3),pictures)
	await walk(game,Vector2(60,18.3),pictures)
	assert(store.nearest_furniture(actor.position)==0)
	game.interact()
	assert(game.searching==0 and game.search_building==store)
	# Refrigerated display cases use the 1.5 second cold-storage search profile.
	game._process(1.6)
	assert(game.active_building==store and game.loot_overlay!=null)
	if pictures: await shot(game,"03-search")
	game.leave_loot(0,"food")
	game.take_loot(0,"water")
	assert(game.inventory.water==5 and store.available_loot(0).water==0)
	assert(store.available_loot(0).food==1)
	assert(house.available_loot(0).bandage==1,"Container IDs cannot cross between buildings")
	game.close_loot()
	actor.set_physics_process(false)
	game.open_loot(0,store)
	assert(store.available_loot(0).water==0 and store.available_loot(0).food==1)
	game.close_loot()
	actor.set_physics_process(false)
	var seen:=reachable(game)
	for index in store.furniture.size():
		var found:=false
		for cell in seen:
			if store.nearest_furniture(world.map_to_world(Vector2(cell)*0.25))==index:
				found=true
				break
		assert(found,"Unreachable store container "+str(index))
	for target in [Vector2(62.5,18.3),Vector2(62.5,25),Vector2(64,25),Vector2(64,28.2)]:
		await walk(game,target,pictures)
	game.interact()
	assert(not store.door_open)
	game._process(0.4)
	for target in [Vector2(64,36),Vector2(48,36),Vector2(48,49),Vector2(36,49),Vector2(30.5,49),Vector2(27.2,49)]: await walk(game,target,pictures)
	game._process(0.5)
	assert(house.inside and not store.inside and store.roof.visible)
	assert(game.inventory.water==5)
	if pictures: await shot(game,"04-home")
	print("STORE ROUND TRIP PASS: continuous walk from house, closed glass door, opening/cutaway, five reachable containers, search/take/leave, isolated loot state, walk home with supplies")
	game.get_tree().quit()

static func walk(game: Node2D,target: Vector2,animated: bool) -> void:
	var destination: Vector2=game.world_map.map_to_world(target)
	for step in 5000:
		var delta: Vector2=destination-game.player.position
		if delta.length()<1.0: break
		var previous: Vector2=game.player.position
		game.player.move_world(delta.limit_length(4.0))
		game._process(1.0/60.0)
		if previous.distance_to(game.player.position)<0.01:
			push_error("Blocked on route to "+str(target)+" at "+str(game.world_map.world_to_map(previous)))
			game.get_tree().quit(1)
			await game.get_tree().process_frame
			return
		if animated and step%5==0: await game.get_tree().process_frame
	assert(game.player.position.distance_to(destination)<1.0)

static func shot(game: Node2D,label: String) -> void:
	await game.get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://build/store-"+label+"-v06.png")

static func reachable(game: Node2D) -> Array[Vector2i]:
	var queue: Array[Vector2i]=[Vector2i(256,100)]
	var visited: Dictionary={queue[0]:true}
	var cursor:=0
	while cursor<queue.size():
		var current:=queue[cursor]
		cursor+=1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=current+direction
			var p:=Vector2(next)*0.25
			if not Rect2(57.4,15.4,15.2,11.2).has_point(p) or visited.has(next): continue
			if game.player.can_stand(game.world_map.map_to_world(p)):
				visited[next]=true
				queue.append(next)
	return queue
