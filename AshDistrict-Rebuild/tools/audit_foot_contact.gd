extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	for asset in ["res://art/characters/human_base/UAL1_Standard.glb", "res://art/characters/human_base/survivor.scn"]:
		var scene := (load(asset) as PackedScene).instantiate()
		root.add_child(scene)
		var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var skeleton := scene.find_child("Skeleton3D", true, false) as Skeleton3D
		print("ASSET ", asset, " root=", scene.name)
		print("  LEG_REST hip=", skeleton.get_bone_global_rest(skeleton.find_bone("thigh_l")).origin,
			" upper=", skeleton.get_bone_rest(skeleton.find_bone("calf_l")).origin.length(),
			" lower=", skeleton.get_bone_rest(skeleton.find_bone("foot_l")).origin.length())
		for name in ["Walk", "Jog_Fwd", "Sprint", "Run"]:
			if not player.has_animation(name): continue
			var clip := player.get_animation(name)
			player.play(name)
			print("CLIP ", name, " length=", clip.length)
			for step in 17:
				var t := float(step) / 16.0 * clip.length
				player.seek(t, true)
				var left := skeleton.get_bone_global_pose(skeleton.find_bone("foot_l")).origin
				var right := skeleton.get_bone_global_pose(skeleton.find_bone("foot_r")).origin
				print("  ", snappedf(t,0.001), " L=", left, " R=", right)
		scene.free()
	quit()
