extends RefCounted

static func run(game: Node2D) -> void:
	var actor: Node2D=game.player
	actor.set_physics_process(false)
	var start:=Vector2(110,50)
	var walk_reference := -1.0
	for hz in [30,60,120]:
		for index in 8:
			actor.position=game.world_map.map_to_world(start)
			actor.velocity_mps=Vector2.ZERO
			actor.running=false
			actor.crouching=false
			var direction:=Vector2.from_angle(index*PI/4)
			actor.set_facing(direction)
			assert(actor.facing_index==index)
			for tick in hz: actor.step_motion(direction,1.0/hz)
			var distance: float=game.world_map.world_to_map(actor.position).distance_to(start)*.5
			assert(distance>1.1 and distance<1.3,"Walking acceleration left expected range")
			if walk_reference<0.0: walk_reference=distance
			assert(absf(distance-walk_reference)<.03,"Direction/FPS changed walking speed")
	for mode in ["run","crouch"]:
		actor.position=game.world_map.map_to_world(start)
		actor.velocity_mps=Vector2.ZERO
		actor.running=mode=="run"
		actor.crouching=mode=="crouch"
		for tick in 60: actor.step_motion(Vector2.RIGHT,1.0/60)
		var meters: float=game.world_map.world_to_map(actor.position).distance_to(start)*.5
		assert(meters>1.9 and meters<2.05 if mode=="run" else meters>.65 and meters<.75,"Locomotion speed outside accelerated range")
		assert(absf(actor.velocity_mps.length()-(2.7 if mode=="run" else .75))<.01,"Failed to reach requested speed")
	actor.position=game.world_map.map_to_world(start)
	actor.velocity_mps=Vector2.ZERO
	actor.running=true
	actor.aim_visible=false
	for tick in 45: actor.step_motion(Vector2.RIGHT,1.0/60.0)
	actor.set_facing(Vector2.LEFT)
	actor.step_motion(Vector2.LEFT,1.0/60.0)
	var travel_facing: Vector2=game.world_map.map_to_world(actor.velocity_mps).normalized()
	assert(actor.visual_facing.dot(travel_facing)>0.99,"Body turned away from actual travel before braking")
	actor.running=false
	for tick in 60: actor.step_motion(Vector2.ZERO,1.0/60)
	assert(actor.velocity_mps.length()<0.01,"Actor kept sliding after releasing input")
	actor.position=game.world_map.map_to_world(Vector2(15,48))
	actor.move_world(game.world_map.map_to_world(Vector2(4,0)))
	assert(game.world_map.world_to_map(actor.position).x<16,"Crossed solid house wall")
	assert(actor.can_stand(actor.position),"Collision left player penetrating wall")
	print("PLAYER PASS: eight directions, 30/60/120 Hz, acceleration, turn, stop, wall sweep")
	game.get_tree().quit()
