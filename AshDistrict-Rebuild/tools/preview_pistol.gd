extends SceneTree

func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	root.size=Vector2i(800,600)
	var scene := Node3D.new()
	root.add_child(scene)
	var pistol: Node3D=load("res://art/weapons/service_pistol.scn").instantiate()
	scene.add_child(pistol)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position=Vector3(0.4,0.22,0.4)
	camera.look_at(Vector3(0,0,0.06))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=0.43
	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.rotation_degrees=Vector3(-50,-30,0)
	light.light_energy=1.4
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/pistol-model-preview.png")
	scene.queue_free()
	await process_frame
	quit()
