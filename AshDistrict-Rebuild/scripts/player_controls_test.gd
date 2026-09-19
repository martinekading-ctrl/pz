extends RefCounted

static func run(game: Node2D) -> void:
	var actor: Node2D=game.player
	actor.set_physics_process(false)
	var start:=Vector2(110,50)
	for hz in [30,60,120]:
		for index in 8:
			actor.position=game.world_map.map_to_world(start)
			actor.running=false
			actor.crouching=false
			var direction:=Vector2.from_angle(index*PI/4)
			actor.set_facing(direction)
			assert(actor.facing_index==index)
			for tick in hz: actor.step_motion(direction,1.0/hz)
			var distance: float=game.world_map.world_to_map(actor.position).distance_to(start)*.5
			assert(absf(distance-1.6)<.02,"Direction/FPS changed walking speed")
	for mode in ["run","crouch"]:
		actor.position=game.world_map.map_to_world(start)
		actor.running=mode=="run"
		actor.crouching=mode=="crouch"
		for tick in 60: actor.step_motion(Vector2.RIGHT,1.0/60)
		var meters: float=game.world_map.world_to_map(actor.position).distance_to(start)*.5
		assert(absf(meters-(3.8 if mode=="run" else .75))<.02)
	actor.position=game.world_map.map_to_world(Vector2(15,48))
	actor.move_world(game.world_map.map_to_world(Vector2(4,0)))
	assert(game.world_map.world_to_map(actor.position).x<16,"Crossed solid house wall")
	assert(actor.can_stand(actor.position),"Collision left player penetrating wall")
	print("PLAYER PASS: eight directions, 30/60/120 Hz, walk/run/crouch meters, wall sweep")
	game.get_tree().quit()
