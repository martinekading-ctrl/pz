extends SceneTree

func _initialize() -> void:
	call_deferred("test_motion")

func test_motion() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := preload("res://scripts/motion_driver_3d.gd").new()
	world.add_child(actor)
	for step in 120:
		actor.step_motion(Vector3.FORWARD, step >= 60, 1.0 / 60.0)
	print("MOTION_LAB_DISTANCE ", actor.global_position, " SPEED ", actor.velocity.length(), " ROOT ", actor.root_delta)
	assert(actor.global_position.z < -3.0, "Root motion failed to move the actor")
	assert(actor.velocity.length() > 2.0, "Jog speed failed to build")
	for step in 60:
		actor.step_motion(Vector3.ZERO, false, 1.0 / 60.0)
	assert(actor.speed_mps < 0.05, "Actor failed to stop")
	print("MOTION_LAB_STOP ", actor.global_position, " SPEED ", actor.speed_mps)
	quit()
