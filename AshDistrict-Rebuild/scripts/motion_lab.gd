extends Node3D
## Play directly with: godot --path . res://scenes/motion_lab.tscn

const DRIVER := preload("res://scripts/motion_driver_3d.gd")
var actor: CharacterBody3D
var camera: Camera3D
var status: Label
var scripted_preview := false
var scripted_time := 0.0

func _ready() -> void:
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40, 0.2, 40)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.1
	floor_body.add_child(floor_collision)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	floor_mesh.material_override = surface(Color("608363"))
	floor_body.add_child(floor_mesh)
	for coordinate in range(-15, 16):
		line(Vector3(float(coordinate), 0.005, 0), Vector3(0.015, 0.01, 30), Color("9cad90"))
		line(Vector3(0, 0.005, float(coordinate)), Vector3(30, 0.01, 0.015), Color("9cad90"))
	line(Vector3.ZERO, Vector3(0.04, 0.015, 30), Color("e6d58e"))
	line(Vector3.ZERO, Vector3(30, 0.015, 0.04), Color("e6d58e"))
	actor = DRIVER.new()
	actor.name = "PlayerMotionPilot"
	add_child(actor)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.2
	add_child(light)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("a8bac2")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dee5db")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.5
	add_child(camera)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(460, 0)
	overlay.add_child(panel)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 18)
	panel.add_child(status)
	update_camera(1.0)

func surface(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func line(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = surface(color)
	add_child(mesh)

func _physics_process(delta: float) -> void:
	var horizontal := (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
	var vertical := (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
	var direction := Vector3(horizontal, 0, vertical).normalized()
	var running := Input.is_key_pressed(KEY_SHIFT)
	if scripted_preview:
		scripted_time += delta
		if scripted_time < 0.5:
			direction = Vector3.ZERO
		elif scripted_time < 1.5:
			direction = Vector3.FORWARD
		elif scripted_time < 3.5:
			direction = Vector3.FORWARD
			running = true
		elif scripted_time < 5.0:
			direction = Vector3.RIGHT
			running = true
		else:
			direction = Vector3.ZERO
	actor.step_motion(direction, running, delta)
	update_camera(delta)
	status.text = "动作测试场 · WASD 移动 / Shift 慢跑\n" + (
		"目标 %.2f m/s   实际 %.2f m/s   动画倍率 %.2f\n" % [actor.requested_speed, actor.velocity.length(), actor.motion_time_scale]
	) + ("根位移 %.3f m/帧   坐标 (%.1f, %.1f)" % [actor.root_delta.z, actor.global_position.x, actor.global_position.z])

func update_camera(delta: float) -> void:
	var target := actor.global_position + Vector3(0, 0.8, 0)
	var desired := target + Vector3(8, 8, 8)
	camera.global_position = camera.global_position.lerp(desired, minf(1.0, delta * 8.0))
	camera.look_at(target)
