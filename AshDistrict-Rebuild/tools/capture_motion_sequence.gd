extends SceneTree

## Records a continuous, reproducible idle/walk/jog/turn/stop pass for review.

const FRAME_COUNT := 390
const FRAME_STEP := 4
const OUTPUT_DIR := "res://build/motion_sequence"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var scene := preload("res://scenes/motion_lab.tscn").instantiate()
	scene.scripted_preview = true
	root.add_child(scene)
	for frame in FRAME_COUNT:
		await physics_frame
		if frame % FRAME_STEP != 0:
			continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/frame_%03d.png" % [OUTPUT_DIR, frame / FRAME_STEP]
		assert(image.save_png(path) == OK, "Could not save motion frame")
	print("MOTION_SEQUENCE ", FRAME_COUNT / FRAME_STEP, " frames in ", OUTPUT_DIR)
	quit()
