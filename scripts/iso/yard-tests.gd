extends RefCounted

static func run(game: Node2D) -> void:
	game.start_game()
	for e in game.enemies:
		e.frozen = true
		e.collision_layer = 0
	for p in [Vector2(600,400),Vector2(610,250),Vector2(760,140),Vector2(1040,110),Vector2(1430,210),Vector2(1510,500),Vector2(1350,650),Vector2(1000,650),Vector2(750,560),Vector2(1650,1150)]:
		assert(game.can_walk(p),"Free yard ground blocked: "+str(p))
		assert(not game.find_route(game.safe_point,p).is_empty(),"Unreachable yard: "+str(p))
	assert(game.clear_line(Vector2(450,340),Vector2(650,340)),"Grass must permit direct cross-country travel")
	for p in [Vector2(750,389),Vector2(820,248),Vector2(1170,500),Vector2(565,160),Vector2(1100,80),Vector2(180,445)]:
		assert(not game.can_walk(p),"Solid object passable: "+str(p))
	var inside := Vector2(960,350)
	var outside := Vector2(750,560)
	assert(not game.find_route(outside,inside).is_empty())
	game.player.position = outside
	assert(game.world.yard.toggle(0))
	assert(game.find_route(outside,inside).is_empty(),"Closed house must not allow entering through a wall")
	assert(game.world.yard.toggle(0))
	assert(not game.find_route(outside,inside).is_empty())
	game.player.position = Vector2(1595,495)
	game.wait_interact_release = false
	Input.action_press("interact")
	game.update_interaction(0.1)
	Input.action_release("interact")
	assert(game.world.yard.doors[1].open,"E must open side gate")
	assert(game.can_walk(Vector2(1645,495)))
	assert(game.save_game("user://iso-yard-test.json"))
	game.world.yard.toggle(1)
	assert(game.load_game("user://iso-yard-test.json"))
	assert(game.world.yard.doors[1].open)
	game.player.position = Vector2(748,563)
	for target in [Vector2(600,400),Vector2(610,250),Vector2(760,140),Vector2(1040,110),Vector2(1430,210),Vector2(1510,500),Vector2(1350,650),Vector2(1000,650),Vector2(750,560)]:
		var route: PackedVector2Array = game.find_route(game.player.position,target)
		var ticks := 0
		for point in route:
			while game.player.position.distance_to(point)>10 and ticks<2500:
				var direction: Vector2 = point-game.player.position
				for pair in [[KEY_D,direction.x>3],[KEY_A,direction.x< -3],[KEY_S,direction.y>3],[KEY_W,direction.y< -3]]:
					var event := InputEventKey.new()
					event.physical_keycode = pair[0]
					event.pressed = pair[1]
					Input.parse_input_event(event)
				await game.get_tree().physics_frame
				ticks += 1
		assert(game.player.position.distance_to(target)<25,"WASD yard walk stalled: "+str(target))
		print("YARD WALK: ",target)
	for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		Input.parse_input_event(event)
	print("FREE YARD PASS: off-road ground, full house circuit with WASD, solid walls/trees/fences/cars, closed-door isolation, real E gate action, persistent doors")
	game.get_tree().quit()
