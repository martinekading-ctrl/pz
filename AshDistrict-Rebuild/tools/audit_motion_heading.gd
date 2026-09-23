extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var actor := preload("res://art/characters/human_base/survivor.scn").instantiate()
	root.add_child(actor)
	var player := actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := actor.find_child("Skeleton3D", true, false) as Skeleton3D
	var pelvis := skeleton.find_bone("pelvis")
	var rest := skeleton.get_bone_global_rest(pelvis).basis
	for clip_name in ["Idle", "Walk", "Run", "Run_Gun"]:
		player.play(clip_name)
		player.pause()
		for phase in [0.0, 0.25, 0.5, 0.75]:
			player.seek(player.get_animation(clip_name).length * phase, true)
			var pose := skeleton.get_bone_global_pose(pelvis).basis
			var front := pose * rest.inverse() * Vector3.BACK
			assert(front.z > 0.9, clip_name + " faces backward at phase " + str(phase))
		print("FORWARD ", clip_name, " PASS")
	actor.free()
	quit()
