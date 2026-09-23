extends SceneTree
## Guard ground clearance and loop continuity; visual review remains required.

func _initialize() -> void:
	call_deferred("test_clearance")

func test_clearance() -> void:
	var scene := preload("res://art/characters/human_base/survivor.scn").instantiate()
	root.add_child(scene)
	var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := scene.find_child("Skeleton3D", true, false) as Skeleton3D
	for clip_name in ["Walk", "Walk_Gun", "Run", "Run_Gun"]:
		var clip := player.get_animation(clip_name)
		var lowest := INF
		var highest := -INF
		player.play(clip_name)
		player.pause()
		for frame in 85:
			player.seek(float(frame) / 85.0 * clip.length, true)
			for side in ["l", "r"]:
				var ankle := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + side)).origin)
				lowest = minf(lowest, ankle.y)
				highest = maxf(highest, ankle.y)
		print("GAIT_CLEARANCE ", clip_name, " min_y=", lowest, " max_y=", highest)
		assert(lowest > 0.04 and lowest < 0.14, "At least one shoe must approach the ground without sinking")
		assert(highest > 0.20 and highest < 0.51, "Swing foot clearance is outside the human run/walk range")
	for clip_name in ["Run", "Run_Gun"]:
		var clip := player.get_animation(clip_name)
		for bone in ["pelvis", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r", "upperarm_l", "upperarm_r"]:
			var path := NodePath("Armature/Skeleton3D:" + bone)
			var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
			assert(track >= 0)
			var first: Quaternion = clip.track_get_key_value(track, 0)
			var last: Quaternion = clip.track_get_key_value(track, clip.track_get_key_count(track) - 1)
			assert(first.angle_to(last) < 0.015, "Run loop jumps at the seam: " + bone)
	quit()
