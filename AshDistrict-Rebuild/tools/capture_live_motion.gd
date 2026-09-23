extends SceneTree
## Captures motion while the regular player physics and world renderer are active.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game := preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.close_product_shell()
	game.player.position = game.world_map.map_to_world(Vector2(110, 50))
	game.camera.position_smoothing_enabled = false
	for zombie in game.zombies:
		zombie.set_physics_process(false)
		zombie.set_process(false)
		zombie.visible = false
	game.game_input.set_touch_move(Vector2.RIGHT)
	game.game_input.set_touch_run(true)
	for frame in 100:
		await physics_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://build/live_motion_preview.png"
	assert(image.save_png(path) == OK)
	print("LIVE_MOTION_PREVIEW ", path, " player=", game.player.position, " speed=", game.player.velocity_mps.length())
	game.game_input.clear_transient()
	quit()
