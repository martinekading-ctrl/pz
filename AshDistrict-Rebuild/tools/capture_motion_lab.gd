extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene := preload("res://scenes/motion_lab.tscn").instantiate()
	scene.scripted_preview = true
	root.add_child(scene)
	for frame in 110:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://build/motion_lab_preview.png"
	var result := image.save_png(path)
	print("MOTION_LAB_PREVIEW ", path, " size=", image.get_size(), " result=", result)
	quit()
