extends SceneTree

## Records the same gait changes in the playable 2D world and 3D actor renderer.

const OUTPUT_DIR := "res://build/live_motion_sequence"
const FRAME_COUNT := 300
const FRAME_STEP := 4

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
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
	for frame in FRAME_COUNT:
		if frame < 30:
			game.game_input.set_touch_move(Vector2.ZERO)
			game.game_input.set_touch_run(false)
		elif frame < 90:
			game.game_input.set_touch_move(Vector2.RIGHT)
			game.game_input.set_touch_run(false)
		elif frame < 180:
			game.game_input.set_touch_move(Vector2.RIGHT)
			game.game_input.set_touch_run(true)
		elif frame < 240:
			game.game_input.set_touch_move(Vector2.DOWN)
			game.game_input.set_touch_run(true)
		else:
			game.game_input.set_touch_move(Vector2.ZERO)
			game.game_input.set_touch_run(false)
		await physics_frame
		if frame % FRAME_STEP != 0:
			continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		assert(image.save_png("%s/frame_%03d.png" % [OUTPUT_DIR, frame / FRAME_STEP]) == OK)
	game.game_input.clear_transient()
	print("LIVE_MOTION_SEQUENCE ", FRAME_COUNT / FRAME_STEP, " frames in ", OUTPUT_DIR,
		" player=", game.player.position)
	quit()
