extends SceneTree
## Print locomotion track evidence from the source pack and current shipped rig.

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	for asset in ["res://art/characters/human_base/UAL1_Standard.glb", "res://art/characters/human_base/survivor.scn"]:
		var packed := load(asset) as PackedScene
		assert(packed != null)
		var scene := packed.instantiate()
		root.add_child(scene)
		var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		assert(player != null)
		print("ASSET ", asset)
		print("AVAILABLE ", player.get_animation_list())
		for clip_name in ["Idle", "Walk", "Jog_Fwd", "Sprint", "Run"]:
			if not player.has_animation(clip_name):
				continue
			var clip := player.get_animation(clip_name)
			print("CLIP ", clip_name, " length=", clip.length, " tracks=", clip.get_track_count())
			for i in clip.get_track_count():
				if clip.track_get_type(i) != Animation.TYPE_POSITION_3D:
					continue
				var path := str(clip.track_get_path(i))
				var first := clip.position_track_interpolate(i, 0.0)
				var last := clip.position_track_interpolate(i, clip.length)
				var midpoint := clip.position_track_interpolate(i, clip.length * 0.5)
				print("  POS ", path, " keys=", clip.track_get_key_count(i), " first=", first, " mid=", midpoint, " last=", last, " delta=", last - first)
		scene.free()
	quit()
