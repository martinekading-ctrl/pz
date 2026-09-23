extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/live_close"))
	var game := preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.close_product_shell()
	game.player.position = game.world_map.map_to_world(Vector2(110, 50))
	game.camera.position_smoothing_enabled = false
	game.camera.zoom = Vector2.ONE * 1.8
	for zombie in game.zombies:
		zombie.set_physics_process(false)
		zombie.set_process(false)
		zombie.visible = false
	game.game_input.set_touch_move(Vector2.RIGHT)
	game.game_input.set_touch_run(true)
	for frame in 150:
		await physics_frame
		if frame % 4 != 0: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		assert(image.save_png("res://build/live_close/frame_%03d.png" % (frame / 4)) == OK)
	game.game_input.clear_transient()
	print("LIVE_CLOSE_CAPTURED")
	quit()
