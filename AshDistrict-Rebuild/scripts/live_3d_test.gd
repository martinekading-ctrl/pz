extends RefCounted

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	for zombie: Node2D in game.zombies: zombie.set_process(false)
	var actors: Array = [game.player,game.zombies[0],game.world_map.vehicles[0]]
	for actor: Node2D in actors:
		var visual: Node2D = actor.live_visual
		assert(visual.viewport.own_world_3d and visual.viewport.transparent_bg)
		assert(visual.model.get_child_count()>0)
		var camera: Camera3D = visual.viewport.get_camera_3d()
		var anchor: Vector2 = camera.unproject_position(Vector3.ZERO)*visual.sprite.scale+visual.sprite.position
		assert(anchor.length()<0.01,"3D ground anchor must coincide with actor collision origin")
	var vehicle: Node2D = actors[2]
	vehicle.heading_logical = Vector2.DOWN
	vehicle.update_pose()
	assert(is_zero_approx(vehicle.rotation),"Vehicle must turn in 3D, not rotate its projected image")
	var visual: Node2D = vehicle.live_visual
	vehicle.position=game.player.position+Vector2(100,0)
	visual._process(1.0)
	assert(absf(angle_difference(visual.model.rotation.y,PI))<0.01)
	game.player.moving=true
	game.update_player_condition_effects()
	assert(game.player.moving,"Condition updates must not reset the walking animation")
	game.player.visible=false
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
	game.stop_firearm_audio()
	print("LIVE 3D PASS: real meshes, transparent isolated worlds, ground anchoring, vehicle heading, locomotion and hidden viewport suspension")
	await game.get_tree().process_frame
	game.get_tree().quit()
